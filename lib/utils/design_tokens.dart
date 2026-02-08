import 'package:flutter/material.dart';

/// 🎨 DESIGN TOKENS SYSTEM
/// Professional color palette and typography based on Material Design 3

class DesignTokens {
  DesignTokens._();
  
  // ============================================
  // COLOR PALETTE - MATERIE (MATTER)
  // ============================================
  
  static const MaterieColors materie = MaterieColors();
  
  // ============================================
  // COLOR PALETTE - ENERGIE (ENERGY)
  // ============================================
  
  static const EnergieColors energie = EnergieColors();
  
  // ============================================
  // NEUTRAL COLORS
  // ============================================
  
  static const NeutralColors neutral = NeutralColors();
  
  // ============================================
  // SEMANTIC COLORS
  // ============================================
  
  static const SemanticColors semantic = SemanticColors();
  
  // ============================================
  // TYPOGRAPHY
  // ============================================
  
  static const AppTypography typography = AppTypography();
  
  // ============================================
  // SPACING
  // ============================================
  
  static const AppSpacing spacing = AppSpacing();
  
  // ============================================
  // ELEVATION (SHADOWS)
  // ============================================
  
  static const AppElevation elevation = AppElevation();
}

// ============================================
// MATERIE COLORS
// ============================================

class MaterieColors {
  const MaterieColors();
  
  // Primary - Earth tones
  Color get primary => const Color(0xFF6B4423);
  Color get primaryLight => const Color(0xFF8B5E3C);
  Color get primaryDark => const Color(0xFF4A2E1A);
  
  // Secondary - Sky tones
  Color get secondary => const Color(0xFF5B9BD5);
  Color get secondaryLight => const Color(0xFF7FB3E0);
  Color get secondaryDark => const Color(0xFF3A7DBF);
  
  // Accent - Nature green
  Color get accent => const Color(0xFF7CB342);
  Color get accentLight => const Color(0xFF9CCC65);
  Color get accentDark => const Color(0xFF558B2F);
  
  // Surface
  Color get surface => const Color(0xFFF5F1ED);
  Color get surfaceVariant => const Color(0xFFE8E2DC);
  
  // Gradient
  LinearGradient get gradient => LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ============================================
// ENERGIE COLORS
// ============================================

class EnergieColors {
  const EnergieColors();
  
  // Primary - Cosmic purple
  Color get primary => const Color(0xFF7B2CBF);
  Color get primaryLight => const Color(0xFF9D4EDD);
  Color get primaryDark => const Color(0xFF5A189A);
  
  // Secondary - Electric blue
  Color get secondary => const Color(0xFF4CC9F0);
  Color get secondaryLight => const Color(0xFF72D8F7);
  Color get secondaryDark => const Color(0xFF2AB5DB);
  
  // Accent - Energy pink
  Color get accent => const Color(0xFFE91E63);
  Color get accentLight => const Color(0xFFF06292);
  Color get accentDark => const Color(0xFFC2185B);
  
  // Surface
  Color get surface => const Color(0xFF1A0F2E);
  Color get surfaceVariant => const Color(0xFF2D1B4E);
  
  // Gradient
  LinearGradient get gradient => LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ============================================
// NEUTRAL COLORS
// ============================================

class NeutralColors {
  const NeutralColors();
  
  // Grayscale
  Color get black => const Color(0xFF000000);
  Color get gray900 => const Color(0xFF212121);
  Color get gray800 => const Color(0xFF424242);
  Color get gray700 => const Color(0xFF616161);
  Color get gray600 => const Color(0xFF757575);
  Color get gray500 => const Color(0xFF9E9E9E);
  Color get gray400 => const Color(0xFFBDBDBD);
  Color get gray300 => const Color(0xFFE0E0E0);
  Color get gray200 => const Color(0xFFEEEEEE);
  Color get gray100 => const Color(0xFFF5F5F5);
  Color get white => const Color(0xFFFFFFFF);
  
  // Alpha variants
  Color blackAlpha(double opacity) => black.withValues(alpha: opacity);
  Color whiteAlpha(double opacity) => white.withValues(alpha: opacity);
}

// ============================================
// SEMANTIC COLORS
// ============================================

class SemanticColors {
  const SemanticColors();
  
  // Success
  Color get success => const Color(0xFF4CAF50);
  Color get successLight => const Color(0xFF81C784);
  Color get successDark => const Color(0xFF388E3C);
  
  // Warning
  Color get warning => const Color(0xFFFF9800);
  Color get warningLight => const Color(0xFFFFB74D);
  Color get warningDark => const Color(0xFFF57C00);
  
  // Error
  Color get error => const Color(0xFFF44336);
  Color get errorLight => const Color(0xFFE57373);
  Color get errorDark => const Color(0xFFD32F2F);
  
  // Info
  Color get info => const Color(0xFF2196F3);
  Color get infoLight => const Color(0xFF64B5F6);
  Color get infoDark => const Color(0xFF1976D2);
}

// ============================================
// TYPOGRAPHY
// ============================================

class AppTypography {
  const AppTypography();
  
  // Display (Extra Large headings)
  TextStyle get displayLarge => const TextStyle(
    fontSize: 57,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
    height: 1.12,
  );
  
  TextStyle get displayMedium => const TextStyle(
    fontSize: 45,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.16,
  );
  
  TextStyle get displaySmall => const TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.22,
  );
  
  // Headline (Large headings)
  TextStyle get headlineLarge => const TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.25,
  );
  
  TextStyle get headlineMedium => const TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.29,
  );
  
  TextStyle get headlineSmall => const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.33,
  );
  
  // Title (Medium headings)
  TextStyle get titleLarge => const TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.27,
  );
  
  TextStyle get titleMedium => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
    height: 1.50,
  );
  
  TextStyle get titleSmall => const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
  );
  
  // Body (Regular text)
  TextStyle get bodyLarge => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.50,
  );
  
  TextStyle get bodyMedium => const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
  );
  
  TextStyle get bodySmall => const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
  );
  
  // Label (Buttons, tabs)
  TextStyle get labelLarge => const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
  );
  
  TextStyle get labelMedium => const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.33,
  );
  
  TextStyle get labelSmall => const TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.45,
  );
}

// ============================================
// SPACING
// ============================================

class AppSpacing {
  const AppSpacing();
  
  // Base spacing unit: 4px
  static const double _unit = 4.0;
  
  double get none => 0;
  double get xxs => _unit; // 4px
  double get xs => _unit * 2; // 8px
  double get sm => _unit * 3; // 12px
  double get md => _unit * 4; // 16px
  double get lg => _unit * 6; // 24px
  double get xl => _unit * 8; // 32px
  double get xxl => _unit * 12; // 48px
  double get xxxl => _unit * 16; // 64px
  
  // Padding presets
  EdgeInsets get paddingXS => EdgeInsets.all(xs);
  EdgeInsets get paddingSM => EdgeInsets.all(sm);
  EdgeInsets get paddingMD => EdgeInsets.all(md);
  EdgeInsets get paddingLG => EdgeInsets.all(lg);
  EdgeInsets get paddingXL => EdgeInsets.all(xl);
}

// ============================================
// ELEVATION (SHADOWS)
// ============================================

class AppElevation {
  const AppElevation();
  
  // Material Design 3 elevation levels
  List<BoxShadow> get level0 => [];
  
  List<BoxShadow> get level1 => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];
  
  List<BoxShadow> get level2 => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];
  
  List<BoxShadow> get level3 => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.10),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];
  
  List<BoxShadow> get level4 => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      blurRadius: 12,
      offset: const Offset(0, 6),
    ),
  ];
  
  List<BoxShadow> get level5 => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.14),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];
}

// ============================================
// THEME DATA GENERATOR
// ============================================

class AppThemes {
  AppThemes._();
  
  /// Materie Light Theme
  static ThemeData materieLight() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: DesignTokens.materie.primary,
        secondary: DesignTokens.materie.secondary,
        surface: DesignTokens.materie.surface,
        error: DesignTokens.semantic.error,
      ),
      textTheme: TextTheme(
        displayLarge: DesignTokens.typography.displayLarge,
        displayMedium: DesignTokens.typography.displayMedium,
        displaySmall: DesignTokens.typography.displaySmall,
        headlineLarge: DesignTokens.typography.headlineLarge,
        headlineMedium: DesignTokens.typography.headlineMedium,
        headlineSmall: DesignTokens.typography.headlineSmall,
        titleLarge: DesignTokens.typography.titleLarge,
        titleMedium: DesignTokens.typography.titleMedium,
        titleSmall: DesignTokens.typography.titleSmall,
        bodyLarge: DesignTokens.typography.bodyLarge,
        bodyMedium: DesignTokens.typography.bodyMedium,
        bodySmall: DesignTokens.typography.bodySmall,
        labelLarge: DesignTokens.typography.labelLarge,
        labelMedium: DesignTokens.typography.labelMedium,
        labelSmall: DesignTokens.typography.labelSmall,
      ),
    );
  }
  
  /// Energie Dark Theme
  static ThemeData energieDark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: DesignTokens.energie.primary,
        secondary: DesignTokens.energie.secondary,
        surface: DesignTokens.energie.surface,
        error: DesignTokens.semantic.error,
      ),
      textTheme: TextTheme(
        displayLarge: DesignTokens.typography.displayLarge,
        displayMedium: DesignTokens.typography.displayMedium,
        displaySmall: DesignTokens.typography.displaySmall,
        headlineLarge: DesignTokens.typography.headlineLarge,
        headlineMedium: DesignTokens.typography.headlineMedium,
        headlineSmall: DesignTokens.typography.headlineSmall,
        titleLarge: DesignTokens.typography.titleLarge,
        titleMedium: DesignTokens.typography.titleMedium,
        titleSmall: DesignTokens.typography.titleSmall,
        bodyLarge: DesignTokens.typography.bodyLarge,
        bodyMedium: DesignTokens.typography.bodyMedium,
        bodySmall: DesignTokens.typography.bodySmall,
        labelLarge: DesignTokens.typography.labelLarge,
        labelMedium: DesignTokens.typography.labelMedium,
        labelSmall: DesignTokens.typography.labelSmall,
      ),
    );
  }
}
