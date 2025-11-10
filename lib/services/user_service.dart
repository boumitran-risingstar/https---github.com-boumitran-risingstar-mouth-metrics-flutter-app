
import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:mouth_metrics/models/user_model.dart' as app_user;

class UserService {
  final String _baseUrl =
      'https://user-service-402886834615.us-central1.run.app';
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final firebase_storage.FirebaseStorage _storage =
      firebase_storage.FirebaseStorage.instance;

  Future<String?> _getIdToken() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      developer.log('User not authenticated', name: 'user_service');
      return null;
    }
    return await user.getIdToken();
  }

    Future<String> uploadProfilePicture(String userId, File image) async {
    try {
      final ref = _storage.ref('profile_pictures/$userId/profile.jpg');
      await ref.putFile(image);
      final url = await ref.getDownloadURL();
      return url;
    } on firebase_storage.FirebaseException catch (e, s) {
      developer.log(
        'Error uploading profile picture',
        name: 'user_service.uploadProfilePicture',
        error: e,
        stackTrace: s,
      );
      throw Exception('Failed to upload profile picture: $e');
    }
  }

  Future<app_user.User?> syncUser() async {
    final idToken = await _getIdToken();
    if (idToken == null) {
      throw Exception('Not authenticated');
    }

    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Not authenticated');
    }

    final displayName = user.displayName;
    final phoneNumber = user.phoneNumber;

    String nameToSync;
    if (displayName != null && displayName.isNotEmpty) {
      nameToSync = displayName;
    } else if (phoneNumber != null && phoneNumber.isNotEmpty) {
      nameToSync = phoneNumber;
    } else {
      nameToSync = 'user';
    }

    developer.log('Attempting to sync user', name: 'user_service');
    final syncUrl = Uri.parse('$_baseUrl/users/sync');
    developer.log('Calling API: $syncUrl with name: $nameToSync', name: 'user_service');

    try {
      final response = await http.post(
        syncUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
          'Cache-Control': 'no-cache',
        },
        body: jsonEncode({'displayName': nameToSync}),
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
        'Cache-Control': 'no-cache',
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

  Future<void> updateUser(String uid, {String? name, String? bio, String? email, String? profilePictureUrl}) async {
    final idToken = await _getIdToken();
    if (idToken == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.put(
      Uri.parse('$_baseUrl/users/$uid'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
        'Cache-Control': 'no-cache',
      },
      body: jsonEncode({
        if (name != null) 'name': name,
        if (bio != null) 'bio': bio,
        if (email != null) 'email': email,
        if (profilePictureUrl != null) 'profilePictureUrl': profilePictureUrl,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update user: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    try {
      // First, get the internal user data to find the slug
      final appUser = await getUser(user.uid);
      final slug = appUser?.slug;

      if (slug == null || slug.isEmpty) {
        // This can happen if the user was created before slugs existed.
        // Sync the user to generate a slug, then fetch the profile.
        final syncedUser = await syncUser();
        final newSlug = syncedUser?.slug;
        if (newSlug == null || newSlug.isEmpty) {
          throw Exception('Could not find or generate a user slug.');
        }
        return await _fetchPublicProfile(newSlug);
      } else {
        // Use the existing slug
        return await _fetchPublicProfile(slug);
      }
    } catch (e, s) {
      developer.log(
        'Error getting user profile',
        name: 'user_service.getUserProfile',
        error: e,
        stackTrace: s,
      );
      throw Exception('Failed to get user profile: $e');
    }
  }

  // Helper method to fetch the public profile by slug
  Future<Map<String, dynamic>> _fetchPublicProfile(String slug) async {
    final profileUrl = Uri.parse('$_baseUrl/profile/$slug');
    developer.log(
      'Fetching public profile from: $profileUrl',
      name: 'user_service',
    );

    final response = await http.get(
      profileUrl,
      headers: {'Cache-Control': 'no-cache'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      developer.log(
        'Failed to fetch public profile',
        name: 'user_service._fetchPublicProfile',
        error: 'Status code: ${response.statusCode}\nBody: ${response.body}',
        level: 1000,
      );
      throw Exception(
        'Failed to load profile for slug $slug: ${response.body}',
      );
    }
  }
}
