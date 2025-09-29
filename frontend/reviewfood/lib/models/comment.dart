import 'user.dart';

class Comment {
  final int id;
  final User user;
  final String content;

  Comment({
    required this.id,
    required this.user,
    required this.content,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      user: User.fromJson(json['user']),
      content: json['content'],
    );
  }
}
