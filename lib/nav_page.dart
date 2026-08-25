import 'package:flutter/material.dart';

class NavPage extends StatefulWidget {
  const NavPage({super.key});

  @override
  State<NavPage> createState() => _NavPageState();
}

class _NavPageState extends State<NavPage> {
  final TextEditingController searchController = TextEditingController();

  List<String> favorites = [
    "自宅",
    "職場",
    "東京駅",
  ];

  List<String> history = [
    "新宿駅",
    "渋谷駅",
    "上野駅",
  ];

  List<String> result = [];

  void searchPlace() {
    String word = searchController.text.trim();

    if (word.isEmpty) return;

    setState(() {
      result = [
        "$word（候補1）",
        "$word（候補2）",
        "$word（候補3）",
      ];

      history.insert(0, word);

      if (history.length > 6) {
        history.removeLast();
      }
    });
  }

  Widget tile(String text) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        title: Text(text),
        subtitle: const Text("約12分 / 2.1km"),
        trailing: const Icon(Icons.directions_bike),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("$text にナビ開始")),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("検索ナビ"),
        centerTitle: true,
      ),
      body: Center(
        child: SizedBox(
          width: 430,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: "目的地を入力",
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      onPressed: searchPlace,
                      icon: const Icon(Icons.send),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onSubmitted: (_) => searchPlace(),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView(
                    children: [
                      const Text(
                        "★ お気に入り",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...favorites.map((e) => tile(e)),
                      const SizedBox(height: 18),
                      const Text(
                        "🕒 履歴",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...history.map((e) => tile(e)),
                      const SizedBox(height: 18),
                      if (result.isNotEmpty) ...[
                        const Text(
                          "🔍 検索結果",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...result.map((e) => tile(e)),
                      ],
                    ],
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
