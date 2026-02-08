/// Custom Particle Painter for Background Effects
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Particle class for animated background
class Particle {
  Offset position;
  final double radius;
  final Color color;
  final double velocityX;
  final double velocityY;
  double opacity;

  Particle({
    required this.position,
    required this.radius,
    required this.color,
    required this.velocityX,
    required this.velocityY,
    this.opacity = 1.0,
  });

  void update(Size size) {
    position = Offset(
      (position.dx + velocityX) % size.width,
      (position.dy + velocityY) % size.height,
    );
  }
}

/// Animated Particle Background Painter
class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final Animation<double> animation;

  ParticlePainter({
    required this.particles,
    required this.animation,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      // Update particle position
      particle.update(size);

      // Draw particle
      final paint = Paint()
        ..color = particle.color.withValues(alpha: particle.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(particle.position, particle.radius, paint);

      // Draw subtle glow
      final glowPaint = Paint()
        ..color = particle.color.withValues(alpha: particle.opacity * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawCircle(particle.position, particle.radius * 1.5, glowPaint);
    }

    // Draw connections between nearby particles
    _drawConnections(canvas, size);
  }

  void _drawConnections(Canvas canvas, Size size) {
    const double maxDistance = 150.0;
    
    for (int i = 0; i < particles.length; i++) {
      for (int j = i + 1; j < particles.length; j++) {
        final dx = particles[i].position.dx - particles[j].position.dx;
        final dy = particles[i].position.dy - particles[j].position.dy;
        final distance = math.sqrt(dx * dx + dy * dy);

        if (distance < maxDistance) {
          final opacity = (1 - distance / maxDistance) * 0.3;
          final paint = Paint()
            ..color = Colors.white.withValues(alpha: opacity)
            ..strokeWidth = 1;

          canvas.drawLine(
            particles[i].position,
            particles[j].position,
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;

  /// Generate random particles
  static List<Particle> generateParticles({
    required Size size,
    required int count,
    required Color color,
  }) {
    final random = math.Random();
    return List.generate(count, (index) {
      return Particle(
        position: Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
        radius: 2 + random.nextDouble() * 3,
        color: color,
        velocityX: (random.nextDouble() - 0.5) * 0.5,
        velocityY: (random.nextDouble() - 0.5) * 0.5,
        opacity: 0.3 + random.nextDouble() * 0.4,
      );
    });
  }
}

/// Shimmer Gradient Text Effect Painter
class ShimmerTextPainter extends CustomPainter {
  final String text;
  final TextStyle textStyle;
  final Animation<double> animation;
  final List<Color> gradientColors;

  ShimmerTextPainter({
    required this.text,
    required this.textStyle,
    required this.animation,
    required this.gradientColors,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    // Animated gradient position
    final gradientShader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: gradientColors,
      tileMode: TileMode.mirror,
      transform: GradientRotation(animation.value * 2 * math.pi),
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final textSpan = TextSpan(
      text: text,
      style: textStyle.copyWith(
        foreground: Paint()..shader = gradientShader,
      ),
    );
    
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: size.width);

    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(ShimmerTextPainter oldDelegate) => true;
}

/// Animated Number Counter Painter
class CounterPainter extends CustomPainter {
  final int currentValue;
  final int targetValue;
  final TextStyle textStyle;
  final Color color;

  CounterPainter({
    required this.currentValue,
    required this.targetValue,
    required this.textStyle,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final textSpan = TextSpan(
      text: currentValue.toString(),
      style: textStyle.copyWith(color: color),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: size.width);

    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(CounterPainter oldDelegate) {
    return oldDelegate.currentValue != currentValue ||
        oldDelegate.targetValue != targetValue;
  }
}

/// Glassmorphism Effect Painter
class GlassmorphismPainter extends CustomPainter {
  final Color backgroundColor;
  final double borderRadius;
  final double blurAmount;

  GlassmorphismPainter({
    required this.backgroundColor,
    required this.borderRadius,
    this.blurAmount = 10.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    // Background with blur effect
    final paint = Paint()
      ..color = backgroundColor
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurAmount);

    canvas.drawRRect(rect, paint);

    // Border
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRRect(rect, borderPaint);
  }

  @override
  bool shouldRepaint(GlassmorphismPainter oldDelegate) => false;
}
