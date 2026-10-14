import 'package:flutter/material.dart';
import 'package:metronome_app/main.dart';

class BorderGlowVisualizer extends StatelessWidget {
  final int currentBeat;
  final int beatsPerMeasure;
  final AppTheme theme;

  const BorderGlowVisualizer({
    super.key,
    required this.currentBeat,
    required this.beatsPerMeasure,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    bool isTick = (currentBeat == 0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isTick
              ? theme.primary 
              : theme.secondary,
          width: isTick ? 6.0 : 2.0,
        ),
        boxShadow: isTick
            ? [
                BoxShadow(
                  color: theme.secondary,
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ]
            : [],
      ),
      child: Center(
        child: Text(
          '${currentBeat + 1} / $beatsPerMeasure',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: isTick ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }
}
