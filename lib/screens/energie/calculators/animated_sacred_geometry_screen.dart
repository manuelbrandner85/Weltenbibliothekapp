// 🔯 ANIMIERTE HEILIGE GEOMETRIE
//
// 8 Sakralformen zeichnen sich live Stroke-für-Stroke nach. CustomPainter
// mit Animation. Frei drehbar via Gesture-Detector. Meditatives Erleben.

import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedSacredGeometryScreen extends StatefulWidget {
  const AnimatedSacredGeometryScreen({super.key});

  @override
  State<AnimatedSacredGeometryScreen> createState() =>
      _AnimatedSacredGeometryScreenState();
}

class _AnimatedSacredGeometryScreenState
    extends State<AnimatedSacredGeometryScreen> with TickerProviderStateMixin {
  static const _bg = Color(0xFF06040F);
  static const _accent = Color(0xFF00ACC1);

  late AnimationController _draw;
  late AnimationController _rotate;

  _Pattern _current = _Pattern.flowerOfLife;
  bool _autoRotate = false;
  double _userRotation = 0;

  @override
  void initState() {
    super.initState();
    _draw = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..forward();
    _rotate = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    );
  }

  @override
  void dispose() {
    _draw.dispose();
    _rotate.dispose();
    super.dispose();
  }

  void _select(_Pattern p) {
    setState(() => _current = p);
    _draw
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _accent,
        title: const Row(children: [
          Text('🔯', style: TextStyle(fontSize: 22)),
          SizedBox(width: 10),
          Text('Heilige Geometrie',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ]),
        actions: [
          IconButton(
            icon: Icon(_autoRotate ? Icons.pause : Icons.rotate_right),
            tooltip: _autoRotate ? 'Rotation stoppen' : 'Auto-Rotation',
            onPressed: () {
              setState(() => _autoRotate = !_autoRotate);
              if (_autoRotate) {
                _rotate.repeat();
              } else {
                _rotate.stop();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Neu zeichnen',
            onPressed: () => _draw
              ..reset()
              ..forward(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: GestureDetector(
              onPanUpdate: (d) {
                setState(() => _userRotation += d.delta.dx / 100);
              },
              child: AnimatedBuilder(
                animation: Listenable.merge([_draw, _rotate]),
                builder: (_, __) {
                  return CustomPaint(
                    size: Size.infinite,
                    painter: _GeometryPainter(
                      pattern: _current,
                      progress: _draw.value,
                      rotation: _userRotation +
                          (_autoRotate ? _rotate.value * 2 * math.pi : 0),
                      color: _accent,
                    ),
                  );
                },
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            decoration: const BoxDecoration(
              color: Color(0xFF0D1F23),
              border: Border(top: BorderSide(color: _accent, width: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_current.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(_current.meaning,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 11.5, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          SizedBox(
            height: 92,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _Pattern.values.length,
              itemBuilder: (_, i) {
                final p = _Pattern.values[i];
                final selected = p == _current;
                return GestureDetector(
                  onTap: () => _select(p),
                  child: Container(
                    width: 70,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: selected
                          ? _accent.withValues(alpha: 0.3)
                          : const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            selected ? _accent : _accent.withValues(alpha: 0.2),
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(p.emoji, style: const TextStyle(fontSize: 22)),
                        const SizedBox(height: 4),
                        Text(p.shortLabel,
                            style: TextStyle(
                              color: selected ? Colors.white : Colors.white70,
                              fontSize: 9,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

enum _Pattern {
  flowerOfLife,
  vesicaPiscis,
  metatronCube,
  sriYantra,
  merkaba,
  torus,
  goldenSpiral,
  hexagram;

  String get title => switch (this) {
        _Pattern.flowerOfLife => 'Blume des Lebens',
        _Pattern.vesicaPiscis => 'Vesica Piscis',
        _Pattern.metatronCube => 'Metatrons Würfel',
        _Pattern.sriYantra => 'Sri Yantra',
        _Pattern.merkaba => 'Merkaba',
        _Pattern.torus => 'Torus',
        _Pattern.goldenSpiral => 'Goldene Spirale',
        _Pattern.hexagram => 'Davidstern',
      };

  String get meaning => switch (this) {
        _Pattern.flowerOfLife =>
          '19 verschränkte Kreise · enthält alle Platonischen Körper. Symbol der Schöpfung.',
        _Pattern.vesicaPiscis =>
          'Zwei sich überlappende Kreise · die Mandorla, das Tor zwischen Welten.',
        _Pattern.metatronCube =>
          '13 Kreise aus der Blume des Lebens · alle 5 Platonischen Körper enthalten.',
        _Pattern.sriYantra =>
          '9 verschränkte Dreiecke · Tantra-Diagramm der Schöpfung.',
        _Pattern.merkaba =>
          'Zwei verschränkte Tetraeder · Lichtkörper-Fahrzeug.',
        _Pattern.torus =>
          'Selbst-zirkulierende Energie · Magnetfeld, Herzfeld, Apfelform.',
        _Pattern.goldenSpiral =>
          'Fibonacci-Spirale nach Phi (1.618) · universelles Wachstumsprinzip.',
        _Pattern.hexagram =>
          'Zwei ineinander verflochtene Dreiecke · Vereinigung Himmel/Erde, männlich/weiblich.',
      };

  String get emoji => switch (this) {
        _Pattern.flowerOfLife => '🌸',
        _Pattern.vesicaPiscis => '👁️',
        _Pattern.metatronCube => '🕯️',
        _Pattern.sriYantra => '🔯',
        _Pattern.merkaba => '🔺',
        _Pattern.torus => '♾️',
        _Pattern.goldenSpiral => '🌀',
        _Pattern.hexagram => '✡️',
      };

  String get shortLabel => switch (this) {
        _Pattern.flowerOfLife => 'Blume',
        _Pattern.vesicaPiscis => 'Vesica',
        _Pattern.metatronCube => 'Metatron',
        _Pattern.sriYantra => 'Sri Yantra',
        _Pattern.merkaba => 'Merkaba',
        _Pattern.torus => 'Torus',
        _Pattern.goldenSpiral => 'Spirale',
        _Pattern.hexagram => 'Hexagram',
      };
}

class _GeometryPainter extends CustomPainter {
  final _Pattern pattern;
  final double progress;
  final double rotation;
  final Color color;

  _GeometryPainter({
    required this.pattern,
    required this.progress,
    required this.rotation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 3.2;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.translate(-center.dx, -center.dy);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    switch (pattern) {
      case _Pattern.flowerOfLife:
        _drawFlowerOfLife(canvas, center, radius, paint, glowPaint);
        break;
      case _Pattern.vesicaPiscis:
        _drawVesicaPiscis(canvas, center, radius, paint, glowPaint);
        break;
      case _Pattern.metatronCube:
        _drawMetatronCube(canvas, center, radius, paint, glowPaint);
        break;
      case _Pattern.sriYantra:
        _drawSriYantra(canvas, center, radius, paint, glowPaint);
        break;
      case _Pattern.merkaba:
        _drawMerkaba(canvas, center, radius, paint, glowPaint);
        break;
      case _Pattern.torus:
        _drawTorus(canvas, center, radius, paint, glowPaint);
        break;
      case _Pattern.goldenSpiral:
        _drawGoldenSpiral(canvas, center, radius, paint, glowPaint);
        break;
      case _Pattern.hexagram:
        _drawHexagram(canvas, center, radius, paint, glowPaint);
        break;
    }
    canvas.restore();
  }

  void _drawArcPart(Canvas canvas, Offset c, double r, Paint p, Paint g,
      double startAngle, double sweepAngle, double prog) {
    final actualSweep = sweepAngle * prog.clamp(0.0, 1.0);
    if (actualSweep <= 0) return;
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawArc(rect, startAngle, actualSweep, false, g);
    canvas.drawArc(rect, startAngle, actualSweep, false, p);
  }

  void _drawCircle(
      Canvas canvas, Offset c, double r, Paint p, Paint g, double prog) {
    _drawArcPart(canvas, c, r, p, g, -math.pi / 2, 2 * math.pi, prog);
  }

  void _drawFlowerOfLife(Canvas canvas, Offset c, double r, Paint p, Paint g) {
    // 7 Kreise (Zentral + 6 Außen). Sequenz-Animation.
    final circles = <Offset>[c];
    for (var i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      circles
          .add(Offset(c.dx + r * math.cos(angle), c.dy + r * math.sin(angle)));
    }
    final perCircleProgress = 1.0 / circles.length;
    for (var i = 0; i < circles.length; i++) {
      final localProg = ((progress - i * perCircleProgress) / perCircleProgress)
          .clamp(0.0, 1.0);
      _drawCircle(canvas, circles[i], r, p, g, localProg);
    }
  }

  void _drawVesicaPiscis(Canvas canvas, Offset c, double r, Paint p, Paint g) {
    final left = Offset(c.dx - r / 2, c.dy);
    final right = Offset(c.dx + r / 2, c.dy);
    _drawCircle(canvas, left, r, p, g, math.min(1.0, progress * 2));
    _drawCircle(canvas, right, r, p, g,
        math.max(0, math.min(1.0, (progress - 0.5) * 2)));
  }

  void _drawMetatronCube(Canvas canvas, Offset c, double r, Paint p, Paint g) {
    final points = <Offset>[];
    points.add(c);
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3;
      points.add(
          Offset(c.dx + r * 0.6 * math.cos(a), c.dy + r * 0.6 * math.sin(a)));
    }
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3 - math.pi / 6;
      points.add(Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a)));
    }
    // Verbindungslinien
    final lines = <(int, int)>[];
    for (var i = 0; i < points.length; i++) {
      for (var j = i + 1; j < points.length; j++) {
        lines.add((i, j));
      }
    }
    final perLine = 1.0 / lines.length;
    for (var i = 0; i < lines.length; i++) {
      final lp = ((progress - i * perLine) / perLine).clamp(0.0, 1.0);
      if (lp <= 0) continue;
      final from = points[lines[i].$1];
      final to = points[lines[i].$2];
      final endX = from.dx + (to.dx - from.dx) * lp;
      final endY = from.dy + (to.dy - from.dy) * lp;
      canvas.drawLine(from, Offset(endX, endY), g);
      canvas.drawLine(from, Offset(endX, endY), p);
    }
  }

  void _drawSriYantra(Canvas canvas, Offset c, double r, Paint p, Paint g) {
    // Vereinfacht: 4 Aufwärts + 5 Abwärts-Dreiecke um zentralen Punkt.
    final triangles = 9;
    final perTri = 1.0 / triangles;
    for (var i = 0; i < triangles; i++) {
      final tp = ((progress - i * perTri) / perTri).clamp(0.0, 1.0);
      if (tp <= 0) continue;
      final scale = 1.0 - i * 0.08;
      final up = i.isEven;
      final path = Path();
      final size = r * scale;
      if (up) {
        path.moveTo(c.dx, c.dy - size);
        path.lineTo(c.dx - size * math.sqrt(3) / 2, c.dy + size / 2);
        path.lineTo(c.dx + size * math.sqrt(3) / 2, c.dy + size / 2);
        path.close();
      } else {
        path.moveTo(c.dx, c.dy + size);
        path.lineTo(c.dx - size * math.sqrt(3) / 2, c.dy - size / 2);
        path.lineTo(c.dx + size * math.sqrt(3) / 2, c.dy - size / 2);
        path.close();
      }
      final metrics = path.computeMetrics();
      for (final m in metrics) {
        final extract = m.extractPath(0, m.length * tp);
        canvas.drawPath(extract, g);
        canvas.drawPath(extract, p);
      }
    }
  }

  void _drawMerkaba(Canvas canvas, Offset c, double r, Paint p, Paint g) {
    // 2 verschränkte Dreiecke
    final ups = ['up', 'down'];
    for (var i = 0; i < 2; i++) {
      final tp = ((progress - i * 0.5) / 0.5).clamp(0.0, 1.0);
      if (tp <= 0) continue;
      final up = ups[i] == 'up';
      final path = Path();
      if (up) {
        path.moveTo(c.dx, c.dy - r);
        path.lineTo(c.dx - r * math.sqrt(3) / 2, c.dy + r / 2);
        path.lineTo(c.dx + r * math.sqrt(3) / 2, c.dy + r / 2);
        path.close();
      } else {
        path.moveTo(c.dx, c.dy + r);
        path.lineTo(c.dx - r * math.sqrt(3) / 2, c.dy - r / 2);
        path.lineTo(c.dx + r * math.sqrt(3) / 2, c.dy - r / 2);
        path.close();
      }
      final metrics = path.computeMetrics();
      for (final m in metrics) {
        final extract = m.extractPath(0, m.length * tp);
        canvas.drawPath(extract, g);
        canvas.drawPath(extract, p);
      }
    }
  }

  void _drawTorus(Canvas canvas, Offset c, double r, Paint p, Paint g) {
    // Mehrere konzentrische Ellipsen aus verschiedenen Winkeln
    final ringCount = 16;
    final perRing = 1.0 / ringCount;
    for (var i = 0; i < ringCount; i++) {
      final rp = ((progress - i * perRing) / perRing).clamp(0.0, 1.0);
      if (rp <= 0) continue;
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(i * math.pi / ringCount);
      canvas.translate(-c.dx, -c.dy);
      final rect = Rect.fromCenter(center: c, width: r * 2, height: r * 0.6);
      canvas.drawArc(rect, 0, 2 * math.pi * rp, false, g);
      canvas.drawArc(rect, 0, 2 * math.pi * rp, false, p);
      canvas.restore();
    }
  }

  void _drawGoldenSpiral(Canvas canvas, Offset c, double r, Paint p, Paint g) {
    final phi = (1 + math.sqrt(5)) / 2;
    final path = Path();
    final maxT = 4 * math.pi;
    final t = maxT * progress;
    final scale = r / 30;
    path.moveTo(c.dx, c.dy);
    for (double i = 0; i <= t; i += 0.05) {
      final rr = scale * math.pow(phi, i / (math.pi / 2));
      final x = c.dx + rr * math.cos(i);
      final y = c.dy + rr * math.sin(i);
      path.lineTo(x, y);
    }
    canvas.drawPath(path, g);
    canvas.drawPath(path, p);
  }

  void _drawHexagram(Canvas canvas, Offset c, double r, Paint p, Paint g) {
    final triangles = 2;
    for (var i = 0; i < triangles; i++) {
      final tp = ((progress - i * 0.5) / 0.5).clamp(0.0, 1.0);
      if (tp <= 0) continue;
      final up = i == 0;
      final path = Path();
      if (up) {
        path.moveTo(c.dx, c.dy - r);
        path.lineTo(c.dx - r * math.sqrt(3) / 2, c.dy + r / 2);
        path.lineTo(c.dx + r * math.sqrt(3) / 2, c.dy + r / 2);
        path.close();
      } else {
        path.moveTo(c.dx, c.dy + r);
        path.lineTo(c.dx - r * math.sqrt(3) / 2, c.dy - r / 2);
        path.lineTo(c.dx + r * math.sqrt(3) / 2, c.dy - r / 2);
        path.close();
      }
      final metrics = path.computeMetrics();
      for (final m in metrics) {
        final extract = m.extractPath(0, m.length * tp);
        canvas.drawPath(extract, g);
        canvas.drawPath(extract, p);
      }
    }
  }

  @override
  bool shouldRepaint(_GeometryPainter old) =>
      old.progress != progress ||
      old.rotation != rotation ||
      old.pattern != pattern;
}
