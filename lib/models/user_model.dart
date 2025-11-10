import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String? name;
  final String? email;
  final String? phoneNumber;
  final String? slug;
  final String? bio;
  final String? profilePictureUrl;
  final DateTime? createdAt;

  User({
    required this.id,
    this.name,
    this.email,
    this.phoneNumber,
    this.slug,
    this.bio,
    this.profilePictureUrl,
    this.createdAt,
  });

  // Factory constructor to create a User from a Firestore document
  factory User.fromFirestore(Map<String, dynamic> data, String documentId) {
    return User(
      id: documentId,
      name: data['name'] as String?,
      email: data['email'] as String?,
      phoneNumber: data['phoneNumber'] as String?,
      slug: data['slug'] as String?,
      bio: data['bio'] as String?,
      profilePictureUrl: data['profilePictureUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  // Factory constructor to create a User from JSON (e.g., from the backend API)
  factory User.fromJson(Map<String, dynamic> json) {
    if (json['id'] == null) {
      throw const FormatException('User JSON response is missing an ID.');
    }

    final dynamic createdAtRaw = json['createdAt'];
    DateTime? createdAt;
    if (createdAtRaw is String) {
      createdAt = DateTime.tryParse(createdAtRaw);
    } else if (createdAtRaw is Timestamp) {
      createdAt = createdAtRaw.toDate();
    }

    return User(
      id: json['id'] as String,
      name: json['name'] as String?,
      email: json['email'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      slug: json['slug'] as String?,
      bio: json['bio'] as String?,
      profilePictureUrl: json['profilePictureUrl'] as String?,
      createdAt: createdAt,
    );
  }

  // Method to convert a User object to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (slug != null) 'slug': slug,
      if (bio != null) 'bio': bio,
      if (profilePictureUrl != null) 'profilePictureUrl': profilePictureUrl,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }

  // Method to convert a User object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'slug': slug,
      'bio': bio,
      'profilePictureUrl': profilePictureUrl,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
