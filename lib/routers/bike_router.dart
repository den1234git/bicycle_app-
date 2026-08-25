import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/route_service.dart';
import '../state/map_state.dart';

class BikeRouter {
  static Future<List<LatLng>> getRoute({
    required LatLng start,
    required LatLng end,
    required RouteMode routeMode,
  }) async {
    switch (routeMode) {
      case RouteMode.fast:
        return await RouteService.getRoute(
          start,
          end,
          routeMode: 'fast',
        );

      case RouteMode.safe:
        return await RouteService.getRoute(
          start,
          end,
          routeMode: 'safe',
        );

      case RouteMode.scenic:
        return await RouteService.getRoute(
          start,
          end,
          routeMode: 'scenic',
        );
    }
  }
}
