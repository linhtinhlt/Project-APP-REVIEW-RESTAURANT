import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/restaurant.dart';
import '../../services/api_service.dart';
import '../../pages/restaurant/restaurant_detail_page.dart';
import '../profile/settings_provider.dart';

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
        setState(() {
          restaurant.isFavorite = true;
          restaurant.favoritesCount = oldCount;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Hủy yêu thích thất bại')));
      } else {
        _loadFavorites();
        setState(() {});
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

  // 🔹 Item quán yêu thích
  Widget _buildRestaurantItem(Restaurant restaurant, double fontScale) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
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
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          final updated = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RestaurantDetailPage(restaurantId: restaurant.id),
            ),
          );
          if (updated == true) {
            _loadFavorites();
            setState(() {});
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 🖼 Ảnh quán ăn
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child:
                    restaurant.imageUrl != null &&
                            restaurant.imageUrl!.isNotEmpty
                        ? Image.network(
                          restaurant.imageUrl!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        )
                        : Container(
                          width: 80,
                          height: 80,
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                          child: Icon(
                            Icons.restaurant,
                            size: 40,
                            color: isDark ? Colors.grey[500] : Colors.grey,
                          ),
                        ),
              ),
              const SizedBox(width: 14),

              // 🏠 Thông tin
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15.5 * fontScale,
                        color: primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      restaurant.address,
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color,
                        fontSize: 14 * fontScale,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.favorite_rounded,
                          size: 18,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${restaurant.favoritesCount}",
                          style: TextStyle(
                            fontSize: 13.5 * fontScale,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ❤️ Nút hủy yêu thích
              TextButton.icon(
                onPressed: () => _unfavorite(restaurant),
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.redAccent,
                  size: 18,
                ),
                label: const Text(
                  "Hủy",
                  style: TextStyle(color: Colors.redAccent),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final fontScale = settings.fontSize / 14.0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0.5,
        title: Text(
          "Quán yêu thích",
          style: theme.appBarTheme.titleTextStyle?.copyWith(
            fontSize: 18 * fontScale,
          ),
        ),
        centerTitle: true,
        iconTheme: theme.appBarTheme.iconTheme,
      ),
      body: FutureBuilder<List<Restaurant>>(
        future: _favoritesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primary));
          } else if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'Chưa có quán yêu thích 💔',
                style: TextStyle(color: theme.hintColor),
              ),
            );
          }

          final favorites = snapshot.data!;
          return RefreshIndicator(
            color: primary,
            onRefresh: () async {
              _loadFavorites();
              setState(() {});
            },
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: favorites.length,
              itemBuilder:
                  (context, index) =>
                      _buildRestaurantItem(favorites[index], fontScale),
            ),
          );
        },
      ),
    );
  }
}
