
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mouth_metrics/models/user_model.dart' as app_user;

class UserService {
  // Base URL for the Cloud Run service
  final String _serviceBaseUrl = 'https://user-service-402886834615.us-central1.run.app';
  // Path for the authenticated API endpoints
  final String _apiPath = '/api';
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
    if (idToken == null) throw Exception('Not authenticated');

    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final displayName = user.displayName;
    final phoneNumber = user.phoneNumber;
    String nameToSync = (displayName != null && displayName.isNotEmpty)
        ? displayName
        : (phoneNumber != null && phoneNumber.isNotEmpty ? phoneNumber : 'user');

    final syncUrl = Uri.parse('$_serviceBaseUrl$_apiPath/users/sync');
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
        return app_user.User.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to sync user: ${response.body}');
      }
    } catch (e) {
      developer.log('Error syncing user', name: 'user_service.syncUser', error: e);
      throw Exception('Failed to sync user: $e');
    }
  }

  Future<app_user.User?> getUser(String uid) async {
    final idToken = await _getIdToken();
    if (idToken == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('$_serviceBaseUrl$_apiPath/users/$uid'),
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

  Future<void> updateUser(String uid, {String? name, String? bio, String? email}) async {
    final idToken = await _getIdToken();
    if (idToken == null) throw Exception('Not authenticated');

    final response = await http.put(
      Uri.parse('$_serviceBaseUrl$_apiPath/users/$uid'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
        'Cache-Control': 'no-cache',
      },
      body: jsonEncode({
        if (name != null) 'name': name,
        if (bio != null) 'bio': bio,
        if (email != null) 'email': email,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update user: ${response.body}');
    }
  }

  // Uploads a photo and returns the updated photo gallery.
  Future<List<app_user.Photo>> uploadPhoto(String userId, File image) async {
    final idToken = await _getIdToken();
    if (idToken == null) throw Exception('Not authenticated');

    final url = Uri.parse('$_serviceBaseUrl$_apiPath/users/$userId/photos');
    final request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $idToken';
    request.files.add(
      await http.MultipartFile.fromPath(
        'photo',
        image.path,
        contentType: MediaType('image', image.path.split('.').last),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      final responseBody = jsonDecode(response.body);
      final List<dynamic> galleryJson = responseBody['gallery'];
      return galleryJson.map((json) => app_user.Photo.fromJson(json)).toList();
    } else {
      throw Exception('Failed to upload photo: ${response.body}');
    }
  }

  // Web-compatible method to upload a photo from a byte array (Uint8List)
  Future<List<app_user.Photo>> uploadPhotoFromBytes(String userId, Uint8List imageBytes, String filename) async {
    final idToken = await _getIdToken();
    if (idToken == null) throw Exception('Not authenticated');

    final url = Uri.parse('$_serviceBaseUrl$_apiPath/users/$userId/photos');
    final request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $idToken';

    request.files.add(
      http.MultipartFile.fromBytes(
        'photo',
        imageBytes,
        filename: filename, // Use the provided filename
        contentType: MediaType('image', filename.split('.').last),      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
        final responseBody = jsonDecode(response.body);
        final List<dynamic> galleryJson = responseBody['gallery'];
        return galleryJson.map((json) => app_user.Photo.fromJson(json)).toList();
    } else {
        throw Exception('Failed to upload photo from bytes: ${response.body}');
    }
  }


  // Sets a photo as default and returns the updated photo gallery.
  Future<List<app_user.Photo>> setDefaultPhoto(String userId, String photoId) async {
    final idToken = await _getIdToken();
    if (idToken == null) throw Exception('Not authenticated');

    final url = Uri.parse('$_serviceBaseUrl$_apiPath/users/$userId/photos/$photoId/default');
    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $idToken',
        'Cache-Control': 'no-cache',
      },
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      final List<dynamic> galleryJson = responseBody['gallery'];
      return galleryJson.map((json) => app_user.Photo.fromJson(json)).toList();
    } else {
      throw Exception('Failed to set default photo: ${response.body}');
    }
  }

  // Deletes a photo and returns the updated photo gallery.
  Future<List<app_user.Photo>> deletePhoto(String userId, String photoId) async {
    final idToken = await _getIdToken();
    if (idToken == null) throw Exception('Not authenticated');

    final url = Uri.parse('$_serviceBaseUrl$_apiPath/users/$userId/photos/$photoId');
    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $idToken',
        'Cache-Control': 'no-cache',
      },
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      final List<dynamic> galleryJson = responseBody['gallery'];
      return galleryJson.map((json) => app_user.Photo.fromJson(json)).toList();
    } else {
      throw Exception('Failed to delete photo: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    try {
      final appUser = await getUser(user.uid);
      final slug = appUser?.slug;

      if (slug == null || slug.isEmpty) {
        final syncedUser = await syncUser();
        final newSlug = syncedUser?.slug;
        if (newSlug == null || newSlug.isEmpty) {
          throw Exception('Could not find or generate a user slug.');
        }
        return await _fetchPublicProfile(newSlug);
      } else {
        return await _fetchPublicProfile(slug);
      }
    } catch (e) {
      developer.log('Error getting user profile', name: 'user_service.getUserProfile', error: e);
      throw Exception('Failed to get user profile: $e');
    }
  }

  // This helper uses the public-facing endpoint, which does NOT have the /api prefix.
  Future<Map<String, dynamic>> _fetchPublicProfile(String slug) async {
    final profileUrl = Uri.parse('$_serviceBaseUrl/profile/$slug');
    final response = await http.get(
      profileUrl,
      headers: {'cache-control': 'no-cache'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load profile for slug $slug: ${response.body}');
    }
  }
}
