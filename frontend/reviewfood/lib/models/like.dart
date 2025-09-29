import 'user.dart';

class Like {
  final int id;
  final User user;

  Like({required this.id, required this.user});

  factory Like.fromJson(Map<String, dynamic> json) {
    return Like(
      id: json['id'],
      user: User.fromJson(json['user']),
    );
  }
}
