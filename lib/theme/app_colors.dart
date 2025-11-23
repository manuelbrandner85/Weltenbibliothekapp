import 'package:flutter/material.dart';

/// 🎨 Zentrales Design System - Weltenbibliothek App
/// 
/// Alle Farben an EINER Stelle definiert für:
/// - Konsistente Farben über die gesamte App
/// - Einfache Theme-Änderungen
/// - Bessere Wartbarkeit
/// 
/// Best Practice 2024: Design Tokens Pattern
class AppColors {
  // Private Constructor - verhindert Instanziierung
  AppColors._();

  // ═══════════════════════════════════════════════════════════════
  // PRIMARY COLORS - Hauptfarben der App
  // ═══════════════════════════════════════════════════════════════
  
  /// Primär-Violett - Hauptfarbe der App (164 Verwendungen)
  static const Color primary = Color(0xFF8B5CF6);
  
  /// Sekundär-Violett - Alternative Primärfarbe (102 Verwendungen)
  static const Color primaryAlt = Color(0xFF9B59B6);
  
  /// Dunkles Violett - Für Schatten und Akzente
  static const Color primaryDark = Color(0xFF6D28D9);
  
  /// Gold - Akzentfarbe, Premium-Features (55 Verwendungen)
  static const Color accent = Color(0xFFFFD700);
  
  /// Helles Gold - Für subtile Akzente
  static const Color accentLight = Color(0xFFFBBF24);
  
  /// Dunkles Gold
  static const Color accentDark = Color(0xFFF59E0B);

  // ═══════════════════════════════════════════════════════════════
  // BACKGROUND COLORS - Hintergrundfarben
  // ═══════════════════════════════════════════════════════════════
  
  /// Haupt-Hintergrund - Dunkles Blau (17 Verwendungen)
  static const Color background = Color(0xFF0F172A);
  
  /// Sekundärer Hintergrund - Etwas heller (58 Verwendungen)
  static const Color backgroundSecondary = Color(0xFF1E293B);
  
  /// Dunkler Hintergrund - Fast Schwarz (53 Verwendungen)
  static const Color backgroundDark = Color(0xFF1A1A2E);
  
  /// Sehr dunkler Hintergrund
  static const Color backgroundDarker = Color(0xFF0F0F1E);
  
  /// Alternative dunkle Farbe
  static const Color backgroundAlt = Color(0xFF2D2D44);

  // ═══════════════════════════════════════════════════════════════
  // SURFACE COLORS - Karten, Panels, erhöhte Elemente
  // ═══════════════════════════════════════════════════════════════
  
  /// Surface - Karten und Panels
  static const Color surface = Color(0xFF334155);
  
  /// Surface Hell
  static const Color surfaceLight = Color(0xFF64748B);
  
  /// Surface Extra Hell
  static const Color surfaceExtraLight = Color(0xFF94A3B8);

  // ═══════════════════════════════════════════════════════════════
  // SEMANTIC COLORS - Funktionale Farben
  // ═══════════════════════════════════════════════════════════════
  
  /// Erfolg - Grün
  static const Color success = Color(0xFF10B981);
  
  /// Information - Blau
  static const Color info = Color(0xFF3498DB);
  static const Color infoAlt = Color(0xFF3B82F6);
  
  /// Warnung - Orange/Gelb
  static const Color warning = Color(0xFFFBBF24);
  
  /// Fehler - Rot
  static const Color error = Color(0xFFEF4444);
  
  /// Online-Status - Hellgrün
  static const Color online = Color(0xFF00FF00);
  
  /// Cyan - Für spezielle Akzente
  static const Color cyan = Color(0xFF06B6D4);

  // ═══════════════════════════════════════════════════════════════
  // TEXT COLORS - Textfarben
  // ═══════════════════════════════════════════════════════════════
  
  /// Primärer Text - Weiß
  static const Color textPrimary = Colors.white;
  
  /// Sekundärer Text - Hellgrau
  static const Color textSecondary = Color(0xFFE2E8F0);
  
  /// Deaktivierter Text - Grau
  static const Color textDisabled = Color(0xFF64748B);

  // ═══════════════════════════════════════════════════════════════
  // OPACITY HELPERS - Transparenz-Helfer
  // ═══════════════════════════════════════════════════════════════
  
  /// Primärfarbe mit 10% Opazität
  static Color get primaryLight => primary.withValues(alpha: 0.1);
  
  /// Primärfarbe mit 30% Opazität
  static Color get primaryFade => primary.withValues(alpha: 0.3);
  
  /// Primärfarbe mit 50% Opazität
  static Color get primaryMedium => primary.withValues(alpha: 0.5);
  
  /// Weiß mit 10% Opazität
  static Color get whiteLight => Colors.white.withValues(alpha: 0.1);
  
  /// Weiß mit 20% Opazität
  static Color get whiteFade => Colors.white.withValues(alpha: 0.2);
  
  /// Weiß mit 30% Opazität
  static Color get whiteMedium => Colors.white.withValues(alpha: 0.3);
  
  /// Schwarz mit 20% Opazität
  static Color get blackLight => Colors.black.withValues(alpha: 0.2);
  
  /// Schwarz mit 30% Opazität
  static Color get blackMedium => Colors.black.withValues(alpha: 0.3);
  
  /// Schwarz mit 50% Opazität
  static Color get blackFade => Colors.black.withValues(alpha: 0.5);

  // ═══════════════════════════════════════════════════════════════
  // GRADIENTS - Farbverläufe
  // ═══════════════════════════════════════════════════════════════
  
  /// Primär-Gradient - Violett
  static LinearGradient get primaryGradient => const LinearGradient(
        colors: [primary, primaryDark],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
  
  /// Alt-Gradient - Alternative Violett
  static LinearGradient get primaryAltGradient => const LinearGradient(
        colors: [primaryAlt, Color(0xFF8E44AD)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
  
  /// Gold-Gradient
  static LinearGradient get accentGradient => const LinearGradient(
        colors: [accent, accentDark],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}
