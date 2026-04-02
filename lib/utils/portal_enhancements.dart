import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Star class for dynamic starfield (v5.37 - Improvement 2.1)
class Star {
  final int index;
  late final double x;
  late final double y;
  late final double size;
  late final double speed;
  late final double twinkleOffset;
  late final double parallaxLayer; // 0.0 (far) to 1.0 (near)
  
  Star({required this.index}) {
    final random = math.Random(index);
    x = random.nextDouble();
    y = random.nextDouble();
    size = random.nextDouble() * 2 + 0.5; // 0.5-2.5
    speed = random.nextDouble() * 0.3 + 0.1; // 0.1-0.4
    twinkleOffset = random.nextDouble();
    parallaxLayer = random.nextDouble(); // Different depths
  }
}

/// StarfieldPainter for rendering dynamic stars (v5.37)
class StarfieldPainter extends CustomPainter {
  final double animation;
  final List<Star> stars;
  
  StarfieldPainter(this.animation, this.stars);
  
  @override
  void paint(Canvas canvas, Size size) {
    for (final star in stars) {
      // Calculate position with parallax movement
      final progress = (animation * star.speed + star.twinkleOffset) % 1.0;
      final x = star.x * size.width;
      final y = (star.y + progress * star.parallaxLayer * 0.1) % 1.0 * size.height;
      
      // Twinkle effect
      final twinkle = (math.sin(animation * math.pi * 2 + star.twinkleOffset * math.pi * 2) + 1) / 2;
      final alpha = 0.3 + twinkle * 0.7;
      
      // Draw star
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: alpha * star.parallaxLayer)
        ..strokeWidth = star.size
        ..strokeCap = StrokeCap.round;
      
      canvas.drawCircle(Offset(x, y), star.size / 2, paint);
      
      // Add subtle glow for larger stars
      if (star.size > 1.5) {
        final glowPaint = Paint()
          ..color = Colors.white.withValues(alpha: alpha * 0.2 * star.parallaxLayer)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, star.size);
        canvas.drawCircle(Offset(x, y), star.size, glowPaint);
      }
    }
  }
  
  @override
  bool shouldRepaint(StarfieldPainter oldDelegate) => true;
}

/// Helper function to get time-based portal colors (v5.37 - Improvement 5.3)
Color getAdaptivePortalColor(bool isPrimary) {
  final hour = DateTime.now().hour;
  
  if (hour >= 6 && hour < 12) {
    // Morning: Energetic bright colors
    return isPrimary 
        ? const Color(0xFF00AAFF) // Bright cyan-blue
        : const Color(0xFFAA00FF); // Bright purple
  } else if (hour >= 12 && hour < 18) {
    // Afternoon: Intense vibrant colors
    return isPrimary 
        ? const Color(0xFF0066FF) // Deep blue
        : const Color(0xFF8B00FF); // Vibrant purple
  } else if (hour >= 18 && hour < 22) {
    // Evening: Warm relaxed colors
    return isPrimary 
        ? const Color(0xFF4477FF) // Soft blue
        : const Color(0xFF9955FF); // Soft purple
  } else {
    // Night: Dark mystical colors
    return isPrimary 
        ? const Color(0xFF003D82) // Dark blue
        : const Color(0xFF5500AA); // Dark purple
  }
}

/// Get "Today Active" indicator based on time (v5.37 - Improvement 3.2)
String getTodayActiveWorld() {
  final hour = DateTime.now().hour;
  
  if (hour >= 6 && hour < 18) {
    return 'MATERIE'; // Daytime = Material world
  } else {
    return 'ENERGIE'; // Evening/Night = Energy world
  }
}

Color getTodayActiveColor() {
  return getTodayActiveWorld() == 'MATERIE'
      ? const Color(0xFF2196F3)
      : const Color(0xFF9C27B0);
}
