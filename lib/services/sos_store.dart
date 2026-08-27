import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sos_report.dart';

class SosStore {
  static const _key = 'sos_reports';

  static Future<void> save(SosReport report) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    raw.add(jsonEncode(report.toJson()));
    if (raw.length > 200) raw.removeRange(0, raw.length - 200);
    await prefs.setStringList(_key, raw);
  }

  static Future<List<SosReport>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key);
    if (raw == null) return [];
    return raw
        .map((s) => SosReport.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList()
        .reversed
        .toList();
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
