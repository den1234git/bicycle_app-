import 'dart:convert';
import 'package:http/http.dart' as http;

class PlaceService {
  final String apiKey;

  PlaceService(this.apiKey);

  Future<Map<String, double>?> search(String keyword) async {
    if (keyword.isEmpty) return null;

    final url = Uri.parse(
      "https://maps.googleapis.com/maps/api/geocode/json?address=$keyword&key=AIzaSyDWMoJAakJzv7c4fA1RQTp1FnPZKVWjhEk",
    );

    final res = await http.get(url);
    final data = json.decode(res.body);

    if (data["results"].isEmpty) return null;

    final loc = data["results"][0]["geometry"]["location"];

    return {
      "lat": loc["lat"],
      "lng": loc["lng"],
    };
  }
}