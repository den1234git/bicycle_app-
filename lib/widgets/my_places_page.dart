import 'package:flutter/material.dart';

class MySettingsSheet extends StatelessWidget {
  const MySettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.2,
      maxChildSize: 0.6,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(16),
            ),
          ),
          child: ListView(
            controller: scrollController,
            children: [
              const ListTile(
                title: Text(
                  'MY設定',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(),

              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('自宅'),
                onTap: () {
                  Navigator.pop(context);
                  // 自宅処理
                },
              ),

              ListTile(
                leading: const Icon(Icons.business),
                title: const Text('会社'),
                onTap: () {
                  Navigator.pop(context);
                  // 会社処理
                },
              ),

              ListTile(
                leading: const Icon(Icons.school),
                title: const Text('学校'),
                onTap: () {
                  Navigator.pop(context);
                  // 学校処理
                },
              ),

              ListTile(
                leading: const Icon(Icons.pedal_bike),
                title: const Text('駐輪位置'),
                onTap: () {
                  Navigator.pop(context);
                  // 駐輪処理
                },
              ),
            ],
          ),
        );
      },
    );
  }
}