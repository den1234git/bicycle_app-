class RideLog {
  final String date;
  final double distanceKm;
  final int minutes;
  final double avgSpeed;
  final int dangerCount;
  final double kcal;

  RideLog({
    required this.date,
    required this.distanceKm,
    required this.minutes,
    required this.avgSpeed,
    required this.dangerCount,
    required this.kcal,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'distanceKm': distanceKm,
      'minutes': minutes,
      'avgSpeed': avgSpeed,
      'dangerCount': dangerCount,
      'kcal': kcal,
    };
  }

  factory RideLog.fromJson(
    Map<String, dynamic> json,
  ) {
    return RideLog(
      date: json['date'],
      distanceKm: json['distanceKm'],
      minutes: json['minutes'],
      avgSpeed: json['avgSpeed'],
      dangerCount: json['dangerCount'],
      kcal: json['kcal'],
    );
  }
}
