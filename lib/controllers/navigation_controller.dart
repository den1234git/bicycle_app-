import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class NavigationController {
  static const double arrivalThreshold = 18;
  static const double offRouteThreshold = 25;

  static bool isArrived(
    LatLng currentPos,
    LatLng goal,
  ) {
    final distance = NavigationMath.distanceMeters(
      currentPos,
      goal,
    );

    return distance < arrivalThreshold;
  }

  static bool isOffRoute(
    LatLng currentPos,
    List<LatLng> routePoints,
  ) {
    if (routePoints.isEmpty) return false;

    final deviation = NavigationMath.routeDeviationMeters(
      currentPos,
      routePoints,
    );

    return deviation > offRouteThreshold;
  }

  static int nearestRouteIndex(
    LatLng currentPos,
    List<LatLng> routePoints,
  ) {
    if (routePoints.isEmpty) return 0;

    int nearest = 0;
    double best = double.infinity;

    for (int i = 0; i < routePoints.length; i++) {
      final d = NavigationMath.distanceMeters(
        currentPos,
        routePoints[i],
      );

      if (d < best) {
        best = d;
        nearest = i;
      }
    }

    return nearest;
  }

  static double routeHeading(
    List<LatLng> routePoints,
    int index,
  ) {
    if (routePoints.length < 2) return 0;

    final nextIndex = (index + 1).clamp(0, routePoints.length - 1);

    return NavigationMath.bearing(
      routePoints[index],
      routePoints[nextIndex],
    );
  }

  static double smoothBearing(
    double currentBearing,
    double targetBearing,
    double alpha,
  ) {
    double diff = targetBearing - currentBearing;

    while (diff > 180) diff -= 360;
    while (diff < -180) diff += 360;

    return currentBearing + diff * alpha;
  }

  static double progress(
    LatLng currentPos,
    List<LatLng> routePoints,
  ) {
    if (routePoints.isEmpty) return 0;

    final index = nearestRouteIndex(currentPos, routePoints);
    return index / routePoints.length;
  }

  static double remainingDistanceKm(
    LatLng currentPos,
    List<LatLng> routePoints,
  ) {
    if (routePoints.isEmpty) return 0;

    final nearest = nearestRouteIndex(currentPos, routePoints);

    double total = 0;

    for (int i = nearest; i < routePoints.length - 1; i++) {
      final a = routePoints[i];
      final b = routePoints[i + 1];

      total += NavigationMath.distanceMeters(a, b) / 1000;
    }

    return total;
  }

  static bool canStartNavigation(
    List<LatLng> routePoints,
  ) {
    return routePoints.isNotEmpty;
  }

  static String nextDirection(
    LatLng currentPos,
    List<LatLng> routePoints,
  ) {
    if (routePoints.length < 3) {
      return 'ルートなし';
    }

    final index = nearestRouteIndex(currentPos, routePoints);

    if (index >= routePoints.length - 2) {
      return '到着付近';
    }

    final a = routePoints[index];
    final b = routePoints[index + 1];
    final c = routePoints[index + 2];

    final angle = NavigationMath.angleBetween(
      a,
      b,
      c,
    );

    if (angle.abs() < 20) {
      return '直進';
    }

    if (angle > 0) {
      return '右折';
    }

    return '左折';
  }

  static bool isNearTurn(
    LatLng currentPos,
    List<LatLng> routePoints,
  ) {
    if (routePoints.length < 3) return false;

    final index = nearestRouteIndex(currentPos, routePoints);

    if (index >= routePoints.length - 2) return false;

    final current = routePoints[index];
    final next = routePoints[index + 1];

    final distance = NavigationMath.distanceMeters(
      current,
      next,
    );

    return distance < 30;
  }

  static bool shouldFollow(
    bool isFollowing,
    String mode,
  ) {
    if (mode == 'train') return false;
    return isFollowing;
  }
}

class NavigationMath {
  static double distanceMeters(
    LatLng a,
    LatLng b,
  ) {
    return Geolocator.distanceBetween(
      a.latitude,
      a.longitude,
      b.latitude,
      b.longitude,
    );
  }

  static double bearing(
    LatLng a,
    LatLng b,
  ) {
    return Geolocator.bearingBetween(
      a.latitude,
      a.longitude,
      b.latitude,
      b.longitude,
    );
  }

  static double angleBetween(
    LatLng a,
    LatLng b,
    LatLng c,
  ) {
    final bearing1 = bearing(a, b);
    final bearing2 = bearing(b, c);

    double diff = bearing2 - bearing1;

    while (diff > 180) {
      diff -= 360;
    }

    while (diff < -180) {
      diff += 360;
    }

    return diff;
  }

  static double routeDeviationMeters(
    LatLng pos,
    List<LatLng> route,
  ) {
    if (route.isEmpty) return 999999;

    double best = double.infinity;

    for (final point in route) {
      final d = distanceMeters(pos, point);

      if (d < best) {
        best = d;
      }
    }

    return best;
  }
}
