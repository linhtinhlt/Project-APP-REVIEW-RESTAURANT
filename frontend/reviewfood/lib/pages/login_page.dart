import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reviewfood/pages/register_page.dart';
import 'package:reviewfood/pages/home/home_page.dart';
import 'package:reviewfood/services/api_service.dart';
import 'package:reviewfood/pages/profile/app_localizations.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final api = ApiService();
  bool loading = false;
  bool loggedIn = false;
  bool obscure = true;

  @override
  void initState() {
    super.initState();
    _checkLoggedIn();
  }

  Future<void> _checkLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null && token.isNotEmpty) {
      setState(() => loggedIn = true);
    }
  }

  Future<void> login() async {
    setState(() => loading = true);
    try {
      final result = await api.login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      setState(() => loading = false);

      if (result['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        int userId = 0;

        if (result.containsKey('token')) {
          await prefs.setString('token', result['token']);
        }
        if (result.containsKey('user')) {
          final user = result['user'];
          if (user.containsKey('id')) {
            userId = user['id'];
            await prefs.setInt('user_id', userId);
          }
        }

        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.tRead('login_success'))));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.tRead('login_failed'))));
      }
    } catch (e) {
      setState(() => loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${context.tRead('error')}: $e')));
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_id');
    setState(() => loggedIn = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0.5,
        centerTitle: true,
        iconTheme: theme.appBarTheme.iconTheme,
        leading:
            Navigator.canPop(context)
                ? IconButton(
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  onPressed: () => Navigator.pop(context),
                )
                : null,
      ),
      body: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child:
              loggedIn
                  ? _buildLoggedInView(context, primary)
                  : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 28, 28, 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 12),

                        // 🌈 Avatar / Icon
                        CircleAvatar(
                          radius: 45,
                          backgroundColor: primary.withOpacity(0.1),
                          child: Icon(
                            Icons.account_circle_rounded,
                            color: primary,
                            size: 80,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // 👋 Tiêu đề thân thiện
                        Text(
                          context.t('welcome_back_title'),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: primary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.t('welcome_back_subtitle'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: theme.hintColor,
                            fontSize: 14.5,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // 📋 Email
                        _buildTextField(
                          controller: emailController,
                          label: context.t('email'),
                          icon: Icons.email_rounded,
                          theme: theme,
                          primary: primary,
                        ),
                        const SizedBox(height: 16),

                        // 🔒 Password
                        _buildTextField(
                          controller: passwordController,
                          label: context.t('password'),
                          icon: Icons.lock_rounded,
                          theme: theme,
                          primary: primary,
                          isPassword: true,
                        ),
                        const SizedBox(height: 28),

                        // 🔘 Nút đăng nhập
                        loading
                            ? CircularProgressIndicator(color: primary)
                            : SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      primary.withOpacity(0.85),
                                      primary,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    if (!isDark)
                                      BoxShadow(
                                        color: primary.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    context.t('login'),
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        const SizedBox(height: 20),

                        // 🌟 Chưa có tài khoản
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              context.t('no_account'),
                              style: TextStyle(
                                color: theme.textTheme.bodyMedium?.color,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterPage(),
                                  ),
                                );
                              },
                              child: Text(
                                context.t('register_now'),
                                style: TextStyle(
                                  color: primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
        ),
      ),
    );
  }

  // ✅ View khi đã đăng nhập
  Widget _buildLoggedInView(BuildContext context, Color primary) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.verified_user_rounded, size: 90, color: primary),
        const SizedBox(height: 16),
        Text(
          context.t('already_logged_in'),
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: logout,
          icon: const Icon(Icons.logout_rounded, color: Colors.white),
          label: Text(
            context.t('logout'),
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }

  // 💫 TextField đồng bộ tone toàn app
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ThemeData theme,
    required Color primary,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? obscure : false,
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: primary),
        suffixIcon:
            isPassword
                ? IconButton(
                  icon: Icon(
                    obscure
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: theme.hintColor,
                  ),
                  onPressed: () => setState(() => obscure = !obscure),
                )
                : null,
        labelText: label,
        filled: true,
        fillColor: theme.cardColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
      ),
    );
  }
}
