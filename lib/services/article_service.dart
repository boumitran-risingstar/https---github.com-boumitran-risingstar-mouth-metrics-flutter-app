
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mouth_metrics/models/article_model.dart';

class ArticleService {
  final String _baseUrl = 'http://127.0.0.1:3002'; // Local development URL for article-service

  Future<bool> createArticle(String title, String content) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in.');
    }

    final token = await user.getIdToken();
    final url = Uri.parse('$_baseUrl/api/articles');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'title': title,
          'content': content,
        }),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        print('Failed to create article: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error creating article: $e');
      return false;
    }
  }

  Future<List<Article>> getArticles() async {
    final url = Uri.parse('$_baseUrl/api/articles');

    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final List<dynamic> articleJson = jsonDecode(response.body);
        return articleJson.map((json) => Article.fromJson(json)).toList();
      } else {
        print('Failed to fetch articles: ${response.statusCode} ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error fetching articles: $e');
      return [];
    }
  }

  Future<Article?> getArticleById(String id) async {
    final url = Uri.parse('$_baseUrl/api/articles/$id');

    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        return Article.fromJson(jsonDecode(response.body));
      } else {
        print('Failed to fetch article: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching article: $e');
      return null;
    }
  }
}
