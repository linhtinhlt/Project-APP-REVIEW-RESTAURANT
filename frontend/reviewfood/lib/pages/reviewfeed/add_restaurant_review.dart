import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
//import 'package:reviewfood/models/review.dart';
import 'package:reviewfood/services/api_service.dart';
import '../profile/settings_provider.dart';
import 'package:reviewfood/pages/profile/app_localizations.dart';
import 'package:geolocator/geolocator.dart';

class AddRestaurantReviewPage extends StatefulWidget {
  const AddRestaurantReviewPage({super.key});

  @override
  State<AddRestaurantReviewPage> createState() =>
      _AddRestaurantReviewPageState();
}

class _AddRestaurantReviewPageState extends State<AddRestaurantReviewPage>
    with TickerProviderStateMixin {
  final _restaurantFormKey = GlobalKey<FormState>();
  final _reviewFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contentController = TextEditingController();

  bool _restaurantAdded = false;
  int? _restaurantId;
  List<Map<String, dynamic>> _existingRestaurants = [];

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

  Future<void> _addRestaurant() async {
    if (!_restaurantFormKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final id = await ApiService().addBasicRestaurant(
        name: _nameController.text,
        address: _addressController.text,
        description:
            _descriptionController.text.isEmpty
                ? null
                : _descriptionController.text,
      );

      setState(() {
        _restaurantAdded = true;
        _restaurantId = id;
        _existingRestaurants = [];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tRead('restaurant_added_success'))),
      );
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('Nhà hàng đã tồn tại')) {
        try {
          final restaurants = await ApiService().getRestaurants();
          final existing =
              restaurants
                  .where(
                    (r) =>
                        r.name.toLowerCase() ==
                        _nameController.text.trim().toLowerCase(),
                  )
                  .toList();

          setState(() {
            _existingRestaurants =
                existing
                    .map(
                      (r) => {'id': r.id, 'name': r.name, 'address': r.address},
                    )
                    .toList();
          });
        } catch (_) {}
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Nhà hàng đã tồn tại")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${context.tRead('restaurant_added_error')}: $e"),
          ),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _submitReview() async {
    if (_restaurantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tRead('please_add_restaurant_first'))),
      );
      return;
    }

    if (!_reviewFormKey.currentState!.validate()) return;

    final theme = Theme.of(context);
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final isDark = settings.isDarkMode;
    final fontScale = settings.fontSize / 14.0;
    final primary = theme.colorScheme.primary;

    setState(() => _loading = true);

    try {
      // 1️⃣ Gửi review
      await ApiService().addReview(
        restaurantId: _restaurantId!,
        rating: _rating,
        content: _contentController.text,
        images: _images,
      );

      if (!mounted) return;

      // 2️⃣ Hiển thị dialog thêm review thành công
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

      // 3️⃣ Hỏi có muốn cập nhật vị trí quán không
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

      // 4️⃣ Nếu người dùng chọn Có → cập nhật vị trí hiện tại
      if (confirm == true) {
        try {
          final pos = await Geolocator.getCurrentPosition();
          final success = await ApiService().updateRestaurantLocation(
            restaurantId: _restaurantId!,
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

      // 5️⃣ Quay lại và reload trang gọi trước
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${context.tRead('add_review_error')}: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
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
        title: Text(
          context.t('add_review_with_restaurant'),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16 * fontScale,
            color: primary,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: primary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            // --- FORM: Restaurant ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow:
                    isDark
                        ? []
                        : [
                          BoxShadow(
                            color: theme.shadowColor.withOpacity(0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
              ),
              child: Form(
                key: _restaurantFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.t('restaurant_info'),
                      style: TextStyle(
                        fontSize: 16 * fontScale,
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    _buildTextField(
                      controller: _nameController,
                      label: context.t('restaurant_name'),
                      enabled: !_restaurantAdded,
                      validatorText: context.tRead('enter_name'),
                      theme: theme,
                      fontScale: fontScale,
                    ),
                    const SizedBox(height: 10),

                    _buildTextField(
                      controller: _addressController,
                      label: context.t('restaurant_address'),
                      enabled: !_restaurantAdded,
                      validatorText: context.tRead('enter_address'),
                      theme: theme,
                      fontScale: fontScale,
                    ),
                    const SizedBox(height: 10),

                    _buildTextField(
                      controller: _descriptionController,
                      label: context.t('restaurant_description'),
                      enabled: !_restaurantAdded,
                      maxLines: 2,
                      theme: theme,
                      fontScale: fontScale,
                    ),
                    const SizedBox(height: 16),

                    // Add button
                    SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            _loading || _restaurantAdded
                                ? null
                                : _addRestaurant,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 3,
                        ),
                        child:
                            _loading
                                ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                                : Text(
                                  context.tRead('add_restaurant'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.5 * fontScale,
                                    color: Colors.white,
                                  ),
                                ),
                      ),
                    ),
                    if (_existingRestaurants.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: _buildExistingList(context, theme, fontScale),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // --- FORM: Review ---
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child:
                  _restaurantAdded
                      ? _buildReviewForm(context, settings, theme, primary)
                      : _buildPlaceholder(context, theme, primary, fontScale),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required ThemeData theme,
    required double fontScale,
    bool enabled = true,
    String? validatorText,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      enabled: enabled,
      style: TextStyle(
        fontSize: 14 * fontScale,
        color: theme.textTheme.bodyLarge?.color,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: theme.hintColor, fontSize: 13 * fontScale),
        filled: true,
        fillColor: theme.cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.3),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 14,
        ),
      ),
      validator:
          validatorText == null
              ? null
              : (val) => val == null || val.isEmpty ? validatorText : null,
    );
  }

  Widget _buildExistingList(
    BuildContext context,
    ThemeData theme,
    double fontScale,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withOpacity(0.4)),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _existingRestaurants.length,
        itemBuilder: (_, i) {
          final r = _existingRestaurants[i];
          return ListTile(
            title: Text(
              r['name'] ?? '',
              style: TextStyle(fontSize: 14.5 * fontScale),
            ),
            subtitle: Text(
              r['address'] ?? '',
              style: TextStyle(
                color: theme.hintColor,
                fontSize: 13 * fontScale,
              ),
            ),
            onTap: () {
              setState(() {
                _restaurantAdded = true;
                _restaurantId = r['id'];
                _existingRestaurants = [];
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Chọn nhà hàng: ${r['name']}")),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildReviewForm(
    BuildContext context,
    SettingsProvider settings,
    ThemeData theme,
    Color primary,
  ) {
    final fontScale = settings.fontSize / 14.0;
    final isDark = settings.isDarkMode;

    return Form(
      key: _reviewFormKey,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow:
              isDark
                  ? []
                  : [
                    BoxShadow(
                      color: theme.shadowColor.withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.t('review_info'),
              style: TextStyle(
                fontSize: 16 * fontScale,
                fontWeight: FontWeight.bold,
                color: primary,
              ),
            ),
            const SizedBox(height: 10),

            // ⭐ Rating
            Row(
              children: List.generate(5, (i) {
                final filled = i < _rating;
                return AnimatedScale(
                  scale: filled ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: IconButton(
                    icon: Icon(
                      filled ? Icons.star_rounded : Icons.star_border_rounded,
                      color: filled ? Colors.amber[600] : theme.hintColor,
                      size: 30,
                    ),
                    onPressed: () => setState(() => _rating = i + 1),
                  ),
                );
              }),
            ),
            const SizedBox(height: 10),

            _buildTextField(
              controller: _contentController,
              label: context.t('review_content'),
              validatorText: context.tRead('enter_content'),
              maxLines: 3,
              theme: theme,
              fontScale: fontScale,
            ),
            const SizedBox(height: 14),

            // 🖼 Image list
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ..._images.map(
                  (file) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          file,
                          width: 95,
                          height: 95,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => setState(() => _images.remove(file)),
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.black45,
                            child: const Icon(
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
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: theme.dividerColor.withOpacity(0.4),
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
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            SizedBox(
              height: 50,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
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
                            fontSize: 15 * fontScale,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(
    BuildContext context,
    ThemeData theme,
    Color primary,
    double fontScale,
  ) {
    return Container(
      key: const ValueKey('placeholder'),
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        context.tRead('please_add_restaurant_first'),
        style: TextStyle(
          color: primary,
          fontSize: 14 * fontScale,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
