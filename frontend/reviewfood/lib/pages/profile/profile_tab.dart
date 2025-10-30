import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reviewfood/pages/login_page.dart';
import 'package:reviewfood/pages/profile/account_info_page.dart';
import 'package:reviewfood/pages/profile/settings_page.dart';
import 'package:reviewfood/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reviewfood/pages/profile/my_reviews_page.dart';
import 'package:reviewfood/pages/profile/favorites_page.dart';
import 'app_localizations.dart';
import 'settings_provider.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool loggedIn = false;
  String userName = "";
  String avatarUrl = "";

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final name = prefs.getString('userName') ?? "";
    final avatar = prefs.getString('avatar') ?? "";

    setState(() {
      loggedIn = token != null;
      userName = name;
      avatarUrl = avatar;
    });
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userName');
    await prefs.remove('avatar');

    setState(() {
      loggedIn = false;
      userName = "";
      avatarUrl = "";
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final fontScale = settings.fontSize / 14.0;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = settings.isDarkMode;

    // 🌈 Nếu chưa đăng nhập
    if (!loggedIn) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline_rounded, size: 80, color: primary),
              const SizedBox(height: 16),
              Text(
                context.t('please_login'),
                style: TextStyle(
                  fontSize: 16 * fontScale,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                  if (result == true) checkLoginStatus();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  context.t('login'),
                  style: TextStyle(
                    fontSize: 16 * fontScale,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 🧑 Khi đã đăng nhập
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          child: Column(
            children: [
              // 🖼 Avatar với viền gradient
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [primary, primary.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: ClipOval(
                  child: SizedBox(
                    width: 110,
                    height: 110,
                    child:
                        avatarUrl.isNotEmpty
                            ? Image.network(
                              ApiService.getFullImageUrl(avatarUrl),
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) => Image.asset(
                                    "assets/images/avatar.jpg",
                                    fit: BoxFit.cover,
                                  ),
                            )
                            : Image.asset(
                              "assets/images/avatar.jpg",
                              fit: BoxFit.cover,
                            ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 👤 Tên người dùng
              Text(
                userName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20 * fontScale,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 6),

              Divider(
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                thickness: 1,
              ),
              const SizedBox(height: 12),

              // 📋 Menu
              _buildMenuItem(
                icon: Icons.person,
                text: context.t('account_info'),
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AccountPage()),
                    ),
              ),
              _buildMenuItem(
                icon: Icons.reviews_rounded,
                text: context.t('my_reviews'),
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyReviewsPage()),
                    ),
              ),
              _buildMenuItem(
                icon: Icons.favorite_rounded,
                text: context.t('favorites'),
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MyFavoritesPage(),
                      ),
                    ),
              ),
              _buildMenuItem(
                icon: Icons.settings_rounded,
                text: context.t('settings'),
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsPage()),
                    ),
              ),

              const SizedBox(height: 20),

              // 🚪 Đăng xuất
              GestureDetector(
                onTap: logout,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 18,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: primary.withOpacity(0.12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded, color: primary),
                      const SizedBox(width: 8),
                      Text(
                        context.t('logout'),
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15 * fontScale,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // 🌟 item menu
  Widget _buildMenuItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    final settings = context.read<SettingsProvider>();
    final fontScale = settings.fontSize / 14.0;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = settings.isDarkMode;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(14),
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
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12 * fontScale.clamp(0.9, 1.2),
          ),
          child: Row(
            children: [
              Icon(icon, color: primary, size: 24 * fontScale.clamp(0.9, 1.3)),
              SizedBox(width: 14 * fontScale.clamp(0.8, 1.3)),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.w500,
                    fontSize: 15.5 * fontScale,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? Colors.grey[500] : Colors.grey[400],
                size: 22 * fontScale.clamp(0.9, 1.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
