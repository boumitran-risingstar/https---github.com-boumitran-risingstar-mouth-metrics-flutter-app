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
