import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Premium Sacred Geometry Widget
/// Enthält: Flower of Life, Golden Ratio Spiral, Sri Yantra, Chakra Wheels
class SacredGeometryWidget extends StatefulWidget {
  final String type; // 'flower', 'spiral', 'yantra', 'chakra'
  final double size;
  final Color primaryColor;
  final Color secondaryColor;
  final bool animate;

  const SacredGeometryWidget({
    super.key,
    required this.type,
    this.size = 120,
    this.primaryColor = const Color(0xFF9C27B0),
    this.secondaryColor = const Color(0xFFFFD700),
    this.animate = true,
  });

  @override
  State<SacredGeometryWidget> createState() => _SacredGeometryWidgetState();
}

class _SacredGeometryWidgetState extends State<SacredGeometryWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );
    if (widget.animate) {
      _controller.repeat();
    }
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
          size: Size(widget.size, widget.size),
          painter: _getGeometryPainter(),
        );
      },
    );
  }

  CustomPainter _getGeometryPainter() {
    switch (widget.type) {
      case 'flower':
        return FlowerOfLifePainter(
          progress: _controller.value,
          primaryColor: widget.primaryColor,
          secondaryColor: widget.secondaryColor,
        );
      case 'spiral':
        return GoldenRatioSpiralPainter(
          progress: _controller.value,
          primaryColor: widget.primaryColor,
          secondaryColor: widget.secondaryColor,
        );
      case 'yantra':
        return SriYantraPainter(
          progress: _controller.value,
          primaryColor: widget.primaryColor,
          secondaryColor: widget.secondaryColor,
        );
      case 'chakra':
        return ChakraWheelPainter(
          progress: _controller.value,
          primaryColor: widget.primaryColor,
          secondaryColor: widget.secondaryColor,
        );
      default:
        return FlowerOfLifePainter(
          progress: _controller.value,
          primaryColor: widget.primaryColor,
          secondaryColor: widget.secondaryColor,
        );
    }
  }
}

/// Flower of Life - Heilige Geometrie
class FlowerOfLifePainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color secondaryColor;

  FlowerOfLifePainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 4;

    // Outer Glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          primaryColor.withValues(alpha: 0.3 * progress),
          primaryColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.width / 2));
    canvas.drawCircle(center, size.width / 2, glowPaint);

    // Main circles in Flower of Life pattern
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = primaryColor.withValues(alpha: 0.8);

    // Center circle
    canvas.drawCircle(center, radius, paint);

    // 6 surrounding circles (hexagon pattern)
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60) * math.pi / 180 + (progress * 2 * math.pi);
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      // Gradient stroke
      final gradientPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..shader = SweepGradient(
          colors: [
            primaryColor,
            secondaryColor,
            primaryColor,
          ],
          transform: GradientRotation(progress * 2 * math.pi),
        ).createShader(Rect.fromCircle(center: Offset(x, y), radius: radius));

      canvas.drawCircle(Offset(x, y), radius, gradientPaint);

      // Inner glow points
      final pointPaint = Paint()
        ..color = secondaryColor.withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(x, y), 3, pointPaint);
    }

    // 12 outer petals
    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * math.pi / 180 - (progress * 2 * math.pi);
      final distance = radius * 1.73; // sqrt(3) * radius for perfect spacing
      final x = center.dx + distance * math.cos(angle);
      final y = center.dy + distance * math.sin(angle);

      final outerPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = secondaryColor.withValues(alpha: 0.4);

      canvas.drawCircle(Offset(x, y), radius * 0.5, outerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant FlowerOfLifePainter oldDelegate) => true;
}

/// Golden Ratio Spiral - Fibonacci Spirale
class GoldenRatioSpiralPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color secondaryColor;

  GoldenRatioSpiralPainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const phi = 1.618033988749; // Golden Ratio

    // Background glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          secondaryColor.withValues(alpha: 0.2),
          primaryColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.width / 2));
    canvas.drawCircle(center, size.width / 2, glowPaint);

    final path = Path();
    final spiralPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [
          primaryColor,
          secondaryColor,
          primaryColor,
        ],
        transform: GradientRotation(progress * 2 * math.pi),
      ).createShader(Rect.fromCircle(center: center, radius: size.width / 2));

    // Generate golden spiral
    double angle = progress * 4 * math.pi;
    double radius = 2.0;
    bool firstPoint = true;

    for (int i = 0; i < 200; i++) {
      final a = angle + i * 0.1;
      final r = radius * math.pow(phi, a / (math.pi / 2));

      if (r > size.width / 2) break;

      final x = center.dx + r * math.cos(a);
      final y = center.dy + r * math.sin(a);

      if (firstPoint) {
        path.moveTo(x, y);
        firstPoint = false;
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, spiralPaint);

    // Draw Fibonacci squares
    double squareSize = 5;
    for (int i = 0; i < 8; i++) {
      final a = progress * 2 * math.pi + i * math.pi / 4;
      final r = squareSize * math.pow(phi, i / 2);

      if (r > size.width / 2) break;

      final x = center.dx + r * math.cos(a);
      final y = center.dy + r * math.sin(a);

      final squarePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = secondaryColor.withValues(alpha: 0.3);

      canvas.drawRect(
        Rect.fromCenter(center: Offset(x, y), width: squareSize, height: squareSize),
        squarePaint,
      );

      squareSize *= phi;
    }
  }

  @override
  bool shouldRepaint(covariant GoldenRatioSpiralPainter oldDelegate) => true;
}

/// Sri Yantra - Heiliges Dreieck-Mandala
class SriYantraPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color secondaryColor;

  SriYantraPainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2.5;

    // Outer circles (3 layers)
    for (int i = 0; i < 3; i++) {
      final circlePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = primaryColor.withValues(alpha: 0.3 - i * 0.1);

      canvas.drawCircle(center, radius + i * 10, circlePaint);
    }

    // 9 interlocking triangles (core of Sri Yantra)
    final trianglePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeJoin = StrokeJoin.miter;

    // 5 downward triangles (Shakti - feminine)
    for (int i = 0; i < 5; i++) {
      final offset = i * 8.0;
      final rotation = progress * 2 * math.pi;

      trianglePaint.shader = LinearGradient(
        colors: [
          primaryColor,
          secondaryColor.withValues(alpha: 0.8),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

      final path = Path();
      final topY = center.dy - radius + offset;
      final bottomY = center.dy + radius - offset;
      final leftX = center.dx - (radius - offset) * math.cos(math.pi / 6);
      final rightX = center.dx + (radius - offset) * math.cos(math.pi / 6);

      // Rotate around center
      final c = math.cos(rotation);
      final s = math.sin(rotation);

      Offset rotate(Offset p) {
        final dx = p.dx - center.dx;
        final dy = p.dy - center.dy;
        return Offset(
          center.dx + dx * c - dy * s,
          center.dy + dx * s + dy * c,
        );
      }

      final p1 = rotate(Offset(center.dx, topY));
      final p2 = rotate(Offset(leftX, bottomY));
      final p3 = rotate(Offset(rightX, bottomY));

      path.moveTo(p1.dx, p1.dy);
      path.lineTo(p2.dx, p2.dy);
      path.lineTo(p3.dx, p3.dy);
      path.close();

      canvas.drawPath(path, trianglePaint);
    }

    // 4 upward triangles (Shiva - masculine)
    for (int i = 0; i < 4; i++) {
      final offset = i * 10.0;
      final rotation = -progress * 2 * math.pi;

      trianglePaint.shader = LinearGradient(
        colors: [
          secondaryColor,
          primaryColor.withValues(alpha: 0.8),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

      final path = Path();
      final topY = center.dy - radius + offset;
      final bottomY = center.dy + radius - offset;
      final leftX = center.dx - (radius - offset) * math.cos(math.pi / 6);
      final rightX = center.dx + (radius - offset) * math.cos(math.pi / 6);

      // Rotate around center
      final c = math.cos(rotation);
      final s = math.sin(rotation);

      Offset rotate(Offset p) {
        final dx = p.dx - center.dx;
        final dy = p.dy - center.dy;
        return Offset(
          center.dx + dx * c - dy * s,
          center.dy + dx * s + dy * c,
        );
      }

      final p1 = rotate(Offset(center.dx, bottomY));
      final p2 = rotate(Offset(leftX, topY));
      final p3 = rotate(Offset(rightX, topY));

      path.moveTo(p1.dx, p1.dy);
      path.lineTo(p2.dx, p2.dy);
      path.lineTo(p3.dx, p3.dy);
      path.close();

      canvas.drawPath(path, trianglePaint);
    }

    // Central point (Bindu)
    final binduPaint = Paint()
      ..color = secondaryColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, 4, binduPaint);

    final binduCorePaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, 2, binduCorePaint);
  }

  @override
  bool shouldRepaint(covariant SriYantraPainter oldDelegate) => true;
}

/// Chakra Wheel - Energiezentrum Visualisierung
class ChakraWheelPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color secondaryColor;

  ChakraWheelPainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2.8;

    // Outer energy glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          primaryColor.withValues(alpha: 0.4 * (0.5 + 0.5 * math.sin(progress * 2 * math.pi))),
          secondaryColor.withValues(alpha: 0.2 * (0.5 + 0.5 * math.cos(progress * 2 * math.pi))),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.width / 2));
    canvas.drawCircle(center, size.width / 2, glowPaint);

    // Main wheel
    final wheelPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..shader = SweepGradient(
        colors: [
          primaryColor,
          secondaryColor,
          primaryColor,
        ],
        transform: GradientRotation(progress * 2 * math.pi),
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, wheelPaint);

    // 8 petals (Anahata Chakra style)
    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * math.pi / 180 + (progress * 2 * math.pi);

      // Petal path
      final petalPath = Path();
      final petalRadius = radius * 0.4;
      final petalCenterX = center.dx + radius * math.cos(angle);
      final petalCenterY = center.dy + radius * math.sin(angle);

      petalPath.addOval(Rect.fromCenter(
        center: Offset(petalCenterX, petalCenterY),
        width: petalRadius,
        height: petalRadius * 1.8,
      ));

      final petalPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            secondaryColor.withValues(alpha: 0.6),
            primaryColor.withValues(alpha: 0.2),
          ],
        ).createShader(Rect.fromCenter(
          center: Offset(petalCenterX, petalCenterY),
          width: petalRadius * 2,
          height: petalRadius * 2,
        ));

      canvas.save();
      canvas.translate(petalCenterX, petalCenterY);
      canvas.rotate(angle);
      canvas.translate(-petalCenterX, -petalCenterY);
      canvas.drawPath(petalPath, petalPaint);
      canvas.restore();
    }

    // Inner circle
    final innerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = secondaryColor.withValues(alpha: 0.6);
    canvas.drawCircle(center, radius * 0.6, innerPaint);

    // Sacred symbol in center (OM)
    final symbolPaint = Paint()
      ..color = primaryColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    // Simple OM approximation with circles
    canvas.drawCircle(
      Offset(center.dx - 8, center.dy),
      6,
      symbolPaint,
    );
    canvas.drawCircle(
      Offset(center.dx + 8, center.dy - 6),
      4,
      symbolPaint,
    );

    final curvePath = Path();
    curvePath.moveTo(center.dx - 10, center.dy + 8);
    curvePath.quadraticBezierTo(
      center.dx,
      center.dy + 15,
      center.dx + 10,
      center.dy + 8,
    );
    canvas.drawPath(curvePath, Paint()..color = primaryColor..style = PaintingStyle.stroke..strokeWidth = 2);

    // Rotating energy dots
    for (int i = 0; i < 12; i++) {
      final dotAngle = (i * 30) * math.pi / 180 + (progress * 4 * math.pi);
      final dotRadius = radius * 0.8;
      final dotX = center.dx + dotRadius * math.cos(dotAngle);
      final dotY = center.dy + dotRadius * math.sin(dotAngle);

      final dotPaint = Paint()
        ..color = (i % 2 == 0 ? primaryColor : secondaryColor).withValues(alpha: 0.7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(Offset(dotX, dotY), 2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ChakraWheelPainter oldDelegate) => true;
}
