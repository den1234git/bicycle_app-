import 'package:google_maps_flutter/google_maps_flutter.dart';

enum HazardType {
  suddenBrake,
  nearMiss,
  dangerousRoad,
  flood,
  landslide,
  roadClosed,
  fallenTree,
  construction,
  icy,
  poorVisibility,
  other,
}

class HazardReport {
  final String id;
  final HazardType type;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String? note;
  final String? photoPath;

  HazardReport({
    required this.id,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.note,
    this.photoPath,
  });

  LatLng get position => LatLng(latitude, longitude);

  bool get isExpired => DateTime.now().isAfter(timestamp.add(autoExpiry));

  Duration get autoExpiry {
    switch (type) {
      case HazardType.suddenBrake: return const Duration(days: 90);
      case HazardType.nearMiss: return const Duration(days: 90);
      case HazardType.dangerousRoad: return const Duration(days: 30);
      case HazardType.flood: return const Duration(hours: 6);
      case HazardType.landslide: return const Duration(hours: 72);
      case HazardType.roadClosed: return const Duration(hours: 24);
      case HazardType.fallenTree: return const Duration(hours: 48);
      case HazardType.construction: return const Duration(days: 7);
      case HazardType.icy: return const Duration(hours: 12);
      case HazardType.poorVisibility: return const Duration(hours: 3);
      case HazardType.other: return const Duration(hours: 6);
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'lat': latitude,
        'lng': longitude,
        'ts': timestamp.millisecondsSinceEpoch,
        'note': note,
        'photoPath': photoPath,
      };

  factory HazardReport.fromJson(Map<String, dynamic> j) {
    HazardType parseType(dynamic v) {
      if (v is int) return HazardType.values[v];
      if (v is String) {
        return HazardType.values.firstWhere(
          (e) => e.name == v,
          orElse: () => HazardType.other,
        );
      }
      return HazardType.other;
    }

    return HazardReport(
      id: j['id'] as String,
      type: parseType(j['type']),
      latitude: (j['lat'] as num).toDouble(),
      longitude: (j['lng'] as num).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(j['ts'] as int),
      note: j['note'] as String?,
      photoPath: j['photoPath'] as String?,
    );
  }

  static String labelFor(HazardType t) {
    switch (t) {
      case HazardType.suddenBrake: return '急ブレーキ';
      case HazardType.nearMiss: return 'ヒヤリハット';
      case HazardType.dangerousRoad: return '危険箇所';
      case HazardType.flood: return '冠水';
      case HazardType.landslide: return '土砂崩れ';
      case HazardType.roadClosed: return '通行止め';
      case HazardType.fallenTree: return '倒木';
      case HazardType.construction: return '工事';
      case HazardType.icy: return '凍結';
      case HazardType.poorVisibility: return '視界不良';
      case HazardType.other: return 'その他';
    }
  }

  static String emojiFor(HazardType t) {
    switch (t) {
      case HazardType.suddenBrake: return '🛑';
      case HazardType.nearMiss: return '💥';
      case HazardType.dangerousRoad: return '⚠️';
      case HazardType.flood: return '🌊';
      case HazardType.landslide: return '⛰️';
      case HazardType.roadClosed: return '🚧';
      case HazardType.fallenTree: return '🌳';
      case HazardType.construction: return '🏗️';
      case HazardType.icy: return '🧊';
      case HazardType.poorVisibility: return '🌫️';
      case HazardType.other: return '❗';
    }
  }

  static IconLabel iconFor(HazardType t) {
    switch (t) {
      case HazardType.suddenBrake: return IconLabel(0xe531, 0xFFF44336); // warning, red
      case HazardType.nearMiss: return IconLabel(0xe531, 0xFFFF9800); // warning, orange
      case HazardType.dangerousRoad: return IconLabel(0xe531, 0xFFFF5722); // warning, deep orange
      case HazardType.flood: return IconLabel(0xe41c, 0xFF2196F3); // water, blue
      case HazardType.landslide: return IconLabel(0xf0773, 0xFF795548); // landscape, brown
      case HazardType.roadClosed: return IconLabel(0xe14b, 0xFFF44336); // block, red
      case HazardType.fallenTree: return IconLabel(0xea48, 0xFF4CAF50); // park, green
      case HazardType.construction: return IconLabel(0xea3c, 0xFFFF9800); // construction, orange
      case HazardType.icy: return IconLabel(0xeb3b, 0xFF03A9F4); // ac_unit, light blue
      case HazardType.poorVisibility: return IconLabel(0xe818, 0xFF9E9E9E); // cloud, grey
      case HazardType.other: return IconLabel(0xe88e, 0xFF9E9E9E); // info, grey
    }
  }
}

class IconLabel {
  final int iconCode;
  final int colorValue;
  const IconLabel(this.iconCode, this.colorValue);
}
