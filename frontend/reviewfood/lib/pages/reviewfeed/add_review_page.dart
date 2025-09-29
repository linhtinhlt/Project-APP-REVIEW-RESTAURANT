import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:reviewfood/models/review.dart';
import 'package:reviewfood/services/api_service.dart';
import '../profile/settings_provider.dart';
//import 'package:reviewfood/pages/profile/settings_provider.dart';
import 'package:reviewfood/pages/profile/app_localizations.dart';

class AddReviewPage extends StatefulWidget {
  final int restaurantId;

  const AddReviewPage({super.key, required this.restaurantId});

  @override
  State<AddReviewPage> createState() => _AddReviewPageState();
}

class _AddReviewPageState extends State<AddReviewPage> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  int _rating = 5;
  List<File> _images = [];
  final picker = ImagePicker();
  bool _loading = false;

  // Chọn nhiều ảnh
  Future<void> _pickImages() async {
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      setState(() {
        _images.addAll(pickedFiles.map((f) => File(f.path)));
      });
    }
  }

  // Submit review
  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      Review review = await ApiService().addReview(
        restaurantId: widget.restaurantId,
        rating: _rating,
        content: _contentController.text,
        images: _images,
      );

      if (!mounted) return;
      Navigator.pop(context, review);
    } catch (e) {
      if (!mounted) return;
      // 🔑 Dùng tRead thay vì t
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${context.tRead('add_review_error')}: $e")),
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
    // watch để rebuild khi đổi language
    context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('add_review')),
      ), // appbar giữ t vì rebuild được
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Chọn số sao
              Row(
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                    onPressed: () {
                      setState(() => _rating = index + 1);
                    },
                  );
                }),
              ),
              const SizedBox(height: 12),

              // Nội dung review
              TextFormField(
                controller: _contentController,
                decoration: InputDecoration(
                  labelText: context.t('review_content'),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
                // 🔑 validator chạy async nên dùng tRead
                validator:
                    (val) =>
                        val == null || val.isEmpty
                            ? context.tRead('enter_content')
                            : null,
              ),
              const SizedBox(height: 16),

              // Hiển thị ảnh đã chọn
              SizedBox(
                width: double.infinity,
                child: Wrap(
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
                              onTap: () {
                                setState(() => _images.remove(file));
                              },
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
              ),
              const Spacer(),

              // Nút submit
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submitReview,
                  child:
                      _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                            context.tRead('submit_review'),
                          ), // 🔑 đổi sang tRead
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
