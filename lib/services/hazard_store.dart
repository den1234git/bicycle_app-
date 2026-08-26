import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/hazard_report.dart';

class HazardStore {
  static const _key = 'hazard_reports';

  static Future<List<HazardReport>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key);
    if (raw == null) return [];
    return raw
        .map((s) => HazardReport.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  static Future<void> save(HazardReport report) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    raw.add(jsonEncode(report.toJson()));
    await prefs.setStringList(_key, raw);
  }

  static Future<void> saveAll(List<HazardReport> reports) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      reports.map((r) => jsonEncode(r.toJson())).toList(),
    );
  }

  static Future<HazardReport> addReport({
    required HazardType type,
    required LatLng position,
    String? note,
  }) async {
    final report = HazardReport(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: DateTime.now(),
      note: note,
    );
    await save(report);
    return report;
  }
}
