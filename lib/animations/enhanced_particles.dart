import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

/// ENHANCED PARTICLE SYSTEM - 200+ Partikel mit Trails
class EnhancedParticleSystem extends StatefulWidget {
  final Color primaryColor;
  final Color secondaryColor;
  final int particleCount;
  final double maxRadius;

  const EnhancedParticleSystem({
    super.key,
    required this.primaryColor,
    this.secondaryColor = Colors.white,
    this.particleCount = 250,
    this.maxRadius = 300,
  });

  @override
  State<EnhancedParticleSystem> createState() => _EnhancedParticleSystemState();
}

class _EnhancedParticleSystemState extends State<EnhancedParticleSystem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<EnhancedParticle> _particles;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    _particles = List.generate(
      widget.particleCount,
      (i) => EnhancedParticle(
        index: i,
        primaryColor: widget.primaryColor,
        secondaryColor: widget.secondaryColor,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: EnhancedParticlePainter(
            particles: _particles,
            progress: _controller.value,
            maxRadius: widget.maxRadius,
          ),
          child: Container(),
        );
      },
    );
  }
}

class EnhancedParticle {
  final int index;
  final Color primaryColor;
  final Color secondaryColor;
  
  late final double angle;
  late final double distance;
  late final double size;
  late final double speed;
  late final double phase;
  late final bool hasTrail;
  late final Color color;

  EnhancedParticle({
    required this.index,
    required this.primaryColor,
    required this.secondaryColor,
  }) {
    final random = math.Random(index);
    
    angle = random.nextDouble() * 2 * math.pi;
    distance = 0.4 + random.nextDouble() * 0.6; // 0.4-1.0
    size = 2 + random.nextDouble() * 6; // 2-8px
    speed = 0.5 + random.nextDouble() * 1.5; // Varied speed
    phase = random.nextDouble() * 2 * math.pi;
    hasTrail = random.nextBool();
    
    // Color variation
    color = random.nextBool() ? primaryColor : secondaryColor;
  }
}

class EnhancedParticlePainter extends CustomPainter {
  final List<EnhancedParticle> particles;
  final double progress;
  final double maxRadius;

  EnhancedParticlePainter({
    required this.particles,
    required this.progress,
    required this.maxRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (final particle in particles) {
      final animatedProgress = (progress * particle.speed + particle.phase) % 1.0;
      final currentAngle = particle.angle + animatedProgress * 2 * math.pi;
      final currentDistance = particle.distance * maxRadius * (1 - animatedProgress * 0.3);
      
      final x = center.dx + currentDistance * math.cos(currentAngle);
      final y = center.dy + currentDistance * math.sin(currentAngle);
      final position = Offset(x, y);

      // Particle opacity based on distance
      final opacity = 0.4 + (1 - animatedProgress) * 0.6;

      // Draw trail if enabled
      if (particle.hasTrail) {
        _drawTrail(canvas, center, position, particle, opacity);
      }

      // Draw particle
      _drawParticle(canvas, position, particle, opacity);
    }
  }

  void _drawParticle(Canvas canvas, Offset position, EnhancedParticle particle, double opacity) {
    final paint = Paint()
      ..color = particle.color.withValues(alpha: opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    canvas.drawCircle(position, particle.size, paint);

    // Inner glow
    final glowPaint = Paint()
      ..color = particle.color.withValues(alpha: opacity * 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawCircle(position, particle.size * 1.5, glowPaint);
  }

  void _drawTrail(Canvas canvas, Offset center, Offset position, EnhancedParticle particle, double opacity) {
    final path = Path();
    path.moveTo(center.dx, center.dy);
    path.lineTo(position.dx, position.dy);

    final trailPaint = Paint()
      ..shader = ui.Gradient.linear(
        center,
        position,
        [
          particle.color.withValues(alpha: 0.0),
          particle.color.withValues(alpha: opacity * 0.2),
        ],
      )
      ..strokeWidth = particle.size * 0.5
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawPath(path, trailPaint);
  }

  @override
  bool shouldRepaint(EnhancedParticlePainter oldDelegate) => progress != oldDelegate.progress;
}

/// FLOATING ORBS - Schwebende Licht-Kugeln
class FloatingOrbs extends StatefulWidget {
  final Color color;
  final int orbCount;

  const FloatingOrbs({
    super.key,
    required this.color,
    this.orbCount = 5,
  });

  @override
  State<FloatingOrbs> createState() => _FloatingOrbsState();
}

class _FloatingOrbsState extends State<FloatingOrbs>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Orb> _orbs;

  @override
  void initState() {
    super.initState();
    
    _controllers = List.generate(
      widget.orbCount,
      (i) => AnimationController(
        vsync: this,
        duration: Duration(seconds: 3 + i),
      )..repeat(reverse: true),
    );

    _orbs = List.generate(widget.orbCount, (i) => Orb(index: i));
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(widget.orbCount, (i) {
        return AnimatedBuilder(
          animation: _controllers[i],
          builder: (context, child) {
            final orb = _orbs[i];
            final offset = _controllers[i].value * orb.floatDistance;
            
            return Positioned(
              left: orb.x,
              top: orb.y + offset,
              child: Container(
                width: orb.size,
                height: orb.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      widget.color.withValues(alpha: 0.6),
                      widget.color.withValues(alpha: 0.2),
                      Colors.transparent,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

class Orb {
  final double x;
  final double y;
  final double size;
  final double floatDistance;

  Orb({required int index}) 
    : x = (index % 3) * 120.0 + 50,
      y = (index ~/ 3) * 150.0 + 100,
      size = 40 + (index % 3) * 20.0,
      floatDistance = 20 + (index % 2) * 15.0;
}
