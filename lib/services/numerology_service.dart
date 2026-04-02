
/// NUMEROLOGIE SERVICE
/// Berechnet Lebenszahl, Namensschwingung, Seelenzahl, Ausdruckszahl
class NumerologyService {
  static final NumerologyService _instance = NumerologyService._internal();
  factory NumerologyService() => _instance;
  NumerologyService._internal();

  /// Buchstaben zu Zahlen Mapping (Pythagoräische Numerologie)
  static const Map<String, int> _letterValues = {
    'A': 1, 'B': 2, 'C': 3, 'D': 4, 'E': 5, 'F': 6, 'G': 7, 'H': 8, 'I': 9,
    'J': 1, 'K': 2, 'L': 3, 'M': 4, 'N': 5, 'O': 6, 'P': 7, 'Q': 8, 'R': 9,
    'S': 1, 'T': 2, 'U': 3, 'V': 4, 'W': 5, 'X': 6, 'Y': 7, 'Z': 8,
    'Ä': 1, 'Ö': 6, 'Ü': 3, 'ß': 1,
  };

  /// Vokale für Seelenzahl
  static const Set<String> _vowels = {'A', 'E', 'I', 'O', 'U', 'Ä', 'Ö', 'Ü'};

  /// LEBENSZAHL - Aus Geburtsdatum
  /// Beispiel: 15.03.1985 → 1+5+3+1+9+8+5 = 32 → 3+2 = 5
  int calculateLifePath(DateTime birthDate) {
    final day = birthDate.day;
    final month = birthDate.month;
    final year = birthDate.year;
    
    final sum = _sumDigits(day) + _sumDigits(month) + _sumDigits(year);
    return _reduceToSingleDigit(sum);
  }

  /// NAMENSSCHWINGUNG - Gesamtzahl aus Vor- und Nachname
  int calculateNameVibration(String firstName, String lastName) {
    final fullName = (firstName + lastName).toUpperCase().replaceAll(' ', '');
    int sum = 0;
    
    for (int i = 0; i < fullName.length; i++) {
      final char = fullName[i];
      sum += _letterValues[char] ?? 0;
    }
    
    return _reduceToSingleDigit(sum);
  }

  /// SEELENZAHL - Nur Vokale des vollständigen Namens
  int calculateSoulNumber(String firstName, String lastName) {
    final fullName = (firstName + lastName).toUpperCase().replaceAll(' ', '');
    int sum = 0;
    
    for (int i = 0; i < fullName.length; i++) {
      final char = fullName[i];
      if (_vowels.contains(char)) {
        sum += _letterValues[char] ?? 0;
      }
    }
    
    return _reduceToSingleDigit(sum);
  }

  /// AUSDRUCKSZAHL - Nur Konsonanten des vollständigen Namens
  int calculateExpressionNumber(String firstName, String lastName) {
    final fullName = (firstName + lastName).toUpperCase().replaceAll(' ', '');
    int sum = 0;
    
    for (int i = 0; i < fullName.length; i++) {
      final char = fullName[i];
      if (!_vowels.contains(char) && _letterValues.containsKey(char)) {
        sum += _letterValues[char] ?? 0;
      }
    }
    
    return _reduceToSingleDigit(sum);
  }

  /// KERNFREQUENZ - Kombinierter Wert aller Zahlen
  /// Gewichtung: Lebenszahl 40%, Namensschwingung 30%, Seelenzahl 20%, Ausdruckszahl 10%
  double calculateCoreFrequency(
    DateTime birthDate,
    String firstName,
    String lastName,
  ) {
    final lifePath = calculateLifePath(birthDate);
    final nameVibration = calculateNameVibration(firstName, lastName);
    final soul = calculateSoulNumber(firstName, lastName);
    final expression = calculateExpressionNumber(firstName, lastName);
    
    // Gewichtete Summe
    final frequency = (lifePath * 0.4) + 
                     (nameVibration * 0.3) + 
                     (soul * 0.2) + 
                     (expression * 0.1);
    
    return frequency;
  }

  /// BEDEUTUNG DER LEBENSZAHL
  String getLifePathMeaning(int number) {
    switch (number) {
      case 1:
        return 'Pionier & Führungskraft - Unabhängigkeit, Innovation, Mut';
      case 2:
        return 'Diplomat & Vermittler - Harmonie, Partnerschaft, Sensibilität';
      case 3:
        return 'Künstler & Kommunikator - Kreativität, Ausdruck, Freude';
      case 4:
        return 'Baumeister & Organisator - Stabilität, Ordnung, Disziplin';
      case 5:
        return 'Abenteurer & Wandler - Freiheit, Veränderung, Vielfalt';
      case 6:
        return 'Verantwortungsträger & Heiler - Fürsorge, Familie, Harmonie';
      case 7:
        return 'Forscher & Mystiker - Weisheit, Spiritualität, Analyse';
      case 8:
        return 'Manifestor & Visionär - Macht, Erfolg, Fülle';
      case 9:
        return 'Weltdiener & Vollender - Mitgefühl, Weisheit, Transformation';
      default:
        return 'Unbekannte Schwingung';
    }
  }

  /// FARBE DER KERNFREQUENZ
  /// Bereich 1.0-9.0 → Gradient von Violett zu Gold
  String getCoreFrequencyColor(double frequency) {
    if (frequency < 2.0) return '#9C27B0'; // Lila
    if (frequency < 3.0) return '#BA68C8'; // Hell-Lila
    if (frequency < 4.0) return '#673AB7'; // Indigo
    if (frequency < 5.0) return '#2196F3'; // Blau
    if (frequency < 6.0) return '#00BCD4'; // Cyan
    if (frequency < 7.0) return '#4CAF50'; // Grün
    if (frequency < 8.0) return '#FFC107'; // Gelb
    if (frequency < 9.0) return '#FF9800'; // Orange
    return '#FFD700'; // Gold
  }

  /// HELPER: Summe aller Ziffern einer Zahl
  int _sumDigits(int number) {
    int sum = 0;
    while (number > 0) {
      sum += number % 10;
      number ~/= 10;
    }
    return sum;
  }

  /// HELPER: Reduziere auf einstellige Zahl (außer Meisterzahlen 11, 22, 33)
  int _reduceToSingleDigit(int number) {
    // Meisterzahlen behalten
    if (number == 11 || number == 22 || number == 33) return number;
    
    while (number > 9) {
      number = _sumDigits(number);
    }
    
    return number;
  }

  /// PERSÖNLICHE SIGNATUR BESCHREIBUNG
  String getPersonalSignature(
    DateTime birthDate,
    String firstName,
    String lastName,
  ) {
    final lifePath = calculateLifePath(birthDate);
    final soul = calculateSoulNumber(firstName, lastName);
    final expression = calculateExpressionNumber(firstName, lastName);
    final frequency = calculateCoreFrequency(birthDate, firstName, lastName);
    
    return '''
Du schwingst in der Frequenz ${frequency.toStringAsFixed(1)} - Eine einzigartige Mischung aus:

🔮 Lebenszahl $lifePath: ${getLifePathMeaning(lifePath)}

💫 Seelenzahl $soul: Deine innere Motivation
Konsonanten zeigen: $expression (Äußerer Ausdruck)

Diese Signatur macht dich einzigartig. Sie beeinflusst deine Resonanz mit Menschen, Orten und Ereignissen.
''';
  }
}
