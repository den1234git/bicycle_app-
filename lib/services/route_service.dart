import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../api_keys.dart';

class RouteService {
  static Future<List<LatLng>> getRoute(
    LatLng start,
    LatLng end, {
    String routeMode = 'fast',
    String travelMode = 'bicycling',
  }) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json'
      '?origin=${start.latitude},${start.longitude}'
      '&destination=${end.latitude},${end.longitude}'
      '&mode=$travelMode'
      '&key=${ApiKeys.googleApiKey}',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode != 200) {
        return [start, end];
      }

      final data = jsonDecode(response.body);

      if (data['status'] != 'OK') {
        return [start, end];
      }

      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) {
        return [start, end];
      }

      final encodedPolyline =
          routes[0]['overview_polyline']['points'] as String?;
      if (encodedPolyline == null || encodedPolyline.isEmpty) {
        return [start, end];
      }

      return _decodePolyline(encodedPolyline);
    } catch (e) {
      return [start, end];
    }
  }

  static List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> points = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;

      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dLat = (result & 1) != 0 ? ~(result >> 1) : result >> 1;
      lat += dLat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dLng = (result & 1) != 0 ? ~(result >> 1) : result >> 1;
      lng += dLng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }
}
