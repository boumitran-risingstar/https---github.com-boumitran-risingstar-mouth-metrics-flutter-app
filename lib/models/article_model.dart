
import 'package:mouth_metrics/models/article_status.dart';

class Article {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final DateTime createdAt;
  final ArticleStatus status; 
  final List<String> reviewers; 
  final List<String> approvals; 

  Article({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.createdAt,
    required this.status,
    this.reviewers = const [],
    this.approvals = const [],
  });

  bool get inReview => status == ArticleStatus.inReview;

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['_id'],
      title: json['title'],
      content: json['content'],
      authorId: json['authorId'],
      createdAt: DateTime.parse(json['createdAt']),
      status: ArticleStatus.values.firstWhere(
        (e) => e.toString() == 'ArticleStatus.' + (json['status'] ?? 'draft'),
        orElse: () => ArticleStatus.draft,
      ),
      reviewers: json['reviewers'] != null ? List<String>.from(json['reviewers']) : [],
      approvals: json['approvals'] != null ? List<String>.from(json['approvals']) : [],
    );
  }
}
