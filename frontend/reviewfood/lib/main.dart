import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/home/home_page.dart';
import 'pages/login_page.dart';
import 'pages/profile/settings_provider.dart';
import 'pages/profile/settings_page.dart';
import 'pages/map/map_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ChangeNotifierProvider(
      create: (_) => SettingsProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        // 🌈 Font scale nhẹ, 16 là gốc chuẩn
        final baseFontScale = (0.97 + (settings.fontSize - 12) * 0.01).clamp(
          0.9,
          1.2,
        );

        // ✅ Nhận màu chủ đạo người dùng chọn (blue/red/green)
        final primarySwatch = settings.getMaterialColor();

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Restaurant Review App',

          // 🌗 Chế độ sáng / tối
          themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,

          // 🌞 Chủ đề sáng
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            primarySwatch: primarySwatch,
            colorScheme: ColorScheme.fromSwatch(
              primarySwatch: primarySwatch,
              accentColor: primarySwatch,
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
            cardColor: Colors.white,
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.white,
              elevation: 0.3,
              iconTheme: IconThemeData(color: primarySwatch),
              titleTextStyle: TextStyle(
                color: primarySwatch,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              backgroundColor: Colors.white,
              selectedItemColor: primarySwatch,
              unselectedItemColor: Colors.grey[500],
              type: BottomNavigationBarType.fixed,
            ),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Color(0xFF1C1C1C)),
              bodyMedium: TextStyle(color: Color(0xFF2C2C2C)),
              bodySmall: TextStyle(color: Color(0xFF4D4D4D)),
            ),
            iconTheme: IconThemeData(color: primarySwatch),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
            ),
            sliderTheme: SliderThemeData(
              activeTrackColor: primarySwatch,
              thumbColor: primarySwatch,
              overlayColor: primarySwatch.withOpacity(0.2),
            ),
            shadowColor: Colors.black12,
          ),

          // 🌙 Chủ đề tối
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            primarySwatch: primarySwatch,
            colorScheme: ColorScheme.fromSwatch(
              primarySwatch: primarySwatch,
              accentColor: primarySwatch,
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF0E1114),
            cardColor: const Color(0xFF1A1D21),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1A1D21),
              elevation: 0.3,
              iconTheme: IconThemeData(color: Colors.white),
              titleTextStyle: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              backgroundColor: const Color(0xFF1A1D21),
              selectedItemColor: primarySwatch,
              unselectedItemColor: Colors.grey,
              type: BottomNavigationBarType.fixed,
            ),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.white),
              bodyMedium: TextStyle(color: Colors.white70),
              bodySmall: TextStyle(color: Colors.white54),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF1E1E1E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(24)),
                borderSide: BorderSide.none,
              ),
            ),
            sliderTheme: SliderThemeData(
              activeTrackColor: primarySwatch,
              thumbColor: primarySwatch,
              overlayColor: primarySwatch.withOpacity(0.2),
            ),
            shadowColor: Colors.transparent,
          ),

          // ✅ Áp dụng scale chữ nhẹ toàn app
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            return MediaQuery(
              data: mq.copyWith(textScaler: TextScaler.linear(baseFontScale)),
              child: child ?? const SizedBox.shrink(),
            );
          },

          // 📍 Các route
          initialRoute: '/home',
          routes: {
            '/home': (_) => const HomePage(),
            '/login': (_) => const LoginPage(),
            '/settings': (_) => const SettingsPage(),
            '/map': (_) => const MapPage(),
          },
        );
      },
    );
  }
}
