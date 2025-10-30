import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reviewfood/services/api_service.dart';
import 'package:reviewfood/models/review.dart';
import '../profile/settings_provider.dart';
import '../profile/app_localizations.dart';
import '../restaurant/restaurant_detail_page.dart';
import 'comments_widget.dart';

class ReviewDetailPage extends StatefulWidget {
  final int reviewId;
  const ReviewDetailPage({super.key, required this.reviewId});

  @override
  State<ReviewDetailPage> createState() => _ReviewDetailPageState();
}

class _ReviewDetailPageState extends State<ReviewDetailPage>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  Review? _review;
  bool _loading = true;
  bool _error = false;
  int _commentReloadTick = 0;

  @override
  void initState() {
    super.initState();
    _loadReview();
  }

  Future<void> _loadReview() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final review = await _apiService.getReviewById(widget.reviewId);
      if (mounted) {
        setState(() {
          _review = review;
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
    final commentsKey = ValueKey('comments_${review.id}_$_commentReloadTick');

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

            Text(
              review.content,
              style: TextStyle(
                fontSize: 14.5 * fontScale,
                color: theme.textTheme.bodyMedium?.color,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 10),

            if (review.images.isNotEmpty) ...[
              const SizedBox(height: 8),
              _ReviewImageCarousel(images: review.images),
              const SizedBox(height: 12),
            ],

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
            const Divider(height: 24),

            ReviewCommentsWidget(
              key: commentsKey,
              review: review,
              fontScale: fontScale,
              onCommentSuccess: () {
                setState(() {
                  _commentReloadTick++;
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
    final fontScale = settings.fontSize / 14.0;

    final appBar = AppBar(
      title: Text(
        context.t('review_detail'),
        style: theme.appBarTheme.titleTextStyle,
      ),
      backgroundColor: theme.appBarTheme.backgroundColor,
      centerTitle: true,
      elevation: 0.5,
      iconTheme: theme.appBarTheme.iconTheme,
    );

    if (_loading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: appBar,
        body: Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary),
        ),
      );
    }

    if (_error || _review == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: appBar,
        body: Center(
          child: Text(
            context.t('load_failed'),
            style: TextStyle(color: theme.hintColor),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: appBar,
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _loadReview,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 60),
            children: [_buildReviewCard(_review!, theme, fontScale)],
          ),
        ),
      ),
    );
  }
}

// 🖼️ Carousel ảnh + toàn màn hình
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
