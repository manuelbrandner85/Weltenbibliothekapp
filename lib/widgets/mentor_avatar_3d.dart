/// 🌐 MENTOR AVATAR 3D — Perspective-projected 3D avatar for mentor sessions.
///
/// Renders a 3D geometric structure unique to each mentor personality using
/// manual perspective projection (no 3D engine package needed, OTA-compatible).
///
/// Architecture:
///   - [MentorAvatar3d] accepts pre-existing AnimationControllers from the
///     caller and delegates rendering to [_Avatar3dPainter].
///   - 3D vertices are rotated via rotation matrices, then projected to 2D
///     using perspective division (focal = 320, z-offset = 400).
///   - Edges are depth-sorted (back-to-front / painter's algorithm).
///   - Each [MentorPersonality] gets its own geometry (cube, atom-orbits,
///     helix, icosahedron) built once and cached.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/mentor_service.dart';

// ─── 3D helpers ─────────────────────────────────────────────────────────────

/// Mutable 3D point.
class _Vec3 {
  double x, y, z;
  _Vec3(this.x, this.y, this.z);

  _Vec3 rotX(double a) {
    final c = math.cos(a), s = math.sin(a);
    return _Vec3(x, y * c - z * s, y * s + z * c);
  }

  _Vec3 rotY(double a) {
    final c = math.cos(a), s = math.sin(a);
    return _Vec3(x * c + z * s, y, -x * s + z * c);
  }
}

/// Projected 2D result (screen x, y, depth for sorting/opacity).
class _Proj {
  final double sx, sy, depth;
  const _Proj(this.sx, this.sy, this.depth);
}

/// Edge between two vertex indices.
class _Edge {
  final int a, b;
  const _Edge(this.a, this.b);
}

/// Depth-sorted edge ready to draw.
class _DrawEdge {
  final Offset p1, p2;
  final double depth;
  const _DrawEdge(this.p1, this.p2, this.depth);
}

// ─── Geometry builders ───────────────────────────────────────────────────────

List<_Vec3> _buildCube(double r) {
  return [
    _Vec3(-r, -r, -r),
    _Vec3(r, -r, -r),
    _Vec3(r, r, -r),
    _Vec3(-r, r, -r),
    _Vec3(-r, -r, r),
    _Vec3(r, -r, r),
    _Vec3(r, r, r),
    _Vec3(-r, r, r),
  ];
}

const List<_Edge> _cubeEdges = [
  _Edge(0, 1),
  _Edge(1, 2),
  _Edge(2, 3),
  _Edge(3, 0),
  _Edge(4, 5),
  _Edge(5, 6),
  _Edge(6, 7),
  _Edge(7, 4),
  _Edge(0, 4),
  _Edge(1, 5),
  _Edge(2, 6),
  _Edge(3, 7),
];

List<_Vec3> _buildIcosahedron(double r) {
  const phi = 1.618033988749895;
  final pts = [
    _Vec3(0, 1, phi),
    _Vec3(0, -1, phi),
    _Vec3(0, 1, -phi),
    _Vec3(0, -1, -phi),
    _Vec3(1, phi, 0),
    _Vec3(-1, phi, 0),
    _Vec3(1, -phi, 0),
    _Vec3(-1, -phi, 0),
    _Vec3(phi, 0, 1),
    _Vec3(-phi, 0, 1),
    _Vec3(phi, 0, -1),
    _Vec3(-phi, 0, -1),
  ];
  final scale = r / math.sqrt(1 + phi * phi);
  return pts.map((v) => _Vec3(v.x * scale, v.y * scale, v.z * scale)).toList();
}

const List<_Edge> _icosaEdges = [
  _Edge(0, 1),
  _Edge(0, 4),
  _Edge(0, 5),
  _Edge(0, 8),
  _Edge(0, 9),
  _Edge(1, 6),
  _Edge(1, 7),
  _Edge(1, 8),
  _Edge(1, 9),
  _Edge(2, 3),
  _Edge(2, 4),
  _Edge(2, 5),
  _Edge(2, 10),
  _Edge(2, 11),
  _Edge(3, 6),
  _Edge(3, 7),
  _Edge(3, 10),
  _Edge(3, 11),
  _Edge(4, 5),
  _Edge(4, 8),
  _Edge(4, 10),
  _Edge(5, 9),
  _Edge(5, 11),
  _Edge(6, 7),
  _Edge(6, 8),
  _Edge(6, 10),
  _Edge(7, 9),
  _Edge(7, 11),
  _Edge(8, 10),
  _Edge(9, 11),
];

/// Three inclined orbits (atom model) for Heiler/Alchemist.
List<_Vec3> _buildOrbitRings(double r, {int steps = 24}) {
  final pts = <_Vec3>[];
  for (int ring = 0; ring < 3; ring++) {
    final tiltX = ring * math.pi / 3.0;
    for (int i = 0; i < steps; i++) {
      final a = i / steps * math.pi * 2;
      final v = _Vec3(r * math.cos(a), r * math.sin(a), 0).rotX(tiltX);
      pts.add(v);
    }
  }
  return pts;
}

List<_Edge> _buildOrbitEdges({int steps = 24}) {
  final edges = <_Edge>[];
  for (int ring = 0; ring < 3; ring++) {
    final base = ring * steps;
    for (int i = 0; i < steps; i++) {
      edges.add(_Edge(base + i, base + (i + 1) % steps));
    }
  }
  return edges;
}

/// Double helix for Forscher.
List<_Vec3> _buildHelix(double r, double h, {int steps = 32}) {
  final pts = <_Vec3>[];
  for (int i = 0; i < steps; i++) {
    final t = i / steps;
    final a = t * math.pi * 4;
    pts.add(_Vec3(r * math.cos(a), h * (t - 0.5), r * math.sin(a)));
    pts.add(
      _Vec3(
        r * math.cos(a + math.pi),
        h * (t - 0.5),
        r * math.sin(a + math.pi),
      ),
    );
  }
  return pts;
}

List<_Edge> _buildHelixEdges({int steps = 32}) {
  final edges = <_Edge>[];
  for (int i = 0; i < steps - 1; i++) {
    edges.add(_Edge(i * 2, (i + 1) * 2));
    edges.add(_Edge(i * 2 + 1, (i + 1) * 2 + 1));
    if (i % 4 == 0) edges.add(_Edge(i * 2, i * 2 + 1));
  }
  return edges;
}

// ─── Public widget ────────────────────────────────────────────────────────────

class MentorAvatar3d extends StatelessWidget {
  final MentorPersonality personality;
  final Color accentColor;

  /// World key ('materie' | 'energie' | 'vorhang' | 'ursprung') -- drives the
  /// secondary palette + atmosphere so the avatar fits each world.
  final String world;
  final MentorAvatarState3d state;
  final double pulseValue;
  final double ringsProgress;
  final double thinkProgress;
  final double wavesProgress;
  final double size;

  const MentorAvatar3d({
    super.key,
    required this.personality,
    required this.accentColor,
    this.world = 'ursprung',
    required this.state,
    required this.pulseValue,
    required this.ringsProgress,
    required this.thinkProgress,
    required this.wavesProgress,
    this.size = 240,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _Avatar3dPainter(
          personality: personality,
          accentColor: accentColor,
          world: world,
          state: state,
          pulseValue: pulseValue,
          ringsProgress: ringsProgress,
          thinkProgress: thinkProgress,
          wavesProgress: wavesProgress,
        ),
      ),
    );
  }
}

/// Avatar animation state — mirrors [MentorAvatarState] without importing the model.
enum MentorAvatarState3d { idle, listening, thinking, speaking }

// ─── Custom painter ───────────────────────────────────────────────────────────

class _Avatar3dPainter extends CustomPainter {
  final MentorPersonality personality;
  final Color accentColor;
  final String world;
  final MentorAvatarState3d state;
  final double pulseValue;
  final double ringsProgress;
  final double thinkProgress;
  final double wavesProgress;

  const _Avatar3dPainter({
    required this.personality,
    required this.accentColor,
    required this.world,
    required this.state,
    required this.pulseValue,
    required this.ringsProgress,
    required this.thinkProgress,
    required this.wavesProgress,
  });

  /// World secondary tone -- blended into rim light + atmosphere so each world
  /// reads distinctly (Materie kuehl-blau, Energie violett, Vorhang gold,
  /// Ursprung tuerkis).
  Color get _worldSecondary => switch (world) {
        'vorhang' => const Color(0xFFFFD27D),
        'energie' => const Color(0xFFB388FF),
        'materie' => const Color(0xFF4FC3F7),
        _ => const Color(0xFF00FFD4),
      };

  // ── Projection ──────────────────────────────────────────────────

  static const double _fov = 320;
  static const double _zOffset = 400;

  _Proj _project(_Vec3 v) {
    final z = v.z + _zOffset;
    final scale = _fov / (z > 1 ? z : 1);
    return _Proj(v.x * scale, v.y * scale, v.z);
  }

  List<_DrawEdge> _projectEdges(
    List<_Vec3> verts,
    List<_Edge> edges,
    double cx,
    double cy,
  ) {
    final projected = verts.map(_project).toList();
    final result = <_DrawEdge>[];
    for (final e in edges) {
      final pa = projected[e.a];
      final pb = projected[e.b];
      result.add(
        _DrawEdge(
          Offset(cx + pa.sx, cy + pa.sy),
          Offset(cx + pb.sx, cy + pb.sy),
          (pa.depth + pb.depth) / 2,
        ),
      );
    }
    result.sort((a, b) => a.depth.compareTo(b.depth));
    return result;
  }

  // ── Rotation angles ─────────────────────────────────────────────

  double get _rotY => thinkProgress * math.pi * 2 + ringsProgress * math.pi;
  double get _rotX => 0.3 + math.sin(pulseValue * math.pi) * 0.12;

  List<_Vec3> _rotate(List<_Vec3> verts) {
    return verts.map((v) => v.rotX(_rotX).rotY(_rotY)).toList();
  }

  // ── Paint ───────────────────────────────────────────────────────

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final baseR = size.width * 0.34 * pulseValue;

    _drawHalo(canvas, cx, cy, baseR);
    _drawAtmosphere(canvas, cx, cy, baseR);
    _drawStateUnderlays(canvas, cx, cy, baseR);
    _draw3dStructure(canvas, cx, cy, baseR);
    _drawSphere(canvas, cx, cy, baseR);
    if (state == MentorAvatarState3d.speaking) {
      _drawSpeakingWaves(canvas, cx, cy, baseR);
    }
    _drawRimLight(canvas, cx, cy, baseR);
  }

  // ── Atmosphere ──────────────────────────────────────────────────
  // World-tinted depth: a soft secondary-coloured glow behind the orb plus a
  // gentle floating dust field -> richer, more lifelike than a flat circle.
  void _drawAtmosphere(Canvas canvas, double cx, double cy, double r) {
    // Secondary-coloured back glow (offset = light direction).
    canvas.drawCircle(
      Offset(cx + r * 0.25, cy + r * 0.2),
      r * 1.45,
      Paint()
        ..color = _worldSecondary.withValues(alpha: 0.06)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40),
    );
    // Floating dust motes orbiting slowly (always on -> feels alive).
    const n = 14;
    for (int i = 0; i < n; i++) {
      final seed = i * 12.9898;
      final ang = ringsProgress * math.pi * 2 * (0.3 + (i % 3) * 0.18) + seed;
      final rad = r * (1.18 + (math.sin(seed) * 0.5 + 0.5) * 0.9);
      final px = cx + math.cos(ang) * rad;
      final py = cy + math.sin(ang) * rad * 0.82;
      final tw = 0.5 + 0.5 * math.sin(pulseValue * math.pi * 2 + seed);
      canvas.drawCircle(
        Offset(px, py),
        0.8 + 1.6 * tw,
        Paint()
          ..color = (i.isEven ? accentColor : _worldSecondary)
              .withValues(alpha: 0.05 + 0.18 * tw),
      );
    }
  }

  // ── Halo ────────────────────────────────────────────────────────

  void _drawHalo(Canvas canvas, double cx, double cy, double r) {
    final alpha = state == MentorAvatarState3d.listening ? 0.15 : 0.07;
    canvas.drawCircle(
      Offset(cx, cy),
      r * 1.6,
      Paint()
        ..color = accentColor.withValues(alpha: alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 32),
    );
  }

  // ── State underlays ─────────────────────────────────────────────

  void _drawStateUnderlays(Canvas canvas, double cx, double cy, double r) {
    switch (state) {
      case MentorAvatarState3d.listening:
        _drawListeningRings(canvas, cx, cy, r);
      case MentorAvatarState3d.thinking:
        _drawThinkingParticles(canvas, cx, cy, r);
      case MentorAvatarState3d.idle:
      case MentorAvatarState3d.speaking:
        break;
    }
  }

  void _drawListeningRings(Canvas canvas, double cx, double cy, double r) {
    for (int i = 0; i < 3; i++) {
      final phase = (ringsProgress + i / 3.0) % 1.0;
      canvas.drawCircle(
        Offset(cx, cy),
        r * (1.15 + phase * 0.85),
        Paint()
          ..color = accentColor.withValues(alpha: (1.0 - phase) * 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );
    }
  }

  void _drawThinkingParticles(Canvas canvas, double cx, double cy, double r) {
    const n = 10;
    final orbit = r * 1.38;
    for (int i = 0; i < n; i++) {
      final angle = thinkProgress * math.pi * 2 + i / n * math.pi * 2;
      final phase = (i / n + thinkProgress) % 1.0;
      // 3D orbit with perspective tilt
      final pz = math.sin(angle + _rotX) * orbit * 0.4 + _zOffset;
      final scale = _fov / (pz > 1 ? pz : 1);
      final px = cx + math.cos(angle) * orbit * (_fov / _zOffset);
      final py = cy + math.sin(angle) * orbit * scale * 0.7;
      final dotR =
          (3.2 + 2.5 * math.sin(phase * math.pi)) * (scale / (_fov / _zOffset));
      canvas.drawCircle(
        Offset(px, py),
        dotR,
        Paint()
          ..color = accentColor.withValues(alpha: 0.45 + 0.35 * (1 - phase)),
      );
    }
  }

  // ── 3D wireframe structure ───────────────────────────────────────

  void _draw3dStructure(Canvas canvas, double cx, double cy, double r) {
    final geo = _geometryFor(r);
    final rotated = _rotate(geo.$1);
    final edges = _projectEdges(rotated, geo.$2, cx, cy);

    final maxZ = r + 1.0;
    for (final edge in edges) {
      // Depth-based opacity: back edges are dimmer
      final t = (edge.depth + maxZ) / (2 * maxZ);
      final alpha = 0.15 + t * 0.55;
      final strokeW = 0.8 + t * 1.4;
      canvas.drawLine(
        edge.p1,
        edge.p2,
        Paint()
          ..color = accentColor.withValues(alpha: alpha)
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  // Returns (vertices, edges) for the personality's geometry.
  // Using a positional record — allowed by CLAUDE.md rules.
  (List<_Vec3>, List<_Edge>) _geometryFor(double r) {
    final geo = r * 1.22;
    switch (personality) {
      case MentorPersonality.stratege:
        return (_buildCube(geo * 0.88), _cubeEdges);
      case MentorPersonality.forscher:
        return (_buildIcosahedron(geo * 0.95), _icosaEdges);
      case MentorPersonality.heiler:
        return (_buildOrbitRings(geo * 0.92), _buildOrbitEdges());
      case MentorPersonality.alchemist:
        return (_buildHelix(geo * 0.65, geo * 1.8), _buildHelixEdges());
    }
  }

  // ── Core sphere ──────────────────────────────────────────────────

  void _drawSphere(Canvas canvas, double cx, double cy, double r) {
    // Ground shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + r * 0.92),
        width: r * 1.55,
        height: r * 0.22,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    // Main sphere — richer Phong-like radial gradient (5 stops: key light ->
    // accent body -> terminator -> shadow) for a more realistic, rounded look.
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.32, -0.42),
          radius: 1.05,
          colors: [
            Color.alphaBlend(Colors.white.withValues(alpha: 0.75), accentColor),
            Color.alphaBlend(Colors.white.withValues(alpha: 0.18), accentColor),
            accentColor,
            Color.alphaBlend(Colors.black.withValues(alpha: 0.45), accentColor),
            Color.alphaBlend(Colors.black.withValues(alpha: 0.72), accentColor),
          ],
          stops: const [0.0, 0.22, 0.5, 0.8, 1.0],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)),
    );

    // Ambient occlusion: subtle darkening on the lower-right (shadow side).
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.45, 0.55),
          radius: 0.95,
          colors: [
            Colors.black.withValues(alpha: 0.28),
            Colors.black.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.7],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)),
    );

    // Subsurface scattering: warm inner core glow that pulses -> the orb looks
    // lit from within (organic, alive), not like a flat shaded ball.
    final coreC = Offset(cx + r * 0.05, cy + r * 0.08);
    canvas.drawCircle(
      coreC,
      r * (0.5 + 0.06 * math.sin(pulseValue * math.pi * 2)),
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color.alphaBlend(Colors.white.withValues(alpha: 0.4), accentColor)
                .withValues(alpha: 0.5),
            accentColor.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: coreC, radius: r * 0.55))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );

    // Rembrandt fill light: soft world-secondary bounce on the shadow side
    // (simulated reflected light -> more dimensional than pure black shadow).
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r - 1)),
    );
    canvas.drawCircle(
      Offset(cx + r * 0.55, cy + r * 0.5),
      r * 0.6,
      Paint()
        ..color = _worldSecondary.withValues(alpha: 0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );
    canvas.restore();

    // Environment reflection band: a thin bright arc near the top edge in the
    // world's secondary tone -> reads like a reflected horizon (glossy).
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r - 1)),
    );
    canvas.drawCircle(
      Offset(cx, cy - r * 0.34),
      r * 0.92,
      Paint()
        ..color = _worldSecondary.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.06
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.restore();

    // HDR specular bloom -- 3 layers (wide soft glow -> mid -> hot sharp core)
    // give a glossy, almost wet highlight that sells the curvature.
    final specC = Offset(cx - r * 0.3, cy - r * 0.32);
    canvas.drawCircle(
      specC,
      r * 0.28,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawCircle(
      specC,
      r * 0.14,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(
      Offset(cx - r * 0.24, cy - r * 0.26),
      r * 0.05,
      Paint()..color = Colors.white.withValues(alpha: 0.92),
    );
    // Tiny secondary catch-light (lower-left) -> ambient reflection.
    canvas.drawCircle(
      Offset(cx + r * 0.34, cy + r * 0.36),
      r * 0.045,
      Paint()..color = _worldSecondary.withValues(alpha: 0.5),
    );
  }

  // ── Speaking wave overlay ────────────────────────────────────────

  void _drawSpeakingWaves(Canvas canvas, double cx, double cy, double r) {
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r - 1)),
    );

    const bands = 6;
    final wavePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (int b = 0; b < bands; b++) {
      final yOff = cy - r * 0.55 + b * (r * 1.1 / (bands - 1));
      final phase = wavesProgress * math.pi * 2 + b * math.pi / bands;
      final path = Path();
      var first = true;
      for (double x = cx - r; x <= cx + r; x += 2) {
        final t = (x - (cx - r)) / (2 * r);
        final amp = r * 0.055 * math.sin(t * math.pi);
        final y = yOff + amp * math.sin(t * math.pi * 5 + phase);
        if (first) {
          path.moveTo(x, y);
          first = false;
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, wavePaint);
    }
    canvas.restore();
  }

  // ── Rim light ────────────────────────────────────────────────────

  void _drawRimLight(Canvas canvas, double cx, double cy, double r) {
    // Fresnel-style rim: brightest on the shadow side, blended accent ->
    // world-secondary, so the orb pops off the background like a lit sphere.
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..shader = SweepGradient(
          colors: [
            _worldSecondary.withValues(alpha: 0.5),
            accentColor.withValues(alpha: 0.2),
            _worldSecondary.withValues(alpha: 0.55),
            accentColor.withValues(alpha: 0.2),
            _worldSecondary.withValues(alpha: 0.5),
          ],
          stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = state == MentorAvatarState3d.speaking ? 3.2 : 2.2,
    );
  }

  @override
  bool shouldRepaint(_Avatar3dPainter old) =>
      old.state != state ||
      old.pulseValue != pulseValue ||
      old.ringsProgress != ringsProgress ||
      old.thinkProgress != thinkProgress ||
      old.wavesProgress != wavesProgress ||
      old.accentColor != accentColor ||
      old.personality != personality ||
      old.world != world;
}
