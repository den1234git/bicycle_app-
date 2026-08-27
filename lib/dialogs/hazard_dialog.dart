import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../models/hazard_report.dart';
import '../services/hazard_store.dart';

Future<HazardReport?> showHazardReportDialog(
  BuildContext context, {
  required LatLng position,
  HazardType? preselected,
}) async {
  return showDialog<HazardReport>(
    context: context,
    builder: (ctx) => _HazardReportDialog(
      position: position,
      preselected: preselected,
    ),
  );
}

void showHazardHistoryPage(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const _HazardHistoryPage()),
  );
}

class _HazardReportDialog extends StatefulWidget {
  final LatLng position;
  final HazardType? preselected;

  const _HazardReportDialog({required this.position, this.preselected});

  @override
  State<_HazardReportDialog> createState() => _HazardReportDialogState();
}

class _HazardReportDialogState extends State<_HazardReportDialog> {
  late HazardType _selected;
  final _noteController = TextEditingController();
  String? _photoPath;
  bool _showDisaster = false;

  static const _normalTypes = [
    HazardType.suddenBrake,
    HazardType.nearMiss,
    HazardType.dangerousRoad,
  ];

  static const _disasterTypes = [
    HazardType.flood,
    HazardType.landslide,
    HazardType.roadClosed,
    HazardType.fallenTree,
    HazardType.construction,
    HazardType.icy,
    HazardType.poorVisibility,
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.preselected ?? HazardType.dangerousRoad;
    if (_disasterTypes.contains(_selected)) _showDisaster = true;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (picked != null) setState(() => _photoPath = picked.path);
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (picked != null) setState(() => _photoPath = picked.path);
  }

  @override
  Widget build(BuildContext context) {
    final types = _showDisaster ? _disasterTypes : _normalTypes;

    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: Row(
        children: [
          Icon(
            _showDisaster ? Icons.flood : Icons.report_problem,
            color: _showDisaster ? Colors.red : Colors.orange,
            size: 28,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _showDisaster ? '災害・通行障害を報告' : '危険箇所を報告',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Category toggle
            Row(
              children: [
                Expanded(
                  child: _TabButton(
                    label: '危険箇所',
                    active: !_showDisaster,
                    onTap: () => setState(() {
                      _showDisaster = false;
                      _selected = HazardType.dangerousRoad;
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TabButton(
                    label: '災害・障害',
                    active: _showDisaster,
                    color: Colors.red,
                    onTap: () => setState(() {
                      _showDisaster = true;
                      _selected = HazardType.flood;
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Type selection
            ...types.map((t) => RadioListTile<HazardType>(
                  title: Text(
                    '${HazardReport.emojiFor(t)} ${HazardReport.labelFor(t)}',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  value: t,
                  groupValue: _selected,
                  activeColor: _showDisaster ? Colors.red : Colors.orange,
                  dense: true,
                  onChanged: (v) => setState(() => _selected = v!),
                )),

            const SizedBox(height: 8),

            // Photo
            if (_photoPath != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(_photoPath!),
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => setState(() => _photoPath = null),
                child: const Text('写真を削除',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
              ),
            ] else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                      ),
                      icon: const Icon(Icons.camera_alt, size: 18),
                      label: const Text('撮影', style: TextStyle(fontSize: 12)),
                      onPressed: _takePhoto,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                      ),
                      icon: const Icon(Icons.photo_library, size: 18),
                      label: const Text('選択', style: TextStyle(fontSize: 12)),
                      onPressed: _pickPhoto,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 8),

            // Note
            TextField(
              controller: _noteController,
              maxLines: 2,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: '状況メモ（任意）',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
              ),
            ),

            // Location info
            const SizedBox(height: 8),
            Text(
              '📍 ${widget.position.latitude.toStringAsFixed(5)}, ${widget.position.longitude.toStringAsFixed(5)}',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: _showDisaster ? Colors.red : Colors.orange,
          ),
          icon: const Icon(Icons.send, size: 18, color: Colors.white),
          label: const Text('報告', style: TextStyle(color: Colors.white)),
          onPressed: () async {
            final report = await HazardStore.addReport(
              type: _selected,
              position: widget.position,
              note: _noteController.text.isEmpty ? null : _noteController.text,
              photoPath: _photoPath,
            );
            if (context.mounted) Navigator.pop(context, report);
          },
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.active,
    this.color = Colors.orange,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? color.withAlpha(50) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? color : Colors.white24,
            width: active ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: active ? color : Colors.white54,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

// ========== Hazard History Page ==========

class _HazardHistoryPage extends StatefulWidget {
  const _HazardHistoryPage();

  @override
  State<_HazardHistoryPage> createState() => _HazardHistoryPageState();
}

class _HazardHistoryPageState extends State<_HazardHistoryPage> {
  List<HazardReport> _reports = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final reports = await HazardStore.load();
    reports.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (mounted) setState(() => _reports = reports);
  }

  @override
  Widget build(BuildContext context) {
    final active = _reports.where((r) => !r.isExpired).toList();
    final expired = _reports.where((r) => r.isExpired).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('危険ポイント履歴'),
        actions: [
          if (_reports.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.cleaning_services),
              tooltip: '期限切れを削除',
              onPressed: () async {
                await HazardStore.removeExpired();
                _load();
              },
            ),
          if (_reports.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('全履歴を削除しますか？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('キャンセル'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('削除',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await HazardStore.clear();
                  _load();
                }
              },
            ),
        ],
      ),
      body: _reports.isEmpty
          ? const Center(child: Text('報告履歴がありません'))
          : ListView(
              children: [
                if (active.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text('有効な報告',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green)),
                  ),
                  ...active.map((r) => _buildTile(r, false)),
                ],
                if (expired.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text('期限切れ',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey)),
                  ),
                  ...expired.map((r) => _buildTile(r, true)),
                ],
              ],
            ),
    );
  }

  Widget _buildTile(HazardReport r, bool expired) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      color: expired ? Colors.grey[200] : null,
      child: ListTile(
        leading: Text(
          HazardReport.emojiFor(r.type),
          style: TextStyle(
            fontSize: 24,
            color: expired ? Colors.grey : null,
          ),
        ),
        title: Text(
          HazardReport.labelFor(r.type),
          style: TextStyle(
            color: expired ? Colors.grey : null,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${r.timestamp.month}/${r.timestamp.day} '
          '${r.timestamp.hour}:${r.timestamp.minute.toString().padLeft(2, '0')}'
          '${r.note != null ? '\n${r.note}' : ''}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (r.photoPath != null)
              const Icon(Icons.photo, color: Colors.blue, size: 18),
            const SizedBox(width: 4),
            const Icon(Icons.location_on, color: Colors.green, size: 18),
          ],
        ),
        onTap: () => _showDetail(r),
      ),
    );
  }

  void _showDetail(HazardReport r) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          '${HazardReport.emojiFor(r.type)} ${HazardReport.labelFor(r.type)}',
          style: const TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${r.timestamp.year}/${r.timestamp.month}/${r.timestamp.day} '
                '${r.timestamp.hour}:${r.timestamp.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(color: Colors.white54),
              ),
              const SizedBox(height: 4),
              Text(
                '📍 ${r.latitude.toStringAsFixed(5)}, ${r.longitude.toStringAsFixed(5)}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              if (r.isExpired)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text('⏰ 期限切れ',
                      style: TextStyle(color: Colors.orange, fontSize: 12)),
                ),
              if (r.note != null) ...[
                const SizedBox(height: 8),
                Text(r.note!,
                    style: const TextStyle(color: Colors.white)),
              ],
              if (r.photoPath != null) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(r.photoPath!),
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Text(
                      '写真を読み込めません',
                      style: TextStyle(color: Colors.white38),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await HazardStore.delete(r.id);
              if (ctx.mounted) Navigator.pop(ctx);
              _load();
            },
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('閉じる', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }
}
