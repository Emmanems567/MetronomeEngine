import 'package:flutter/material.dart';
import 'package:metronome_app/main.dart';

class RhythmicBarsVisualizer extends StatelessWidget {
  final int currentBeat;
  final int beatsPerMeasure;
  final AppTheme theme;

  const RhythmicBarsVisualizer({
    super.key,
    required this.currentBeat,
    required this.beatsPerMeasure,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(beatsPerMeasure, (index) {
        bool isActive = (index == currentBeat);
        bool isTick = (isActive && index == 0);

        double height = isActive ? (isTick ? 120.0 : 80.0) : 20.0;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 75),
          curve: Curves.easeOut,
          width: 15,
          height: height,
          decoration: BoxDecoration(
            color: isActive
                ? (isTick ? theme.primary : theme.secondary)
                : Colors.grey[800],
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: theme.secondary,
                      blurRadius: 15,
                    ),
                  ]
                : [],
          ),
        );
      }),
    );
  }
}
