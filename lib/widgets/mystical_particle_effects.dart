import 'dart:math';
import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════
/// MYSTICAL PARTICLE EFFECTS WIDGET
/// ═══════════════════════════════════════════════════════════════
///
/// Features:
/// - Floating gold particles (sacred geometry)
/// - Animated glow effects
/// - Subtle shimmer for mystical ambiance
/// - Performance-optimized for mobile
/// - No external dependencies (pure Flutter)
/// ═══════════════════════════════════════════════════════════════

class MysticalParticleEffect extends StatefulWidget {
  final Widget child;
  final int particleCount;
  final Color particleColor;
  final double particleSize;
  final bool enabled;

  const MysticalParticleEffect({
    super.key,
    required this.child,
    this.particleCount = 20,
    this.particleColor = const Color(0xFFFFD700), // Gold
    this.particleSize = 2.0,
    this.enabled = true,
  });

  @override
  State<MysticalParticleEffect> createState() => _MysticalParticleEffectState();
}

class _MysticalParticleEffectState extends State<MysticalParticleEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    // Create particles
    _initializeParticles();

    // Animation controller for continuous movement
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _controller.addListener(() {
      if (mounted) {
        setState(() {
          _updateParticles();
        });
      }
    });
  }

  void _initializeParticles() {
    _particles.clear();
    for (int i = 0; i < widget.particleCount; i++) {
      _particles.add(
        Particle(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          speed: 0.0001 + _random.nextDouble() * 0.0003,
          size: widget.particleSize * (0.5 + _random.nextDouble()),
          opacity: 0.3 + _random.nextDouble() * 0.4,
          phase: _random.nextDouble() * 2 * pi,
        ),
      );
    }
  }

  void _updateParticles() {
    for (var particle in _particles) {
      // Slow upward movement
      particle.y -= particle.speed;

      // Slight horizontal oscillation
      particle.x += sin(particle.phase + _controller.value * 2 * pi) * 0.0005;

      // Wrap around screen
      if (particle.y < -0.1) {
        particle.y = 1.1;
        particle.x = _random.nextDouble();
      }
      if (particle.x < -0.1) particle.x = 1.1;
      if (particle.x > 1.1) particle.x = -0.1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return Stack(
      children: [
        // Child content
        widget.child,

        // Particle overlay
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: ParticlePainter(
                particles: _particles,
                color: widget.particleColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Particle data class
class Particle {
  double x;
  double y;
  double speed;
  double size;
  double opacity;
  double phase;

  Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.opacity,
    required this.phase,
  });
}

/// Custom painter for particles
class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final Color color;

  ParticlePainter({required this.particles, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = color.withValues(alpha: particle.opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, particle.size * 2);

      canvas.drawCircle(
        Offset(particle.x * size.width, particle.y * size.height),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// ═══════════════════════════════════════════════════════════════
/// GLOWING CONTAINER - Mystical glow effect for cards
/// ═══════════════════════════════════════════════════════════════

class GlowingContainer extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final double glowIntensity;
  final bool enabled;

  const GlowingContainer({
    super.key,
    required this.child,
    this.glowColor = const Color(0xFFFFD700), // Gold
    this.glowIntensity = 0.3,
    this.enabled = true,
  });

  @override
  State<GlowingContainer> createState() => _GlowingContainerState();
}

class _GlowingContainerState extends State<GlowingContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withValues(
                  alpha: widget.glowIntensity * _animation.value,
                ),
                blurRadius: 20 * _animation.value,
                spreadRadius: 5 * _animation.value,
              ),
            ],
          ),
          child: widget.child,
        );
      },
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// SHIMMER EFFECT - For loading states and mystical polish
/// ═══════════════════════════════════════════════════════════════

class ShimmerEffect extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final bool enabled;

  const ShimmerEffect({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFF1A1A2E),
    this.highlightColor = const Color(0xFFFFD700),
    this.enabled = true,
  });

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.baseColor,
                widget.highlightColor.withValues(alpha: 0.3),
                widget.baseColor,
              ],
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// SACRED GEOMETRY BACKGROUND - Mystical patterns
/// ═══════════════════════════════════════════════════════════════

class SacredGeometryBackground extends StatelessWidget {
  final Color color;
  final double opacity;

  const SacredGeometryBackground({
    super.key,
    this.color = const Color(0xFFFFD700),
    this.opacity = 0.1,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: SacredGeometryPainter(color: color.withValues(alpha: opacity)),
      size: Size.infinite,
    );
  }
}

class SacredGeometryPainter extends CustomPainter {
  final Color color;

  SacredGeometryPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = min(size.width, size.height) * 0.3;

    // Draw flower of life pattern (simplified)
    for (int i = 0; i < 6; i++) {
      final angle = (i * pi / 3) - pi / 2;
      final x = centerX + radius * cos(angle);
      final y = centerY + radius * sin(angle);

      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    // Center circle
    canvas.drawCircle(Offset(centerX, centerY), radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
