
const express = require('express');
const admin = require('firebase-admin');
const cors = require('cors');
const geofire = require('geofire-common');
const { Storage } = require('@google-cloud/storage');

const app = express();
const port = process.env.PORT || 8080;

// Use more explicit CORS options to handle proxies
app.use(cors({
  origin: true, // Reflects the request origin
  credentials: true
}));
app.options('*', cors()); // Enable pre-flight for all routes

// Initialize Firebase Admin SDK
admin.initializeApp();
const db = admin.firestore();

// Initialize Google Cloud Storage
const storage = new Storage();
const bucketName = 'business-profile-pages'; 
const businessPagesBucket = storage.bucket(bucketName);

// Function to generate HTML for a business profile
const generateBusinessPageHTML = (businessData) => {
    return `
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>${businessData.name}</title>
            <meta name="description" content="${businessData.description}">
            <meta property="og:title" content="${businessData.name}" />
            <meta property="og:description" content="${businessData.description}" />
            <meta property="og:image" content="${businessData.image}" />
            <meta property="og:type" content="website" />
        </head>
        <body>
            <h1>${businessData.name}</h1>
            <p>${businessData.description}</p>
            <img src="${businessData.image}" alt="${businessData.name}" style="max-width: 500px;">
            <h2>Services</h2>
            <ul>
                ${businessData.services.map(service => `<li>${service}</li>`).join('')}
            </ul>
        </body>
        </html>
    `;
};

// Function to upload HTML to Google Cloud Storage
const uploadHtmlToGcs = async (slug, htmlContent) => {
    const fileName = `${slug.substring(1)}.html`; // Remove leading slash for filename
    const file = businessPagesBucket.file(fileName);

    try {
        await file.save(htmlContent, {
            metadata: {
                contentType: 'text/html',
                cacheControl: 'public, max-age=3600',
            },
        });
        console.log(`Successfully uploaded ${fileName} to ${bucketName}`);
    } catch (error) {
        console.error(`Error uploading ${fileName} to GCS:`, error);
        throw error; // Re-throw to be caught by the endpoint handler
    }
};


// Middleware to verify Firebase ID token
const authenticate = async (req, res, next) => {
  console.log('Authenticating request...');
  const idToken = req.headers.authorization?.split('Bearer ')[1];

  if (!idToken) {
    console.log('Unauthorized: No token provided');
    return res.status(401).send('Unauthorized: No token provided');
  }

  try {
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    req.user = decodedToken;
    console.log('Authentication successful');
    next();
  } catch (error) {
    console.error('Error verifying ID token:', error);
    res.status(401).send('Unauthorized: Invalid token');
  }
};

app.use(express.json());

// Function to generate a unique slug
const generateSlug = async (name, category, location) => {
    const slugify = (text) => text.toString().toLowerCase()
        .replace(/\s+/g, '-')
        .replace(/[^\w\-]+/g, '')
        .replace(/\-\-+/g, '-')
        .replace(/^-+/, '')
        .replace(/-+$/, '');

    let slug = `/${slugify(category)}/${slugify(location)}/${slugify(name)}`;
    let businessWithSlug = await db.collection('businesses').where('slug', '==', slug).get();

    while (!businessWithSlug.empty) {
        const randomDigits = Math.floor(1000 + Math.random() * 9000);
        slug = `/${slugify(category)}/${slugify(location)}/${slugify(name)}-${randomDigits}`;
        businessWithSlug = await db.collection('businesses').where('slug', '==', slug).get();
    }

    return slug;
};


app.get('/', (req, res) => {
  res.send('Business management service is running');
});

// Create a new business profile
app.post('/api/businesses', authenticate, async (req, res) => {
    try {
        const { name, description, image, services, location, category } = req.body;
        const ownerId = req.user.uid;

        if (!name || !location || !category) {
            return res.status(400).send('Missing required fields: name, location, and category are required.');
        }

        const lat = location.latitude;
        const lng = location.longitude;

        if (typeof lat !== 'number' || typeof lng !== 'number') {
            return res.status(400).send('Invalid location data: latitude and longitude must be numbers.');
        }

        const geohash = geofire.geohashForLocation([lat, lng]);
        const slug = await generateSlug(name, category, location.city || 'location');


        const businessData = {
            name,
            description: description || '',
            image: image || '',
            services: services || [],
            location: new admin.firestore.GeoPoint(lat, lng),
            category: category || '',
            ownerId,
            geohash,
            slug,
            slugHistory: []
        };

        const docRef = await db.collection('businesses').add(businessData);

        // Generate and upload static HTML page
        const htmlContent = generateBusinessPageHTML(businessData);
        await uploadHtmlToGcs(slug, htmlContent);

        res.status(201).send({ id: docRef.id, ...businessData });

    } catch (error) {
        console.error('Error creating business:', error);
        res.status(500).send('Error creating business profile.');
    }
});

// Update an existing business profile
app.put('/api/businesses/:id', authenticate, async (req, res) => {
    try {
        const businessId = req.params.id;
        const ownerId = req.user.uid;
        const updateData = req.body;

        const docRef = db.collection('businesses').doc(businessId);
        const doc = await docRef.get();

        if (!doc.exists) {
            return res.status(404).send('Business not found.');
        }

        const businessData = doc.data();

        if (businessData.ownerId !== ownerId) {
            return res.status(403).send('Forbidden: You do not have permission to update this profile.');
        }

        // If location is being updated, recalculate the geohash
        if (updateData.location) {
             const lat = updateData.location.latitude;
             const lng = updateData.location.longitude;

            if (typeof lat !== 'number' || typeof lng !== 'number') {
                return res.status(400).send('Invalid location data: latitude and longitude must be numbers.');
            }

             updateData.geohash = geofire.geohashForLocation([lat, lng]);
             updateData.location = new admin.firestore.GeoPoint(lat, lng);
        }

        if (updateData.name && updateData.name !== businessData.name) {
            const newSlug = await generateSlug(updateData.name, businessData.category, businessData.location.city || 'location');
            const oldSlug = businessData.slug;

            updateData.slug = newSlug;
            if (oldSlug) { 
              updateData.slugHistory = [...(businessData.slugHistory || []), oldSlug];
            }
        }


        await docRef.update(updateData);
        const updatedDoc = await docRef.get();
        const updatedBusinessData = updatedDoc.data();

        // Regenerate and upload static HTML page
        const htmlContent = generateBusinessPageHTML(updatedBusinessData);
        const slugForUpload = updatedBusinessData.slug;
        await uploadHtmlToGcs(slugForUpload, htmlContent);

        res.status(200).send({ id: updatedDoc.id, ...updatedBusinessData });

    } catch (error) {
        console.error('Error updating business:', error);
        res.status(500).send('Error updating business profile.');
    }
});


// Authenticated endpoint to find nearby businesses
app.get('/api/businesses/nearby', authenticate, async (req, res) => {
    const { lat, lng, radius } = req.query;

    if (!lat || !lng || !radius) {
        return res.status(400).send('Missing required query parameters: lat, lng, radius');
    }

    const center = [parseFloat(lat), parseFloat(lng)];
    const radiusInM = parseFloat(radius) * 1000; // Convert radius from km to meters

    // Get hash bounds
    const bounds = geofire.geohashQueryBounds(center, radiusInM);
    const promises = [];

    for (const b of bounds) {
        const q = db.collection('businesses')
            .orderBy('geohash')
            .startAt(b[0])
            .endAt(b[1]);
        promises.push(q.get());
    }

    try {
        const snapshots = await Promise.all(promises);
        const matchingDocs = [];

        for (const snap of snapshots) {
            for (const doc of snap.docs) {
                const docData = doc.data();
                const lat = docData.location.latitude;
                const lng = docData.location.longitude;

                // We have to filter out a few false positives due to GeoHash
                // accuracy, but most will be accurate
                const distanceInKm = geofire.distanceBetween([lat, lng], center);
                const distanceInM = distanceInKm * 1000;
                if (distanceInM <= radiusInM) {
                    matchingDocs.push({ id: doc.id, ...docData });
                }
            }
        }

        res.status(200).send(matchingDocs);
    } catch (error) {
        console.error('Error during nearby search:', error);
        res.status(500).send('Error searching for nearby businesses.');
    }
});

// Get all businesses for the current user
app.get('/api/businesses/my-businesses', authenticate, async (req, res) => {
    try {
        const ownerId = req.user.uid;
        const snapshot = await db.collection('businesses').where('ownerId', '==', ownerId).get();
        
        const businesses = [];
        snapshot.forEach(doc => {
            businesses.push({ id: doc.id, ...doc.data() });
        });
        
        res.status(200).send(businesses);

    } catch (error) {
        console.error('Error fetching user businesses:', error);
        res.status(500).send('Error fetching user businesses.');
    }
});

// Get a single business by ID
app.get('/api/businesses/:id', authenticate, async (req, res) => {
    try {
        const businessId = req.params.id;
        const docRef = db.collection('businesses').doc(businessId);
        const doc = await docRef.get();

        if (!doc.exists) {
            return res.status(404).send('Business not found.');
        }

        res.status(200).send({ id: doc.id, ...doc.data() });

    } catch (error) {
        console.error('Error fetching business:', error);
        res.status(500).send('Error fetching business data.');
    }
});

app.get('/api/businesses/by-slug/*', authenticate, async (req, res) => {
    try {
        const slug = req.path.replace('/api/businesses/by-slug', '');
        let businessQuery = await db.collection('businesses').where('slug', '==', slug).limit(1).get();

        if (!businessQuery.empty) {
            const business = businessQuery.docs[0];
            return res.status(200).send({ id: business.id, ...business.data() });
        }

        // If not found, check slug history
        businessQuery = await db.collection('businesses').where('slugHistory', 'array-contains', slug).limit(1).get();

        if (!businessQuery.empty) {
            const business = businessQuery.docs[0];
            return res.status(301).redirect(`/api/businesses/by-slug${business.data().slug}`);
        }

        return res.status(404).send('Business not found.');

    } catch (error) {
        console.error('Error fetching business by slug:', error);
        res.status(500).send('Error fetching business data.');
    }
});


// Example authenticated route
app.get('/businesses', authenticate, (req, res) => {
  // This route is now protected and requires a valid Firebase ID token.
  // In a real application, you would fetch and return business data here.
  res.status(200).send([
    { id: '1', name: 'Business A', owner: req.user.uid },
    { id: '2', name: 'Business B', owner: req.user.uid },
  ]);
});

app.listen(port, () => {
  console.log(`Business service listening on port ${port}`);
});
