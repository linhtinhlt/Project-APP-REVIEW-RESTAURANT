import 'user.dart';
import 'review.dart';

class Comment {
  final int id;
  final User user;
  final String content;
  final Review?
  review; // ✅ để hiển thị thông tin bài review mà comment thuộc về

  Comment({
    required this.id,
    required this.user,
    required this.content,
    this.review,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] ?? 0,
      user: User.fromJson(json['user'] ?? {}),
      content: json['content'] ?? '',
      review:
          json['review'] != null
              ? Review.fromJson(json['review'])
              : null, // ✅ lấy review kèm theo nếu có
    );
  }
}
