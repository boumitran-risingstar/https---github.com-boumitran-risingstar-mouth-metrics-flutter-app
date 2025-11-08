const express = require('express');
const admin = require('firebase-admin');
const cors = require('cors');

const app = express();
const port = process.env.PORT || 8080;

// Explicitly whitelist allowed origins
const allowedOrigins = [
  'https://9000-firebase-mouth-metrics-app-1762189896766.cluster-zkm2jrwbnbd4awuedc2alqxrpk.cloudworkstations.dev',
  'https://mouthmetrics.32studio.org' // Deployed frontend
];

const corsOptions = {
  origin: (origin, callback) => {
    if (allowedOrigins.includes(origin) || !origin) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true,
};

// Use the CORS middleware with options
app.use(cors(corsOptions));
app.options('*', cors(corsOptions)); // Enable pre-flight for all routes

// Initialize Firebase Admin SDK
admin.initializeApp();

// Connect to the 'users' Firestore database
const db = admin.firestore();
const usersCollection = db.collection('users');


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
  res.send('User management service is running');
});

// Helper to format user data for response
const formatUserResponse = (doc) => {
    const data = doc.data();
    if (data.createdAt && typeof data.createdAt.toDate === 'function') {
        data.createdAt = data.createdAt.toDate().toISOString();
    }
    return { id: doc.id, ...data };
};


// GET a user profile by UID
app.get('/users/:uid', authenticate, async (req, res) => {
  const { uid } = req.params;

  // Ensure the authenticated user is requesting their own data
  if (req.user.uid !== uid) {
    return res.status(403).send('Forbidden: You can only request your own user data.');
  }

  try {
    const userDoc = await usersCollection.doc(uid).get();
    if (!userDoc.exists) {
      return res.status(404).send('User not found');
    }
    res.status(200).send(formatUserResponse(userDoc));
  } catch (error) {
    console.error('Error getting user:', error);
    res.status(500).send('Error getting user data');
  }
});


// POST to create/sync user after authentication
app.post('/users/sync', authenticate, async (req, res) => {
  console.log('Syncing user...');
  const { uid, phone_number } = req.user; // Data from the ID token

  try {
    const userDocRef = usersCollection.doc(uid);
    const userDoc = await userDocRef.get();

    if (userDoc.exists) {
      console.log('User already exists');
      // User already exists, return existing data formatted correctly
      res.status(200).send(formatUserResponse(userDoc));
    } else {
      console.log('Creating new user');
      // User does not exist, create a new document
      const newUserForDb = {
        phoneNumber: phone_number,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      };
      await userDocRef.set(newUserForDb);

      // Create a response object with a parsable date
      const newUserForResponse = {
          id: uid,
          phoneNumber: newUserForDb.phoneNumber,
          createdAt: new Date().toISOString(), // Send current time as ISO string
      };
      
      res.status(201).send(newUserForResponse);
    }
  } catch (error) {
    console.error('Error syncing user:', error);
    res.status(500).send('Error syncing user data');
  }
});


// PUT to update a user's profile
app.put('/users/:uid', authenticate, async (req, res) => {
  const { uid } = req.params;
  const { name, email } = req.body;

  if (req.user.uid !== uid) {
    return res.status(403).send('Forbidden: You can only update your own profile.');
  }

  try {
    const userDocRef = usersCollection.doc(uid);
    const updateData = {};
    if (name) updateData.name = name;
    if (email) updateData.email = email;
    
    await userDocRef.update(updateData);
    res.status(200).send({ message: 'User profile updated successfully' });
  } catch (error) {
    console.error('Error updating user profile:', error);
    res.status(500).send('Error updating user profile');
  }
});


app.listen(port, () => {
  console.log(`User service listening on port ${port}`);
});
