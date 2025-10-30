import 'package:flutter/material.dart';
import 'package:reviewfood/services/api_service.dart';
import 'package:reviewfood/models/restaurant.dart';
import 'package:reviewfood/pages/restaurant/restaurant_detail_page.dart';
import '../profile/app_localizations.dart';

class TopRatedRestaurantsWidget extends StatefulWidget {
  final ApiService apiService;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const TopRatedRestaurantsWidget({
    super.key,
    required this.apiService,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  State<TopRatedRestaurantsWidget> createState() =>
      _TopRatedRestaurantsWidgetState();
}

class _TopRatedRestaurantsWidgetState extends State<TopRatedRestaurantsWidget>
    with SingleTickerProviderStateMixin {
  List<Restaurant> topRated = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchTopRated();
  }

  void fetchTopRated() async {
    setState(() => loading = true);
    try {
      final list = await widget.apiService.getTopRatedRestaurants(limit: 5);
      setState(() {
        topRated = list;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải dữ liệu: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    if (loading) {
      return Center(child: CircularProgressIndicator(color: primary));
    }

    if (topRated.isEmpty) {
      return Center(
        child: Text(
          context.t('no_top_restaurants'),
          style: TextStyle(color: theme.hintColor),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics ?? const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemCount: topRated.length,
      itemBuilder: (_, index) {
        final r = topRated[index];

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow:
                isDark
                    ? []
                    : [
                      BoxShadow(
                        color: theme.shadowColor.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RestaurantDetailPage(restaurantId: r.id),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🖼 Ảnh
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      r.imageUrl != null && r.imageUrl!.isNotEmpty
                          ? FadeInImage.assetNetwork(
                            placeholder: 'assets/images/food.jpg',
                            image: r.imageUrl!,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            imageErrorBuilder:
                                (_, __, ___) => Container(
                                  height: 180,
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.broken_image_outlined,
                                    color: Colors.grey,
                                    size: 50,
                                  ),
                                ),
                          )
                          : Container(
                            height: 180,
                            width: double.infinity,
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.restaurant_rounded,
                              color: Colors.white70,
                              size: 50,
                            ),
                          ),
                      // Overlay mờ
                      Positioned.fill(
                        child: Container(color: Colors.black.withOpacity(0.08)),
                      ),
                      // Huy hiệu thứ hạng
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "#${index + 1}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 📋 Nội dung
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🏷️ Tên nhà hàng
                      Text(
                        r.name,
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // 📍 Địa chỉ
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 16,
                            color: primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              r.address,
                              style: TextStyle(
                                fontSize: 13.5,
                                color: theme.hintColor,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // ⭐ Rating + số đánh giá
                      Row(
                        children: [
                          ...List.generate(5, (i) {
                            final filled = i < (r.avgRating ?? 0).floor();
                            return Icon(
                              filled
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: Colors.amber[600],
                              size: 16,
                            );
                          }),
                          const SizedBox(width: 6),
                          Text(
                            "${r.avgRating?.toStringAsFixed(1) ?? "0.0"}/5",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "(${r.reviewsCount ?? 0} ${context.t('reviews')})",
                            style: TextStyle(
                              fontSize: 12.5,
                              color: theme.hintColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
