/// 🌌 3D KNOWLEDGE GRAPH — Vollbild-Modus mit perspektivischer Projektion.
///
/// Knoten orbiten als Spheres im 3D-Raum um den zentralen Topic.
/// User kann mit Drag rotieren, Pinch zoomen, Tap auf Knoten = neuer Thread.
/// Reine Custom-Painter-Implementierung — kein 3D-Plugin nötig.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/thread.dart';
import 'kb_design.dart';

class Network3DView extends StatefulWidget {
  final List<NetworkNode> nodes;
  final void Function(String label) onTapNode;

  const Network3DView({
    super.key,
    required this.nodes,
    required this.onTapNode,
  });

  @override
  State<Network3DView> createState() => _Network3DViewState();
}

class _Network3DViewState extends State<Network3DView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _orbit;
  double _rotX = 0.3;
  double _rotY = 0.0;
  double _zoom = 1.0;
  bool _userInteracting = false;

  @override
  void initState() {
    super.initState();
    _orbit = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
  }

  @override
  void dispose() {
    _orbit.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails d) {
    setState(() {
      _userInteracting = true;
      _rotY += d.delta.dx * 0.01;
      _rotX += d.delta.dy * 0.01;
      _rotX = _rotX.clamp(-math.pi / 2, math.pi / 2);
    });
  }

  void _onPanEnd(DragEndDetails _) {
    setState(() => _userInteracting = false);
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    setState(() {
      _zoom = (_zoom * d.scale).clamp(0.4, 2.5);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.nodes.isEmpty) {
      return Container(
        color: KbDesign.voidBlack,
        child: const Center(
          child: Text('Keine Knoten geladen',
              style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: KbDesign.voidBlack,
      body: SafeArea(
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _orbit,
              builder: (_, __) {
                final autoY = _userInteracting
                    ? _rotY
                    : _rotY + _orbit.value * 2 * math.pi * 0.3;
                return GestureDetector(
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  onScaleUpdate: _onScaleUpdate,
                  onTapUp: (d) => _handleTap(d.localPosition),
                  child: CustomPaint(
                    painter: _Graph3DPainter(
                      nodes: widget.nodes,
                      rotX: _rotX,
                      rotY: autoY,
                      zoom: _zoom,
                    ),
                    size: Size.infinite,
                  ),
                );
              },
            ),
            // TopBar
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.threed_rotation,
                      color: KbDesign.neonRedSoft, size: 18),
                  const SizedBox(width: 6),
                  const Text('3D NETZWERK',
                      style: TextStyle(
                        color: Colors.white,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      )),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                    child: Text(
                      '${widget.nodes.length} Knoten',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Hinweis
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.black.withValues(alpha: 0.5),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Text(
                    'Wischen = Drehen · Pinch = Zoom · Tap auf Knoten = Eintauchen',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTap(Offset p) {
    // Berechne welcher Knoten getroffen wurde via Painter-Logik
    final size = context.size ?? const Size(400, 800);
    final autoY = _userInteracting
        ? _rotY
        : _rotY + _orbit.value * 2 * math.pi * 0.3;

    final positions = _projectAll(
      nodes: widget.nodes,
      size: size,
      rotX: _rotX,
      rotY: autoY,
      zoom: _zoom,
    );
    NetworkNode? hit;
    double hitDist = 9999;
    double hitR = 0;
    for (var i = 0; i < positions.length; i++) {
      final pos = positions[i];
      final r = pos.radius;
      final d = (Offset(pos.x, pos.y) - p).distance;
      if (d < r && d < hitDist) {
        hit = widget.nodes[i];
        hitDist = d;
        hitR = r;
      }
    }
    if (hit != null && hit.id != 'center') {
      HapticFeedback.mediumImpact();
      widget.onTapNode(hit.label);
    }
    // suppress unused warning
    hitR.toString();
  }
}

/// Berechnet 2D-Bildschirm-Positionen aller Knoten (Center+Outer) mit Rotation.
List<_Projected> _projectAll({
  required List<NetworkNode> nodes,
  required Size size,
  required double rotX,
  required double rotY,
  required double zoom,
}) {
  final result = <_Projected>[];
  final cx = size.width / 2;
  final cy = size.height / 2;
  final perspective = math.min(size.width, size.height) * 1.2;
  final radius3d = math.min(size.width, size.height) * 0.32 * zoom;

  // Center
  final center = nodes.firstWhere(
    (n) => n.id == 'center',
    orElse: () => nodes.first,
  );
  result.add(_Projected(x: cx, y: cy, depth: 0, radius: 36 * zoom));

  // Outer nodes verteilen sich auf Sphäre (Fibonacci-Verteilung)
  final outer = nodes.where((n) => n.id != 'center').toList();
  final n = outer.length;
  final golden = math.pi * (3 - math.sqrt(5));
  for (var i = 0; i < n; i++) {
    final t = (i + 0.5) / n;
    final theta = math.acos(1 - 2 * t); // Polarwinkel 0..pi
    final phi = i * golden; // Azimut
    // 3D-Position auf Einheitssphäre
    var x = math.sin(theta) * math.cos(phi);
    var y = math.sin(theta) * math.sin(phi);
    var z = math.cos(theta);

    // Rotation um Y-Achse
    final cosY = math.cos(rotY), sinY = math.sin(rotY);
    final x1 = cosY * x + sinY * z;
    final z1 = -sinY * x + cosY * z;
    x = x1;
    z = z1;
    // Rotation um X-Achse
    final cosX = math.cos(rotX), sinX = math.sin(rotX);
    final y2 = cosX * y - sinX * z;
    final z2 = sinX * y + cosX * z;
    y = y2;
    z = z2;

    // Skalieren auf 3D-Radius
    x *= radius3d;
    y *= radius3d;
    z *= radius3d;
    // Perspektive
    final scale = perspective / (perspective + z);
    final px = cx + x * scale;
    final py = cy + y * scale;
    final pr = (16 + outer[i].weight * 12) * scale;
    result.add(_Projected(x: px, y: py, depth: z, radius: pr));
  }
  // Avoid unused var lint
  center.toString();
  return result;
}

class _Projected {
  final double x;
  final double y;
  final double depth;
  final double radius;
  _Projected({required this.x, required this.y, required this.depth, required this.radius});
}

class _Graph3DPainter extends CustomPainter {
  final List<NetworkNode> nodes;
  final double rotX;
  final double rotY;
  final double zoom;

  _Graph3DPainter({
    required this.nodes,
    required this.rotX,
    required this.rotY,
    required this.zoom,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Sternfeld-Hintergrund
    final rng = math.Random(42);
    final starPaint = Paint();
    for (var i = 0; i < 200; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = rng.nextDouble() * 1.4 + 0.3;
      final alpha = rng.nextDouble() * 0.6 + 0.15;
      starPaint.color = Colors.white.withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), r, starPaint);
    }

    final positions = _projectAll(
      nodes: nodes,
      size: size,
      rotX: rotX,
      rotY: rotY,
      zoom: zoom,
    );

    // Sortiere nach Tiefe (entferntere zuerst zeichnen)
    final indices = List<int>.generate(positions.length, (i) => i);
    indices.sort((a, b) => positions[b].depth.compareTo(positions[a].depth));

    final centerPos = positions[0];

    // Edges zuerst (zwischen center und outer, hinter den Knoten)
    final edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (var i = 1; i < positions.length; i++) {
      final p = positions[i];
      // Tiefen-abhängige Opacity (entfernte Edges blasser)
      final depthFade = ((1.0 - (p.depth / (size.shortestSide * 0.5))) * 0.5)
          .clamp(0.05, 0.45);
      edgePaint.color = KbDesign.neonRed.withValues(alpha: depthFade);
      canvas.drawLine(
        Offset(centerPos.x, centerPos.y),
        Offset(p.x, p.y),
        edgePaint,
      );
    }

    // Knoten
    for (final idx in indices) {
      final pos = positions[idx];
      final node = nodes[idx];
      final isCenter = node.id == 'center';
      final color = _typeColor(node.type, isCenter);
      // Entfernung-zu-Kamera-Fade
      final depthFactor =
          ((1.0 - (pos.depth / (size.shortestSide * 0.5))) * 0.7 + 0.3)
              .clamp(0.2, 1.0);

      // Glow
      canvas.drawCircle(
        Offset(pos.x, pos.y),
        pos.radius + 6,
        Paint()..color = color.withValues(alpha: 0.25 * depthFactor),
      );
      // Body
      canvas.drawCircle(
        Offset(pos.x, pos.y),
        pos.radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: 0.95 * depthFactor),
              color.withValues(alpha: 0.4 * depthFactor),
            ],
          ).createShader(Rect.fromCircle(
              center: Offset(pos.x, pos.y), radius: pos.radius)),
      );
      // Border
      canvas.drawCircle(
        Offset(pos.x, pos.y),
        pos.radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = isCenter ? 1.8 : 1.0
          ..color = Colors.white
              .withValues(alpha: (isCenter ? 0.85 : 0.45) * depthFactor),
      );

      // Label
      final tp = TextPainter(
        text: TextSpan(
          text: node.label.length > 14
              ? '${node.label.substring(0, 13)}…'
              : node.label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: depthFactor),
            fontSize: isCenter ? 13 : (10 * (pos.radius / 22)).clamp(7.0, 11.0),
            fontWeight: isCenter ? FontWeight.w700 : FontWeight.w500,
            shadows: const [
              Shadow(blurRadius: 4, color: Colors.black, offset: Offset(0, 1)),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        maxLines: 2,
      )..layout(maxWidth: pos.radius * 4);
      tp.paint(
        canvas,
        Offset(pos.x - tp.width / 2, pos.y + pos.radius + 2),
      );
    }
  }

  Color _typeColor(String type, bool isCenter) {
    if (isCenter) return KbDesign.neonRed;
    switch (type) {
      case 'person':
        return const Color(0xFF66BB6A);
      case 'company':
        return const Color(0xFF42A5F5);
      case 'org':
        return const Color(0xFFFFB74D);
      default:
        return const Color(0xFFAB47BC);
    }
  }

  @override
  bool shouldRepaint(covariant _Graph3DPainter old) =>
      old.rotX != rotX ||
      old.rotY != rotY ||
      old.zoom != zoom ||
      old.nodes != nodes;
}
