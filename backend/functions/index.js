const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onRequest } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const { getStorage } = require("firebase-admin/storage");
const slugify = require("slugify");

admin.initializeApp();

const db = admin.firestore();
const storage = getStorage();

const REGION = "us-central1";

// --- HTTPS Handlers for serving static content ---

exports.profileHandler = onRequest({ region: REGION }, async (req, res) => {
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
    const profilesBucket = storage.bucket('user-profile-pages');

    try {
        const usersRef = db.collection('users');
        let userSnapshot = await usersRef.where('slug', '==', requestedSlug).limit(1).get();

        if (!userSnapshot.empty) {
            const file = profilesBucket.file(`${requestedSlug}.html`);
            const [exists] = await file.exists();

            if (exists) {
                res.set('Cache-Control', 'public, max-age=300, s-maxage=600');
                res.setHeader('Content-Type', 'text/html');
                file.createReadStream().pipe(res);
                return;
            }
        }

        userSnapshot = await usersRef.where('slugHistory', 'array-contains', requestedSlug).limit(1).get();

        if (!userSnapshot.empty) {
            const userData = userSnapshot.docs[0].data();
            if (userData.slug) {
                res.set('Cache-Control', 'public, max-age=3600, s-maxage=86400');
                res.redirect(301, `/profile/${userData.slug}`);
                return;
            }
        }

        res.status(404).send('Profile not found.');
    } catch (error) {
        console.error('Error in profileHandler:', error);
        res.status(500).send('Internal Server Error');
    }
});

exports.businessProfileRedirect = onRequest({ region: REGION }, async (req, res) => {
    const slug = req.path.replace('/business', '');
    const businessPagesBucket = storage.bucket('business-profile-pages');

    try {
        let businessQuery = await db.collection('businesses').where('slug', '==', slug).limit(1).get();

        if (!businessQuery.empty) {
            const file = businessPagesBucket.file(`${slug.substring(1)}.html`);
            const [exists] = await file.exists();
            if (exists) {
                res.set('Cache-Control', 'public, max-age=300, s-maxage=600');
                res.setHeader('Content-Type', 'text/html');
                file.createReadStream().pipe(res);
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

exports.articleHandler = onRequest({ region: REGION }, async (req, res) => {
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
    const articlesBucket = storage.bucket('published-articles');

    try {
        const articleSnapshot = await db.collection('articles').where('slug', '==', requestedSlug).where('status', '==', 'published').limit(1).get();

        if (!articleSnapshot.empty) {
            const file = articlesBucket.file(`${requestedSlug}.html`);
            const [exists] = await file.exists();
            if (exists) {
                res.set('Cache-Control', 'public, max-age=300, s-maxage=600');
                res.setHeader('Content-Type', 'text/html');
                file.createReadStream().pipe(res);
                return;
            }
        }
        res.status(404).send('Article not found.');
    } catch (error) {
        console.error('Error in articleHandler:', error);
        res.status(500).send('Internal Server Error');
    }
});

// --- Firestore Trigger for Auto-Publishing ---

exports.autoPublishArticle = onDocumentUpdated("articles/{articleId}", async (event) => {
    const newValue = event.data.after.data();
    const previousValue = event.data.before.data();

    // Check if the article was just approved to meet the threshold and is not already published
    if (newValue.approvals.length >= 3 && newValue.status !== 'published' && newValue.approvals.length > previousValue.approvals.length) {
        
        const article = newValue;
        const slug = slugify(article.title, { lower: true, strict: true });
        const articlesBucket = storage.bucket('published-articles');

        const htmlContent = `
            <!DOCTYPE html>
            <html>
            <head>
                <title>${article.title}</title>
                <meta charset="utf-8">
                <meta name="viewport" content="width=device-width, initial-scale=1">
                <style>
                  body { font-family: sans-serif; margin: 2em; }
                </style>
            </head>
            <body>
                <h1>${article.title}</h1>
                <div>${article.content}</div>
            </body>
            </html>
        `;

        const file = articlesBucket.file(`${slug}.html`);
        await file.save(htmlContent, { contentType: 'text/html' });
        
        const publicUrl = `https://storage.googleapis.com/${articlesBucket.name}/${slug}.html`;

        return db.collection('articles').doc(event.params.articleId).update({
            status: 'published',
            slug: slug,
            publishedUrl: publicUrl,
        });
    }
    
    return null;
});
