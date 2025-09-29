import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:reviewfood/services/api_service.dart';
import 'package:reviewfood/models/restaurant.dart';
import 'package:reviewfood/pages/map/map_helper.dart';
import 'package:reviewfood/services/directions_service.dart';

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
  bool loading = true;

  final Map<int, mapbox.CircleAnnotation> restaurantCircles = {};
  String? highlightedCircleId;
  Restaurant? selectedRestaurant;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
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
      debugPrint("Location permission denied");
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
        radius: 5,
      );

      if (!mounted) return;
      setState(() {
        restaurants = nearby;
        loading = false;
      });

      // Xóa tất cả circle cũ
      await circleManager?.deleteAll();
      restaurantCircles.clear();
      highlightedCircleId = null;

      // Thêm user marker
      if (userLat != null && userLng != null) {
        await MapHelper.addUserMarker(
          manager: circleManager!,
          lat: userLat!,
          lng: userLng!,
        );
      }

      // Thêm marker cho các quán
      restaurantCircles.addAll(
        await MapHelper.addRestaurantMarkers(
          manager: circleManager!,
          restaurants:
              nearby
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
    } catch (e) {
      debugPrint("Fetch nearby error: $e");
      if (!mounted) return;
      setState(() => loading = false);
    }
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

    if (circleManager == null) return;

    // Reset circle cũ
    if (highlightedCircleId != null) {
      final prevEntry = restaurantCircles.entries.firstWhere(
        (e) => e.value.id == highlightedCircleId,
        orElse: () => MapEntry(-1, null as mapbox.CircleAnnotation),
      );
      if (prevEntry.key != -1) {
        final prev = prevEntry.value!;
        final reset = mapbox.CircleAnnotation(
          id: prev.id,
          geometry: prev.geometry,
          circleColor: 0xFFFF0000,
          circleRadius: 6.0,
          circleOpacity: prev.circleOpacity,
        );
        try {
          await circleManager!.update(reset);
        } catch (e) {
          debugPrint('Error resetting previous circle: $e');
        }
      }
    }

    // Highlight circle được chọn
    final existing = restaurantCircles[r.id];
    if (existing != null) {
      final updated = mapbox.CircleAnnotation(
        id: existing.id,
        geometry: existing.geometry,
        circleColor: 0xFFFFFF00,
        circleRadius: 10.0,
        circleOpacity: existing.circleOpacity,
      );
      try {
        await circleManager!.update(updated);
        highlightedCircleId = existing.id;
      } catch (e) {
        debugPrint('Error highlighting circle: $e');
      }
    }

    // Lưu quán được chọn để dùng nút route
    setState(() {
      selectedRestaurant = r;
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bản đồ quán ăn")),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Stack(
              children: [
                mapbox.MapWidget(
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
                // Nút chỉ đường nếu đã chọn quán
                if (selectedRestaurant != null)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: FloatingActionButton(
                      onPressed: () async {
                        await _drawRouteToRestaurant(selectedRestaurant!);
                      },
                      backgroundColor: Colors.green,
                      child: const Icon(Icons.directions),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child:
                loading
                    ? const Center(child: CircularProgressIndicator())
                    : restaurants.isEmpty
                    ? const Center(child: Text("Không có quán nào gần bạn 😅"))
                    : ListView.builder(
                      itemCount: restaurants.length,
                      itemBuilder: (context, index) {
                        final r = restaurants[index];
                        return ListTile(
                          leading: const Icon(Icons.restaurant),
                          title: Text(r.name),
                          subtitle: Text(
                            r.distance != null
                                ? "${r.address}\nCách ${r.distance!.toStringAsFixed(2)} km"
                                : r.address,
                          ),
                          onTap: () async {
                            // Chỉ fly tới quán + highlight marker
                            await _flyToRestaurant(r);
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _flyToUser();
          _addUserCircle();
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }
}
