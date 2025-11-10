const express = require('express');
const { Firestore, Timestamp } = require('@google-cloud/firestore');
const { Storage } = require('@google-cloud/storage');
const admin = require('firebase-admin');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

// Initialize Firebase Admin SDK
admin.initializeApp();

const firestore = new Firestore({ ignoreUndefinedProperties: true });
const storage = new Storage();
const usersCollection = firestore.collection('users');
const slugsCollection = firestore.collection('slugs');
const profilesBucketName = 'user-profile-pages'; // Replace with your bucket name
const profilesBucket = storage.bucket(profilesBucketName);

// Authentication middleware
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

// Helper to generate a unique slug
const generateUniqueSlug = async (name) => {
    const baseSlug = name.toLowerCase().replace(/\s+/g, '-').replace(/[^a-z0-9-]/g, '');
    let slug = baseSlug;
    let suffix = 1;
    while (true) {
        const slugDoc = await slugsCollection.doc(slug).get();
        if (!slugDoc.exists) {
            break;
        }
        slug = `${baseSlug}-${(Math.random().toString(36).substring(2, 6))}`; // Add a random suffix
    }
    return slug;
};

// Helper function to generate and upload a static HTML page for the user's profile
const generateAndUploadProfilePage = async (userData) => {
    const { name, bio, profilePictureUrl, slug } = userData;
    if (!slug) {
        console.error('Cannot generate profile page without a slug for user:', name);
        return;
    }
    const htmlContent = `
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>${name}'s Profile</title>
            <style>
                body { font-family: sans-serif; text-align: center; margin-top: 50px; background-color: #f0f2f5; }
                .profile-card { background: white; padding: 30px; border-radius: 15px; box-shadow: 0 4px 8px rgba(0,0,0,0.1); display: inline-block; }
                img { width: 150px; height: 150px; border-radius: 50%; border: 4px solid #fff; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
                h1 { margin-top: 15px; color: #333; }
                p { color: #666; }
            </style>
        </head>
        <body>
            <div class="profile-card">
                <img src="${profilePictureUrl || 'https://storage.googleapis.com/user-profile-pages/default-avatar.png'}" alt="Profile Picture">
                <h1>${name}</h1>
                <p>${bio || 'No bio provided.'}</p>
            </div>
        </body>
        </html>
    `;
    const file = profilesBucket.file(`${slug}.html`);
    await file.save(htmlContent, {
        metadata: { contentType: 'text/html' },
    });
    console.log(`Profile page for ${slug} uploaded to GCS.`);
};

// Helper function to create and upload a static HTML redirect page
const createAndUploadRedirectPage = async (oldSlug, newSlug) => {
    if (!oldSlug || !newSlug) {
        console.log('Skipping redirect page creation: old or new slug is missing.');
        return;
    }

    // The final public URL path for profiles
    const newProfileUrl = `/profiles/${newSlug}`; 

    const redirectHtmlContent = `
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <title>Permanent Redirect</title>
            <link rel="canonical" href="${newProfileUrl}" />
            <meta http-equiv="refresh" content="0; url=${newProfileUrl}" />
            <style>
                body { font-family: sans-serif; text-align: center; padding-top: 50px; }
            </style>
        </head>
        <body>
            <h1>This page has permanently moved.</h1>
            <p>You will be redirected to the new location automatically.</p>
            <p>If you are not redirected, <a href="${newProfileUrl}">click here</a>.</p>
        </body>
        </html>
    `;
    const file = profilesBucket.file(`${oldSlug}.html`);
    await file.save(redirectHtmlContent, {
        metadata: { 
            contentType: 'text/html',
            cacheControl: 'public, max-age=3600', // Cache redirect for 1 hour
        },
    });
    console.log(`Redirect page created from ${oldSlug}.html to ${newProfileUrl}.`);
};


// Sync user: Creates a user if they don't exist, or returns the existing user.
app.post('/users/sync', authenticate, async (req, res) => {
    try {
        const { uid, email, phone_number, name: firebaseName } = req.user;
        const displayName = req.body.displayName || firebaseName;

        const userRef = usersCollection.doc(uid);
        const userDoc = await userRef.get();

        if (userDoc.exists) {
            // User exists, return their data
            return res.status(200).send({ id: userDoc.id, ...userDoc.data() });
        } else {
            // User does not exist, create them
            const slug = await generateUniqueSlug(displayName || 'user');
            
            const newUser = {
                name: displayName || 'New User',
                email: email,
                phoneNumber: phone_number,
                slug: slug,
                bio: 'Welcome to my profile!',
                profilePictureUrl: req.user.picture || null,
                createdAt: Timestamp.now(),
                slugHistory: [],
            };

            await firestore.runTransaction(async (transaction) => {
                const slugDoc = await slugsCollection.doc(slug).get();
                if (slugDoc.exists) {
                    throw new Error('Slug conflict during user creation.');
                }
                transaction.set(userRef, newUser);
                transaction.set(slugsCollection.doc(slug), { userId: uid });
            });
            
            await generateAndUploadProfilePage(newUser);
            
            return res.status(201).send({ id: uid, ...newUser });
        }
    } catch (error) {
        console.error('Error syncing user:', error);
        res.status(500).send('Error syncing user');
    }
});


// Get a user's profile by ID
app.get('/users/:userId', authenticate, async (req, res) => {
    try {
        const { userId } = req.params;
        // Basic authorization: ensure the authenticated user can only access their own profile
        if (req.user.uid !== userId) {
            return res.status(403).send('Forbidden: You can only access your own profile.');
        }

        const userDoc = await usersCollection.doc(userId).get();
        if (!userDoc.exists) {
            return res.status(404).send('User not found');
        }
        res.status(200).send({ id: userDoc.id, ...userDoc.data() });
    } catch (error) {
        console.error('Error getting user profile by ID:', error);
        res.status(500).send('Error getting user profile');
    }
});

// Get public user profile by slug - This endpoint remains public
app.get('/profile/:slug', async (req, res) => {
    try {
        const { slug } = req.params;
        const slugDoc = await slugsCollection.doc(slug).get();

        if (!slugDoc.exists) {
            // It might be an old slug, so we need to check slugHistory.
            // This requires a more complex query. For this service, we assume public access is via the static pages.
            // A separate Cloud Function (`redirectHandler`) will handle old slug redirects.
            return res.status(404).send('Profile not found.');
        }

        const { userId } = slugDoc.data();
        const userDoc = await usersCollection.doc(userId).get();

        if (!userDoc.exists) {
            // This case indicates an orphaned slug, which should be cleaned up.
            return res.status(404).send('Profile data not found.');
        }
        
        const userData = userDoc.data();
        // Return only public-safe data
        res.status(200).send({
            name: userData.name,
            bio: userData.bio,
            profilePictureUrl: userData.profilePictureUrl,
            slug: userData.slug,
        });
    } catch (error) {
        console.error('Error getting public profile by slug:', error);
        res.status(500).send('Error getting profile');
    }
});

// Update a user's profile
app.put('/users/:userId', authenticate, async (req, res) => {
    try {
        const { userId } = req.params;
        if (req.user.uid !== userId) {
            return res.status(403).send('Forbidden: You can only update your own profile.');
        }

        const { name, bio, email } = req.body;
        const userRef = usersCollection.doc(userId);
        const userDoc = await userRef.get();

        if (!userDoc.exists) {
            return res.status(404).send('User not found');
        }

        const currentData = userDoc.data();
        const updatedData = { ...currentData };
        let newSlug = null;
        let oldSlug = currentData.slug;

        // If email is provided, update it in the local object
        if (email) {
            updatedData.email = email;
        }

        // If the name is changing, generate a new slug
        if (name && name !== currentData.name) {
            updatedData.name = name;
            newSlug = await generateUniqueSlug(name);
            updatedData.slug = newSlug;
            // Prepend old slug to history to keep it ordered chronologically
            updatedData.slugHistory = [oldSlug, ...(currentData.slugHistory || [])];
        }

        if (bio) {
            updatedData.bio = bio;
        }

        // Use a transaction to update Firestore and the slugs collection atomically
        await firestore.runTransaction(async (transaction) => {
            const updatePayload = {
                name: updatedData.name,
                bio: updatedData.bio,
                email: updatedData.email,
                slug: updatedData.slug,
                slugHistory: updatedData.slugHistory,
            };

            Object.keys(updatePayload).forEach(key => updatePayload[key] === undefined && delete updatePayload[key]);

            transaction.update(userRef, updatePayload);

            if (newSlug) {
                // Register the new slug
                transaction.set(slugsCollection.doc(newSlug), { userId });
                // We no longer delete the old slug from the slugs collection.
                // It now points to a redirect page, and we might need it for historical lookups.
            }
        });

        // Regenerate and upload the static HTML page with the new data
        await generateAndUploadProfilePage(updatedData);

        // If a new slug was created, create a redirect page for the old one
        if (newSlug && oldSlug) {
            await createAndUploadRedirectPage(oldSlug, newSlug);
        }

        res.status(200).send({ message: 'Profile updated successfully', newSlug: newSlug });
    } catch (error) {
        console.error('Error updating profile:', error);
        res.status(500).send('Error updating profile');
    }
});

const port = process.env.PORT || 8080;
app.listen(port, () => {
    console.log(`Server listening on port ${port}`);
});
