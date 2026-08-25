import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_android/geolocator_android.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SensorController {
  StreamSubscription<Position>? posSub;
  StreamSubscription? compassSub;
  StreamSubscription? gyroSub;

  Future<void> startGps({
    required Future<void> Function(
      LatLng pos,
      double speed,
      double heading,
    ) onUpdate,
    required bool Function() isActive,
  }) async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    // ✅ 修正: 表示の遅延対策。
    // Android標準のFused Location Provider経由だと、intervalDurationを
    // 5秒未満に設定しても実際には5秒程度になる既知の制約がある。
    // forceLocationManager: true でAndroidのLocationManagerを直接使うことで
    // より短い更新間隔を実現する。
    final locationSettings = AndroidSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0, // 距離フィルタなし、intervalDurationのみで制御
      intervalDuration: const Duration(milliseconds: 1000),
      forceLocationManager: true,
    );

    posSub = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (p) async {
        if (!isActive()) return;

        final speed = p.speed < 0 ? 0.0 : p.speed * 3.6;

        await onUpdate(
          LatLng(p.latitude, p.longitude),
          speed,
          p.heading,
        );
      },
      onError: (e) {
        // エラーを静かに無視してストリームを継続
      },
      cancelOnError: false,
    );
  }

  void startCompass({
    required double Function() getCurrentHeading,
    required double Function() getSensorHeading,
    required bool Function() isActive,
    required void Function(double diff) onRotate,
  }) {
    compassSub = magnetometerEventStream().listen((event) {
      if (!isActive()) return;

      final angle = atan2(event.y, event.x) * 180 / pi;
      final sensorHeading = (angle + 360) % 360;

      final diff = ((sensorHeading - getCurrentHeading() + 540) % 360) - 180;

      if (diff.abs() > 8) {
        onRotate(diff * 0.35);
      }
    });

    gyroSub = gyroscopeEventStream().listen((event) {
      if (!isActive()) return;

      final rotation = event.z * 2.4;

      if (rotation.abs() > 0.01) {
        onRotate(rotation);
      }
    });
  }

  void dispose() {
    posSub?.cancel();
    compassSub?.cancel();
    gyroSub?.cancel();
  }
}
