import 'package:flutter/material.dart';
import 'package:reviewfood/models/category.dart';
import 'package:reviewfood/pages/category/RestaurantByCategory.dart';
import 'package:reviewfood/services/api_service.dart';

class CategoryWidget extends StatefulWidget {
  const CategoryWidget({super.key});

  @override
  State<CategoryWidget> createState() => _CategoryWidgetState();
}

class _CategoryWidgetState extends State<CategoryWidget> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  double _scrollProgress = 0.0;

  List<Category>? _categories; // ✅ lưu dữ liệu tĩnh để tránh rebuild ListView
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadCategories();
  }

  void _loadCategories() async {
    try {
      final data = await _apiService.getCategories();
      setState(() {
        _categories = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _categories == null) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll > 0) {
      setState(() {
        _scrollProgress = _scrollController.offset / maxScroll;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Text(
            "Lỗi: $_error",
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      );
    }

    final categories = _categories ?? [];
    if (categories.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(child: Text("Không có danh mục")),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 🔹 Danh mục có thể trượt ngang
        SizedBox(
          height: 120,
          child: ListView.separated(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final c = categories[index];
              return Column(
                children: [
                  InkWell(
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
                    borderRadius: BorderRadius.circular(50),
                    child: CircleAvatar(
                      radius: 35,
                      backgroundColor: theme.cardColor,
                      backgroundImage:
                          (c.image != null && c.image!.isNotEmpty)
                              ? NetworkImage(c.image!)
                              : null,
                      child:
                          (c.image == null || c.image!.isEmpty)
                              ? const Icon(
                                Icons.fastfood,
                                color: Colors.blueAccent,
                                size: 30,
                              )
                              : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 70,
                    child: Text(
                      c.name,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        // 🔹 Thanh chỉ thị cuộn
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final indicatorWidth = constraints.maxWidth * 0.25;
              final leftOffset =
                  _scrollProgress * (constraints.maxWidth - indicatorWidth);

              return Stack(
                children: [
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 150),
                    left: leftOffset,
                    child: Container(
                      height: 3,
                      width: indicatorWidth,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color.fromARGB(255, 123, 203, 247),
                            Color.fromARGB(255, 70, 181, 241),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
