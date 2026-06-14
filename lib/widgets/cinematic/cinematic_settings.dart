/// Kaninchenbau Cinema-Postprocessing — Qualitaets-Einstellung (persistent).
library;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CinematicQuality { off, subtle, cinema, auto }

extension CinematicQualityLabel on CinematicQuality {
  String get label {
    switch (this) {
      case CinematicQuality.off:
        return 'Aus';
      case CinematicQuality.subtle:
        return 'Subtil';
      case CinematicQuality.cinema:
        return 'Kino';
      case CinematicQuality.auto:
        return 'Auto';
    }
  }

  /// Master-Basis-Intensitaet (0..1) fuer den Shader. Auto startet bei Subtil
  /// und wird vom Frame-Time-Watchdog ggf. heruntergeregelt.
  double get baseMaster {
    switch (this) {
      case CinematicQuality.off:
        return 0.0;
      case CinematicQuality.subtle:
        return 0.5;
      case CinematicQuality.cinema:
        return 1.0;
      case CinematicQuality.auto:
        return 0.5;
    }
  }
}

/// Globaler Einstellungs-Store (Singleton, persistent via SharedPreferences).
class KbCinemaSettings {
  KbCinemaSettings._();
  static final KbCinemaSettings instance = KbCinemaSettings._();

  // v2: Default auf "off" geaendert + Key-Bump, weil der Fragment-Shader
  // (AnimatedSampler) auf manchen Android-GPUs den gesamten Inhalt schwarz
  // rendert. Der Auto-Watchdog faengt nur Ruckler ab, nicht schwarze Ausgabe,
  // d.h. Auto blieb dauerhaft schwarz. Cinema-Effekt ist jetzt opt-in via Chip.
  static const _key = 'kb_cinema_quality_v2';

  final ValueNotifier<CinematicQuality> quality =
      ValueNotifier<CinematicQuality>(CinematicQuality.off);

  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final p = await SharedPreferences.getInstance();
      final v = p.getString(_key);
      if (v != null) {
        quality.value = CinematicQuality.values.firstWhere(
          (e) => e.name == v,
          orElse: () => CinematicQuality.off,
        );
      }
    } catch (_) {
      // Default bleibt Aus.
    }
  }

  Future<void> set(CinematicQuality q) async {
    quality.value = q;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_key, q.name);
    } catch (_) {
      // ignore persist errors
    }
  }
}
