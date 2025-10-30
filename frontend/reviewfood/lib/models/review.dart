class ReviewImage {
  final String imageUrl;

  ReviewImage({required this.imageUrl});

  factory ReviewImage.fromJson(Map<String, dynamic> json) {
    return ReviewImage(imageUrl: json['image_url'] ?? '');
  }
}

class Review {
  final int id;
  final int rating;
  final String content;
  final List<ReviewImage> images;
  final String userName;
  final String? userAvatar;
  final int restaurantId; // ✅ thêm
  final String restaurantName; // ✅ thêm
  int likesCount;
  bool isLiked; // ✅ like
  List<String> comments;
  final String? createdAt;

  Review({
    required this.id,
    required this.rating,
    required this.content,
    required this.images,
    required this.userName,
    this.userAvatar,
    required this.restaurantId,
    required this.restaurantName,
    required this.likesCount,
    this.isLiked = false, // mặc định chưa like
    this.comments = const [], // mặc định không có comment
    this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      rating: json['rating'] ?? 0,
      content: json['content'] ?? '',
      images:
          (json['images'] as List<dynamic>?)
              ?.map((e) => ReviewImage.fromJson(e))
              .toList() ??
          [],
      userName: json['user']?['name'] ?? 'Ẩn danh',
      userAvatar: json['user']?['avatar'],
      restaurantId: json['restaurant']?['id'] ?? 0, // ✅ lấy từ relation
      restaurantName: json['restaurant']?['name'] ?? '', // ✅ lấy từ relation
      likesCount: json['likes_count'] ?? 0,
      isLiked: json['is_liked'] == true || json['is_liked'] == 1,
      comments:
          (json['comments'] as List<dynamic>?)
              ?.map((c) => c.toString())
              .toList() ??
          [],
      createdAt: json['created_at'],
    );
  }
}
