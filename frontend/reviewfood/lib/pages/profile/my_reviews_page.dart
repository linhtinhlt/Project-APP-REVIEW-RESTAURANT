import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/review.dart';
import '../../models/comment.dart';
import '../../services/api_service.dart';
import '../profile/settings_provider.dart';

class MyReviewsPage extends StatefulWidget {
  const MyReviewsPage({super.key});

  @override
  State<MyReviewsPage> createState() => _MyReviewsPageState();
}

class _MyReviewsPageState extends State<MyReviewsPage>
    with SingleTickerProviderStateMixin {
  final ApiService api = ApiService();

  late TabController _tabController;
  late Future<List<Review>> _myReviewsFuture;
  late Future<List<Review>> _likedReviewsFuture;
  late Future<List<Comment>> _myCommentsFuture; // ✅ danh sách comment

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  void _loadData() {
    _myReviewsFuture = api.getMyReviews();
    _likedReviewsFuture = api.getLikedReviews();
    _myCommentsFuture = api.getMyComments(); // ✅ thêm future comment
  }

  // ❤️ Like / Unlike
  Future<void> _toggleLike(Review review) async {
    final oldLiked = review.isLiked;
    setState(() {
      review.isLiked = !review.isLiked;
      review.likesCount += review.isLiked ? 1 : -1;
    });

    try {
      final success = await api.toggleLikeReview(review.id, oldLiked);
      if (!success) {
        setState(() {
          review.isLiked = oldLiked;
          review.likesCount += oldLiked ? 1 : -1;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Thao tác thất bại')));
      } else if (oldLiked) {
        setState(() {
          _likedReviewsFuture = api.getLikedReviews();
        });
      }
    } catch (e) {
      setState(() {
        review.isLiked = oldLiked;
        review.likesCount += oldLiked ? 1 : -1;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  // 🗑️ Xoá review
  Future<void> _deleteReview(Review review) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Xoá bài review"),
            content: const Text(
              "Bạn có chắc chắn muốn xoá bài review này không?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Huỷ"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  "Xoá",
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
    );
    if (confirm != true) return;

    try {
      final success = await api.deleteReview(review.id);
      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Đã xoá bài review")));
        setState(() => _loadData());
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi khi xoá: $e")));
    }
  }

  // 🗑️ Xoá comment
  Future<void> _deleteComment(Comment c) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Xoá bình luận"),
            content: const Text(
              "Bạn có chắc chắn muốn xoá bình luận này không?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Huỷ"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  "Xoá",
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
    );
    if (confirm != true) return;

    try {
      final ok = await api.deleteComment(c.id);
      if (ok) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Đã xoá bình luận")));

        // ✅ Sửa lỗi ở đây — KHÔNG để setState trả về Future
        final newFuture = api.getMyComments();
        setState(() {
          _myCommentsFuture = newFuture;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi xoá bình luận: $e")));
    }
  }

  // 🔹 Item review
  Widget _buildReviewItem(
    BuildContext context,
    Review review, {
    bool showUnlike = false,
  }) {
    final theme = Theme.of(context);
    final settings = context.read<SettingsProvider>();
    final fontScale = settings.fontSize / 14.0;
    final primary = theme.colorScheme.primary;
    final isDark = settings.isDarkMode;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow:
            isDark
                ? []
                : [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🍴 Tên nhà hàng + nút xoá
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    review.restaurantName,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16 * fontScale,
                      color: primary,
                    ),
                  ),
                ),
                if (!showUnlike)
                  IconButton(
                    onPressed: () => _deleteReview(review),
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                    ),
                    tooltip: "Xoá bài review",
                  ),
              ],
            ),
            const SizedBox(height: 6),
            // 📝 Nội dung review
            Text(
              review.content,
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color,
                height: 1.4,
                fontSize: 14 * fontScale,
              ),
            ),
            const SizedBox(height: 10),
            // ⭐ Rating + 👍 Like + 💬 Comment
            Row(
              children: [
                Icon(
                  Icons.star_rounded,
                  color: Colors.amber[600],
                  size: 18 * fontScale,
                ),
                const SizedBox(width: 4),
                Text(
                  "${review.rating}",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13.5 * fontScale,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(width: 14),
                GestureDetector(
                  onTap: () => _toggleLike(review),
                  child: AnimatedScale(
                    scale: review.isLiked ? 1.15 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutBack,
                    child: Icon(
                      review.isLiked
                          ? Icons.thumb_up_alt_rounded
                          : Icons.thumb_up_off_alt_rounded,
                      color:
                          review.isLiked
                              ? Colors.blueAccent
                              : Colors.grey.shade600,
                      size: 22 * fontScale,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  "${review.likesCount}",
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color,
                    fontSize: 13 * fontScale,
                  ),
                ),
                const SizedBox(width: 14),
                Icon(
                  Icons.comment_rounded,
                  size: 18 * fontScale,
                  color: primary,
                ),
                const SizedBox(width: 4),
                Text(
                  "${review.comments.length}",
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color,
                    fontSize: 13 * fontScale,
                  ),
                ),
              ],
            ),
            if (showUnlike)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _toggleLike(review),
                  icon: const Icon(
                    Icons.thumb_down_alt_rounded,
                    color: Colors.redAccent,
                  ),
                  label: const Text(
                    "Bỏ thích",
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 🔹 Danh sách review
  Widget _buildReviewList(
    Future<List<Review>> future, {
    bool showUnlike = false,
  }) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return FutureBuilder<List<Review>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: primary));
        } else if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'Chưa có dữ liệu',
              style: TextStyle(color: theme.hintColor),
            ),
          );
        }
        final reviews = snapshot.data!;
        return RefreshIndicator(
          color: primary,
          onRefresh: () async => setState(() => _loadData()),
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 20),
            itemCount: reviews.length,
            itemBuilder:
                (context, index) => _buildReviewItem(
                  context,
                  reviews[index],
                  showUnlike: showUnlike,
                ),
          ),
        );
      },
    );
  }

  // 🔹 Danh sách comment (đã bình luận)
  Widget _buildMyCommentsList(Future<List<Comment>> future) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return FutureBuilder<List<Comment>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: primary));
        } else if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'Bạn chưa bình luận bài nào',
              style: TextStyle(color: theme.hintColor),
            ),
          );
        }

        final comments = snapshot.data!;
        return RefreshIndicator(
          color: primary,
          onRefresh:
              () async =>
                  setState(() => _myCommentsFuture = api.getMyComments()),
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 20),
            itemCount: comments.length,
            itemBuilder: (context, i) {
              final c = comments[i];
              final restaurantName = c.review?.restaurantName ?? 'Ẩn danh';
              return ListTile(
                title: Text(c.content),
                subtitle: Text("Trong bài review: $restaurantName"),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                  ),
                  tooltip: "Xoá bình luận",
                  onPressed: () => _deleteComment(c),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final fontScale = settings.fontSize / 14.0;
    final isDark = settings.isDarkMode;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        title: Text(
          "Bài Review của tôi",
          style: theme.appBarTheme.titleTextStyle?.copyWith(
            fontSize: 18 * fontScale,
          ),
        ),
        centerTitle: true,
        elevation: 0.5,
        iconTheme: theme.appBarTheme.iconTheme,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(46),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            height: 38,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: isDark ? Colors.white70 : primary,
              indicator: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(20),
              ),
              labelStyle: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13.5 * fontScale,
              ),
              tabs: const [
                Tab(text: "Của tôi"),
                Tab(text: "Đã bình luận"),
                Tab(text: "Đã thích"),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReviewList(_myReviewsFuture),
          _buildMyCommentsList(_myCommentsFuture), // ✅ Tab “Đã bình luận”
          _buildReviewList(_likedReviewsFuture, showUnlike: true),
        ],
      ),
    );
  }
}
