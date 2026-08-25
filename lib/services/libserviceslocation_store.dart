import 'package:shared_preferences/shared_preferences.dart';

class LocationStore {
  static Future<void> saveHome(double lat, double lng) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('home_lat', lat);
    await prefs.setDouble('home_lng', lng);
  }

  static Future<void> saveWork(double lat, double lng) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('work_lat', lat);
    await prefs.setDouble('work_lng', lng);
  }

  static Future<Map<String, double>?> loadHome() async {
    final prefs = await SharedPreferences.getInstance();

    final lat = prefs.getDouble('home_lat');
    final lng = prefs.getDouble('home_lng');

    if (lat == null || lng == null) return null;

    return {
      'lat': lat,
      'lng': lng,
    };
  }

  static Future<Map<String, double>?> loadWork() async {
    final prefs = await SharedPreferences.getInstance();

    final lat = prefs.getDouble('work_lat');
    final lng = prefs.getDouble('work_lng');

    if (lat == null || lng == null) return null;

    return {
      'lat': lat,
      'lng': lng,
    };
  }
}
