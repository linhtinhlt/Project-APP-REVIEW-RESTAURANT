import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reviewfood/services/api_service.dart';
import '../profile/settings_provider.dart';
import 'package:reviewfood/pages/profile/app_localizations.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  String avatarUrl = "";
  bool _loading = false;
  final ApiService _api = ApiService();

  // ================== Load user từ local ==================
  Future<void> _loadUserFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nameController.text = prefs.getString("userName") ?? "";
      emailController.text = prefs.getString("email") ?? "";
      final avatar = prefs.getString("avatar") ?? "";
      avatarUrl = avatar.isNotEmpty ? ApiService.getFullImageUrl(avatar) : "";
    });
  }

  // ================== Cập nhật user info ==================
  Future<void> _updateUserInfo() async {
    setState(() => _loading = true);
    try {
      final updatedUser = await _api.updateUserInfo(
        name: nameController.text,
        email: emailController.text,
      );
      setState(() {
        nameController.text = updatedUser["name"] ?? "";
        emailController.text = updatedUser["email"] ?? "";
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tRead('update_success'))));
    } catch (e) {
      debugPrint("Update user error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${context.tRead('update_failed')}: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  // ================== Upload avatar ==================
  Future<void> _uploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _loading = true);
    try {
      final newAvatarUrl = await _api.uploadAvatar(File(picked.path));
      setState(() {
        avatarUrl = ApiService.getFullImageUrl(newAvatarUrl);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tRead('upload_avatar_success'))),
      );
    } catch (e) {
      debugPrint("Upload avatar error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tRead('upload_avatar_failed'))),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserFromLocal();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final fontScale = settings.fontSize / 14.0;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = settings.isDarkMode;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          context.t('account_info'),
          style: theme.appBarTheme.titleTextStyle?.copyWith(
            fontSize: 18 * fontScale,
          ),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        centerTitle: true,
        elevation: 0.5,
        iconTheme: theme.appBarTheme.iconTheme,
      ),
      body:
          _loading
              ? Center(child: CircularProgressIndicator(color: primary))
              : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 28,
                ),
                child: Column(
                  children: [
                    // 🖼 Avatar với viền gradient nhẹ
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
                                    avatarUrl,
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
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _uploadAvatar,
                      style: TextButton.styleFrom(foregroundColor: primary),
                      child: Text(
                        context.t('change_avatar'),
                        style: TextStyle(
                          fontSize: 14 * fontScale,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 26),

                    // 📝 Họ tên
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        context.t('name'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15 * fontScale,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: nameController,
                      hint: context.t('enter_name'),
                      enabled: true,
                      theme: theme,
                    ),

                    const SizedBox(height: 18),

                    // 📧 Email
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        context.t('email'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15 * fontScale,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: emailController,
                      hint: context.t('email'),
                      enabled: false,
                      theme: theme,
                    ),

                    const SizedBox(height: 28),

                    // 💾 Nút lưu
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _updateUserInfo,
                        icon: const Icon(
                          Icons.save_rounded,
                          color: Colors.white,
                        ),
                        label: Text(
                          context.t('save_changes'),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16 * fontScale,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          shadowColor: primary.withOpacity(0.25),
                          elevation: 4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
    );
  }

  // 🔹 TextField bo mềm, nhận màu từ theme
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required bool enabled,
    required ThemeData theme,
  }) {
    final settings = context.read<SettingsProvider>();
    final fontScale = settings.fontSize / 14.0;
    final isDark = settings.isDarkMode;

    return TextField(
      controller: controller,
      enabled: enabled,
      style: TextStyle(
        fontSize: 15 * fontScale,
        color: theme.textTheme.bodyLarge?.color,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
          fontSize: 14 * fontScale,
        ),
        filled: true,
        fillColor: theme.cardColor,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12 * fontScale.clamp(0.9, 1.3),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[700]! : const Color(0xFFD0D0D0),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[600]! : const Color(0xFFD0D0D0),
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[800]! : const Color(0xFFE0E0E0),
          ),
        ),
      ),
    );
  }
}
