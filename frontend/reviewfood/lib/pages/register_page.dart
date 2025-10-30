import 'package:flutter/material.dart';
import 'package:reviewfood/pages/login_page.dart';
import 'package:reviewfood/services/api_service.dart';
import 'package:reviewfood/pages/profile/app_localizations.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  bool _obscure = true;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final success = await _apiService.register(name, email, password);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tRead('register_success'))),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tRead('register_failed'))));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 40),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 12),

              // 🌈 Icon đăng ký
              CircleAvatar(
                radius: 45,
                backgroundColor: primary.withOpacity(0.1),
                child: Icon(
                  Icons.person_add_alt_1_rounded,
                  color: primary,
                  size: 80,
                ),
              ),
              const SizedBox(height: 28),

              // 🎉 Tiêu đề
              Text(
                context.t('create_account_title'),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.t('create_account_subtitle'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.hintColor,
                  fontSize: 14.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),

              // 🧑‍💼 Họ tên
              _buildTextField(
                controller: _nameController,
                label: context.t('username'),
                icon: Icons.person_rounded,
                primary: primary,
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? context.t('enter_username')
                            : null,
              ),
              const SizedBox(height: 16),

              // 📧 Email
              _buildTextField(
                controller: _emailController,
                label: context.t('email'),
                icon: Icons.email_rounded,
                primary: primary,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.t('enter_email');
                  }
                  if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                    return context.t('invalid_email');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 🔒 Mật khẩu
              _buildTextField(
                controller: _passwordController,
                label: context.t('password'),
                icon: Icons.lock_rounded,
                primary: primary,
                isPassword: true,
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? context.t('enter_password')
                            : null,
              ),

              const SizedBox(height: 28),

              // 💙 Nút đăng ký
              _isLoading
                  ? CircularProgressIndicator(color: primary)
                  : SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primary.withOpacity(0.85), primary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          if (!isDark)
                            BoxShadow(
                              color: primary.withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          context.t('register'),
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

              // 🔁 Quay lại đăng nhập
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    context.t('already_have_account'),
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                    },
                    child: Text(
                      context.t('back_to_login'),
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // 💫 TextField đồng bộ theme app
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color primary,
    String? Function(String?)? validator,
    bool isPassword = false,
  }) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: isPassword ? _obscure : false,
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: primary),
        suffixIcon:
            isPassword
                ? IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: theme.hintColor,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
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
