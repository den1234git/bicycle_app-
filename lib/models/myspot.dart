class MySpot {
  final String name;
  final double lat;
  final double lng;

  MySpot({
    required this.name,
    required this.lat,
    required this.lng,
  });

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "lat": lat,
      "lng": lng,
    };
  }

  factory MySpot.fromJson(Map<String, dynamic> json) {
    return MySpot(
      name: json["name"],
      lat: json["lat"],
      lng: json["lng"],
    );
  }
}
