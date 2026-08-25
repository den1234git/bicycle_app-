import 'package:flutter/material.dart';
import 'myspot_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'api_keys.dart';
import 'widgets/bottom_bar.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  TextEditingController searchController = TextEditingController();
  LatLng currentPos = const LatLng(35.681236, 139.767125);
  Set<Polyline> polylines = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      // 👇 ここが重要（childじゃなくbody）
      body: SafeArea(
        child: Column(
          children: [
            // 上部バー
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () async {
                      final query = searchController.text;

                      final url =
                          "https://maps.googleapis.com/maps/api/place/textsearch/json"
                          "?query=$query"
                          "&key=${ApiKeys.web}";

                      final res = await http.get(Uri.parse(url));
                      final data = jsonDecode(res.body);

                      if (data['results'] == null || data['results'].isEmpty) {
                        return;
                      }

                      final loc = data['results'][0]['geometry']['location'];

                      final goal = LatLng(
                        (loc['lat'] as num).toDouble(),
                        (loc['lng'] as num).toDouble(),
                      );

                      final dirUrl =
                          "https://maps.googleapis.com/maps/api/directions/json"
                          "?origin=${currentPos.latitude},${currentPos.longitude}"
                          "&destination=${goal.latitude},${goal.longitude}"
                          "&key=${ApiKeys.web}";

                      final dirRes = await http.get(Uri.parse(dirUrl));
                      final dirData = jsonDecode(dirRes.body);

                      print(dirData['routes']);

                      setState(() {
                        polylines = {
                          Polyline(
                            polylineId: const PolylineId("route"),
                            points: [currentPos, goal],
                            width: 6,
                            color: Colors.blue,
                          ),
                        };
                      });
                    },
                    icon: const Icon(Icons.search),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "My Page",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // 検索欄（追加）
                    TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        hintText: "場所を検索",
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // MYSPOTボタン
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.place),
                        label: const Text(
                          "MYSPOT（地点登録）",
                          style: TextStyle(fontSize: 18),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MySpotPage(),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 走行ログ
                    cardBox(
                      title: "走行ログ",
                      child: Column(
                        children: const [
                          LogRow("距離", "12.4 km"),
                          LogRow("時間", "42 分"),
                          LogRow("危険回数", "2 回"),
                          LogRow("平均速度", "17 km/h"),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 危険履歴
                    cardBox(
                      title: "危険履歴",
                      child: Column(
                        children: const [
                          DangerRow("ヒヤリ", "4/30"),
                          DangerRow("車多い", "4/29"),
                          DangerRow("見通し悪い", "4/28"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget cardBox({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            blurRadius: 8,
            color: Colors.black12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class LogRow extends StatelessWidget {
  final String left;
  final String right;

  const LogRow(this.left, this.right, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(left),
          Text(
            right,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class DangerRow extends StatelessWidget {
  final String left;
  final String right;

  const DangerRow(this.left, this.right, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(left),
          Text(
            right,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
