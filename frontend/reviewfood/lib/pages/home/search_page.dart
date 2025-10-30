import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/restaurant.dart';
import '../../services/api_service.dart';
import '../restaurant/restaurant_detail_page.dart';
import '../profile/app_localizations.dart';
import '../profile/settings_provider.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<Restaurant> _results = [];
  bool _isLoading = false;
  Timer? _debounce;

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.trim().length < 2) {
      setState(() => _results = []);
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 600), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);
    try {
      final list = await _apiService.searchRestaurants(query: query, limit: 20);
      setState(() => _results = list);
    } catch (e) {
      setState(() => _results = []);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.t('search_error')}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final fontSize = settings.fontSize;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.cardColor,
        elevation: 0.4,
        iconTheme: IconThemeData(color: primary),
        titleSpacing: 0,
        title: Container(
          height: 44,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color:
                isDark
                    ? theme.cardColor.withOpacity(0.6)
                    : const Color(0xFFE8F6FD),
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: primary),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: TextStyle(fontSize: fontSize),
                  decoration: InputDecoration(
                    hintText: context.t('search_hint'),
                    hintStyle: TextStyle(
                      color: theme.hintColor,
                      fontSize: fontSize - 1,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              if (_searchController.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() => _results = []);
                  },
                  child: Icon(Icons.close_rounded, color: theme.hintColor),
                ),
            ],
          ),
        ),
      ),
      body: _buildBody(theme, primary, fontSize),
    );
  }

  Widget _buildBody(ThemeData theme, Color primary, double fontSize) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: primary));
    }

    if (_searchController.text.trim().length < 2) {
      return _buildPlaceholder(
        icon: Icons.search_rounded,
        color: primary,
        text: context.t('enter_keyword'),
        fontSize: fontSize,
      );
    }

    if (_results.isEmpty) {
      return _buildPlaceholder(
        icon: Icons.sentiment_dissatisfied_rounded,
        color: theme.hintColor,
        text: context.t('no_results'),
        fontSize: fontSize,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        return _buildRestaurantItem(
          context,
          _results[index],
          theme,
          primary,
          fontSize,
        );
      },
    );
  }

  Widget _buildPlaceholder({
    required IconData icon,
    required Color color,
    required String text,
    required double fontSize,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color.withOpacity(0.8), size: 90),
          const SizedBox(height: 16),
          Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              color: color.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantItem(
    BuildContext context,
    Restaurant restaurant,
    ThemeData theme,
    Color primary,
    double fontSize,
  ) {
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
                    color: theme.shadowColor.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        splashColor: primary.withOpacity(0.15),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RestaurantDetailPage(restaurantId: restaurant.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 🖼 Ảnh nhà hàng
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child:
                    restaurant.imageUrl != null &&
                            restaurant.imageUrl!.isNotEmpty
                        ? FadeInImage.assetNetwork(
                          placeholder: 'assets/images/food.jpg',
                          image: restaurant.imageUrl!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          imageErrorBuilder:
                              (_, __, ___) => Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.broken_image_outlined,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              ),
                        )
                        : Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.restaurant,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
              ),
              const SizedBox(width: 14),

              // 📋 Thông tin
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: fontSize + 1,
                        color: primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      restaurant.address,
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color,
                        fontSize: fontSize * 0.95,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    if (restaurant.avgRating != null)
                      Row(
                        children: [
                          ..._buildStarIcons(restaurant.avgRating!),
                          const SizedBox(width: 6),
                          Text(
                            '${restaurant.avgRating!.toStringAsFixed(1)}/5',
                            style: TextStyle(
                              fontSize: fontSize * 0.95,
                              color: theme.textTheme.bodyLarge?.color,
                              fontWeight: FontWeight.w600,
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
      ),
    );
  }

  List<Widget> _buildStarIcons(double rating) {
    final fullStars = rating.floor();
    final halfStar = (rating - fullStars) >= 0.5;

    return List.generate(5, (i) {
      if (i < fullStars) {
        return const Icon(
          Icons.star_rounded,
          color: Color(0xFFFFC107),
          size: 16,
        );
      } else if (i == fullStars && halfStar) {
        return const Icon(
          Icons.star_half_rounded,
          color: Color(0xFFFFC107),
          size: 16,
        );
      } else {
        return const Icon(
          Icons.star_border_rounded,
          color: Color(0xFFFFC107),
          size: 16,
        );
      }
    });
  }
}
