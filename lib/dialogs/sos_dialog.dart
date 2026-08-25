import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../state/map_state.dart';

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
            Text(
              isTrainMode ? '緊急通報' : 'SOS 緊急通報',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SosButton(
              icon: Icons.local_hospital,
              label: '119 救急車を呼ぶ',
              subtitle: '事故・ケガ',
              color: Colors.red,
              onPressed: () => _callNumber('119', context),
            ),
            const SizedBox(height: 10),
            _SosButton(
              icon: Icons.local_police,
              label: '110 警察を呼ぶ',
              subtitle: isTrainMode ? '痴漢・犯罪被害' : '事故・犯罪被害',
              color: Colors.blue,
              onPressed: () => _callNumber('110', context),
            ),
            if (isTrainMode) ...[
              const SizedBox(height: 10),
              _SosButton(
                icon: Icons.flash_on,
                label: '痴漢撃退画面',
                subtitle: '画面に大きく表示',
                color: Colors.orange,
                onPressed: () {
                  Navigator.pop(context);
                  _showChikanAlert(context);
                },
              ),
            ],
            const SizedBox(height: 10),
            _SosButton(
              icon: Icons.sms,
              label: '緊急連絡先にSMS',
              subtitle: '現在地を送信',
              color: Colors.green,
              onPressed: () => _sendEmergencySms(context, currentPos),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'キャンセル',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
          ],
        ),
      );
    },
  );
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
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                Text(subtitle,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _callNumber(String number, BuildContext context) async {
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

void _showChikanAlert(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const _ChikanAlertScreen(),
    ),
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
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                ),
              ),
              SizedBox(height: 40),
              Text(
                'タップで閉じる',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
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
