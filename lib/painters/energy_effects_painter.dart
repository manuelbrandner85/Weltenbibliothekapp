import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Energy Beam Painter - Draws energy beams from portal to buttons (v5.37 - Improvement 2.3)
class EnergyBeamPainter extends CustomPainter {
  final double animation;
  final Offset portalCenter;
  final Offset materieButtonCenter;
  final Offset energieButtonCenter;
  final Color materieColor;
  final Color energieColor;
  
  EnergyBeamPainter({
    required this.animation,
    required this.portalCenter,
    required this.materieButtonCenter,
    required this.energieButtonCenter,
    this.materieColor = const Color(0xFF2196F3),
    this.energieColor = const Color(0xFF9C27B0),
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Beam to Materie Button
    _drawEnergyBeam(
      canvas,
      portalCenter,
      materieButtonCenter,
      materieColor,
      animation,
    );
    
    // Beam to Energie Button
    _drawEnergyBeam(
      canvas,
      portalCenter,
      energieButtonCenter,
      energieColor,
      animation + 0.5, // Offset animation for variety
    );
  }
  
  void _drawEnergyBeam(
    Canvas canvas,
    Offset start,
    Offset end,
    Color color,
    double animValue,
  ) {
    // Pulsating effect
    final pulse = (math.sin(animValue * math.pi * 2) + 1) / 2;
    final alpha = 0.1 + pulse * 0.15;
    
    // Draw multiple layers for depth
    for (int i = 0; i < 3; i++) {
      final layerAlpha = alpha * (1.0 - i * 0.3);
      final layerWidth = 2.0 + i * 1.5;
      
      final paint = Paint()
        ..color = color.withValues(alpha: layerAlpha)
        ..strokeWidth = layerWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      
      // Add slight curve for organic feel
      final controlPoint = Offset(
        (start.dx + end.dx) / 2 + math.sin(animValue * math.pi) * 20,
        (start.dy + end.dy) / 2,
      );
      
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(
          controlPoint.dx,
          controlPoint.dy,
          end.dx,
          end.dy,
        );
      
      canvas.drawPath(path, paint);
    }
    
    // Draw energy particles along beam
    for (int i = 0; i < 5; i++) {
      final particleProgress = ((animValue + i * 0.2) % 1.0);
      final particlePos = _getPointOnCurve(
        start,
        end,
        particleProgress,
        animValue,
      );
      
      final particlePaint = Paint()
        ..color = color.withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      
      canvas.drawCircle(particlePos, 3, particlePaint);
    }
  }
  
  Offset _getPointOnCurve(Offset start, Offset end, double t, double animValue) {
    final controlPoint = Offset(
      (start.dx + end.dx) / 2 + math.sin(animValue * math.pi) * 20,
      (start.dy + end.dy) / 2,
    );
    
    // Quadratic Bezier curve formula
    final x = math.pow(1 - t, 2) * start.dx +
        2 * (1 - t) * t * controlPoint.dx +
        math.pow(t, 2) * end.dx;
    final y = math.pow(1 - t, 2) * start.dy +
        2 * (1 - t) * t * controlPoint.dy +
        math.pow(t, 2) * end.dy;
    
    return Offset(x.toDouble(), y.toDouble());
  }
  
  @override
  bool shouldRepaint(EnergyBeamPainter oldDelegate) => true;
}

/// Portal Light Reflection on Buttons (v5.37 - Improvement 2.2)
class PortalLightReflection extends StatelessWidget {
  final Animation<double> animation;
  final Color glowColor;
  final Widget child;
  
  const PortalLightReflection({
    super.key,
    required this.animation,
    required this.glowColor,
    required this.child,
  });
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        // Pulsating glow effect
        final pulse = (math.sin(animation.value * math.pi * 2) + 1) / 2;
        final glowIntensity = 0.3 + pulse * 0.4;
        
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              // Animated glow from portal
              BoxShadow(
                color: glowColor.withValues(alpha: glowIntensity * 0.5),
                blurRadius: 30 + pulse * 20,
                spreadRadius: -5 + pulse * 10,
                offset: Offset(0, -10 + pulse * 5),
              ),
              // Secondary glow layer
              BoxShadow(
                color: glowColor.withValues(alpha: glowIntensity * 0.3),
                blurRadius: 50,
                spreadRadius: -10,
              ),
            ],
          ),
          child: this.child,
        );
      },
      child: child,
    );
  }
}
