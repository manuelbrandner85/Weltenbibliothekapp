// WbQuality -- zentrale, adaptive Effekt-Qualitaet.
//
// Single source of truth dafuer, WIE viel visueller Aufwand gerade vertretbar
// ist. Kombiniert zwei Eingaben:
//   1. Geraete-Faehigkeit (WbDeviceCapability, fix pro Geraet)
//   2. Nutzer-Einstellung (KbCinemaSettings: off/subtil/kino/auto)
//
// Alle teuren Effekte (Ambient-Videos, Shader, Partikel, Entrance-Animationen)
// sollten ihre Entscheidung HIER abfragen, statt eigene Heuristiken zu bauen.
//
// Hinweis: OS-Reduce-Motion ist kontextabhaengig (MediaQuery) und wird daher
// zusaetzlich auf Widget-Ebene geprueft -- nicht hier (global).

import 'package:flutter/foundation.dart';

import 'wb_device_capability.dart';
import '../../widgets/cinematic/cinematic_settings.dart';

/// Effektive Gesamt-Qualitaetsstufe.
enum WbQualityLevel {
  /// Nur statisch -- keine teuren Effekte (schwaches Geraet ODER Nutzer = Aus).
  minimal,

  /// Standard -- dezente Bewegung, Ambient erlaubt, keine Schwergewichte.
  balanced,

  /// Volle Effekte -- nur auf starken Geraeten + Nutzer = Kino.
  full,
}

class WbQuality {
  WbQuality._();

  /// Auf Aenderungen der Nutzer-Einstellung hoeren (z.B. via
  /// `ValueListenableBuilder(valueListenable: WbQuality.listenable, ...)`).
  static Listenable get listenable => KbCinemaSettings.instance.quality;

  static CinematicQuality get _userQuality =>
      KbCinemaSettings.instance.quality.value;

  /// Aktuelle effektive Stufe (Geraet x Nutzer-Einstellung).
  static WbQualityLevel get level {
    if (_userQuality == CinematicQuality.off) return WbQualityLevel.minimal;

    final tier = WbDeviceCapability.tier;
    if (tier == WbDeviceTier.low) return WbQualityLevel.minimal;

    if (_userQuality == CinematicQuality.cinema && tier == WbDeviceTier.high) {
      return WbQualityLevel.full;
    }
    return WbQualityLevel.balanced;
  }

  // ── Capability-Getter (das fragen Effekte ab) ────────────────────────────

  /// Bewegte Ambient-Hintergrund-Videos vertretbar?
  static bool get ambientVideo =>
      level != WbQualityLevel.minimal && WbDeviceCapability.allowsAmbientVideo;

  /// Schwergewichtige Effekte (extra Partikel-Layer, voller Shader)?
  static bool get heavyEffects => level == WbQualityLevel.full;

  /// Entrance-/Staggered-Animationen abspielen?
  static bool get entranceAnimations => level != WbQualityLevel.minimal;

  /// Tap-Scale ist immer guenstig -> immer erlaubt (Reduce-Motion separat).
  static bool get tapScale => true;

  /// Shader-Master-Intensitaet 0..1 (kombiniert Nutzer-Basis + Geraete-Cap).
  static double get shaderIntensity {
    if (level == WbQualityLevel.minimal) return 0.0;
    final base = _userQuality.baseMaster;
    return level == WbQualityLevel.full ? base : (base * 0.7).clamp(0.0, 1.0);
  }

  @visibleForTesting
  static String debugSummary() =>
      'level=$level tier=${WbDeviceCapability.tier} user=$_userQuality '
      'ambientVideo=$ambientVideo heavy=$heavyEffects entrance=$entranceAnimations';
}
