import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/wb_cinematic_tokens.dart';

/// 🎨 ENHANCED APP THEMES - UI/UX POLISH UPDATE
///
/// Features:
/// - WCAG AAA Contrast Ratios (7:1+)
/// - Smooth Dark/Light Mode Transitions
/// - Glassmorphism-Effects
/// - Consistent Spacing System (4px Grid)
/// - Professional Typography Scale
/// - Semantic Color System
/// - Weltenbibliothek-spezifische Farben (Energie & Materie)
/// - Advanced Animation Curves
/// - Responsive Breakpoints
/// - Accessibility Excellence

class EnhancedAppThemes {
  // ════════════════════════════════════════════════════════════
  // COLOR SYSTEM - WCAG AAA COMPLIANT
  // ════════════════════════════════════════════════════════════

  // Weltenbibliothek-Spezifische Farben
  // Energie-Welt (Spirituell, Bewusstsein)
  static const Color energiePrimary = Color(0xFF7E57C2); // Deep Purple 400
  static const Color energieSecondary = Color(0xFF26C6DA); // Cyan 400
  static const Color energieAccent = Color(0xFFAB47BC); // Purple 400
  static const Color energieGradientStart = Color(0xFF7E57C2);
  static const Color energieGradientEnd = Color(0xFF26C6DA);

  // Materie-Welt (Recherche, Fakten)
  static const Color materiePrimary = Color(0xFFE53935); // Red 600
  static const Color materieSecondary = Color(0xFFFF6F00); // Orange 900
  static const Color materieAccent = Color(0xFFFF5722); // Deep Orange 500
  static const Color materieGradientStart = Color(0xFFE53935);
  static const Color materieGradientEnd = Color(0xFFFF6F00);

  // Vorhang-Welt (Dunkle Psychologie & Elite-Strategien)
  static const Color vorhangPrimary = Color(0xFFC9A84C); // Gold
  static const Color vorhangSecondary = Color(0xFFFFD700); // Goldglanz
  static const Color vorhangAccent = Color(0xFFE0C872); // Helles Gold
  static const Color vorhangGradientStart = Color(0xFFC9A84C);
  static const Color vorhangGradientEnd = Color(0xFFFFD700);
  static const Color vorhangBackground = Color(0xFF000000); // Schwarz

  // Ursprung-Welt (Realitätserschaffung & CIA-Bewusstseins-Codes)
  static const Color ursprungPrimary = Color(0xFF00D4AA); // Cyan
  static const Color ursprungSecondary = Color(0xFF00FFD4); // Neon-Cyan
  static const Color ursprungAccent = Color(0xFF40E8C0); // Helles Cyan
  static const Color ursprungGradientStart = Color(0xFF00D4AA);
  static const Color ursprungGradientEnd = Color(0xFF00FFD4);
  static const Color ursprungBackground = Color(0xFF050510); // Tiefes Dunkel

  // Glassmorphism Colors
  static const Color glassDark = Color(0x33000000); // 20% black
  static const Color glassLight = Color(0x33FFFFFF); // 20% white
  static const Color glassBorder = Color(0x1AFFFFFF); // 10% white border

  // Light Mode Colors
  static const Color lightPrimary = Color(0xFF1E88E5); // Blue 600
  static const Color lightSecondary = Color(0xFF7E57C2); // Deep Purple 400
  static const Color lightBackground = Color(0xFFFAFAFA); // Grey 50
  static const Color lightSurface = Color(0xFFFFFFFF); // White
  static const Color lightError = Color(0xFFD32F2F); // Red 700
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightOnBackground =
      Color(0xFF1A1A1A); // Near Black (WCAG AAA)
  static const Color lightOnSurface = Color(0xFF1A1A1A);

  // Dark Mode Colors (Enhanced Contrast)
  static const Color darkPrimary =
      Color(0xFF64B5F6); // Blue 300 (lighter for dark bg)
  static const Color darkSecondary = Color(0xFFB39DDB); // Deep Purple 200
  static const Color darkBackground = Color(0xFF121212); // True Dark
  static const Color darkSurface = Color(0xFF1E1E1E); // Elevated Surface
  static const Color darkError =
      Color(0xFFEF5350); // Red 400 (lighter for dark bg)
  static const Color darkOnPrimary = Color(0xFF000000);
  static const Color darkOnBackground =
      Color(0xFFE8E8E8); // Light Grey (WCAG AAA)
  static const Color darkOnSurface = Color(0xFFE8E8E8);

  // ════════════════════════════════════════════════════════════
  // SPACING SYSTEM - 4px GRID
  // ════════════════════════════════════════════════════════════

  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;
  static const double space64 = 64.0;

  // ════════════════════════════════════════════════════════════
  // TYPOGRAPHY SCALE — Inter (Google Fonts)
  // ════════════════════════════════════════════════════════════

  static TextTheme get textTheme => GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
              fontSize: 57, fontWeight: FontWeight.w400, letterSpacing: -0.25),
          displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w400),
          displaySmall: TextStyle(
              fontSize: 36, fontWeight: FontWeight.w400, letterSpacing: -0.3),
          headlineLarge: TextStyle(
              fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5),
          headlineMedium: TextStyle(
              fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.4),
          headlineSmall: TextStyle(
              fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: -0.3),
          titleLarge: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.2),
          titleMedium: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.1),
          titleSmall: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.05),
          bodyLarge: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.3),
          bodyMedium: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.2),
          bodySmall: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.3),
          labelLarge: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.05),
          labelMedium: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.4),
          labelSmall: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5),
        ),
      );

  // ════════════════════════════════════════════════════════════
  // LIGHT THEME - ENHANCED
  // ════════════════════════════════════════════════════════════

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: lightPrimary,
        secondary: lightSecondary,
        surface: lightSurface,
        error: lightError,
        onPrimary: lightOnPrimary,
        onSecondary: Color(0xFFFFFFFF),
        onSurface: lightOnSurface,
        onError: Color(0xFFFFFFFF),
      ).copyWith(
        surface: lightBackground,
        surfaceContainerHighest: lightSurface,
      ),

      // Scaffold
      scaffoldBackgroundColor: lightBackground,

      // Typography — Inter via Google Fonts
      textTheme: textTheme.apply(
        bodyColor: lightOnBackground,
        displayColor: lightOnBackground,
      ),

      // AppBar — transparent, borderless
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: lightSurface,
        foregroundColor: lightOnSurface,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: lightOnSurface,
          letterSpacing: -0.3,
        ),
      ),

      // Card — tighter radius, subtle shadow
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFF0F0F0), width: 1),
        ),
        color: lightSurface,
        shadowColor: Colors.transparent,
      ),

      // Dialog — premium rounded
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 8,
        backgroundColor: lightSurface,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: lightOnSurface,
          letterSpacing: -0.2,
        ),
      ),

      // BottomSheet — pill handle, smooth radius
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        showDragHandle: true,
        dragHandleColor: Color(0xFFBDBDBD),
        elevation: 0,
        modalElevation: 0,
        backgroundColor: lightSurface,
        surfaceTintColor: Colors.transparent,
      ),

      // SnackBar — floating + rounded
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: const Color(0xFF1A1A2E),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        elevation: 8,
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // Input Decoration (Light)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF7F7F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: lightPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: lightError, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: lightError, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(
            color: Color(0xFF9E9E9E), fontWeight: FontWeight.w400),
        labelStyle: const TextStyle(color: Color(0xFF757575)),
        floatingLabelStyle: const TextStyle(color: lightPrimary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        thickness: 0.5,
        space: 1,
        color: Color(0xFFEEEEEE),
      ),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        elevation: 0,
        backgroundColor: lightSurface,
        selectedItemColor: lightPrimary,
        unselectedItemColor: Color(0xFF9E9E9E),
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
      ),

      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 4,
        highlightElevation: 8,
        shape: CircleBorder(),
        backgroundColor: lightPrimary,
        foregroundColor: lightOnPrimary,
      ),

      // v5.44.6 - im Light-Theme nutzen wir die LIGHT cinematic tokens
      // (warm cream bg, soft glass, gedaempfte Welt-Akzente)
      extensions: const <ThemeExtension<dynamic>>[
        WBCinematic.light,
      ],
    );
  }

  // ════════════════════════════════════════════════════════════
  // DARK THEME - ENHANCED
  // ════════════════════════════════════════════════════════════

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: darkPrimary,
        secondary: darkSecondary,
        surface: darkSurface,
        error: darkError,
        onPrimary: darkOnPrimary,
        onSecondary: Color(0xFF000000),
        onSurface: darkOnSurface,
        onError: Color(0xFF000000),
      ).copyWith(
        surface: darkBackground,
        surfaceContainerHighest: darkSurface,
      ),

      // Scaffold
      scaffoldBackgroundColor: darkBackground,

      // Typography — Inter via Google Fonts
      textTheme: textTheme.apply(
        bodyColor: darkOnBackground,
        displayColor: darkOnBackground,
      ),

      // AppBar — transparent, borderless for cinematic screens
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: darkSurface,
        foregroundColor: darkOnSurface,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: darkOnSurface,
          letterSpacing: -0.3,
        ),
      ),

      // Card — flat glass-style
      cardTheme: const CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: Color(0xFF2A2A2A), width: 1),
        ),
        color: darkSurface,
        shadowColor: Colors.transparent,
      ),

      // Dialog — premium rounded
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: const Color(0xFF1A1A2E),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: darkOnSurface,
          letterSpacing: -0.2,
        ),
      ),

      // BottomSheet — pill handle, smooth radius
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        showDragHandle: true,
        dragHandleColor: Color(0xFF555555),
        elevation: 0,
        modalElevation: 0,
        backgroundColor: Color(0xFF0D0A1A),
        surfaceTintColor: Colors.transparent,
      ),

      // SnackBar — floating + rounded, cinematic
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: const Color(0xFF1E1E2E),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        elevation: 8,
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // Input Decoration (Dark)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1A1A2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2A2A3E), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2A2A3E), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF9A9A), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF9A9A), width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF222222), width: 1),
        ),
        hintStyle: const TextStyle(
            color: Color(0xFF555566), fontWeight: FontWeight.w400),
        labelStyle: const TextStyle(color: Color(0xFF9E9E9E)),
        floatingLabelStyle: const TextStyle(color: darkPrimary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),

      // Divider — very subtle
      dividerTheme: const DividerThemeData(
        thickness: 0.5,
        space: 1,
        color: Color(0xFF2A2A2A),
      ),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        elevation: 0,
        backgroundColor: darkSurface,
        selectedItemColor: darkPrimary,
        unselectedItemColor: Color(0xFF666666),
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
      ),

      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 4,
        highlightElevation: 8,
        shape: CircleBorder(),
        backgroundColor: darkPrimary,
        foregroundColor: darkOnPrimary,
      ),

      // Cinematic Token-System (Foundation für premium Glass-/Welt-Widgets)
      extensions: const <ThemeExtension<dynamic>>[
        WBCinematic.dark,
      ],
    );
  }

  // ════════════════════════════════════════════════════════════
  // ANIMATION CURVES & DURATIONS
  // ════════════════════════════════════════════════════════════

  static Duration get themeTransitionDuration =>
      const Duration(milliseconds: 300);
  static Curve get themeTransitionCurve => Curves.easeInOut;

  // Standard Animation Durations
  static const Duration fastAnimation = Duration(milliseconds: 150);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);

  // Advanced Animation Curves
  static const Curve smoothCurve = Curves.easeInOutCubic;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve snapCurve = Curves.easeOutBack;

  // ════════════════════════════════════════════════════════════
  // RESPONSIVE BREAKPOINTS
  // ════════════════════════════════════════════════════════════

  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  static bool isMobile(double width) => width < mobileBreakpoint;
  static bool isTablet(double width) =>
      width >= mobileBreakpoint && width < desktopBreakpoint;
  static bool isDesktop(double width) => width >= desktopBreakpoint;

  // ════════════════════════════════════════════════════════════
  // GLASSMORPHISM HELPERS
  // ════════════════════════════════════════════════════════════

  static BoxDecoration glassmorphicDecoration({
    Color? color,
    double blur = 10,
    double borderWidth = 1,
  }) {
    return BoxDecoration(
      color: color ?? glassLight,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: glassBorder,
        width: borderWidth,
      ),
      // Note: Actual backdrop filter applied in widget tree
    );
  }
}

/// 🎨 Theme Extension for Custom Properties
extension ThemeDataExtensions on ThemeData {
  /// Get spacing values
  double get space4 => EnhancedAppThemes.space4;
  double get space8 => EnhancedAppThemes.space8;
  double get space12 => EnhancedAppThemes.space12;
  double get space16 => EnhancedAppThemes.space16;
  double get space20 => EnhancedAppThemes.space20;
  double get space24 => EnhancedAppThemes.space24;
  double get space32 => EnhancedAppThemes.space32;
  double get space40 => EnhancedAppThemes.space40;
  double get space48 => EnhancedAppThemes.space48;
  double get space64 => EnhancedAppThemes.space64;
}
