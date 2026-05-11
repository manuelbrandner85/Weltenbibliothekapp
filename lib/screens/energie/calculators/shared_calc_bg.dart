/// Wiederverwendbarer animierter Hintergrund für alle Spirit-Calculator-Screens.
/// Füge ihn als Stack-Basis in jeden Calculator-Screen ein.
library;

import 'package:flutter/material.dart';

class CalcAnimatedBg extends StatefulWidget {
  final Color primaryColor;
  final Color secondaryColor;
  final Widget child;

  const CalcAnimatedBg({
    super.key,
    this.primaryColor = const Color(0xFFAB47BC),
    this.secondaryColor = const Color(0xFF26C6DA),
    required this.child,
  });

  @override
  State<CalcAnimatedBg> createState() => _CalcAnimatedBgState();
}

class _CalcAnimatedBgState extends State<CalcAnimatedBg>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Stack(
          children: [
            Container(color: const Color(0xFF06040F)),
            // Orb 1 (Primary)
            Positioned(
              top: -80 + _ctrl.value * 40,
              right: -60 + _ctrl.value * 30,
              child: _Orb(color: widget.primaryColor, size: 250, opacity: 0.12),
            ),
            // Orb 2 (Secondary)
            Positioned(
              bottom: -100 + _ctrl.value * 50,
              left: -80,
              child:
                  _Orb(color: widget.secondaryColor, size: 220, opacity: 0.10),
            ),
            // Orb 3 (Accent)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.4,
              left: MediaQuery.of(context).size.width * 0.3,
              child: _Orb(
                color: widget.primaryColor.withValues(alpha: 0.5),
                size: 150,
                opacity: 0.06 + _ctrl.value * 0.04,
              ),
            ),
            child!,
          ],
        );
      },
      child: widget.child,
    );
  }
}

class _Orb extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;

  const _Orb({required this.color, required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}

/// Animierter Ergebnis-Karte Wrapper für Calculator-Results
class AnimatedResultCard extends StatefulWidget {
  final Widget child;
  final int delayMs;

  const AnimatedResultCard({
    super.key,
    required this.child,
    this.delayMs = 0,
  });

  @override
  State<AnimatedResultCard> createState() => _AnimatedResultCardState();
}

class _AnimatedResultCardState extends State<AnimatedResultCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
