import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:reviewfood/services/directions_service.dart';

class MapHelper {
  /// Vẽ user marker (màu xanh) trên map
  static Future<void> addUserMarker({
    required mapbox.CircleAnnotationManager manager,
    required double lat,
    required double lng,
    double radius = 8.0,
    int color = 0xFF0000FF,
  }) async {
    final circle = mapbox.CircleAnnotationOptions(
      geometry: mapbox.Point(
        coordinates: mapbox.Position(lng, lat),
      ),
      circleColor: color,
      circleRadius: radius,
      circleOpacity: 0.8,
    );

    await manager.create(circle);
  }

  /// Vẽ danh sách quán (CircleAnnotation) và trả về map id → CircleAnnotation
  static Future<Map<int, mapbox.CircleAnnotation>> addRestaurantMarkers({
    required mapbox.CircleAnnotationManager manager,
    required List<Map<String, dynamic>> restaurants,
    int defaultColor = 0xFFFF0000,
    double radius = 6.0,
  }) async {
    final Map<int, mapbox.CircleAnnotation> mapResult = {};

    for (final r in restaurants) {
      final lat = r['latitude'] as double?;
      final lng = r['longitude'] as double?;
      final id = r['id'] as int?;
      if (lat != null && lng != null && id != null) {
        final options = mapbox.CircleAnnotationOptions(
          geometry: mapbox.Point(
            coordinates: mapbox.Position(lng, lat),
          ),
          circleColor: defaultColor,
          circleRadius: radius,
          circleOpacity: 0.9,
        );

        final created = await manager.create(options);
        mapResult[id] = created;
      }
    }

    return mapResult;
  }

  /// Vẽ route line từ coords (List<[lat,lng]>) trên map
  static Future<void> drawRoute({
    required mapbox.PolylineAnnotationManager manager,
    required List<List<double>> coords, // [[lat,lng], ...]
    int color = 0xFF007AFF,
    double width = 5.0,
    double opacity = 0.8,
  }) async {
    if (coords.isEmpty) return;

    final line = mapbox.PolylineAnnotationOptions(
      geometry: mapbox.LineString(
        coordinates: coords.map((c) => mapbox.Position(c[1], c[0])).toList(),
      ),
      lineColor: color,
      lineWidth: width,
      lineOpacity: opacity,
    );

    await manager.deleteAll(); // Xóa line cũ
    await manager.create(line);
  }

  /// Lấy route từ DirectionsService và vẽ luôn
  static Future<void> drawRouteFromService({
    required mapbox.PolylineAnnotationManager manager,
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    final routeInfo = await DirectionsService().getRoute(
      originLat: originLat,
      originLng: originLng,
      destLat: destLat,
      destLng: destLng,
    );

    await drawRoute(
      manager: manager,
      coords: routeInfo.coords,
    );
  }
}
