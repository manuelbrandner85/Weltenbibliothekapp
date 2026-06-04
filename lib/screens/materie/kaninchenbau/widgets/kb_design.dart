/// Design-Tokens für Kaninchenbau (Cyberpunk-Neon × Apple Vision).
library;

import 'package:flutter/material.dart';

class KbDesign {
  static const Color voidBlack = Color(0xFF000000);
  static const Color deepNight = Color(0xFF0A0A0F);
  static const Color cardSurface = Color(0xFF0F0F18);
  static const Color cardSurfaceAlt = Color(0xFF14141F);

  // Akzent-Glow (Materie-Welt)
  static const Color neonRed = Color(0xFFFF1744);
  static const Color neonRedSoft = Color(0xFFFF5277);
  static const Color goldAccent = Color(0xFFFFC857);

  // Glaubwürdigkeits-Farben
  static const Color credGold = Color(0xFFFFD700);
  static const Color credSilver = Color(0xFFB0BEC5);
  static const Color credAlert = Color(0xFFFF5252);

  // Quellen-Linsen
  static const Color lensOfficial = Color(0xFF42A5F5);
  static const Color lensCritical = Color(0xFFFF6E40);
  static const Color lensNeutral = Color(0xFFB0BEC5);

  static const double radiusSm = 12;
  static const double radiusMd = 18;
  static const double radiusLg = 28;

  static const Duration easyMotion = Duration(milliseconds: 320);
  static const Curve easyCurve = Curves.easeOutCubic;

  /// Glas-Box-Decoration mit subtilem Glow.
  static BoxDecoration glassBox({
    Color tint = neonRed,
    double opacity = 0.06,
    double radius = radiusMd,
  }) =>
      BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cardSurface,
            cardSurfaceAlt,
          ],
        ),
        border: Border.all(
          color: tint.withValues(alpha: 0.18),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: tint.withValues(alpha: opacity),
            blurRadius: 28,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: voidBlack.withValues(alpha: 0.6),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      );

  /// Hero-Decoration für Identitäts-Karte.
  static BoxDecoration heroBox() => BoxDecoration(
        borderRadius: BorderRadius.circular(radiusLg),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A0010),
            Color(0xFF0A0010),
          ],
        ),
        border: Border.all(
          color: neonRed.withValues(alpha: 0.35),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: neonRed.withValues(alpha: 0.18),
            blurRadius: 40,
            spreadRadius: 2,
          ),
        ],
      );

  /// Hinweis-Banner fuer Karten mit geschaetzten / illustrativen Daten.
  /// WICHTIG: Macht transparent, dass Zahlen NICHT belegt sind (Glaubwuerdigkeit).
  static Widget estimateBanner([String? note]) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radiusSm),
          color: const Color(0xFFFFB300).withValues(alpha: 0.10),
          border: Border.all(
            color: const Color(0xFFFFB300).withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline,
                color: Color(0xFFFFB300), size: 15),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                note ??
                    'Schaetzung / Illustration - keine belegten Zahlen. '
                        'Dient nur zur Veranschaulichung moeglicher Zusammenhaenge.',
                style: TextStyle(
                  color: const Color(0xFFFFB300).withValues(alpha: 0.95),
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      );
}