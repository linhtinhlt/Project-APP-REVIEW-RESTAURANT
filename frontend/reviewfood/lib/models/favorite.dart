import 'restaurant.dart';

class Favorite {
  final int id;
  final Restaurant restaurant;

  Favorite({required this.id, required this.restaurant});

  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      id: json['id'],
      restaurant: Restaurant.fromJson(json['restaurant']),
    );
  }
}
