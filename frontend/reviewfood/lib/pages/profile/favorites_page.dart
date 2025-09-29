import 'package:flutter/material.dart';
import '../../models/restaurant.dart';
import '../../services/api_service.dart';
import '../../pages/restaurant/restaurant_detail_page.dart';

class MyFavoritesPage extends StatefulWidget {
  const MyFavoritesPage({super.key});

  @override
  State<MyFavoritesPage> createState() => _MyFavoritesPageState();
}

class _MyFavoritesPageState extends State<MyFavoritesPage> {
  final ApiService api = ApiService();
  late Future<List<Restaurant>> _favoritesFuture;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  void _loadFavorites() {
    _favoritesFuture = api.getMyFavorites();
  }

  Future<void> _unfavorite(Restaurant restaurant) async {
    final oldCount = restaurant.favoritesCount;

    // Update UI trước (optimistic)
    setState(() {
      restaurant.isFavorite = false;
      restaurant.favoritesCount = (restaurant.favoritesCount - 1).clamp(
        0,
        9999,
      );
    });

    try {
      final success = await api.unfavoriteRestaurant(restaurant.id);

      if (!success) {
        // rollback nếu thất bại
        setState(() {
          restaurant.isFavorite = true;
          restaurant.favoritesCount = oldCount;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Hủy yêu thích thất bại')));
      } else {
        // Nếu hủy thành công, load lại danh sách
        _loadFavorites(); // cập nhật Future
        setState(() {}); // rebuild FutureBuilder
      }
    } catch (e) {
      setState(() {
        restaurant.isFavorite = true;
        restaurant.favoritesCount = oldCount;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Widget _buildRestaurantItem(Restaurant restaurant) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading:
                  restaurant.imageUrl != null
                      ? Image.network(
                        restaurant.imageUrl!,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      )
                      : Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey[300],
                        child: const Icon(Icons.restaurant, size: 30),
                      ),
              title: Text(
                restaurant.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                restaurant.address,
                style: const TextStyle(fontSize: 14),
              ),
              onTap: () async {
                final updated = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) =>
                            RestaurantDetailPage(restaurantId: restaurant.id),
                  ),
                );
                if (updated == true) {
                  _loadFavorites();
                  setState(() {});
                }
              },
            ),
            const SizedBox(height: 4),
            Text(
              'Đã được yêu thích: ${restaurant.favoritesCount}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            // Luôn hiển thị nút Hủy yêu thích
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _unfavorite(restaurant),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text(
                  'Hủy yêu thích',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quán yêu thích")),
      body: FutureBuilder<List<Restaurant>>(
        future: _favoritesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Chưa có quán yêu thích'));
          }

          final favorites = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async {
              _loadFavorites();
              setState(() {});
            },
            child: ListView.builder(
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                return _buildRestaurantItem(favorites[index]);
              },
            ),
          );
        },
      ),
    );
  }
}
