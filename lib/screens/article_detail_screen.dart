
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:mouth_metrics/models/article_model.dart';
import 'package:mouth_metrics/models/article_status.dart';
import 'package:mouth_metrics/models/comment_model.dart';
import 'package:mouth_metrics/services/article_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class ArticleDetailScreen extends StatefulWidget {
  final String articleId;

  const ArticleDetailScreen({super.key, required this.articleId});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  final ArticleService _articleService = ArticleService();
  final _commentController = TextEditingController();
  final _reviewerEmailController = TextEditingController();
  late Future<Article?> _articleFuture;
  late Future<List<Comment>> _commentsFuture;
  bool _isPostingComment = false;

  @override
  void initState() {
    super.initState();
    _loadArticleAndComments();
  }

  void _loadArticleAndComments() {
    _articleFuture = _articleService.getArticleById(widget.articleId);
    _commentsFuture = _articleService.getComments(widget.articleId);
  }

  Future<void> _postComment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to comment.')),
      );
      return;
    }

    if (_commentController.text.trim().isEmpty) {
      return;
    }

    setState(() {
      _isPostingComment = true;
    });

    final newComment = await _articleService.addComment(
      widget.articleId,
      _commentController.text.trim(),
    );

    if (newComment != null && mounted) {
      _commentController.clear();
      // Refresh the comments list
      setState(() {
        _commentsFuture = _articleService.getComments(widget.articleId);
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to post comment. Please try again.')),
      );
    }

    if (mounted) {
      setState(() {
        _isPostingComment = false;
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _reviewerEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Article'),
      ),
      body: FutureBuilder<Article?>(
        future: _articleFuture,
        builder: (context, articleSnapshot) {
          if (articleSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (articleSnapshot.hasError || !articleSnapshot.hasData) {
            return const Center(child: Text('Article not found or failed to load.'));
          }

          final article = articleSnapshot.data!;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusBadge(article.status),
                      const SizedBox(height: 8),
                      Text(
                        article.title,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Published on ${article.createdAt.toLocal().toString().split(' ')[0]}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      if (article.inReview)
                        _buildReviewSection(article),
                      MarkdownBody(
                        data: article.content,
                        selectable: true,
                        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                          p: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      Text(
                        'Comments',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
              ),
              _buildCommentsSection(),
              SliverToBoxAdapter(
                child: _buildCommentInputField(),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _buildCustomFAB(),
    );
  }

  Widget _buildStatusBadge(ArticleStatus status) {
    Color color;
    String text;
    switch (status) {
      case ArticleStatus.draft:
        color = Colors.grey;
        text = 'Draft';
        break;
      case ArticleStatus.inReview:
        color = Colors.orange;
        text = 'In Review';
        break;
      case ArticleStatus.approved:
        color = Colors.green;
        text = 'Approved';
        break;
      case ArticleStatus.rejected:
        color = Colors.red;
        text = 'Rejected';
        break;
    }

    return Chip(
      label: Text(text),
      backgroundColor: color,
      labelStyle: const TextStyle(color: Colors.white),
    );
  }


  Widget _buildReviewSection(Article article) {
    final user = FirebaseAuth.instance.currentUser;
    final isReviewer = article.reviewers.contains(user?.uid);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reviewers',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        ...article.reviewers.map((reviewerId) => Text(reviewerId)),
        const SizedBox(height: 16),
        if (isReviewer)
          Row(
            children: [
              ElevatedButton(
                onPressed: () => _approveArticle(article.id),
                child: const Text('Approve'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _rejectArticle(article.id),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Reject'),
              ),
            ],
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _approveArticle(String articleId) async {
    final success = await _articleService.approveArticle(articleId);
    if (success && mounted) {
      setState(() {
        _loadArticleAndComments();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Article approved!'), backgroundColor: Colors.green),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to approve article.'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _rejectArticle(String articleId) async {
    final success = await _articleService.rejectArticle(articleId);
    if (success && mounted) {
      setState(() {
        _loadArticleAndComments();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Article rejected!'), backgroundColor: Colors.orange),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to reject article.'), backgroundColor: Colors.red),
      );
    }
  }

  void _showInviteReviewerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite a Reviewer'),
        content: TextField(
          controller: _reviewerEmailController,
          decoration: const InputDecoration(
            labelText: 'Reviewer\'s Email',
            hintText: 'Enter the email address of the reviewer',
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _inviteReviewer(_reviewerEmailController.text);
            },
            child: const Text('Invite'),
          ),
        ],
      ),
    );
  }

  Future<void> _inviteReviewer(String email) async {
    if (email.isEmpty) return;

    final reviewerId = await _articleService.findUserByEmail(email);

    if (reviewerId != null) {
      final success = await _articleService.inviteReviewer(widget.articleId, reviewerId);
      if (success && mounted) {
        setState(() {
          _loadArticleAndComments();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reviewer invited!'), backgroundColor: Colors.green),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to invite reviewer.'), backgroundColor: Colors.red),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not found.'), backgroundColor: Colors.red),
      );
    }
  }


  Widget _buildCommentsSection() {
    return FutureBuilder<List<Comment>>(
      future: _commentsFuture,
      builder: (context, commentSnapshot) {
        if (commentSnapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (commentSnapshot.hasError) {
          return const SliverToBoxAdapter(
            child: Center(child: Text('Could not load comments.')),
          );
        }

        final comments = commentSnapshot.data ?? [];

        if (comments.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32.0),
              child: Center(child: Text('Be the first to comment!')),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildCommentItem(comments[index]),
            childCount: comments.length,
          ),
        );
      },
    );
  }

  Widget _buildCommentItem(Comment comment) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundImage: comment.authorProfilePicture != null
                ? NetworkImage(comment.authorProfilePicture!)
                : null,
            child: comment.authorProfilePicture == null
                ? const Icon(Icons.person)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.authorName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeago.format(comment.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment.content),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInputField() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const SizedBox.shrink(); // Don't show input field if not logged in
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: 'Add a comment...',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _postComment(),
            ),
          ),
          const SizedBox(width: 8),
          _isPostingComment
              ? const CircularProgressIndicator()
              : IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _postComment,
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildCustomFAB() {
    return FutureBuilder<Article?>(
      future: _articleFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final article = snapshot.data!;
        final isAuthor = article.authorId == FirebaseAuth.instance.currentUser?.uid;

        if (isAuthor) {
          return FloatingActionButton.extended(
            onPressed: _showInviteReviewerDialog,
            label: const Text('Invite Reviewer'),
            icon: const Icon(Icons.person_add),
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }
}
