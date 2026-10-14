import 'package:flutter/material.dart';
import 'package:metronome_app/main.dart';

class PulseVisualizer extends StatefulWidget {
  final int currentBeat;
  final int beatsPerMeasure;
  final AppTheme theme;

  const PulseVisualizer({
    super.key,
    required this.currentBeat,
    required this.beatsPerMeasure,
    required this.theme,
  });

  @override
  State<PulseVisualizer> createState() => _PulseVisualizerState();
}

class _PulseVisualizerState extends State<PulseVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant PulseVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentBeat != oldWidget.currentBeat) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isTick = (widget.currentBeat == 0);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: isTick ? 80 : 80,
        height: isTick ? 80 : 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isTick ? widget.theme.primary : const Color(0xFF1E1E1E),
          boxShadow: isTick
              ? [
                  BoxShadow(
                    color: widget.theme.secondary, 
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ]
              : [],
          border: Border.all(
            color: isTick ? Colors.white : widget.theme.secondary,
            width: isTick ? 4 : 2,
          ),
        ),
        child: Center(
          child: Text(
            '${widget.currentBeat + 1}',
            style: TextStyle(
              fontSize: isTick ? 40 : 24,
              fontWeight: FontWeight.bold,
              color: isTick ? Colors.white : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}

