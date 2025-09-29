import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:reviewfood/models/review.dart';
import 'package:reviewfood/services/api_service.dart';
import '../profile/settings_provider.dart';
import 'package:reviewfood/pages/profile/app_localizations.dart';

class AddRestaurantReviewPage extends StatefulWidget {
  const AddRestaurantReviewPage({super.key});

  @override
  State<AddRestaurantReviewPage> createState() =>
      _AddRestaurantReviewPageState();
}

class _AddRestaurantReviewPageState extends State<AddRestaurantReviewPage> {
  // --- Form nhà hàng ---
  final _restaurantFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _restaurantAdded = false;
  int? _restaurantId;
  List<Map<String, dynamic>> _existingRestaurants = [];

  // --- Form review ---
  final _reviewFormKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  int _rating = 5;
  List<File> _images = [];
  final picker = ImagePicker();
  bool _loading = false;

  // --- Chọn ảnh ---
  Future<void> _pickImages() async {
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      setState(() {
        _images.addAll(pickedFiles.map((f) => File(f.path)));
      });
    }
  }

  // --- Thêm nhà hàng ---
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
        // Lấy danh sách nhà hàng từ server
        try {
          final restaurants = await ApiService().getRestaurants();
          // Lọc những nhà hàng có cùng tên
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
        } catch (_) {
          // fallback: dùng dữ liệu cũ
          final start = msg.indexOf('{');
          final end = msg.lastIndexOf('}') + 1;
          Map<String, dynamic> restaurantData = {};
          if (start >= 0 && end > start) {
            restaurantData = Map<String, dynamic>.from(
              jsonDecode(msg.substring(start, end))['restaurant'],
            );
          }
          setState(() {
            _existingRestaurants = [restaurantData];
          });
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Nhà hàng đã tồn tại")));
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

  // --- Thêm review ---
  Future<void> _submitReview() async {
    if (_restaurantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tRead('please_add_restaurant_first'))),
      );
      return;
    }

    if (!_reviewFormKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      Review review = await ApiService().addReview(
        restaurantId: _restaurantId!,
        rating: _rating,
        content: _contentController.text,
        images: _images,
      );
      if (!mounted) return;
      Navigator.pop(context, review);
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
    context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(context.t('add_review_with_restaurant'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // --- Form nhà hàng ---
            Form(
              key: _restaurantFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.t('restaurant_info'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: context.t('restaurant_name'),
                      border: const OutlineInputBorder(),
                    ),
                    validator:
                        (val) =>
                            val == null || val.isEmpty
                                ? context.tRead('enter_name')
                                : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: context.t('restaurant_address'),
                      border: const OutlineInputBorder(),
                    ),
                    validator:
                        (val) =>
                            val == null || val.isEmpty
                                ? context.tRead('enter_address')
                                : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: context.t('restaurant_description'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _addRestaurant,
                      child:
                          _loading
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : Text(context.tRead('add_restaurant')),
                    ),
                  ),
                  // --- Hiển thị danh sách nhà hàng trùng ---
                  if (_existingRestaurants.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        Text(
                          context.t('existing_restaurants'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: 200, // giới hạn chiều cao, tuỳ chỉnh
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: _existingRestaurants.length,
                              itemBuilder: (context, index) {
                                final r = _existingRestaurants[index];
                                return ListTile(
                                  title: Text(r['name'] ?? ''),
                                  subtitle: Text(r['address'] ?? ''),
                                  onTap: () {
                                    setState(() {
                                      _restaurantAdded = true;
                                      _restaurantId = r['id'];
                                      _existingRestaurants = [];
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "Chọn nhà hàng: ${r['name']}",
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- Form review ---
            if (_restaurantAdded)
              Form(
                key: _reviewFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.t('review_info'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Chọn sao
                    Row(
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < _rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                          ),
                          onPressed: () => setState(() => _rating = index + 1),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _contentController,
                      decoration: InputDecoration(
                        labelText: context.t('review_content'),
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator:
                          (val) =>
                              val == null || val.isEmpty
                                  ? context.tRead('enter_content')
                                  : null,
                    ),
                    const SizedBox(height: 12),
                    // Chọn ảnh
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ..._images.map(
                          (file) => Stack(
                            children: [
                              Image.file(
                                file,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: GestureDetector(
                                  onTap:
                                      () =>
                                          setState(() => _images.remove(file)),
                                  child: const CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.red,
                                    child: Icon(
                                      Icons.close,
                                      size: 14,
                                      color: Colors.white,
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
                            width: 100,
                            height: 100,
                            color: Colors.grey[300],
                            child: const Icon(Icons.add),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submitReview,
                        child:
                            _loading
                                ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                                : Text(context.tRead('submit_review')),
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
