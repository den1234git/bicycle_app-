import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  static Future<bool> getNavVoice() => _getBool('nav_voice', true);
  static Future<void> setNavVoice(bool v) => _setBool('nav_voice', v);

  static Future<double> getVolume() => _getDouble('volume', 0.8);
  static Future<void> setVolume(double v) => _setDouble('volume', v);

  static Future<String> getGpsAccuracy() => _getString('gps_accuracy', 'high'); // high, balanced, low
  static Future<void> setGpsAccuracy(String v) => _setString('gps_accuracy', v);

  static Future<bool> getNotifications() => _getBool('notifications', true);
  static Future<void> setNotifications(bool v) => _setBool('notifications', v);

  static Future<bool> getBatterySaver() => _getBool('battery_saver', false);
  static Future<void> setBatterySaver(bool v) => _setBool('battery_saver', v);

  static Future<bool> getAutoReroute() => _getBool('auto_reroute', true);
  static Future<void> setAutoReroute(bool v) => _setBool('auto_reroute', v);

  static Future<String> getRoutingEngine() => _getString('routing_engine', 'google'); // google, osrm
  static Future<void> setRoutingEngine(String v) => _setString('routing_engine', v);

  static Future<String> getMapTheme() => _getString('map_theme', 'standard'); // standard, dark, satellite
  static Future<void> setMapTheme(String v) => _setString('map_theme', v);

  static Future<bool> getWeatherEffect() => _getBool('weather_effect', true);
  static Future<void> setWeatherEffect(bool v) => _setBool('weather_effect', v);

  static Future<bool> getTimeEffect() => _getBool('time_effect', true);
  static Future<void> setTimeEffect(bool v) => _setBool('time_effect', v);

  static Future<bool> getShowUi() => _getBool('show_ui', true);
  static Future<void> setShowUi(bool v) => _setBool('show_ui', v);

  static Future<double> getCameraTilt() => _getDouble('camera_tilt', 60.0);
  static Future<void> setCameraTilt(double v) => _setDouble('camera_tilt', v);

  static Future<double> getCameraZoom() => _getDouble('camera_zoom', 17.0);
  static Future<void> setCameraZoom(double v) => _setDouble('camera_zoom', v);

  static Future<bool> getCameraFollow() => _getBool('camera_follow', true);
  static Future<void> setCameraFollow(bool v) => _setBool('camera_follow', v);

  static Future<double> getCameraSmoothness() => _getDouble('camera_smoothness', 0.5);
  static Future<void> setCameraSmoothness(double v) => _setDouble('camera_smoothness', v);

  static Future<int> getRouteColor() => _getInt('route_color', 0xFFB388FF);
  static Future<void> setRouteColor(int v) => _setInt('route_color', v);

  static Future<double> getRouteWidth() => _getDouble('route_width', 6.0);
  static Future<void> setRouteWidth(double v) => _setDouble('route_width', v);

  static Future<double> getMarkerSize() => _getDouble('marker_size', 1.0);
  static Future<void> setMarkerSize(double v) => _setDouble('marker_size', v);

  static Future<int> getMarkerColor() => _getInt('marker_color', 0xFF4CAF50);
  static Future<void> setMarkerColor(int v) => _setInt('marker_color', v);

  static Future<String> getBikeMarker() => _getString('bike_marker', 'default');
  static Future<void> setBikeMarker(String v) => _setString('bike_marker', v);

  static Future<String> getWalkMarker() => _getString('walk_marker', 'default');
  static Future<void> setWalkMarker(String v) => _setString('walk_marker', v);

  static Future<String> getInsuranceInfo() => _getString('insurance_info', '');
  static Future<void> setInsuranceInfo(String v) => _setString('insurance_info', v);

  static Future<String> getEmergencyContact() => _getString('emergency_contact', '');
  static Future<void> setEmergencyContact(String v) => _setString('emergency_contact', v);

  static Future<String> getAccidentMemo() => _getString('accident_memo', '');
  static Future<void> setAccidentMemo(String v) => _setString('accident_memo', v);

  static Future<String> getSchoolName() => _getString('school_name', '');
  static Future<void> setSchoolName(String v) => _setString('school_name', v);

  static Future<double?> getSchoolLat() => _getDoubleNullable('school_lat');
  static Future<double?> getSchoolLng() => _getDoubleNullable('school_lng');
  static Future<void> setSchoolPos(double lat, double lng) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('school_lat', lat);
    await prefs.setDouble('school_lng', lng);
  }

  static Future<double?> getParkingLat() => _getDoubleNullable('parking_lat');
  static Future<double?> getParkingLng() => _getDoubleNullable('parking_lng');
  static Future<void> setParkingPos(double lat, double lng) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('parking_lat', lat);
    await prefs.setDouble('parking_lng', lng);
  }

  static Future<bool> _getBool(String key, bool def) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? def;
  }
  static Future<void> _setBool(String key, bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, v);
  }
  static Future<double> _getDouble(String key, double def) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(key) ?? def;
  }
  static Future<double?> _getDoubleNullable(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(key);
  }
  static Future<void> _setDouble(String key, double v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(key, v);
  }
  static Future<String> _getString(String key, String def) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key) ?? def;
  }
  static Future<void> _setString(String key, String v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, v);
  }
  static Future<int> _getInt(String key, int def) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key) ?? def;
  }
  static Future<void> _setInt(String key, int v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, v);
  }
}
