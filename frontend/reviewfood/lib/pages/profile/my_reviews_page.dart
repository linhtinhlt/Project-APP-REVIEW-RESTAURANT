import 'package:flutter/material.dart';
import '../../models/review.dart';
import '../../services/api_service.dart';

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
  late Future<List<Review>> _commentedReviewsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  void _loadData() {
    _myReviewsFuture = api.getMyReviews();
    _likedReviewsFuture = api.getLikedReviews();
    _commentedReviewsFuture = api.getCommentedReviews();
  }

  Future<void> _toggleLike(Review review) async {
    final oldLiked = review.isLiked;
    setState(() {
      review.isLiked = !review.isLiked;
      review.likesCount += review.isLiked ? 1 : -1;
    });

    try {
      final success = await api.toggleLikeReview(review.id, oldLiked);
      if (!success) {
        // rollback nếu thất bại
        setState(() {
          review.isLiked = oldLiked;
          review.likesCount += oldLiked ? 1 : -1;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Thao tác thất bại')));
      } else if (oldLiked) {
        // Nếu là unlike, refresh list liked
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

  Widget _buildReviewItem(Review review, {bool showUnlike = false}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        title: Text(
          review.restaurantName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(review.content),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text('${review.rating}'),
                const SizedBox(width: 16),
                Icon(
                  review.isLiked ? Icons.thumb_up : Icons.thumb_up_off_alt,
                  size: 16,
                  color: review.isLiked ? Colors.blue : null,
                ),
                const SizedBox(width: 4),
                Text('${review.likesCount}'),
                const SizedBox(width: 16),
                Icon(Icons.comment, size: 16),
                const SizedBox(width: 4),
                Text('${review.comments.length}'),
              ],
            ),
            if (showUnlike)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _toggleLike(review),
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  label: const Text(
                    'Hủy thích',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
          ],
        ),
        onTap: () {
          // TODO: mở chi tiết review nếu muốn
        },
      ),
    );
  }

  Widget _buildReviewList(
    Future<List<Review>> future, {
    bool showUnlike = false,
  }) {
    return FutureBuilder<List<Review>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Chưa có dữ liệu'));
        }

        final reviews = snapshot.data!;
        return ListView.builder(
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            return _buildReviewItem(reviews[index], showUnlike: showUnlike);
          },
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý bài review"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Bài review của tôi"),
            Tab(text: "Đã bình luận"),
            Tab(text: "Đã thích"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReviewList(_myReviewsFuture),
          _buildReviewList(_commentedReviewsFuture),
          _buildReviewList(_likedReviewsFuture, showUnlike: true),
        ],
      ),
    );
  }
}
