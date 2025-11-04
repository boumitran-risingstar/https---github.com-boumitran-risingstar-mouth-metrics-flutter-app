
class Business {
  final String id;
  final String name;
  final String ownerId;
  // Add other business-related fields here

  Business({required this.id, required this.name, required this.ownerId});

  factory Business.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Business(
      id: documentId,
      name: data['name'] ?? '',
      ownerId: data['ownerId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'ownerId': ownerId,
    };
  }
}

