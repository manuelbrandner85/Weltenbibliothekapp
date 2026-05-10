import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Subtiles Film-Grain-Overlay.
///
/// Verwendet einen einzelnen `CustomPainter`, der Pseudo-Noise zeichnet.
/// Animiert durch Verschiebung (kein neues Pixel-Pattern pro Frame, nur
/// Translate auf statisch generierten Punkten — GPU-leicht).
/// In `RepaintBoundary`, `IgnorePointer`, BlendMode `overlay`.
class WBGrainOverlay extends StatefulWidget {
  final double opacity; // default 0.06
  final bool animate;

  const WBGrainOverlay({
    super.key,
    this.opacity = 0.06,
    this.animate = true,
  });

  @override
  State<WBGrainOverlay> createState() => _WBGrainOverlayState();
}

class _WBGrainOverlayState extends State<WBGrainOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<Offset> _points;

  @override
  void initState() {
    super.initState();
    final rng = math.Random(42);
    _points = List.generate(
      900,
      (_) => Offset(rng.nextDouble(), rng.nextDouble()),
    );
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    );
    if (widget.animate) _ctrl.repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) => CustomPaint(
            painter: _GrainPainter(
              points: _points,
              tick: _ctrl.value,
              opacity: widget.opacity,
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _GrainPainter extends CustomPainter {
  final List<Offset> points;
  final double tick;
  final double opacity;

  _GrainPainter({
    required this.points,
    required this.tick,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Diskreter Shift-Schritt (6 Schritte über die gesamte Animation)
    final step = (tick * 6).floor();
    final shifts = [
      const Offset(0, 0),
      const Offset(-1, 1),
      const Offset(1, -1),
      const Offset(-2, -1),
      const Offset(1, 2),
      const Offset(0, 0),
    ];
    final shift = shifts[step % shifts.length];

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.overlay;

    for (final p in points) {
      final x = p.dx * size.width + shift.dx;
      final y = p.dy * size.height + shift.dy;
      canvas.drawRect(Rect.fromLTWH(x, y, 1.2, 1.2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GrainPainter oldDelegate) =>
      oldDelegate.tick != tick || oldDelegate.opacity != opacity;
}
