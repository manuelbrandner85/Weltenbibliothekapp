import 'package:flutter/material.dart';

/// App-weite Farb-Konstanten für konsistentes Dark Mode Design
/// 
/// VERWENDUNG:
/// ```dart
/// Container(color: AppColors.background)
/// Text('Hello', style: TextStyle(color: AppColors.textPrimary))
/// ```
class AppColors {
  AppColors._(); // Private constructor - nur statische Werte
  
  // 🎨 BACKGROUND COLORS
  static const Color background = Color(0xFF0A0A0A);  // Haupt-Hintergrund
  static const Color backgroundLight = Color(0xFF1A1A1A);  // Cards, Panels
  static const Color backgroundElevated = Color(0xFF2A2A2A);  // Elevated Cards
  
  // 🎨 WELT-FARBEN
  static const Color energiePurple = Color(0xFF9B51E0);  // Energie-Welt
  static const Color energiePurpleDark = Color(0xFF6A1B9A);
  static const Color energiePurpleLight = Color(0xFFCE93D8);
  
  static const Color materieBlue = Color(0xFF2196F3);  // Materie-Welt
  static const Color materieBlueDark = Color(0xFF1565C0);
  static const Color materieBlueLight = Color(0xFF64B5F6);
  
  static const Color materieRed = Color(0xFFE53935);  // Materie-Akzent
  static const Color materieRedDark = Color(0xFFC62828);
  static const Color materieRedLight = Color(0xFFEF5350);
  
  // 🎨 TEXT COLORS
  static const Color textPrimary = Colors.white;  // Haupt-Text
  static const Color textSecondary = Color(0xFFB0B0B0);  // Sekundär-Text
  static const Color textTertiary = Color(0xFF707070);  // Tertiär-Text
  static const Color textDisabled = Color(0xFF505050);  // Deaktiviert
  
  // 🎨 ACCENT COLORS
  static const Color success = Color(0xFF4CAF50);  // Erfolg
  static const Color warning = Color(0xFFFFC107);  // Warnung
  static const Color error = Color(0xFFF44336);  // Fehler
  static const Color info = Color(0xFF2196F3);  // Info
  
  // 🎨 BORDER & DIVIDER COLORS
  static const Color border = Color(0xFF333333);
  static const Color borderLight = Color(0xFF444444);
  static const Color divider = Color(0xFF2A2A2A);
  
  // 🎨 OVERLAY COLORS
  static Color overlay5 = Colors.white.withValues(alpha: 0.05);
  static Color overlay10 = Colors.white.withValues(alpha: 0.10);
  static Color overlay20 = Colors.white.withValues(alpha: 0.20);
  static Color overlay50 = Colors.white.withValues(alpha: 0.50);
  
  // 🎨 SHADOW COLORS
  static Color shadowLight = Colors.black.withValues(alpha: 0.1);
  static Color shadowMedium = Colors.black.withValues(alpha: 0.2);
  static Color shadowHeavy = Colors.black.withValues(alpha: 0.4);
  
  // 🎨 GRADIENT COLORS
  static const List<Color> energieGradient = [
    Color(0xFF9B51E0),
    Color(0xFF6A1B9A),
  ];
  
  static const List<Color> materieGradient = [
    Color(0xFF2196F3),
    Color(0xFF1565C0),
  ];
  
  static const List<Color> backgroundGradient = [
    Color(0xFF0A0A0A),
    Color(0xFF1A1A1A),
  ];
}

/// Spacing-Konstanten für konsistente Abstände
class AppSpacing {
  AppSpacing._();
  
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

/// Border Radius Konstanten
class AppBorderRadius {
  AppBorderRadius._();
  
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double round = 100.0;
  
  static BorderRadius get small => BorderRadius.circular(sm);
  static BorderRadius get medium => BorderRadius.circular(md);
  static BorderRadius get large => BorderRadius.circular(lg);
  static BorderRadius get extraLarge => BorderRadius.circular(xl);
  static BorderRadius get circular => BorderRadius.circular(round);
}

/// Icon Size Konstanten
class AppIconSize {
  AppIconSize._();
  
  static const double xs = 16.0;
  static const double sm = 20.0;
  static const double md = 24.0;
  static const double lg = 32.0;
  static const double xl = 48.0;
  static const double xxl = 64.0;
}

/// Animation Duration Konstanten
class AppDurations {
  AppDurations._();
  
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 1000);
}

/// Helper für konsistente Card-Dekoration
class AppCardDecoration {
  AppCardDecoration._();
  
  /// Standard Card Dekoration
  static BoxDecoration get standard => BoxDecoration(
    color: AppColors.backgroundLight,
    borderRadius: AppBorderRadius.medium,
    border: Border.all(
      color: AppColors.border,
      width: 1,
    ),
  );
  
  /// Elevated Card Dekoration
  static BoxDecoration get elevated => BoxDecoration(
    color: AppColors.backgroundElevated,
    borderRadius: AppBorderRadius.medium,
    boxShadow: [
      BoxShadow(
        color: AppColors.shadowMedium,
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );
  
  /// Energie-Welt Card
  static BoxDecoration get energie => BoxDecoration(
    color: AppColors.backgroundLight,
    borderRadius: AppBorderRadius.medium,
    border: Border.all(
      color: AppColors.energiePurple.withValues(alpha: 0.3),
      width: 1,
    ),
  );
  
  /// Materie-Welt Card
  static BoxDecoration get materie => BoxDecoration(
    color: AppColors.backgroundLight,
    borderRadius: AppBorderRadius.medium,
    border: Border.all(
      color: AppColors.materieBlue.withValues(alpha: 0.3),
      width: 1,
    ),
  );
}

/// Helper für konsistente Button-Styles
class AppButtonStyles {
  AppButtonStyles._();
  
  /// Primary Button Style
  static ButtonStyle get primary => ElevatedButton.styleFrom(
    backgroundColor: AppColors.energiePurple,
    foregroundColor: AppColors.textPrimary,
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: AppBorderRadius.medium,
    ),
  );
  
  /// Secondary Button Style
  static ButtonStyle get secondary => OutlinedButton.styleFrom(
    foregroundColor: AppColors.textPrimary,
    side: const BorderSide(color: AppColors.border),
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: AppBorderRadius.medium,
    ),
  );
}
