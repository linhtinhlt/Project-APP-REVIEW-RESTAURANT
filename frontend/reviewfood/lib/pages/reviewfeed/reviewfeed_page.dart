import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reviewfood/services/api_service.dart';
import 'package:reviewfood/models/review.dart';
import '../profile/settings_provider.dart';
import '../profile/app_localizations.dart';
import 'add_restaurant_review.dart';
import '../restaurant/restaurant_detail_page.dart';
import 'comments_widget.dart';

class ReviewFeedPage extends StatefulWidget {
  const ReviewFeedPage({super.key});

  @override
  State<ReviewFeedPage> createState() => _ReviewFeedPageState();
}

class _ReviewFeedPageState extends State<ReviewFeedPage>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final Map<int, int> _commentReloadTick = {};
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

  List<Review> _reviews = [];
  bool _loading = true;
  bool _error = false;
  Key _feedKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(() {
      // Khi lướt xuống hơn 600px thì hiện nút
      if (_scrollController.offset > 600 && !_showScrollToTop) {
        setState(() => _showScrollToTop = true);
      } else if (_scrollController.offset <= 600 && _showScrollToTop) {
        setState(() => _showScrollToTop = false);
      }
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final reviews = await _apiService.getAllReviews();
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = true;
          _loading = false;
        });
      }
    }
  }

  Future<void> _toggleLike(Review review) async {
    final oldLiked = review.isLiked;
    final oldCount = review.likesCount;
    setState(() {
      review.isLiked = !oldLiked;
      review.likesCount += review.isLiked ? 1 : -1;
    });

    try {
      final success = await _apiService.toggleLikeReview(review.id, oldLiked);
      if (!success) {
        setState(() {
          review.isLiked = oldLiked;
          review.likesCount = oldCount;
        });
      }
    } catch (_) {
      setState(() {
        review.isLiked = oldLiked;
        review.likesCount = oldCount;
      });
    }
  }

  String _formatDate(String createdAt) {
    try {
      final date = DateTime.parse(createdAt);
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
    } catch (_) {
      return createdAt;
    }
  }

  Widget _buildReviewCard(Review review, ThemeData theme, double fontScale) {
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    final commentsKey = ValueKey(
      'comments_${review.id}_${_commentReloadTick[review.id] ?? 0}',
    );

    return Container(
      key: ValueKey(review.id),
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow:
            isDark
                ? []
                : [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🍽️ Tên quán
            if (review.restaurantName.isNotEmpty)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => RestaurantDetailPage(
                            restaurantId: review.restaurantId,
                          ),
                    ),
                  );
                },
                child: Text(
                  review.restaurantName,
                  style: TextStyle(
                    fontSize: 17 * fontScale,
                    fontWeight: FontWeight.w800,
                    color: primary,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            const SizedBox(height: 12),

            // 👤 Người đăng + thời gian
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage:
                      (review.userAvatar?.isNotEmpty ?? false)
                          ? NetworkImage(
                            ApiService.getFullImageUrl(review.userAvatar!),
                          )
                          : const AssetImage("assets/images/avatar.jpg")
                              as ImageProvider,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5 * fontScale,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        review.createdAt != null
                            ? _formatDate(review.createdAt!)
                            : '',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12 * fontScale,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ✍️ Nội dung review
            Text(
              review.content,
              style: TextStyle(
                fontSize: 14.5 * fontScale,
                color: theme.textTheme.bodyMedium?.color,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 10),

            // 🖼️ Ảnh review có thể nhấn zoom
            if (review.images.isNotEmpty) ...[
              const SizedBox(height: 8),
              _ReviewImageCarousel(images: review.images),
              const SizedBox(height: 12),
            ],

            // ❤️ Nút Like
            Row(
              children: [
                GestureDetector(
                  onTap: () => _toggleLike(review),
                  child: AnimatedScale(
                    scale: review.isLiked ? 1.15 : 1.0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutBack,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder:
                          (child, anim) =>
                              ScaleTransition(scale: anim, child: child),
                      child: Icon(
                        review.isLiked
                            ? Icons.thumb_up_alt_rounded
                            : Icons.thumb_up_off_alt_rounded,
                        key: ValueKey(review.isLiked),
                        color:
                            review.isLiked
                                ? Colors.redAccent
                                : (isDark ? Colors.white54 : Colors.grey),
                        size: 26,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  "${review.likesCount}",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13.5 * fontScale,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Divider(
            //   height: 24,
            //   color: Colors.grey.withOpacity(0.3), // 🌿 Màu xám nhạt
            //   thickness: 0.8, // Mảnh và nhẹ
            //   indent: 8, // Lùi nhẹ 2 bên
            //   endIndent: 8,
            // ),

            // 💬 Bình luận (từ widget riêng)
            ReviewCommentsWidget(
              key: commentsKey,
              review: review,
              fontScale: fontScale,
              onCommentSuccess: () {
                setState(() {
                  _commentReloadTick[review.id] =
                      (_commentReloadTick[review.id] ?? 0) + 1;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final fontScale = settings.fontSize / 14.0;

    if (_loading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: primary)),
      );
    }

    if (_error) {
      return Scaffold(
        body: Center(
          child: Text(
            "Không thể tải review 😢",
            style: TextStyle(color: theme.hintColor),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _loadData,
          child:
              _reviews.isEmpty
                  ? ListView(
                    children: [
                      const SizedBox(height: 200),
                      Center(
                        child: Text(
                          context.t('no_reviews'),
                          style: TextStyle(color: theme.hintColor),
                        ),
                      ),
                    ],
                  )
                  : ListView.builder(
                    controller: _scrollController,
                    key: _feedKey,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: _reviews.length,
                    itemBuilder:
                        (context, i) =>
                            _buildReviewCard(_reviews[i], theme, fontScale),
                  ),
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   backgroundColor: primary,
      //   elevation: 4,
      //   onPressed: () async {
      //     final newReview = await Navigator.push(
      //       context,
      //       MaterialPageRoute(builder: (_) => const AddRestaurantReviewPage()),
      //     );
      //     if (newReview != null) _loadData();
      //   },
      //   child: const Icon(Icons.add_rounded, size: 30, color: Colors.white),
      // ),
      floatingActionButton: Stack(
        children: [
          // 🟦 Nút thêm review
          Positioned(
            bottom: 0,
            right: 0,
            child: FloatingActionButton(
              backgroundColor: primary,
              elevation: 4,
              onPressed: () async {
                final newReview = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddRestaurantReviewPage(),
                  ),
                );
                if (newReview != null) _loadData();
              },
              child: const Icon(
                Icons.add_rounded,
                size: 30,
                color: Colors.white,
              ),
            ),
          ),

          // 🟨 Nút mũi tên lên đầu
          if (_showScrollToTop)
            Positioned(
              bottom: 80, 
              right: 0,
              child: FloatingActionButton(
                heroTag: 'scrollTop',
                mini: true,
                backgroundColor: const Color.fromARGB(255, 202, 208, 214),
                onPressed: () async {
                  await _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                  );
                  await _loadData(); 
                },
                child: const Icon(
                  Icons.arrow_upward_rounded,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}


class _ReviewImageCarousel extends StatefulWidget {
  final List images;
  const _ReviewImageCarousel({required this.images});

  @override
  State<_ReviewImageCarousel> createState() => _ReviewImageCarouselState();
}

class _ReviewImageCarouselState extends State<_ReviewImageCarousel> {
  final PageController _controller = PageController();
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: 230,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _controller,
                  itemCount: widget.images.length,
                  onPageChanged: (i) => setState(() => _current = i),
                  itemBuilder: (context, i) {
                    final img = ApiService.getFullImageUrl(
                      widget.images[i].imageUrl,
                    );
                    return GestureDetector(
                      onTap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => _FullScreenImagePage(
                                    images:
                                        widget.images
                                            .map(
                                              (e) => ApiService.getFullImageUrl(
                                                e.imageUrl,
                                              ),
                                            )
                                            .toList(),
                                    initialIndex: i,
                                  ),
                            ),
                          ),
                      child: FadeInImage.assetNetwork(
                        placeholder: 'assets/images/review.jpg',
                        image: img,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        imageErrorBuilder:
                            (_, __, ___) => Image.asset(
                              'assets/images/review.jpg',
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                      ),
                    );
                  },
                ),
                Positioned(
                  bottom: 8,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      widget.images.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: _current == i ? 10 : 6,
                        height: _current == i ? 10 : 6,
                        decoration: BoxDecoration(
                          color:
                              _current == i
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.white70,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// 🔍 Xem ảnh toàn màn hình có thể zoom
class _FullScreenImagePage extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _FullScreenImagePage({required this.images, this.initialIndex = 0});

  @override
  State<_FullScreenImagePage> createState() => _FullScreenImagePageState();
}

class _FullScreenImagePageState extends State<_FullScreenImagePage> {
  late PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.initialIndex);
    _index = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder:
                (context, i) => InteractiveViewer(
                  child: Center(
                    child: FadeInImage.assetNetwork(
                      placeholder: 'assets/images/review.jpg',
                      image: widget.images[i],
                      fit: BoxFit.contain,
                      imageErrorBuilder:
                          (_, __, ___) =>
                              Image.asset('assets/images/review.jpg'),
                    ),
                  ),
                ),
          ),
          Positioned(
            bottom: 20,
            child: Row(
              children: List.generate(
                widget.images.length,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _index == i ? 10 : 6,
                  height: _index == i ? 10 : 6,
                  decoration: BoxDecoration(
                    color:
                        _index == i
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
