import 'package:flutter/material.dart';

void showSosDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('SOS'),
        content: const Text('緊急連絡を送信しますか？'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('送信'),
          ),
        ],
      );
    },
  );
}
