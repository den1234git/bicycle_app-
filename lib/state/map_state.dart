import 'package:google_maps_flutter/google_maps_flutter.dart';

enum AppMode {
  idle,
  preview,
  navigating,
}

enum TransportMode {
  bike,
  train,
  walk,
}

enum RouteMode {
  fast,
  safe,
  scenic,
}

enum ViewMode {
  walk,
  bike,
  bird,
}

class TransitInfo {
  final String lineName;
  final String vehicleType;
  final String departureStop;
  final String arrivalStop;
  final String departureTime;
  final String arrivalTime;
  final int numStops;

  TransitInfo({
    required this.lineName,
    required this.vehicleType,
    required this.departureStop,
    required this.arrivalStop,
    required this.departureTime,
    required this.arrivalTime,
    required this.numStops,
  });
}

class MapState {
  LatLng? goal;

  List<LatLng> routePoints = [];

  Map<RouteMode, List<LatLng>> candidateRoutes = {};
  Map<RouteMode, double> candidateDistances = {};
  Map<RouteMode, String> candidateEtas = {};

  TransportMode transportMode = TransportMode.bike;

  RouteMode routeMode = RouteMode.fast;

  ViewMode viewMode = ViewMode.bike;

  AppMode appMode = AppMode.idle;

  bool isLoading = false;

  double routeProgress = 0;

  String nextGuideText = '';

  bool isFollowing = true;
  bool isRouteOverview = false;
  bool isFullView = false;

  double speed = 0;
  double heading = 0;
  double smoothedHeading = 0;

  double routeDistanceKm = 0;
  String etaText = "--";

  List<TransitInfo> transitSteps = [];
  String? transitDepartureTime;
  String? transitArrivalTime;
  String? transitDuration;

  void clearRoute() {
    routePoints.clear();
    candidateRoutes.clear();
    candidateDistances.clear();
    candidateEtas.clear();
    transitSteps.clear();
    transitDepartureTime = null;
    transitArrivalTime = null;
    transitDuration = null;
    goal = null;
    appMode = AppMode.idle;
    isRouteOverview = false;
    isFullView = false;
  }
}
