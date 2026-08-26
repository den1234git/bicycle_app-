import 'package:flutter/material.dart';

class TopBar extends StatelessWidget {
  final TextEditingController controller;
  final double speed;
  final bool isFullView;
  final double dangerValue;
  final double distanceKm;
  final String etaText;
  final String guideText;
  final String routeModeText;
  final VoidCallback onSearch;
  final VoidCallback onMore;
  final VoidCallback onProfile;

  // 👇ここを変更
  final void Function(String mode) onRouteMode;

  final VoidCallback onCancel;
  final VoidCallback onGo;
  final bool isNavigating;
  final VoidCallback? onMapStyle;
  final String mapStyleLabel;
  final String? weatherText;

  const TopBar({
    super.key,
    required this.controller,
    required this.speed,
    required this.isFullView,
    required this.dangerValue,
    required this.distanceKm,
    required this.etaText,
    required this.guideText,
    required this.routeModeText,
    required this.onSearch,
    required this.onMore,
    required this.onProfile,
    required this.onRouteMode,
    required this.onCancel,
    required this.onGo,
    required this.isNavigating,
    this.onMapStyle,
    this.mapStyleLabel = '標準',
    this.weatherText,
  });

  Widget box({
    required Widget child,
    required String label,
    required VoidCallback onTap,
    double width = 56,
    Color color = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: 56,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            child,
            if (label.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: color == Colors.white ? Colors.black54 : Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            box(
              child: const Icon(Icons.circle_outlined),
              label: 'More',
              onTap: onMore,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  controller: controller,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => onSearch(),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "検索",
                    prefixIcon: GestureDetector(
                      onTap: onSearch,
                      child: const Icon(Icons.search),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            box(
              child: const Icon(Icons.travel_explore),
              label: 'FULLVIEW',
              onTap: onProfile,
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (value) {
                onRouteMode(value); // ✅ 修正ポイント
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'F', child: Text('FAST')),
                PopupMenuItem(value: 'S', child: Text('SAFE')),
                PopupMenuItem(value: 'C', child: Text('SCENIC')),
              ],
              child: box(
                child: Text(
                  routeModeText,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                label: 'Route',
                onTap: () {},
              ),
            ),
            const SizedBox(width: 8),
            box(
              child: TweenAnimationBuilder<double>(
                tween: Tween(
                  begin: 1.0,
                  end: isNavigating ? 2.16 : 1.5,
                ),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeInOut,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                child: const Text(
                  'GO',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              label: '',
              onTap: onGo,
              color: const Color.fromARGB(255, 246, 247, 248),
            ),
          ],
        ),
        if (weatherText != null || onMapStyle != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                if (weatherText != null)
                  Expanded(
                    child: Container(
                      height: 32,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        weatherText!,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                if (weatherText != null && onMapStyle != null)
                  const SizedBox(width: 6),
                if (onMapStyle != null)
                  GestureDetector(
                    onTap: onMapStyle,
                    child: Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.map, size: 14),
                          const SizedBox(width: 4),
                          Text(mapStyleLabel, style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        if (isFullView)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      "${distanceKm.toStringAsFixed(1)}km $etaText",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: Container(
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      guideText,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: onCancel,
                    child: Container(
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
