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

  @override
  void initState() {
    super.initState();
    futureCategories = ApiService().getCategories();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    context.watch<SettingsProvider>(); // rebuild khi language thay đổi

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(30),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          alignment: Alignment.centerLeft,
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[900] // màu nền tối khi dark mode
                  : const Color.fromARGB(255, 238, 244, 255), // màu sáng
          child: Text(
            context.t('category_title'),
            style: TextStyle(
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : const Color.fromARGB(255, 64, 104, 165),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),

      body: FutureBuilder<List<Category>>(
        future: futureCategories,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text("${context.t('error')}: ${snapshot.error}"),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text(context.t('no_categories')));
          }

          final categories = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(12),
            child: GridView.builder(
              itemCount: categories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.95,
              ),
              itemBuilder: (context, index) {
                final c = categories[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 3,
                  color: theme.cardColor,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        c.image != null && c.image!.isNotEmpty
                            ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                c.image!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            )
                            : Icon(
                              Icons.fastfood,
                              size: 50,
                              color: theme.colorScheme.primary,
                            ),
                        const SizedBox(height: 12),
                        Text(
                          c.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
