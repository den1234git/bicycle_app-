import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/place_service.dart';
import '../routers/router_manager.dart';
import '../state/map_state.dart';

import 'dart:math';

class RouteController {
  static Future<LatLng?> searchPlace(
    TextEditingController controller,
  ) async {
    return await searchPlaceFromText(controller.text);
  }

  static Future<LatLng?> searchPlaceFromText(
    String text,
  ) async {
    if (text.isEmpty) return null;
    return await PlaceService.searchPlace(text);
  }

  // ✅ 修正: transportMode を引数で受け取るように変更。
  //    ハードコードの TransportMode.bike を廃止。
  static Future<List<LatLng>> previewRoute(
    LatLng start,
    LatLng end,
    String routeMode, {
    TransportMode transportMode = TransportMode.bike, // ✅ 追加
  }) async {
    final mode = RouteMode.values.firstWhere(
      (e) => e.name == routeMode,
      orElse: () => RouteMode.fast,
    );

    return await RouterManager.getRoute(
      start: start,
      end: end,
      transportMode: transportMode, // ✅ 修正
      routeMode: mode,
    );
  }

  static LatLngBounds createBounds(
    LatLng a,
    LatLng b,
  ) {
    return LatLngBounds(
      southwest: LatLng(
        a.latitude < b.latitude ? a.latitude : b.latitude,
        a.longitude < b.longitude ? a.longitude : b.longitude,
      ),
      northeast: LatLng(
        a.latitude > b.latitude ? a.latitude : b.latitude,
        a.longitude > b.longitude ? a.longitude : b.longitude,
      ),
    );
  }

  static double calcDistanceKm(List<LatLng> points) {
    double total = 0;
    for (int i = 0; i < points.length - 1; i++) {
      total += _distance(points[i], points[i + 1]);
    }
    return total;
  }

  static double _distance(LatLng a, LatLng b) {
    const R = 6371;
    final dLat = _deg(b.latitude - a.latitude);
    final dLng = _deg(b.longitude - a.longitude);
    final x = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg(a.latitude)) *
            cos(_deg(b.latitude)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(x), sqrt(1 - x));
    return R * c;
  }

  static double _deg(double v) => v * pi / 180;

  static String calcEta(double km, double speed) {
    if (speed < 1) return "--";
    final hours = km / speed;
    final minutes = (hours * 60).round();
    return "${minutes}分";
  }

  // ✅ 修正: shouldReroute を削除。
  //    リルート判定は GpsUpdateController.shouldReroute に一本化。
  //    （旧実装は routePoints.every(...) で全ポイントを検索する
  //      壊れたロジックのまま残っていたため）
}
