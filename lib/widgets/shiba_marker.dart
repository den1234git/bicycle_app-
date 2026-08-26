import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ShibaMarkerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.45;
    final r = size.width * 0.35;

    // 耳（左右）
    final earPaint = Paint()..color = const Color(0xFFD4883E);
    final earInnerPaint = Paint()..color = const Color(0xFFFFC97E);

    // 左耳
    final leftEar = Path()
      ..moveTo(cx - r * 0.7, cy - r * 0.3)
      ..lineTo(cx - r * 1.1, cy - r * 1.4)
      ..lineTo(cx - r * 0.1, cy - r * 0.8)
      ..close();
    canvas.drawPath(leftEar, earPaint);
    canvas.drawPath(
      Path()
        ..moveTo(cx - r * 0.6, cy - r * 0.4)
        ..lineTo(cx - r * 0.9, cy - r * 1.1)
        ..lineTo(cx - r * 0.2, cy - r * 0.7)
        ..close(),
      earInnerPaint,
    );

    // 右耳
    final rightEar = Path()
      ..moveTo(cx + r * 0.7, cy - r * 0.3)
      ..lineTo(cx + r * 1.1, cy - r * 1.4)
      ..lineTo(cx + r * 0.1, cy - r * 0.8)
      ..close();
    canvas.drawPath(rightEar, earPaint);
    canvas.drawPath(
      Path()
        ..moveTo(cx + r * 0.6, cy - r * 0.4)
        ..lineTo(cx + r * 0.9, cy - r * 1.1)
        ..lineTo(cx + r * 0.2, cy - r * 0.7)
        ..close(),
      earInnerPaint,
    );

    // 顔（メイン）
    final facePaint = Paint()..color = const Color(0xFFFAD5A5);
    canvas.drawCircle(Offset(cx, cy), r, facePaint);

    // 白い模様（口元）
    final whitePaint = Paint()..color = Colors.white;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + r * 0.3), width: r * 1.2, height: r * 0.9),
      whitePaint,
    );

    // 目（左右）
    final eyePaint = Paint()..color = const Color(0xFF2C1810);
    canvas.drawCircle(Offset(cx - r * 0.35, cy - r * 0.1), r * 0.12, eyePaint);
    canvas.drawCircle(Offset(cx + r * 0.35, cy - r * 0.1), r * 0.12, eyePaint);

    // 目のハイライト
    final highlightPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(cx - r * 0.32, cy - r * 0.14), r * 0.04, highlightPaint);
    canvas.drawCircle(Offset(cx + r * 0.38, cy - r * 0.14), r * 0.04, highlightPaint);

    // 鼻
    final nosePaint = Paint()..color = const Color(0xFF2C1810);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + r * 0.15), width: r * 0.22, height: r * 0.15),
      nosePaint,
    );

    // 口
    final mouthPaint = Paint()
      ..color = const Color(0xFF2C1810)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final mouthPath = Path()
      ..moveTo(cx, cy + r * 0.22)
      ..lineTo(cx, cy + r * 0.35);
    canvas.drawPath(mouthPath, mouthPaint);

    // 口角（笑顔）
    final smilePath = Path()
      ..moveTo(cx - r * 0.15, cy + r * 0.35)
      ..quadraticBezierTo(cx, cy + r * 0.5, cx + r * 0.15, cy + r * 0.35);
    canvas.drawPath(smilePath, mouthPaint);

    // ほっぺ（赤み）
    final cheekPaint = Paint()..color = const Color(0xFFFF9999).withOpacity(0.4);
    canvas.drawCircle(Offset(cx - r * 0.55, cy + r * 0.15), r * 0.12, cheekPaint);
    canvas.drawCircle(Offset(cx + r * 0.55, cy + r * 0.15), r * 0.12, cheekPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Future<BitmapDescriptor> createShibaMarker({int size = 80}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final painter = ShibaMarkerPainter();
  final s = Size(size.toDouble(), size.toDouble());
  painter.paint(canvas, s);
  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
}
