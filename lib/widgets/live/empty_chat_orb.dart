// Empty-State fuer Live-Chat Raeume:
// Atmender Welt-Orb (Materie rot / Energie lila) statt generisches Bubble-Icon.

import 'dart:math' as math;
import 'package:flutter/material.dart';

class EmptyChatOrb extends StatefulWidget {
  final String world; // 'materie' | 'energie' | ...
  final String roomName;
  final String? hint;

  const EmptyChatOrb({
    super.key,
    required this.world,
    required this.roomName,
    this.hint,
  });

  @override
  State<EmptyChatOrb> createState() => _EmptyChatOrbState();
}

class _EmptyChatOrbState extends State<EmptyChatOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  Color get _accent {
    switch (widget.world) {
      case 'materie':
        return const Color(0xFFE53935);
      case 'energie':
        return const Color(0xFF9B51E0);
      case 'vorhang':
        return const Color(0xFFC9A84C);
      case 'ursprung':
        return const Color(0xFF00D4AA);
      default:
        return const Color(0xFF9B51E0);
    }
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) {
                final t = Curves.easeInOut.transform(_ctrl.value);
                final scale = 0.92 + t * 0.16;
                final glow = 0.35 + t * 0.45;
                return SizedBox(
                  width: 140,
                  height: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 140 * scale,
                        height: 140 * scale,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              accent.withValues(alpha: glow * 0.55),
                              accent.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              accent.withValues(alpha: 0.85),
                              accent.withValues(alpha: 0.25),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: glow),
                              blurRadius: 28,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      Transform.rotate(
                        angle: _ctrl.value * 2 * math.pi,
                        child: CustomPaint(
                          size: const Size(140, 140),
                          painter: _SparkRingPainter(
                            color: Colors.white.withValues(alpha: 0.65),
                            progress: t,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            const Text(
              'Hier ist es noch still.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.hint ?? 'Sei der/die Erste in ${widget.roomName}.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: accent.withValues(alpha: 0.3),
                  width: 0.6,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_downward_rounded,
                      size: 14, color: accent.withValues(alpha: 0.9)),
                  const SizedBox(width: 6),
                  Text(
                    'Tippe unten und schreibe los',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 11,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SparkRingPainter extends CustomPainter {
  final Color color;
  final double progress;
  _SparkRingPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.48;
    final paint = Paint()..color = color;
    for (int i = 0; i < 6; i++) {
      final angle = i * (math.pi * 2 / 6);
      final r = radius + math.sin(progress * math.pi + i) * 4;
      final p = Offset(
        center.dx + math.cos(angle) * r,
        center.dy + math.sin(angle) * r,
      );
      canvas.drawCircle(p, 1.6, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparkRingPainter old) =>
      old.progress != progress || old.color != color;
}
