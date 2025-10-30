import 'package:flutter/material.dart';
import 'package:reviewfood/models/comment.dart';
import 'package:reviewfood/models/review.dart';
import 'package:reviewfood/services/api_service.dart';
import '../profile/app_localizations.dart';

class ReviewCommentsWidget extends StatefulWidget {
  final Review review;
  final double fontScale;
  final VoidCallback? onCommentSuccess;

  const ReviewCommentsWidget({
    super.key,
    required this.review,
    required this.fontScale,
    this.onCommentSuccess,
  });

  @override
  State<ReviewCommentsWidget> createState() => _ReviewCommentsWidgetState();
}

class _ReviewCommentsWidgetState extends State<ReviewCommentsWidget> {
  final ApiService _api = ApiService();
  final TextEditingController _controller = TextEditingController();
  bool _showAll = false;
  bool _notLoggedIn = false;
  late Future<List<Comment>> _commentsFuture = Future.value([]);

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    try {
      final token = await _api.getToken();
      if (token == null || token.isEmpty) {
        setState(() => _notLoggedIn = true);
        return;
      }
      setState(() {
        _notLoggedIn = false;
        _commentsFuture = _api.getComments(widget.review.id);
      });
    } catch (_) {
      setState(() => _notLoggedIn = true);
    }
  }

  Future<void> _sendComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    try {
      final token = await _api.getToken();
      if (token == null || token.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.t('login_required')),
            backgroundColor: Colors.orangeAccent,
          ),
        );
        return;
      }

      final success = await _api.addComment(widget.review.id, text);
      if (!mounted) return;

      if (success) {
        _controller.clear();
        FocusScope.of(context).unfocus();

        // 🟢 FIXED AlertDialog: không bị tràn, có i18n
        await showDialog(
          context: context,
          builder:
              (ctx) => AlertDialog(
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.t('comment_success_title'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        softWrap: true,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ],
                ),
                content: Text(
                  context.t('comment_success_message'),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      context.t('ok'),
                      style: const TextStyle(color: Colors.green),
                    ),
                  ),
                ],
              ),
        );

        await _loadComments();
        widget.onCommentSuccess?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.t('comment_failed')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${context.t('error')}: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fontScale = widget.fontScale;

    if (_notLoggedIn) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              color: Colors.grey,
              size: 18,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                context.t('login_required'),
                style: TextStyle(
                  color: theme.hintColor,
                  fontSize: 13 * fontScale,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return FutureBuilder<List<Comment>>(
      future: _commentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(8),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        } else if (snapshot.hasError) {
          return Text("${context.t('error')}: ${snapshot.error}");
        }

        final comments = snapshot.data ?? [];
        comments.sort((a, b) => b.id.compareTo(a.id));
        final visible = _showAll ? comments : comments.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...visible.map(
              (c) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 16,
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
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[850] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.user.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5 * fontScale,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              c.content,
                              style: TextStyle(
                                fontSize: 13 * fontScale,
                                color: theme.textTheme.bodyMedium?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (comments.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 48),
                child: TextButton(
                  onPressed: () => setState(() => _showAll = !_showAll),
                  child: Text(
                    _showAll
                        ? context.t('collapse_comments')
                        : context.t('see_more_comments'),
                    style: TextStyle(
                      fontSize: 13 * fontScale,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[850] : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.grey.withOpacity(
                          0.25,
                        ), // 🌿 Viền xám mờ nhạt
                        width: 1,
                      ),
                      boxShadow:
                          isDark
                              ? []
                              : [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(
                                    0.08,
                                  ), // ☁ Shadow nhẹ
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                    ),
                    child: TextField(
                      controller: _controller,
                      style: TextStyle(
                        fontSize: 13.5 * fontScale,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                      decoration: InputDecoration(
                        hintText: context.t('write_comment'),
                        hintStyle: TextStyle(
                          color: Colors.grey.withOpacity(
                            0.6,
                          ), // ✨ Placeholder mềm hơn
                          fontSize: 13 * fontScale,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _sendComment,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: theme.colorScheme.primary,
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
