import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'models/myspot.dart';
import 'services/storage_service.dart';

class MySpotPage extends StatefulWidget {
  const MySpotPage({super.key});

  @override
  State<MySpotPage> createState() => _MySpotPageState();
}

class _MySpotPageState extends State<MySpotPage> {
  List<MySpot> spots = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    spots = await StorageService.loadMySpots();
    setState(() {});
  }

  Future<void> saveSpot(String name) async {
    await Geolocator.requestPermission();

    Position pos = await Geolocator.getCurrentPosition();

    final spot = MySpot(
      name: name,
      lat: pos.latitude,
      lng: pos.longitude,
    );

    await StorageService.saveMySpot(spot);

    await loadData();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$name を保存しました")),
    );
  }

  Future<void> deleteSpot(String name) async {
    await StorageService.deleteMySpot(name);
    await loadData();
  }

  Color buttonColor(String name) {
    if (name == "自宅") return Colors.green;
    if (name == "会社") return Colors.blue;
    return Colors.grey.shade700;
  }

  Widget saveButton(String name) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor(name),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: () => saveSpot(name),
        child: Text(
          name,
          style: const TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget spotCard(MySpot spot) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            blurRadius: 6,
            color: Colors.black12,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.place, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  spot.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text("緯度 ${spot.lat.toStringAsFixed(5)}"),
                Text("経度 ${spot.lng.toStringAsFixed(5)}"),
              ],
            ),
          ),
          IconButton(
            onPressed: () => deleteSpot(spot.name),
            icon: const Icon(Icons.delete),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: SizedBox(
          width: 430,
          child: SafeArea(
            child: Column(
              children: [
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "MYSPOT（地点登録）",
                        style: TextStyle(
                          fontSize: 22,
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
                        saveButton("自宅"),
                        const SizedBox(height: 10),
                        saveButton("会社"),
                        const SizedBox(height: 10),
                        saveButton("地点1"),
                        const SizedBox(height: 10),
                        saveButton("地点2"),
                        const SizedBox(height: 10),
                        saveButton("地点3"),
                        const SizedBox(height: 10),
                        saveButton("地点4"),
                        const SizedBox(height: 10),
                        saveButton("地点5"),
                        const SizedBox(height: 24),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "登録済み地点",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...spots.map((e) => spotCard(e)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
