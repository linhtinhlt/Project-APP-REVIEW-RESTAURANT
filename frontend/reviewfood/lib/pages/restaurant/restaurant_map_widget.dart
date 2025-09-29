import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:reviewfood/models/restaurant.dart';
import 'package:reviewfood/pages/map/map_helper.dart';

class RestaurantMapWidget extends StatefulWidget {
  final Restaurant restaurant;
  final double height;

  const RestaurantMapWidget({
    super.key,
    required this.restaurant,
    this.height = 200,
  });

  @override
  State<RestaurantMapWidget> createState() => _RestaurantMapWidgetState();
}

class _RestaurantMapWidgetState extends State<RestaurantMapWidget> {
  mapbox.MapboxMap? mapboxMap;
  mapbox.CircleAnnotationManager? circleManager;
  mapbox.PolylineAnnotationManager? polylineManager;

  double? userLat;
  double? userLng;

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
      if (mapboxMap != null) _addMarkersAndRoute();
    } else {
      debugPrint("Location permission denied");
    }
  }

  void _onMapCreated(mapbox.MapboxMap map) async {
    mapboxMap = map;
    circleManager = await map.annotations.createCircleAnnotationManager();
    polylineManager = await map.annotations.createPolylineAnnotationManager();
    _addMarkersAndRoute();
  }

  Future<void> _addMarkersAndRoute() async {
    if (circleManager == null || polylineManager == null) return;

    // Xóa marker và route cũ
    await circleManager!.deleteAll();
    await polylineManager!.deleteAll();

    // Marker user
    if (userLat != null && userLng != null) {
      await MapHelper.addUserMarker(
        manager: circleManager!,
        lat: userLat!,
        lng: userLng!,
      );
    }

    // Marker quán
    if (widget.restaurant.latitude != null &&
        widget.restaurant.longitude != null) {
      await MapHelper.addRestaurantMarkers(
        manager: circleManager!,
        restaurants: [
          {
            'id': widget.restaurant.id,
            'latitude': widget.restaurant.latitude,
            'longitude': widget.restaurant.longitude,
          },
        ],
      );
    }

    // Vẽ route nếu có đủ tọa độ
    if (userLat != null &&
        userLng != null &&
        widget.restaurant.latitude != null &&
        widget.restaurant.longitude != null) {
      await MapHelper.drawRouteFromService(
        manager: polylineManager!,
        originLat: userLat!,
        originLng: userLng!,
        destLat: widget.restaurant.latitude!,
        destLng: widget.restaurant.longitude!,
      );
    }

    // Tự động zoom và center map vừa bao gồm user và quán
    if (userLat != null &&
        userLng != null &&
        widget.restaurant.latitude != null &&
        widget.restaurant.longitude != null) {
      final latMin = [
        userLat!,
        widget.restaurant.latitude!,
      ].reduce((a, b) => a < b ? a : b);
      final latMax = [
        userLat!,
        widget.restaurant.latitude!,
      ].reduce((a, b) => a > b ? a : b);
      final lngMin = [
        userLng!,
        widget.restaurant.longitude!,
      ].reduce((a, b) => a < b ? a : b);
      final lngMax = [
        userLng!,
        widget.restaurant.longitude!,
      ].reduce((a, b) => a > b ? a : b);

      final centerLat = (latMin + latMax) / 2;
      final centerLng = (lngMin + lngMax) / 2;

      final latDiff = latMax - latMin;
      final lngDiff = lngMax - lngMin;
      final zoom = 14 - (latDiff + lngDiff) * 5; // điều chỉnh zoom tạm

      mapboxMap?.flyTo(
        mapbox.CameraOptions(
          center: mapbox.Point(
            coordinates: mapbox.Position(centerLng, centerLat),
          ),
          zoom: zoom.clamp(5.0, 16.0),
        ),
        mapbox.MapAnimationOptions(duration: 800),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: widget.height,
      child: mapbox.MapWidget(
        key: const ValueKey("restaurantDetailMap"),
        styleUri: mapbox.MapboxStyles.MAPBOX_STREETS,
        cameraOptions: mapbox.CameraOptions(
          center: mapbox.Point(
            coordinates: mapbox.Position(
              widget.restaurant.longitude ?? 105.84117,
              widget.restaurant.latitude ?? 21.0245,
            ),
          ),
          zoom: 14,
        ),
        onMapCreated: _onMapCreated,
        // 👇 Thêm để map nhận gesture pan/zoom thay vì bị scroll view ăn mất
        gestureRecognizers: {
          Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
        },
      ),
    );
  }
}
