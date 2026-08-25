import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteModel {
  final List<LatLng> points;
  final String mode; // fast / safe / scenic
  final DateTime createdAt;

  RouteModel({
    required this.points,
    required this.mode,
    required this.createdAt,
  });
}
