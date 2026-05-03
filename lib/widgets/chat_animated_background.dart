import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animierter Hintergrund für Chat-Screens — identischer Stil wie LiveKit-Screen.
/// Materie: Hexagon-Grid + pulsierende Orbs (Blau).
/// Energie: Aurora-Wellen + schwebende Partikel (Violett).
class ChatAnimatedBackground extends StatelessWidget {
  final String world;
  final Animation<double> animation;

  const ChatAnimatedBackground({
    super.key,
    required this.world,
    required this.animation,
  });

  static const _materieAccent = Color(0xFF42A5F5);
  static const _energieAccent = Color(0xFFEA80FC);

  @override
  Widget build(BuildContext context) {
    final accent = world == 'materie' ? _materieAccent : _energieAccent;
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) => CustomPaint(
        painter: world == 'materie'
            ? _MaterieChatPainter(animation.value, accent)
            : _EnergieChatPainter(animation.value, accent),
        child: const SizedBox.expand(),
      ),
    );
  }
}

// ─── Materie ────────────────────────────────────────────────────────────────

class _MaterieChatPainter extends CustomPainter {
  final double t;
  final Color accent;

  _MaterieChatPainter(this.t, this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = accent.withValues(alpha: 0.06);

    const hexRadius = 60.0;
    final hexHeight = hexRadius * math.sqrt(3);
    final cols = (size.width / (hexRadius * 1.5)).ceil() + 1;
    final rows = (size.height / hexHeight).ceil() + 1;

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final x = col * hexRadius * 1.5;
        final y = row * hexHeight + (col.isOdd ? hexHeight / 2 : 0);
        _drawHex(canvas, paint, Offset(x, y), hexRadius);
      }
    }

    final pulsePaint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 5; i++) {
      final phase = (t + i * 0.2) % 1.0;
      final angle = i * math.pi * 2 / 5 + t * math.pi * 0.3;
      final x = size.width * 0.5 + math.cos(angle) * size.width * 0.35;
      final y = size.height * 0.45 + math.sin(angle) * size.height * 0.25;
      final radius = 80.0 + 40.0 * phase;
      pulsePaint.shader = RadialGradient(
        colors: [
          accent.withValues(alpha: 0.10 * (1 - phase)),
          accent.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: Offset(x, y), radius: radius));
      canvas.drawCircle(Offset(x, y), radius, pulsePaint);
    }
  }

  void _drawHex(Canvas canvas, Paint paint, Offset center, double radius) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = math.pi / 3 * i;
      final px = center.dx + radius * math.cos(angle);
      final py = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MaterieChatPainter old) => old.t != t;
}

// ─── Energie ────────────────────────────────────────────────────────────────

class _EnergieChatPainter extends CustomPainter {
  final double t;
  final Color accent;

  _EnergieChatPainter(this.t, this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    for (int wave = 0; wave < 4; wave++) {
      final path = Path();
      final waveY = size.height * (0.3 + wave * 0.15);
      final amplitude = 40.0 + wave * 15.0;
      final frequency = 0.005 + wave * 0.001;
      final phase = t * math.pi * 2 + wave * math.pi / 3;

      path.moveTo(0, waveY);
      for (double x = 0; x <= size.width; x += 4) {
        final y = waveY + math.sin(x * frequency + phase) * amplitude;
        path.lineTo(x, y);
      }

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 80.0 + wave * 20.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40)
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accent.withValues(alpha: 0.04 + wave * 0.005),
            accent.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromLTWH(0, waveY - 60, size.width, 120));
      canvas.drawPath(path, paint);
    }

    final particlePaint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 15; i++) {
      final seed = i * 0.137;
      final angle = (seed + t * 0.2) * math.pi * 2;
      final radiusPercent = 0.2 + ((i * 7) % 60) / 100;
      final x = size.width * 0.5 + math.cos(angle) * size.width * radiusPercent;
      final y = size.height * 0.5 + math.sin(angle * 1.3) * size.height * radiusPercent;
      final particleSize = 1.5 + math.sin(t * math.pi * 2 + i) * 0.8;
      particlePaint.color = accent.withValues(alpha: 0.4);
      canvas.drawCircle(Offset(x, y), particleSize, particlePaint);
      particlePaint.color = accent.withValues(alpha: 0.15);
      canvas.drawCircle(Offset(x, y), particleSize * 3, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _EnergieChatPainter old) => old.t != t;
}
