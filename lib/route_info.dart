import 'package:flutter/material.dart';

class RouteInfo extends StatelessWidget {
  final String routeInfo;

  const RouteInfo({
    super.key,
    required this.routeInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 120,
      left: 10,
      child: Container(
        padding: const EdgeInsets.all(8),
        color: Colors.black54,
        child: Text(
          routeInfo,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}