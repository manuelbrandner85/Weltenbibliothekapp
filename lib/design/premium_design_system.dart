import 'package:flutter/material.dart';

/// WELTENBIBLIOTHEK PREMIUM DESIGN SYSTEM
/// Konsistente Design-Sprache für atemberaubend schöne Dashboards
///
/// Features:
/// - Glassmorphism & Neumorphism
/// - Smooth Animations
/// - Gradient Backgrounds
/// - Premium Typography
/// - Consistent Spacing

class PremiumDesignSystem {
  // ═══════════════════════════════════════════════════════════
  // COLORS - Premium Color Palette
  // ═══════════════════════════════════════════════════════════
  
  /// Energie Colors (Purple Theme)
  static const energiePrimary = Color(0xFF6B46C1);
  static const energieSecondary = Color(0xFF9333EA);
  static const energieAccent = Color(0xFFD946EF);
  static const energieLight = Color(0xFFF3E8FF);
  
  /// Materie Colors (Blue Theme)
  static const materiePrimary = Color(0xFF0D47A1);
  static const materieSecondary = Color(0xFF1565C0);
  static const materieAccent = Color(0xFF1976D2);
  static const materieLight = Color(0xFFE3F2FD);
  
  /// Neutral Colors
  static const backgroundDark = Color(0xFF0A0E27);
  static const backgroundLight = Color(0xFF1A1F3A);
  static const cardDark = Color(0xFF1E2139);
  static const cardLight = Color(0xFF252A43);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB4B7C9);
  static const divider = Color(0xFF2D3250);
  
  /// Status Colors
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);
  
  // ═══════════════════════════════════════════════════════════
  // GRADIENTS - Premium Gradient Definitions
  // ═══════════════════════════════════════════════════════════
  
  static const energieGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [energiePrimary, energieSecondary, energieAccent],
    stops: [0.0, 0.5, 1.0],
  );
  
  static const materieGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [materiePrimary, materieSecondary, materieAccent],
    stops: [0.0, 0.5, 1.0],
  );
  
  static const backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundDark, backgroundLight],
    stops: [0.0, 1.0],
  );
  
  static const glassmorphismOverlay = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x33FFFFFF),
      Color(0x11FFFFFF),
    ],
  );
  
  // ═══════════════════════════════════════════════════════════
  // TYPOGRAPHY - Premium Text Styles
  // ═══════════════════════════════════════════════════════════
  
  static const headingXL = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 1.2,
    letterSpacing: -0.5,
    color: textPrimary,
  );
  
  static const headingLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    height: 1.3,
    letterSpacing: -0.3,
    color: textPrimary,
  );
  
  static const headingMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: -0.2,
    color: textPrimary,
  );
  
  static const headingSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
    letterSpacing: 0,
    color: textPrimary,
  );
  
  static const bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
    letterSpacing: 0,
    color: textPrimary,
  );
  
  static const bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.5,
    letterSpacing: 0,
    color: textSecondary,
  );
  
  static const bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.4,
    letterSpacing: 0,
    color: textSecondary,
  );
  
  static const caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 0.5,
    color: textSecondary,
  );
  
  // ═══════════════════════════════════════════════════════════
  // SPACING - Consistent Spacing System
  // ═══════════════════════════════════════════════════════════
  
  static const double space1 = 4.0;   // 4px
  static const double space2 = 8.0;   // 8px
  static const double space3 = 12.0;  // 12px
  static const double space4 = 16.0;  // 16px
  static const double space5 = 20.0;  // 20px
  static const double space6 = 24.0;  // 24px
  static const double space8 = 32.0;  // 32px
  static const double space10 = 40.0; // 40px
  static const double space12 = 48.0; // 48px
  
  // ═══════════════════════════════════════════════════════════
  // BORDER RADIUS - Consistent Radius System
  // ═══════════════════════════════════════════════════════════
  
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusXXL = 24.0;
  static const double radiusFull = 9999.0;
  
  // ═══════════════════════════════════════════════════════════
  // SHADOWS - Premium Shadow Definitions
  // ═══════════════════════════════════════════════════════════
  
  static List<BoxShadow> get shadowSmall => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> get shadowMedium => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> get shadowLarge => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.2),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
  
  static List<BoxShadow> glassShadow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.3),
      blurRadius: 20,
      spreadRadius: -5,
      offset: const Offset(0, 10),
    ),
  ];
  
  // ═══════════════════════════════════════════════════════════
  // ANIMATIONS - Animation Durations & Curves
  // ═══════════════════════════════════════════════════════════
  
  static const durationFast = Duration(milliseconds: 150);
  static const durationMedium = Duration(milliseconds: 300);
  static const durationSlow = Duration(milliseconds: 500);
  static const durationXSlow = Duration(milliseconds: 800);
  
  static const curveDefault = Curves.easeInOutCubic;
  static const curveSmooth = Curves.easeOutQuart;
  static const curveSnappy = Curves.easeOutExpo;
  static const curveBounce = Curves.elasticOut;
  
  // ═══════════════════════════════════════════════════════════
  // GLASSMORPHISM - Premium Glass Effect
  // ═══════════════════════════════════════════════════════════
  
  static BoxDecoration glassDecoration({
    required Color color,
    double blur = 10,
    double opacity = 0.1,
    double borderOpacity = 0.2,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      color: color.withValues(alpha: opacity),
      borderRadius: borderRadius ?? BorderRadius.circular(radiusLarge),
      border: Border.all(
        color: Colors.white.withValues(alpha: borderOpacity),
        width: 1.5,
      ),
      boxShadow: glassShadow(color),
    );
  }
  
  // ═══════════════════════════════════════════════════════════
  // CARD STYLES - Premium Card Decorations
  // ═══════════════════════════════════════════════════════════
  
  static BoxDecoration cardDecoration({
    Color? color,
    Gradient? gradient,
    BorderRadius? borderRadius,
    List<BoxShadow>? shadows,
  }) {
    return BoxDecoration(
      color: color ?? cardDark,
      gradient: gradient,
      borderRadius: borderRadius ?? BorderRadius.circular(radiusLarge),
      boxShadow: shadows ?? shadowMedium,
    );
  }
  
  static BoxDecoration elevatedCardDecoration({
    required Color color,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: borderRadius ?? BorderRadius.circular(radiusLarge),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.4),
          blurRadius: 20,
          spreadRadius: -5,
          offset: const Offset(0, 10),
        ),
        ...shadowLarge,
      ],
    );
  }
}
