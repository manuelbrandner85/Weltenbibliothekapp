import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/spirit_extended_models.dart';

/// ============================================
/// ACHIEVEMENT UNLOCK POPUP
/// Animiertes Popup mit Konfetti-Effekt
/// ============================================

class AchievementUnlockPopup extends StatefulWidget {
  final Achievement achievement;
  final VoidCallback? onDismiss;

  const AchievementUnlockPopup({
    super.key,
    required this.achievement,
    this.onDismiss,
  });

  /// Show-Methode für einfache Nutzung
  static Future<void> show(
    BuildContext context,
    Achievement achievement,
  ) async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AchievementUnlockPopup(
        achievement: achievement,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  State<AchievementUnlockPopup> createState() => _AchievementUnlockPopupState();
}

class _AchievementUnlockPopupState extends State<AchievementUnlockPopup>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rotateController;
  late AnimationController _confettiController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();

    // Scale-Animation (Badge erscheint)
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    // Rotate-Animation (Badge dreht sich)
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _rotateAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.easeInOut),
    );

    // Konfetti-Animation
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Start-Animationen
    Future.delayed(const Duration(milliseconds: 100), () {
      _scaleController.forward();
      _rotateController.forward();
      _confettiController.forward();
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rotateController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          // Konfetti-Effekt
          AnimatedBuilder(
            animation: _confettiController,
            builder: (context, child) {
              return CustomPaint(
                painter: _ConfettiPainter(
                  animation: _confettiController.value,
                  color: widget.achievement.color,
                ),
                size: Size.infinite,
              );
            },
          ),

          // Popup-Content
          Center(
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                );
              },
              child: Container(
                constraints: const BoxConstraints(maxWidth: 320),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1A1A2E),
                      const Color(0xFF0F0F1E),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: widget.achievement.color.withValues(alpha: 0.3),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                  border: Border.all(
                    color: widget.achievement.color.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            widget.achievement.color.withValues(alpha: 0.2),
                            widget.achievement.color.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: Column(
                        children: [
                          // "ACHIEVEMENT UNLOCKED" Text
                          Text(
                            'ACHIEVEMENT FREIGESCHALTET!',
                            style: TextStyle(
                              color: widget.achievement.color,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Badge mit Animation
                          AnimatedBuilder(
                            animation: _rotateAnimation,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _rotateAnimation.value,
                                child: child,
                              );
                            },
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    widget.achievement.color,
                                    widget.achievement.color.withValues(alpha: 0.5),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: widget.achievement.color.withValues(alpha: 0.5),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Icon(
                                widget.achievement.icon,
                                size: 50,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Body
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Titel
                          Text(
                            widget.achievement.title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),

                          // Beschreibung
                          Text(
                            widget.achievement.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.7),
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),

                          // OK-Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: widget.onDismiss,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: widget.achievement.color,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'WEITER',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ============================================
/// KONFETTI-PAINTER
/// ============================================

class _ConfettiPainter extends CustomPainter {
  final double animation;
  final Color color;
  final math.Random random = math.Random(42); // Seed für Konsistenz

  _ConfettiPainter({
    required this.animation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Konfetti-Partikel
    for (int i = 0; i < 30; i++) {
      final double startX = random.nextDouble() * size.width;
      final double startY = -20;
      final double endY = size.height;
      final double sway = math.sin(animation * math.pi * 4 + i) * 50;

      final x = startX + sway;
      final y = startY + (endY - startY) * animation;

      // Farbe variieren
      final colorVariant = i % 3;
      if (colorVariant == 0) {
        paint.color = color.withValues(alpha: 0.7);
      } else if (colorVariant == 1) {
        paint.color = Colors.white.withValues(alpha: 0.7);
      } else {
        paint.color = color.withValues(alpha: 0.4);
      }

      // Rotation
      final rotation = animation * math.pi * 2 + i;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      // Konfetti-Form (Rechteck)
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: 8,
        height: 4,
      );
      canvas.drawRect(rect, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) {
    return animation != oldDelegate.animation;
  }
}
