import 'package:google_maps_flutter/google_maps_flutter.dart';

enum HazardType {
  suddenBrake,
  nearMiss,
  dangerousRoad,
  other,
}

class HazardReport {
  final String id;
  final HazardType type;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String? note;

  HazardReport({
    required this.id,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.note,
  });

  LatLng get position => LatLng(latitude, longitude);

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.index,
        'lat': latitude,
        'lng': longitude,
        'ts': timestamp.millisecondsSinceEpoch,
        'note': note,
      };

  factory HazardReport.fromJson(Map<String, dynamic> j) => HazardReport(
        id: j['id'] as String,
        type: HazardType.values[j['type'] as int],
        latitude: (j['lat'] as num).toDouble(),
        longitude: (j['lng'] as num).toDouble(),
        timestamp: DateTime.fromMillisecondsSinceEpoch(j['ts'] as int),
        note: j['note'] as String?,
      );

  static String labelFor(HazardType t) {
    switch (t) {
      case HazardType.suddenBrake:
        return '急ブレーキ';
      case HazardType.nearMiss:
        return 'ヒヤリハット';
      case HazardType.dangerousRoad:
        return '危険箇所';
      case HazardType.other:
        return 'その他';
    }
  }
}
