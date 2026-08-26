import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../state/map_state.dart';
import 'bike_router.dart';
import 'osrm_router.dart';

class RouteResult {
  final List<LatLng> points;
  final String source;

  RouteResult({required this.points, required this.source});
}

class RouterManager {
  static Future<List<LatLng>> getRoute({
    required LatLng start,
    required LatLng end,
    required TransportMode transportMode,
    required RouteMode routeMode,
  }) async {
    final result = await getRouteWithSource(
      start: start,
      end: end,
      transportMode: transportMode,
      routeMode: routeMode,
    );
    return result.points;
  }

  static Future<RouteResult> getRouteWithSource({
    required LatLng start,
    required LatLng end,
    required TransportMode transportMode,
    required RouteMode routeMode,
  }) async {
    final profile = transportMode == TransportMode.walk ? 'foot' : 'bike';

    // Google Directions API をメインルーターとして試行
    try {
      final googleRoute = await BikeRouter.getRoute(
        start: start,
        end: end,
        routeMode: routeMode,
      );
      if (googleRoute.length > 2) {
        return RouteResult(points: googleRoute, source: 'google');
      }
    } catch (_) {}

    // フォールバック: OSRM (無料)
    final osrmRoute = await OsrmRouter.getRoute(
      start: start,
      end: end,
      profile: profile,
    );
    if (osrmRoute != null && osrmRoute.length > 2) {
      return RouteResult(points: osrmRoute, source: 'osrm');
    }

    // 両方失敗なら直線
    return RouteResult(points: [start, end], source: 'direct');
  }
}
