import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/hazard_report.dart';
import '../models/ride_report.dart';

class RideTracker {
  DateTime? _startTime;
  final List<LatLng> _trace = [];
  final List<HazardReport> _hazards = [];
  final List<double> _speeds = [];
  double _maxSpeed = 0;
  int _suddenBrakeCount = 0;
  String? _weather;
  double? _temperature;
  bool _tracking = false;

  bool get isTracking => _tracking;

  void start() {
    _startTime = DateTime.now();
    _trace.clear();
    _hazards.clear();
    _speeds.clear();
    _maxSpeed = 0;
    _suddenBrakeCount = 0;
    _tracking = true;
  }

  void recordPosition(LatLng pos, double speed) {
    if (!_tracking) return;
    _trace.add(pos);
    _speeds.add(speed);
    if (speed > _maxSpeed) _maxSpeed = speed;
  }

  void recordHazard(HazardReport hazard) {
    if (!_tracking) return;
    _hazards.add(hazard);
    if (hazard.type == HazardType.suddenBrake) _suddenBrakeCount++;
  }

  void setWeather(String weather, double temp) {
    _weather = weather;
    _temperature = temp;
  }

  Future<RideReport?> stop(double distanceKm) async {
    if (!_tracking || _startTime == null) return null;
    _tracking = false;

    final endTime = DateTime.now();
    final avgSpeed = _speeds.isEmpty
        ? 0.0
        : _speeds.reduce((a, b) => a + b) / _speeds.length;

    final nightRide = _startTime!.hour >= 18 || _startTime!.hour < 6 ||
        endTime.hour >= 18 || endTime.hour < 6;

    final score = _calcSafetyScore(
      suddenBrakes: _suddenBrakeCount,
      maxSpeed: _maxSpeed,
      avgSpeed: avgSpeed,
      nightRide: nightRide,
      hazardCount: _hazards.length,
      durationMin: endTime.difference(_startTime!).inMinutes,
    );

    // 間引き: 軌跡を最大500ポイントに
    final trace = _trace.length > 500
        ? List.generate(500, (i) => _trace[(i * _trace.length / 500).floor()])
        : List<LatLng>.from(_trace);

    final report = RideReport(
      id: _startTime!.millisecondsSinceEpoch.toString(),
      startTime: _startTime!,
      endTime: endTime,
      distanceKm: distanceKm,
      avgSpeedKmh: avgSpeed,
      maxSpeedKmh: _maxSpeed,
      suddenBrakeCount: _suddenBrakeCount,
      hazardCount: _hazards.length,
      nightRide: nightRide,
      safetyScore: score,
      hazardEvents: List.from(_hazards),
      routeTrace: trace,
      weather: _weather,
      temperature: _temperature,
    );

    await _saveReport(report);
    return report;
  }

  static int _calcSafetyScore({
    required int suddenBrakes,
    required double maxSpeed,
    required double avgSpeed,
    required bool nightRide,
    required int hazardCount,
    required int durationMin,
  }) {
    double score = 100;

    // 急ブレーキ: 1回ごとに-5（走行時間で正規化）
    final brakeRate = durationMin > 0 ? suddenBrakes / (durationMin / 30) : suddenBrakes.toDouble();
    score -= (brakeRate * 5).clamp(0, 30);

    // 最高速度: 30km/h超過で減点
    if (maxSpeed > 30) score -= ((maxSpeed - 30) * 1.5).clamp(0, 20);

    // 夜間走行: -5
    if (nightRide) score -= 5;

    // ハザードイベント: 1件ごとに-3
    score -= (hazardCount * 3).clamp(0, 15).toDouble();

    return score.round().clamp(0, 100);
  }

  static Future<void> _saveReport(RideReport report) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('ride_reports') ?? [];
    raw.add(jsonEncode(report.toJson()));
    // 最新100件のみ保持
    if (raw.length > 100) raw.removeRange(0, raw.length - 100);
    await prefs.setStringList('ride_reports', raw);
  }

  static Future<List<RideReport>> loadReports() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('ride_reports');
    if (raw == null) return [];
    return raw
        .map((s) => RideReport.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  static Future<int> overallScore() async {
    final reports = await loadReports();
    if (reports.isEmpty) return 100;
    final total = reports.fold<int>(0, (sum, r) => sum + r.safetyScore);
    return total ~/ reports.length;
  }
}
