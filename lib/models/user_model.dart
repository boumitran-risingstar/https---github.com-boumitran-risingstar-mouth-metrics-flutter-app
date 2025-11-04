import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String? name;
  final String? email;
  final String? phoneNumber;
  final DateTime? createdAt;

  User({
    required this.id,
    this.name,
    this.email,
    this.phoneNumber,
    this.createdAt,
  });

  // Factory constructor to create a User from a Firestore document
  factory User.fromFirestore(Map<String, dynamic> data, String documentId) {
    return User(
      id: documentId,
      name: data['name'] as String?,
      email: data['email'] as String?,
      phoneNumber: data['phoneNumber'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  // Factory constructor to create a User from JSON (e.g., from the backend API)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String?,
      email: json['email'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String) 
          : null,
    );
  }

  // Method to convert a User object to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }
}
