import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/route_service.dart';
import '../state/map_state.dart';

class BikeRouter {
  static Future<List<LatLng>> getRoute({
    required LatLng start,
    required LatLng end,
    required RouteMode routeMode,
    String travelMode = 'bicycling',
  }) async {
    return await RouteService.getRoute(
      start,
      end,
      routeMode: routeMode.name,
      travelMode: travelMode,
    );
  }
}
