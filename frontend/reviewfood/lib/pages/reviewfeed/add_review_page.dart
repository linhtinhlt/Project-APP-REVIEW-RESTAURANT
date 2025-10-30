import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:reviewfood/models/review.dart';
import 'package:reviewfood/services/api_service.dart';
import '../profile/settings_provider.dart';
import 'package:reviewfood/pages/profile/app_localizations.dart';
import 'package:geolocator/geolocator.dart';

class AddReviewPage extends StatefulWidget {
  final int restaurantId;
  const AddReviewPage({super.key, required this.restaurantId});

  @override
  State<AddReviewPage> createState() => _AddReviewPageState();
}

class _AddReviewPageState extends State<AddReviewPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  int _rating = 5;
  List<File> _images = [];
  final picker = ImagePicker();
  bool _loading = false;

  Future<void> _pickImages() async {
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _images.addAll(pickedFiles.map((f) => File(f.path)));
      });
    }
  }

  Future<void> _submitReview({
    required bool isDark,
    required double fontScale,
    required Color primary,
  }) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final theme = Theme.of(context);

    try {
      Review review = await ApiService().addReview(
        restaurantId: widget.restaurantId,
        rating: _rating,
        content: _contentController.text,
        images: _images,
      );

      if (!mounted) return;
      await showDialog(
        context: context,
        builder:
            (ctx) => AlertDialog(
              backgroundColor: theme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                "🎉 ${context.tRead('review_added_success')}",
                style: TextStyle(
                  color: primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16 * fontScale,
                ),
              ),
              content: Text(
                context.tRead('review_added_msg'),
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 13.5 * fontScale,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    context.tRead('ok'),
                    style: TextStyle(color: primary, fontSize: 14 * fontScale),
                  ),
                ),
              ],
            ),
      );

      // 3️⃣ Hỏi có muốn cập nhật vị trí quán không (⚠️ dùng tRead)
      final confirm = await showDialog<bool>(
        context: context,
        builder:
            (ctx) => AlertDialog(
              backgroundColor: theme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                "📍 ${context.tRead('update_restaurant_location')}",
                style: TextStyle(
                  color: primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16 * fontScale,
                ),
              ),
              content: Text(
                context.tRead('confirm_use_current_location'),
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 13.5 * fontScale,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(
                    context.tRead('no'),
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                      fontSize: 14 * fontScale,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    context.tRead('yes'),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14 * fontScale,
                    ),
                  ),
                ),
              ],
            ),
      );

      if (confirm == true) {
        try {
          final pos = await Geolocator.getCurrentPosition();
          final success = await ApiService().updateRestaurantLocation(
            restaurantId: widget.restaurantId,
            latitude: pos.latitude,
            longitude: pos.longitude,
          );

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? context.tRead('update_location_success')
                    : context.tRead('update_location_failed'),
                style: TextStyle(fontSize: 13.5 * fontScale),
              ),
              backgroundColor: success ? Colors.green : Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "${context.tRead('error_getting_location')}: $e",
                style: TextStyle(fontSize: 13.5 * fontScale),
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${context.tRead('add_review_error')}: $e"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final fontScale = settings.fontSize / 14.0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.cardColor,
        elevation: 0.5,
        centerTitle: true,
        iconTheme: IconThemeData(color: primary),
        title: Text(
          context.t('add_review'),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16 * fontScale,
            color: primary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ⭐ Rating
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final filled = index < _rating;
                  return AnimatedScale(
                    scale: filled ? 1.1 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOutBack,
                    child: IconButton(
                      icon: Icon(
                        filled ? Icons.star_rounded : Icons.star_border_rounded,
                        color:
                            filled ? Colors.amber[600] : Colors.grey.shade400,
                        size: 34,
                      ),
                      onPressed: () => setState(() => _rating = index + 1),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 22),

              // 📝 Nội dung đánh giá
              TextFormField(
                controller: _contentController,
                style: TextStyle(
                  fontSize: 14.5 * fontScale,
                  color: theme.textTheme.bodyLarge?.color,
                ),
                decoration: InputDecoration(
                  hintText: context.t('review_content'),
                  hintStyle: TextStyle(
                    color: theme.hintColor,
                    fontSize: 13 * fontScale,
                  ),
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: theme.dividerColor.withOpacity(0.4),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: primary, width: 1.3),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                ),
                maxLines: 4,
                validator:
                    (val) =>
                        val == null || val.isEmpty
                            ? context.tRead('enter_content')
                            : null,
              ),
              const SizedBox(height: 20),

              // 🖼 Hình ảnh
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ..._images.map(
                    (file) => Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: theme.cardColor,
                            boxShadow:
                                isDark
                                    ? []
                                    : [
                                      BoxShadow(
                                        color: theme.shadowColor.withOpacity(
                                          0.08,
                                        ),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              file,
                              width: 95,
                              height: 95,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => setState(() => _images.remove(file)),
                            child: const CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.black45,
                              child: Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _pickImages,
                    child: Container(
                      width: 95,
                      height: 95,
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.dividerColor.withOpacity(0.4),
                          width: 1.2,
                        ),
                        boxShadow:
                            isDark
                                ? []
                                : [
                                  BoxShadow(
                                    color: theme.shadowColor.withOpacity(0.08),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                      ),
                      child: Icon(
                        Icons.add_a_photo_rounded,
                        color: primary,
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // 🔘 Nút gửi
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed:
                      _loading
                          ? null
                          : () {
                            final theme = Theme.of(context);
                            final settings = Provider.of<SettingsProvider>(
                              context,
                              listen: false,
                            );
                            _submitReview(
                              isDark: settings.isDarkMode,
                              fontScale: settings.fontSize / 14.0,
                              primary: theme.colorScheme.primary,
                            );
                          },

                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: isDark ? 0 : 3,
                    shadowColor: primary.withOpacity(0.2),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child:
                        _loading
                            ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.white,
                              ),
                            )
                            : Text(
                              context.tRead('submit_review'),
                              style: TextStyle(
                                fontSize: 15.5 * fontScale,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
