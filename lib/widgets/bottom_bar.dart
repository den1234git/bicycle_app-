import 'package:flutter/material.dart';
import 'map_buttons.dart';

class BottomBar extends StatelessWidget {
  final String nowTime;
  final double speed;
  final bool showSpeed;
  final VoidCallback onTimeTap;
  final VoidCallback? onTimeLongPress;
  final String modeText;
  final bool walkMode;
  final VoidCallback onCurrent;
  final VoidCallback onMode;
  final VoidCallback onSos;
  final VoidCallback onViewMode;
  final VoidCallback onWait;
  final VoidCallback? onWaitLongPress;
  final String viewText;
  final String commuteText;
  final bool isTrainMode;
  final String? trainFrom;
  final String? trainTo;
  final String? eta;

  const BottomBar({
    super.key,
    required this.nowTime,
    required this.speed,
    required this.showSpeed,
    required this.onTimeTap,
    this.onTimeLongPress,
    required this.modeText,
    required this.walkMode,
    required this.onCurrent,
    required this.onMode,
    required this.onSos,
    required this.onViewMode,
    required this.onWait,
    this.onWaitLongPress,
    required this.viewText,
    required this.commuteText,
    required this.isTrainMode,
    this.trainFrom,
    this.trainTo,
    this.eta,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        MapButton(
          color: Colors.red,
          onLongPress: onSos,
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(height: 2),
              Text(
                'SOS',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        MapButton(
          onTap: onTimeTap,
          onLongPress: onTimeLongPress,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                showSpeed ? "${speed.toStringAsFixed(0)}km" : nowTime,
              ),
              const SizedBox(height: 2),
              Text(
                showSpeed ? 'SPEED' : 'TIME',
                style: const TextStyle(fontSize: 9),
              ),
            ],
          ),
        ),
        MapButton(
          onTap: onCurrent,
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.my_location),
              SizedBox(height: 2),
              Text(
                'GPS',
                style: TextStyle(fontSize: 9),
              ),
            ],
          ),
        ),
        MapButton(
          onTap: onMode,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(modeText),
              const SizedBox(height: 2),
              const Text(
                'MODE',
                style: TextStyle(fontSize: 9),
              ),
            ],
          ),
        ),
        isTrainMode
            ? MapButton(
                onTap: onWait,
                onLongPress: onWaitLongPress,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_active),
                    SizedBox(height: 2),
                    Text(
                      'WAIT',
                      style: TextStyle(fontSize: 9),
                    ),
                  ],
                ),
              )
            : MapButton(
                onTap: onViewMode,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(viewText),
                    const SizedBox(height: 2),
                    const Text(
                      'VIEW',
                      style: TextStyle(fontSize: 9),
                    ),
                  ],
                ),
              ),
      ],
    );
  }
}
