import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomMarkerService {
  static const _keyPath = 'custom_marker_path';

  static Future<File?> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 256,
      maxHeight: 256,
    );
    if (picked == null) return null;

    final dir = await getApplicationDocumentsDirectory();
    final saved = File('${dir.path}/custom_marker.png');
    await File(picked.path).copy(saved.path);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPath, saved.path);

    return saved;
  }

  static Future<File?> takePhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 256,
      maxHeight: 256,
    );
    if (picked == null) return null;

    final dir = await getApplicationDocumentsDirectory();
    final saved = File('${dir.path}/custom_marker.png');
    await File(picked.path).copy(saved.path);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPath, saved.path);

    return saved;
  }

  static Future<String?> getSavedPath() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_keyPath);
    if (path == null) return null;
    if (!File(path).existsSync()) return null;
    return path;
  }

  static Future<void> clearCustomMarker() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_keyPath);
    if (path != null) {
      final file = File(path);
      if (file.existsSync()) await file.delete();
    }
    await prefs.remove(_keyPath);
  }

  static const _directionNames = [
    'back', 'back_right', 'right', 'front_right',
    'front', 'front_left', 'left', 'back_left',
  ];

  static Future<BitmapDescriptor> loadCharacterMarker({int size = 80}) async {
    final data = await rootBundle.load('assets/icons/character/back.png');
    final bytes = data.buffer.asUint8List();
    return _renderCircularMarker(bytes, size);
  }

  static Future<Map<String, BitmapDescriptor>> loadCharacterMarkers({int size = 80}) async {
    final markers = <String, BitmapDescriptor>{};
    for (final name in _directionNames) {
      final data = await rootBundle.load('assets/icons/character/$name.png');
      markers[name] = await _renderCircularMarker(data.buffer.asUint8List(), size);
    }
    return markers;
  }

  static String directionForHeading(double heading) {
    final normalized = ((heading % 360) + 360) % 360;
    final index = ((normalized + 22.5) / 45).floor() % 8;
    return _directionNames[index];
  }

  static Future<BitmapDescriptor> _renderCircularMarker(
      List<int> bytes, int size) async {
    final codec = await ui.instantiateImageCodec(
      Uint8List.fromList(bytes),
      targetWidth: size,
      targetHeight: size,
    );
    final frame = await codec.getNextFrame();
    final original = frame.image;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final s = size.toDouble();

    canvas.clipPath(Path()..addOval(Rect.fromLTWH(0, 0, s, s)));
    canvas.drawImageRect(
      original,
      Rect.fromLTWH(0, 0, original.width.toDouble(), original.height.toDouble()),
      Rect.fromLTWH(0, 0, s, s),
      Paint(),
    );

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(Offset(s / 2, s / 2), s / 2 - 1.5, borderPaint);

    final picture = recorder.endRecording();
    final image = await picture.toImage(size, size);
    final pngBytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(pngBytes!.buffer.asUint8List());
  }

  static Future<BitmapDescriptor?> loadCustomMarker({int size = 80}) async {
    final path = await getSavedPath();
    if (path == null) return null;

    try {
      final file = File(path);
      final bytes = await file.readAsBytes();
      return _renderCircularMarker(bytes, size);
    } catch (_) {
      return null;
    }
  }
}
