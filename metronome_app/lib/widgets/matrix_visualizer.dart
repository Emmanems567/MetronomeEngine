import 'package:flutter/material.dart';
import 'package:metronome_app/main.dart';

class MatrixVisualizer extends StatelessWidget {
  final int currentBeat;
  final int beatsPerMeasure;
  final AppTheme theme;

  const MatrixVisualizer({
    super.key,
    required this.currentBeat,
    required this.beatsPerMeasure,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(beatsPerMeasure, (index) {
        bool isActive = (index == currentBeat);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 50),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: isActive
                ? (index == 0 ? theme.primary : theme.secondary)
                : Colors.grey[800],
            borderRadius: BorderRadius.circular(5),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: theme.secondary,
                      blurRadius: 10,
                    ),
                  ]
                : [],
          ),
        );
      }),
    );
  }
}
