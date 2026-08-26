import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart';

class GpsUpdateController {
  static double _prevSpeed = 0;

  static bool detectSuddenBrake({
    required double currentSpeed,
    double threshold = 8.0,
  }) {
    final prev = _prevSpeed;
    _prevSpeed = currentSpeed;
    final drop = prev - currentSpeed;
    return prev > 10 && drop >= threshold;
  }

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
  //    点→セグメント距離を使い、長い直線区間での誤リルートを防ぐ。
  static bool shouldReroute({
    required LatLng currentPos,
    required List<LatLng> routePoints,
    required DateTime lastRouteTime,
  }) {
    if (routePoints.isEmpty) return false;

    final nearest = _closestIndex(currentPos, routePoints);
    final start = (nearest - 2).clamp(0, routePoints.length - 1);
    final end = (nearest + 5).clamp(0, routePoints.length);

    double minDist = double.infinity;
    for (int i = start; i < end - 1; i++) {
      final d = _pointToSegmentDistance(
        currentPos, routePoints[i], routePoints[i + 1],
      );
      if (d < minDist) minDist = d;
    }
    if (end - 1 > start) {
      // already handled via segments
    } else {
      final p = routePoints[start];
      minDist = (currentPos.latitude - p.latitude).abs() +
          (currentPos.longitude - p.longitude).abs();
    }

    if (minDist <= 0.00012) return false;

    return DateTime.now().difference(lastRouteTime).inSeconds >= 3;
  }

  static double _pointToSegmentDistance(LatLng p, LatLng a, LatLng b) {
    final dx = b.latitude - a.latitude;
    final dy = b.longitude - a.longitude;
    final lenSq = dx * dx + dy * dy;
    if (lenSq == 0) {
      return (p.latitude - a.latitude).abs() +
          (p.longitude - a.longitude).abs();
    }
    var t = ((p.latitude - a.latitude) * dx + (p.longitude - a.longitude) * dy) / lenSq;
    t = t.clamp(0.0, 1.0);
    final projLat = a.latitude + t * dx;
    final projLng = a.longitude + t * dy;
    final dLat = p.latitude - projLat;
    final dLng = p.longitude - projLng;
    return (dLat.abs() + dLng.abs());
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
