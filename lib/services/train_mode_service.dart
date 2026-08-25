import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'train_task_handler.dart';

class TrainModeService {
  static Future<void> start({
    String text = '乗過ごし防止 ON',
  }) async {
    if (await FlutterForegroundTask.isRunningService) {
      return;
    }

    await FlutterForegroundTask.startService(
      serviceId: 100,
      notificationTitle: '🚆 電車モード',
      // ✅ 修正: タップで復帰できることを本文に明記
      notificationText: '$text（タップで復帰）',
      callback: startCallback,
      // 「↩ アプリ復帰」ボタンを削除。
      // 通知バー本文タップでも復帰できる（標準のcontentIntent）ため、
      // 小さく押しづらいボタンは廃止し、停止ボタンのみ残す。
      notificationButtons: [
        const NotificationButton(
          id: 'stop',
          text: '⏹ 電車モードを停止',
        ),
      ],
    );
  }

  static Future<void> update({
    required String text,
    String title = '🚆 電車モード',
  }) async {
    if (!await FlutterForegroundTask.isRunningService) return;

    await FlutterForegroundTask.updateService(
      notificationTitle: title,
      // ✅ 修正: タップで復帰できることを本文に明記
      notificationText: '$text（タップで復帰）',
    );
  }

  static Future<void> alertArrival({
    required String stationName,
    required double distanceM,
  }) async {
    if (!await FlutterForegroundTask.isRunningService) return;

    final distText = distanceM < 1000
        ? '${distanceM.toInt()}m'
        : '${(distanceM / 1000).toStringAsFixed(1)}km';

    await FlutterForegroundTask.updateService(
      notificationTitle: '🚉 もうすぐ $stationName',
      notificationText: '残り $distText ・タップでアプリ復帰',
    );
  }

  static Future<void> stop() async {
    await FlutterForegroundTask.stopService();
  }

  static Future<bool> isRunning() async {
    return await FlutterForegroundTask.isRunningService;
  }
}
