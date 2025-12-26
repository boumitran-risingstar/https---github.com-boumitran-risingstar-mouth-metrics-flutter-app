
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mouth_metrics/models/article_model.dart';
import 'package:mouth_metrics/services/article_service.dart';

class ArticleListScreen extends StatefulWidget {
  const ArticleListScreen({super.key});

  @override
  State<ArticleListScreen> createState() => _ArticleListScreenState();
}

class _ArticleListScreenState extends State<ArticleListScreen> {
  final ArticleService _articleService = ArticleService();
  late Future<List<Article>> _articlesFuture;

  @override
  void initState() {
    super.initState();
    _articlesFuture = _articleService.getArticles();
  }

  void _refreshArticles() {
    setState(() {
      _articlesFuture = _articleService.getArticles();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Articles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshArticles,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: FutureBuilder<List<Article>>(
        future: _articlesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No articles found.'));
          }

          final articles = snapshot.data!;

          return ListView.builder(
            itemCount: articles.length,
            itemBuilder: (context, index) {
              final article = articles[index];
              return ListTile(
                title: Text(article.title),
                subtitle: Text(
                  'Published on ${article.createdAt.toLocal().toString().split(' ')[0]}',
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  context.push('/articles/${article.id}');
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Navigate and refresh the list when the user returns
          await context.push('/create-article');
          _refreshArticles();
        },
        label: const Text('Create Article'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
