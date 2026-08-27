import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../services/app_settings.dart';
import '../services/ride_tracker.dart';
import '../services/sos_store.dart';
import '../services/custom_marker_service.dart';
import '../models/ride_report.dart';
import '../models/sos_report.dart';
import '../dialogs/hazard_dialog.dart';

class MorePage extends StatefulWidget {
  const MorePage({
    super.key,
    required this.homeRegistered,
    required this.companyRegistered,
    required this.onSelectHome,
    required this.onSelectCompany,
    required this.onSelectSchool,
    required this.onSelectParking,
    required this.schoolRegistered,
    required this.parkingRegistered,
  });

  final bool homeRegistered;
  final bool companyRegistered;
  final bool schoolRegistered;
  final bool parkingRegistered;
  final VoidCallback onSelectHome;
  final VoidCallback onSelectCompany;
  final VoidCallback onSelectSchool;
  final VoidCallback onSelectParking;

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  bool _navVoice = true;
  double _volume = 0.8;
  String _gpsAccuracy = 'high';
  bool _notifications = true;
  bool _batterySaver = false;
  bool _autoReroute = true;
  String _routingEngine = 'google';
  String _mapTheme = 'standard';
  bool _weatherEffect = true;
  bool _timeEffect = true;
  bool _showUi = true;
  double _cameraTilt = 60.0;
  double _cameraZoom = 17.0;
  bool _cameraFollow = true;
  double _cameraSmoothness = 0.5;
  int _routeColor = 0xFFB388FF;
  double _routeWidth = 6.0;
  double _markerSize = 1.0;
  String _insuranceInfo = '';
  String _emergencyContact = '';
  String _accidentMemo = '';
  double _weight = 60.0;

  List<RideReport> _reports = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadReports();
    _loadCustomMarkerPath();
  }

  Future<void> _loadCustomMarkerPath() async {
    final path = await CustomMarkerService.getSavedPath();
    if (mounted) setState(() => _customMarkerPath = path);
  }

  Future<void> _loadSettings() async {
    final results = await Future.wait([
      AppSettings.getNavVoice(),
      AppSettings.getVolume(),
      AppSettings.getGpsAccuracy(),
      AppSettings.getNotifications(),
      AppSettings.getBatterySaver(),
      AppSettings.getAutoReroute(),
      AppSettings.getRoutingEngine(),
      AppSettings.getMapTheme(),
      AppSettings.getWeatherEffect(),
      AppSettings.getTimeEffect(),
      AppSettings.getShowUi(),
      AppSettings.getCameraTilt(),
      AppSettings.getCameraZoom(),
      AppSettings.getCameraFollow(),
      AppSettings.getCameraSmoothness(),
      AppSettings.getRouteColor(),
      AppSettings.getRouteWidth(),
      AppSettings.getMarkerSize(),
      AppSettings.getInsuranceInfo(),
      AppSettings.getEmergencyContact(),
      AppSettings.getAccidentMemo(),
      AppSettings.getWeight(),
    ]);
    if (!mounted) return;
    setState(() {
      _navVoice = results[0] as bool;
      _volume = results[1] as double;
      _gpsAccuracy = results[2] as String;
      _notifications = results[3] as bool;
      _batterySaver = results[4] as bool;
      _autoReroute = results[5] as bool;
      _routingEngine = results[6] as String;
      _mapTheme = results[7] as String;
      _weatherEffect = results[8] as bool;
      _timeEffect = results[9] as bool;
      _showUi = results[10] as bool;
      _cameraTilt = results[11] as double;
      _cameraZoom = results[12] as double;
      _cameraFollow = results[13] as bool;
      _cameraSmoothness = results[14] as double;
      _routeColor = results[15] as int;
      _routeWidth = results[16] as double;
      _markerSize = results[17] as double;
      _insuranceInfo = results[18] as String;
      _emergencyContact = results[19] as String;
      _accidentMemo = results[20] as String;
      _weight = results[21] as double;
    });
  }

  Future<void> _loadReports() async {
    final reports = await RideTracker.loadReports();
    if (!mounted) return;
    setState(() => _reports = reports.reversed.toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MORE'), centerTitle: true),
      body: ListView(
        children: [
          const SizedBox(height: 10),
          _buildMySettings(),
          _buildSettings(),
          _buildTrain(),
          _buildDisplay(),
          _buildCamera(),
          _buildMarker(),
          _buildBicycle(),
          _buildInsurance(),
          _buildSos(),
          _buildDemo(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _card(Widget child) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: child,
      );

  // ========== MY設定 ==========
  Widget _buildMySettings() {
    return ExpansionTile(
      leading: const Icon(Icons.home),
      title: const Text('MY設定'),
      children: [
        _locationTile(
          icon: widget.homeRegistered ? Icons.check_circle : Icons.add_location,
          color: widget.homeRegistered ? Colors.green : null,
          title: '自宅',
          subtitle: widget.homeRegistered ? '登録済み' : '未登録',
          onTap: () {
            widget.onSelectHome();
            Navigator.pop(context);
          },
        ),
        _locationTile(
          icon: widget.companyRegistered
              ? Icons.check_circle
              : Icons.add_location,
          color: widget.companyRegistered ? Colors.green : null,
          title: '会社',
          subtitle: widget.companyRegistered ? '登録済み' : '未登録',
          onTap: () {
            widget.onSelectCompany();
            Navigator.pop(context);
          },
        ),
        _locationTile(
          icon: widget.schoolRegistered
              ? Icons.check_circle
              : Icons.add_location,
          color: widget.schoolRegistered ? Colors.green : null,
          title: '学校',
          subtitle: widget.schoolRegistered ? '登録済み' : '未登録',
          onTap: () {
            widget.onSelectSchool();
            Navigator.pop(context);
          },
        ),
        _locationTile(
          icon: widget.parkingRegistered
              ? Icons.check_circle
              : Icons.add_location,
          color: widget.parkingRegistered ? Colors.green : null,
          title: '駐輪位置',
          subtitle: widget.parkingRegistered ? '登録済み' : '未登録',
          onTap: () {
            widget.onSelectParking();
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  Widget _locationTile({
    required IconData icon,
    Color? color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }

  // ========== 設定 ==========
  Widget _buildSettings() {
    return _card(ExpansionTile(
      leading: const Icon(Icons.settings),
      title: const Text('設定'),
      children: [
        SwitchListTile(
          title: const Text('ナビ音声'),
          subtitle: Text(_navVoice ? 'ON' : 'OFF'),
          value: _navVoice,
          onChanged: (v) {
            setState(() => _navVoice = v);
            AppSettings.setNavVoice(v);
          },
        ),
        ListTile(
          title: const Text('音量'),
          subtitle: Slider(
            value: _volume,
            min: 0,
            max: 1,
            divisions: 10,
            label: '${(_volume * 100).round()}%',
            onChanged: (v) {
              setState(() => _volume = v);
              AppSettings.setVolume(v);
            },
          ),
        ),
        ListTile(
          title: const Text('GPS精度'),
          subtitle: Text(_gpsLabel(_gpsAccuracy)),
          trailing: DropdownButton<String>(
            value: _gpsAccuracy,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 'high', child: Text('高精度')),
              DropdownMenuItem(value: 'balanced', child: Text('バランス')),
              DropdownMenuItem(value: 'low', child: Text('省電力')),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() => _gpsAccuracy = v);
              AppSettings.setGpsAccuracy(v);
            },
          ),
        ),
        SwitchListTile(
          title: const Text('通知'),
          value: _notifications,
          onChanged: (v) {
            setState(() => _notifications = v);
            AppSettings.setNotifications(v);
          },
        ),
        SwitchListTile(
          title: const Text('バッテリーセーバー'),
          subtitle: const Text('GPS更新頻度を下げて節電'),
          value: _batterySaver,
          onChanged: (v) {
            setState(() => _batterySaver = v);
            AppSettings.setBatterySaver(v);
          },
        ),
        SwitchListTile(
          title: const Text('自動再探索'),
          subtitle: const Text('ルートから外れたら自動で再計算'),
          value: _autoReroute,
          onChanged: (v) {
            setState(() => _autoReroute = v);
            AppSettings.setAutoReroute(v);
          },
        ),
        ListTile(
          title: const Text('Routing Engine'),
          subtitle: Text(_routingEngine == 'google' ? 'Google Directions' : 'OSRM (無料)'),
          trailing: DropdownButton<String>(
            value: _routingEngine,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 'google', child: Text('Google')),
              DropdownMenuItem(value: 'osrm', child: Text('OSRM')),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() => _routingEngine = v);
              AppSettings.setRoutingEngine(v);
            },
          ),
        ),
      ],
    ));
  }

  String _gpsLabel(String v) {
    switch (v) {
      case 'high': return '高精度';
      case 'balanced': return 'バランス';
      case 'low': return '省電力';
      default: return v;
    }
  }

  // ========== Train ==========
  Widget _buildTrain() {
    return _card(ExpansionTile(
      leading: const Icon(Icons.train),
      title: const Text('Train'),
      children: [
        ListTile(
          title: const Text('乗り過ごし防止'),
          subtitle: const Text('TRAIN通知設定'),
          onTap: () {
            Navigator.of(context, rootNavigator: true)
                .popUntil((route) => route.isFirst);
          },
        ),
      ],
    ));
  }

  // ========== Display ==========
  Widget _buildDisplay() {
    return _card(ExpansionTile(
      leading: const Icon(Icons.map),
      title: const Text('Display'),
      children: [
        ListTile(
          title: const Text('地図テーマ'),
          subtitle: Text(_themeLabel(_mapTheme)),
          trailing: DropdownButton<String>(
            value: _mapTheme,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 'standard', child: Text('標準')),
              DropdownMenuItem(value: 'dark', child: Text('ダーク')),
              DropdownMenuItem(value: 'satellite', child: Text('衛星')),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() => _mapTheme = v);
              AppSettings.setMapTheme(v);
            },
          ),
        ),
        SwitchListTile(
          title: const Text('天気演出'),
          subtitle: const Text('天気に合わせた地図演出'),
          value: _weatherEffect,
          onChanged: (v) {
            setState(() => _weatherEffect = v);
            AppSettings.setWeatherEffect(v);
          },
        ),
        SwitchListTile(
          title: const Text('時間帯演出'),
          subtitle: const Text('朝昼夜で地図の色調変更'),
          value: _timeEffect,
          onChanged: (v) {
            setState(() => _timeEffect = v);
            AppSettings.setTimeEffect(v);
          },
        ),
        SwitchListTile(
          title: const Text('UI表示'),
          subtitle: const Text('走行中のUI非表示'),
          value: _showUi,
          onChanged: (v) {
            setState(() => _showUi = v);
            AppSettings.setShowUi(v);
          },
        ),
      ],
    ));
  }

  String _themeLabel(String v) {
    switch (v) {
      case 'standard': return '標準';
      case 'dark': return 'ダーク';
      case 'satellite': return '衛星';
      default: return v;
    }
  }

  // ========== Camera ==========
  Widget _buildCamera() {
    return _card(ExpansionTile(
      leading: const Icon(Icons.videocam),
      title: const Text('Camera'),
      children: [
        ListTile(
          title: const Text('Bike View 傾き'),
          subtitle: Slider(
            value: _cameraTilt,
            min: 0,
            max: 90,
            divisions: 9,
            label: '${_cameraTilt.round()}°',
            onChanged: (v) {
              setState(() => _cameraTilt = v);
              AppSettings.setCameraTilt(v);
            },
          ),
        ),
        ListTile(
          title: const Text('ズームレベル'),
          subtitle: Slider(
            value: _cameraZoom,
            min: 12,
            max: 20,
            divisions: 8,
            label: _cameraZoom.toStringAsFixed(0),
            onChanged: (v) {
              setState(() => _cameraZoom = v);
              AppSettings.setCameraZoom(v);
            },
          ),
        ),
        SwitchListTile(
          title: const Text('自動フォロー'),
          subtitle: const Text('走行中に自動で追従'),
          value: _cameraFollow,
          onChanged: (v) {
            setState(() => _cameraFollow = v);
            AppSettings.setCameraFollow(v);
          },
        ),
        ListTile(
          title: const Text('スムーズネス'),
          subtitle: Slider(
            value: _cameraSmoothness,
            min: 0,
            max: 1,
            divisions: 10,
            label: '${(_cameraSmoothness * 100).round()}%',
            onChanged: (v) {
              setState(() => _cameraSmoothness = v);
              AppSettings.setCameraSmoothness(v);
            },
          ),
        ),
      ],
    ));
  }

  String? _customMarkerPath;

  // ========== Marker ==========
  Widget _buildMarker() {
    return _card(ExpansionTile(
      leading: const Icon(Icons.location_on),
      title: const Text('Marker'),
      children: [
        ListTile(
          title: const Text('マーカーアイコン'),
          subtitle: Text(_customMarkerPath != null ? 'カスタム画像' : '柴犬（デフォルト）'),
          leading: _customMarkerPath != null
              ? ClipOval(
                  child: Image.file(
                    File(_customMarkerPath!),
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                )
              : const Icon(Icons.pets, size: 40),
          trailing: const Icon(Icons.edit, size: 18),
          onTap: _showMarkerIconOptions,
        ),
        ListTile(
          title: const Text('ルート色'),
          trailing: _colorCircle(Color(_routeColor)),
          onTap: () => _pickColor('route_color', _routeColor, (c) {
            setState(() => _routeColor = c);
            AppSettings.setRouteColor(c);
          }),
        ),
        ListTile(
          title: const Text('ルート線太さ'),
          subtitle: Slider(
            value: _routeWidth,
            min: 2,
            max: 12,
            divisions: 10,
            label: _routeWidth.toStringAsFixed(0),
            onChanged: (v) {
              setState(() => _routeWidth = v);
              AppSettings.setRouteWidth(v);
            },
          ),
        ),
        ListTile(
          title: const Text('マーカーサイズ'),
          subtitle: Slider(
            value: _markerSize,
            min: 0.5,
            max: 2.0,
            divisions: 6,
            label: '${(_markerSize * 100).round()}%',
            onChanged: (v) {
              setState(() => _markerSize = v);
              AppSettings.setMarkerSize(v);
            },
          ),
        ),
      ],
    ));
  }

  void _showMarkerIconOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('ギャラリーから選択'),
              onTap: () async {
                Navigator.pop(ctx);
                final file = await CustomMarkerService.pickImage();
                if (file != null) {
                  setState(() => _customMarkerPath = file.path);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('マーカーを変更しました。アプリ再起動で反映されます')),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('カメラで撮影'),
              onTap: () async {
                Navigator.pop(ctx);
                final file = await CustomMarkerService.takePhoto();
                if (file != null) {
                  setState(() => _customMarkerPath = file.path);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('マーカーを変更しました。アプリ再起動で反映されます')),
                    );
                  }
                }
              },
            ),
            if (_customMarkerPath != null)
              ListTile(
                leading: const Icon(Icons.restore, color: Colors.orange),
                title: const Text('デフォルト（柴犬）に戻す'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await CustomMarkerService.clearCustomMarker();
                  setState(() => _customMarkerPath = null);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('デフォルトマーカーに戻しました。アプリ再起動で反映されます')),
                    );
                  }
                },
              ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('キャンセル'),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  Widget _colorCircle(Color c) => Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: c,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey),
        ),
      );

  void _pickColor(String key, int current, Function(int) onPick) {
    final colors = [
      0xFFB388FF, 0xFFFF5722, 0xFF4CAF50, 0xFF2196F3,
      0xFFFF9800, 0xFFE91E63, 0xFF9C27B0, 0xFF00BCD4,
      0xFFFFEB3B, 0xFF795548,
    ];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('色を選択'),
        content: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: colors.map((c) {
            return GestureDetector(
              onTap: () {
                onPick(c);
                Navigator.pop(ctx);
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Color(c),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: c == current ? Colors.black : Colors.grey,
                    width: c == current ? 3 : 1,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ========== Bicycle ==========
  Widget _buildBicycle() {
    final totalDistance = _reports.fold<double>(0, (s, r) => s + r.distanceKm);
    final totalMinutes = _reports.fold<int>(0, (s, r) => s + r.durationMinutes);
    final avgSpeed = _reports.isEmpty
        ? 0.0
        : _reports.fold<double>(0, (s, r) => s + r.avgSpeedKmh) / _reports.length;
    final maxSpeed = _reports.isEmpty
        ? 0.0
        : _reports.fold<double>(0, (s, r) => s > r.maxSpeedKmh ? s : r.maxSpeedKmh);
    final totalHours = totalMinutes / 60.0;
    final avgMet = avgSpeed < 16 ? 6.8 : avgSpeed < 20 ? 8.0 : 10.0;
    final totalCalories = (avgMet * _weight * totalHours).round();

    return _card(ExpansionTile(
      leading: const Icon(Icons.pedal_bike),
      title: const Text('Bicycle'),
      children: [
        ListTile(
          title: const Text('体重'),
          subtitle: Text('${_weight.toStringAsFixed(0)} kg'),
          trailing: const Icon(Icons.edit, size: 16),
          onTap: () => _editWeight(),
        ),
        ListTile(
          title: const Text('走行記録'),
          subtitle: Text('${_reports.length}件'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _showRideHistory(),
        ),
        ListTile(
          title: const Text('総走行距離'),
          subtitle: Text('${totalDistance.toStringAsFixed(1)} km'),
        ),
        ListTile(
          title: const Text('総走行時間'),
          subtitle: Text('${totalMinutes ~/ 60}時間${totalMinutes % 60}分'),
        ),
        ListTile(
          title: const Text('消費カロリー'),
          subtitle: Text('$totalCalories kcal'),
        ),
        ListTile(
          title: const Text('平均速度'),
          subtitle: Text('${avgSpeed.toStringAsFixed(1)} km/h'),
        ),
        ListTile(
          title: const Text('最高速度'),
          subtitle: Text('${maxSpeed.toStringAsFixed(1)} km/h'),
        ),
      ],
    ));
  }

  void _editWeight() {
    final controller = TextEditingController(text: _weight.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('体重を入力'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            suffixText: 'kg',
            hintText: '60',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              final v = double.tryParse(controller.text);
              if (v != null && v > 0 && v < 300) {
                await AppSettings.setWeight(v);
                setState(() => _weight = v);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showRideHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _RideHistoryPage(reports: _reports),
      ),
    );
  }

  // ========== Insurance ==========
  Widget _buildInsurance() {
    return _card(ExpansionTile(
      leading: const Icon(Icons.shield),
      title: const Text('Insurance'),
      children: [
        ListTile(
          title: const Text('保険情報'),
          subtitle: Text(_insuranceInfo.isEmpty ? '未登録' : _insuranceInfo),
          trailing: const Icon(Icons.edit, size: 18),
          onTap: () => _editText('保険情報', _insuranceInfo, (v) {
            setState(() => _insuranceInfo = v);
            AppSettings.setInsuranceInfo(v);
          }),
        ),
        ListTile(
          title: const Text('緊急連絡先'),
          subtitle: Text(_emergencyContact.isEmpty ? '未登録' : _emergencyContact),
          trailing: const Icon(Icons.edit, size: 18),
          onTap: () => _editText('緊急連絡先', _emergencyContact, (v) {
            setState(() => _emergencyContact = v);
            AppSettings.setEmergencyContact(v);
            final prefs = SharedPreferences.getInstance();
            prefs.then((p) => p.setString('emergency_contact', v));
          }),
        ),
        ListTile(
          title: const Text('事故メモ'),
          subtitle: Text(_accidentMemo.isEmpty ? 'なし' : _accidentMemo),
          trailing: const Icon(Icons.edit, size: 18),
          onTap: () => _editText('事故メモ', _accidentMemo, (v) {
            setState(() => _accidentMemo = v);
            AppSettings.setAccidentMemo(v);
          }, multiline: true),
        ),
      ],
    ));
  }

  void _editText(String title, String current, Function(String) onSave,
      {bool multiline = false}) {
    final controller = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: multiline ? 5 : 1,
          keyboardType:
              multiline ? TextInputType.multiline : TextInputType.text,
          decoration: InputDecoration(
            hintText: '$titleを入力',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              onSave(controller.text);
              Navigator.pop(ctx);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  // ========== SOS ==========
  Widget _buildSos() {
    return _card(ExpansionTile(
      leading: const Icon(Icons.warning, color: Colors.red),
      title: const Text('SOS'),
      children: [
        ListTile(
          leading: const Icon(Icons.local_hospital, color: Colors.red),
          title: const Text('119 救急車'),
          onTap: () => _confirmCall('119'),
        ),
        ListTile(
          leading: const Icon(Icons.local_police, color: Colors.blue),
          title: const Text('110 警察'),
          onTap: () => _confirmCall('110'),
        ),
        ListTile(
          leading: const Icon(Icons.share_location, color: Colors.green),
          title: const Text('現在地共有'),
          subtitle: const Text('緊急連絡先に位置情報を送信'),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('地図画面のSOSボタンから送信できます')),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.history, color: Colors.grey),
          title: const Text('SOS通報履歴'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _showSosHistory(),
        ),
        ListTile(
          leading: const Icon(Icons.report_problem, color: Colors.orange),
          title: const Text('危険ポイント履歴'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => showHazardHistoryPage(context),
        ),
      ],
    ));
  }

  void _showSosHistory() async {
    final reports = await SosStore.loadAll();
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _SosHistoryPage(reports: reports),
      ),
    );
  }

  Future<void> _confirmCall(String number) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$number に発信しますか？'),
        content: const Text('誤操作ではありませんか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('発信する', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // ========== Demo ==========
  Widget _buildDemo() {
    return _card(ExpansionTile(
      leading: const Icon(Icons.play_circle),
      title: const Text('Demo'),
      children: [
        ListTile(
          title: const Text('ナビデモ'),
          subtitle: const Text('サンプルルートでナビ体験'),
          onTap: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('デモモード: 準備中')),
            );
          },
        ),
        ListTile(
          title: const Text('カメラデモ'),
          subtitle: const Text('カメラアングル確認'),
          onTap: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('カメラデモ: 準備中')),
            );
          },
        ),
      ],
    ));
  }
}

// ========== 走行履歴ページ ==========
class _RideHistoryPage extends StatelessWidget {
  final List<RideReport> reports;
  const _RideHistoryPage({required this.reports});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('走行記録')),
      body: reports.isEmpty
          ? const Center(child: Text('走行記録がありません'))
          : ListView.builder(
              itemCount: reports.length,
              itemBuilder: (_, i) {
                final r = reports[i];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _gradeColor(r.grade),
                      child: Text(
                        r.grade,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      '${r.startTime.month}/${r.startTime.day} '
                      '${r.startTime.hour}:${r.startTime.minute.toString().padLeft(2, '0')}',
                    ),
                    subtitle: Text(
                      '${r.distanceKm.toStringAsFixed(1)}km  '
                      '${r.durationMinutes}分  '
                      '平均${r.avgSpeedKmh.toStringAsFixed(1)}km/h',
                    ),
                    trailing: Text(
                      '${r.safetyScore}点',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _gradeColor(r.grade),
                      ),
                    ),
                    onTap: () => _showDetail(context, r),
                  ),
                );
              },
            ),
    );
  }

  Color _gradeColor(String g) {
    switch (g) {
      case 'S': return Colors.amber;
      case 'A': return Colors.green;
      case 'B': return Colors.blue;
      case 'C': return Colors.orange;
      default: return Colors.red;
    }
  }

  void _showDetail(BuildContext context, RideReport r) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${r.startTime.month}/${r.startTime.day} 走行詳細'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row('安全スコア', '${r.safetyScore}点 (${r.grade})'),
            _row('距離', '${r.distanceKm.toStringAsFixed(1)} km'),
            _row('時間', '${r.durationMinutes}分'),
            _row('平均速度', '${r.avgSpeedKmh.toStringAsFixed(1)} km/h'),
            _row('最高速度', '${r.maxSpeedKmh.toStringAsFixed(1)} km/h'),
            _row('急ブレーキ', '${r.suddenBrakeCount}回'),
            _row('ハザード', '${r.hazardCount}件'),
            _row('夜間走行', r.nightRide ? 'はい' : 'いいえ'),
            if (r.weather != null) _row('天気', r.weather!),
            _row('カロリー', '${(r.distanceKm * 30).round()} kcal'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      );
}

class _SosHistoryPage extends StatelessWidget {
  final List<SosReport> reports;
  const _SosHistoryPage({required this.reports});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('通報履歴')),
      body: reports.isEmpty
          ? const Center(child: Text('通報履歴がありません'))
          : ListView.builder(
              itemCount: reports.length,
              itemBuilder: (_, i) {
                final r = reports[i];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _typeColor(r.type),
                      child: Icon(_typeIcon(r.type),
                          color: Colors.white, size: 20),
                    ),
                    title: Text(r.typeLabel),
                    subtitle: Text(
                      '${r.timestamp.month}/${r.timestamp.day} '
                      '${r.timestamp.hour}:${r.timestamp.minute.toString().padLeft(2, '0')}'
                      '${r.memo != null && r.memo!.isNotEmpty ? '\n${r.memo}' : ''}',
                    ),
                    trailing: r.lat != null
                        ? const Icon(Icons.location_on,
                            color: Colors.green, size: 18)
                        : null,
                  ),
                );
              },
            ),
    );
  }

  static Color _typeColor(SosType t) {
    switch (t) {
      case SosType.emergency119: return Colors.red;
      case SosType.police110: return Colors.blue;
      case SosType.chikan: return Colors.orange;
      case SosType.fight: return Colors.deepPurple;
      case SosType.accident: return Colors.red[800]!;
      case SosType.suspicious: return Colors.grey[700]!;
      case SosType.other: return Colors.grey;
    }
  }

  static IconData _typeIcon(SosType t) {
    switch (t) {
      case SosType.emergency119: return Icons.local_hospital;
      case SosType.police110: return Icons.local_police;
      case SosType.chikan: return Icons.flash_on;
      case SosType.fight: return Icons.sports_mma;
      case SosType.accident: return Icons.car_crash;
      case SosType.suspicious: return Icons.visibility;
      case SosType.other: return Icons.warning;
    }
  }
}
