import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/wb_cinematic_tokens.dart';

/// Ambient floating particles overlay for world screens.
///
/// Renders subtle, slowly drifting luminous dots that match the world palette.
/// Uses a single `CustomPainter` with periodic animation for GPU efficiency.
/// Wrap with `RepaintBoundary` + `IgnorePointer` externally if needed.
class WBAmbientParticles extends StatefulWidget {
  final WBWorld world;
  final int count;
  final double maxRadius;
  final double speed;

  const WBAmbientParticles({
    super.key,
    this.world = WBWorld.neutral,
    this.count = 40,
    this.maxRadius = 2.5,
    this.speed = 0.3,
  });

  @override
  State<WBAmbientParticles> createState() => _WBAmbientParticlesState();
}

class _WBAmbientParticlesState extends State<WBAmbientParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_Particle> _particles;
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _particles = List.generate(widget.count, (_) => _Particle.random(_rng));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.wb.palette(widget.world);

    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) => CustomPaint(
            painter: _ParticlePainter(
              particles: _particles,
              color: palette.primary,
              time: _ctrl.value,
              maxRadius: widget.maxRadius,
              speed: widget.speed,
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _Particle {
  double x, y, dx, dy, radius, phase;

  _Particle({
    required this.x,
    required this.y,
    required this.dx,
    required this.dy,
    required this.radius,
    required this.phase,
  });

  factory _Particle.random(Random rng) => _Particle(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        dx: (rng.nextDouble() - 0.5) * 2,
        dy: (rng.nextDouble() - 0.5) * 2,
        radius: 0.5 + rng.nextDouble() * 2.0,
        phase: rng.nextDouble() * 2 * pi,
      );
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final Color color;
  final double time;
  final double maxRadius;
  final double speed;

  _ParticlePainter({
    required this.particles,
    required this.color,
    required this.time,
    required this.maxRadius,
    required this.speed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      final t = time * speed;
      final px = ((p.x + p.dx * t) % 1.0) * size.width;
      final py = ((p.y + p.dy * t) % 1.0) * size.height;
      final alpha = (0.15 + 0.25 * sin(time * 2 * pi + p.phase)).clamp(0.0, 1.0);
      final r = p.radius * (0.6 + 0.4 * sin(time * 2 * pi * 0.5 + p.phase));

      paint.color = color.withValues(alpha: alpha);
      canvas.drawCircle(Offset(px, py), r.clamp(0.3, maxRadius), paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.time != time;
}
