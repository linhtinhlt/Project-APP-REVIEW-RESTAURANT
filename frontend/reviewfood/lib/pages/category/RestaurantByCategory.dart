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

class _RestaurantByCategoryPageState extends State<RestaurantByCategoryPage> {
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
            "${context.t('restaurant_category')} - ${widget.categoryName}"),
      ),
      body: FutureBuilder<List<Restaurant>>(
        future: _futureRestaurants,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: Text(context.t('loading') ?? 'Đang tải...'));
          } else if (snapshot.hasError) {
            return Center(
                child: Text("${context.t('error')}: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text(context.t('no_restaurants')));
          }

          final restaurants = snapshot.data!;
          return ListView.builder(
            itemCount: restaurants.length,
            itemBuilder: (context, index) {
              final r = restaurants[index];
              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: r.imageUrl != null && r.imageUrl!.isNotEmpty
                      ? Image.network(
                          r.imageUrl!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.restaurant),
                  title: Text(r.name),
                  subtitle: Text(r.address ?? ""),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            RestaurantDetailPage(restaurantId: r.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
