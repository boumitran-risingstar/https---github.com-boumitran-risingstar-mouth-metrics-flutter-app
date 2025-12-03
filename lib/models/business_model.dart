import 'package:cloud_firestore/cloud_firestore.dart';

class Business {
  final String id;
  final String name;
  final String description;
  final String image;
  final List<String> services;
  final GeoPoint location;
  final String category;
  final String ownerId;
  final String geohash;

  Business({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    required this.services,
    required this.location,
    required this.category,
    required this.ownerId,
    required this.geohash,
  });

  factory Business.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Business(
      id: documentId,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      image: data['image'] ?? '',
      services: List<String>.from(data['services'] ?? []),
      location: data['location'] ?? const GeoPoint(0, 0),
      category: data['category'] ?? '',
      ownerId: data['ownerId'] ?? '',
      geohash: data['geohash'] ?? '',
    );
  }

  factory Business.fromJson(Map<String, dynamic> json) {
    final locationData = json['location'] as Map<String, dynamic>; 
    final geoPoint = GeoPoint(
      locationData['_latitude'] as double,
      locationData['_longitude'] as double,
    );

    return Business(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      image: json['image'] as String,
      services: List<String>.from(json['services'] as List),
      location: geoPoint,
      category: json['category'] as String,
      ownerId: json['ownerId'] as String,
      geohash: json['geohash'] as String,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'image': image,
      'services': services,
      'location': location,
      'category': category,
      'ownerId': ownerId,
      'geohash': geohash,
    };
  }
}
