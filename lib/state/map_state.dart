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

  TransportMode transportMode = TransportMode.bike;

  RouteMode routeMode = RouteMode.fast;

  ViewMode viewMode = ViewMode.bike;

  AppMode appMode = AppMode.idle;

  bool isLoading = false;

  double routeProgress = 0;

  String nextGuideText = '';

  void clearRoute() {
    routePoints.clear();
    goal = null;
    appMode = AppMode.idle;
  }
}
