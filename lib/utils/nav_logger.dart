import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class NavLogger {
  static final List<String> _buffer = [];
  static final List<String> _pendingLogs = [];
  static Timer? _saveTimer;

  // =========================
  // ログ本体（唯一の正解）
  // =========================
  static void _log(String tag, String message) {
    final line = '[${DateTime.now().toIso8601String()}][$tag] $message';

    // コンソール
    developer.log(line);

    // メモリ保持
    _buffer.add(line);
    if (_buffer.length > 500) {
      _buffer.removeAt(0);
    }

    // 保存キュー
    _pendingLogs.add(line);

    // Timerは1回だけ起動
    _startTimerIfNeeded();
  }

  // =========================
  // 外部API
  // =========================
  static void gps(String msg) => _log('GPS', msg);
  static void camera(String msg) => _log('CAMERA', msg);
  static void nav(String msg) => _log('NAV', msg);
  static void follow(String msg) => _log('FOLLOW', msg);

  static List<String> dump() => List.from(_buffer);

  static void clear() => _buffer.clear();

  static void stop() {
    _saveTimer?.cancel();
    _saveTimer = null;
  }

  // =========================
  // Timer管理
  // =========================
  static void _startTimerIfNeeded() {
    if (_saveTimer != null) return;

    _saveTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _flushLogs(),
    );
  }

  // =========================
  // ファイル保存
  // =========================
  static Future<void> _flushLogs() async {
    if (_pendingLogs.isEmpty) return;

    try {
      final dir = await getApplicationDocumentsDirectory();

      final file = File('${dir.path}/nav_log.txt');

      developer.log('LOG FILE PATH: ${file.path}');

      final content = '${_pendingLogs.join('\n')}\n';

      _pendingLogs.clear();

      await file.writeAsString(
        content,
        mode: FileMode.append,
      );
    } catch (e) {
      developer.log('NAV LOG ERROR: $e');
    }
  }

  static Future<void> flushWithModeHeader(String mode) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/nav_log.txt');

      final header = '''
===== MODE CHANGE: $mode =====
TIME: ${DateTime.now().toIso8601String()}
==============================
''';

      final content = '$header\n${_pendingLogs.join('\n')}\n';

      _pendingLogs.clear();

      await file.writeAsString(
        content,
        mode: FileMode.append,
      );
    } catch (e) {
      developer.log('NAV LOG ERROR (MODE FLUSH): $e');
    }
  }
}
