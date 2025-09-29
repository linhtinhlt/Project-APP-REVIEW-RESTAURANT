import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reviewfood/services/api_service.dart';
import '../profile/settings_provider.dart';
//import 'package:reviewfood/pages/profile/settings_provider.dart';
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

  // ================== Load user từ local (SharedPreferences) ==================
  Future<void> _loadUserFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nameController.text = prefs.getString("userName") ?? "";
      emailController.text = prefs.getString("email") ?? "";
      avatarUrl = ApiService.getFullImageUrl(prefs.getString("avatar"));
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
      // 🔑 Dùng tRead
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
      // 🔑 Dùng tRead
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
    // watch để rebuild khi đổi language
    context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(context.t('account_info'))),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage:
                          avatarUrl.isNotEmpty
                              ? NetworkImage(avatarUrl)
                              : const AssetImage("assets/images/avatar.jpg")
                                  as ImageProvider,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _uploadAvatar,
                      child: Text(context.t('change_avatar')),
                    ),
                    const SizedBox(height: 20),
                    // Tên
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: context.t('name'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Email (không cho sửa)
                    TextField(
                      controller: emailController,
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: context.t('email'),
                        border: const OutlineInputBorder(),
                      ),
                      style: const TextStyle(
                        color: Color.fromARGB(221, 70, 69, 69),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _updateUserInfo,
                      icon: const Icon(Icons.save),
                      label: Text(context.t('save_changes')),
                    ),
                  ],
                ),
              ),
    );
  }
}
