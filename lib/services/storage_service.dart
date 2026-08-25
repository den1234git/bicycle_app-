import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/ride_log.dart';
import '../models/myspot.dart';

class StorageService {
  // ===============================
  // 走行ログ保存
  // ===============================
  static Future<void> saveRideLog(RideLog log) async {
    final prefs = await SharedPreferences.getInstance();

    final oldList = prefs.getStringList("ride_logs") ?? [];

    oldList.add(jsonEncode(log.toJson()));

    await prefs.setStringList("ride_logs", oldList);
  }

  static Future<List<RideLog>> loadRideLogs() async {
    final prefs = await SharedPreferences.getInstance();

    final list = prefs.getStringList("ride_logs") ?? [];

    return list
        .map((e) => RideLog.fromJson(jsonDecode(e)))
        .toList()
        .reversed
        .toList();
  }

  // ===============================
  // MYSPOT保存
  // ===============================
  static Future<void> saveMySpot(MySpot spot) async {
    final prefs = await SharedPreferences.getInstance();

    final oldList = prefs.getStringList("my_spots") ?? [];

    oldList.removeWhere((e) {
      final item = MySpot.fromJson(jsonDecode(e));
      return item.name == spot.name;
    });

    oldList.add(jsonEncode(spot.toJson()));

    await prefs.setStringList("my_spots", oldList);
  }

  static Future<List<MySpot>> loadMySpots() async {
    final prefs = await SharedPreferences.getInstance();

    final list = prefs.getStringList("my_spots") ?? [];

    return list.map((e) => MySpot.fromJson(jsonDecode(e))).toList();
  }

  static Future<void> deleteMySpot(String name) async {
    final prefs = await SharedPreferences.getInstance();

    final list = prefs.getStringList("my_spots") ?? [];

    list.removeWhere((e) {
      final item = MySpot.fromJson(jsonDecode(e));
      return item.name == name;
    });

    await prefs.setStringList("my_spots", list);
  }
}
