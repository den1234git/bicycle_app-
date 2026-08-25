import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../api_keys.dart';

class PlaceService {
  static Future<LatLng?> searchPlace(
    String query,
  ) async {
    final url = "https://maps.googleapis.com/maps/api/geocode/json"
        "?address=${Uri.encodeComponent(query)}"
        "&key=${ApiKeys.googleApiKey}";

    final response = await http.get(
      Uri.parse(url),
    );

    if (response.statusCode != 200) {
      return null;
    }

    final data = jsonDecode(response.body);

    if (data["results"] == null || data["results"].isEmpty) {
      return null;
    }

    final location = data["results"][0]["geometry"]["location"];

    return LatLng(
      (location["lat"] as num).toDouble(),
      (location["lng"] as num).toDouble(),
    );
  }
}
