import 'package:flutter/material.dart';

/// 🎨 WELTENBIBLIOTHEK - GLOBALES DESIGN-SYSTEM
/// 
/// Professionelles Theme mit konsistenten Farben, Typografie und Komponenten
/// für beide Welten (Materie & Energie)

class AppTheme {
  // ============================================
  // 🎨 PRIMÄRFARBEN PRO WELT
  // ============================================
  
  /// Materie-Welt: Blau (Wissen, Logik, Fakten)
  static const Color materieBlue = Color(0xFF2196F3);
  static const Color materieBlueDark = Color(0xFF1976D2);
  static const Color materieBlueLight = Color(0xFF64B5F6);
  
  /// Energie-Welt: Lila (Spiritualität, Mystik, Energie)
  static const Color energiePurple = Color(0xFF9C27B0);
  static const Color energiePurpleDark = Color(0xFF7B1FA2);
  static const Color energiePurpleLight = Color(0xFFCE93D8);
  
  // ============================================
  // 🌈 KATEGORIE-FARBEN (MATERIE)
  // ============================================
  
  static const Color geopolitikGreen = Color(0xFF4CAF50);
  static const Color medienRed = Color(0xFFFF5252);
  static const Color forschungPurple = Color(0xFF9C27B0);
  static const Color transparenzYellow = Color(0xFFFFEB3B);
  static const Color ueberwachungOrange = Color(0xFFFF9800);
  
  // ============================================
  // 🔮 KATEGORIE-FARBEN (ENERGIE)
  // ============================================
  
  static const Color kraftorteViolet = Color(0xFF9C27B0);
  static const Color leyLinesBlue = Color(0xFF2196F3);
  static const Color heiligeStaettenGreen = Color(0xFF4CAF50);
  static const Color spirituellYellow = Color(0xFFFFEB3B);
  static const Color vortexGold = Color(0xFFFFD700);
  
  // ============================================
  // 🔲 NEUTRALE FARBEN (UI)
  // ============================================
  
  static const Color backgroundDark = Color(0xFF0A0A0A);
  static const Color surfaceDark = Color(0xFF1A1A1A);
  static const Color surfaceLight = Color(0xFF2A2A2A);
  
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textHint = Color(0xFF707070);
  
  // ============================================
  // ⚠️ SIGNAL-FARBEN
  // ============================================
  
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color errorRed = Color(0xFFFF5252);
  static const Color warningYellow = Color(0xFFFFC107);
  static const Color infoBlue = Color(0xFF2196F3);
  
  // ============================================
  // 📐 SPACING SYSTEM (8px Grid)
  // ============================================
  
  static const double space1 = 4.0;
  static const double space2 = 8.0;
  static const double space3 = 12.0;
  static const double space4 = 16.0;
  static const double space5 = 20.0;
  static const double space6 = 24.0;
  static const double space8 = 32.0;
  static const double space10 = 40.0;
  static const double space12 = 48.0;
  
  // ============================================
  // 📏 BORDER-RADIUS
  // ============================================
  
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0;
  static const double radiusXLarge = 32.0;
  static const double radiusFull = 999.0;
  
  // ============================================
  // 🔤 TYPOGRAFIE-SYSTEM
  // ============================================
  
  /// Display (sehr große Überschriften)
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.5,
    height: 1.2,
    color: textPrimary,
  );
  
  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
    height: 1.3,
    color: textPrimary,
  );
  
  static const TextStyle displaySmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
    height: 1.3,
    color: textPrimary,
  );
  
  /// Headlines (Überschriften)
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
    height: 1.4,
    color: textPrimary,
  );
  
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    height: 1.4,
    color: textPrimary,
  );
  
  static const TextStyle headlineSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    height: 1.4,
    color: textPrimary,
  );
  
  /// Body (Fließtext)
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.6,
    color: textPrimary,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.6,
    color: textPrimary,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.5,
    color: textSecondary,
  );
  
  /// Labels (Buttons, Chips)
  static const TextStyle labelLarge = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
    height: 1.4,
    color: textPrimary,
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.4,
    color: textPrimary,
  );
  
  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.3,
    color: textSecondary,
  );
  
  // ============================================
  // 🎨 GRADIENT-PRESETS
  // ============================================
  
  /// Materie Gradient (Blau)
  static const LinearGradient materieGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0D47A1),
      Color(0xFF1976D2),
      Color(0xFF2196F3),
    ],
  );
  
  /// Energie Gradient (Lila/Pink)
  static const LinearGradient energieGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF4A148C),
      Color(0xFF7B1FA2),
      Color(0xFF9C27B0),
    ],
  );
  
  /// Dark Surface Gradient
  static LinearGradient get darkSurfaceGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.black.withValues(alpha: 0.85),
      Colors.black.withValues(alpha: 0.65),
      Colors.black.withValues(alpha: 0.50),
    ],
  );
  
  // ============================================
  // 💫 SHADOW-PRESETS
  // ============================================
  
  static List<BoxShadow> get shadowSmall => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.2),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> get shadowMedium => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.3),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> get shadowLarge => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.4),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];
  
  /// Colored Shadow (für Chips, Buttons)
  static List<BoxShadow> coloredShadow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.5),
      blurRadius: 16,
      spreadRadius: 2,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: color.withValues(alpha: 0.3),
      blurRadius: 28,
      spreadRadius: 4,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: Colors.white.withValues(alpha: 0.2),
      blurRadius: 4,
      offset: const Offset(0, -2),
    ),
  ];
  
  // ============================================
  // 🎯 HELPER METHODS
  // ============================================
  
  /// Gibt die Primärfarbe für eine Welt zurück
  static Color getWorldColor(String world) {
    switch (world.toLowerCase()) {
      case 'materie':
        return materieBlue;
      case 'energie':
        return energiePurple;
      default:
        return materieBlue;
    }
  }
  
  /// Gibt den Gradienten für eine Welt zurück
  static LinearGradient getWorldGradient(String world) {
    switch (world.toLowerCase()) {
      case 'materie':
        return materieGradient;
      case 'energie':
        return energieGradient;
      default:
        return materieGradient;
    }
  }
}
