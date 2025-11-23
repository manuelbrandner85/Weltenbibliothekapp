import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 📝 Zentrales Text-Design System
/// 
/// Alle TextStyles an EINER Stelle definiert für:
/// - Konsistente Typografie
/// - Einfache Font-Änderungen
/// - Accessibility-freundlich
/// 
/// Best Practice 2024: Typography Scale Pattern
class AppTextStyles {
  // Private Constructor
  AppTextStyles._();

  // ═══════════════════════════════════════════════════════════════
  // HEADINGS - Überschriften
  // ═══════════════════════════════════════════════════════════════
  
  /// H1 - Sehr große Überschrift (z.B. Screen-Titel)
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
  );
  
  /// H2 - Große Überschrift (z.B. Section-Titel)
  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
  );
  
  /// H3 - Mittlere Überschrift (z.B. Card-Titel)
  static const TextStyle h3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.3,
  );
  
  /// H4 - Kleine Überschrift
  static const TextStyle h4 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.3,
  );

  // ═══════════════════════════════════════════════════════════════
  // BODY TEXT - Fließtext
  // ═══════════════════════════════════════════════════════════════
  
  /// Body Large - Großer Fließtext
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
    letterSpacing: 0.2,
  );
  
  /// Body Medium - Standard Fließtext (DEFAULT)
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.4,
    letterSpacing: 0.2,
  );
  
  /// Body Small - Kleiner Fließtext
  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  // ═══════════════════════════════════════════════════════════════
  // LABELS & CAPTIONS - Klein-Text
  // ═══════════════════════════════════════════════════════════════
  
  /// Label - Für Buttons, Chips
  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
  );
  
  /// Caption - Sehr kleiner Text (z.B. Timestamps)
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.3,
  );
  
  /// Overline - Uppercase Labels
  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.bold,
    color: AppColors.textSecondary,
    letterSpacing: 1.2,
  );

  // ═══════════════════════════════════════════════════════════════
  // BUTTON TEXT STYLES
  // ═══════════════════════════════════════════════════════════════
  
  /// Button Large
  static const TextStyle buttonLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
  );
  
  /// Button Medium
  static const TextStyle buttonMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
  );
  
  /// Button Small
  static const TextStyle buttonSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
  );

  // ═══════════════════════════════════════════════════════════════
  // SEMANTIC STYLES - Funktionale Text-Stile
  // ═══════════════════════════════════════════════════════════════
  
  /// Success Message
  static const TextStyle success = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.success,
  );
  
  /// Error Message
  static const TextStyle error = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.error,
  );
  
  /// Warning Message
  static const TextStyle warning = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.warning,
  );
  
  /// Info Message
  static const TextStyle info = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.info,
  );

  // ═══════════════════════════════════════════════════════════════
  // SPECIALIZED STYLES - Spezielle Anwendungsfälle
  // ═══════════════════════════════════════════════════════════════
  
  /// Link Text
  static const TextStyle link = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    color: AppColors.primary,
    decoration: TextDecoration.underline,
  );
  
  /// Hint Text (z.B. in TextFields)
  static const TextStyle hint = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    color: AppColors.textDisabled,
  );
  
  /// Placeholder Text
  static const TextStyle placeholder = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textDisabled,
    fontStyle: FontStyle.italic,
  );
  
  /// Chat Message
  static const TextStyle chatMessage = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.4,
    letterSpacing: 0.2,
  );
  
  /// Username/Display Name
  static const TextStyle username = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );
  
  /// Timestamp
  static const TextStyle timestamp = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.normal,
    color: AppColors.textDisabled,
  );

  // ═══════════════════════════════════════════════════════════════
  // HELPER METHODS - Farb-Varianten
  // ═══════════════════════════════════════════════════════════════
  
  /// Erstelle white-colored Variante eines Styles
  static TextStyle white(TextStyle style) => style.copyWith(color: Colors.white);
  
  /// Erstelle primary-colored Variante eines Styles
  static TextStyle primary(TextStyle style) => style.copyWith(color: AppColors.primary);
  
  /// Erstelle accent-colored Variante eines Styles
  static TextStyle accent(TextStyle style) => style.copyWith(color: AppColors.accent);
  
  /// Erstelle bold Variante eines Styles
  static TextStyle bold(TextStyle style) => style.copyWith(fontWeight: FontWeight.bold);
  
  /// Erstelle semi-bold Variante eines Styles
  static TextStyle semiBold(TextStyle style) => style.copyWith(fontWeight: FontWeight.w600);
}
