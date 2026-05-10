import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/wb_cinematic_tokens.dart';

/// Pulsierender Welt-Orb (CustomPainter, kein BackdropFilter, GPU-leicht).
///
/// Zeichnet:
///  • äußeren weichen Halo-Glow
///  • zwei konzentrische Akzent-Ringe (Atemrhythmus)
///  • inneren weißen Lichtkern mit Welt-Color-Halo
///
/// Verwendet einen einzelnen `AnimationController`, repaintet nur bei Tick.
class WBWorldOrb extends StatefulWidget {
  final WBWorld world;
  final double size;

  /// Wenn `false`, wird statisch gerendert (für stark performance-sensitive Stellen).
  final bool animate;

  const WBWorldOrb({
    super.key,
    this.world = WBWorld.neutral,
    this.size = 64,
    this.animate = true,
  });

  @override
  State<WBWorldOrb> createState() => _WBWorldOrbState();
}

class _WBWorldOrbState extends State<WBWorldOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    if (widget.animate) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant WBWorldOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.animate && _ctrl.isAnimating) {
      _ctrl.stop();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.wb.palette(widget.world);
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) => CustomPaint(
            painter: _OrbPainter(
              t: widget.animate ? _ctrl.value : 0.5,
              primary: palette.primary,
              highlight: palette.highlight,
              deep: palette.deep,
            ),
          ),
        ),
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  final double t;
  final Color primary;
  final Color highlight;
  final Color deep;

  _OrbPainter({
    required this.t,
    required this.primary,
    required this.highlight,
    required this.deep,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxR = size.shortestSide / 2;
    final breathe = math.sin(t * math.pi) * 0.08; // 0..0.08

    // Aussen-Halo (weicher Welt-Glow)
    final haloPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          primary.withValues(alpha: 0.55 + breathe * 1.5),
          primary.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: maxR));
    canvas.drawCircle(Offset(cx, cy), maxR, haloPaint);

    // Akzent-Ring außen
    final ring1 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withValues(alpha: 0.10 + breathe);
    canvas.drawCircle(Offset(cx, cy), maxR * 0.78, ring1);

    // Akzent-Ring innen (gegen-pulsierend)
    final ring2 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withValues(alpha: 0.18 - breathe);
    canvas.drawCircle(Offset(cx, cy), maxR * 0.55, ring2);

    // Welt-Tinted Innenfläche
    final innerPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.4),
        colors: [
          highlight.withValues(alpha: 0.95),
          primary.withValues(alpha: 0.85),
          deep.withValues(alpha: 0.95),
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(
          Rect.fromCircle(center: Offset(cx, cy), radius: maxR * 0.45));
    canvas.drawCircle(Offset(cx, cy), maxR * 0.45, innerPaint);

    // Hot-Core (weißes Lichtzentrum)
    final corePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85 + breathe);
    canvas.drawCircle(Offset(cx, cy), maxR * 0.10, corePaint);

    // Spekular-Highlight oben links (Glanz)
    final specular = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.55),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(
          center: Offset(cx - maxR * 0.18, cy - maxR * 0.20),
          radius: maxR * 0.22));
    canvas.drawCircle(
        Offset(cx - maxR * 0.18, cy - maxR * 0.20), maxR * 0.22, specular);
  }

  @override
  bool shouldRepaint(covariant _OrbPainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.primary != primary ||
      oldDelegate.highlight != highlight ||
      oldDelegate.deep != deep;
}
