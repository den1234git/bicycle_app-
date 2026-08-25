import 'package:flutter/material.dart';

class MapButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color? color;

  const MapButton({
    super.key,
    required this.child,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color ?? Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: child,
      ),
    );
  }
}