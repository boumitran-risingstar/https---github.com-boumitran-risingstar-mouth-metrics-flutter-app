
class Article {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final String status;
  final DateTime createdAt;

  Article({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.status,
    required this.createdAt,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['_id'], // The backend uses _id
      title: json['title'],
      content: json['content'],
      authorId: json['authorId'],
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
