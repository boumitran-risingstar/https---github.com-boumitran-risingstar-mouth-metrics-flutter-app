import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mouth_metrics/models/business_model.dart';

class BusinessService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'businesses';

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
    await _firestore.collection(_collectionName).doc(business.id).update(business.toFirestore());
  }

  // Delete a business
  Future<void> deleteBusiness(String id) async {
    await _firestore.collection(_collectionName).doc(id).delete();
  }
}
