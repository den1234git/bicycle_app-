import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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

  @override
  void initState() {
    super.initState();
    _selected = widget.preselected ?? HazardType.dangerousRoad;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: const Row(
        children: [
          Icon(Icons.report_problem, color: Colors.orange, size: 28),
          SizedBox(width: 8),
          Text('危険箇所を報告',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...HazardType.values.map((t) => RadioListTile<HazardType>(
                title: Text(HazardReport.labelFor(t),
                    style: const TextStyle(color: Colors.white)),
                value: t,
                groupValue: _selected,
                activeColor: Colors.orange,
                onChanged: (v) => setState(() => _selected = v!),
              )),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'メモ（任意）',
              hintStyle: TextStyle(color: Colors.white38),
              enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24)),
              focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.orange)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          onPressed: () async {
            final report = await HazardStore.addReport(
              type: _selected,
              position: widget.position,
              note: _noteController.text.isEmpty ? null : _noteController.text,
            );
            if (context.mounted) Navigator.pop(context, report);
          },
          child: const Text('報告', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
