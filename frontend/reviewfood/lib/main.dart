import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/home/home_page.dart';
import 'pages/login_page.dart';
import 'pages/profile/settings_provider.dart';
import 'pages/profile/settings_page.dart';
import 'pages/map/map_page.dart';
//import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart'; 

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
      builder: (context, settings, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Restaurant Review App',
          themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            primarySwatch: settings.getMaterialColor(),
            textTheme: Theme.of(
              context,
            ).textTheme.apply(fontSizeFactor: settings.fontSize / 14),
          ),
          darkTheme: ThemeData.dark().copyWith(
            textTheme: Theme.of(context).textTheme.apply(
              fontSizeFactor: settings.fontSize / 14,
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),
            scaffoldBackgroundColor: Colors.black,
            colorScheme: ColorScheme.dark(
              primary: settings.getMaterialColor(),
              onPrimary: Colors.white,
              secondary: Colors.white,
            ),
          ),
          initialRoute: '/home',
          routes: {
            '/home': (context) => HomePage(),
            '/login': (context) => LoginPage(),
            '/settings': (context) => SettingsPage(),
            '/map': (context) => MapPage(),
          },
        );
      },
    );
  }
}
