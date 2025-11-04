const express = require('express');
const admin = require('firebase-admin');
const cors = require('cors');

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
    res.status(200).send({ id: userDoc.id, ...userDoc.data() });
  } catch (error) {
    console.error('Error getting user:', error);
    res.status(500).send('Error getting user data');
  }
});


// POST to create/sync user after authentication
app.post('/users/sync', authenticate, async (req, res) => {
  console.log('Syncing user...');
  const { uid, phone_number, email } = req.user; // Data from the ID token
  const { displayName } = req.body; // Additional data from request body

  try {
    const userDocRef = usersCollection.doc(uid);
    const userDoc = await userDocRef.get();

    if (userDoc.exists) {
      console.log('User already exists');
      // User already exists, return existing data
      res.status(200).send({ id: userDoc.id, ...userDoc.data() });
    } else {
      console.log('Creating new user');
      // User does not exist, create a new document
      const newUser = {
        name: displayName || 'New User', // Use display name from body or default
        email: email || null,
        phoneNumber: phone_number,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      };
      await userDocRef.set(newUser);
      res.status(201).send({ id: uid, ...newUser });
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
