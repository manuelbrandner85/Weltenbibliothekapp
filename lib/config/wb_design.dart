import 'package:flutter/material.dart';

/// 🎨 WB DESIGN TOKENS — Single Source of Truth
///
/// Zentrale Design-Tokens passend zum Home-Tab-Stil (`screens/{materie,energie}/home_tab_v5.dart`).
/// Alle anderen Screens sollten ausschließlich diese Tokens nutzen statt
/// hardcoded `Color(0x...)`/`SizedBox(height: 7)`/`borderRadius: 14`.
///
/// **Welt-Awareness**: Die meisten Tokens haben Materie- und Energie-Varianten.
/// Verwende `WbDesign.world(world)` um sie kontextabhängig zu wählen.
///
/// Stil-Charakteristik (aus Home-Bereich extrahiert):
/// - Sehr dunkler Hintergrund (`#06040F`/`#04080F`)
/// - Glassmorphic Cards mit subtilen Borders (`white.alpha=0.05`)
/// - Multi-Stop-Gradients pro Welt
/// - Konsistente Radien (12 Buttons / 16 Cards / 22 Hero-Cards)
/// - 4/8-Raster für Spacings
class WbDesign {
  WbDesign._();

  // ═══════════════════════════════════════════════════════════════════════
  // BACKGROUND COLORS
  // ═══════════════════════════════════════════════════════════════════════

  /// Hintergrund Energie-Welt (Spirit, Bewusstsein) — sehr dunkles Lila-Schwarz.
  static const Color bgEnergie = Color(0xFF06040F);

  /// Hintergrund Materie-Welt (Recherche, Fakten) — sehr dunkles Blau-Schwarz.
  static const Color bgMaterie = Color(0xFF04080F);

  /// Universaler dunkler Hintergrund (Portal, Settings ohne Welt-Kontext).
  static const Color bgNeutral = Color(0xFF0A0A0A);

  // ═══════════════════════════════════════════════════════════════════════
  // SURFACE / CARD COLORS
  // ═══════════════════════════════════════════════════════════════════════

  /// Card-Surface Energie (primär, leicht gehoben).
  static const Color surfaceEnergie = Color(0xFF100B1E);

  /// Card-Surface Energie variant B (höhere Hierarchie).
  static const Color surfaceEnergieAlt = Color(0xFF150E25);

  /// Card-Surface Materie (primär).
  static const Color surfaceMaterie = Color(0xFF0A1020);

  /// Card-Surface Materie variant B.
  static const Color surfaceMaterieAlt = Color(0xFF0D1528);

  // ═══════════════════════════════════════════════════════════════════════
  // ACCENT COLORS (Welt-spezifisch)
  // ═══════════════════════════════════════════════════════════════════════

  // Energie-Akzente (Lila-Spektrum)
  static const Color energiePurple = Color(0xFFAB47BC);
  static const Color energiePurpleDark = Color(0xFF4A148C);
  static const Color energiePurpleLight = Color(0xFFCE93D8);
  static const Color energieTeal = Color(0xFF26C6DA);
  static const Color energiePink = Color(0xFFEC407A);
  static const Color energieGold = Color(0xFFFFD54F);
  static const Color energieGreen = Color(0xFF66BB6A);
  static const Color energieIndigo = Color(0xFF7E57C2);

  // Materie-Akzente (Blau-Spektrum)
  static const Color materieBlue = Color(0xFF1E88E5);
  static const Color materieBlueDark = Color(0xFF0D47A1);
  static const Color materieBlueLight = Color(0xFF64B5F6);
  static const Color materieCyan = Color(0xFF00E5FF);
  static const Color materieRed = Color(0xFFFF1744);
  static const Color materieAmber = Color(0xFFFFB300);
  static const Color materieGreen = Color(0xFF43A047);
  static const Color materiePurple = Color(0xFF9C27B0);

  // ═══════════════════════════════════════════════════════════════════════
  // TEXT COLORS (klare Hierarchie)
  // ═══════════════════════════════════════════════════════════════════════

  /// Primärer Text — höchste Priorität, vollständig lesbar.
  static const Color textPrimary = Colors.white;

  /// Sekundärer Text — etwas zurückgenommen (z.B. Subtitles).
  static Color get textSecondary => Colors.white.withValues(alpha: 0.70);

  /// Tertiärer Text — Hinweise, Metadaten.
  static Color get textTertiary => Colors.white.withValues(alpha: 0.54);

  /// Disabled Text — quasi unsichtbar (Captions, geringer Kontrast).
  static Color get textDisabled => Colors.white.withValues(alpha: 0.38);

  // ═══════════════════════════════════════════════════════════════════════
  // BORDERS
  // ═══════════════════════════════════════════════════════════════════════

  /// Subtile Card-Border (Standard, kaum sichtbar — passt zu dunklem BG).
  static Color get borderSubtle => Colors.white.withValues(alpha: 0.05);

  /// Mittlere Border (Hover, leicht hervorgehoben).
  static Color get borderMedium => Colors.white.withValues(alpha: 0.10);

  /// Akzent-Border in Welt-Farbe (für aktive Selektoren).
  static Color borderAccent(String world) {
    return _accent(world).withValues(alpha: 0.30);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SPACING (4/8-Raster, identisch zu EnhancedAppThemes)
  // ═══════════════════════════════════════════════════════════════════════

  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;

  // ═══════════════════════════════════════════════════════════════════════
  // BORDER RADIUS
  // ═══════════════════════════════════════════════════════════════════════

  /// Klein (8) — Chips, kleine Pills.
  static const double radiusSmall = 8.0;

  /// Standard (12) — Buttons, Inputs, kleine Cards.
  static const double radiusMedium = 12.0;

  /// Card (16) — Standard-Card-Container.
  static const double radiusCard = 16.0;

  /// Large (20) — Stat-Banner, Action-Tiles.
  static const double radiusLarge = 20.0;

  /// Hero (22) — Action-Grid Tiles, Primary CTAs.
  static const double radiusHero = 22.0;

  /// Pill (999) — vollrund.
  static const double radiusPill = 999.0;

  // ═══════════════════════════════════════════════════════════════════════
  // GRADIENTS (Welt-spezifisch, multi-stop)
  // ═══════════════════════════════════════════════════════════════════════

  /// Hero-Header Gradient für Energie (Lila-Aura wie im Home-Tab).
  static LinearGradient heroEnergie() => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF3E0D6B), Color(0xFF6A1B9A), Color(0xFFAB47BC)],
      );

  /// Hero-Header Gradient für Materie (Tiefblau wie im Home-Tab).
  static LinearGradient heroMaterie() => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF2979FF)],
      );

  /// Action-Tile Gradients pro Welt — 4 Variantes (hue-rotiert).
  static List<LinearGradient> actionTilesEnergie() => const [
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3E0D6B), Color(0xFF6A1B9A), Color(0xFFAB47BC)],
        ),
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF004D40), Color(0xFF00796B), Color(0xFF26C6DA)],
        ),
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF880E4F), Color(0xFFC2185B), Color(0xFFEC407A)],
        ),
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4A3B00), Color(0xFF827717), Color(0xFFFFD54F)],
        ),
      ];

  static List<LinearGradient> actionTilesMaterie() => const [
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF2979FF)],
        ),
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF006064), Color(0xFF00838F), Color(0xFF00E5FF)],
        ),
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF43A047)],
        ),
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE65100), Color(0xFFF57C00), Color(0xFFFFAB00)],
        ),
      ];

  /// Patch-Update / Update-Dialog Gradient (cyaner Akzent — neutral).
  static const LinearGradient updateAccent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00E5FF), Color(0xFF7C4DFF)],
  );

  // ═══════════════════════════════════════════════════════════════════════
  // BOX SHADOWS
  // ═══════════════════════════════════════════════════════════════════════

  /// Standard-Card-Shadow (subtil, dunkel).
  static List<BoxShadow> shadowCard(String world) => [
        BoxShadow(
          color: _accent(world).withValues(alpha: 0.12),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];

  /// Action-Tile Shadow (stärker, akzentuiert).
  static List<BoxShadow> shadowTile(Color accent) => [
        BoxShadow(
          color: accent.withValues(alpha: 0.25),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  // ═══════════════════════════════════════════════════════════════════════
  // TEXT STYLES (für consistent Typography)
  // ═══════════════════════════════════════════════════════════════════════

  static const TextStyle titleLarge = TextStyle(
    color: textPrimary,
    fontSize: 20,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.3,
  );

  static const TextStyle titleMedium = TextStyle(
    color: textPrimary,
    fontSize: 17,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle titleSmall = TextStyle(
    color: textPrimary,
    fontSize: 15,
    fontWeight: FontWeight.bold,
  );

  static TextStyle bodyMedium = TextStyle(
    color: textSecondary,
    fontSize: 14,
    height: 1.5,
  );

  static TextStyle bodySmall = TextStyle(
    color: textSecondary,
    fontSize: 12,
    height: 1.4,
  );

  static TextStyle caption = TextStyle(
    color: textTertiary,
    fontSize: 11,
    fontWeight: FontWeight.w500,
  );

  static TextStyle labelMicro = TextStyle(
    color: textDisabled,
    fontSize: 9,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
  );

  // ═══════════════════════════════════════════════════════════════════════
  // HELPERS — Welt-aware Tokens
  // ═══════════════════════════════════════════════════════════════════════

  /// Liefert den passenden Welt-Hintergrund. `world` = `'materie'`/`'energie'`.
  static Color background(String world) =>
      world == 'energie' ? bgEnergie : bgMaterie;

  /// Liefert die primäre Card-Surface der Welt.
  static Color surface(String world) =>
      world == 'energie' ? surfaceEnergie : surfaceMaterie;

  /// Liefert die alternative Card-Surface der Welt.
  static Color surfaceAlt(String world) =>
      world == 'energie' ? surfaceEnergieAlt : surfaceMaterieAlt;

  /// Liefert den Hero-Gradient der Welt.
  static LinearGradient hero(String world) =>
      world == 'energie' ? heroEnergie() : heroMaterie();

  /// Liefert die 4 Action-Tile-Gradients der Welt.
  static List<LinearGradient> actionTiles(String world) =>
      world == 'energie' ? actionTilesEnergie() : actionTilesMaterie();

  /// Internal: Welt-Akzent für Border/Shadow.
  static Color _accent(String world) =>
      world == 'energie' ? energiePurple : materieBlue;

  /// Public Accent. Verwende in Buttons, Highlights, aktiven Tabs.
  static Color accent(String world) => _accent(world);

  // ═══════════════════════════════════════════════════════════════════════
  // PRE-COMPOSED DECORATIONS (häufige Patterns)
  // ═══════════════════════════════════════════════════════════════════════

  /// Standard Card-Decoration: Surface-Color + subtile Border + Card-Radius.
  /// Verwende für die meisten Container-Cards in der App.
  static BoxDecoration card(String world, {double? radius}) => BoxDecoration(
        color: surface(world),
        borderRadius: BorderRadius.circular(radius ?? radiusCard),
        border: Border.all(color: borderSubtle),
      );

  /// Stat-Banner-Decoration (wie in Home-Tab `_buildLiveStatBanner`):
  /// AlternativeSurface + radiusLarge + subtile Border.
  static BoxDecoration statBanner(String world) => BoxDecoration(
        color: surfaceAlt(world),
        borderRadius: BorderRadius.circular(radiusLarge),
        border: Border.all(color: borderSubtle),
      );

  /// Hero-Banner-Decoration mit Gradient (wie `_buildMysticBanner`).
  /// Akzent-Border und Glow-Shadow inkludiert.
  static BoxDecoration heroBanner(String world) => BoxDecoration(
        gradient: hero(world),
        borderRadius: BorderRadius.circular(radiusLarge),
        border: Border.all(color: borderAccent(world)),
        boxShadow: shadowCard(world),
      );

  // ═══════════════════════════════════════════════════════════════════════
  // ACCESSIBILITY
  // ═══════════════════════════════════════════════════════════════════════

  /// Minimale Touch-Target-Größe (Material Design + WCAG: 44x44dp).
  static const double minTouchTarget = 44.0;
}

/// Convenience-Extension um WbDesign-Tokens via `Theme.of(context)` zu nutzen.
extension WbDesignContext on BuildContext {
  /// Liefert WbDesign-Tokens für eine bestimmte Welt.
  /// Verwendung: `context.wbWorld('energie').card(...)`
  _WbDesignWorld wbWorld(String world) => _WbDesignWorld(world);
}

/// Welt-bound Wrapper über WbDesign — vermeidet ständiges Übergeben des
/// `world`-Strings.
class _WbDesignWorld {
  final String world;
  const _WbDesignWorld(this.world);

  Color get background => WbDesign.background(world);
  Color get surface => WbDesign.surface(world);
  Color get surfaceAlt => WbDesign.surfaceAlt(world);
  Color get accent => WbDesign.accent(world);
  LinearGradient get hero => WbDesign.hero(world);
  List<LinearGradient> get actionTiles => WbDesign.actionTiles(world);

  BoxDecoration card({double? radius}) =>
      WbDesign.card(world, radius: radius);
  BoxDecoration get statBanner => WbDesign.statBanner(world);
  BoxDecoration get heroBanner => WbDesign.heroBanner(world);
}
