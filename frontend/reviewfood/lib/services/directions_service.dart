
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

const String MAPBOX_ACCESS_TOKEN =
    "pk.eyJ1IjoidGh1eW5ndXllbjI1IiwiYSI6ImNtZnJ6em0wOTAwb2oya29oOGN0N2d1dTEifQ.pe-1KjHMJ0rBP1y4VDzS0A";

class RouteInfo {
  /// coords: list các điểm dưới dạng [lat, lng]
  final List<List<double>> coords;
  final double distance; // meters
  final double duration; // seconds

  RouteInfo({
    required this.coords,
    required this.distance,
    required this.duration,
  });

  /// Convenience: trả về coords dưới dạng [lng, lat] (thường Mapbox SDK cần [lng, lat])
  List<List<double>> coordsLngLat() => coords.map((c) => [c[1], c[0]]).toList();
}

class DirectionsService {
  final String token;

  DirectionsService({String? token}) : token = token ?? MAPBOX_ACCESS_TOKEN {
    if (this.token.trim().isEmpty) {
      throw Exception(
          'MAPBOX_ACCESS_TOKEN is empty. Provide a valid Mapbox token.');
    }
  }

  /// Gọi Mapbox Directions API
  /// LƯU Ý: gọi bằng các named parameters đúng: originLat, originLng, destLat, destLng
  Future<RouteInfo> getRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    String profile = 'driving',
  }) async {
    final uri = Uri.https(
      'api.mapbox.com',
      '/directions/v5/mapbox/$profile/$originLng,$originLat;$destLng,$destLat',
      {
        'geometries': 'polyline6',
        'overview': 'full',
        'alternatives': 'false',
        'access_token': token,
      },
    );

    final resp = await http.get(uri);
    if (resp.statusCode != 200) {
      throw Exception('Directions API failed: ${resp.statusCode} ${resp.body}');
    }

    final Map<String, dynamic> data = json.decode(resp.body);
    final routes = data['routes'] as List<dynamic>?;
    if (routes == null || routes.isEmpty) {
      throw Exception('No routes returned from directions API');
    }

    final first = routes[0] as Map<String, dynamic>;
    final geometry = first['geometry'] as String?;
    final distance = (first['distance'] as num?)?.toDouble() ?? 0.0;
    final duration = (first['duration'] as num?)?.toDouble() ?? 0.0;

    if (geometry == null || geometry.isEmpty) {
      throw Exception('No geometry in route');
    }

    final coords = _decodePolyline6(geometry); // [[lat, lng], ...]
    return RouteInfo(coords: coords, distance: distance, duration: duration);
  }

  /// Decode polyline6 (precision = 1e6). Trả list [lat, lng].
  List<List<double>> _decodePolyline6(String encoded) {
    final List<List<double>> coords = [];
    int index = 0;
    int lat = 0;
    int lng = 0;
    final int len = encoded.length;

    while (index < len) {
      int shift = 0;
      int result = 0;
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      final double finalLat = lat / 1e6;
      final double finalLng = lng / 1e6;
      coords.add([finalLat, finalLng]);
    }

    return coords;
  }
}
