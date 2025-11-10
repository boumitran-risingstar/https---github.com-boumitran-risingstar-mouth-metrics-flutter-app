const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

const db = admin.firestore();

/**
 * This function handles redirects for old user profile slugs.
 * It's triggered when a request is made to a path under /profiles/ that
 * does not match a static file in Firebase Hosting.
 */
exports.redirectHandler = functions.https.onRequest(async (req, res) => {
  // Extract the slug from the path, e.g., "old-slug-123.html" -> "old-slug-123"
  const pathParts = req.path.split('/').filter(part => part.length > 0);
  if (pathParts.length !== 2 || pathParts[0] !== 'profiles') {
      return res.status(404).send('Not Found');
  }
  
  const requestedSlugWithHtml = pathParts[1];
  const requestedSlug = requestedSlugWithHtml.replace('.html', '');

  try {
    // Query the users collection to find a user with this slug in their history
    const querySnapshot = await db.collection('users')
                                  .where('slugHistory', 'array-contains', requestedSlug)
                                  .limit(1)
                                  .get();

    if (querySnapshot.empty) {
      // If no user is found with that old slug, it's a true 404
      return res.status(404).send('Profile not found.');
    }

    // If a user is found, get their current slug and redirect
    const userData = querySnapshot.docs[0].data();
    const currentSlug = userData.currentSlug;
    
    if (!currentSlug) {
        // This is an edge case, but good to handle
        return res.status(404).send('Profile not found; current URL is not set.');
    }

    // Construct the new URL and issue a permanent redirect
    const newUrl = `/profiles/${currentSlug}.html`;
    res.set('Cache-Control', 'public, max-age=3600, s-maxage=86400');
    res.redirect(301, newUrl);

  } catch (error) {
    console.error('Error in redirectHandler:', error);
    res.status(500).send('Internal Server Error');
  }
});

/**
 * This function serves public user profile data.
 * It's triggered by a GET request to /profile/:slug
 * It handles CORS to allow requests from the web app.
 */
exports.getPublicProfile = functions.https.onRequest(async (req, res) => {
    // Set CORS headers for preflight and actual requests
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method === 'OPTIONS') {
        // Stop processing preflight requests
        return res.status(204).send('');
    }

    const slug = req.path.split('/').pop();
    if (!slug) {
        return res.status(400).send('Slug not provided.');
    }

    try {
        const usersRef = db.collection('users');
        const snapshot = await usersRef.where('slug', '==', slug).limit(1).get();

        if (snapshot.empty) {
            return res.status(404).send('User not found.');
        }

        const userDoc = snapshot.docs[0];
        const userData = userDoc.data();

        // Return only public data
        res.status(200).json({
            name: userData.name,
            slug: userData.slug,
        });

    } catch (error) {
        console.error('Error in getPublicProfile:', error);
        res.status(500).send('Internal Server Error');
    }
});
