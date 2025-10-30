import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reviewfood/services/api_service.dart';
import 'package:reviewfood/pages/login_page.dart';
import 'package:reviewfood/pages/profile/profile_tab.dart';
import 'package:reviewfood/pages/reviewfeed/reviewfeed_page.dart';
import 'package:reviewfood/pages/map/map_page.dart';
import 'package:reviewfood/pages/category/category_page.dart';
import '../profile/settings_provider.dart';
import '../profile/app_localizations.dart';
import 'top_rated_restaurants.dart';
import 'search_page.dart';
import 'recommendation.dart';
import 'category_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService _apiService = ApiService();
  int _selectedIndex = 0;
  Key _reloadKey = UniqueKey();
  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  // 🌈 Header Gradient
  Widget _buildHeader(
    BuildContext context,
    SettingsProvider settings,
    double fontScale,
  ) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 44, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              isDark
                  ? [primary.withOpacity(0.3), primary.withOpacity(0.5)]
                  : [
                    primary.withOpacity(0.6),
                    primary,
                    const Color(0xFF0288D1),
                  ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 🏷️ App name & slogan
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "🍽️ ReviewFood",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22 * fontScale,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          // 👤 Profile/Login
          IconButton(
            icon: const Icon(
              Icons.account_circle_rounded,
              color: Colors.white,
              size: 34,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  // 🔍 Thanh tìm kiếm
  Widget _buildSearchBar(BuildContext context, double fontScale) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SearchPage()),
          ),
      child: Container(
        height: 46,
        margin: const EdgeInsets.fromLTRB(20, 12, 20, 10),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? theme.cardColor : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow:
              isDark
                  ? []
                  : [
                    BoxShadow(
                      color: primary.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: primary),
            const SizedBox(width: 8),
            Text(
              context.t('search_hint'),
              style: TextStyle(
                color: theme.hintColor,
                fontSize: 14 * fontScale,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🧠 Nội dung chính có refresh
  Widget _buildMainContent(SettingsProvider settings, double fontScale) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return RefreshIndicator(
      color: primary,
      onRefresh: () async {
        // 🔄 ép reload lại toàn bộ widget con
        setState(() {
          _reloadKey = UniqueKey();
        });
      },
      child: Container(
        color: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF8FAFC),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildSearchBar(context, fontScale)),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // 🧭 Danh mục
            SliverToBoxAdapter(
              key: ValueKey("${_reloadKey}_cat"),
              child: CategoryWidget(),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // 🔮 Gợi ý & Nhà hàng nổi bật
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                key: _reloadKey, // ép rebuild toàn bộ nội dung
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔮 Gợi ý AI
                    Row(
                      children: [
                        Icon(Icons.lightbulb_rounded, color: primary, size: 22),
                        const SizedBox(width: 6),
                        Text(
                          context.t('recommendations'),
                          style: TextStyle(
                            color: primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 17 * fontScale,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color:
                            isDark
                                ? theme.cardColor.withOpacity(0.4)
                                : const Color(0xFFE8F6FD),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: RecommendationWidget(
                        topN: 5,
                        alpha: 0.6,
                        key: UniqueKey(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ⭐ Nhà hàng nổi bật
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFC107),
                          size: 22,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          context.t('top_rated_restaurants'),
                          style: TextStyle(
                            color: primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 17 * fontScale,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TopRatedRestaurantsWidget(
                      key: UniqueKey(),
                      apiService: _apiService,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(SettingsProvider settings, double fontScale) {
    if (_selectedIndex == 0) return _buildMainContent(settings, fontScale);
    switch (_selectedIndex) {
      case 1:
        return const ReviewFeedPage();
      case 2:
        return const MapPage();
      case 3:
        return const CategoryPage();
      case 4:
        return const ProfileTab();
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final fontScale = settings.fontSize / 14.0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildHeader(context, settings, fontScale),
          Expanded(child: _buildBody(settings, fontScale)),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: theme.cardColor,
        selectedItemColor: primary,
        unselectedItemColor: theme.hintColor,
        showUnselectedLabels: true,
        elevation: 8,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_rounded),
            label: context.t('home_title'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.reviews_rounded),
            label: context.t('review_feed'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.map_rounded),
            label: context.t('map'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.grid_view_rounded),
            label: context.t('category'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline_rounded),
            label: context.t('profile'),
          ),
        ],
      ),
    );
  }
}
