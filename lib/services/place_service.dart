import 'dart:convert';
import 'dart:developer' as developer;

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../api_keys.dart';

class PlaceService {
  static Future<LatLng?> searchPlace(String query) async {
    developer.log('SEARCH: query="$query"');

    final result = await _searchPlaces(query);
    if (result != null) return result;

    developer.log('SEARCH: Places API no result, trying Geocoding');
    return _searchGeocode(query);
  }

  static Future<LatLng?> _searchPlaces(String query) async {
    final url = "https://maps.googleapis.com/maps/api/place/textsearch/json"
        "?query=${Uri.encodeComponent(query)}"
        "&language=ja"
        "&key=${ApiKeys.googleApiKey}";

    try {
      final response = await http.get(Uri.parse(url));
      developer.log('PLACES: status=${response.statusCode}');
      developer.log('PLACES: body=${response.body.substring(0, response.body.length.clamp(0, 500))}');

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      if (data["results"] == null || (data["results"] as List).isEmpty) {
        developer.log('PLACES: no results, status=${data["status"]}');
        return null;
      }

      final loc = data["results"][0]["geometry"]["location"];
      developer.log('PLACES: found lat=${loc["lat"]} lng=${loc["lng"]} name=${data["results"][0]["name"]}');

      return LatLng(
        (loc["lat"] as num).toDouble(),
        (loc["lng"] as num).toDouble(),
      );
    } catch (e) {
      developer.log('PLACES: ERROR $e');
      return null;
    }
  }

  static Future<LatLng?> _searchGeocode(String query) async {
    final url = "https://maps.googleapis.com/maps/api/geocode/json"
        "?address=${Uri.encodeComponent(query)}"
        "&key=${ApiKeys.googleApiKey}";

    try {
      final response = await http.get(Uri.parse(url));
      developer.log('GEOCODE: status=${response.statusCode}');

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      if (data["results"] == null || (data["results"] as List).isEmpty) {
        developer.log('GEOCODE: no results, status=${data["status"]}');
        return null;
      }

      final loc = data["results"][0]["geometry"]["location"];
      developer.log('GEOCODE: found lat=${loc["lat"]} lng=${loc["lng"]}');

      return LatLng(
        (loc["lat"] as num).toDouble(),
        (loc["lng"] as num).toDouble(),
      );
    } catch (e) {
      developer.log('GEOCODE: ERROR $e');
      return null;
    }
  }
}
