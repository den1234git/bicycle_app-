import 'dart:convert';
import 'dart:developer' as developer;

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../api_keys.dart';

class PlaceService {
  static Future<LatLng?> searchPlace(
    String query,
  ) async {
    developer.log('SEARCH: query="$query"');

    final url = "https://maps.googleapis.com/maps/api/geocode/json"
        "?address=${Uri.encodeComponent(query)}"
        "&key=${ApiKeys.googleApiKey}";

    try {
      final response = await http.get(
        Uri.parse(url),
      );

      developer.log('SEARCH: status=${response.statusCode}');
      developer.log('SEARCH: body=${response.body.substring(0, response.body.length.clamp(0, 500))}');

      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body);

      if (data["results"] == null || data["results"].isEmpty) {
        developer.log('SEARCH: no results, status=${data["status"]}');
        return null;
      }

      final location = data["results"][0]["geometry"]["location"];

      developer.log('SEARCH: found lat=${location["lat"]} lng=${location["lng"]}');

      return LatLng(
        (location["lat"] as num).toDouble(),
        (location["lng"] as num).toDouble(),
      );
    } catch (e) {
      developer.log('SEARCH: ERROR $e');
      return null;
    }
  }
}
