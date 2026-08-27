enum SosType {
  emergency119,
  police110,
  chikan,
  fight,
  accident,
  suspicious,
  other,
}

class SosReport {
  final String id;
  final SosType type;
  final DateTime timestamp;
  final double? lat;
  final double? lng;
  final String? memo;

  SosReport({
    required this.id,
    required this.type,
    required this.timestamp,
    this.lat,
    this.lng,
    this.memo,
  });

  String get typeLabel {
    switch (type) {
      case SosType.emergency119: return '救急 119';
      case SosType.police110: return '警察 110';
      case SosType.chikan: return '痴漢';
      case SosType.fight: return '喧嘩・暴力';
      case SosType.accident: return '事故';
      case SosType.suspicious: return '不審者';
      case SosType.other: return 'その他';
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'timestamp': timestamp.toIso8601String(),
    'lat': lat,
    'lng': lng,
    'memo': memo,
  };

  factory SosReport.fromJson(Map<String, dynamic> j) => SosReport(
    id: j['id'] as String,
    type: SosType.values.firstWhere((e) => e.name == j['type']),
    timestamp: DateTime.parse(j['timestamp'] as String),
    lat: (j['lat'] as num?)?.toDouble(),
    lng: (j['lng'] as num?)?.toDouble(),
    memo: j['memo'] as String?,
  );
}
