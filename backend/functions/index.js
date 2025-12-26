const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { Storage } = require('@google-cloud/storage');
const slugify = require('slugify');

admin.initializeApp();

const db = admin.firestore();
const storage = new Storage();
const profilesBucket = storage.bucket('user-profile-pages');
const businessPagesBucket = storage.bucket('business-profile-pages');
const articlesBucket = storage.bucket('published-articles');

exports.profileHandler = functions.https.onRequest(async (req, res) => {
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method === 'OPTIONS') {
        return res.status(204).send('');
    }

    const pathParts = req.path.split('/').filter(part => part.length > 0);

    if (pathParts.length < 2 || pathParts[0] !== 'profile') {
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
                const newUrl = `/profile/${currentSlug}`;
                res.set('Cache-control', 'public, max-age=3600, s-maxage=86400');
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

exports.businessProfileRedirect = functions.https.onRequest(async (req, res) => {
    const slug = req.path.replace('/business', '');
    try {
        let businessQuery = await db.collection('businesses').where('slug', '==', slug).limit(1).get();

        if (!businessQuery.empty) {
            const fileName = `${slug.substring(1)}.html`;
            const file = businessPagesBucket.file(fileName);
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
            } else {
                // If file doesn't exist, maybe it hasn't been generated yet.
                // We can still try to redirect to the correct page.
                res.status(200).send("This would be the business profile page, but the static file is missing.");
                return;
            }
        }

        businessQuery = await db.collection('businesses').where('slugHistory', 'array-contains', slug).limit(1).get();

        if (!businessQuery.empty) {
            const business = businessQuery.docs[0].data();
            res.redirect(301, `/business${business.slug}`);
            return;
        }

        res.status(404).send("Business not found");

    } catch (error) {
        console.error('Error in businessProfileRedirect:', error);
        res.status(500).send("Internal Server Error");
    }
});

exports.autoPublishArticle = functions.firestore
    .document('articles/{articleId}')
    .onUpdate(async (change, context) => {
        const newValue = change.after.data();
        const previousValue = change.before.data();

        // Check if the article has just been approved
        if (newValue.approvals.length > previousValue.approvals.length && newValue.approvals.length >= 3 && newValue.status !== 'published') {
            const articleId = context.params.articleId;
            const article = newValue;

            // Generate a slug
            const slug = slugify(article.title, { lower: true, strict: true });

            // Generate static HTML
            const htmlContent = `
                <!DOCTYPE html>
                <html>
                <head>
                    <title>${article.title}</title>
                </head>
                <body>
                    <h1>${article.title}</h1>
                    <div>${article.content}</div>
                </body>
                </html>
            `;

            // Upload to Cloud Storage
            const fileName = `${slug}.html`;
            const file = articlesBucket.file(fileName);
            await file.save(htmlContent, { contentType: 'text/html' });
            const publicUrl = `https://storage.googleapis.com/${articlesBucket.name}/${fileName}`;

            // Update Firestore
            return db.collection('articles').doc(articleId).update({
                status: 'published',
                slug: slug,
                publishedUrl: publicUrl,
            });
        }
        return null;
    });

exports.articleHandler = functions.https.onRequest(async (req, res) => {
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method === 'OPTIONS') {
        return res.status(204).send('');
    }

    const pathParts = req.path.split('/').filter(part => part.length > 0);

    if (pathParts.length < 2 || pathParts[0] !== 'articles') {
        return res.status(404).send('Not Found: Invalid article path.');
    }

    const requestedSlug = pathParts[1].replace('.html', '');

    try {
        const articlesRef = db.collection('articles');
        const articleSnapshot = await articlesRef.where('slug', '==', requestedSlug).where('status', '==', 'published').limit(1).get();

        if (!articleSnapshot.empty) {
            const fileName = `${requestedSlug}.html`;
            const file = articlesBucket.file(fileName);
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

        res.status(404).send('Article not found.');

    } catch (error) {
        console.error('Error in articleHandler:', error);
        res.status(500).send('Internal Server Error');
    }
});
