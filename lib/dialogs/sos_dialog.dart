import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../state/map_state.dart';
import '../models/sos_report.dart';
import '../services/sos_store.dart';

Future<void> showSosDialog(
  BuildContext context, {
  LatLng? currentPos,
  TransportMode? transportMode,
}) async {
  final isTrainMode = transportMode == TransportMode.train;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.red, size: 28),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'SOS 緊急通報',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.history, color: Colors.white54),
              onPressed: () {
                Navigator.pop(context);
                _showSosHistory(context);
              },
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SosButton(
                icon: Icons.local_hospital,
                label: '119 救急車を呼ぶ',
                subtitle: '事故・ケガ',
                color: Colors.red,
                onPressed: () => _callAndLog(
                  '119', context, currentPos, SosType.emergency119,
                ),
              ),
              const SizedBox(height: 8),
              _SosButton(
                icon: Icons.local_police,
                label: '110 警察を呼ぶ',
                subtitle: '事故・犯罪被害',
                color: Colors.blue,
                onPressed: () => _callAndLog(
                  '110', context, currentPos, SosType.police110,
                ),
              ),
              const SizedBox(height: 8),
              _SosButton(
                icon: Icons.flash_on,
                label: '痴漢撃退',
                subtitle: '画面に大きく表示 + 通報記録',
                color: Colors.orange,
                onPressed: () async {
                  await _logReport(SosType.chikan, currentPos);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  _showChikanAlert(context);
                },
              ),
              const SizedBox(height: 8),
              _SosButton(
                icon: Icons.sports_mma,
                label: '喧嘩・暴力通報',
                subtitle: '位置情報を記録',
                color: Colors.deepPurple,
                onPressed: () async {
                  await _logReport(SosType.fight, currentPos);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  _showReportConfirm(context, '喧嘩・暴力', currentPos);
                },
              ),
              const SizedBox(height: 8),
              _SosButton(
                icon: Icons.car_crash,
                label: '事故通報',
                subtitle: '現在地・状況を記録',
                color: Colors.red[800]!,
                onPressed: () async {
                  await _logReport(SosType.accident, currentPos);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  _showReportConfirm(context, '事故', currentPos);
                },
              ),
              const SizedBox(height: 8),
              _SosButton(
                icon: Icons.visibility,
                label: '不審者通報',
                subtitle: '位置情報を記録',
                color: Colors.grey[700]!,
                onPressed: () async {
                  await _logReport(SosType.suspicious, currentPos);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  _showReportConfirm(context, '不審者', currentPos);
                },
              ),
              const SizedBox(height: 8),
              _SosButton(
                icon: Icons.sms,
                label: '緊急連絡先にSMS',
                subtitle: '現在地を送信',
                color: Colors.green,
                onPressed: () => _sendEmergencySms(context, currentPos),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'キャンセル',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _logReport(SosType type, LatLng? pos) async {
  final report = SosReport(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    type: type,
    timestamp: DateTime.now(),
    lat: pos?.latitude,
    lng: pos?.longitude,
  );
  await SosStore.save(report);
}

Future<void> _callAndLog(
  String number, BuildContext context, LatLng? pos, SosType type,
) async {
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

  await _logReport(type, pos);

  final uri = Uri(scheme: 'tel', path: number);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  }
}

void _showReportConfirm(BuildContext context, String type, LatLng? pos) {
  final memoController = TextEditingController();

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.grey[900],
      title: Text(
        '$type 通報完了',
        style: const TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '現在地を記録しました',
            style: TextStyle(color: Colors.green[300]),
          ),
          if (pos != null)
            Text(
              '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: memoController,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'メモ（任意）',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.grey[800],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  icon: const Icon(Icons.local_police, color: Colors.white),
                  label: const Text('110に通報',
                      style: TextStyle(color: Colors.white)),
                  onPressed: () async {
                    if (memoController.text.isNotEmpty) {
                      final reports = await SosStore.loadAll();
                      if (reports.isNotEmpty) {
                        final latest = reports.first;
                        final updated = SosReport(
                          id: latest.id,
                          type: latest.type,
                          timestamp: latest.timestamp,
                          lat: latest.lat,
                          lng: latest.lng,
                          memo: memoController.text,
                        );
                        await SosStore.save(updated);
                      }
                    }
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    final uri = Uri(scheme: 'tel', path: '110');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            if (memoController.text.isNotEmpty) {
              final reports = await SosStore.loadAll();
              if (reports.isNotEmpty) {
                final latest = reports.first;
                final updated = SosReport(
                  id: latest.id,
                  type: latest.type,
                  timestamp: latest.timestamp,
                  lat: latest.lat,
                  lng: latest.lng,
                  memo: memoController.text,
                );
                await SosStore.save(updated);
              }
            }
            if (!ctx.mounted) return;
            Navigator.pop(ctx);
          },
          child: const Text('閉じる', style: TextStyle(color: Colors.white70)),
        ),
      ],
    ),
  );
}

void _showSosHistory(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const _SosHistoryPage()),
  );
}

class _SosHistoryPage extends StatefulWidget {
  const _SosHistoryPage();

  @override
  State<_SosHistoryPage> createState() => _SosHistoryPageState();
}

class _SosHistoryPageState extends State<_SosHistoryPage> {
  List<SosReport> _reports = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final reports = await SosStore.loadAll();
    if (mounted) setState(() => _reports = reports);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('通報履歴'),
        actions: [
          if (_reports.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('履歴を全削除しますか？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('キャンセル'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('削除',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await SosStore.clear();
                  _load();
                }
              },
            ),
        ],
      ),
      body: _reports.isEmpty
          ? const Center(child: Text('通報履歴がありません'))
          : ListView.builder(
              itemCount: _reports.length,
              itemBuilder: (_, i) {
                final r = _reports[i];
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

  Color _typeColor(SosType t) {
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

  IconData _typeIcon(SosType t) {
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

class _SosButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onPressed;

  const _SosButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                  Text(subtitle,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showChikanAlert(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const _ChikanAlertScreen()),
  );
}

class _ChikanAlertScreen extends StatelessWidget {
  const _ChikanAlertScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning, color: Colors.white, size: 100),
              SizedBox(height: 20),
              Text(
                '痴漢です',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 60,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                '助けてください',
                style: TextStyle(color: Colors.white, fontSize: 30),
              ),
              SizedBox(height: 40),
              Text(
                'タップで閉じる',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _sendEmergencySms(BuildContext context, LatLng? pos) async {
  final prefs = await SharedPreferences.getInstance();
  final emergencyNumber = prefs.getString('emergency_contact');

  if (emergencyNumber == null || emergencyNumber.isEmpty) {
    if (!context.mounted) return;
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('緊急連絡先を登録'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            hintText: '電話番号を入力',
            prefixIcon: Icon(Icons.phone),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('登録して送信'),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;
    await prefs.setString('emergency_contact', result);
    await _launchSms(result, pos);
  } else {
    await _launchSms(emergencyNumber, pos);
  }
}

Future<void> _launchSms(String number, LatLng? pos) async {
  String body = '【SOS】助けが必要です。';
  if (pos != null) {
    body +=
        '\n現在地: https://maps.google.com/?q=${pos.latitude},${pos.longitude}';
  }

  final uri = Uri(
    scheme: 'sms',
    path: number,
    queryParameters: {'body': body},
  );

  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  }
}
