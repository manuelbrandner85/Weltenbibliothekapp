import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Welt-Identität für cinematic Komponenten.
enum WBWorld { materie, energie, vorhang, ursprung, neutral }

/// Welt-Farbpalette: alle Töne, die ein Screen pro Welt braucht.
@immutable
class WBWorldPalette {
  final Color primary;
  final Color deep;
  final Color highlight;
  final Color label;
  final Color glow;

  const WBWorldPalette({
    required this.primary,
    required this.deep,
    required this.highlight,
    required this.label,
    required this.glow,
  });

  WBWorldPalette lerp(WBWorldPalette other, double t) => WBWorldPalette(
        primary: Color.lerp(primary, other.primary, t)!,
        deep: Color.lerp(deep, other.deep, t)!,
        highlight: Color.lerp(highlight, other.highlight, t)!,
        label: Color.lerp(label, other.label, t)!,
        glow: Color.lerp(glow, other.glow, t)!,
      );
}

/// Zentrale cinematic Tokens — Glass, Welt-Paletten, Spacings, Radien, Blur, Motion.
/// Wird via `Theme.of(context).extension<WBCinematic>()` abgerufen.
@immutable
class WBCinematic extends ThemeExtension<WBCinematic> {
  // Hintergründe
  final Color bgVoid;
  final Color bgDeep;
  final Color bgSurface;

  // Glass-Oberflächen
  final Color glassBase;
  final Color glassElevated;
  final Color glassStroke;
  final Color glassStrokeHi;

  // Welt-Paletten
  final WBWorldPalette materie;
  final WBWorldPalette energie;
  final WBWorldPalette vorhang;
  final WBWorldPalette ursprung;
  final WBWorldPalette neutral;

  // Blur-Stufen
  final double blurLight;
  final double blurMedium;
  final double blurHeavy;

  const WBCinematic({
    required this.bgVoid,
    required this.bgDeep,
    required this.bgSurface,
    required this.glassBase,
    required this.glassElevated,
    required this.glassStroke,
    required this.glassStrokeHi,
    required this.materie,
    required this.energie,
    required this.vorhang,
    required this.ursprung,
    required this.neutral,
    required this.blurLight,
    required this.blurMedium,
    required this.blurHeavy,
  });

  /// Default cinematic dark theme.
  static const dark = WBCinematic(
    bgVoid: Color(0xFF000004),
    bgDeep: Color(0xFF050310),
    bgSurface: Color(0xFF0D0A1A),
    glassBase: Color(0x8C08080E), // 0.55 alpha
    glassElevated: Color(0xCC0E1226), // 0.80 alpha — etwas heller
    glassStroke: Color(0x38FFFFFF), // 0.22 — gut sichtbare Ränder
    glassStrokeHi: Color(0x55FFFFFF), // 0.33 — highlight Ränder
    materie: WBWorldPalette(
      primary: Color(0xFF3B82F6),
      deep: Color(0xFF0A2452),
      highlight: Color(0xFFCFDFFF),
      label: Color(0xFF7DA7FF),
      glow: Color(0x663B82F6),
    ),
    energie: WBWorldPalette(
      primary: Color(0xFFA855F7),
      deep: Color(0xFF3B0D6E),
      highlight: Color(0xFFE9CCFF),
      label: Color(0xFFC79AFF),
      glow: Color(0x66A855F7),
    ),
    vorhang: WBWorldPalette(
      primary: Color(0xFFC9A84C),
      deep: Color(0xFF1A1500),
      highlight: Color(0xFFFFE9A0),
      label: Color(0xFFE0C872),
      glow: Color(0x66C9A84C),
    ),
    ursprung: WBWorldPalette(
      primary: Color(0xFF00D4AA),
      deep: Color(0xFF002B22),
      highlight: Color(0xFFA0FFE0),
      label: Color(0xFF40E8C0),
      glow: Color(0x6600D4AA),
    ),
    neutral: WBWorldPalette(
      primary: Color(0xFF8AA3FF),
      deep: Color(0xFF1A1A2E),
      highlight: Color(0xFFEEEEFF),
      label: Color(0xFF9FA8FF),
      glow: Color(0x668AA3FF),
    ),
    blurLight: 16,
    blurMedium: 28,
    blurHeavy: 40,
  );

  /// v5.44.6 - Cinematic Light Theme.
  ///
  /// Helle Variante mit warmen, klaren Tönen statt schwarz-blauer
  /// Nacht-Atmosphäre. Welt-Identität bleibt durch Akzent-Farben
  /// erhalten, aber Hintergründe + Glas sind hell/cremeweiß.
  ///
  /// Übergänge zwischen dark/light werden via ThemeExtension.lerp()
  /// in Flutter automatisch animiert.
  static const light = WBCinematic(
    // Warmer Cream-Hintergrund - wie altes Buchpapier
    bgVoid: Color(0xFFFBF8F3),
    bgDeep: Color(0xFFF2EBE0),
    bgSurface: Color(0xFFFFFFFF),
    // Helle frosted Glas-Oberflächen (weiß-tönt statt schwarz)
    glassBase: Color(0xCCFFFFFF), // 0.80 alpha weiß
    glassElevated: Color(0xE6FFFFFF), // 0.90 alpha weiß
    glassStroke: Color(0x22000000), // 0.13 schwarz - dezent
    glassStrokeHi: Color(0x33000000), // 0.20 schwarz - prominent
    // Welt-Paletten in Light-Variante (gedämpfte Akzente)
    materie: WBWorldPalette(
      primary: Color(0xFFD32F2F), // Korallrot
      deep: Color(0xFFFFEBEE), // Sehr helles Rosé
      highlight: Color(0xFF8B1A1A), // Dunkles Bordeaux für Kontrast
      label: Color(0xFFB23030),
      glow: Color(0x33D32F2F),
    ),
    energie: WBWorldPalette(
      primary: Color(0xFF7B1FA2), // Dunkles Lila
      deep: Color(0xFFF3E5F5), // Lavendelweiß
      highlight: Color(0xFF4A148C),
      label: Color(0xFF9C27B0),
      glow: Color(0x337B1FA2),
    ),
    vorhang: WBWorldPalette(
      primary: Color(0xFFB89344), // Dunkleres Gold
      deep: Color(0xFFFFF8DC), // Champagner-Creme
      highlight: Color(0xFF7A5F1C),
      label: Color(0xFFA0832F),
      glow: Color(0x33B89344),
    ),
    ursprung: WBWorldPalette(
      primary: Color(0xFF00897B), // Gedämpftes Türkis
      deep: Color(0xFFE0F2F1), // Sehr helles Türkis
      highlight: Color(0xFF004D40),
      label: Color(0xFF00796B),
      glow: Color(0x3300897B),
    ),
    neutral: WBWorldPalette(
      primary: Color(0xFF5C6BC0), // Indigoblau
      deep: Color(0xFFE8EAF6),
      highlight: Color(0xFF1A237E),
      label: Color(0xFF3F51B5),
      glow: Color(0x335C6BC0),
    ),
    blurLight: 16,
    blurMedium: 28,
    blurHeavy: 40,
  );

  /// Liefert die Welt-Palette für das gegebene Welt-Token.
  WBWorldPalette palette(WBWorld world) {
    switch (world) {
      case WBWorld.materie:
        return materie;
      case WBWorld.energie:
        return energie;
      case WBWorld.vorhang:
        return vorhang;
      case WBWorld.ursprung:
        return ursprung;
      case WBWorld.neutral:
        return neutral;
    }
  }

  @override
  WBCinematic copyWith({
    Color? bgVoid,
    Color? bgDeep,
    Color? bgSurface,
    Color? glassBase,
    Color? glassElevated,
    Color? glassStroke,
    Color? glassStrokeHi,
    WBWorldPalette? materie,
    WBWorldPalette? energie,
    WBWorldPalette? vorhang,
    WBWorldPalette? ursprung,
    WBWorldPalette? neutral,
    double? blurLight,
    double? blurMedium,
    double? blurHeavy,
  }) =>
      WBCinematic(
        bgVoid: bgVoid ?? this.bgVoid,
        bgDeep: bgDeep ?? this.bgDeep,
        bgSurface: bgSurface ?? this.bgSurface,
        glassBase: glassBase ?? this.glassBase,
        glassElevated: glassElevated ?? this.glassElevated,
        glassStroke: glassStroke ?? this.glassStroke,
        glassStrokeHi: glassStrokeHi ?? this.glassStrokeHi,
        materie: materie ?? this.materie,
        energie: energie ?? this.energie,
        vorhang: vorhang ?? this.vorhang,
        ursprung: ursprung ?? this.ursprung,
        neutral: neutral ?? this.neutral,
        blurLight: blurLight ?? this.blurLight,
        blurMedium: blurMedium ?? this.blurMedium,
        blurHeavy: blurHeavy ?? this.blurHeavy,
      );

  @override
  WBCinematic lerp(ThemeExtension<WBCinematic>? other, double t) {
    if (other is! WBCinematic) return this;
    return WBCinematic(
      bgVoid: Color.lerp(bgVoid, other.bgVoid, t)!,
      bgDeep: Color.lerp(bgDeep, other.bgDeep, t)!,
      bgSurface: Color.lerp(bgSurface, other.bgSurface, t)!,
      glassBase: Color.lerp(glassBase, other.glassBase, t)!,
      glassElevated: Color.lerp(glassElevated, other.glassElevated, t)!,
      glassStroke: Color.lerp(glassStroke, other.glassStroke, t)!,
      glassStrokeHi: Color.lerp(glassStrokeHi, other.glassStrokeHi, t)!,
      materie: materie.lerp(other.materie, t),
      energie: energie.lerp(other.energie, t),
      vorhang: vorhang.lerp(other.vorhang, t),
      ursprung: ursprung.lerp(other.ursprung, t),
      neutral: neutral.lerp(other.neutral, t),
      blurLight: blurLight + (other.blurLight - blurLight) * t,
      blurMedium: blurMedium + (other.blurMedium - blurMedium) * t,
      blurHeavy: blurHeavy + (other.blurHeavy - blurHeavy) * t,
    );
  }
}

/// Bequeme Erweiterung: `context.wb` statt `Theme.of(context).extension<WBCinematic>()!`.
extension WBCinematicContext on BuildContext {
  WBCinematic get wb =>
      Theme.of(this).extension<WBCinematic>() ?? WBCinematic.dark;

  /// v5.44.7: Theme-aware Text/Icon-Farben fuer cinematic Screens.
  /// In Dark-Mode weiss, in Light-Mode dunkelblau.
  /// Verwendung: `Text('...', style: TextStyle(color: context.onBg))`
  Color get onBg {
    return Theme.of(this).brightness == Brightness.light
        ? const Color(0xFF1A1A2E)
        : Colors.white;
  }

  /// Sekundaere Text-Farbe (60% Opacity vom Primaer).
  Color get onBgSecondary {
    return Theme.of(this).brightness == Brightness.light
        ? const Color(0xFF1A1A2E).withValues(alpha: 0.65)
        : Colors.white.withValues(alpha: 0.65);
  }

  /// Tertiaere/Hint-Text-Farbe (38% Opacity).
  Color get onBgHint {
    return Theme.of(this).brightness == Brightness.light
        ? const Color(0xFF1A1A2E).withValues(alpha: 0.38)
        : Colors.white.withValues(alpha: 0.38);
  }
}

/// Cinematic-Spacings (4er-Rhythmus).
class WBSpace {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;
}

/// Cinematic-Radien.
class WBRadius {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double pill = 999;
}

/// Cinematic-Bewegungs-Hierarchie (Standard-Curves + Durations).
class WBMotion {
  static const Curve enterCurve = Curves.easeOutCubic;
  static const Curve heroCurve = Curves.easeOutBack;
  static const Curve revealCurve = Curves.easeOutExpo;

  static const Duration micro = Duration(milliseconds: 100);
  static const Duration press = Duration(milliseconds: 150);
  static const Duration card = Duration(milliseconds: 300);
  static const Duration page = Duration(milliseconds: 450);
  static const Duration hero = Duration(milliseconds: 800);
  static const Duration reveal = Duration(milliseconds: 1200);
}

/// Cinematic Text-Hierarchie (Inter via Google Fonts, Cormorant Garamond serif).
class WBType {
  static TextStyle get title => GoogleFonts.inter(
        fontWeight: FontWeight.w200,
        fontSize: 22,
        letterSpacing: 5.0,
        color: Colors.white,
        height: 1.0,
      );

  static TextStyle get hero => GoogleFonts.inter(
        fontWeight: FontWeight.w200,
        fontSize: 38,
        letterSpacing: 10.0,
        color: Colors.white,
        height: 1.0,
      );

  static TextStyle get body => GoogleFonts.inter(
        fontWeight: FontWeight.w400,
        fontSize: 14,
        letterSpacing: 0.2,
        color: const Color(0xE6FFFFFF),
      );

  static TextStyle get eyebrow => GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: 9,
        letterSpacing: 4.0,
      );

  static TextStyle get serif => GoogleFonts.cormorantGaramond(
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w300,
        fontSize: 13,
        letterSpacing: 1.8,
        color: const Color(0x75FFFFFF),
      );

  static TextStyle get micro => GoogleFonts.inter(
        fontWeight: FontWeight.w500,
        fontSize: 10,
        letterSpacing: 4.2,
        color: const Color(0x6BFFFFFF),
      );
}
