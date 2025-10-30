import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'settings_provider.dart';
import 'app_localizations.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final fontScale = settings.fontSize / 14.0;
    final theme = Theme.of(context);
    final isDark = settings.isDarkMode;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0.5,
        title: Text(
          context.t('settings'),
          style: theme.appBarTheme.titleTextStyle?.copyWith(
            fontSize: 18 * fontScale,
          ),
        ),
        centerTitle: true,
        iconTheme: theme.appBarTheme.iconTheme,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // 🌐 Ngôn ngữ
          _buildSettingCard(
            context,
            title: context.t('language'),
            icon: Icons.language_rounded,
            child: DropdownButton<String>(
              value: settings.language,
              borderRadius: BorderRadius.circular(12),
              underline: const SizedBox(),
              style: TextStyle(
                fontSize: 15 * fontScale,
                color: theme.textTheme.bodyMedium?.color,
              ),
              items: const [
                DropdownMenuItem(value: "vi", child: Text("🇻🇳 Tiếng Việt")),
                DropdownMenuItem(value: "en", child: Text("🇬🇧 English")),
              ],
              onChanged: (value) {
                if (value != null) settings.updateLanguage(value);
              },
            ),
          ),
          const SizedBox(height: 16),

          // 🌙 Dark mode
          _buildSettingCard(
            context,
            title: context.t('dark_mode'),
            icon: Icons.dark_mode_rounded,
            child: Switch(
              activeColor: Colors.white, // ✅ nút tròn sáng, luôn thấy rõ
              trackColor: WidgetStateProperty.resolveWith<Color?>(
                (states) =>
                    states.contains(WidgetState.selected)
                        ? theme.colorScheme.primary.withOpacity(0.6)
                        : Colors.grey.withOpacity(0.3),
              ),
              value: settings.isDarkMode,
              onChanged: (value) => settings.toggleDarkMode(value),
            ),
          ),
          const SizedBox(height: 16),

          // 🎨 Màu chủ đạo
          _buildSettingCard(
            context,
            title: context.t('theme_color'),
            icon: Icons.palette_rounded,
            child: DropdownButton<String>(
              value: settings.themeColor,
              borderRadius: BorderRadius.circular(12),
              underline: const SizedBox(),
              style: TextStyle(
                fontSize: 15 * fontScale,
                color: theme.textTheme.bodyMedium?.color,
              ),
              items: [
                DropdownMenuItem(
                  value: "blue",
                  child: Row(
                    children: [
                      const Icon(
                        Icons.circle,
                        color: Color(0xFF46B5F1),
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(context.t('blue')),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: "red",
                  child: Row(
                    children: [
                      const Icon(
                        Icons.circle,
                        color: Colors.redAccent,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(context.t('red')),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: "green",
                  child: Row(
                    children: [
                      const Icon(Icons.circle, color: Colors.green, size: 14),
                      const SizedBox(width: 6),
                      Text(context.t('green')),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                if (value != null) settings.updateThemeColor(value);
              },
            ),
          ),

          const SizedBox(height: 28),

          // 🔠 Kích thước chữ
          Text(
            context.t('font_size'),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16 * fontScale,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow:
                  isDark
                      ? []
                      : const [
                        BoxShadow(
                          color: Color(0x11000000),
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 8,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 14,
                    ),
                    activeTrackColor: theme.colorScheme.primary,
                    inactiveTrackColor: Colors.grey[400],
                    thumbColor: theme.colorScheme.primary,
                  ),
                  child: Slider(
                    value: settings.fontSize,
                    min: 12,
                    max: 24,
                    divisions: 6,
                    label: "${settings.fontSize.toInt()}",
                    onChanged: (value) => settings.updateFontSize(value),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "${settings.fontSize.toInt()} pt",
                    style: TextStyle(
                      fontSize: 13 * fontScale,
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // 🔹 Widget Card setting item chung
  Widget _buildSettingCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final settings = context.read<SettingsProvider>();
    final fontScale = settings.fontSize / 14.0;
    final theme = Theme.of(context);
    final isDark = settings.isDarkMode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow:
            isDark
                ? []
                : const [
                  BoxShadow(
                    color: Color(0x11000000),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15.5 * fontScale,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
