import 'package:cloud_firestore/cloud_firestore.dart';

// Represents a single photo in the user's gallery
class Photo {
  final String id;
  final String url;
  final bool isDefault;
  final DateTime createdAt;

  Photo({
    required this.id,
    required this.url,
    required this.isDefault,
    required this.createdAt,
  });

  // Factory constructor to create a Photo from JSON
  factory Photo.fromJson(Map<String, dynamic> json) {
    if (json['id'] == null || json['url'] == null || json['isDefault'] == null || json['createdAt'] == null) {
      throw const FormatException('Photo JSON is missing required fields.');
    }

    final dynamic createdAtRaw = json['createdAt'];
    DateTime createdAt;
    if (createdAtRaw is String) {
      createdAt = DateTime.parse(createdAtRaw);
    } else if (createdAtRaw is Timestamp) {
      createdAt = createdAtRaw.toDate();
    } else if (createdAtRaw is Map<String, dynamic> && createdAtRaw.containsKey('_seconds')) {
      createdAt = Timestamp(createdAtRaw['_seconds'], createdAtRaw['_nanoseconds'] ?? 0).toDate();
    } 
    else {
      throw FormatException('Invalid format for createdAt in Photo JSON: $createdAtRaw');
    }

    return Photo(
      id: json['id'] as String,
      url: json['url'] as String,
      isDefault: json['isDefault'] as bool,
      createdAt: createdAt,
    );
  }

  // Method to convert a Photo object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class User {
  final String id;
  final String? name;
  final String? email;
  final String? phoneNumber;
  final String? slug;
  final String? bio;
  final String? profilePictureUrl;
  final DateTime? createdAt;
  final List<Photo> photoGallery; // New field for the photo gallery
  final String userType; // New field
  final GeoPoint? location; // New field

  User({
    required this.id,
    this.name,
    this.email,
    this.phoneNumber,
    this.slug,
    this.bio,
    this.profilePictureUrl,
    this.createdAt,
    this.photoGallery = const [], // Default to an empty list
    this.userType = 'Patient', // Default to 'Patient'
    this.location,
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
      photoGallery: (data['photoGallery'] as List<dynamic>?)
              ?.map((photoJson) => Photo.fromJson(photoJson as Map<String, dynamic>))
              .toList() ??
          const [],
      userType: data['userType'] as String? ?? 'Patient',
      location: data['location'] as GeoPoint?,
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
    } else if (createdAtRaw is Map<String, dynamic> && createdAtRaw.containsKey('_seconds')) {
        createdAt = Timestamp(createdAtRaw['_seconds'], createdAtRaw['_nanoseconds'] ?? 0).toDate();
    }

    // Parse the photo gallery
    final List<Photo> gallery = (json['photoGallery'] as List<dynamic>?)
            ?.map((photoJson) => Photo.fromJson(photoJson as Map<String, dynamic>))
            .toList() ??
        const [];

    // Parse location
    GeoPoint? location;
    if (json['location'] is Map) {
      final locMap = json['location'] as Map<String, dynamic>;
      if (locMap.containsKey('_latitude') && locMap.containsKey('_longitude')) {
          location = GeoPoint(locMap['_latitude'], locMap['_longitude']);
      }
    } else if (json['location'] is GeoPoint) {
        location = json['location'];
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
      photoGallery: gallery,
      userType: json['userType'] as String? ?? 'Patient',
      location: location,
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
      'photoGallery': photoGallery.map((p) => p.toJson()).toList(),
      'userType': userType,
      if (location != null) 'location': location,
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
      'photoGallery': photoGallery.map((p) => p.toJson()).toList(),
      'userType': userType,
      if (location != null) 'location': {
          '_latitude': location!.latitude,
          '_longitude': location!.longitude,
      },
    };
  }
}
