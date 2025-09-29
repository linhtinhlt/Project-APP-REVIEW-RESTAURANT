import 'package:flutter/material.dart';
import 'package:reviewfood/pages/login_page.dart';
import 'package:reviewfood/pages/profile/account_info_page.dart';
import 'package:reviewfood/pages/profile/settings_page.dart';
import 'package:reviewfood/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reviewfood/pages/profile/my_reviews_page.dart';
import 'package:reviewfood/pages/profile/favorites_page.dart';
import 'app_localizations.dart';

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
    final theme = Theme.of(context);

    if (!loggedIn) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
              if (result == true) checkLoginStatus();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent, // đổi sang xanh
              foregroundColor: Colors.white, // chữ trắng
            ),
            child: Text(context.t('login')),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          const SizedBox(height: 40),

          // Avatar với shadow nhẹ
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: SizedBox(
                width: 100,
                height: 100,
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

          const SizedBox(height: 12),

          // Tên người dùng
          Text(
            userName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),

          const SizedBox(height: 24),

          // Divider
          Divider(color: theme.dividerColor, thickness: 1),

          // Menu
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                _buildMenuItem(
                  icon: Icons.person,
                  text: context.t('account_info'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AccountPage()),
                    );
                  },
                  theme: theme,
                ),
                _buildMenuItem(
                  icon: Icons.reviews,
                  text: context.t('my_reviews'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyReviewsPage()),
                    );
                  },
                  theme: theme,
                ),
                _buildMenuItem(
                  icon: Icons.favorite,
                  text: context.t('favorites'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyFavoritesPage()),
                    );
                  },
                  theme: theme,
                ),
                _buildMenuItem(
                  icon: Icons.settings,
                  text: context.t('settings'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsPage()),
                    );
                  },
                  theme: theme,
                ),

                const SizedBox(height: 12),

                // Logout riêng
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  color: theme.cardColor,
                  child: ListTile(
                    leading: Icon(
                      Icons.logout,
                      color: Colors.blueAccent,
                    ), // đổi sang xanh
                    title: Text(
                      context.t('logout'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.blueAccent, // đổi sang xanh
                      ),
                    ),
                    onTap: logout,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      color: theme.cardColor,
      child: ListTile(
        leading: Icon(icon, color: Colors.blueAccent), // đổi sang xanh
        title: Text(text, style: theme.textTheme.bodyMedium),
        trailing: Icon(Icons.chevron_right, color: theme.iconTheme.color),
        onTap: onTap,
      ),
    );
  }
}
