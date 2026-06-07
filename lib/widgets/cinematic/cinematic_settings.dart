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

  static const _key = 'kb_cinema_quality_v1';

  final ValueNotifier<CinematicQuality> quality =
      ValueNotifier<CinematicQuality>(CinematicQuality.auto);

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
          orElse: () => CinematicQuality.auto,
        );
      }
    } catch (_) {
      // Default bleibt Auto.
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
