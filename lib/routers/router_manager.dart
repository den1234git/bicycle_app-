import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../state/map_state.dart';
import 'bike_router.dart';

class RouterManager {
  static Future<List<LatLng>> getRoute({
    required LatLng start,
    required LatLng end,
    required TransportMode transportMode,
    required RouteMode routeMode,
  }) async {
    switch (transportMode) {
      case TransportMode.bike:
        return await BikeRouter.getRoute(
          start: start,
          end: end,
          routeMode: routeMode,
        );

      case TransportMode.train:
        // TODO: TrainRouter作ったらここ差し替え
        return await BikeRouter.getRoute(
          start: start,
          end: end,
          routeMode: routeMode,
        );

      case TransportMode.walk:
        // TODO: WalkRouter作ったらここ差し替え
        return await BikeRouter.getRoute(
          start: start,
          end: end,
          routeMode: routeMode,
        );
    }
  }
}
