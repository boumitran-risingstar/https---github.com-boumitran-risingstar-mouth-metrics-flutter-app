
const express = require('express');
const { Firestore, Timestamp, FieldValue } = require('@google-cloud/firestore');
const { Storage } = require('@google-cloud/storage');
const admin = require('firebase-admin');
const cors = require('cors');
const multer = require('multer');
const { v4: uuidv4 } = require('uuid');
const geofire = require('geofire-common');


const app = express();
app.use(cors());
app.use(express.json());

// Initialize Firebase Admin SDK
admin.initializeApp();

const firestore = new Firestore({ ignoreUndefinedProperties: true });
const storage = new Storage();
const usersCollection = firestore.collection('users');
const businessesCollection = firestore.collection('businesses');
const slugsCollection = firestore.collection('slugs');
const profilesBucketName = 'user-profile-pages'; // Replace with your bucket name
const profilesBucket = storage.bucket(profilesBucketName);

// Configure Multer for in-memory file storage and validation
const upload = multer({
    storage: multer.memoryStorage(),
    limits: {
        fileSize: 2 * 1024 * 1024, // 2 MB
    },
    fileFilter: (req, file, cb) => {
        if (file.mimetype === 'image/jpeg' || file.mimetype === 'image/png') {
            cb(null, true);
        } else {
            cb(new Error('Invalid file type. Only JPEG and PNG are allowed.'), false);
        }
    },
});


// --- Authentication Middleware ---
const authenticate = async (req, res, next) => {
    const idToken = req.headers.authorization?.split('Bearer ')[1];
    if (!idToken) {
        return res.status(401).send('Unauthorized');
    }
    try {
        const decodedToken = await admin.auth().verifyIdToken(idToken);
        req.user = decodedToken;
        next();
    } catch (error) {
        console.error('Error verifying token:', error);
        return res.status(403).send('Forbidden');
    }
};

// --- Authorization Middleware for Business Owners ---
const authorizeBusinessOwner = async (req, res, next) => {
    try {
        const { uid } = req.user; // Comes from `authenticate` middleware
        const businessQuery = await businessesCollection.where('ownerId', '==', uid).limit(1).get();

        if (businessQuery.empty) {
            return res.status(403).send('Forbidden: User is not a business owner.');
        }

        // Attach the business to the request object for later use
        req.business = { id: businessQuery.docs[0].id, ...businessQuery.docs[0].data() };
        next();
    } catch (error) {
        console.error('Error authorizing business owner:', error);
        res.status(500).send('Internal Server Error');
    }
};


// --- Helper Functions ---

const generateUniqueSlug = async (name) => {
    const baseSlug = name.toLowerCase().replace(/\s+/g, '-').replace(/[^a-z0-9-]/g, '');
    let slug = baseSlug;
    let suffix = 1;
    while (true) {
        const slugDoc = await slugsCollection.doc(slug).get();
        if (!slugDoc.exists) break;
        slug = `${baseSlug}-${(Math.random().toString(36).substring(2, 6))}`;
    }
    return slug;
};

const generateAndUploadProfilePage = async (userData) => {
    const { name, bio, profilePictureUrl, slug } = userData;
    if (!slug) {
        console.error('Cannot generate profile page without a slug for user:', userData);
        return;
    }
    const imageElement = profilePictureUrl
        ? `<img src="https://user-service-402886834615.us-central1.run.app${profilePictureUrl}" alt="Profile Picture">`
        : `<div class="default-icon">
               <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#ccc" width="100px" height="100px">
                   <path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z"/>
               </svg>
           </div>`;
    const htmlContent = `
        <!DOCTYPE html><html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>${name}'s Profile</title>
            <style>
                body { font-family: sans-serif; text-align: center; margin-top: 50px; background-color: #f0f2f5; }
                .profile-card { background: white; padding: 30px; border-radius: 15px; box-shadow: 0 4px 8px rgba(0,0,0,0.1); display: inline-block; }
                img { width: 150px; height: 150px; border-radius: 50%; object-fit: cover; border: 4px solid #fff; }
                .default-icon {
                    width: 150px; height: 150px; border-radius: 50%; background-color: #e0e0e0;
                    display: inline-flex; justify-content: center; align-items: center; border: 4px solid #fff;
                }
                h1 { margin-top: 15px; }
                p { color: #666; }
            </style>
        </head>
        <body>
            <div class="profile-card">
                ${imageElement}
                <h1>${name}</h1>
                <p>${bio || 'No bio provided.'}</p>
            </div>
        </body></html>`;
    const file = profilesBucket.file(`${slug}.html`);
    await file.save(htmlContent, { metadata: { contentType: 'text/html' } });
    console.log(`Profile page for ${slug} uploaded to GCS.`);
};

const createAndUploadRedirectPage = async (oldSlug, newSlug) => {
    if (!oldSlug || !newSlug) return;
    const newProfileUrl = `/profile/${newSlug}`;
    const redirectHtmlContent = `
        <!DOCTYPE html><html lang="en">
        <head>
            <meta charset="UTF-8"><title>Permanent Redirect</title>
            <link rel="canonical" href="${newProfileUrl}" />
            <meta http-equiv="refresh" content="0; url=${newProfileUrl}" />
        </head>
        <body><p>This page has moved. You will be redirected.</p></body></html>`;
    const file = profilesBucket.file(`${oldSlug}.html`);
    await file.save(redirectHtmlContent, { metadata: { contentType: 'text/html' } });
    console.log(`Redirect page created from ${oldSlug}.html to ${newProfileUrl}.`);
};

// --- API Routes ---
const userRouter = express.Router();
const professionalsRouter = express.Router(); // New router for professionals


// Sync User
userRouter.post('/sync', authenticate, async (req, res) => {
    try {
        const { uid, email, phone_number, name: firebaseName, picture } = req.user;
        const { displayName, userType = 'Patient', location } = req.body;
        const finalName = displayName || firebaseName;
        const userRef = usersCollection.doc(uid);
        const userDoc = await userRef.get();

        // Check if the user is a business owner
        const businessQuery = await businessesCollection.where('ownerId', '==', uid).limit(1).get();
        const isBusinessOwner = !businessQuery.empty;

        if (userDoc.exists) {
            const userData = userDoc.data();
            // If the business owner status has changed, update it
            if (userData.isBusinessOwner !== isBusinessOwner) {
                await userRef.update({ isBusinessOwner });
            }
            return res.status(200).send({ id: userDoc.id, ...userData, isBusinessOwner });
        }

        const slug = await generateUniqueSlug(finalName || 'user');
        const newUser = {
            name: finalName || 'New User',
            email: email,
            phoneNumber: phone_number,
            userType: userType,
            isBusinessOwner: isBusinessOwner, // Add the flag here
            slug: slug,
            bio: 'Welcome to my profile!',
            profilePictureUrl: picture || null,
            photoGallery: [],
            createdAt: Timestamp.now(),
            slugHistory: [],
        };

        // Add location and geohash if user is a Professional
        if (userType === 'Professional' && location) {
            if (location.latitude && location.longitude) {
                newUser.location = new Firestore.GeoPoint(location.latitude, location.longitude);
                newUser.geohash = geofire.geohashForLocation([location.latitude, location.longitude]);
            }
        }

        await firestore.runTransaction(async (t) => {
            t.set(userRef, newUser);
            t.set(slugsCollection.doc(slug), { userId: uid });
        });

        await generateAndUploadProfilePage({ ...newUser, uid });
        res.status(201).send({ id: uid, ...newUser });
    } catch (error) {
        console.error('Error syncing user:', error);
        res.status(500).send('Error syncing user');
    }
});

// Get User Profile
userRouter.get('/:userId', authenticate, async (req, res) => {
    if (req.user.uid !== req.params.userId) return res.status(403).send('Forbidden');
    try {
        const userDoc = await usersCollection.doc(req.params.userId).get();
        if (!userDoc.exists) return res.status(404).send('User not found');
        res.status(200).send({ id: userDoc.id, ...userDoc.data() });
    } catch (error) {
        res.status(500).send('Error getting user profile');
    }
});

// Update User Profile
userRouter.put('/:userId', authenticate, async (req, res) => {
    const { userId } = req.params;
    if (req.user.uid !== userId) return res.status(403).send('Forbidden');

    try {
        const { name, bio, email, location, userType } = req.body;
        const userRef = usersCollection.doc(userId);
        const userDoc = await userRef.get();
        if (!userDoc.exists) return res.status(404).send('User not found');

        const currentData = userDoc.data();
        const updatedData = { ...currentData, uid: userId };
        let newSlug = null, oldSlug = currentData.slug;
        let needsPageUpdate = false;

        const payload = {
            bio: bio !== undefined ? bio : currentData.bio,
            email: email !== undefined ? email : currentData.email,
            userType: userType !== undefined ? userType : currentData.userType
        };

        if (name && name !== currentData.name) {
            payload.name = name;
            newSlug = await generateUniqueSlug(name);
            payload.slug = newSlug;
            payload.slugHistory = [oldSlug, ...(currentData.slugHistory || [])];
            needsPageUpdate = true;
        }

        // Handle location update
        if (payload.userType === 'Professional' && location) {
            if (location.latitude && location.longitude) {
                payload.location = new Firestore.GeoPoint(location.latitude, location.longitude);
                payload.geohash = geofire.geohashForLocation([location.latitude, location.longitude]);
            }
        } else {
             // If user is no longer a professional, remove location data
            payload.location = FieldValue.delete();
            payload.geohash = FieldValue.delete();
        }

        Object.keys(payload).forEach(k => payload[k] === undefined && delete payload[k]);

        await firestore.runTransaction(async (t) => {
            t.update(userRef, payload);
            if (newSlug) {
                t.set(slugsCollection.doc(newSlug), { userId });
                Object.assign(updatedData, payload); 
            }
        });

        if (needsPageUpdate) {
            await generateAndUploadProfilePage({ ...currentData, ...payload, uid: userId});
        }
        if (newSlug) {
            await createAndUploadRedirectPage(oldSlug, newSlug);
        }

        res.status(200).send({ message: 'Profile updated', newSlug });
    } catch (error) {
        console.error('Error updating profile:', error);
        res.status(500).send('Error updating profile');
    }
});


// --- Photo Management Endpoints ---

// Upload a new photo
userRouter.post('/:userId/photos', authenticate, upload.single('photo'), async (req, res) => {
    const { userId } = req.params;
    if (req.user.uid !== userId) return res.status(403).send('Forbidden');
    if (!req.file) return res.status(400).send('No photo file provided.');

    try {
        const userRef = usersCollection.doc(userId);
        const userDoc = await userRef.get();
        if (!userDoc.exists) return res.status(404).send('User not found');

        const userData = userDoc.data();
        let { photoGallery = [] } = userData;

        if (photoGallery.length >= 5) {
            return res.status(400).send('Photo gallery is full. Maximum of 5 photos allowed.');
        }

        const photoId = uuidv4();
        const fileName = `user-photos/${userId}/${photoId}`;
        const file = profilesBucket.file(fileName);

        await file.save(req.file.buffer, { metadata: { contentType: 'image/jpeg' } });
        
        const proxyUrl = `/photos/${userId}/${photoId}`; // The relative URL to store

        const newPhoto = {
            id: photoId,
            url: proxyUrl,
            isDefault: photoGallery.length === 0, // First photo is the default
            createdAt: Timestamp.now(),
        };

        photoGallery.push(newPhoto);

        const updatePayload = {
            photoGallery,
            profilePictureUrl: newPhoto.isDefault ? proxyUrl : userData.profilePictureUrl,
        };
        
        await userRef.update(updatePayload);

        // Regenerate static page if the default picture changed
        if (newPhoto.isDefault) {
            await generateAndUploadProfilePage({ ...userData, profilePictureUrl: proxyUrl, uid: userId });
        }

        res.status(201).send({ message: 'Photo uploaded successfully', photo: newPhoto, gallery: photoGallery });

    } catch (error) {
        console.error('Error uploading photo:', error);
        res.status(500).send('Error uploading photo');
    }
});

// Set a default photo
userRouter.put('/:userId/photos/:photoId/default', authenticate, async (req, res) => {
    const { userId, photoId } = req.params;
    if (req.user.uid !== userId) return res.status(403).send('Forbidden');

    try {
        const userRef = usersCollection.doc(userId);
        const userDoc = await userRef.get();
        if (!userDoc.exists) return res.status(404).send('User not found');

        const userData = userDoc.data();
        let { photoGallery = [] } = userData;
        let newDefaultUrl = null;

        const updatedGallery = photoGallery.map(photo => {
            if (photo.id === photoId) {
                newDefaultUrl = photo.url;
                return { ...photo, isDefault: true };
            } 
            return { ...photo, isDefault: false };
        });

        if (!newDefaultUrl) return res.status(404).send('Photo not found in gallery.');

        await userRef.update({ photoGallery: updatedGallery, profilePictureUrl: newDefaultUrl });

        await generateAndUploadProfilePage({ ...userData, profilePictureUrl: newDefaultUrl, uid: userId });

        res.status(200).send({ message: 'Default photo updated successfully.', gallery: updatedGallery });
    } catch (error) {
        console.error('Error setting default photo:', error);
        res.status(500).send('Error setting default photo');
    }
});

// Delete a photo
userRouter.delete('/:userId/photos/:photoId', authenticate, async (req, res) => {
    const { userId, photoId } = req.params;
    if (req.user.uid !== userId) return res.status(403).send('Forbidden');

    try {
        const userRef = usersCollection.doc(userId);
        const userDoc = await userRef.get();
        if (!userDoc.exists) return res.status(404).send('User not found');
        
        const userData = userDoc.data();
        let { photoGallery = [], profilePictureUrl } = userData;
        
        const photoToDelete = photoGallery.find(p => p.id === photoId);
        if (!photoToDelete) return res.status(404).send('Photo not found in gallery.');

        // Delete file from GCS
        const fileName = `user-photos/${userId}/${photoId}`;
        await profilesBucket.file(fileName).delete({ ignoreNotFound: true });

        let updatedGallery = photoGallery.filter(p => p.id !== photoId);
        let newDefaultUrl = profilePictureUrl;
        let pageNeedsUpdate = false;

        if (photoToDelete.isDefault && updatedGallery.length > 0) {
            // If the default was deleted, make the newest remaining photo the new default
            updatedGallery[0].isDefault = true;
            newDefaultUrl = updatedGallery[0].url;
            pageNeedsUpdate = true;
        } else if (updatedGallery.length === 0) {
            // If the gallery is now empty, clear the profile picture
            newDefaultUrl = null;
            pageNeedsUpdate = true;
        }

        await userRef.update({ photoGallery: updatedGallery, profilePictureUrl: newDefaultUrl });

        if (pageNeedsUpdate) {
            await generateAndUploadProfilePage({ ...userData, profilePictureUrl: newDefaultUrl, uid: userId });
        }

        res.status(200).send({ message: 'Photo deleted successfully.', gallery: updatedGallery });

    } catch (error) {
        console.error('Error deleting photo:', error);
        res.status(500).send('Error deleting photo');
    }
});


// --- Professionals Endpoints ---

// Find nearby professionals (for business owners)
professionalsRouter.get('/nearby', [authenticate, authorizeBusinessOwner], async (req, res) => {
    try {
        const { location } = req.business; // Business location from middleware
        if (!location || !location.latitude || !location.longitude) {
            return res.status(400).send('Business location is not set.');
        }

        const center = [location.latitude, location.longitude];
        const radiusInM = 50 * 1000; // 50 kilometers

        // Get the bounding box for the query
        const bounds = geofire.geohashQueryBounds(center, radiusInM);
        const promises = [];

        // Construct a query for each bound
        for (const b of bounds) {
            const q = usersCollection
                .where('userType', '==', 'Professional')
                .orderBy('geohash')
                .startAt(b[0])
                .endAt(b[1]);
            promises.push(q.get());
        }

        // Await all queries and process the results
        const snapshots = await Promise.all(promises);
        const matchingDocs = [];

        for (const snap of snapshots) {
            for (const doc of snap.docs) {
                const docData = doc.data();
                const docLocation = docData.location;

                if (docLocation && docLocation.latitude && docLocation.longitude) {
                    const distanceInKm = geofire.distanceBetween(
                        [docLocation.latitude, docLocation.longitude],
                        center
                    );
                    if (distanceInKm * 1000 <= radiusInM) {
                        matchingDocs.push({ id: doc.id, ...docData, distance: distanceInKm.toFixed(2) });
                    }
                }
            }
        }

        // Sort results by distance
        matchingDocs.sort((a, b) => a.distance - b.distance);

        res.status(200).send(matchingDocs);
    } catch (error) {
        console.error('Error finding nearby professionals:', error);
        res.status(500).send('Error finding nearby professionals');
    }
});


// --- Public Photo Proxy (No Auth) ---
app.get('/photos/:userId/:photoId', (req, res) => {
    const { userId, photoId } = req.params;
    const fileName = `user-photos/${userId}/${photoId}`;
    const file = profilesBucket.file(fileName);

    file.createReadStream()
        .on('error', (err) => {
            console.error('Error streaming file:', err);
            res.status(404).send('Photo not found.');
        })
        .on('response', (response) => {
            // Set caching headers
            res.set('Cache-Control', 'public, max-age=3600'); // Cache for 1 hour
            res.set('Content-Type', 'image/jpeg');
        })
        .pipe(res);
});

// --- Public Profile Route (No Auth) ---
app.get('/profile/:slug', async (req, res) => {
    try {
        const slugDoc = await slugsCollection.doc(req.params.slug).get();
        if (!slugDoc.exists) return res.status(404).send('Profile not found.');
        
        const { userId } = slugDoc.data();
        const userDoc = await usersCollection.doc(userId).get();
        if (!userDoc.exists) return res.status(404).send('Profile data not found.');
        
        const { name, bio, profilePictureUrl, slug } = userDoc.data();
        res.status(200).send({ name, bio, profilePictureUrl, slug });
    } catch (error) {
        console.error('Error getting public profile:', error);
        res.status(500).send('Error getting profile');
    }
});

// Main app configuration
app.use('/api/users', userRouter);
app.use('/api/professionals', professionalsRouter); // Register the new router


const port = process.env.PORT || 8080;
app.listen(port, () => {
    console.log(`Server listening on port ${port}`);
});
