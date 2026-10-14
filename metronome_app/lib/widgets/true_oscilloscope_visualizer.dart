import 'package:flutter/material.dart';
import 'package:metronome_app/main.dart';

class TrueOscilloscopeVisualizer extends StatefulWidget {
  final int currentBeat;
  final int beatsPerMeasure;
  final AppTheme theme;

  const TrueOscilloscopeVisualizer({
    super.key,
    required this.currentBeat,
    required this.beatsPerMeasure,
    required this.theme,
  });

  @override
  State<TrueOscilloscopeVisualizer> createState() =>
      _TrueOscilloscopeVisualizerState();
}

class _TrueOscilloscopeVisualizerState extends State<TrueOscilloscopeVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  final int _maxPoints = 100;
  final List<double> _points = [];
  double _currentAmplitude = 0.0;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < _maxPoints; i++) {
      _points.add(0.0);
    }

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_updateWaveform);

    _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant TrueOscilloscopeVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentBeat != oldWidget.currentBeat) {
      _currentAmplitude = (widget.currentBeat == 0) ? 1.0 : 0.4;
    }
  }

  void _updateWaveform() {
    setState(() {
      _points.removeAt(0);

      _points.add(_currentAmplitude);

      _currentAmplitude *= 0.75;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 120,
      child: CustomPaint(painter: _EcgPainter(_points, widget.theme.primary)),
    );
  }
}

class _EcgPainter extends CustomPainter {
  final List<double> points;
  final Color glowColor;

  _EcgPainter(this.points, this.glowColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = glowColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeJoin = StrokeJoin.round;

    final glowPaint = Paint()
      ..color = glowColor.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);

    final path = Path();
    final double stepX = size.width / (points.length - 1);
    final double centerY = size.height / 2;

    for (int i = 0; i < points.length; i++) {
      final double x = i * stepX;

      double polarity = (i % 2 == 0) ? 1.0 : -1.0;

      if (points[i] < 0.02) polarity = 0.0;

      final double y = centerY - (points[i] * (centerY - 10) * polarity);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _EcgPainter oldDelegate) {
    return true;
  }
}
