const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { Storage } = require('@google-cloud/storage');

admin.initializeApp();

const db = admin.firestore();
const storage = new Storage();
const profilesBucket = storage.bucket('user-profile-pages');

exports.profileHandler = functions.https.onRequest(async (req, res) => {
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method === 'OPTIONS') {
        return res.status(204).send('');
    }

    const pathParts = req.path.split('/').filter(part => part.length > 0);

    if (pathParts.length < 2 || pathParts[0] !== 'profiles') {
        return res.status(404).send('Not Found: Invalid profile path.');
    }

    const requestedSlug = pathParts[1].replace('.html', '');

    try {
        const usersRef = db.collection('users');
        const currentUserSnapshot = await usersRef.where('slug', '==', requestedSlug).limit(1).get();

        if (!currentUserSnapshot.empty) {
            const fileName = `${requestedSlug}.html`;
            const file = profilesBucket.file(fileName);
            const [exists] = await file.exists();

            if (exists) {
                res.set('Cache-Control', 'public, max-age=300, s-maxage=600');
                res.setHeader('Content-Type', 'text/html');
                file.createReadStream()
                    .on('error', (err) => {
                        console.error('Error streaming file from GCS:', err);
                        res.status(500).send('Internal Server Error');
                    })
                    .pipe(res);
                return;
            }
        }

        const oldUserSnapshot = await usersRef.where('slugHistory', 'array-contains', requestedSlug).limit(1).get();

        if (!oldUserSnapshot.empty) {
            const userData = oldUserSnapshot.docs[0].data();
            const currentSlug = userData.slug;

            if (currentSlug) {
                const newUrl = `/profiles/${currentSlug}`;
                res.set('Cache-Control', 'public, max-age=3600, s-maxage=86400');
                res.redirect(301, newUrl);
                return;
            }
        }

        res.status(404).send('Profile not found.');

    } catch (error) {
        console.error('Error in profileHandler:', error);
        res.status(500).send('Internal Server Error');
    }
});
