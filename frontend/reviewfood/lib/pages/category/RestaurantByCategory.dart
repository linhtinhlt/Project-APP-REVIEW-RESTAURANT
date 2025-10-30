import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/restaurant.dart';
import 'package:reviewfood/pages/restaurant/restaurant_detail_page.dart';
import '../profile/app_localizations.dart';

class RestaurantByCategoryPage extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const RestaurantByCategoryPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<RestaurantByCategoryPage> createState() =>
      _RestaurantByCategoryPageState();
}

class _RestaurantByCategoryPageState extends State<RestaurantByCategoryPage>
    with TickerProviderStateMixin {
  late Future<List<Restaurant>> _futureRestaurants;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _futureRestaurants = _apiService.getRestaurantsByCategory(
      widget.categoryId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: primary,
        elevation: 2,
        title: Text(
          "${context.t('restaurant_category')} - ${widget.categoryName}",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Restaurant>>(
        future: _futureRestaurants,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF46B5F1)),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                "${context.t('error')}: ${snapshot.error}",
                style: TextStyle(color: theme.colorScheme.error),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                context.t('no_restaurants'),
                style: TextStyle(color: theme.hintColor, fontSize: 16),
              ),
            );
          }

          final restaurants = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            physics: const BouncingScrollPhysics(),
            itemCount: restaurants.length,
            itemBuilder: (context, index) {
              final r = restaurants[index];

              final animController = AnimationController(
                vsync: this,
                duration: Duration(milliseconds: 350 + index * 40),
              )..forward();

              final fade = CurvedAnimation(
                parent: animController,
                curve: Curves.easeOut,
              );

              return FadeTransition(
                opacity: fade,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => RestaurantDetailPage(restaurantId: r.id),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        if (!isDark)
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // 🖼 Ảnh nhà hàng
                        ClipRRect(
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(18),
                          ),
                          child:
                              (r.imageUrl != null && r.imageUrl!.isNotEmpty)
                                  ? FadeInImage.assetNetwork(
                                    placeholder: 'assets/images/food.jpg',
                                    image: r.imageUrl!,
                                    width: 110,
                                    height: 110,
                                    fit: BoxFit.cover,
                                    imageErrorBuilder:
                                        (_, __, ___) => Container(
                                          width: 110,
                                          height: 110,
                                          color: Colors.grey[300],
                                          child: const Icon(
                                            Icons.broken_image_outlined,
                                            size: 40,
                                            color: Colors.grey,
                                          ),
                                        ),
                                  )
                                  : Container(
                                    width: 110,
                                    height: 110,
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.fastfood_rounded,
                                      color: Colors.grey,
                                      size: 38,
                                    ),
                                  ),
                        ),

                        // 📋 Thông tin nhà hàng
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 🏷️ Tên quán
                                Text(
                                  r.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: primary,
                                  ),
                                ),
                                const SizedBox(height: 6),

                                // 📍 Địa chỉ
                                Text(
                                  r.address ?? "",
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color: theme.textTheme.bodyMedium?.color
                                        ?.withOpacity(0.8),
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // ⭐ Đánh giá (ngăn tràn ngang)
                                Row(
                                  children: [
                                    // 5 sao
                                    ...List.generate(5, (i) {
                                      final filled =
                                          i < (r.avgRating ?? 0).floor();
                                      return Icon(
                                        filled
                                            ? Icons.star_rounded
                                            : Icons.star_border_rounded,
                                        color: Colors.amber[600],
                                        size: 16,
                                      );
                                    }),
                                    const SizedBox(width: 6),

                                    // Điểm trung bình
                                    Text(
                                      "${r.avgRating?.toStringAsFixed(1) ?? "0.0"}/5",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13.5,
                                        color: theme.textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                    const SizedBox(width: 6),

                                    // Số đánh giá — cho vào Flexible để tránh overflow
                                    Flexible(
                                      child: Text(
                                        "(${r.reviewsCount ?? 0} ${context.t('rvs')})",
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: theme.hintColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        softWrap: false,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
