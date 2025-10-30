import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  String _language = "vi";
  bool _isDarkMode = false;
  String _themeColor = "blue";
  double _fontSize = 14.0;

  String get language => _language;
  bool get isDarkMode => _isDarkMode;
  String get themeColor => _themeColor;
  double get fontSize => _fontSize;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _language = prefs.getString("language") ?? "vi";
    _isDarkMode = prefs.getBool("isDarkMode") ?? false;
    _themeColor = prefs.getString("themeColor") ?? "blue";
    _fontSize = prefs.getDouble("fontSize") ?? 14.0;
    notifyListeners();
  }

  Future<void> updateLanguage(String lang) async {
    _language = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("language", lang);
    notifyListeners();
  }

  Future<void> toggleDarkMode(bool value) async {
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("isDarkMode", value);
    notifyListeners();
  }

  Future<void> updateThemeColor(String color) async {
    _themeColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("themeColor", color);
    notifyListeners();
  }

  Future<void> updateFontSize(double size) async {
    _fontSize = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble("fontSize", size);
    notifyListeners();
  }

  // 🌈 Xanh ngọc chủ đạo (#46B5F1) – đồng bộ với HomePage
  MaterialColor blueAccentSwatch = const MaterialColor(
    0xFF46B5F1, // Màu chính
    <int, Color>{
      50: Color(0xFFE8F6FD),
      100: Color(0xFFD0EDFB),
      200: Color(0xFFA9E0F8),
      300: Color(0xFF82D3F5),
      400: Color(0xFF5BC7F3),
      500: Color(0xFF46B5F1),
      600: Color(0xFF3BA1E0),
      700: Color(0xFF2F8DCB),
      800: Color(0xFF237AB6),
      900: Color(0xFF1565C0),
    },
  );

  MaterialColor getMaterialColor() {
    switch (_themeColor) {
      case "red":
        return Colors.red;
      case "green":
        return Colors.green;
      default:
        return blueAccentSwatch;
    }
  }
}
