import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class OsrmRouter {
  static Future<List<LatLng>?> getRoute({
    required LatLng start,
    required LatLng end,
    String profile = 'bike',
  }) async {
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/$profile/'
      '${start.longitude},${start.latitude};'
      '${end.longitude},${end.latitude}'
      '?overview=full&geometries=geojson',
    );

    try {
      final res = await http.get(url);
      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body);
      if (data['code'] != 'Ok') return null;

      final coords = data['routes'][0]['geometry']['coordinates'] as List;
      return coords
          .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
          .toList();
    } catch (_) {
      return null;
    }
  }

  static double? extractDistance(String responseBody) {
    try {
      final data = jsonDecode(responseBody);
      return (data['routes'][0]['distance'] as num).toDouble();
    } catch (_) {
      return null;
    }
  }
}
