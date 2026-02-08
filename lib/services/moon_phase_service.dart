/// Moon Phase Service
/// Berechnet Mondphasen basierend auf astronomischen Formeln
library;
import 'dart:math' as math;
import 'package:flutter/foundation.dart';

class MoonPhaseService {
  static final MoonPhaseService _instance = MoonPhaseService._internal();
  factory MoonPhaseService() => _instance;
  MoonPhaseService._internal();

  /// Berechnet die aktuelle Mondphase
  MoonPhaseData getCurrentMoonPhase() {
    final now = DateTime.now().toUtc();
    return calculateMoonPhase(now);
  }

  /// Berechnet Mondphase für ein bestimmtes Datum
  MoonPhaseData calculateMoonPhase(DateTime date) {
    // Julian Date berechnen
    final jd = _toJulianDate(date);
    
    // Tage seit bekanntem Neumond (1. Januar 2000, 18:14 UTC)
    const knownNewMoon = 2451550.1; // JD für Neumond am 6. Januar 2000
    final daysSinceNewMoon = jd - knownNewMoon;
    
    // Synodischer Monat (durchschnittliche Dauer eines Mondzyklus)
    const synodicMonth = 29.53058867;
    
    // Aktuelle Phase im Zyklus (0.0 = Neumond, 0.5 = Vollmond)
    final phase = (daysSinceNewMoon % synodicMonth) / synodicMonth;
    
    // Beleuchtung berechnen (0.0 = Neumond, 1.0 = Vollmond)
    final illumination = (1 - math.cos(phase * 2 * math.pi)) / 2;
    
    // Phase-Name und Details bestimmen
    final phaseInfo = _getPhaseInfo(phase);
    
    // Nächste Mondphasen berechnen
    final nextPhases = _calculateNextPhases(jd, phase, synodicMonth);
    
    if (kDebugMode) {
      debugPrint('🌙 Moon Phase Service: Phase=$phase, Illumination=${(illumination * 100).toStringAsFixed(1)}%');
    }
    
    return MoonPhaseData(
      phaseName: phaseInfo['name']!,
      phaseEmoji: phaseInfo['emoji']!,
      illumination: illumination,
      phaseAngle: phase * 360,
      date: date,
      description: phaseInfo['description']!,
      energyDescription: phaseInfo['energy']!,
      recommendedActivities: phaseInfo['activities'] as List<String>,
      nextNewMoon: nextPhases['newMoon']!,
      nextFullMoon: nextPhases['fullMoon']!,
      nextFirstQuarter: nextPhases['firstQuarter']!,
      nextLastQuarter: nextPhases['lastQuarter']!,
    );
  }

  /// Konvertiert DateTime zu Julian Date
  double _toJulianDate(DateTime date) {
    final y = date.year;
    final m = date.month;
    final d = date.day + 
             (date.hour + 
             (date.minute + 
             date.second / 60.0) / 60.0) / 24.0;
    
    final a = (14 - m) ~/ 12;
    final y1 = y + 4800 - a;
    final m1 = m + 12 * a - 3;
    
    final jdn = d + 
                (153 * m1 + 2) ~/ 5 + 
                365 * y1 + 
                y1 ~/ 4 - 
                y1 ~/ 100 + 
                y1 ~/ 400 - 
                32045;
    
    return jdn;
  }

  /// Bestimmt Phase-Informationen basierend auf Phase-Wert
  Map<String, dynamic> _getPhaseInfo(double phase) {
    if (phase < 0.03 || phase > 0.97) {
      // Neumond
      return {
        'name': 'Neumond',
        'emoji': '🌑',
        'description': 'Der Mond ist zwischen Erde und Sonne positioniert und von der Erde aus nicht sichtbar.',
        'energy': 'Zeit für Neuanfänge, Intentionen setzen und innere Einkehr. Perfekt für Meditation und Selbstreflexion.',
        'activities': [
          '🎯 Neue Ziele und Intentionen setzen',
          '🧘 Meditation und innere Einkehr',
          '📝 Journaling und Selbstreflexion',
          '🌱 Neue Projekte beginnen',
        ],
      };
    } else if (phase < 0.22) {
      // Zunehmende Sichel
      return {
        'name': 'Zunehmende Sichel',
        'emoji': '🌒',
        'description': 'Der Mond zeigt eine schmale, zunehmende Sichel am westlichen Himmel nach Sonnenuntergang.',
        'energy': 'Wachsende Energie für Manifestation und erste Schritte. Zeit, um Pläne in die Tat umzusetzen.',
        'activities': [
          '💪 Aktiv werden und erste Schritte machen',
          '📋 Pläne konkretisieren',
          '🤝 Neue Kontakte knüpfen',
          '💡 Kreative Ideen entwickeln',
        ],
      };
    } else if (phase < 0.28) {
      // Erstes Viertel
      return {
        'name': 'Erstes Viertel',
        'emoji': '🌓',
        'description': 'Der Mond ist zur Hälfte beleuchtet und steht im rechten Winkel zur Sonne.',
        'energy': 'Herausforderungen annehmen und Hindernisse überwinden. Zeit für Entscheidungen und Handlungen.',
        'activities': [
          '⚡ Herausforderungen aktiv angehen',
          '✅ Wichtige Entscheidungen treffen',
          '🎯 Ziele konkret verfolgen',
          '🔧 Probleme lösen',
        ],
      };
    } else if (phase < 0.47) {
      // Zunehmender Mond
      return {
        'name': 'Zunehmender Mond',
        'emoji': '🌔',
        'description': 'Der Mond ist zu mehr als der Hälfte beleuchtet und wächst weiter zum Vollmond.',
        'energy': 'Maximale Wachstumsenergie und Aufbau. Perfekte Zeit für Expansion und persönliche Entwicklung.',
        'activities': [
          '🚀 Projekte vorantreiben',
          '📈 Wachstum und Expansion fokussieren',
          '💰 Finanzielle Ziele verfolgen',
          '🎓 Neues Wissen erwerben',
        ],
      };
    } else if (phase < 0.53) {
      // Vollmond
      return {
        'name': 'Vollmond',
        'emoji': '🌕',
        'description': 'Der Mond steht der Sonne gegenüber und ist vollständig von der Erde aus beleuchtet.',
        'energy': 'Höhepunkt der Energie, Manifestation und Dankbarkeit. Zeit für Loslassen und Abschlüsse.',
        'activities': [
          '🙏 Dankbarkeit praktizieren',
          '✨ Manifestationen feiern',
          '🔓 Loslassen von Altem',
          '🌟 Energie-Rituale durchführen',
        ],
      };
    } else if (phase < 0.72) {
      // Abnehmender Mond
      return {
        'name': 'Abnehmender Mond',
        'emoji': '🌖',
        'description': 'Der Mond nimmt ab und die Beleuchtung reduziert sich von der linken Seite.',
        'energy': 'Dankbarkeit und Reflexion. Zeit, um Errungenschaften zu würdigen und sich auszuruhen.',
        'activities': [
          '📖 Erkenntnisse reflektieren',
          '🎉 Erfolge feiern',
          '💫 Energie teilen und weitergeben',
          '🤗 Dankbarkeit ausdrücken',
        ],
      };
    } else if (phase < 0.78) {
      // Letztes Viertel
      return {
        'name': 'Letztes Viertel',
        'emoji': '🌗',
        'description': 'Der Mond ist zur Hälfte beleuchtet, diesmal auf der linken Seite.',
        'energy': 'Loslassen und Reinigung. Zeit, um Altes abzuschließen und Platz für Neues zu schaffen.',
        'activities': [
          '🧹 Aufräumen und Ausmisten',
          '🔄 Alte Gewohnheiten loslassen',
          '💭 Vergeben und vergessen',
          '🌊 Emotionale Reinigung',
        ],
      };
    } else {
      // Abnehmende Sichel
      return {
        'name': 'Abnehmende Sichel',
        'emoji': '🌘',
        'description': 'Eine schmale Sichel am östlichen Himmel vor Sonnenaufgang, kurz vor Neumond.',
        'energy': 'Innere Ruhe und Vorbereitung. Zeit für Ruhe, Heilung und Vorbereitung auf den nächsten Zyklus.',
        'activities': [
          '😌 Ruhe und Entspannung',
          '🛀 Selbstfürsorge praktizieren',
          '🩹 Heilung und Regeneration',
          '🔮 Intuition stärken',
        ],
      };
    }
  }

  /// Berechnet die nächsten wichtigen Mondphasen
  Map<String, DateTime> _calculateNextPhases(double currentJd, double currentPhase, double synodicMonth) {
    // Tage bis zur nächsten Phase berechnen
    final daysToNewMoon = currentPhase > 0.5 
        ? (1.0 - currentPhase) * synodicMonth 
        : (1.0 - currentPhase) * synodicMonth;
    
    final daysToFullMoon = currentPhase < 0.5 
        ? (0.5 - currentPhase) * synodicMonth 
        : (1.5 - currentPhase) * synodicMonth;
    
    final daysToFirstQuarter = currentPhase < 0.25 
        ? (0.25 - currentPhase) * synodicMonth 
        : (1.25 - currentPhase) * synodicMonth;
    
    final daysToLastQuarter = currentPhase < 0.75 
        ? (0.75 - currentPhase) * synodicMonth 
        : (1.75 - currentPhase) * synodicMonth;
    
    // DateTime berechnen
    final now = DateTime.now().toUtc();
    
    return {
      'newMoon': now.add(Duration(days: daysToNewMoon.round())),
      'fullMoon': now.add(Duration(days: daysToFullMoon.round())),
      'firstQuarter': now.add(Duration(days: daysToFirstQuarter.round())),
      'lastQuarter': now.add(Duration(days: daysToLastQuarter.round())),
    };
  }

  /// Berechnet Mondphasen für einen Datumsbereich
  List<MoonPhaseData> getMoonPhasesForRange(DateTime start, DateTime end) {
    final phases = <MoonPhaseData>[];
    var current = start;
    
    while (current.isBefore(end)) {
      phases.add(calculateMoonPhase(current));
      current = current.add(const Duration(days: 1));
    }
    
    return phases;
  }
}

/// Moon Phase Data Model
class MoonPhaseData {
  final String phaseName;
  final String phaseEmoji;
  final double illumination; // 0.0 - 1.0
  final double phaseAngle; // 0 - 360 Grad
  final DateTime date;
  final String description;
  final String energyDescription;
  final List<String> recommendedActivities;
  final DateTime nextNewMoon;
  final DateTime nextFullMoon;
  final DateTime nextFirstQuarter;
  final DateTime nextLastQuarter;

  MoonPhaseData({
    required this.phaseName,
    required this.phaseEmoji,
    required this.illumination,
    required this.phaseAngle,
    required this.date,
    required this.description,
    required this.energyDescription,
    required this.recommendedActivities,
    required this.nextNewMoon,
    required this.nextFullMoon,
    required this.nextFirstQuarter,
    required this.nextLastQuarter,
  });

  /// Formatierter Beleuchtungsprozent
  String get illuminationPercent => '${(illumination * 100).toStringAsFixed(0)}%';

  /// Ist es Vollmond (> 95% beleuchtet)
  bool get isFullMoon => illumination > 0.95;

  /// Ist es Neumond (< 5% beleuchtet)
  bool get isNewMoon => illumination < 0.05;

  /// Ist der Mond zunehmend
  bool get isWaxing => phaseAngle < 180;

  /// Ist der Mond abnehmend
  bool get isWaning => phaseAngle >= 180;

  @override
  String toString() {
    return 'MoonPhase: $phaseName $phaseEmoji ($illuminationPercent)';
  }
}
