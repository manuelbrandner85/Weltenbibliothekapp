import 'package:flutter/material.dart';

/// Premium Typografie für Weltenbibliothek
/// Enthält: Variable Fonts, optimiertes Letter-Spacing, Line-Height, Text-Shadows
class PremiumTextStyles {
  // MATERIE - Analytische Typografie
  static const TextStyle materieTitle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: 4.0,
    height: 1.3,
    color: Colors.white,
    shadows: [
      Shadow(
        color: Color(0xFF2196F3),
        blurRadius: 12,
        offset: Offset(0, 2),
      ),
    ],
  );

  static const TextStyle materieSubtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 2.0,
    color: Color(0xFF90CAF9),
    height: 1.5,
  );

  static const TextStyle materieCardTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: Colors.white,
    height: 1.4,
  );

  static const TextStyle materieBody = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.3,
    color: Color(0xFFB0BEC5),
    height: 1.6,
  );

  static const TextStyle materieBadge = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    color: Color(0xFF2196F3),
  );

  // ENERGIE - Spirituelle Typografie
  static const TextStyle energieTitle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: 4.0,
    height: 1.3,
    color: Colors.white,
    shadows: [
      Shadow(
        color: Color(0xFF9C27B0),
        blurRadius: 16,
        offset: Offset(0, 2),
      ),
      Shadow(
        color: Color(0xFFFFD700),
        blurRadius: 24,
        offset: Offset(0, 4),
      ),
    ],
  );

  static const TextStyle energieSubtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 3.0,
    color: Color(0xFFCE93D8),
    height: 1.5,
  );

  static const TextStyle energieCardTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    color: Colors.white,
    height: 1.4,
  );

  static const TextStyle energieBody = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    color: Color(0xFFE1BEE7),
    height: 1.7,
  );

  static const TextStyle energieBadge = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.5,
    color: Color(0xFF9C27B0),
  );

  // Portal - Cosmic Typografie
  static const TextStyle portalWorldLabel = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 3.0,
    color: Colors.white,
    shadows: [
      Shadow(
        color: Colors.white,
        blurRadius: 8,
        offset: Offset(0, 0),
      ),
    ],
  );

  static const TextStyle portalDescription = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 1.5,
    color: Colors.white70,
    height: 1.4,
  );

  // Community - Interaktive Typografie
  static const TextStyle communityUsername = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
    color: Colors.white,
  );

  static const TextStyle communityMessage = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    color: Color(0xFFDEDEDE),
    height: 1.5,
  );

  static const TextStyle communityTag = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  // Profile - Persönliche Typografie
  static const TextStyle profileName = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: Colors.white,
  );

  static const TextStyle profileInfo = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.3,
    color: Colors.white70,
  );

  // Button - Call-to-Action Typografie
  static const TextStyle buttonLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
    color: Colors.white,
  );

  static const TextStyle buttonLabelSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.0,
    color: Colors.white,
  );

  // Data Viz - Analytische Labels
  static const TextStyle dataLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    color: Color(0xFF90CAF9),
  );

  static const TextStyle dataValue = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.0,
    color: Colors.white,
    shadows: [
      Shadow(
        color: Color(0xFF2196F3),
        blurRadius: 8,
      ),
    ],
  );

  // Sacred Geometry - Mystische Labels
  static const TextStyle sacredLabel = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 2.0,
    color: Color(0xFFCE93D8),
  );

  // Timing - Animation Durations
  static const Duration fastAnimation = Duration(milliseconds: 150);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 600);
  static const Duration cosmicAnimation = Duration(milliseconds: 1200);
}

/// Premium Text-Gradient Effekt
class GradientText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final List<Color> gradientColors;

  const GradientText({
    super.key,
    required this.text,
    required this.style,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: gradientColors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: Text(
        text,
        style: style.copyWith(color: Colors.white),
      ),
    );
  }
}

/// Animated Glowing Text
class GlowingText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Color glowColor;
  final double maxGlowRadius;

  const GlowingText({
    super.key,
    required this.text,
    required this.style,
    required this.glowColor,
    this.maxGlowRadius = 20,
  });

  @override
  State<GlowingText> createState() => _GlowingTextState();
}

class _GlowingTextState extends State<GlowingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(
      begin: widget.maxGlowRadius * 0.5,
      end: widget.maxGlowRadius,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Text(
          widget.text,
          style: widget.style.copyWith(
            shadows: [
              Shadow(
                color: widget.glowColor,
                blurRadius: _glowAnimation.value,
                offset: const Offset(0, 0),
              ),
            ],
          ),
        );
      },
    );
  }
}
