import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'enhanced_particles.dart';

/// ULTRA-REALISTISCHER PORTAL WARP EFFEKT
/// Der Nutzer wird in die Welt "hineingezogen" mit:
/// - Vortex-Rotation (Spirale)
/// - Scale-Animation (größer werdend)
/// - Opacity-Fade
/// - Blur-Effekt
/// - Partikel-Sog
class PortalWarpTransition extends StatefulWidget {
  final Widget child;
  final Color portalColor;
  final VoidCallback? onComplete;

  const PortalWarpTransition({
    super.key,
    required this.child,
    required this.portalColor,
    this.onComplete,
  });

  @override
  State<PortalWarpTransition> createState() => _PortalWarpTransitionState();
}

class _PortalWarpTransitionState extends State<PortalWarpTransition>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _blurAnimation;
  late Animation<double> _vortexAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Vortex Rotation - 3 volle Umdrehungen
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 6 * math.pi, // 3 Rotationen
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.8, curve: Curves.easeInCubic),
    ));

    // Scale - Von klein zu groß (Zoom-In-Effekt)
    _scaleAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    // Opacity - Fade In
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
    ));

    // Blur - Stark verschwommen zu scharf
    _blurAnimation = Tween<double>(
      begin: 20.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    // Vortex Spiral - Radiale Verzerrung
    _vortexAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeInQuad),
    ));

    _controller.forward().then((_) {
      if (widget.onComplete != null) {
        widget.onComplete!();
      }
    });
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
        return Stack(
          children: [
            // Portal Vortex Background
            _buildVortexBackground(),
            
            // ENHANCED Portal Particles mit Trails
            EnhancedParticleSystem(
              particleCount: 150,
              primaryColor: widget.portalColor,
              secondaryColor: widget.portalColor.withValues(alpha: 0.5),
              maxRadius: 400,
            ),
            
            // Portal Particles (Original)
            _buildPortalParticles(),
            
            // Main Content mit Warp-Effekt
            Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.rotate(
                angle: _rotationAnimation.value,
                child: Opacity(
                  opacity: _opacityAnimation.value,
                  child: ClipRRect(
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(
                        sigmaX: _blurAnimation.value,
                        sigmaY: _blurAnimation.value,
                      ),
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            ),
            
            // Portal Glow Overlay
            if (_vortexAnimation.value > 0.1)
              _buildPortalGlow(),
          ],
        );
      },
    );
  }

  Widget _buildVortexBackground() {
    return Positioned.fill(
      child: CustomPaint(
        painter: VortexPainter(
          progress: _vortexAnimation.value,
          color: widget.portalColor,
        ),
      ),
    );
  }

  Widget _buildPortalParticles() {
    return Positioned.fill(
      child: CustomPaint(
        painter: PortalParticlesPainter(
          progress: 1.0 - _vortexAnimation.value,
          color: widget.portalColor,
        ),
      ),
    );
  }

  Widget _buildPortalGlow() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [
              widget.portalColor.withValues(alpha: 0.3 * _vortexAnimation.value),
              widget.portalColor.withValues(alpha: 0.1 * _vortexAnimation.value),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

/// Vortex Spiral Painter - Schwarzes Loch Effekt
class VortexPainter extends CustomPainter {
  final double progress;
  final Color color;

  VortexPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress < 0.05) return;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.sqrt(size.width * size.width + size.height * size.height) / 2;

    // Vortex Spiral Linien
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * math.pi;
      final spiralPaint = Paint()
        ..color = color.withValues(alpha: 0.3 * progress)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(center.dx, center.dy);

      for (double r = 0; r < maxRadius * progress; r += 5) {
        final spiralAngle = angle + (r / maxRadius) * 4 * math.pi * progress;
        final x = center.dx + r * math.cos(spiralAngle);
        final y = center.dy + r * math.sin(spiralAngle);
        path.lineTo(x, y);
      }

      canvas.drawPath(path, spiralPaint);
    }

    // Zentrum Glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.6 * progress),
          color.withValues(alpha: 0.3 * progress),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 100 * progress));

    canvas.drawCircle(center, 100 * progress, glowPaint);
  }

  @override
  bool shouldRepaint(VortexPainter oldDelegate) => progress != oldDelegate.progress;
}

/// Portal Particles - Fliegende Licht-Partikel
class PortalParticlesPainter extends CustomPainter {
  final double progress;
  final Color color;
  final List<Particle> particles;

  PortalParticlesPainter({required this.progress, required this.color})
      : particles = List.generate(50, (i) => Particle(i));

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (final particle in particles) {
      final angle = particle.angle + progress * 2 * math.pi;
      final distance = particle.distance * (1 - progress) * (math.min(size.width, size.height) / 2);
      
      final x = center.dx + distance * math.cos(angle);
      final y = center.dy + distance * math.sin(angle);

      final particleSize = 3 + particle.size * (1 - progress) * 5;
      final opacity = (1 - progress) * 0.8;

      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      canvas.drawCircle(Offset(x, y), particleSize, paint);
    }
  }

  @override
  bool shouldRepaint(PortalParticlesPainter oldDelegate) => progress != oldDelegate.progress;
}

class Particle {
  final double angle;
  final double distance;
  final double size;

  Particle(int seed)
      : angle = (seed * 137.5) * (math.pi / 180),
        distance = 0.3 + (seed % 7) / 10,
        size = (seed % 3) / 3;
}
