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

  void clearRoute() {
    routePoints.clear();
    candidateRoutes.clear();
    candidateDistances.clear();
    candidateEtas.clear();
    goal = null;
    appMode = AppMode.idle;
    isRouteOverview = false;
    isFullView = false;
  }
}
