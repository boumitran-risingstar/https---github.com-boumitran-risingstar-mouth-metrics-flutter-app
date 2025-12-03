import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mouth_metrics/models/business_model.dart';

class BusinessService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'businesses';
  final String _baseUrl = 'https://business-service-402886834615.us-central1.run.app';

  // Create a new business
  Future<void> createBusiness(Business business) async {
    await _firestore.collection(_collectionName).add(business.toFirestore());
  }

  // Get a business by ID
  Future<Business?> getBusiness(String id) async {
    final doc = await _firestore.collection(_collectionName).doc(id).get();
    if (doc.exists) {
      return Business.fromFirestore(doc.data()!, doc.id);
    }
    return null;
  }

  // Update a business
  Future<void> updateBusiness(Business business) async {
    await _firestore
        .collection(_collectionName)
        .doc(business.id)
        .update(business.toFirestore());
  }

  // Delete a business
  Future<void> deleteBusiness(String id) async {
    await _firestore.collection(_collectionName).doc(id).delete();
  }

  // Find nearby businesses
  Future<List<Business>> findNearbyBusinesses(double lat, double lng, {double radius = 10.0}) async {
    final uri = Uri.parse('$_baseUrl/api/businesses/nearby?lat=$lat&lng=$lng&radius=$radius');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Business.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load nearby businesses');
    }
  }
}
