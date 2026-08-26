import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'hazard_report.dart';

class RideReport {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final double distanceKm;
  final double avgSpeedKmh;
  final double maxSpeedKmh;
  final int suddenBrakeCount;
  final int hazardCount;
  final bool nightRide;
  final int safetyScore;
  final List<HazardReport> hazardEvents;
  final List<LatLng> routeTrace;
  final String? weather;
  final double? temperature;

  RideReport({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.distanceKm,
    required this.avgSpeedKmh,
    required this.maxSpeedKmh,
    required this.suddenBrakeCount,
    required this.hazardCount,
    required this.nightRide,
    required this.safetyScore,
    required this.hazardEvents,
    required this.routeTrace,
    this.weather,
    this.temperature,
  });

  int get durationMinutes => endTime.difference(startTime).inMinutes;

  String get grade {
    if (safetyScore >= 90) return 'S';
    if (safetyScore >= 75) return 'A';
    if (safetyScore >= 60) return 'B';
    if (safetyScore >= 40) return 'C';
    return 'D';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'distanceKm': distanceKm,
        'durationMinutes': durationMinutes,
        'avgSpeedKmh': avgSpeedKmh,
        'maxSpeedKmh': maxSpeedKmh,
        'suddenBrakeCount': suddenBrakeCount,
        'hazardCount': hazardCount,
        'nightRide': nightRide,
        'safetyScore': safetyScore,
        'grade': grade,
        'weather': weather,
        'temperature': temperature,
        'hazardEvents': hazardEvents.map((e) => e.toJson()).toList(),
        'routeTrace': routeTrace
            .map((p) => {'lat': p.latitude, 'lng': p.longitude})
            .toList(),
      };

  factory RideReport.fromJson(Map<String, dynamic> j) => RideReport(
        id: j['id'] as String,
        startTime: DateTime.parse(j['startTime'] as String),
        endTime: DateTime.parse(j['endTime'] as String),
        distanceKm: (j['distanceKm'] as num).toDouble(),
        avgSpeedKmh: (j['avgSpeedKmh'] as num).toDouble(),
        maxSpeedKmh: (j['maxSpeedKmh'] as num).toDouble(),
        suddenBrakeCount: j['suddenBrakeCount'] as int,
        hazardCount: j['hazardCount'] as int,
        nightRide: j['nightRide'] as bool,
        safetyScore: j['safetyScore'] as int,
        hazardEvents: (j['hazardEvents'] as List)
            .map((e) => HazardReport.fromJson(e as Map<String, dynamic>))
            .toList(),
        routeTrace: (j['routeTrace'] as List)
            .map((p) => LatLng(
                (p['lat'] as num).toDouble(), (p['lng'] as num).toDouble()))
            .toList(),
        weather: j['weather'] as String?,
        temperature: (j['temperature'] as num?)?.toDouble(),
      );
}
