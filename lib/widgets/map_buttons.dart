import 'package:flutter/material.dart';

class MapButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Color color;

  const MapButton({
    super.key,
    required this.child,
    required this.onTap,
    this.onLongPress,
    this.color = Colors.white,
  });

  @override
  State<MapButton> createState() => _MapButtonState();
}

class _MapButtonState extends State<MapButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _pressed = false);
      },
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color:
                _pressed ? widget.color.withValues(alpha: 0.8) : widget.color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                blurRadius: _pressed ? 2 : 6,
                color: Colors.black26,
              ),
            ],
          ),
          child: Center(
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
