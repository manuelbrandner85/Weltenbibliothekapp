/// 🧭 MEDIEN-KOMPASS — Quellen auf 2D-Achse positioniert.
///
/// X-Achse: politisch links (-1) ↔ rechts (+1)
/// Y-Achse: alternativ (-1) ↔ Establishment (+1)
/// Punktgröße = Glaubwürdigkeit
library;

import 'package:flutter/material.dart';
import '../models/thread.dart';
import '../widgets/kb_design.dart';

class MediaCompassCard extends StatelessWidget {
  final List<MediaCompassPoint> points;
  final bool loading;

  const MediaCompassCard({
    super.key,
    required this.points,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: KbDesign.glassBox(tint: KbDesign.lensOfficial),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.explore_rounded,
                  color: KbDesign.lensOfficial, size: 18),
              const SizedBox(width: 8),
              const Text(
                'MEDIEN-KOMPASS',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Wo stehen die Quellen?',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 14),
          if (loading)
            _buildLoading()
          else
            AspectRatio(
              aspectRatio: 1,
              child: CustomPaint(
                painter: _CompassPainter(points: points),
              ),
            ),
          const SizedBox(height: 8),
          // Legende
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _legend('← Links', Colors.white60),
              _legend('Rechts →', Colors.white60),
              _legend('↑ Establishment', Colors.white60),
              _legend('Alternativ ↓', Colors.white60),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(String text, Color color) => Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          letterSpacing: 1,
        ),
      );

  Widget _buildLoading() => SizedBox(
        height: 200,
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: KbDesign.lensOfficial,
            ),
          ),
        ),
      );
}

class _CompassPainter extends CustomPainter {
  final List<MediaCompassPoint> points;
  _CompassPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final pad = 16.0;
    final maxR = (size.width / 2) - pad;

    // Grid background
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    // Konzentrische Ringe
    for (var i = 1; i <= 3; i++) {
      canvas.drawCircle(Offset(cx, cy), maxR * (i / 3), gridPaint);
    }
    // Achsen
    final axisPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(pad, cy), Offset(size.width - pad, cy), axisPaint);
    canvas.drawLine(Offset(cx, pad), Offset(cx, size.height - pad), axisPaint);

    // Quadranten-Tint
    final quadrants = [
      (Rect.fromLTWH(pad, pad, cx - pad, cy - pad), const Color(0xFF42A5F5)), // links-establishment (blau)
      (Rect.fromLTWH(cx, pad, cx - pad, cy - pad), const Color(0xFF66BB6A)), // rechts-establishment (grün)
      (Rect.fromLTWH(pad, cy, cx - pad, cy - pad), const Color(0xFFFF6E40)), // links-alternativ (orange)
      (Rect.fromLTWH(cx, cy, cx - pad, cy - pad), const Color(0xFFAB47BC)), // rechts-alternativ (purple)
    ];
    for (final (rect, color) in quadrants) {
      canvas.drawRect(
        rect,
        Paint()..color = color.withValues(alpha: 0.04),
      );
    }

    // Punkte zeichnen
    for (final p in points) {
      final px = cx + (p.xAxis * maxR);
      final py = cy - (p.yAxis * maxR);
      final radius = 4 + (p.credibility / 100.0) * 8;
      final color = _colorForCred(p.credibility);

      // Glow
      canvas.drawCircle(
        Offset(px, py),
        radius + 4,
        Paint()..color = color.withValues(alpha: 0.25),
      );
      canvas.drawCircle(
        Offset(px, py),
        radius,
        Paint()..color = color.withValues(alpha: 0.95),
      );
      canvas.drawCircle(
        Offset(px, py),
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Colors.white.withValues(alpha: 0.7),
      );

      // Label
      final tp = TextPainter(
        text: TextSpan(
          text: p.name,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final tx = (px + radius + 2).clamp(0.0, size.width - tp.width - 2);
      final ty = (py - tp.height / 2).clamp(0.0, size.height - tp.height);
      tp.paint(canvas, Offset(tx, ty));
    }
  }

  Color _colorForCred(int cred) {
    if (cred >= 80) return KbDesign.credGold;
    if (cred >= 60) return KbDesign.credSilver;
    if (cred >= 40) return Colors.orange;
    return KbDesign.credAlert;
  }

  @override
  bool shouldRepaint(covariant _CompassPainter old) =>
      old.points != points;
}
