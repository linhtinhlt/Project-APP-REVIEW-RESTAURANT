import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:reviewfood/services/api_service.dart';
import 'package:reviewfood/models/restaurant.dart';
import 'package:reviewfood/pages/map/map_helper.dart';
import 'package:reviewfood/pages/restaurant/restaurant_detail_page.dart';
import 'package:reviewfood/pages/reviewfeed/add_restaurant_review.dart';
import '../profile/app_localizations.dart';
import '../profile/settings_provider.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  mapbox.MapboxMap? mapboxMap;
  mapbox.CircleAnnotationManager? circleManager;
  mapbox.PolylineAnnotationManager? polylineManager;

  double? userLat;
  double? userLng;

  final ApiService api = ApiService();
  List<Restaurant> restaurants = [];
  List<Restaurant> searchResults = [];
  bool loading = true;
  bool searching = false;
  bool isTyping = false;

  final Map<int, mapbox.CircleAnnotation> restaurantCircles = {};
  Restaurant? selectedRestaurant;
  final TextEditingController searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.locationWhenInUse.request();
    if (status == PermissionStatus.granted) {
      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        userLat = pos.latitude;
        userLng = pos.longitude;
      });

      if (mapboxMap != null) {
        _flyToUser();
        await _addUserCircle();
        await _fetchNearbyRestaurants();
      }
    } else {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  void _onMapCreated(mapbox.MapboxMap map) async {
    mapboxMap = map;
    circleManager = await map.annotations.createCircleAnnotationManager();
    polylineManager = await map.annotations.createPolylineAnnotationManager();

    _flyToUser();
    await _addUserCircle();
    await _fetchNearbyRestaurants();
  }

  Future<void> _fetchNearbyRestaurants() async {
    if (userLat == null || userLng == null) return;
    try {
      final nearby = await api.getNearbyRestaurants(
        lat: userLat!,
        lng: userLng!,
        radius: 2,
      );

      for (var r in nearby) {
        if (r.latitude != null && r.longitude != null) {
          r.distance =
              Geolocator.distanceBetween(
                userLat!,
                userLng!,
                r.latitude!,
                r.longitude!,
              ) /
              1000;
        }
      }

      if (!mounted) return;
      setState(() {
        restaurants = nearby;
        loading = false;
      });

      await _renderMarkers(nearby);
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  Future<void> _renderMarkers(List<Restaurant> data) async {
    await circleManager?.deleteAll();
    restaurantCircles.clear();

    if (userLat != null && userLng != null) {
      await MapHelper.addUserMarker(
        manager: circleManager!,
        lat: userLat!,
        lng: userLng!,
      );
    }

    restaurantCircles.addAll(
      await MapHelper.addRestaurantMarkers(
        manager: circleManager!,
        restaurants:
            data
                .map(
                  (r) => {
                    'id': r.id,
                    'latitude': r.latitude,
                    'longitude': r.longitude,
                  },
                )
                .toList(),
      ),
    );
  }

  void _flyToUser() {
    if (userLat != null && userLng != null) {
      mapboxMap?.flyTo(
        mapbox.CameraOptions(
          center: mapbox.Point(
            coordinates: mapbox.Position(userLng!, userLat!),
          ),
          zoom: 15,
        ),
        mapbox.MapAnimationOptions(duration: 1000),
      );
    }
  }

  Future<void> _addUserCircle() async {
    if (circleManager != null && userLat != null && userLng != null) {
      await MapHelper.addUserMarker(
        manager: circleManager!,
        lat: userLat!,
        lng: userLng!,
      );
    }
  }

  Future<void> _flyToRestaurant(Restaurant r) async {
    if (r.latitude == null || r.longitude == null) return;
    mapboxMap?.flyTo(
      mapbox.CameraOptions(
        center: mapbox.Point(
          coordinates: mapbox.Position(r.longitude!, r.latitude!),
        ),
        zoom: 16,
      ),
      mapbox.MapAnimationOptions(duration: 1000),
    );
    selectedRestaurant = r;
  }

  Future<void> _drawRouteToRestaurant(Restaurant r) async {
    if (userLat == null || userLng == null) return;
    if (r.latitude == null || r.longitude == null) return;
    if (polylineManager == null) return;

    await MapHelper.drawRouteFromService(
      manager: polylineManager!,
      originLat: userLat!,
      originLng: userLng!,
      destLat: r.latitude!,
      destLng: r.longitude!,
    );
  }

  Future<void> _searchRestaurants(String query) async {
    if (query.isEmpty) {
      if (!mounted) return;
      setState(() => searchResults = []);
      await _renderMarkers(restaurants);
      return;
    }

    if (!mounted) return;
    setState(() => searching = true);

    try {
      final results = await api.searchRestaurants(query: query);
      for (var r in results) {
        if (userLat != null &&
            userLng != null &&
            r.latitude != null &&
            r.longitude != null) {
          r.distance =
              Geolocator.distanceBetween(
                userLat!,
                userLng!,
                r.latitude!,
                r.longitude!,
              ) /
              1000;
        }
      }

      if (!mounted) return;
      setState(() {
        searchResults = results;
        searching = false;
      });

      await _renderMarkers(results);
    } catch (e) {
      if (!mounted) return;
      setState(() => searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final fontScale = settings.fontSize / 14.0;
    final isDark = settings.isDarkMode;
    final showingList = searchResults.isNotEmpty ? searchResults : restaurants;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          IgnorePointer(
            ignoring: isTyping,
            child: mapbox.MapWidget(
              key: const ValueKey("mapWidget"),
              styleUri: mapbox.MapboxStyles.MAPBOX_STREETS,
              cameraOptions: mapbox.CameraOptions(
                center: mapbox.Point(
                  coordinates: mapbox.Position(
                    userLng ?? 105.84117,
                    userLat ?? 21.0245,
                  ),
                ),
                zoom: 14,
              ),
              onMapCreated: _onMapCreated,
            ),
          ),

          // 🔍 Ô tìm kiếm
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: FocusScope(
              child: Focus(
                onFocusChange: (hasFocus) {
                  setState(() => isTyping = hasFocus);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color:
                            isTyping
                                ? primary.withOpacity(0.3)
                                : theme.shadowColor.withOpacity(0.1),
                        blurRadius: isTyping ? 10 : 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: searchCtrl,
                    style: TextStyle(
                      fontSize: 15 * fontScale,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                    onSubmitted: _searchRestaurants,
                    decoration: InputDecoration(
                      hintText: context.t('search_hint'),
                      hintStyle: TextStyle(
                        color: theme.hintColor,
                        fontSize: 14 * fontScale,
                      ),
                      prefixIcon: Icon(Icons.search_rounded, color: primary),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      suffixIcon:
                          searchCtrl.text.isNotEmpty
                              ? IconButton(
                                icon: Icon(
                                  Icons.clear_rounded,
                                  color: theme.iconTheme.color?.withOpacity(
                                    0.7,
                                  ),
                                ),
                                onPressed: () async {
                                  searchCtrl.clear();
                                  if (!mounted) return;
                                  setState(() => searchResults = []);
                                  await _renderMarkers(restaurants);
                                },
                              )
                              : null,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 🧾 Danh sách quán
          DraggableScrollableSheet(
            initialChildSize: 0.25,
            minChildSize: 0.2,
            maxChildSize: 0.65,
            builder: (_, controller) {
              return Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      height: 5,
                      width: 50,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[700] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Text(
                      searchResults.isNotEmpty
                          ? context.t('search_results')
                          : context.t('nearby_restaurants'),
                      style: TextStyle(
                        fontSize: 16 * fontScale,
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                    Expanded(
                      child:
                          searching
                              ? Center(
                                child: CircularProgressIndicator(
                                  color: primary,
                                ),
                              )
                              : ListView.builder(
                                controller: controller,
                                itemCount: showingList.length + 1,
                                itemBuilder: (context, index) {
                                  if (index < showingList.length) {
                                    final r = showingList[index];
                                    return RestaurantListTile(
                                      restaurant: r,
                                      fontScale: fontScale,
                                      onTap: () => _flyToRestaurant(r),
                                      onDirection:
                                          () => _drawRouteToRestaurant(r),
                                      onDetail: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => RestaurantDetailPage(
                                                  restaurantId: r.id,
                                                ),
                                          ),
                                        );
                                      },
                                    );
                                  } else {
                                    return ListTile(
                                      leading: Icon(
                                        Icons.add_rounded,
                                        color: primary,
                                      ),
                                      title: Text(
                                        context.t('add_new_restaurant'),
                                        style: TextStyle(
                                          color: primary,
                                          fontSize: 15 * fontScale,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) =>
                                                    const AddRestaurantReviewPage(),
                                          ),
                                        );
                                      },
                                    );
                                  }
                                },
                              ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _flyToUser();
          _addUserCircle();
        },
        backgroundColor: primary,
        elevation: 6,
        child: const Icon(Icons.my_location_rounded, color: Colors.white),
      ),
    );
  }
}

// ================= RestaurantListTile ==================
class RestaurantListTile extends StatelessWidget {
  final Restaurant restaurant;
  final double fontScale;
  final VoidCallback onTap;
  final VoidCallback onDirection;
  final VoidCallback onDetail;

  const RestaurantListTile({
    super.key,
    required this.restaurant,
    required this.fontScale,
    required this.onTap,
    required this.onDirection,
    required this.onDetail,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: isDark ? 0 : 2,
      shadowColor: theme.shadowColor,
      color: theme.cardColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              // Ảnh
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child:
                    (restaurant.imageUrl != null &&
                            restaurant.imageUrl!.isNotEmpty)
                        ? Image.network(
                          restaurant.imageUrl!,
                          width: 58,
                          height: 58,
                          fit: BoxFit.cover,
                        )
                        : Container(
                          width: 58,
                          height: 58,
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                          child: Icon(
                            Icons.restaurant_menu_rounded,
                            color: isDark ? Colors.grey[400] : Colors.grey,
                          ),
                        ),
              ),
              const SizedBox(width: 12),

              // Thông tin
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tên
                    Text(
                      restaurant.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15 * fontScale,
                        color: primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Địa chỉ (tách riêng)
                    if ((restaurant.address ?? '').isNotEmpty)
                      Text(
                        restaurant.address!,
                        style: TextStyle(
                          fontSize: 13 * fontScale,
                          color: theme.textTheme.bodyMedium?.color,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                    // Khoảng cách (dòng riêng – luôn thấy)
                    if (restaurant.distance != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        "${context.t('distance')} ${restaurant.distance!.toStringAsFixed(2)} km",
                        style: TextStyle(
                          fontSize: 12.5 * fontScale,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),

              // Hành động
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.directions_rounded,
                      color: primary,
                      size: 22,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onDirection,
                    tooltip: context.t('directions'),
                  ),
                  const SizedBox(height: 4),
                  IconButton(
                    icon: const Icon(
                      Icons.info_outline_rounded,
                      color: Colors.orange,
                      size: 22,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onDetail,
                    tooltip: context.t('details'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
