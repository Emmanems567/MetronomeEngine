import 'package:flutter/material.dart';

import 'dart:math' as math;

import 'package:metronome_app/main.dart';

class RadialRingsVisualizer extends StatelessWidget {
  final int currentBeat;
  final int beatsPerMeasure;
  final AppTheme theme;

  const RadialRingsVisualizer({
    super.key,
    required this.currentBeat,
    required this.beatsPerMeasure,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    bool isTick = (currentBeat == 0);

    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 160,
            height: 160,
            child: CustomPaint(
              painter: _RadialPainter(
                currentBeat,
                beatsPerMeasure,
                theme,
              ),
            ),
          ),

          Text(
            '${currentBeat + 1} / $beatsPerMeasure',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isTick ? Colors.white : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}

class _RadialPainter extends CustomPainter {
  final int currentBeat;
  final int beatsPerMeasure;
  final AppTheme theme;

  _RadialPainter(this.currentBeat, this.beatsPerMeasure, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final sweepAngle = (2 * math.pi) / beatsPerMeasure;

    final gap = sweepAngle * 0.25;
    final blockSweep = sweepAngle - gap;

    final bgPaint = Paint()
      ..color = Colors.grey[800]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < beatsPerMeasure; i++) {
      if (i == currentBeat) continue;

      final startAngle = -math.pi / 2 + (i * sweepAngle) + (gap / 2);
      canvas.drawArc(rect, startAngle, blockSweep, false, bgPaint);
    }

    final isTick = currentBeat == 0;
    final activeColor = isTick ? theme.primary : theme.secondary;
    final startAngle = -math.pi / 2 + (currentBeat * sweepAngle) + (gap / 2);

    final glowPaint = Paint()
      ..color = activeColor.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0);

    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, blockSweep, false, glowPaint);
    canvas.drawArc(rect, startAngle, blockSweep, false, activePaint);
  }

  @override
  bool shouldRepaint(covariant _RadialPainter oldDelegate) {
    return oldDelegate.currentBeat != currentBeat ||
        oldDelegate.beatsPerMeasure != beatsPerMeasure;
  }
}

