class Restaurant {
  final int id;
  final String name;
  final String address;
  final String? description;
  final double? latitude;
  final double? longitude;
  final String? imageUrl;
  double? distance;
  final double? avgRating; // ✅ thêm trường trung bình rating
  final int? reviewsCount;

  // ✅ favorite
  bool isFavorite; // trạng thái user đã thích hay chưa
  int favoritesCount; // số lượng user đã thích

  Restaurant({
    required this.id,
    required this.name,
    required this.address,
    this.description,
    this.latitude,
    this.longitude,
    this.imageUrl,
    this.distance,
    this.isFavorite = false,
    this.favoritesCount = 0,
    this.avgRating,
    this.reviewsCount,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      description: json['description'],
      latitude:
          json['latitude'] != null
              ? double.tryParse(json['latitude'].toString())
              : null,
      longitude:
          json['longitude'] != null
              ? double.tryParse(json['longitude'].toString())
              : null,
      imageUrl: json['image_url'],
      distance:
          json['distance'] != null
              ? double.tryParse(json['distance'].toString())
              : null,
      isFavorite: json['is_favorite'] ?? false,
      favoritesCount: json['favorites_count'] ?? 0,
      avgRating:
          json['avg_rating'] != null
              ? double.tryParse(json['avg_rating'].toString())
              : 0,
      reviewsCount: json['reviews_count'], // ✅ parse từ JSON
    );
  }
}
