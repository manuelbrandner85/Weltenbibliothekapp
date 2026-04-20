
/// ZYKLUS-ANALYSE SERVICE
/// Berechnet persönliches Jahr, Monat, Tag und 9-Jahres-Zyklen
class CycleAnalysisService {
  static final CycleAnalysisService _instance = CycleAnalysisService._internal();
  factory CycleAnalysisService() => _instance;
  CycleAnalysisService._internal();

  /// PERSÖNLICHES JAHR
  /// Geburtsdatum + aktuelles Jahr
  /// Beispiel: 15.03.1985 + 2025 → 1+5+3+2+0+2+5 = 18 → 1+8 = 9
  int calculatePersonalYear(DateTime birthDate, DateTime currentDate) {
    final day = birthDate.day;
    final month = birthDate.month;
    final year = currentDate.year;
    
    int sum = _sumDigits(day) + _sumDigits(month) + _sumDigits(year);
    return _reduceToSingleDigit(sum);
  }

  /// PERSÖNLICHER MONAT
  /// Persönliches Jahr + aktueller Monat
  int calculatePersonalMonth(DateTime birthDate, DateTime currentDate) {
    final personalYear = calculatePersonalYear(birthDate, currentDate);
    final currentMonth = currentDate.month;
    
    final sum = personalYear + _sumDigits(currentMonth);
    return _reduceToSingleDigit(sum);
  }

  /// PERSÖNLICHER TAG
  /// Persönlicher Monat + aktueller Tag
  int calculatePersonalDay(DateTime birthDate, DateTime currentDate) {
    final personalMonth = calculatePersonalMonth(birthDate, currentDate);
    final currentDay = currentDate.day;
    
    final sum = personalMonth + _sumDigits(currentDay);
    return _reduceToSingleDigit(sum);
  }

  /// GROSSE LEBENSZYKLEN (9-Jahres-Zyklus)
  /// Position im aktuellen 9-Jahres-Zyklus
  Map<String, dynamic> calculateNineYearCycle(DateTime birthDate, DateTime currentDate) {
    final personalYear = calculatePersonalYear(birthDate, currentDate);
    final cyclePosition = personalYear;
    final cycleStart = currentDate.year - (personalYear - 1);
    final cycleEnd = cycleStart + 8;
    
    return {
      'position': cyclePosition,
      'cycleStart': cycleStart,
      'cycleEnd': cycleEnd,
      'phase': _getCyclePhase(cyclePosition),
      'description': _getCycleDescription(cyclePosition),
    };
  }

  /// SCHWELLENJAHRE (Übergangsphasen)
  /// Jahr 9 → 1 ist besonders transformativ
  bool isTransitionYear(DateTime birthDate, DateTime currentDate) {
    final personalYear = calculatePersonalYear(birthDate, currentDate);
    return personalYear == 9 || personalYear == 1;
  }

  /// PHASEN-BESCHREIBUNG FÜR PERSÖNLICHES JAHR
  String getPersonalYearDescription(int year) {
    switch (year) {
      case 1:
        return '''
🌱 NEUBEGINN & PIONIERARBEIT
Ein Jahr der Neuanfänge, Initiativen und Selbstfindung. 
Zeit für mutige Schritte und neue Projekte.
Energie: Aktivierend, initiativ, unabhängig
''';
      case 2:
        return '''
🤝 PARTNERSCHAFT & GEDULD
Ein Jahr der Zusammenarbeit, Harmonie und emotionalen Entwicklung.
Zeit für Beziehungen, Diplomatie und innere Balance.
Energie: Verbindend, sensibel, kooperativ
''';
      case 3:
        return '''
🎨 KREATIVITÄT & AUSDRUCK
Ein Jahr der Selbstentfaltung, Kommunikation und Freude.
Zeit für kreative Projekte, soziale Kontakte und Lebensfreude.
Energie: Ausdrucksstark, inspirierend, kommunikativ
''';
      case 4:
        return '''
🏗️ FUNDAMENT & STRUKTUR
Ein Jahr der Arbeit, Ordnung und praktischen Umsetzung.
Zeit für Aufbau, Disziplin und langfristige Planung.
Energie: Stabilisierend, organisiert, fleißig
''';
      case 5:
        return '''
🌍 FREIHEIT & VERÄNDERUNG
Ein Jahr der Bewegung, Vielfalt und Abenteuer.
Zeit für Reisen, neue Erfahrungen und Flexibilität.
Energie: Dynamisch, abenteuerlich, vielseitig
''';
      case 6:
        return '''
💚 VERANTWORTUNG & FÜRSORGE
Ein Jahr der Familie, Gemeinschaft und Heilung.
Zeit für Beziehungspflege, Harmonie und Selbstfürsorge.
Energie: Liebevoll, verantwortungsvoll, heilend
''';
      case 7:
        return '''
🔮 INNENSCHAU & WEISHEIT
Ein Jahr der Spiritualität, Reflexion und Erkenntnis.
Zeit für Rückzug, Meditation und Selbsterforschung.
Energie: Introspektiv, spirituell, analytisch
''';
      case 8:
        return '''
⚡ MACHT & MANIFESTATION
Ein Jahr der Erfolge, Fülle und materiellen Verwirklichung.
Zeit für geschäftliche Projekte, Autorität und Durchsetzung.
Energie: Kraftvoll, erfolgsorientiert, manifestierend
''';
      case 9:
        return '''
🌟 VOLLENDUNG & TRANSFORMATION
Ein Jahr des Loslassens, der Weisheit und des Neuausrichtens.
Zeit für Abschlüsse, Heilung und universelles Mitgefühl.
Energie: Transformierend, weise, abschließend
''';
      default:
        return 'Unbekannte Energie';
    }
  }

  /// ZYKLUS-PHASE (Anfang, Mitte, Ende)
  String _getCyclePhase(int position) {
    if (position >= 1 && position <= 3) return 'Anfang';
    if (position >= 4 && position <= 6) return 'Mitte';
    return 'Ende';
  }

  /// ZYKLUS-BESCHREIBUNG
  String _getCycleDescription(int position) {
    if (position >= 1 && position <= 3) {
      return 'Aufbauphase: Neue Projekte, Lernen, Entwicklung';
    }
    if (position >= 4 && position <= 6) {
      return 'Reifephase: Stabilität, Verantwortung, Entfaltung';
    }
    return 'Transformationsphase: Loslassen, Weisheit, Vorbereitung auf Neubeginn';
  }

  /// TIMELINE-DATEN FÜR VISUALISIERUNG
  /// Gibt die letzten 3 Jahre, aktuelles Jahr und nächsten 3 Jahre zurück
  List<Map<String, dynamic>> getTimelineData(DateTime birthDate, DateTime currentDate) {
    List<Map<String, dynamic>> timeline = [];
    
    for (int offset = -3; offset <= 3; offset++) {
      final yearDate = DateTime(currentDate.year + offset, birthDate.month, birthDate.day);
      final personalYear = calculatePersonalYear(birthDate, yearDate);
      
      timeline.add({
        'year': yearDate.year,
        'personalYear': personalYear,
        'isCurrent': offset == 0,
        'phase': _getCyclePhase(personalYear),
        'description': getPersonalYearDescription(personalYear),
      });
    }
    
    return timeline;
  }

  /// HELPER: Summe aller Ziffern
  int _sumDigits(int number) {
    int sum = 0;
    while (number > 0) {
      sum += number % 10;
      number ~/= 10;
    }
    return sum;
  }

  /// HELPER: Reduziere auf einstellige Zahl
  int _reduceToSingleDigit(int number) {
    if (number == 11 || number == 22 || number == 33) return number;
    
    while (number > 9) {
      number = _sumDigits(number);
    }
    
    return number;
  }
}
