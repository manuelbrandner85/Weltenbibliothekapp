/// Vertikaler "Roter Faden" auf der linken Seite — verbindet alle Karten.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'kb_design.dart';

class RoteFadenLine extends StatefulWidget {
  final ScrollController scroll;
  final double maxHeight;

  const RoteFadenLine({
    super.key,
    required this.scroll,
    required this.maxHeight,
  });

  @override
  State<RoteFadenLine> createState() => _RoteFadenLineState();
}

class _RoteFadenLineState extends State<RoteFadenLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glow;
  double _scrollFraction = 0;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    widget.scroll.addListener(_onScroll);
  }

  void _onScroll() {
    if (!widget.scroll.hasClients) return;
    final max = widget.scroll.position.maxScrollExtent;
    final pos = widget.scroll.position.pixels;
    final f = max > 0 ? (pos / max).clamp(0.0, 1.0) : 0.0;
    if ((f - _scrollFraction).abs() > 0.01) {
      setState(() => _scrollFraction = f);
    }
  }

  @override
  void dispose() {
    widget.scroll.removeListener(_onScroll);
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glow,
      builder: (_, __) => SizedBox(
        width: 18,
        height: widget.maxHeight,
        child: CustomPaint(
          painter: _FadenPainter(
            scrollFraction: _scrollFraction,
            sparkleOffset: _glow.value,
          ),
        ),
      ),
    );
  }
}

class _FadenPainter extends CustomPainter {
  final double scrollFraction;
  final double sparkleOffset;
  _FadenPainter({required this.scrollFraction, required this.sparkleOffset});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final line = Paint()
      ..color = KbDesign.neonRed.withValues(alpha: 0.32)
      ..strokeWidth = 1.4;
    canvas.drawLine(Offset(cx, 0), Offset(cx, size.height), line);

    // Glow-Knoten am aktuellen Scroll-Punkt + entlang
    final spotsCount = 5;
    for (var i = 0; i < spotsCount; i++) {
      final f = ((sparkleOffset + i / spotsCount) % 1.0);
      final y = f * size.height;
      final glow = Paint()
        ..color = KbDesign.neonRedSoft.withValues(alpha: 0.7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(cx, y), 3, glow);
    }

    // Aktiver Punkt
    final activeY = scrollFraction * size.height;
    final core = Paint()..color = KbDesign.neonRedSoft;
    final aura = Paint()
      ..color = KbDesign.neonRed.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(Offset(cx, activeY), 8, aura);
    canvas.drawCircle(Offset(cx, activeY), 4, core);

    // Markierungen (kleine Notches)
    final notches = 8;
    final notch = Paint()
      ..color = KbDesign.neonRed.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    for (var i = 0; i < notches; i++) {
      final y = (i / (notches - 1)) * size.height;
      canvas.drawLine(Offset(cx - 4, y), Offset(cx + 4, y), notch);
    }

    // unbenutzte math-import verhindert
    // ignore: unused_local_variable
    final _ = math.pi;
  }

  @override
  bool shouldRepaint(covariant _FadenPainter old) =>
      old.scrollFraction != scrollFraction ||
      old.sparkleOffset != sparkleOffset;
}
