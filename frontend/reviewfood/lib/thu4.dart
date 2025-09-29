//import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:reviewfood/services/api_service.dart';
// import 'package:reviewfood/models/restaurant.dart';
// import 'package:reviewfood/models/review.dart';
// import 'package:reviewfood/pages/reviewfeed/add_review_page.dart';
// import '../profile/settings_provider.dart';
// import 'package:reviewfood/pages/profile/app_localizations.dart';
// import 'restaurant_map_widget.dart';

// class RestaurantDetailPage extends StatefulWidget {
//   final int restaurantId;

//   const RestaurantDetailPage({super.key, required this.restaurantId});

//   @override
//   State<RestaurantDetailPage> createState() => _RestaurantDetailPageState();
// }

// class _RestaurantDetailPageState extends State<RestaurantDetailPage> {
//   final ApiService _apiService = ApiService();

//   late Future<Restaurant> _restaurantFuture;
//   late Future<List<Review>> _reviewsFuture;
//   Restaurant? _restaurantData;

//   @override
//   void initState() {
//     super.initState();
//     _restaurantFuture = _apiService.getRestaurantDetail(widget.restaurantId);
//     _reviewsFuture = _apiService.getReviewsByRestaurant(widget.restaurantId);
//   }

//   Future<void> _refreshReviews() async {
//     setState(() {
//       _reviewsFuture = _apiService.getReviewsByRestaurant(widget.restaurantId);
//     });
//   }

//   Future<bool> _toggleFavorite() async {
//     if (_restaurantData == null) return false;
//     final oldFavorite = _restaurantData!.isFavorite;
//     final oldCount = _restaurantData!.favoritesCount;

//     setState(() {
//       _restaurantData!.isFavorite = !oldFavorite;
//       _restaurantData!.favoritesCount += _restaurantData!.isFavorite ? 1 : -1;
//     });

//     final success = await _apiService.toggleFavoriteRestaurant(
//       _restaurantData!.id,
//       oldFavorite,
//     );

//     if (!success) {
//       // rollback nếu API fail
//       setState(() {
//         _restaurantData!.isFavorite = oldFavorite;
//         _restaurantData!.favoritesCount = oldCount;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Cập nhật yêu thích thất bại")),
//       );
//     }
//     return success;
//   }

//   @override
//   Widget build(BuildContext context) {
//     context.watch<SettingsProvider>();

//     return Scaffold(
//       body: FutureBuilder<Restaurant>(
//         future: _restaurantFuture,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           } else if (snapshot.hasError) {
//             return Center(
//               child: Text("${context.t('error')}: ${snapshot.error}"),
//             );
//           } else if (!snapshot.hasData) {
//             return Center(child: Text(context.t('no_data')));
//           }

//           // Lưu dữ liệu restaurant vào biến để toggle favorite
//           _restaurantData ??= snapshot.data!;
//           final r = _restaurantData!;

//           return CustomScrollView(
//             slivers: [
//               SliverAppBar(
//                 expandedHeight: 220,
//                 pinned: true,
//                 flexibleSpace: FlexibleSpaceBar(
//                   title: Text(
//                     r.name,
//                     style: const TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                       shadows: [Shadow(color: Colors.black54, blurRadius: 3)],
//                     ),
//                   ),
//                   background:
//                       r.imageUrl != null && r.imageUrl!.isNotEmpty
//                           ? Image.network(
//                             r.imageUrl!,
//                             width: double.infinity,
//                             height: 220,
//                             fit: BoxFit.cover,
//                             errorBuilder:
//                                 (_, __, ___) => Container(
//                                   color: Colors.grey[300],
//                                   child: const Icon(
//                                     Icons.broken_image,
//                                     size: 80,
//                                   ),
//                                 ),
//                           )
//                           : Container(
//                             color: Colors.grey[300],
//                             child: const Icon(Icons.restaurant, size: 80),
//                           ),
//                 ),
//               ),
//               SliverToBoxAdapter(
//                 child: Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Địa chỉ
//                       Row(
//                         children: [
//                           const Icon(
//                             Icons.location_on,
//                             size: 18,
//                             color: Colors.redAccent,
//                           ),
//                           const SizedBox(width: 6),
//                           Expanded(
//                             child: Text(
//                               r.address,
//                               style: const TextStyle(fontSize: 15),
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 8),

//                       // Favorite button + số lượng
//                       FavoriteRow(restaurant: r, onToggle: _toggleFavorite),

//                       const SizedBox(height: 16),

//                       // Map
//                       RestaurantMapContainer(restaurant: r, height: 200),

//                       const SizedBox(height: 16),

//                       // Giới thiệu
//                       Text(
//                         context.t('introduction'),
//                         style: const TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         r.description ?? context.t('no_description'),
//                         style: const TextStyle(fontSize: 15, height: 1.4),
//                       ),
//                       const SizedBox(height: 16),

//                       // ⭐ Tổng đánh giá trung bình
//                       FutureBuilder<List<Review>>(
//                         future: _reviewsFuture,
//                         builder: (context, snap) {
//                           if (!snap.hasData || snap.data!.isEmpty) {
//                             return Text(context.t('no_reviews'));
//                           }
//                           final reviews = snap.data!;
//                           final avg =
//                               reviews
//                                   .map((e) => e.rating)
//                                   .reduce((a, b) => a + b) /
//                               reviews.length;

//                           return Row(
//                             children: [
//                               ...List.generate(5, (i) {
//                                 if (i < avg.floor()) {
//                                   return const Icon(
//                                     Icons.star,
//                                     color: Colors.orange,
//                                     size: 20,
//                                   );
//                                 } else {
//                                   return const Icon(
//                                     Icons.star_border,
//                                     color: Colors.orange,
//                                     size: 20,
//                                   );
//                                 }
//                               }),
//                               const SizedBox(width: 6),
//                               Text(
//                                 avg.toStringAsFixed(1),
//                                 style: const TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 16,
//                                 ),
//                               ),
//                               Text(
//                                 " /5 (${reviews.length} ${context.t('reviews')})",
//                               ),
//                             ],
//                           );
//                         },
//                       ),
//                       const SizedBox(height: 24),

//                       // Đánh giá
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(
//                             context.t('reviews'),
//                             style: const TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           ElevatedButton(
//                             onPressed: () async {
//                               final added = await Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder:
//                                       (_) => AddReviewPage(restaurantId: r.id),
//                                 ),
//                               );
//                               if (added == true) _refreshReviews();
//                             },
//                             child: Text(context.t('add_review')),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 12),

//                       FutureBuilder<List<Review>>(
//                         future: _reviewsFuture,
//                         builder: (context, snap) {
//                           if (snap.connectionState == ConnectionState.waiting) {
//                             return const Center(
//                               child: CircularProgressIndicator(),
//                             );
//                           } else if (snap.hasError) {
//                             return Text("${context.t('error')}: ${snap.error}");
//                           } else if (!snap.hasData || snap.data!.isEmpty) {
//                             return Container(
//                               width: double.infinity,
//                               padding: const EdgeInsets.all(16),
//                               decoration: BoxDecoration(
//                                 color: Colors.grey[100],
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               child: Text(
//                                 context.t('no_reviews'),
//                                 style: const TextStyle(color: Colors.grey),
//                               ),
//                             );
//                           }

//                           final reviews = snap.data!;

//                           return Column(
//                             children:
//                                 reviews.map((review) {
//                                   return Container(
//                                     width: double.infinity,
//                                     margin: const EdgeInsets.only(bottom: 12),
//                                     padding: const EdgeInsets.all(12),
//                                     decoration: BoxDecoration(
//                                       color: Colors.grey[100],
//                                       borderRadius: BorderRadius.circular(12),
//                                     ),
//                                     child: Column(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         Row(
//                                           children: [
//                                             CircleAvatar(
//                                               radius: 16,
//                                               backgroundColor: Colors.grey[300],
//                                               backgroundImage:
//                                                   review.userAvatar != null &&
//                                                           review
//                                                               .userAvatar!
//                                                               .isNotEmpty
//                                                       ? NetworkImage(
//                                                         review.userAvatar!,
//                                                       )
//                                                       : const AssetImage(
//                                                             "assets/images/avatar.jpg",
//                                                           )
//                                                           as ImageProvider,
//                                             ),
//                                             const SizedBox(width: 8),
//                                             Text(
//                                               review.userName,
//                                               style: const TextStyle(
//                                                 fontWeight: FontWeight.bold,
//                                               ),
//                                             ),
//                                             const Spacer(),
//                                             Row(
//                                               children: [
//                                                 ...List.generate(5, (i) {
//                                                   if (i < review.rating) {
//                                                     return const Icon(
//                                                       Icons.star,
//                                                       color: Colors.orange,
//                                                       size: 16,
//                                                     );
//                                                   } else {
//                                                     return const Icon(
//                                                       Icons.star_border,
//                                                       color: Colors.orange,
//                                                       size: 16,
//                                                     );
//                                                   }
//                                                 }),
//                                                 const SizedBox(width: 4),
//                                                 Text("${review.rating}/5"),
//                                               ],
//                                             ),
//                                           ],
//                                         ),
//                                         const SizedBox(height: 8),
//                                         Text(review.content),
//                                         if (review.images.isNotEmpty) ...[
//                                           const SizedBox(height: 8),
//                                           SizedBox(
//                                             height: 80,
//                                             child: ListView.builder(
//                                               scrollDirection: Axis.horizontal,
//                                               itemCount: review.images.length,
//                                               itemBuilder: (context, index) {
//                                                 final img =
//                                                     review
//                                                         .images[index]
//                                                         .imageUrl;
//                                                 return Container(
//                                                   margin: const EdgeInsets.only(
//                                                     right: 8,
//                                                   ),
//                                                   child: Image.network(
//                                                     img,
//                                                     width: 80,
//                                                     height: 80,
//                                                     fit: BoxFit.cover,
//                                                     errorBuilder:
//                                                         (
//                                                           _,
//                                                           __,
//                                                           ___,
//                                                         ) => Image.asset(
//                                                           "assets/images/food.jpg",
//                                                           width: 80,
//                                                           height: 80,
//                                                           fit: BoxFit.cover,
//                                                         ),
//                                                   ),
//                                                 );
//                                               },
//                                             ),
//                                           ),
//                                         ],
//                                       ],
//                                     ),
//                                   );
//                                 }).toList(),
//                           );
//                         },
//                       ),
//                       const SizedBox(height: 40),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }
// }

// /// Widget FavoriteRow chuyển sang Stateful để cập nhật số lượng ngay lập tức
// class FavoriteRow extends StatefulWidget {
//   final Restaurant restaurant;
//   final Future<bool> Function() onToggle;

//   const FavoriteRow({
//     super.key,
//     required this.restaurant,
//     required this.onToggle,
//   });

//   @override
//   State<FavoriteRow> createState() => _FavoriteRowState();
// }

// class _FavoriteRowState extends State<FavoriteRow> {
//   late bool isFavorite;
//   late int favoritesCount;

//   @override
//   void initState() {
//     super.initState();
//     isFavorite = widget.restaurant.isFavorite;
//     favoritesCount = widget.restaurant.favoritesCount;
//   }

//   void _handleToggle() async {
//     final oldFavorite = isFavorite;
//     final oldCount = favoritesCount;

//     setState(() {
//       isFavorite = !oldFavorite;
//       favoritesCount += isFavorite ? 1 : -1;
//     });

//     final success = await widget.onToggle();
//     if (!success) {
//       // rollback nếu fail
//       setState(() {
//         isFavorite = oldFavorite;
//         favoritesCount = oldCount;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         IconButton(
//           icon: Icon(
//             isFavorite ? Icons.favorite : Icons.favorite_border,
//             color: Colors.redAccent,
//           ),
//           onPressed: _handleToggle,
//         ),
//         const SizedBox(width: 4),
//         Text(
//           '$favoritesCount ${context.t('favorites_fav')}',
//           style: const TextStyle(fontSize: 14, color: Colors.grey),
//         ),
//       ],
//     );
//   }
// }

// /// Widget Mapbox riêng để tránh lỗi khi rebuild
// class RestaurantMapContainer extends StatefulWidget {
//   final Restaurant restaurant;
//   final double height;

//   const RestaurantMapContainer({
//     super.key,
//     required this.restaurant,
//     this.height = 200,
//   });

//   @override
//   State<RestaurantMapContainer> createState() => _RestaurantMapContainerState();
// }

// class _RestaurantMapContainerState extends State<RestaurantMapContainer> {
//   @override
//   Widget build(BuildContext context) {
//     return RestaurantMapWidget(
//       restaurant: widget.restaurant,
//       height: widget.height,
//     );
//   }
// }
