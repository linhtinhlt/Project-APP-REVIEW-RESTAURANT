import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reviewfood/services/api_service.dart';
import 'package:reviewfood/models/restaurant.dart';
import 'package:reviewfood/models/review.dart';
import 'package:reviewfood/pages/reviewfeed/add_review_page.dart';
import 'package:reviewfood/pages/reviewfeed/review_detail_page.dart';
import '../profile/settings_provider.dart';
import '../profile/app_localizations.dart';
import 'restaurant_map_widget.dart';

class RestaurantDetailPage extends StatefulWidget {
  final int restaurantId;

  const RestaurantDetailPage({super.key, required this.restaurantId});

  @override
  State<RestaurantDetailPage> createState() => _RestaurantDetailPageState();
}

class _RestaurantDetailPageState extends State<RestaurantDetailPage>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  Future<Restaurant>? _restaurantFuture;
  Future<List<Review>>? _reviewsFuture;
  Restaurant? _restaurantData;

  @override
  void initState() {
    super.initState();
    _loadData(); // ✅ đảm bảo token sẵn sàng trước khi load
  }

  /// ✅ Load restaurant và reviews (có token nếu có)
  Future<void> _loadData() async {
    final token = await _apiService.getToken();
    debugPrint('🔑 Token in detail: $token'); // Kiểm tra token có chưa

    setState(() {
      _restaurantFuture = _apiService.getRestaurantDetail(widget.restaurantId);
      _reviewsFuture = _apiService.getReviewsByRestaurant(widget.restaurantId);
    });
  }

  Future<void> _refreshReviews() async {
    setState(() {
      _reviewsFuture = _apiService.getReviewsByRestaurant(widget.restaurantId);
    });
  }

  /// ❤️ Toggle favorite
  Future<void> _toggleFavorite() async {
    if (_restaurantData == null) return;

    final oldFavorite = _restaurantData!.isFavorite;
    final oldCount = _restaurantData!.favoritesCount;

    setState(() {
      _restaurantData!.isFavorite = !oldFavorite;
      _restaurantData!.favoritesCount += _restaurantData!.isFavorite ? 1 : -1;
    });

    try {
      final success = await _apiService.toggleFavoriteRestaurant(
        _restaurantData!.id,
        oldFavorite,
      );

      if (!success) {
        setState(() {
          _restaurantData!.isFavorite = oldFavorite;
          _restaurantData!.favoritesCount = oldCount;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t('favorite_update_failed'))),
        );
      }
    } catch (e) {
      setState(() {
        _restaurantData!.isFavorite = oldFavorite;
        _restaurantData!.favoritesCount = oldCount;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi khi cập nhật yêu thích: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final fontScale = settings.fontSize / 14.0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: FutureBuilder<Restaurant>(
        future: _restaurantFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primary));
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                "${context.t('error')}: ${snapshot.error}",
                style: TextStyle(color: theme.hintColor),
              ),
            );
          } else if (!snapshot.hasData) {
            return Center(child: Text(context.t('no_data')));
          }

          _restaurantData ??= snapshot.data!;
          final r = _restaurantData!;

          return CustomScrollView(
            slivers: [
              // 🖼 HEADER
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                elevation: 0,
                backgroundColor: theme.cardColor,
                iconTheme: IconThemeData(color: primary),
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  titlePadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  title: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.cardColor.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      r.name,
                      style: TextStyle(
                        fontSize: 15.5 * fontScale,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      FadeInImage.assetNetwork(
                        placeholder: 'assets/images/food.jpg',
                        image: r.imageUrl ?? '',
                        fit: BoxFit.cover,
                        imageErrorBuilder:
                            (_, __, ___) => Container(
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.restaurant,
                                size: 80,
                                color: Colors.white70,
                              ),
                            ),
                      ),
                      Container(
                        color: Colors.black.withOpacity(isDark ? 0.25 : 0.15),
                      ),
                    ],
                  ),
                ),
              ),

              // 📋 BODY
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 📍 Địa chỉ
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded, color: primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              r.address,
                              style: TextStyle(
                                fontSize: 14.5 * fontScale,
                                color: theme.textTheme.bodyMedium?.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ❤️ Yêu thích
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _toggleFavorite,
                            child: AnimatedScale(
                              scale: r.isFavorite ? 1.15 : 1.0,
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutBack,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                transitionBuilder:
                                    (child, anim) => ScaleTransition(
                                      scale: anim,
                                      child: child,
                                    ),
                                child: Icon(
                                  r.isFavorite
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  key: ValueKey(r.isFavorite),
                                  color:
                                      r.isFavorite
                                          ? Colors
                                              .redAccent // ❤️ Đỏ khi đã thích
                                          : (isDark
                                              ? Colors.white54
                                              : Colors.grey),
                                  size: 28,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "${r.favoritesCount} ${context.t('favorites_fav')}",
                            style: TextStyle(
                              fontSize: 13.5 * fontScale,
                              color: theme.hintColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // 🗺️ Bản đồ
                      Container(
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow:
                              isDark
                                  ? []
                                  : [
                                    BoxShadow(
                                      color: theme.shadowColor.withOpacity(
                                        0.08,
                                      ),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                        ),
                        child: RestaurantMapContainer(
                          restaurant: r,
                          height: 200,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 🧾 Giới thiệu
                      Text(
                        context.t('introduction'),
                        style: TextStyle(
                          fontSize: 16.5 * fontScale,
                          fontWeight: FontWeight.bold,
                          color: primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        r.description ?? context.t('no_description'),
                        style: TextStyle(
                          fontSize: 14.5 * fontScale,
                          height: 1.5,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ⭐ Đánh giá trung bình
                      FutureBuilder<List<Review>>(
                        future: _reviewsFuture,
                        builder: (context, snap) {
                          if (!snap.hasData || snap.data!.isEmpty) {
                            return Text(
                              context.t('no_reviews'),
                              style: TextStyle(
                                color: theme.hintColor,
                                fontSize: 14 * fontScale,
                              ),
                            );
                          }
                          final reviews = snap.data!;
                          final avg =
                              reviews
                                  .map((e) => e.rating)
                                  .reduce((a, b) => a + b) /
                              reviews.length;

                          return Row(
                            children: [
                              ...List.generate(
                                5,
                                (i) => Icon(
                                  i < avg.floor()
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  color: Colors.amber[600],
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                avg.toStringAsFixed(1),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15 * fontScale,
                                ),
                              ),
                              Text(
                                " /5 (${reviews.length} ${context.t('reviews')})",
                                style: TextStyle(
                                  fontSize: 13.5 * fontScale,
                                  color: theme.hintColor,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 28),

                      // 💬 Review Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context.t('reviews'),
                            style: TextStyle(
                              fontSize: 16.5 * fontScale,
                              fontWeight: FontWeight.bold,
                              color: primary,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final added = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => AddReviewPage(restaurantId: r.id),
                                ),
                              );
                              if (added == true) _refreshReviews();
                            },
                            icon: const Icon(
                              Icons.add,
                              size: 18,
                              color: Colors.white,
                            ),
                            label: Text(
                              context.t('add_review'),
                              style: const TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // 🗨️ Danh sách review
                      FutureBuilder<List<Review>>(
                        future: _reviewsFuture,
                        builder: (context, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return Center(
                              child: CircularProgressIndicator(color: primary),
                            );
                          } else if (snap.hasError) {
                            return Text("${context.t('error')}: ${snap.error}");
                          } else if (!snap.hasData || snap.data!.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                context.t('no_reviews'),
                                style: TextStyle(color: theme.hintColor),
                              ),
                            );
                          }

                          final reviews = snap.data!;
                          return Column(
                            children:
                                reviews.map((review) {
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) => ReviewDetailPage(
                                                reviewId: review.id,
                                              ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: theme.cardColor,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow:
                                            isDark
                                                ? []
                                                : [
                                                  BoxShadow(
                                                    color: theme.shadowColor
                                                        .withOpacity(0.08),
                                                    blurRadius: 5,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 16,
                                                backgroundImage:
                                                    (review
                                                                .userAvatar
                                                                ?.isNotEmpty ??
                                                            false)
                                                        ? NetworkImage(
                                                          review.userAvatar!,
                                                        )
                                                        : const AssetImage(
                                                              "assets/images/avatar.jpg",
                                                            )
                                                            as ImageProvider,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  review.userName,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14 * fontScale,
                                                  ),
                                                ),
                                              ),
                                              Row(
                                                children: List.generate(
                                                  5,
                                                  (i) => Icon(
                                                    i < review.rating
                                                        ? Icons.star_rounded
                                                        : Icons
                                                            .star_border_rounded,
                                                    color: Colors.amber[600],
                                                    size: 15,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            review.content,
                                            style: TextStyle(
                                              fontSize: 13.5 * fontScale,
                                              height: 1.4,
                                              color:
                                                  theme
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.color,
                                            ),
                                          ),
                                          if (review.images.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            SizedBox(
                                              height: 80,
                                              child: ListView.separated(
                                                scrollDirection:
                                                    Axis.horizontal,
                                                itemCount: review.images.length,
                                                separatorBuilder:
                                                    (_, __) => const SizedBox(
                                                      width: 8,
                                                    ),
                                                itemBuilder: (context, index) {
                                                  final imgUrl =
                                                      ApiService.getFullImageUrl(
                                                        review
                                                            .images[index]
                                                            .imageUrl,
                                                      );

                                                  return ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    child: FadeInImage.assetNetwork(
                                                      placeholder:
                                                          'assets/images/review.jpg', // ảnh mặc định khi đang load
                                                      image: imgUrl,
                                                      width: 80,
                                                      height: 80,
                                                      fit: BoxFit.cover,
                                                      imageErrorBuilder:
                                                          (
                                                            _,
                                                            __,
                                                            ___,
                                                          ) => Image.asset(
                                                            'assets/images/review.jpg', // ảnh fallback nếu lỗi tải
                                                            width: 80,
                                                            height: 80,
                                                            fit: BoxFit.cover,
                                                          ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 🗺️ Widget Bản đồ
class RestaurantMapContainer extends StatelessWidget {
  final Restaurant restaurant;
  final double height;

  const RestaurantMapContainer({
    super.key,
    required this.restaurant,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    return RestaurantMapWidget(restaurant: restaurant, height: height);
  }
}
