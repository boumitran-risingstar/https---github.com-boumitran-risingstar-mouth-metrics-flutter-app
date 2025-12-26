
class Comment {
  final String id;
  final String articleId;
  final String authorId;
  final String authorName;
  final String? authorProfilePicture; // Nullable for users without a profile picture
  final String content;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.articleId,
    required this.authorId,
    required this.authorName,
    this.authorProfilePicture,
    required this.content,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['_id'], // Assuming the backend sends the ID as '_id'
      articleId: json['articleId'],
      authorId: json['author']['uid'], // Assuming author details are nested
      authorName: json['author']['name'],
      authorProfilePicture: json['author']['profilePictureUrl'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
