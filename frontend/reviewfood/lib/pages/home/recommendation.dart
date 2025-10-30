import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../models/restaurant.dart';
import '../profile/settings_provider.dart';
import '../restaurant/restaurant_detail_page.dart';
import '../profile/app_localizations.dart';

class RecommendationWidget extends StatefulWidget {
  final int topN;
  final double alpha;

  const RecommendationWidget({super.key, this.topN = 5, this.alpha = 0.6});

  @override
  State<RecommendationWidget> createState() => _RecommendationWidgetState();
}

class _RecommendationWidgetState extends State<RecommendationWidget>
    with SingleTickerProviderStateMixin {
  late Future<List<Restaurant>> _recommendationsFuture;
  late AnimationController _rotateController;

  @override
  void initState() {
    super.initState();

    // ✅ Gán giá trị mặc định để tránh lỗi late init
    _recommendationsFuture = Future.value([]);

    // ✅ Khởi tạo animation controller
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    // ✅ Sau khi widget đã dựng, mới gọi load dữ liệu thật
    _loadRecommendations();
  }

  @override
  void dispose() {
    _rotateController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant RecommendationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.topN != widget.topN || oldWidget.alpha != widget.alpha) {
      _loadRecommendations();
    }
  }

  // ✅ Load dữ liệu gợi ý từ backend AI
  void _loadRecommendations() async {
    final token = await ApiService().getToken();

    if (!mounted) return; // tránh crash khi widget bị dispose

    if (token == null || token.isEmpty) {
      setState(() {
        _recommendationsFuture = Future.error("not_logged_in");
      });
      return;
    }

    setState(() {
      _recommendationsFuture = ApiService().getRecommendations(
        topN: widget.topN,
        alpha: widget.alpha,
      );
    });
  }

  // 🔁 Làm mới dữ liệu gợi ý + hiệu ứng xoay icon
  void reloadRecommendations() {
    _rotateController.forward(from: 0);
    setState(() {
      _recommendationsFuture = ApiService().getRecommendations(
        topN: widget.topN,
        alpha: widget.alpha,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();
    final fontScale = settings.fontSize / 14.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔄 Icon refresh góc phải trên
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 10, top: 4, bottom: 6),
            child: RotationTransition(
              turns: Tween(begin: 0.0, end: 1.0).animate(_rotateController),
              child: IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 26),
                color: primary,
                tooltip: "Làm mới gợi ý",
                splashRadius: 22,
                onPressed: reloadRecommendations,
              ),
            ),
          ),
        ),

        // 🔽 Danh sách gợi ý
        FutureBuilder<List<Restaurant>>(
          future: _recommendationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox(
                height: 220,
                child: Center(child: CircularProgressIndicator(color: primary)),
              );
            } else if (snapshot.hasError) {
              if (snapshot.error == "not_logged_in") {
                // 🔐 Nếu chưa đăng nhập
                return _buildMessage(
                  context.t('login_to_see_recommendations'),
                  theme,
                );
              } else {
                return _buildMessage(context.t('recommendation_error'), theme);
              }
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildMessage("Không có gợi ý nào 😅", theme);
            }

            final recs = snapshot.data!;

            return SizedBox(
              height: 230,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: recs.length,
                itemBuilder: (context, index) {
                  final r = recs[index];
                  return _buildRestaurantCard(
                    context,
                    r,
                    theme,
                    primary,
                    isDark,
                    fontScale,
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  // 🧩 Helper hiển thị lỗi / không có dữ liệu
  Widget _buildMessage(String message, ThemeData theme) {
    return SizedBox(
      height: 220,
      child: Center(
        child: Text(message, style: TextStyle(color: theme.hintColor)),
      ),
    );
  }

  // 🧱 Thẻ nhà hàng
  Widget _buildRestaurantCard(
    BuildContext context,
    Restaurant r,
    ThemeData theme,
    Color primary,
    bool isDark,
    double fontScale,
  ) {
    return Container(
      width: 165,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow:
            isDark
                ? []
                : [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        splashColor: primary.withOpacity(0.15),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RestaurantDetailPage(restaurantId: r.id),
            ),
          );
          reloadRecommendations(); // reload khi quay lại
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼 Ảnh nhà hàng
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  child:
                      r.imageUrl != null && r.imageUrl!.isNotEmpty
                          ? FadeInImage.assetNetwork(
                            placeholder: 'assets/images/food.jpg',
                            image: r.imageUrl!,
                            width: double.infinity,
                            height: 120,
                            fit: BoxFit.cover,
                            imageErrorBuilder:
                                (_, __, ___) => Container(
                                  width: double.infinity,
                                  height: 120,
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.broken_image_outlined,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                          )
                          : Container(
                            width: double.infinity,
                            height: 120,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  primary.withOpacity(0.6),
                                  primary.withOpacity(0.9),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Icon(
                              Icons.fastfood_rounded,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                ),
                // 💧 Overlay gradient dịu
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18),
                      ),
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.15),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // 📜 Thông tin
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15 * fontScale,
                      fontWeight: FontWeight.w700,
                      color: primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    r.address ?? "Đang cập nhật địa chỉ",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13 * fontScale,
                      color: theme.hintColor,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
