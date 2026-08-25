import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../controllers/route_controller.dart';

class MapActionController {
  static Future<LatLng?> searchPlace(String text) async {
    return RouteController.searchPlaceFromText(text);
  }

  static Future<List<LatLng>> buildRoute({
    required LatLng currentPos,
    required LatLng goal,
    required String routeMode,
  }) async {
    return RouteController.previewRoute(
      currentPos,
      goal,
      routeMode,
    );
  }
}
