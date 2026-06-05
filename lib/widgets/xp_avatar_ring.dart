// XpAvatarRing -- wraps any avatar widget with a circular XP-progress arc
// and a small level badge in the corner (Duolingo-style).
//
// FEATURE (H): Makes the user's level + progress to the next level visible
// directly on the avatar, anywhere the avatar is shown. Reusable: pass the
// avatar as [child], the progress 0..1 and the level.
//
// Usage:
//   XpAvatarRing(
//     progress: p.progressToNext,
//     level: p.level,
//     accent: gold,
//     size: 72,
//     child: CircleAvatar(...),
//   )

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/gamification_service.dart';

class XpAvatarRing extends StatelessWidget {
  /// Progress within the current level (0.0 .. 1.0).
  final double progress;

  /// Current level shown in the badge. If null, the badge is hidden.
  final int? level;

  /// World accent color for the ring + badge.
  final Color accent;

  /// Total outer diameter of the ring (the child is inset by [strokeWidth]+gap).
  final double size;

  /// Ring stroke width.
  final double strokeWidth;

  /// Whether to show the small level badge in the bottom-right corner.
  final bool showBadge;

  /// The avatar widget to wrap.
  final Widget child;

  const XpAvatarRing({
    super.key,
    required this.progress,
    required this.accent,
    required this.child,
    this.level,
    this.size = 72,
    this.strokeWidth = 3.5,
    this.showBadge = true,
  });

  /// Convenience constructor that reads progress + level from the gamification
  /// service for the given [world].
  factory XpAvatarRing.forWorld({
    Key? key,
    required String world,
    required Color accent,
    required Widget child,
    double size = 72,
    double strokeWidth = 3.5,
    bool showBadge = true,
  }) {
    final p = GamificationService().getProgress(world);
    return XpAvatarRing(
      key: key,
      progress: p.progressToNext,
      level: p.level,
      accent: accent,
      size: size,
      strokeWidth: strokeWidth,
      showBadge: showBadge,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final inner = size - (strokeWidth * 2) - 4;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Progress ring.
          SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _RingPainter(
                progress: progress.clamp(0.0, 1.0),
                accent: accent,
                strokeWidth: strokeWidth,
              ),
            ),
          ),
          // Avatar inset inside the ring.
          ClipOval(
            child: SizedBox(
              width: inner,
              height: inner,
              child: FittedBox(fit: BoxFit.cover, child: child),
            ),
          ),
          // Level badge bottom-right.
          if (showBadge && level != null)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent, accent.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: const Color(0xFF0A0A14), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Text(
                  'Lv $level',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color accent;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.accent,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track (background ring).
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.10);
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc.
    if (progress > 0) {
      final progressPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: 3 * math.pi / 2,
          colors: [accent.withValues(alpha: 0.7), accent],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, // start at top
        2 * math.pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.accent != accent ||
      old.strokeWidth != strokeWidth;
}
