import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class CharacterViewerPage extends StatelessWidget {
  const CharacterViewerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('3D キャラクター'),
      ),
      body: const ModelViewer(
        src: 'assets/character_model.glb',
        alt: '3D キャラクター',
        autoRotate: true,
        cameraControls: true,
        backgroundColor: Color(0xFFF5F5F5),
      ),
    );
  }
}
