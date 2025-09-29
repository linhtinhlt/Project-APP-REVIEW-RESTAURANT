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

  // Lấy MaterialColor từ string
  MaterialColor blueAccentSwatch = MaterialColor(
    0xFF448AFF, // màu chủ đạo
    <int, Color>{
      50: Color(0xFFE3F2FD),
      100: Color(0xFFBBDEFB),
      200: Color(0xFF90CAF9),
      300: Color(0xFF64B5F6),
      400: Color(0xFF42A5F5),
      500: Color(0xFF2196F3),
      600: Color(0xFF1E88E5),
      700: Color(0xFF1976D2),
      800: Color(0xFF1565C0),
      900: Color(0xFF0D47A1),
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
