import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../api_keys.dart';

class TransitStep {
  final String lineName;
  final String vehicleType;
  final String departureStop;
  final String arrivalStop;
  final String departureTime;
  final String arrivalTime;
  final int numStops;

  TransitStep({
    required this.lineName,
    required this.vehicleType,
    required this.departureStop,
    required this.arrivalStop,
    required this.departureTime,
    required this.arrivalTime,
    required this.numStops,
  });
}

class RouteDetail {
  final List<LatLng> points;
  final List<TransitStep> transitSteps;
  final String? totalDuration;
  final String? departureTime;
  final String? arrivalTime;

  RouteDetail({
    required this.points,
    this.transitSteps = const [],
    this.totalDuration,
    this.departureTime,
    this.arrivalTime,
  });
}

class RouteService {
  static Future<List<LatLng>> getRoute(
    LatLng start,
    LatLng end, {
    String routeMode = 'fast',
    String travelMode = 'bicycling',
  }) async {
    final detail = await getRouteDetail(start, end,
        routeMode: routeMode, travelMode: travelMode);
    return detail.points;
  }

  static Future<RouteDetail> getRouteDetail(
    LatLng start,
    LatLng end, {
    String routeMode = 'fast',
    String travelMode = 'bicycling',
  }) async {
    final fallback = RouteDetail(points: [start, end]);

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json'
      '?origin=${start.latitude},${start.longitude}'
      '&destination=${end.latitude},${end.longitude}'
      '&mode=$travelMode'
      '&language=ja'
      '&key=${ApiKeys.googleApiKey}',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode != 200) return fallback;

      final data = jsonDecode(response.body);
      if (data['status'] != 'OK') return fallback;

      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) return fallback;

      final route = routes[0];
      final encodedPolyline =
          route['overview_polyline']['points'] as String?;
      if (encodedPolyline == null || encodedPolyline.isEmpty) return fallback;

      final points = _decodePolyline(encodedPolyline);

      final legs = route['legs'] as List?;
      if (legs == null || legs.isEmpty) {
        return RouteDetail(points: points);
      }

      final leg = legs[0];
      final totalDuration = leg['duration']?['text'] as String?;
      final depTime = leg['departure_time']?['text'] as String?;
      final arrTime = leg['arrival_time']?['text'] as String?;

      final transitSteps = <TransitStep>[];
      final steps = leg['steps'] as List? ?? [];
      for (final step in steps) {
        final transit = step['transit_details'];
        if (transit == null) continue;

        final line = transit['line'] ?? {};
        transitSteps.add(TransitStep(
          lineName: (line['short_name'] ?? line['name'] ?? '') as String,
          vehicleType: (line['vehicle']?['type'] ?? '') as String,
          departureStop: (transit['departure_stop']?['name'] ?? '') as String,
          arrivalStop: (transit['arrival_stop']?['name'] ?? '') as String,
          departureTime: (transit['departure_time']?['text'] ?? '') as String,
          arrivalTime: (transit['arrival_time']?['text'] ?? '') as String,
          numStops: (transit['num_stops'] as num?)?.toInt() ?? 0,
        ));
      }

      return RouteDetail(
        points: points,
        transitSteps: transitSteps,
        totalDuration: totalDuration,
        departureTime: depTime,
        arrivalTime: arrTime,
      );
    } catch (e) {
      return fallback;
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
