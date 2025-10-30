import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../models/category.dart';
import 'package:reviewfood/pages/category/RestaurantByCategory.dart';
import 'package:reviewfood/pages/profile/settings_provider.dart';
import 'package:reviewfood/pages/profile/app_localizations.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  late Future<List<Category>> futureCategories;
  int? _tappedIndex;

  @override
  void initState() {
    super.initState();
    futureCategories = ApiService().getCategories();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = settings.isDarkMode;
    final fontScale = settings.fontSize / 14.0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        top: false,
        child: FutureBuilder<List<Category>>(
          future: futureCategories,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: primary));
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  "${context.t('error')}: ${snapshot.error}",
                  style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Text(
                  context.t('no_categories'),
                  style: TextStyle(color: theme.hintColor),
                ),
              );
            }

            final categories = snapshot.data!;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: GridView.builder(
                itemCount: categories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.9,
                ),
                itemBuilder: (context, index) {
                  final c = categories[index];

                  return GestureDetector(
                    onTapDown: (_) => setState(() => _tappedIndex = index),
                    onTapUp: (_) => setState(() => _tappedIndex = null),
                    onTapCancel: () => setState(() => _tappedIndex = null),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => RestaurantByCategoryPage(
                                categoryId: c.id,
                                categoryName: c.name,
                              ),
                        ),
                      );
                    },
                    child: AnimatedScale(
                      scale: _tappedIndex == index ? 1.03 : 1.0,
                      duration: const Duration(milliseconds: 120),
                      curve: Curves.easeOut,
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow:
                              isDark
                                  ? []
                                  : [
                                    BoxShadow(
                                      color: theme.shadowColor.withOpacity(
                                        0.08,
                                      ),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 🖼 Ảnh danh mục
                            c.image != null && c.image!.isNotEmpty
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: Image.network(
                                    c.image!,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                )
                                : Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color:
                                        isDark
                                            ? Colors.grey[850]
                                            : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Icon(
                                    Icons.fastfood_rounded,
                                    color:
                                        isDark ? Colors.grey[400] : Colors.grey,
                                    size: 48,
                                  ),
                                ),
                            const SizedBox(height: 14),

                            // 🏷️ Tên danh mục
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Text(
                                c.name,
                                style: TextStyle(
                                  fontSize: 15 * fontScale,
                                  fontWeight: FontWeight.w600,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            const SizedBox(height: 8),

                            // ✅ Đường gạch nhỏ màu chủ đạo dưới tên
                            Container(
                              width: 36,
                              height: 3,
                              decoration: BoxDecoration(
                                color: primary.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
