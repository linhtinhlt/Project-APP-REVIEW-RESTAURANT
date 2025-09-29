import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reviewfood/services/api_service.dart';
import 'package:reviewfood/models/review.dart';
import 'package:reviewfood/models/comment.dart';
import '../profile/settings_provider.dart';
import 'package:reviewfood/pages/profile/app_localizations.dart';
import 'add_restaurant_review.dart';

class ReviewFeedPage extends StatefulWidget {
  const ReviewFeedPage({super.key});

  @override
  State<ReviewFeedPage> createState() => _ReviewFeedPageState();
}

class _ReviewFeedPageState extends State<ReviewFeedPage> {
  final ApiService _apiService = ApiService();
  late Future<List<Review>> _reviewsFuture;
  final Map<int, TextEditingController> _commentControllers = {};

  @override
  void initState() {
    super.initState();
    _reviewsFuture = _apiService.getAllReviews();
  }

  Future<void> _toggleLike(Review review) async {
    final oldLiked = review.isLiked;

    // Optimistic update
    setState(() {
      review.isLiked = !review.isLiked;
      review.likesCount += review.isLiked ? 1 : -1;
    });

    try {
      bool success = await _apiService.toggleLikeReview(review.id, oldLiked);

      if (!success) {
        // Rollback nếu API fail
        setState(() {
          review.isLiked = oldLiked;
          review.likesCount = review.likesCount + (oldLiked ? 1 : -1);
        });
      }
    } catch (e) {
      // Rollback nếu có exception
      setState(() {
        review.isLiked = oldLiked;
        review.likesCount = review.likesCount + (oldLiked ? 1 : -1);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${context.tRead('like_error')}: $e")),
      );
    }
  }

  Future<void> _sendComment(Review review) async {
    final controller = _commentControllers[review.id]!;
    final text = controller.text.trim();
    if (text.isNotEmpty) {
      bool success = await _apiService.addComment(review.id, text);
      if (success) {
        controller.clear();
        setState(() {});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tRead('comment_failed'))),
        );
      }
    }
  }

  Widget _buildComments(Review review, ThemeData theme) {
    return FutureBuilder<List<Comment>>(
      future: _apiService.getComments(review.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(8),
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError) {
          return Text("${context.tRead('error')}: ${snapshot.error}");
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(8),
            child: Text(context.t('no_comments')),
          );
        }

        final comments = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:
              comments.map((c) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundImage:
                            (c.user.avatar?.isNotEmpty ?? false)
                                ? NetworkImage(
                                  ApiService.getFullImageUrl(c.user.avatar!),
                                )
                                : const AssetImage("assets/images/avatar.jpg")
                                    as ImageProvider,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.user.name,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(c.content),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
        );
      },
    );
  }

  Widget _buildReviewCard(Review review, ThemeData theme) {
    _commentControllers.putIfAbsent(review.id, () => TextEditingController());

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar + tên user + tên quán
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
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if ((review.restaurantName ?? '').isNotEmpty)
                        Text(
                          review.restaurantName!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Nội dung review
            Text(review.content, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 10),

            // Ảnh review
            if (review.images.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  ApiService.getFullImageUrl(review.images[0].imageUrl),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            if (review.images.isNotEmpty) const SizedBox(height: 10),

            // Like + số lượng
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    review.isLiked ? Icons.favorite : Icons.favorite_border,
                    color: review.isLiked ? Colors.red : theme.iconTheme.color,
                  ),
                  onPressed: () => _toggleLike(review),
                ),
                Text("${review.likesCount}"),
              ],
            ),

            const Divider(),

            // Comments
            _buildComments(review, theme),

            const SizedBox(height: 10),

            // Input comment
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentControllers[review.id],
                    decoration: InputDecoration(
                      hintText: context.t('write_comment'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      filled: true,
                      fillColor: theme.cardColor,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.send,
                    color: Colors.blueAccent,
                  ), // đổi sang xanh
                  onPressed: () => _sendComment(review),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(30),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          alignment: Alignment.centerLeft,
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[900]
                  : const Color.fromARGB(255, 238, 244, 255),
          child: Text(
            context.t('review_feed'),
            style: const TextStyle(
              color: Colors.blueAccent, // đổi sang xanh
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),

      body: SafeArea(
        child: FutureBuilder<List<Review>>(
          future: _reviewsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Colors.blueAccent, // đổi sang xanh
                ),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text("${context.tRead('error')}: ${snapshot.error}"),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text(context.t('no_reviews')));
            }

            final reviews = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                return _buildReviewCard(reviews[index], theme);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent, // đổi sang xanh
        onPressed: () async {
          final newReview = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddRestaurantReviewPage(),
            ),
          );

          if (newReview != null) {
            setState(() {});
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
