//import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:reviewfood/services/api_service.dart';
import 'package:reviewfood/models/restaurant.dart';
import 'package:reviewfood/pages/restaurant/restaurant_detail_page.dart';

class RestaurantListPage extends StatefulWidget {
  final ApiService api;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const RestaurantListPage({
    super.key,
    required this.api,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  State<RestaurantListPage> createState() => _RestaurantListPageState();
}

class _RestaurantListPageState extends State<RestaurantListPage> {
  List<Restaurant> restaurants = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchRestaurants();
  }

  void fetchRestaurants() async {
    setState(() => loading = true);
    try {
      final restaurantsList = await widget.api.getRestaurants();
      setState(() {
        restaurants = restaurantsList;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      print('Fetch error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (restaurants.isEmpty) {
      return const Center(child: Text('Không có quán ăn nào 😅'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      itemCount: restaurants.length,
      itemBuilder: (_, index) {
        final r = restaurants[index];
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
                // Hình ảnh quán
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
