import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../state/map_state.dart';

enum CameraMode {
  follow,
  overview,
  free,
}

enum CameraPreset {
  walk,
  bike,
  bird,
}

class CameraService {
  // ✅ 修正: _isAnimating は animateCamera の Future 完了で false に戻す。
  //    それまでは重複呼び出しをガードするために使う。
  static bool _isAnimating = false;
  static DateTime _lastMove = DateTime.fromMillisecondsSinceEpoch(0);

  static CameraPreset presetFromViewMode(ViewMode viewMode) {
    switch (viewMode) {
      case ViewMode.walk:
        return CameraPreset.walk;
      case ViewMode.bike:
        return CameraPreset.bike;
      case ViewMode.bird:
        return CameraPreset.bird;
    }
  }

  static double _smoothedHeading = 0;

  // ===== CAMERA UPDATE =====
  static void updateCamera({
    required bool isFollowing,
    required bool isRouteOverview,
    required GoogleMapController? mapController,
    required LatLng currentPos,
    required LatLng? goal,
    required double heading,
    required double speed,
    required CameraPreset preset,
    required VoidCallback onProgrammaticMove,
  }) {
    if (mapController == null) return;

    if (isRouteOverview && goal != null) {
      overviewCamera(
        mapController: mapController,
        currentPos: currentPos,
        goal: goal,
      );
      return;
    }

    if (!isFollowing) return;

    followCamera(
      mapController: mapController,
      currentPos: currentPos,
      heading: heading,
      speed: speed,
      preset: preset,
      onProgrammaticMove: onProgrammaticMove,
    );
  }

  // ===== FOLLOW（GPS追従）=====
  static void followCamera({
    required GoogleMapController? mapController,
    required LatLng currentPos,
    required double heading,
    required double speed,
    required CameraPreset preset,
    required VoidCallback onProgrammaticMove,
  }) {
    if (mapController == null) return;

    final now = DateTime.now();

    // クールダウン（500ms）
    if (now.difference(_lastMove).inMilliseconds < 500) return;

    // ✅ 修正: アニメーション中は重複実行しない
    if (_isAnimating) return;

    _lastMove = now;
    _isAnimating = true;

    final alpha = speed < 2 ? 0.1 : 0.3;

    if (heading != 0) {
      _smoothedHeading = _smoothedHeading == 0
          ? heading
          : _smoothedHeading + (heading - _smoothedHeading) * alpha;
    }

    double zoom = 19;
    double tilt = 55;
    double lookAhead = 0.0004;

    if (preset == CameraPreset.walk) {
      zoom = 18.8;
      tilt = 0;
      lookAhead = 0.00005;
    } else if (preset == CameraPreset.bird) {
      zoom = 18.5;
      tilt = 65;
      lookAhead = 0.00035;
    }

    final radians = _smoothedHeading * pi / 180;

    final target = LatLng(
      currentPos.latitude + lookAhead * cos(radians),
      currentPos.longitude + lookAhead * sin(radians),
    );

    // ✅ 修正: onProgrammaticMove を animateCamera の直前に呼ぶ。
    //    これにより SET PROGRAMMATIC TRUE → moveStarted の順序が保証される。
    onProgrammaticMove();

    // ✅ 修正: Future を受け取り、完了後に _isAnimating を false に戻す。
    //    これで「_isAnimating が永遠に true のまま」問題を解消。
    mapController
        .animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: target,
          zoom: zoom,
          tilt: tilt,
          bearing: _smoothedHeading,
        ),
      ),
    )
        .then((_) {
      _isAnimating = false;
    }).catchError((_) {
      // コントローラ破棄などで Future がエラーになっても安全に戻す
      _isAnimating = false;
    });
  }

  // ===== OVERVIEW（全体表示）=====
  static void overviewCamera({
    required GoogleMapController? mapController,
    required LatLng currentPos,
    required LatLng goal,
  }) {
    if (mapController == null) return;

    final bounds = LatLngBounds(
      southwest: LatLng(
        min(currentPos.latitude, goal.latitude),
        min(currentPos.longitude, goal.longitude),
      ),
      northeast: LatLng(
        max(currentPos.latitude, goal.latitude),
        max(currentPos.longitude, goal.longitude),
      ),
    );

    mapController.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 80),
    );
  }

  // ===== RESET =====
  static void reset() {
    _smoothedHeading = 0;
    // ✅ 修正: reset 時は _isAnimating も必ず解除する
    _isAnimating = false;
  }
}
