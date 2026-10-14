import 'package:flutter/material.dart';
import '../main.dart'; 

class PongVisualizer extends StatefulWidget {
  final int currentBeat;
  final int beatsPerMeasure;
  final int bpm; 
  final int noteValue; 
  final AppTheme theme;

  const PongVisualizer({
    super.key,
    required this.currentBeat,
    required this.beatsPerMeasure,
    required this.bpm,
    required this.noteValue, 
    required this.theme,
  });

  @override
  State<PongVisualizer> createState() => _PongVisualizerState();
}

class _PongVisualizerState extends State<PongVisualizer> with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  
  bool _isLeft = true; 

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _glowAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeOut)
    );
  }

  @override
  void didUpdateWidget(covariant PongVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentBeat != oldWidget.currentBeat) {
      _isLeft = !_isLeft; 
      _glowController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isTick = widget.currentBeat == 0;
    
    int durationMs = ((60000 / widget.bpm) * (4.0 / widget.noteValue)).round();

    Color activeColor = isTick ? widget.theme.primary : widget.theme.secondary;

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        double glow = _glowAnimation.value;

        return Container(
          width: double.infinity,
          height: 120,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              // --- LEFT BLOCK ---
              Container(
                width: 15,
                height: 90,
                decoration: BoxDecoration(
                  color: _isLeft ? activeColor : Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _isLeft ? [
                    BoxShadow(color: activeColor.withOpacity(0.8 * glow), blurRadius: 20 * glow, spreadRadius: 5 * glow)
                  ] : [],
                ),
              ),
              
              // --- GAME ZONE ---
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(width: 2, height: double.infinity, color: Colors.grey[800]?.withOpacity(0.5)),
                    
                    AnimatedAlign(
                      // LÓGICA INVERTIDA: Si la pala izquierda brilla (_isLeft), la pelota DEBE VIAJAR hacia la derecha
                      alignment: _isLeft ? Alignment.centerRight : Alignment.centerLeft,
                      duration: Duration(milliseconds: durationMs),
                      curve: Curves.linear, 
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: widget.theme.primary,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: widget.theme.primary.withOpacity(0.5), blurRadius: 10)]
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // --- RIGHT BLOCK---
              Container(
                width: 15,
                height: 90,
                decoration: BoxDecoration(
                  color: !_isLeft ? activeColor : Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: !_isLeft ? [
                    BoxShadow(color: activeColor.withOpacity(0.8 * glow), blurRadius: 20 * glow, spreadRadius: 5 * glow)
                  ] : [],
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}
