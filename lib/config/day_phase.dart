// 🕑 Tagesabhaengiges Design — Day-Phase-System.
//
// FEATURE: Jede Welt behaelt ihren Akzent-Farbton, aber die Atmosphaere
// (Helligkeit + Waerme + ein subtiler Farb-Scrim) verschiebt sich nach
// Tageszeit. 4 Phasen: Morgen / Tag / Abend / Nacht.
//
// Verwendung:
//   Positioned.fill(child: IgnorePointer(child: TimeOfDayOverlay(world: w)))
// als oberster atmosphaerischer Layer im Welt-Stack (wie die Vignette).

import 'package:flutter/material.dart';

import 'wb_design.dart';

enum DayPhase { morning, day, evening, night }

/// Aktuelle Tagesphase aus der Uhrzeit.
///   05-11 Morgen · 11-17 Tag · 17-22 Abend · sonst Nacht
DayPhase currentDayPhase([DateTime? now]) {
  final h = (now ?? DateTime.now()).hour;
  if (h >= 5 && h < 11) return DayPhase.morning;
  if (h >= 11 && h < 17) return DayPhase.day;
  if (h >= 17 && h < 22) return DayPhase.evening;
  return DayPhase.night;
}

extension DayPhaseLabel on DayPhase {
  String get label {
    switch (this) {
      case DayPhase.morning:
        return 'Morgen';
      case DayPhase.day:
        return 'Tag';
      case DayPhase.evening:
        return 'Abend';
      case DayPhase.night:
        return 'Nacht';
    }
  }

  IconData get icon {
    switch (this) {
      case DayPhase.morning:
        return Icons.wb_twilight_rounded;
      case DayPhase.day:
        return Icons.wb_sunny_rounded;
      case DayPhase.evening:
        return Icons.nightlight_round;
      case DayPhase.night:
        return Icons.dark_mode_rounded;
    }
  }
}

/// Subtiler tageszeitabhaengiger Scrim-Gradient ueber dem Welt-Hintergrund.
/// Mischt eine Phasen-Farbe mit dem Welt-Akzent (sehr niedrige Deckkraft,
/// damit die Welt-Identitaet dominant bleibt).
class TimeOfDayOverlay extends StatelessWidget {
  final String world;

  /// Erlaubt Tests/Previews eine feste Phase zu erzwingen.
  final DayPhase? phaseOverride;

  const TimeOfDayOverlay({super.key, required this.world, this.phaseOverride});

  @override
  Widget build(BuildContext context) {
    final phase = phaseOverride ?? currentDayPhase();
    final accent = WbDesign.accent(world);

    // (topColor, bottomColor) je Phase. Werte bewusst niedrig-deckend.
    late final Color top;
    late final Color bottom;
    switch (phase) {
      case DayPhase.morning:
        // Warmer Dämmerungs-Glow oben, leicht aufhellend.
        top = const Color(0xFFFFB07C).withValues(alpha: 0.12);
        bottom = accent.withValues(alpha: 0.04);
        break;
      case DayPhase.day:
        // Klar, fast neutral — minimaler kühler Lichtschimmer.
        top = Colors.white.withValues(alpha: 0.04);
        bottom = accent.withValues(alpha: 0.03);
        break;
      case DayPhase.evening:
        // Goldene/warme Abendstimmung.
        top = const Color(0xFFFF8C42).withValues(alpha: 0.13);
        bottom = const Color(0xFF3A1E5C).withValues(alpha: 0.10);
        break;
      case DayPhase.night:
        // Tiefes Indigo, gesamtes Bild dunkler + kühler.
        top = const Color(0xFF050516).withValues(alpha: 0.22);
        bottom = const Color(0xFF02010A).withValues(alpha: 0.30);
        break;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      child: DecoratedBox(
        key: ValueKey(phase),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [top, bottom],
          ),
        ),
      ),
    );
  }
}
