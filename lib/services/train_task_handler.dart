import 'package:flutter_foreground_task/flutter_foreground_task.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(TrainTaskHandler());
}

class TrainTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(
    DateTime timestamp,
    TaskStarter starter,
  ) async {
    // ✅ 修正: 「（タップで復帰）」を追加。
    //    ここはサービス開始時にOSから直接呼ばれるコールバックなので、
    //    TrainModeService.start()で設定した文言とは別に
    //    ここでも明記しておく必要がある。
    FlutterForegroundTask.updateService(
      notificationTitle: '🚆 電車モード',
      notificationText: '次: 葛西駅 300m（タップで復帰）',
    );
  }

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp) async {}

  @override
  void onReceiveData(Object data) {}

  @override
  void onNotificationButtonPressed(String id) {
    // ✅ 修正: 'resume' ボタンは廃止（通知バー本文タップで復帰するため）。
    //    停止ボタンのみ残す。
    if (id == 'stop') {
      FlutterForegroundTask.stopService();
    }
  }
}
