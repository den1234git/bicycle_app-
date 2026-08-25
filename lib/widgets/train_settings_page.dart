import 'package:flutter/material.dart';

class TrainSettingsPage extends StatefulWidget {
  const TrainSettingsPage({super.key});

  @override
  State<TrainSettingsPage> createState() => _TrainSettingsPageState();
}

class _TrainSettingsPageState extends State<TrainSettingsPage> {
  bool popupEnabled = true;
  bool soundEnabled = true;
  bool vibrationEnabled = true;

  Widget buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      child: SwitchListTile(
        secondary: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('乗過ごし防止'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 10),
          buildSwitchTile(
            title: 'ポップアップ通知',
            subtitle: '降車前に画面表示',
            value: popupEnabled,
            icon: Icons.notification_important,
            onChanged: (v) {
              setState(() {
                popupEnabled = v;
              });
            },
          ),
          buildSwitchTile(
            title: '通知音',
            subtitle: '通知時に音を鳴らす',
            value: soundEnabled,
            icon: Icons.volume_up,
            onChanged: (v) {
              setState(() {
                soundEnabled = v;
              });
            },
          ),
          buildSwitchTile(
            title: 'バイブ',
            subtitle: '通知時に振動',
            value: vibrationEnabled,
            icon: Icons.vibration,
            onChanged: (v) {
              setState(() {
                vibrationEnabled = v;
              });
            },
          ),
        ],
      ),
    );
  }
}
