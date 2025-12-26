'''
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mouth_metrics/models/article_model.dart';
import 'package:mouth_metrics/models/comment_model.dart';

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

  Future<bool> updateArticle(String id, String title, String content) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in.');
    }

    final token = await user.getIdToken();
    final url = Uri.parse('$_baseUrl/api/articles/$id');

    try {
      final response = await http.put(
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

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Failed to update article: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error updating article: $e');
      return false;
    }
  }

  Future<List<Comment>> getComments(String articleId) async {
    final url = Uri.parse('$_baseUrl/api/articles/$articleId/comments');
    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
      });
      if (response.statusCode == 200) {
        final List<dynamic> commentsJson = jsonDecode(response.body);
        return commentsJson.map((json) => Comment.fromJson(json)).toList();
      } else {
        print('Failed to fetch comments: ${response.statusCode} ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error fetching comments: $e');
      return [];
    }
  }

  Future<Comment?> addComment(String articleId, String content) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');

    final token = await user.getIdToken();
    final url = Uri.parse('$_baseUrl/api/articles/$articleId/comments');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'content': content}),
      );

      if (response.statusCode == 201) {
        return Comment.fromJson(jsonDecode(response.body));
      } else {
        print('Failed to add comment: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error adding comment: $e');
      return null;
    }
  }

  Future<bool> inviteReviewer(String articleId, String reviewerId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');

    final token = await user.getIdToken();
    final url = Uri.parse('$_baseUrl/api/articles/$articleId/invite');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'reviewerId': reviewerId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error inviting reviewer: $e');
      return false;
    }
  }

  Future<bool> approveArticle(String articleId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');

    final token = await user.getIdToken();
    final url = Uri.parse('$_baseUrl/api/articles/$articleId/approve');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error approving article: $e');
      return false;
    }
  }

  Future<bool> rejectArticle(String articleId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');

    final token = await user.getIdToken();
    final url = Uri.parse('$_baseUrl/api/articles/$articleId/reject');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error rejecting article: $e');
      return false;
    }
  }

  Future<String?> findUserByEmail(String email) async {
    final url = Uri.parse('$_baseUrl/api/users/by-email/$email');
    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
      });
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['uid'];
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
''