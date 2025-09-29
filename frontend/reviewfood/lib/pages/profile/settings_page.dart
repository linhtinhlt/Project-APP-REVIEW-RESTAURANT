import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'settings_provider.dart';
import 'app_localizations.dart'; // nhớ import để dùng context.t()

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings =
        context
            .watch<
              SettingsProvider
            >(); // watch để rebuild khi language thay đổi

    return Scaffold(
      appBar: AppBar(title: Text(context.t('settings'))),
      body: ListView(
        children: [
          // Ngôn ngữ
          ListTile(
            title: Text(context.t('language')),
            trailing: DropdownButton<String>(
              value: settings.language,
              items: [
                DropdownMenuItem(value: "vi", child: Text("Tiếng Việt")),
                DropdownMenuItem(value: "en", child: Text("English")),
              ],
              onChanged: (value) {
                if (value != null) settings.updateLanguage(value);
              },
            ),
          ),
          Divider(),

          // Dark mode
          SwitchListTile(
            title: Text(context.t('dark_mode')),
            value: settings.isDarkMode,
            onChanged: (value) => settings.toggleDarkMode(value),
          ),
          Divider(),

          // Màu chủ đạo
          ListTile(
            title: Text(context.t('theme_color')),
            trailing: DropdownButton<String>(
              value: settings.themeColor,
              items: [
                DropdownMenuItem(value: "blue", child: Text("Xanh dương")),
                DropdownMenuItem(value: "red", child: Text("Đỏ")),
                DropdownMenuItem(value: "green", child: Text("Xanh lá")),
              ],
              onChanged: (value) {
                if (value != null) settings.updateThemeColor(value);
              },
            ),
          ),
          Divider(),

          // Font size
          ListTile(
            title: Text(context.t('font_size')),
            subtitle: Slider(
              value: settings.fontSize,
              min: 12,
              max: 24,
              divisions: 6,
              label: "${settings.fontSize.toInt()}",
              onChanged: (value) => settings.updateFontSize(value),
            ),
          ),
        ],
      ),
    );
  }
}
