// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:reviewfood/pages/login_page.dart';
// import 'package:reviewfood/pages/profile/profile_tab.dart';
// import 'package:reviewfood/pages/reviewfeed/reviewfeed_page.dart';
// import 'package:reviewfood/pages/map/map_page.dart';
// import 'package:reviewfood/pages/category/category_page.dart';
// import 'package:reviewfood/pages/restaurant/restaurant_list_page.dart';
// import 'package:reviewfood/services/api_service.dart';
// import '../profile/settings_provider.dart';
// import '../profile/app_localizations.dart';
// import '../../models/category.dart';
// import 'package:reviewfood/pages/category/RestaurantByCategory.dart';

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   final ApiService _apiService = ApiService();
//   int _selectedIndex = 0;
//   final TextEditingController _searchController = TextEditingController();

//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//   }

//   // Tab Home scrollable
//   Widget _buildHomeTab() {
//     final theme = Theme.of(context);

//     return ListView(
//       padding: EdgeInsets.zero,
//       children: [
//         // Search Bar
//         Container(
//           height: 40,
//           margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
//           padding: const EdgeInsets.symmetric(horizontal: 12),
//           decoration: BoxDecoration(
//             color: theme.cardColor,
//             borderRadius: BorderRadius.circular(8),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.05),
//                 blurRadius: 4,
//                 offset: const Offset(0, 2),
//               ),
//             ],
//           ),
//           child: TextField(
//             controller: _searchController,
//             decoration: InputDecoration(
//               hintText: context.t('search_hint'),
//               border: InputBorder.none,
//               icon: Icon(Icons.search, color: theme.iconTheme.color),
//             ),
//           ),
//         ),

//         // Categories tròn ngang
//         SizedBox(
//           height: 120,
//           child: FutureBuilder<List<Category>>(
//             future: _apiService.getCategories(),
//             builder: (context, snapshot) {
//               if (snapshot.connectionState == ConnectionState.waiting) {
//                 return Center(
//                   child: CircularProgressIndicator(
//                     color: Colors.blueAccent, // đổi sang xanh
//                   ),
//                 );
//               } else if (snapshot.hasError) {
//                 return Center(
//                   child: Text("${context.t('error')}: ${snapshot.error}"),
//                 );
//               } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//                 return const SizedBox.shrink();
//               }

//               final categories = snapshot.data!;
//               return ListView.separated(
//                 scrollDirection: Axis.horizontal,
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 itemCount: categories.length,
//                 separatorBuilder: (_, __) => const SizedBox(width: 12),
//                 itemBuilder: (context, index) {
//                   final c = categories[index];
//                   return Column(
//                     children: [
//                       InkWell(
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (_) => RestaurantByCategoryPage(
//                                 categoryId: c.id,
//                                 categoryName: c.name,
//                               ),
//                             ),
//                           );
//                         },
//                         borderRadius: BorderRadius.circular(50),
//                         child: CircleAvatar(
//                           radius: 35,
//                           backgroundColor: theme.cardColor,
//                           backgroundImage: c.image != null && c.image!.isNotEmpty
//                               ? NetworkImage(c.image!)
//                               : null,
//                           child: (c.image == null || c.image!.isEmpty)
//                               ? const Icon(
//                                   Icons.fastfood,
//                                   color: Colors.blueAccent, // đổi sang xanh
//                                   size: 30,
//                                 )
//                               : null,
//                         ),
//                       ),
//                       const SizedBox(height: 6),
//                       SizedBox(
//                         width: 70,
//                         child: Text(
//                           c.name,
//                           textAlign: TextAlign.center,
//                           overflow: TextOverflow.ellipsis,
//                           maxLines: 2,
//                           style: theme.textTheme.bodySmall,
//                         ),
//                       ),
//                     ],
//                   );
//                 },
//               );
//             },
//           ),
//         ),

//         const SizedBox(height: 16),

//         // Danh sách quán ăn
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16),
//           child: RestaurantListPage(
//             api: _apiService,
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//           ),
//         ),

//         const SizedBox(height: 16),
//       ],
//     );
//   }

//   Widget _buildOtherPage(int index) {
//     switch (index) {
//       case 1:
//         return ReviewFeedPage();
//       case 2:
//         return MapPage();
//       case 3:
//         return CategoryPage();
//       case 4:
//         return const ProfileTab();
//       default:
//         return const SizedBox();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     context.watch<SettingsProvider>();

//     return Scaffold(
//       backgroundColor: theme.scaffoldBackgroundColor,
//       body: Column(
//         children: [
//           // Header cố định
//           Container(
//             color: theme.scaffoldBackgroundColor,
//             padding: const EdgeInsets.fromLTRB(16, 40, 16, 8),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   "FoodReview",
//                   style: theme.textTheme.headlineMedium?.copyWith(
//                     color: Colors.blueAccent, // đổi sang xanh
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 Row(
//                   children: [
//                     IconButton(
//                       iconSize: 32,
//                       icon: Icon(
//                         Icons.notifications_outlined,
//                         color: theme.iconTheme.color,
//                       ),
//                       onPressed: () {},
//                     ),
//                     IconButton(
//                       iconSize: 32,
//                       icon: Icon(
//                         Icons.account_circle_outlined,
//                         color: theme.iconTheme.color,
//                       ),
//                       onPressed: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => const LoginPage(),
//                           ),
//                         );
//                       },
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),

//           // Body
//           Expanded(
//             child: _selectedIndex == 0
//                 ? _buildHomeTab()
//                 : _buildOtherPage(_selectedIndex),
//           ),
//         ],
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         backgroundColor: theme.scaffoldBackgroundColor,
//         type: BottomNavigationBarType.fixed,
//         currentIndex: _selectedIndex,
//         onTap: _onItemTapped,
//         selectedItemColor: Colors.blueAccent, // đổi sang xanh
//         unselectedItemColor: theme.iconTheme.color,
//         items: [
//           BottomNavigationBarItem(
//             icon: const Icon(Icons.home),
//             label: context.t('home_title'),
//           ),
//           BottomNavigationBarItem(
//             icon: const Icon(Icons.reviews),
//             label: context.t('review_feed'),
//           ),
//           BottomNavigationBarItem(
//             icon: const Icon(Icons.map),
//             label: context.t('map'),
//           ),
//           BottomNavigationBarItem(
//             icon: const Icon(Icons.grid_view),
//             label: context.t('category'),
//           ),
//           BottomNavigationBarItem(
//             icon: const Icon(Icons.person),
//             label: context.t('profile'),
//           ),
//         ],
//       ),
//     );
//   }
// }
