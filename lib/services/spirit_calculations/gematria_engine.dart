/// 🔯 GEMATRIA-BERECHNUNGS-ENGINE
/// 
/// Basiert auf klassischen Gematria-Systemen
/// Quellen: Hebräische Kabbala, Lateinische Numerologie
/// 
/// Berechnungsmethoden:
/// - Hebräische Gematria (Mispar Hechrachi - Standard)
/// - Mispar Gadol (mit Endbuchstaben)
/// - Mispar Katan (reduzierte Werte)
/// - Mispar Siduri (Ordinalwerte 1-22)
/// - Lateinische Gematria (A=1...Z=26)
/// - Englische Gematria (A=6, B=12, C=18...)
/// - Zahlenwort-Korrelationen
/// - Symbol-Zahlen-Resonanz
library;

class GematriaEngine {
  /// Hebräisches Alphabet mit Standardwerten (Mispar Hechrachi)
  static const Map<String, int> _hebrewStandard = {
    'א': 1, // Aleph
    'ב': 2, // Bet
    'ג': 3, // Gimel
    'ד': 4, // Dalet
    'ה': 5, // He
    'ו': 6, // Vav
    'ז': 7, // Zayin
    'ח': 8, // Het
    'ט': 9, // Tet
    'י': 10, // Yod
    'כ': 20, // Kaf
    'ל': 30, // Lamed
    'מ': 40, // Mem
    'נ': 50, // Nun
    'ס': 60, // Samekh
    'ע': 70, // Ayin
    'פ': 80, // Pe
    'צ': 90, // Tsadi
    'ק': 100, // Qof
    'ר': 200, // Resh
    'ש': 300, // Shin
    'ת': 400, // Tav
    // Endbuchstaben (Sofit) - Standard gleich wie Normalbuchstaben
    'ך': 20, // Kaf Sofit (in Mispar Gadol: 500)
    'ם': 40, // Mem Sofit (in Mispar Gadol: 600)
    'ן': 50, // Nun Sofit (in Mispar Gadol: 700)
    'ף': 80, // Pe Sofit (in Mispar Gadol: 800)
    'ץ': 90, // Tsadi Sofit (in Mispar Gadol: 900)
  };

  /// Hebräische Endbuchstaben mit erweiterten Werten (Mispar Gadol)
  static const Map<String, int> _hebrewGadol = {
    'ך': 500, // Kaf Sofit
    'ם': 600, // Mem Sofit
    'ן': 700, // Nun Sofit
    'ף': 800, // Pe Sofit
    'ץ': 900, // Tsadi Sofit
  };

  /// Lateinisches Alphabet (Simple: A=1...Z=26)
  static const Map<String, int> _latinSimple = {
    'A': 1, 'B': 2, 'C': 3, 'D': 4, 'E': 5, 'F': 6, 'G': 7, 'H': 8, 'I': 9,
    'J': 10, 'K': 11, 'L': 12, 'M': 13, 'N': 14, 'O': 15, 'P': 16, 'Q': 17,
    'R': 18, 'S': 19, 'T': 20, 'U': 21, 'V': 22, 'W': 23, 'X': 24, 'Y': 25, 'Z': 26,
  };

  /// Englische Gematria (A=6, B=12, C=18...)
  static const Map<String, int> _englishGematria = {
    'A': 6, 'B': 12, 'C': 18, 'D': 24, 'E': 30, 'F': 36, 'G': 42, 'H': 48, 'I': 54,
    'J': 60, 'K': 66, 'L': 72, 'M': 78, 'N': 84, 'O': 90, 'P': 96, 'Q': 102,
    'R': 108, 'S': 114, 'T': 120, 'U': 126, 'V': 132, 'W': 138, 'X': 144, 'Y': 150, 'Z': 156,
  };

  /// Berechne Hebräische Gematria (Standard - Mispar Hechrachi)
  static int calculateHebrewStandard(String text) {
    int sum = 0;
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      if (_hebrewStandard.containsKey(char)) {
        sum += _hebrewStandard[char]!;
      }
    }
    return sum;
  }

  /// Berechne Hebräische Gematria mit Endbuchstaben (Mispar Gadol)
  static int calculateHebrewGadol(String text) {
    int sum = 0;
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      
      // Prüfe zuerst auf Endbuchstaben
      if (_hebrewGadol.containsKey(char)) {
        sum += _hebrewGadol[char]!;
      } else if (_hebrewStandard.containsKey(char)) {
        sum += _hebrewStandard[char]!;
      }
    }
    return sum;
  }

  /// Berechne Mispar Katan (Reduzierte Werte 1-9)
  static int calculateHebrewKatan(String text) {
    final standard = calculateHebrewStandard(text);
    return _reduceToSingleDigit(standard);
  }

  /// Berechne Lateinische Gematria (Simple)
  static int calculateLatinSimple(String text) {
    int sum = 0;
    final upperText = text.toUpperCase();
    
    for (int i = 0; i < upperText.length; i++) {
      final char = upperText[i];
      if (_latinSimple.containsKey(char)) {
        sum += _latinSimple[char]!;
      }
    }
    return sum;
  }

  /// Berechne Englische Gematria
  static int calculateEnglishGematria(String text) {
    int sum = 0;
    final upperText = text.toUpperCase();
    
    for (int i = 0; i < upperText.length; i++) {
      final char = upperText[i];
      if (_englishGematria.containsKey(char)) {
        sum += _englishGematria[char]!;
      }
    }
    return sum;
  }

  /// Berechne Pythagoräische Reduktion (wie Numerologie)
  static int calculatePythagorean(String text) {
    final latinValue = calculateLatinSimple(text);
    return _reduceToSingleDigit(latinValue);
  }

  /// Berechne Isopsephie (Griechisch, hier vereinfacht als Lateinisch)
  static int calculateIsopsephy(String text) {
    return calculateLatinSimple(text);
  }

  /// Berechne Wort-Zahl-Resonanz
  /// Vergleicht numerologischen Wert mit Gematria-Wert
  static Map<String, dynamic> calculateWordNumberResonance(
    String word,
    int targetNumber,
  ) {
    final latin = calculateLatinSimple(word);
    final pythagorean = calculatePythagorean(word);
    final english = calculateEnglishGematria(word);

    final resonances = <String, bool>{
      'Latin': latin == targetNumber,
      'Pythagorean': pythagorean == targetNumber,
      'English': english == targetNumber,
    };

    final hasResonance = resonances.values.any((v) => v);

    return {
      'word': word,
      'targetNumber': targetNumber,
      'latinValue': latin,
      'pythagoreanValue': pythagorean,
      'englishValue': english,
      'resonances': resonances,
      'hasResonance': hasResonance,
    };
  }

  /// Finde Wörter mit gleichem Gematria-Wert
  static List<String> findEquivalentWords(
    String word,
    List<String> wordList,
    String system,
  ) {
    final targetValue = _calculateBySystem(word, system);
    final equivalents = <String>[];

    for (final testWord in wordList) {
      if (testWord != word) {
        final testValue = _calculateBySystem(testWord, system);
        if (testValue == targetValue) {
          equivalents.add(testWord);
        }
      }
    }

    return equivalents;
  }

  /// Berechne Buchstaben-Häufigkeit im Namen
  static Map<String, int> calculateLetterFrequency(String text) {
    final frequency = <String, int>{};
    final upperText = text.toUpperCase();

    for (int i = 0; i < upperText.length; i++) {
      final char = upperText[i];
      if (_latinSimple.containsKey(char)) {
        frequency[char] = (frequency[char] ?? 0) + 1;
      }
    }

    return frequency;
  }

  /// Analysiere Namen für versteckte Zahlen
  static Map<String, dynamic> analyzeNameForNumbers(String firstName, String lastName) {
    final fullName = '$firstName $lastName';
    
    return {
      'fullName': fullName,
      'latinSimple': calculateLatinSimple(fullName),
      'pythagorean': calculatePythagorean(fullName),
      'englishGematria': calculateEnglishGematria(fullName),
      'firstNameValue': calculateLatinSimple(firstName),
      'lastNameValue': calculateLatinSimple(lastName),
      'letterFrequency': calculateLetterFrequency(fullName),
      'totalLetters': fullName.replaceAll(' ', '').length,
    };
  }

  /// Berechne Datum-Wort-Relation
  static Map<String, dynamic> calculateDateWordRelation(
    DateTime date,
    String word,
  ) {
    final dateNumber = date.day + date.month + date.year;
    final dateReduced = _reduceToSingleDigit(dateNumber);
    
    final wordValue = calculateLatinSimple(word);
    final wordReduced = _reduceToSingleDigit(wordValue);

    return {
      'date': date,
      'word': word,
      'dateNumber': dateNumber,
      'dateReduced': dateReduced,
      'wordValue': wordValue,
      'wordReduced': wordReduced,
      'match': dateReduced == wordReduced,
      'resonanceStrength': (dateReduced - wordReduced).abs(),
    };
  }

  /// Hilfsmethode: Berechnung nach System
  static int _calculateBySystem(String text, String system) {
    switch (system.toLowerCase()) {
      case 'hebrew':
      case 'hebräisch':
        return calculateHebrewStandard(text);
      case 'hebrew_gadol':
        return calculateHebrewGadol(text);
      case 'latin':
      case 'lateinisch':
        return calculateLatinSimple(text);
      case 'english':
      case 'englisch':
        return calculateEnglishGematria(text);
      case 'pythagorean':
        return calculatePythagorean(text);
      default:
        return calculateLatinSimple(text);
    }
  }

  /// Hilfsmethode: Auf einzelne Ziffer reduzieren
  static int _reduceToSingleDigit(int number) {
    while (number > 9) {
      int sum = 0;
      while (number > 0) {
        sum += number % 10;
        number ~/= 10;
      }
      number = sum;
    }
    return number;
  }

  /// Bekannte Gematria-Werte (Beispiele)
  static Map<String, dynamic> getKnownGematriaValues() {
    return {
      'LOVE': {
        'latin': calculateLatinSimple('LOVE'),
        'meaning': 'Liebe, Verbindung',
      },
      'TRUTH': {
        'latin': calculateLatinSimple('TRUTH'),
        'meaning': 'Wahrheit, Klarheit',
      },
      'WISDOM': {
        'latin': calculateLatinSimple('WISDOM'),
        'meaning': 'Weisheit, Erkenntnis',
      },
      'LIGHT': {
        'latin': calculateLatinSimple('LIGHT'),
        'meaning': 'Licht, Erleuchtung',
      },
    };
  }

  // Wrapper-Methoden für einfachere API
  static int calculateHebrewGematria(String text) => calculateHebrewStandard(text);
  static int calculateLatinGematria(String text) => calculateLatinSimple(text);
  static int calculateOrdinalGematria(String text) => calculateLatinSimple(text);
  static int calculateReducedGematria(String text) => calculatePythagorean(text);
}
