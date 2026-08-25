import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart';

class GpsUpdateController {
  // ✅ applyHeading を削除（smoothHeading と完全に重複していたデッドコード）
  static double smoothHeading({
    required double currentHeading,
    required double newHeading,
  }) {
    if (currentHeading == 0) return newHeading;
    return currentHeading + (newHeading - currentHeading) * 0.55;
  }

  static bool shouldArrive({
    required LatLng currentPos,
    required LatLng goal,
    required double threshold,
  }) {
    final latDiff = (currentPos.latitude - goal.latitude).abs();
    final lngDiff = (currentPos.longitude - goal.longitude).abs();
    return latDiff < threshold && lngDiff < threshold;
  }

  static double routeProgress({
    required LatLng currentPos,
    required List<LatLng> routePoints,
  }) {
    if (routePoints.isEmpty) return 0;

    double closest = double.infinity;
    int closestIndex = 0;

    for (int i = 0; i < routePoints.length; i++) {
      final latDiff = (currentPos.latitude - routePoints[i].latitude).abs();
      final lngDiff = (currentPos.longitude - routePoints[i].longitude).abs();
      final score = latDiff + lngDiff;

      if (score < closest) {
        closest = score;
        closestIndex = i;
      }
    }

    return closestIndex / routePoints.length;
  }

  // ✅ 修正: 通過済みポイントを除外するため、routeProgress を使って
  //    現在地に最も近いインデックス以降のポイントだけを対象にする。
  static bool shouldShowTurnGuide({
    required LatLng currentPos,
    required List<LatLng> routePoints,
  }) {
    if (routePoints.isEmpty) return false;

    // 現在地に最も近いインデックスを探す
    final startIndex = _closestIndex(currentPos, routePoints);

    // 直近 10 ポイントだけを対象にチェック
    final end = (startIndex + 10).clamp(0, routePoints.length);

    for (int i = startIndex; i < end; i++) {
      final latDiff = (currentPos.latitude - routePoints[i].latitude).abs();
      final lngDiff = (currentPos.longitude - routePoints[i].longitude).abs();
      if (latDiff < 0.00015 && lngDiff < 0.00015) return true;
    }

    return false;
  }

  static void updateBasicState({
    required LatLng pos,
    required double spd,
    required double hdg,
    required Function(LatLng) setPos,
    required Function(double) setSpeed,
    required Function(double) setHeading,
  }) {
    setPos(pos);
    setSpeed(spd);
    setHeading(hdg);
  }

  // ✅ 修正: moveCamera（瞬間移動）→ animateCamera に変更。
  //    また onProgrammaticMove を受け取り、カメラ移動前に必ず呼ぶ。
  static void handleInitialCamera({
    required bool hasMoved,
    required GoogleMapController? controller,
    required LatLng currentPos,
    required Function(bool) setHasMoved,
    required VoidCallback onProgrammaticMove, // ✅ 追加
  }) {
    if (!hasMoved && controller != null) {
      setHasMoved(true);
      onProgrammaticMove(); // ✅ 追加: programmatic=false の誤検知を防ぐ
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(currentPos, 16),
      );
    }
  }

  static bool shouldUpdateUi({
    required DateTime lastUiUpdate,
  }) {
    return DateTime.now().difference(lastUiUpdate).inMilliseconds > 33;
  }

  // ✅ 修正: 「全ポイントから離れている」→「直近ポイントから離れている」に変更。
  //    通過済みポイントを無視することで、正常走行中の誤リルートを防ぐ。
  static bool shouldReroute({
    required LatLng currentPos,
    required List<LatLng> routePoints,
    required DateTime lastRouteTime,
  }) {
    if (routePoints.isEmpty) return false;

    // 現在地に最も近いインデックスを基点に、前後 5 ポイントだけ確認
    final nearest = _closestIndex(currentPos, routePoints);
    final start = (nearest - 2).clamp(0, routePoints.length - 1);
    final end = (nearest + 5).clamp(0, routePoints.length);

    final offRoute = routePoints.sublist(start, end).every((point) {
      final latDiff = (currentPos.latitude - point.latitude).abs();
      final lngDiff = (currentPos.longitude - point.longitude).abs();
      return latDiff > 0.00009 || lngDiff > 0.00009;
    });

    if (!offRoute) return false;

    return DateTime.now().difference(lastRouteTime).inSeconds >= 3;
  }

  // ✅ 追加: 共通ヘルパー。最近傍インデックスを返す。
  static int _closestIndex(LatLng currentPos, List<LatLng> points) {
    double closest = double.infinity;
    int index = 0;

    for (int i = 0; i < points.length; i++) {
      final score = (currentPos.latitude - points[i].latitude).abs() +
          (currentPos.longitude - points[i].longitude).abs();
      if (score < closest) {
        closest = score;
        index = i;
      }
    }

    return index;
  }
}
