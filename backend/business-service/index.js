
const express = require('express');
const admin = require('firebase-admin');
const cors = require('cors');
const geofire = require('geofire-common');

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

app.get('/', (req, res) => {
  res.send('Business management service is running');
});

// Create a new business profile
app.post('/api/businesses', authenticate, async (req, res) => {
    try {
        const { name, description, image, services, location, category } = req.body;
        const ownerId = req.user.uid;

        if (!name || !location) {
            return res.status(400).send('Missing required fields: name and location are required.');
        }

        const lat = location.latitude || location._latitude;
        const lng = location.longitude || location._longitude;

        const geohash = geofire.geohashForLocation([lat, lng]);

        const businessData = {
            name,
            description: description || '',
            image: image || '',
            services: services || [],
            location: new admin.firestore.GeoPoint(lat, lng),
            category: category || '',
            ownerId,
            geohash,
        };

        const docRef = await db.collection('businesses').add(businessData);
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

        if (doc.data().ownerId !== ownerId) {
            return res.status(403).send('Forbidden: You do not have permission to update this profile.');
        }
        
        // If location is being updated, recalculate the geohash
        if (updateData.location) {
             const lat = updateData.location.latitude || updateData.location._latitude;
             const lng = updateData.location.longitude || updateData.location._longitude;
             updateData.geohash = geofire.geohashForLocation([lat, lng]);
             updateData.location = new admin.firestore.GeoPoint(lat, lng);
        }

        await docRef.update(updateData);
        const updatedDoc = await docRef.get();
        res.status(200).send({ id: updatedDoc.id, ...updatedDoc.data() });

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
