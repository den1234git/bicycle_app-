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
  static String _travelMode(TransportMode t) {
    switch (t) {
      case TransportMode.bike: return 'bicycling';
      case TransportMode.walk: return 'walking';
      case TransportMode.train: return 'transit';
    }
  }

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
    final travel = _travelMode(transportMode);
    final profile = transportMode == TransportMode.walk ? 'foot' : 'bike';

    try {
      final googleRoute = await BikeRouter.getRoute(
        start: start,
        end: end,
        routeMode: routeMode,
        travelMode: travel,
      );
      if (googleRoute.length > 2) {
        return RouteResult(points: googleRoute, source: 'google');
      }
    } catch (_) {}

    // フォールバック: OSRM (電車モードではスキップ)
    if (transportMode != TransportMode.train) {
      final osrmRoute = await OsrmRouter.getRoute(
        start: start,
        end: end,
        profile: profile,
      );
      if (osrmRoute != null && osrmRoute.length > 2) {
        return RouteResult(points: osrmRoute, source: 'osrm');
      }
    }

    // 両方失敗なら直線
    return RouteResult(points: [start, end], source: 'direct');
  }
}
