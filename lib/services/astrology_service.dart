import 'package:flutter/material.dart';

/// ASTROLOGIE SERVICE
/// Berechnet Sonnenzeichen, Mondzeichen (optional), Aszendent (optional), Elementeverteilung
class AstrologyService {
  static final AstrologyService _instance = AstrologyService._internal();
  factory AstrologyService() => _instance;
  AstrologyService._internal();

  /// SONNENZEICHEN - Basierend auf Geburtsdatum
  Map<String, dynamic> getSunSign(DateTime birthDate) {
    final month = birthDate.month;
    final day = birthDate.day;

    // Sternzeichen-Grenzen
    if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) {
      return _zodiacSigns[0]; // Widder
    } else if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) {
      return _zodiacSigns[1]; // Stier
    } else if ((month == 5 && day >= 21) || (month == 6 && day <= 20)) {
      return _zodiacSigns[2]; // Zwillinge
    } else if ((month == 6 && day >= 21) || (month == 7 && day <= 22)) {
      return _zodiacSigns[3]; // Krebs
    } else if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) {
      return _zodiacSigns[4]; // Löwe
    } else if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) {
      return _zodiacSigns[5]; // Jungfrau
    } else if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) {
      return _zodiacSigns[6]; // Waage
    } else if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) {
      return _zodiacSigns[7]; // Skorpion
    } else if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) {
      return _zodiacSigns[8]; // Schütze
    } else if ((month == 12 && day >= 22) || (month == 1 && day <= 19)) {
      return _zodiacSigns[9]; // Steinbock
    } else if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) {
      return _zodiacSigns[10]; // Wassermann
    } else {
      return _zodiacSigns[11]; // Fische
    }
  }

  /// MONDZEICHEN - Vereinfachte Berechnung (ohne Uhrzeit)
  /// Mond wechselt ca. alle 2.5 Tage das Zeichen
  Map<String, dynamic> getMoonSign(DateTime birthDate) {
    // Vereinfachte Berechnung: Tage seit Referenzpunkt
    final daysSince2000 = birthDate.difference(DateTime(2000, 1, 1)).inDays;
    final moonCycle = (daysSince2000 * 13.176) % 360; // ~13 Umläufe pro Jahr
    final signIndex = (moonCycle / 30).floor() % 12;

    return _zodiacSigns[signIndex];
  }

  /// ASZENDENT - Vereinfachte Berechnung (mit Geburtszeit)
  /// Aszendent wechselt ca. alle 2 Stunden
  Map<String, dynamic>? getAscendant(DateTime birthDate, String? birthTime) {
    if (birthTime == null || birthTime.isEmpty) return null;

    try {
      final parts = birthTime.split(':');
      if (parts.isEmpty) return null;
      // v95 Crash-Fix: tryParse statt parse -- bei ungueltigen Strings
      // wie "XX:YY" gab es einen FormatException-Crash.
      final hour = int.tryParse(parts[0]);
      if (hour == null) return null;
      final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

      // Vereinfacht: 2 Stunden pro Zeichen, startend bei Sonnenaufgang (~6 Uhr)
      final offsetHours = (hour - 6 + (minute / 60)).toDouble();
      final signIndex = ((offsetHours / 2).floor() % 12).abs();

      return _zodiacSigns[signIndex];
    } catch (e) {
      return null;
    }
  }

  /// ELEMENTEVERTEILUNG
  /// Zählt Feuer, Wasser, Luft, Erde aus Sonne, Mond, Aszendent
  Map<String, int> getElementDistribution(
    DateTime birthDate,
    String? birthTime,
  ) {
    final elements = {'Feuer': 0, 'Erde': 0, 'Luft': 0, 'Wasser': 0};

    // Sonnenzeichen
    final sun = getSunSign(birthDate);
    elements[sun['element'] as String] = (elements[sun['element']]! + 1);

    // Mondzeichen
    final moon = getMoonSign(birthDate);
    elements[moon['element'] as String] = (elements[moon['element']]! + 1);

    // Aszendent (falls vorhanden)
    final ascendant = getAscendant(birthDate, birthTime);
    if (ascendant != null) {
      elements[ascendant['element'] as String] =
          (elements[ascendant['element']]! + 1);
    }

    return elements;
  }

  /// DOMINANTES ELEMENT
  String getDominantElement(DateTime birthDate, String? birthTime) {
    final distribution = getElementDistribution(birthDate, birthTime);

    String dominantElement = 'Feuer';
    int maxCount = 0;

    distribution.forEach((element, count) {
      if (count > maxCount) {
        maxCount = count;
        dominantElement = element;
      }
    });

    return dominantElement;
  }

  /// ASTROLOGISCHE PERSÖNLICHKEITS-BESCHREIBUNG
  String getAstrologyProfile(
    DateTime birthDate,
    String? birthTime,
  ) {
    final sun = getSunSign(birthDate);
    final moon = getMoonSign(birthDate);
    final ascendant = getAscendant(birthDate, birthTime);
    final dominant = getDominantElement(birthDate, birthTime);

    final ascText = ascendant != null
        ? '\n🌅 Aszendent: ${ascendant['name']} (${ascendant['element']})'
        : '';

    return '''
☀️ Sonnenzeichen: ${sun['name']} (${sun['element']})
${sun['description']}

🌙 Mondzeichen: ${moon['name']} (${moon['element']})
Emotionale Natur: ${moon['keywords']}$ascText

🔥 Dominantes Element: $dominant
${_getElementDescription(dominant)}
''';
  }

  String _getElementDescription(String element) {
    switch (element) {
      case 'Feuer':
        return 'Leidenschaft, Energie, Kreativität, Spontaneität';
      case 'Erde':
        return 'Stabilität, Praktikabilität, Geduld, Zuverlässigkeit';
      case 'Luft':
        return 'Intellekt, Kommunikation, Freiheit, Sozialität';
      case 'Wasser':
        return 'Emotion, Intuition, Empathie, Tiefe';
      default:
        return '';
    }
  }

  /// STERNZEICHEN-KATALOG
  static final List<Map<String, dynamic>> _zodiacSigns = [
    {
      'name': 'Widder',
      'symbol': '♈',
      'element': 'Feuer',
      'quality': 'Kardinal',
      'keywords': 'Mut, Initiative, Durchsetzung',
      'description': 'Pioniergeist und Tatendrang prägen deine Persönlichkeit.',
      'color': 0xFFFF5252,
      'icon': Icons.whatshot,
    },
    {
      'name': 'Stier',
      'symbol': '♉',
      'element': 'Erde',
      'quality': 'Fix',
      'keywords': 'Stabilität, Genuss, Beharrlichkeit',
      'description': 'Erdverbundenheit und Sinnlichkeit kennzeichnen dich.',
      'color': 0xFF4CAF50,
      'icon': Icons.terrain,
    },
    {
      'name': 'Zwillinge',
      'symbol': '♊',
      'element': 'Luft',
      'quality': 'Veränderlich',
      'keywords': 'Kommunikation, Vielseitigkeit, Neugier',
      'description': 'Flexibilität und Wissensdurst sind deine Stärken.',
      'color': 0xFF2196F3,
      'icon': Icons.air,
    },
    {
      'name': 'Krebs',
      'symbol': '♋',
      'element': 'Wasser',
      'quality': 'Kardinal',
      'keywords': 'Fürsorglichkeit, Emotionalität, Intuition',
      'description': 'Tiefe Gefühle und Empathie prägen dein Wesen.',
      'color': 0xFF00BCD4,
      'icon': Icons.water_drop,
    },
    {
      'name': 'Löwe',
      'symbol': '♌',
      'element': 'Feuer',
      'quality': 'Fix',
      'keywords': 'Selbstbewusstsein, Kreativität, Großzügigkeit',
      'description': 'Strahlkraft und Führungsstärke zeichnen dich aus.',
      'color': 0xFFFFD700,
      'icon': Icons.wb_sunny,
    },
    {
      'name': 'Jungfrau',
      'symbol': '♍',
      'element': 'Erde',
      'quality': 'Veränderlich',
      'keywords': 'Präzision, Analyse, Dienst',
      'description': 'Ordnung und Detailgenauigkeit sind deine Gaben.',
      'color': 0xFF8BC34A,
      'icon': Icons.grass,
    },
    {
      'name': 'Waage',
      'symbol': '♎',
      'element': 'Luft',
      'quality': 'Kardinal',
      'keywords': 'Harmonie, Gerechtigkeit, Ästhetik',
      'description': 'Balance und Schönheit sind dir wichtig.',
      'color': 0xFFE1BEE7,
      'icon': Icons.balance,
    },
    {
      'name': 'Skorpion',
      'symbol': '♏',
      'element': 'Wasser',
      'quality': 'Fix',
      'keywords': 'Intensität, Transformation, Tiefe',
      'description': 'Leidenschaft und Wandlungskraft definieren dich.',
      'color': 0xFF9C27B0,
      'icon': Icons.water,
    },
    {
      'name': 'Schütze',
      'symbol': '♐',
      'element': 'Feuer',
      'quality': 'Veränderlich',
      'keywords': 'Optimismus, Weisheit, Freiheit',
      'description': 'Expansionsdrang und Philosophie begleiten dich.',
      'color': 0xFFFF9800,
      'icon': Icons.explore,
    },
    {
      'name': 'Steinbock',
      'symbol': '♑',
      'element': 'Erde',
      'quality': 'Kardinal',
      'keywords': 'Disziplin, Ambition, Verantwortung',
      'description': 'Zielstrebigkeit und Ausdauer sind deine Basis.',
      'color': 0xFF795548,
      'icon': Icons.landscape,
    },
    {
      'name': 'Wassermann',
      'symbol': '♒',
      'element': 'Luft',
      'quality': 'Fix',
      'keywords': 'Innovation, Unabhängigkeit, Humanität',
      'description': 'Originalität und Zukunftsvision prägen dich.',
      'color': 0xFF00E5FF,
      'icon': Icons.cloud,
    },
    {
      'name': 'Fische',
      'symbol': '♓',
      'element': 'Wasser',
      'quality': 'Veränderlich',
      'keywords': 'Mitgefühl, Spiritualität, Sensibilität',
      'description': 'Einfühlungsvermögen und Transzendenz sind dein Weg.',
      'color': 0xFF7986CB,
      'icon': Icons.graphic_eq,
    },
  ];
}
