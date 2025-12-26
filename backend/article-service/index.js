const express = require('express');
const { Firestore } = require('@google-cloud/firestore');
const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
try {
  admin.initializeApp();
} catch (error) {
  if (error.code !== 'app/duplicate-app') {
    console.error('Firebase admin initialization error', error);
  }
}

const app = express();
app.use(express.json());
const port = process.env.PORT || 8080;

// Initialize Firestore
const firestore = new Firestore();
const articlesCollection = firestore.collection('articles');
const commentsCollection = firestore.collection('comments');

// Middleware for authentication
const authenticate = async (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).send('Unauthorized: No token provided');
  }

  const idToken = authHeader.split('Bearer ')[1];
  try {
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    req.user = decodedToken;
    next();
  } catch (error) {
    console.error('Error verifying token:', error);
    return res.status(403).send('Forbidden: Invalid token');
  }
};

app.get('/', (req, res) => {
  res.send('Article service is running!');
});

// Create a new draft article
app.post('/api/articles', authenticate, async (req, res) => {
  try {
    const { title, content } = req.body;
    const authorId = req.user.uid;

    if (!title || !content) {
      return res.status(400).send('Title and content are required.');
    }

    const newArticle = {
      title,
      content,
      authorId,
      status: 'draft',
      reviewers: [],
      approvals: [],
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    const docRef = await articlesCollection.add(newArticle);
    res.status(201).send({ id: docRef.id, ...newArticle });
  } catch (error) {
    console.error('Error creating article:', error);
    res.status(500).send('Internal Server Error');
  }
});

// Update an article
app.put('/api/articles/:id', authenticate, async (req, res) => {
  try {
    const { id } = req.params;
    const { title, content } = req.body;
    const userId = req.user.uid;

    const docRef = articlesCollection.doc(id);
    const doc = await docRef.get();

    if (!doc.exists) {
      return res.status(404).send('Article not found.');
    }

    const article = doc.data();

    if (article.authorId !== userId) {
      return res.status(403).send('Forbidden: You are not the author of this article.');
    }

    const updatedArticle = {
      title: title || article.title,
      content: content || article.content,
      updatedAt: new Date(),
    };

    await docRef.update(updatedArticle);
    res.status(200).send({ id, ...updatedArticle });

  } catch (error) {
    console.error('Error updating article:', error);
    res.status(500).send('Internal Server Error');
  }
});

// Get article details
app.get('/api/articles/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const doc = await articlesCollection.doc(id).get();
    if (!doc.exists) {
      return res.status(404).send('Article not found');
    }
    res.status(200).send({ id: doc.id, ...doc.data() });
  } catch (error) {
    console.error('Error getting article:', error);
    res.status(500).send('Internal Server Error');
  }
});

// List all articles (published)
app.get('/api/articles', async (req, res) => {
  try {
    const snapshot = await articlesCollection.where('status', '==', 'published').get();
    const articles = [];
    snapshot.forEach(doc => {
      articles.push({ id: doc.id, ...doc.data() });
    });
    res.status(200).send(articles);
  } catch (error) {
    console.error('Error listing articles:', error);
    res.status(500).send('Internal Server Error');
  }
});

// Add a comment to an article
app.post('/api/articles/:id/comments', authenticate, async (req, res) => {
  try {
    const { id: articleId } = req.params;
    const { content, parentCommentId } = req.body;
    const authorId = req.user.uid;

    if (!content) {
      return res.status(400).send('Comment content is required.');
    }

    const newComment = {
      articleId,
      authorId,
      content,
      parentCommentId: parentCommentId || null,
      createdAt: new Date(),
    };

    const docRef = await commentsCollection.add(newComment);
    res.status(201).send({ id: docRef.id, ...newComment });
  } catch (error) {
    console.error('Error adding comment:', error);
    res.status(500).send('Internal Server Error');
  }
});


// Invite a reviewer to an article
app.post('/api/articles/:id/invite', authenticate, async (req, res) => {
    try {
        const { id } = req.params;
        const { reviewerId } = req.body;
        const userId = req.user.uid;

        const docRef = articlesCollection.doc(id);
        const doc = await docRef.get();

        if (!doc.exists) {
            return res.status(404).send('Article not found.');
        }

        const article = doc.data();

        if (article.authorId !== userId) {
            return res.status(403).send('Forbidden: You are not the author of this article.');
        }

        if (article.reviewers.includes(reviewerId)) {
            return res.status(400).send('This user is already a reviewer.');
        }

        await docRef.update({
            reviewers: admin.firestore.FieldValue.arrayUnion(reviewerId)
        });

        res.status(200).send({ message: 'Reviewer invited successfully.' });

    } catch (error) {
        console.error('Error inviting reviewer:', error);
        res.status(500).send('Internal Server Error');
    }
});

// Approve an article
app.post('/api/articles/:id/approve', authenticate, async (req, res) => {
    try {
        const { id } = req.params;
        const userId = req.user.uid;

        const docRef = articlesCollection.doc(id);
        const doc = await docRef.get();

        if (!doc.exists) {
            return res.status(404).send('Article not found.');
        }

        const article = doc.data();

        if (!article.reviewers.includes(userId)) {
            return res.status(403).send('Forbidden: You are not a reviewer for this article.');
        }

        if (article.approvals.includes(userId)) {
            return res.status(400).send('You have already approved this article.');
        }

        await docRef.update({
            approvals: admin.firestore.FieldValue.arrayUnion(userId)
        });
        
        // Check if the article has enough approvals to be published
        if (article.approvals.length + 1 >= 3) {
            // Auto-publish logic will be handled by a cloud function for robustness
        }

        res.status(200).send({ message: 'Article approved successfully.' });

    } catch (error) {
        console.error('Error approving article:', error);
        res.status(500).send('Internal Server Error');
    }
});

app.listen(port, () => {
  console.log(`Article service listening on port ${port}`);
});
