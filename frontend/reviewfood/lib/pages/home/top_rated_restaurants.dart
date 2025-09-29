import 'package:flutter/material.dart';
import 'package:reviewfood/services/api_service.dart';
import 'package:reviewfood/models/restaurant.dart';
import 'package:reviewfood/pages/restaurant/restaurant_detail_page.dart';
//import '../profile/settings_provider.dart';
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

class _TopRatedRestaurantsWidgetState extends State<TopRatedRestaurantsWidget> {
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (topRated.isEmpty)
      return const Center(child: Text('Không có quán ăn nào 😅'));

    return ListView.builder(
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics ?? const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      itemCount: topRated.length,
      itemBuilder: (_, index) {
        final r = topRated[index];
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          clipBehavior: Clip.antiAlias,
          elevation: 4,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RestaurantDetailPage(restaurantId: r.id),
                ),
              );
            },
            splashColor: Colors.blue.withOpacity(0.2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ảnh quán
                r.imageUrl != null && r.imageUrl!.isNotEmpty
                    ? Image.network(
                      r.imageUrl!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) => Container(
                            height: 180,
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.broken_image,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                    )
                    : Container(
                      height: 180,
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.restaurant,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                // Nội dung
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              r.address,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // ⭐ Rating + số đánh giá
                      Row(
                        children: [
                          ...List.generate(5, (i) {
                            if (i < (r.avgRating ?? 0).floor()) {
                              return const Icon(
                                Icons.star,
                                color: Colors.orange,
                                size: 14,
                              );
                            } else {
                              return const Icon(
                                Icons.star_border,
                                color: Colors.orange,
                                size: 14,
                              );
                            }
                          }),
                          const SizedBox(width: 4),
                          Text(
                            '${r.avgRating?.toStringAsFixed(1) ?? "0"}/5',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '(${r.reviewsCount ?? 0} ${context.t('reviews')})',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
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
