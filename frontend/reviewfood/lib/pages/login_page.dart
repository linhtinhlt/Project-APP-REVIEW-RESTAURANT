import 'dart:convert';
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

  Future<void> login() async {
    setState(() => loading = true);

    try {
      final Map<String, dynamic> result = await api.login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      setState(() => loading = false);

      if (result['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        if (result.containsKey('token')) {
          await prefs.setString('token', result['token']);
        }

        if (!mounted) return;
        // DÙNG tRead() trong async / event handler
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

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(context.t('login')),
      ), // ok: dùng t() trong build
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Icon(
              Icons.account_circle,
              size: 100,
              color: Color.fromARGB(255, 28, 105, 164),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: context.t('email'),
                prefixIcon: const Icon(Icons.email),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: context.t('password'),
                prefixIcon: const Icon(Icons.lock),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                  onPressed: login,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: const Color.fromARGB(255, 28, 105, 164),
                  ),
                  child: Text(
                    context.t('login'),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color.fromARGB(255, 225, 241, 255),
                    ),
                  ),
                ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterPage()),
                );
              },
              child: Text(context.t('register_prompt')),
            ),
          ],
        ),
      ),
    );
  }
}
