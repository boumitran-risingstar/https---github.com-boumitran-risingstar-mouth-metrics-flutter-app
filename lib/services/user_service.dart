
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mouth_metrics/models/user_model.dart' as app_user;

class UserService {
  final String _baseUrl = 'https://user-service-ydrkozv2xa-uc.a.run.app'; 
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> _getIdToken() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      developer.log('User not authenticated', name: 'user_service');
      return null;
    }
    return await user.getIdToken();
  }

  Future<app_user.User?> syncUser() async {
    final idToken = await _getIdToken();
    if (idToken == null) {
      throw Exception('Not authenticated');
    }

    developer.log('Attempting to sync user', name: 'user_service');
    final syncUrl = Uri.parse('$_baseUrl/users/sync');
    developer.log('Calling API: $syncUrl', name: 'user_service');

    try {
      final response = await http.post(
        syncUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'displayName': _auth.currentUser?.displayName,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        developer.log('User synced successfully', name: 'user_service');
        return app_user.User.fromJson(jsonDecode(response.body));
      } else {
        developer.log(
          'Failed to sync user',
          name: 'user_service',
          error: 'Status code: ${response.statusCode}\nBody: ${response.body}',
          level: 1000,
        );
        throw Exception('Failed to sync user: ${response.body}');
      }
    } catch (e, s) {
      developer.log(
        'Error syncing user',
        name: 'user_service.syncUser',
        error: e,
        stackTrace: s,
      );
      throw Exception('Failed to sync user: $e');
    }
  }

  Future<app_user.User?> getUser(String uid) async {
    final idToken = await _getIdToken();
    if (idToken == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/users/$uid'),
      headers: {
        'Authorization': 'Bearer $idToken',
      },
    );

    if (response.statusCode == 200) {
      return app_user.User.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Failed to get user: ${response.body}');
    }
  }

  Future<void> updateUser(String uid, {String? name, String? email}) async {
    final idToken = await _getIdToken();
    if (idToken == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.put(
      Uri.parse('$_baseUrl/users/$uid'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        if (name != null) 'name': name,
        if (email != null) 'email': email,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update user: ${response.body}');
    }
  }
}
