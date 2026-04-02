import 'package:flutter/material.dart';
import 'responsive_utils.dart';

/// Responsive TextStyles für Weltenbibliothek
/// Automatische Anpassung der Schriftgrößen an Bildschirmgröße
class ResponsiveTextStyles {
  final ResponsiveUtils responsive;

  ResponsiveTextStyles(this.responsive);

  /// Factory-Konstruktor aus BuildContext
  factory ResponsiveTextStyles.of(BuildContext context) {
    return ResponsiveTextStyles(ResponsiveUtils.of(context));
  }

  // ==================== ÜBERSCHRIFTEN (HEADLINES) ====================

  /// Haupt-Titel (H1)
  TextStyle get titleLarge => TextStyle(
        fontSize: responsive.titleFontSize,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
        height: 1.2,
      );

  /// Große Überschrift (H2)
  TextStyle get headlineLarge => TextStyle(
        fontSize: responsive.headingLargeFontSize,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.3,
        height: 1.3,
      );

  /// Mittlere Überschrift (H3)
  TextStyle get headlineMedium => TextStyle(
        fontSize: responsive.headingMediumFontSize,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        height: 1.3,
      );

  /// Kleine Überschrift (H4)
  TextStyle get headlineSmall => TextStyle(
        fontSize: responsive.headingSmallFontSize,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        height: 1.4,
      );

  // ==================== BODY TEXT ====================

  /// Standard Body-Text (groß)
  TextStyle get bodyLarge => TextStyle(
        fontSize: responsive.bodyFontSize,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.15,
        height: 1.5,
      );

  /// Mittlerer Body-Text
  TextStyle get bodyMedium => TextStyle(
        fontSize: responsive.bodyFontSize * 0.95,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.1,
        height: 1.5,
      );

  /// Kleiner Body-Text
  TextStyle get bodySmall => TextStyle(
        fontSize: responsive.smallFontSize,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.1,
        height: 1.4,
      );

  // ==================== LABELS & BUTTONS ====================

  /// Label-Text (groß)
  TextStyle get labelLarge => TextStyle(
        fontSize: responsive.bodyFontSize,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.4,
      );

  /// Label-Text (mittel)
  TextStyle get labelMedium => TextStyle(
        fontSize: responsive.smallFontSize,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
        height: 1.4,
      );

  /// Label-Text (klein)
  TextStyle get labelSmall => TextStyle(
        fontSize: responsive.extraSmallFontSize,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
        height: 1.3,
      );

  // ==================== SPEZIAL-STILE ====================

  /// Button-Text
  TextStyle get button => TextStyle(
        fontSize: responsive.bodyFontSize,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
        height: 1.2,
      );

  /// Caption-Text (Bildunterschriften, Timestamps)
  TextStyle get caption => TextStyle(
        fontSize: responsive.extraSmallFontSize,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.2,
        height: 1.3,
      );

  /// Overline-Text (Kategorie-Labels)
  TextStyle get overline => TextStyle(
        fontSize: responsive.extraSmallFontSize,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.5,
        height: 1.2,
      );

  // ==================== CUSTOM WELTENBIBLIOTHEK STYLES ====================

  /// Welten-Titel (für Portal-Screen)
  TextStyle get worldTitle => TextStyle(
        fontSize: responsive.headingLargeFontSize,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
        height: 1.2,
        shadows: [
          Shadow(
            offset: const Offset(0, 2),
            blurRadius: 4,
            color: Colors.black.withValues(alpha: 0.5),
          ),
        ],
      );

  /// Mystischer Text (für spezielle UI-Elemente)
  TextStyle get mysticalText => TextStyle(
        fontSize: responsive.bodyFontSize,
        fontWeight: FontWeight.w500,
        letterSpacing: 2.0,
        height: 1.4,
        shadows: [
          Shadow(
            offset: const Offset(0, 0),
            blurRadius: 8,
            color: Colors.purpleAccent.withValues(alpha: 0.6),
          ),
        ],
      );

  /// Chat-Nachricht
  TextStyle get chatMessage => TextStyle(
        fontSize: responsive.bodyFontSize,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.1,
        height: 1.4,
      );

  /// Chat-Timestamp
  TextStyle get chatTimestamp => TextStyle(
        fontSize: responsive.extraSmallFontSize,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
        height: 1.2,
      );

  /// Chat-Username
  TextStyle get chatUsername => TextStyle(
        fontSize: responsive.smallFontSize,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        height: 1.3,
      );

  /// Recherche-Ergebnis-Titel
  TextStyle get researchResultTitle => TextStyle(
        fontSize: responsive.headingSmallFontSize,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.2,
        height: 1.3,
      );

  /// Recherche-Ergebnis-Text
  TextStyle get researchResultBody => TextStyle(
        fontSize: responsive.bodyFontSize,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.1,
        height: 1.5,
      );

  /// Post-Titel
  TextStyle get postTitle => TextStyle(
        fontSize: responsive.headingSmallFontSize,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.2,
        height: 1.3,
      );

  /// Post-Content
  TextStyle get postContent => TextStyle(
        fontSize: responsive.bodyFontSize,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.1,
        height: 1.5,
      );

  /// Post-Metadaten (Author, Date, etc.)
  TextStyle get postMetadata => TextStyle(
        fontSize: responsive.extraSmallFontSize,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
        height: 1.2,
      );

  // ==================== COLOR VARIANTS ====================

  /// Text mit spezifischer Farbe
  TextStyle withColor(TextStyle base, Color color) =>
      base.copyWith(color: color);

  /// Weißer Text (für dunkle Hintergründe)
  TextStyle white(TextStyle base) => base.copyWith(color: Colors.white);

  /// Heller Text (70% Opacity)
  TextStyle light(TextStyle base) =>
      base.copyWith(color: Colors.white.withValues(alpha: 0.7));

  /// Gedämpfter Text (50% Opacity)
  TextStyle muted(TextStyle base) =>
      base.copyWith(color: Colors.white.withValues(alpha: 0.5));

  /// Deaktivierter Text (30% Opacity)
  TextStyle disabled(TextStyle base) =>
      base.copyWith(color: Colors.white.withValues(alpha: 0.3));

  /// Fehler-Text (Rot)
  TextStyle error(TextStyle base) =>
      base.copyWith(color: Colors.red.shade300);

  /// Erfolgs-Text (Grün)
  TextStyle success(TextStyle base) =>
      base.copyWith(color: Colors.green.shade300);

  /// Warn-Text (Orange)
  TextStyle warning(TextStyle base) =>
      base.copyWith(color: Colors.orange.shade300);

  /// Info-Text (Blau)
  TextStyle info(TextStyle base) =>
      base.copyWith(color: Colors.blue.shade300);
}

/// Extension für einfachen Zugriff auf ResponsiveTextStyles
extension ResponsiveTextStylesExtension on BuildContext {
  ResponsiveTextStyles get textStyles => ResponsiveTextStyles.of(this);
}
