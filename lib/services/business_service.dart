import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mouth_metrics/models/business_model.dart';

class BusinessService {
  final String _baseUrl = 'https://business-service-402886834615.us-central1.run.app';

  Future<String?> _getIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return null;
    }
    return await user.getIdToken();
  }

  // Create a new business
  Future<Business> createBusiness(Business business) async {
    final idToken = await _getIdToken();
    if (idToken == null) {
      throw Exception('User not authenticated');
    }

    final uri = Uri.parse('$_baseUrl/api/businesses');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: json.encode(business.toFirestore()),
    );

    if (response.statusCode == 201) {
      return Business.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create business');
    }
  }

  // Update a business
  Future<Business> updateBusiness(Business business) async {
    final idToken = await _getIdToken();
    if (idToken == null) {
      throw Exception('User not authenticated');
    }

    final uri = Uri.parse('$_baseUrl/api/businesses/${business.id}');
    final response = await http.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: json.encode(business.toFirestore()),
    );

    if (response.statusCode == 200) {
      return Business.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update business');
    }
  }

  // Find nearby businesses
  Future<List<Business>> findNearbyBusinesses(double lat, double lng, {double radius = 10.0}) async {
    final idToken = await _getIdToken();
    if (idToken == null) {
      throw Exception('User not authenticated');
    }

    final uri = Uri.parse('$_baseUrl/api/businesses/nearby?lat=$lat&lng=$lng&radius=$radius');
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $idToken',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Business.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load nearby businesses');
    }
  }
}
