import 'package:flutter/material.dart';

class MorePage extends StatelessWidget {
  const MorePage({
    super.key,
    required this.homeRegistered,
    required this.companyRegistered,
    required this.onSelectHome,
    required this.onSelectCompany,
  });

  final bool homeRegistered;
  final bool companyRegistered;

  final VoidCallback onSelectHome;
  final VoidCallback onSelectCompany;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MORE'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 10),
          ExpansionTile(
            leading: const Icon(Icons.home),
            title: const Text('MY設定'),
            children: [
              ListTile(
                leading: Icon(
                  homeRegistered ? Icons.check_circle : Icons.add_location,
                  color: homeRegistered ? Colors.green : null,
                ),
                title: const Text('自宅'),
                subtitle: Text(
                  homeRegistered ? '登録済み' : '未登録',
                ),
                onTap: () {
                  onSelectHome();
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(
                  companyRegistered ? Icons.check_circle : Icons.add_location,
                  color: companyRegistered ? Colors.green : null,
                ),
                title: const Text('会社'),
                subtitle: Text(
                  homeRegistered ? '登録済み' : '未登録',
                ),
                onTap: () {
                  onSelectCompany();
                  Navigator.pop(context);
                },
              ),
              const ListTile(title: Text('学校')),
              const ListTile(title: Text('駐輪位置')),
            ],
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ExpansionTile(
              leading: const Icon(Icons.settings),
              title: const Text('設定'),
              children: [
                ListTile(title: const Text('ナビ音声'), onTap: () {}),
                ListTile(title: const Text('音量'), onTap: () {}),
                ListTile(title: const Text('GPS'), onTap: () {}),
                ListTile(title: const Text('通知'), onTap: () {}),
                ListTile(title: const Text('バッテリー'), onTap: () {}),
                ListTile(title: const Text('自動再探索'), onTap: () {}),
                ListTile(title: const Text('Routing Engine'), onTap: () {}),
              ],
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ExpansionTile(
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
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ExpansionTile(
              leading: const Icon(Icons.map),
              title: const Text('Display'),
              children: [
                ListTile(title: const Text('FULLVIEW'), onTap: () {}),
                ListTile(title: const Text('地図テーマ'), onTap: () {}),
                ListTile(title: const Text('地図スタイル'), onTap: () {}),
                ListTile(title: const Text('天気演出'), onTap: () {}),
                ListTile(title: const Text('時間帯演出'), onTap: () {}),
                ListTile(title: const Text('UI表示'), onTap: () {}),
              ],
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ExpansionTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Camera'),
              children: [
                ListTile(title: const Text('Bike View'), onTap: () {}),
                ListTile(title: const Text('Bird View'), onTap: () {}),
                ListTile(title: const Text('Follow'), onTap: () {}),
                ListTile(title: const Text('Smoothness'), onTap: () {}),
              ],
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ExpansionTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Marker'),
              children: [
                ListTile(title: const Text('自転車マーカー'), onTap: () {}),
                ListTile(title: const Text('人マーカー'), onTap: () {}),
                ListTile(title: const Text('サイズ'), onTap: () {}),
                ListTile(title: const Text('色'), onTap: () {}),
                ListTile(title: const Text('ルート色'), onTap: () {}),
                ListTile(title: const Text('線太さ'), onTap: () {}),
              ],
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ExpansionTile(
              leading: const Icon(Icons.pedal_bike),
              title: const Text('Bicycle'),
              children: [
                ListTile(title: const Text('走行記録'), onTap: () {}),
                ListTile(title: const Text('カロリー'), onTap: () {}),
                ListTile(title: const Text('ステップ'), onTap: () {}),
                ListTile(title: const Text('駐輪履歴'), onTap: () {}),
                ListTile(title: const Text('平均速度'), onTap: () {}),
                ListTile(title: const Text('最高速度'), onTap: () {}),
              ],
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ExpansionTile(
              leading: const Icon(Icons.shield),
              title: const Text('Insurance'),
              children: [
                ListTile(title: const Text('保険情報'), onTap: () {}),
                ListTile(title: const Text('緊急連絡'), onTap: () {}),
                ListTile(title: const Text('事故メモ'), onTap: () {}),
              ],
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ExpansionTile(
              leading: const Icon(Icons.warning),
              title: const Text('SOS'),
              children: [
                ListTile(title: const Text('SOS送信'), onTap: () {}),
                ListTile(title: const Text('現在地共有'), onTap: () {}),
                ListTile(title: const Text('緊急通報'), onTap: () {}),
                Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ExpansionTile(
                    leading: const Icon(Icons.play_circle),
                    title: const Text('Demo'),
                    children: [
                      ListTile(title: const Text('ナビデモ'), onTap: () {}),
                      ListTile(title: const Text('カメラデモ'), onTap: () {}),
                      ListTile(title: const Text('演出確認'), onTap: () {}),
                      ListTile(title: const Text('UI確認'), onTap: () {}),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
