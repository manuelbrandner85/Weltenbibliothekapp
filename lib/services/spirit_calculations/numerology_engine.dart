/// 🔢 NUMEROLOGIE-BERECHNUNGS-ENGINE
///
/// Basiert auf historischen pythagoräischen Methoden
/// Quellen: Pythagoras, Chaldean Numerology, Modern Western Numerology
///
/// Berechnungsmethoden:
/// - Lebenszahl (Life Path): Geburtsdatum reduziert
/// - Seelenzahl (Soul Urge): Vokale des Namens
/// - Ausdruckszahl (Expression): Gesamter Name
/// - Persönlichkeitszahl (Personality): Konsonanten
/// - Schicksalszahl (Destiny): Alternative zur Ausdruckszahl
/// - Namenszahl (Name Number): Gesamtname-Schwingung
/// - Herzenswunschzahl: Tiefste Wünsche (Vokale)
/// - Persönliches Jahr/Monat/Tag: Zeitzyklen
/// - Lebenszyklen: 3 große Phasen
/// - Pinnacle-Zyklen: 4 Höhepunkte
/// - Herausforderungszahlen: 4 Lernthemen
/// - Meisterzahlen: 11, 22, 33
/// - Karma-Zahlen: 13, 14, 16, 19
library;

class NumerologyEngine {
  /// Pythagorean Letter Values (A=1, B=2, ..., I=9, J=1, K=2, ...)
  static const Map<String, int> _pythagoreanValues = {
    'A': 1,
    'J': 1,
    'S': 1,
    'B': 2,
    'K': 2,
    'T': 2,
    'C': 3,
    'L': 3,
    'U': 3,
    'D': 4,
    'M': 4,
    'V': 4,
    'E': 5,
    'N': 5,
    'W': 5,
    'F': 6,
    'O': 6,
    'X': 6,
    'G': 7,
    'P': 7,
    'Y': 7,
    'H': 8,
    'Q': 8,
    'Z': 8,
    'I': 9,
    'R': 9,
  };

  /// Chaldean Letter Values (ca. 4000 v.Chr., Babylonien).
  /// WICHTIG: Die 9 ist heilig und keinem Buchstaben zugeordnet.
  /// Basiert auf Klangschwingungen, nicht auf Reihenfolge.
  static const Map<String, int> _chaldeanValues = {
    'A': 1, 'I': 1, 'J': 1, 'Q': 1, 'Y': 1,
    'B': 2, 'K': 2, 'R': 2,
    'C': 3, 'G': 3, 'L': 3, 'S': 3,
    'D': 4, 'M': 4, 'T': 4,
    'E': 5, 'H': 5, 'N': 5, 'X': 5,
    'U': 6, 'V': 6, 'W': 6,
    'O': 7, 'Z': 7,
    'F': 8, 'P': 8,
    // 9 wird KEINEM Buchstaben zugeordnet (heilig).
  };

  static const List<String> _vowels = ['A', 'E', 'I', 'O', 'U'];
  static const List<int> _masterNumbers = [11, 22, 33];
  static const List<int> _karmaNumbers = [13, 14, 16, 19];

  /// Berechne Lebenszahl (Life Path Number)
  /// Methode: Geburtsdatum (Tag + Monat + Jahr) auf eine Ziffer reduzieren
  /// Beispiel: 15.03.1985 → (1+5) + (0+3) + (1+9+8+5) = 6 + 3 + 23 = 32 → 3+2 = 5
  static int calculateLifePath(DateTime birthDate) {
    final day = _reduceToSingleDigit(birthDate.day, keepMaster: true);
    final month = _reduceToSingleDigit(birthDate.month, keepMaster: true);
    final year = _reduceToSingleDigit(birthDate.year, keepMaster: true);

    final sum = day + month + year;
    return _reduceToSingleDigit(sum, keepMaster: true);
  }

  /// Berechne Seelenzahl (Soul Urge / Heart's Desire)
  /// Methode: Nur Vokale des vollständigen Namens
  static int calculateSoulNumber(String firstName, String lastName) {
    final fullName = '$firstName $lastName'.toUpperCase();
    int sum = 0;

    for (int i = 0; i < fullName.length; i++) {
      final char = fullName[i];
      if (_vowels.contains(char) && _pythagoreanValues.containsKey(char)) {
        sum += _pythagoreanValues[char]!;
      }
    }

    return _reduceToSingleDigit(sum, keepMaster: true);
  }

  /// Berechne Ausdruckszahl (Expression / Destiny)
  /// Methode: Alle Buchstaben des vollständigen Namens
  static int calculateExpressionNumber(String firstName, String lastName) {
    final fullName = '$firstName $lastName'.toUpperCase();
    int sum = 0;

    for (int i = 0; i < fullName.length; i++) {
      final char = fullName[i];
      if (_pythagoreanValues.containsKey(char)) {
        sum += _pythagoreanValues[char]!;
      }
    }

    return _reduceToSingleDigit(sum, keepMaster: true);
  }

  /// Berechne Persönlichkeitszahl (Personality Number)
  /// Methode: Nur Konsonanten des Namens
  static int calculatePersonalityNumber(String firstName, String lastName) {
    final fullName = '$firstName $lastName'.toUpperCase();
    int sum = 0;

    for (int i = 0; i < fullName.length; i++) {
      final char = fullName[i];
      if (!_vowels.contains(char) && _pythagoreanValues.containsKey(char)) {
        sum += _pythagoreanValues[char]!;
      }
    }

    return _reduceToSingleDigit(sum, keepMaster: true);
  }

  /// Berechne Namenszahl (Name Vibration)
  /// Identisch mit Ausdruckszahl, separate Methode für Klarheit
  static int calculateNameNumber(String firstName, String lastName) {
    return calculateExpressionNumber(firstName, lastName);
  }

  /// Berechne Persönliches Jahr (Personal Year)
  /// Methode: Geburtstag + Geburtsmonat + aktuelles Jahr
  static int calculatePersonalYear(DateTime birthDate, DateTime currentDate) {
    final birthDay = _reduceToSingleDigit(birthDate.day, keepMaster: false);
    final birthMonth = _reduceToSingleDigit(birthDate.month, keepMaster: false);
    final currentYear =
        _reduceToSingleDigit(currentDate.year, keepMaster: false);

    final sum = birthDay + birthMonth + currentYear;
    return _reduceToSingleDigit(sum, keepMaster: false);
  }

  /// Berechne Persönlichen Monat (Personal Month)
  /// Methode: Persönliches Jahr + aktueller Monat
  static int calculatePersonalMonth(DateTime birthDate, DateTime currentDate) {
    final personalYear = calculatePersonalYear(birthDate, currentDate);
    final currentMonth =
        _reduceToSingleDigit(currentDate.month, keepMaster: false);

    final sum = personalYear + currentMonth;
    return _reduceToSingleDigit(sum, keepMaster: false);
  }

  /// Berechne Persönlichen Tag (Personal Day)
  /// Methode: Persönlicher Monat + aktueller Tag
  static int calculatePersonalDay(DateTime birthDate, DateTime currentDate) {
    final personalMonth = calculatePersonalMonth(birthDate, currentDate);
    final currentDay = _reduceToSingleDigit(currentDate.day, keepMaster: false);

    final sum = personalMonth + currentDay;
    return _reduceToSingleDigit(sum, keepMaster: false);
  }

  /// Berechne Lebenszyklen (3 große Phasen)
  /// Zyklus 1: Geburt bis ~28 Jahre
  /// Zyklus 2: ~28 bis ~56 Jahre
  /// Zyklus 3: ~56 Jahre bis Lebensende
  static List<Map<String, dynamic>> calculateLifeCycles(DateTime birthDate) {
    final month = _reduceToSingleDigit(birthDate.month, keepMaster: false);
    final day = _reduceToSingleDigit(birthDate.day, keepMaster: false);
    final year = _reduceToSingleDigit(birthDate.year, keepMaster: false);

    return [
      {
        'cycle': 1,
        'number': month,
        'startAge': 0,
        'endAge': 28,
        'theme': _getCycleTheme(month),
      },
      {
        'cycle': 2,
        'number': day,
        'startAge': 28,
        'endAge': 56,
        'theme': _getCycleTheme(day),
      },
      {
        'cycle': 3,
        'number': year,
        'startAge': 56,
        'endAge': 100,
        'theme': _getCycleTheme(year),
      },
    ];
  }

  /// Berechne Pinnacle-Zyklen (4 Höhepunkte)
  static List<Map<String, dynamic>> calculatePinnacleCycles(
      DateTime birthDate) {
    final lifePathNumber = calculateLifePath(birthDate);
    final month = _reduceToSingleDigit(birthDate.month, keepMaster: false);
    final day = _reduceToSingleDigit(birthDate.day, keepMaster: false);
    final year = _reduceToSingleDigit(birthDate.year, keepMaster: false);

    final firstDuration = 36 - lifePathNumber;

    final pinnacle1 = _reduceToSingleDigit(month + day, keepMaster: false);
    final pinnacle2 = _reduceToSingleDigit(day + year, keepMaster: false);
    final pinnacle3 =
        _reduceToSingleDigit(pinnacle1 + pinnacle2, keepMaster: false);
    final pinnacle4 = _reduceToSingleDigit(month + year, keepMaster: false);

    return [
      {
        'pinnacle': 1,
        'number': pinnacle1,
        'startAge': 0,
        'duration': firstDuration,
        'theme': _getPinnacleTheme(pinnacle1),
      },
      {
        'pinnacle': 2,
        'number': pinnacle2,
        'startAge': firstDuration,
        'duration': 9,
        'theme': _getPinnacleTheme(pinnacle2),
      },
      {
        'pinnacle': 3,
        'number': pinnacle3,
        'startAge': firstDuration + 9,
        'duration': 9,
        'theme': _getPinnacleTheme(pinnacle3),
      },
      {
        'pinnacle': 4,
        'number': pinnacle4,
        'startAge': firstDuration + 18,
        'duration': 100,
        'theme': _getPinnacleTheme(pinnacle4),
      },
    ];
  }

  /// Berechne Herausforderungszahlen (4 Challenges)
  static List<Map<String, dynamic>> calculateChallenges(DateTime birthDate) {
    final month = birthDate.month;
    final day = birthDate.day;
    final year = birthDate.year;

    final monthReduced = _reduceToSingleDigit(month, keepMaster: false);
    final dayReduced = _reduceToSingleDigit(day, keepMaster: false);
    final yearReduced = _reduceToSingleDigit(year, keepMaster: false);

    final challenge1 = (monthReduced - dayReduced).abs();
    final challenge2 = (dayReduced - yearReduced).abs();
    final challenge3 = (challenge1 - challenge2).abs();
    final challenge4 = (monthReduced - yearReduced).abs();

    return [
      {
        'challenge': 1,
        'number': challenge1,
        'theme': _getChallengeTheme(challenge1)
      },
      {
        'challenge': 2,
        'number': challenge2,
        'theme': _getChallengeTheme(challenge2)
      },
      {
        'challenge': 3,
        'number': challenge3,
        'theme': _getChallengeTheme(challenge3)
      },
      {
        'challenge': 4,
        'number': challenge4,
        'theme': _getChallengeTheme(challenge4)
      },
    ];
  }

  /// Prüfe auf Meisterzahlen im Namen oder Geburtsdatum
  static List<int> findMasterNumbers(
      String firstName, String lastName, DateTime birthDate) {
    final masterNumbers = <int>[];

    // Check in name
    final fullName = '$firstName $lastName'.toUpperCase();
    int sum = 0;
    for (int i = 0; i < fullName.length; i++) {
      final char = fullName[i];
      if (_pythagoreanValues.containsKey(char)) {
        sum += _pythagoreanValues[char]!;
        if (_masterNumbers.contains(sum)) {
          if (!masterNumbers.contains(sum)) masterNumbers.add(sum);
        }
      }
    }

    // Check in birthdate
    final dateSum = birthDate.day + birthDate.month + birthDate.year;
    if (_masterNumbers.contains(dateSum)) {
      if (!masterNumbers.contains(dateSum)) masterNumbers.add(dateSum);
    }

    return masterNumbers;
  }

  /// Prüfe auf Karma-Zahlen
  static List<int> findKarmaNumbers(
      String firstName, String lastName, DateTime birthDate) {
    final karmaNumbers = <int>[];

    final fullName = '$firstName $lastName'.toUpperCase();
    int sum = 0;
    for (int i = 0; i < fullName.length; i++) {
      final char = fullName[i];
      if (_pythagoreanValues.containsKey(char)) {
        sum += _pythagoreanValues[char]!;
        if (_karmaNumbers.contains(sum)) {
          if (!karmaNumbers.contains(sum)) karmaNumbers.add(sum);
        }
      }
    }

    return karmaNumbers;
  }

  /// Berechne Kernfrequenz (Durchschnitt der wichtigsten Zahlen)
  static double calculateCoreFrequency(
    int lifePath,
    int soul,
    int expression,
    int personality,
  ) {
    return (lifePath + soul + expression + personality) / 4.0;
  }

  // ════════════════════════════════════════════════════════════════════
  // 🏛️ CHALDÄISCHES SYSTEM (Verbesserung 1)
  // ════════════════════════════════════════════════════════════════════

  /// Chaldean Name Number (gesamter Name).
  static int calculateChaldeanName(String firstName, String lastName) {
    final fullName = '$firstName $lastName'.toUpperCase();
    int sum = 0;
    for (int i = 0; i < fullName.length; i++) {
      final v = _chaldeanValues[fullName[i]];
      if (v != null) sum += v;
    }
    return _reduceToSingleDigit(sum, keepMaster: true);
  }

  /// Chaldean Soul Number (nur Vokale).
  static int calculateChaldeanSoul(String firstName, String lastName) {
    final fullName = '$firstName $lastName'.toUpperCase();
    int sum = 0;
    for (int i = 0; i < fullName.length; i++) {
      final c = fullName[i];
      if (_vowels.contains(c)) {
        final v = _chaldeanValues[c];
        if (v != null) sum += v;
      }
    }
    return _reduceToSingleDigit(sum, keepMaster: true);
  }

  /// Chaldean Personality Number (nur Konsonanten).
  static int calculateChaldeanPersonality(String firstName, String lastName) {
    final fullName = '$firstName $lastName'.toUpperCase();
    int sum = 0;
    for (int i = 0; i < fullName.length; i++) {
      final c = fullName[i];
      if (!_vowels.contains(c)) {
        final v = _chaldeanValues[c];
        if (v != null) sum += v;
      }
    }
    return _reduceToSingleDigit(sum, keepMaster: true);
  }

  /// Wichtige Quellen-Notiz fuer UI.
  static const String chaldeanSystemInfo =
      'Das Chaldaeische System (ca. 4000 v.Chr., Babylonien) gilt als '
      'das aeltere System. Es basiert auf Klangschwingungen statt '
      'alphabetischer Reihenfolge. Die 9 wird als heilig betrachtet und '
      'keinem Buchstaben zugeordnet.';

  // ════════════════════════════════════════════════════════════════════
  // 👰 GEBURTSNAME VS. AKTUELLER NAME (Verbesserung 2)
  // ════════════════════════════════════════════════════════════════════

  /// Vergleicht Schwingung des Geburtsnamens mit aktuellem Namen.
  /// Liefert beide Sets + Shift + Deutung.
  static Map<String, dynamic> compareNameVibrations(
    String birthFirst,
    String? birthMiddle,
    String birthLast,
    String currentFirst,
    String currentLast,
  ) {
    // Geburtsname kombiniert Vor- + Zweit- + Nachname.
    final birthFullFirst = (birthMiddle?.trim().isNotEmpty ?? false)
        ? '$birthFirst $birthMiddle'
        : birthFirst;

    final birthExpression =
        calculateExpressionNumber(birthFullFirst, birthLast);
    final birthSoul = calculateSoulNumber(birthFullFirst, birthLast);
    final birthPersonality =
        calculatePersonalityNumber(birthFullFirst, birthLast);

    final currentExpression =
        calculateExpressionNumber(currentFirst, currentLast);
    final currentSoul = calculateSoulNumber(currentFirst, currentLast);
    final currentPersonality =
        calculatePersonalityNumber(currentFirst, currentLast);

    final shift = (birthExpression - currentExpression).abs();

    return {
      'birthExpression': birthExpression,
      'currentExpression': currentExpression,
      'birthSoul': birthSoul,
      'currentSoul': currentSoul,
      'birthPersonality': birthPersonality,
      'currentPersonality': currentPersonality,
      'vibrationShift': shift,
      'shiftInterpretation': _interpretShift(
          birthExpression, currentExpression, birthSoul, currentSoul),
    };
  }

  static String _interpretShift(
      int birthExp, int currentExp, int birthSoul, int currentSoul) {
    if (birthExp == currentExp && birthSoul == currentSoul) {
      return 'Deine Schwingung ist unveraendert geblieben - du lebst auch '
          'mit dem neuen Namen deine urspruengliche Mission.';
    }
    if (birthExp == currentExp) {
      return 'Die Hauptschwingung deines Namens ist erhalten - nur die '
          'innere Sehnsucht (Seele) hat sich verschoben.';
    }
    if (birthSoul == currentSoul) {
      return 'Deine Seele schwingt unveraendert, aber deine aeussere '
          'Ausdrucksform hat eine neue Resonanz angenommen.';
    }
    final delta = (birthExp - currentExp).abs();
    if (delta <= 1) {
      return 'Eine sanfte Verschiebung - dein neuer Name liegt nahe an der '
          'Geburtsschwingung. Du bist gewachsen, ohne dich zu verlieren.';
    }
    if (delta >= 5) {
      return 'Eine grosse Schwingungsverschiebung - der neue Name oeffnet '
          'voellig neue Energiebereiche. Tiefe Transformation.';
    }
    return 'Mittlere Verschiebung - der neue Name bringt frische Themen '
        'in dein Leben, ohne deine Wurzeln zu kappen.';
  }

  // ════════════════════════════════════════════════════════════════════
  // 🌉 BRÜCKENZAHLEN (Verbesserung 3)
  // ════════════════════════════════════════════════════════════════════

  /// Bridge Numbers: Differenzen zwischen Kernzahlen mit Ratschlaegen.
  /// Eine Bruecke = die Energie, die zwei Aspekte verbindet.
  static List<Map<String, dynamic>> calculateBridgeNumbers(
    int lifePath,
    int expression,
    int soul,
    int personality,
  ) {
    return [
      _buildBridge('Lebenszahl', lifePath, 'Ausdruckszahl', expression),
      _buildBridge('Seelenzahl', soul, 'Persoenlichkeitszahl', personality),
      _buildBridge('Lebenszahl', lifePath, 'Seelenzahl', soul),
      _buildBridge(
          'Ausdruckszahl', expression, 'Persoenlichkeitszahl', personality),
    ];
  }

  static Map<String, dynamic> _buildBridge(
      String labelA, int a, String labelB, int b) {
    final bridge = (a - b).abs();
    return {
      'labelA': labelA,
      'numberA': a,
      'labelB': labelB,
      'numberB': b,
      'bridge': bridge,
      'interpretation': _getBridgeInterpretation(bridge),
    };
  }

  static String _getBridgeInterpretation(int bridge) {
    switch (bridge) {
      case 0:
        return 'Perfekte Harmonie zwischen diesen Aspekten - sie verstaerken sich gegenseitig.';
      case 1:
        return 'Mehr Eigeninitiative und Selbstvertrauen verbindet diese Energien.';
      case 2:
        return 'Diplomatisches Feingefuehl und Kooperation schliessen die Bruecke.';
      case 3:
        return 'Kreativer Selbstausdruck und Kommunikation sind der Schluessel.';
      case 4:
        return 'Praktische Disziplin und Struktur bauen die Verbindung.';
      case 5:
        return 'Flexibilitaet und Offenheit fuer Veraenderung heilen die Luecke.';
      case 6:
        return 'Mehr Verantwortung und liebevolle Fuersorge harmonisieren.';
      case 7:
        return 'Meditation, Stille und innere Einkehr ueberbruecken die Differenz.';
      case 8:
        return 'Materielles Engagement und Fuehrungskraft verbinden die Kraefte.';
      default:
        return 'Aussergewoehnliche Spanne - braucht bewusste Integration.';
    }
  }

  // ════════════════════════════════════════════════════════════════════
  // 🗺️ INCLUSION CHART (Verbesserung 4)
  // ════════════════════════════════════════════════════════════════════

  /// Zaehlt wie oft jede Zahl 1-9 im Namen vorkommt (Pythagoraeisch).
  /// Fehlende Zahlen = Karmische Lektionen.
  /// Zahlen mit 3+ Vorkommen = Staerken/Dominanz.
  static Map<String, dynamic> calculateInclusionChart(
    String firstName,
    String lastName,
  ) {
    final fullName = '$firstName $lastName'.toUpperCase();
    final counts = <int, int>{
      for (var n = 1; n <= 9; n++) n: 0,
    };

    for (int i = 0; i < fullName.length; i++) {
      final v = _pythagoreanValues[fullName[i]];
      if (v != null) counts[v] = (counts[v] ?? 0) + 1;
    }

    final missing = <int>[];
    final dominant = <int>[];
    counts.forEach((n, c) {
      if (c == 0) missing.add(n);
      if (c >= 3) dominant.add(n);
    });

    final missingInterpretations = <int, String>{
      1: 'Karmische Lektion: Selbstvertrauen und Unabhaengigkeit entwickeln.',
      2: 'Karmische Lektion: Geduld, Kooperation und Feingefuehl lernen.',
      3: 'Karmische Lektion: Kreativen Selbstausdruck und Freude kultivieren.',
      4: 'Karmische Lektion: Disziplin, Ordnung und Durchhaltevermoegen aufbauen.',
      5: 'Karmische Lektion: Anpassungsfaehigkeit und Freiheit zulassen.',
      6: 'Karmische Lektion: Verantwortung und bedingungslose Liebe ueben.',
      7: 'Karmische Lektion: Vertrauen in Intuition und spirituelle Tiefe.',
      8: 'Karmische Lektion: Materiellen Erfolg und Macht annehmen.',
      9: 'Karmische Lektion: Mitgefuehl, Loslassen und Universalitaet.',
    };

    return {
      'numberCounts': counts,
      'missingNumbers': missing,
      'dominantNumbers': dominant,
      'missingInterpretations': {
        for (final n in missing) n: missingInterpretations[n]!,
      },
    };
  }

  // ════════════════════════════════════════════════════════════════════
  // 💞 ECHTE KOMPATIBILITÄTSMATRIX (Verbesserung 6)
  // ════════════════════════════════════════════════════════════════════

  /// Klassische numerologische Kompatibilitaets-Matrix (Score 0-100).
  static int calculateTrueCompatibility(int a, int b) {
    final key = a <= b ? '$a-$b' : '$b-$a';
    return _compatibilityMatrix[key] ?? 50;
  }

  /// Textuelle Beschreibung pro Paar.
  static String getCompatibilityDescription(int a, int b) {
    final key = a <= b ? '$a-$b' : '$b-$a';
    return _compatibilityDescriptions[key] ??
        'Eine einzigartige Konstellation - betrachte beide Energien als '
            'Ergaenzung statt als Gegensatz.';
  }

  static const Map<String, int> _compatibilityMatrix = {
    '1-1': 75,
    '1-2': 60,
    '1-3': 80,
    '1-4': 50,
    '1-5': 90,
    '1-6': 55,
    '1-7': 65,
    '1-8': 45,
    '1-9': 70,
    '2-2': 80,
    '2-3': 75,
    '2-4': 85,
    '2-5': 40,
    '2-6': 95,
    '2-7': 60,
    '2-8': 70,
    '2-9': 65,
    '3-3': 70,
    '3-4': 35,
    '3-5': 85,
    '3-6': 90,
    '3-7': 55,
    '3-8': 50,
    '3-9': 80,
    '4-4': 65,
    '4-5': 30,
    '4-6': 80,
    '4-7': 70,
    '4-8': 90,
    '4-9': 45,
    '5-5': 60,
    '5-6': 40,
    '5-7': 75,
    '5-8': 50,
    '5-9': 85,
    '6-6': 75,
    '6-7': 45,
    '6-8': 55,
    '6-9': 90,
    '7-7': 80,
    '7-8': 40,
    '7-9': 70,
    '8-8': 65,
    '8-9': 50,
    '9-9': 75,
  };

  static const Map<String, String> _compatibilityDescriptions = {
    '1-1':
        'Zwei Pioniere - feurig und ambitioniert. Beide wollen fuehren, das kann Reibung erzeugen, aber auch enorme Power.',
    '1-2':
        'Pionier trifft Diplomat. Die 1 fuehrt, die 2 unterstuetzt sanft. Funktioniert wenn beide ihre Rollen ehren.',
    '1-3':
        'Pionier + Kuenstler. Sehr inspirierend und kreativ. Beide lieben Aufmerksamkeit, koennen sich gegenseitig bestaerken.',
    '1-4':
        'Pionier + Baumeister. Tempo trifft Geduld. Herausfordernd, aber die 4 erdet die 1, wenn beide nachgeben.',
    '1-5':
        'Eine elektrische, aufregende Verbindung! Beide lieben Freiheit und Abenteuer. Pionier (1) und Freigeist (5) inspirieren sich gegenseitig.',
    '1-6':
        'Pionier + Naehrender. Die 6 fordert Familienzeit, die 1 will durchstarten - Kompromisse noetig.',
    '1-7':
        'Pionier + Mystiker. Komplementaer: 7 bringt Tiefe, 1 bringt Aktion. Brauchen Verstaendnis fuer beide Welten.',
    '1-8':
        'Zwei Alphas auf demselben Feld. Machtkampf vorprogrammiert, sofern keine klare Rollenverteilung.',
    '1-9':
        'Pionier + Humanist. 9 zaehmt 1, 1 mobilisiert 9. Sehr fruchtbar wenn beide ihre Egos zuegeln.',
    '2-2':
        'Doppelte Harmonie - sanft, liebevoll, einfuehlsam. Risiko: Entscheidungsschwaeche.',
    '2-3':
        'Harmonisch und kreativ. 3 bringt Leichtigkeit, 2 bringt Tiefe. Schoene Balance.',
    '2-4':
        'Sehr stabile Verbindung. 2 sorgt fuer Frieden, 4 fuer Struktur. Klassisches Erfolgsteam.',
    '2-5':
        'Schwierig: 2 will Sicherheit, 5 will Freiheit. Nur bei viel Reife tragfaehig.',
    '2-6':
        'Top-Match. Beide werte-orientiert, fuersorglich und partnerschaftlich. Sehr nahrhaft.',
    '2-7':
        'Subtil und tief. 7 braucht Rueckzug, 2 sehnt sich nach Naehe - kann ungleich wirken.',
    '2-8':
        'Klassisches Klassikerpaar: 8 fuehrt, 2 unterstuetzt. Funktioniert wenn 8 die 2 wertschaetzt.',
    '2-9':
        'Beide humanitaer veranlagt, gemeinsame Mission moeglich. Sehr warm.',
    '3-3':
        'Doppelte Kreativitaet - viel Spass, aber auch viel Drama. Beide brauchen Buehne.',
    '3-4':
        'Herausfordernd: 3 liebt Spontanitaet, 4 will Planung. Kann sich aber wunderbar ergaenzen.',
    '3-5':
        'Lebhaft, freiheitsliebend, abenteuerlustig. Sehr inspirierend, kann fluechtig sein.',
    '3-6':
        'Warmes Kuenstler-Paar. 6 erdet die 3, 3 bringt Lebendigkeit in das 6er-Heim.',
    '3-7':
        'Kuenstler + Mystiker. Tief und kreativ - aber 7 braucht mehr Ruhe als 3 verstehen kann.',
    '3-8':
        'Aussen vs. Innen: 8 will Erfolg, 3 will Ausdruck. Kann sich ergaenzen, oft kontaer.',
    '3-9':
        'Beide kreativ und expressiv, mit Tiefe. Sehr inspirierend und farbig.',
    '4-4': 'Stabil, vorhersehbar, sicher. Risiko: zu wenig Funken, Routine.',
    '4-5':
        'Herausforderndste Kombi: Stabilitaet trifft Freiheit. Grosses Wachstumspotenzial bei Kompromissbereitschaft.',
    '4-6':
        'Solide Familien-Verbindung. Beide bauen, beide tragen Verantwortung.',
    '4-7':
        'Strukturiert + introspektiv. Funktioniert leise, beide schaetzen Tiefe.',
    '4-8':
        'Power-Duo: Disziplin + Erfolg. Sehr kraftvolle Verbindung, sehr ergebnisorientiert.',
    '4-9':
        'Pragmatiker + Idealist. 9 sieht das grosse Ganze, 4 die Details - braucht Geduld.',
    '5-5':
        'Doppelte Freiheit, dauerhafte Abwechslung. Schwer fuer Bindung, leicht fuer Erlebnisse.',
    '5-6':
        'Freigeist + Familienseele. Zugkraefte in entgegengesetzte Richtungen.',
    '5-7': 'Beide unabhaengig und tief, geben sich Raum - sehr respektvoll.',
    '5-8':
        'Ehrgeiz + Freiheit. 8 will Stabilitaet im Erfolg, 5 will offene Tueren.',
    '5-9':
        'Universell und abenteuerlustig - beide wollen die Welt sehen und veraendern.',
    '6-6': 'Warmes, fuersorgliches Paar. Familienzentriert, harmonisch.',
    '6-7':
        'Naehrer + Denker. 7 zieht sich zurueck, 6 will Naehe - sanfte Reibung.',
    '6-8': 'Solide, fokussiert - 6 schafft das Zuhause, 8 schafft den Erfolg.',
    '6-9':
        'Bedingungslose Liebe meets universelle Liebe - sehr selten und kostbar.',
    '7-7': 'Tiefe, philosophische Verbindung. Beide brauchen viel Allein-Zeit.',
    '7-8':
        'Innenwelt + Aussenwelt - selten an einem Strang, aber komplementaer wenn ja.',
    '7-9': 'Mystiker + Humanist. Tief, weise, oft spirituell ausgerichtet.',
    '8-8':
        'Doppelte Power - oft Geschaeftspartner und Liebhaber zugleich. Klare Spielregeln noetig.',
    '8-9':
        'Ehrgeiz + Mitgefuehl. 9 erdet das Materielle der 8 im Sinn fuer das Hoehere.',
    '9-9':
        'Doppelter Idealismus - kann sich gegenseitig hochziehen oder gemeinsam erschoepfen.',
  };

  /// Gewichteter Gesamt-Score fuer Synastrie:
  /// Lebenszahl 40%, Seelenzahl 35%, Ausdruckszahl 25%.
  static int calculateWeightedCompatibility({
    required int lifePathA,
    required int lifePathB,
    required int soulA,
    required int soulB,
    required int expressionA,
    required int expressionB,
  }) {
    final lp = calculateTrueCompatibility(lifePathA, lifePathB);
    final so = calculateTrueCompatibility(soulA, soulB);
    final ex = calculateTrueCompatibility(expressionA, expressionB);
    return (lp * 0.40 + so * 0.35 + ex * 0.25).round();
  }

  // ════════════════════════════════════════════════════════════════════
  // 🏠 ADRESS- / TELEFON- / KENNZEICHEN-NUMEROLOGIE (Verbesserung 9)
  // ════════════════════════════════════════════════════════════════════

  /// Extrahiert nur Ziffern aus Adresse und reduziert.
  static int calculateAddressNumber(String address) {
    int sum = 0;
    for (final ch in address.split('')) {
      final n = int.tryParse(ch);
      if (n != null) sum += n;
    }
    if (sum == 0) return 0;
    return _reduceToSingleDigit(sum, keepMaster: false);
  }

  /// Alle Ziffern der Telefonnummer summiert und reduziert.
  static int calculatePhoneNumber(String phone) {
    int sum = 0;
    for (final ch in phone.split('')) {
      final n = int.tryParse(ch);
      if (n != null) sum += n;
    }
    if (sum == 0) return 0;
    return _reduceToSingleDigit(sum, keepMaster: false);
  }

  /// Kennzeichen: Buchstaben (Pythagoraeisch) + Ziffern.
  static int calculateLicensePlate(String plate) {
    final upper = plate.toUpperCase();
    int sum = 0;
    for (int i = 0; i < upper.length; i++) {
      final ch = upper[i];
      final asDigit = int.tryParse(ch);
      if (asDigit != null) {
        sum += asDigit;
      } else {
        final letter = _pythagoreanValues[ch];
        if (letter != null) sum += letter;
      }
    }
    if (sum == 0) return 0;
    return _reduceToSingleDigit(sum, keepMaster: false);
  }

  static String getAddressNumberMeaning(int number) {
    switch (number) {
      case 1:
        return 'Haus der Unabhaengigkeit - foerdert Eigenstaendigkeit und neue Anfaenge.';
      case 2:
        return 'Haus der Partnerschaft - ideal fuer Paare und harmonisches Zusammenleben.';
      case 3:
        return 'Haus der Kreativitaet - inspiriert kuenstlerischen Ausdruck und Geselligkeit.';
      case 4:
        return 'Haus der Stabilitaet - foerdert harte Arbeit, Ordnung und Sicherheit.';
      case 5:
        return 'Haus der Veraenderung - dynamisch, aufregend, ideal fuer Freigeister.';
      case 6:
        return 'Haus der Familie - warm, naehrend, perfekt fuer Familien.';
      case 7:
        return 'Haus der Stille - ideal fuer Denker, Meditierende und Suchende.';
      case 8:
        return 'Haus des Wohlstands - foerdert finanziellen Erfolg und Ambitionen.';
      case 9:
        return 'Haus der Vollendung - humanitaer, weltoffen, spirituell.';
      default:
        return 'Keine Ziffern erkannt - bitte Adresse pruefen.';
    }
  }

  // ════════════════════════════════════════════════════════════════════
  // 📅 TAGES-ENERGIE-TEXTE (Verbesserung 5 -- App-seitig fuer Fallback)
  // ════════════════════════════════════════════════════════════════════

  /// 3 Varianten pro Tagesenergie 1..9. Selektion deterministisch pro Datum.
  static String getDailyEnergyText(int personalDay, {DateTime? seed}) {
    final variants = _dailyEnergyTexts[personalDay] ??
        const [
          'Heute traegt deine einzigartige Schwingung. Hoere auf dein Inneres.',
        ];
    if (variants.isEmpty) return '';
    final date = seed ?? DateTime.now();
    final idx = (date.day + date.month) % variants.length;
    return variants[idx];
  }

  static const Map<int, List<String>> _dailyEnergyTexts = {
    1: [
      'Heute strahlt Pionierenergie! Starte etwas Neues.',
      'Tag der Initiative - geh voran!',
      'Die 1 ruft: Sei mutig und eigenstaendig!',
    ],
    2: [
      'Harmonie-Tag: Pflege deine Beziehungen.',
      'Diplomatie und Feingefuehl sind heute deine Staerken.',
      'Die 2 fluestert: Hoere zu und vermittle.',
    ],
    3: [
      'Kreativitaets-Explosion! Druecke dich aus.',
      'Freude und Ausdruck stehen heute im Fokus.',
      'Die 3 singt: Erschaffe etwas Schoenes!',
    ],
    4: [
      'Strukturtag: Ordne und organisiere.',
      'Heute lohnt sich fleissige Arbeit doppelt.',
      'Die 4 spricht: Baue solide Fundamente.',
    ],
    5: [
      'Abenteuer-Tag! Sei offen fuer Neues.',
      'Veraenderung liegt in der Luft - umarme sie!',
      'Die 5 ruft: Brich aus der Routine aus!',
    ],
    6: [
      'Familien- und Liebestag.',
      'Fuersorge und Verantwortung tragen heute Fruechte.',
      'Die 6 waermt: Gib und empfange Liebe.',
    ],
    7: [
      'Tag der inneren Einkehr und Analyse.',
      'Meditation und Stille bringen heute Klarheit.',
      'Die 7 schweigt: Hoere nach innen.',
    ],
    8: [
      'Manifestations-Tag! Denke gross.',
      'Materieller Fokus bringt heute Ergebnisse.',
      'Die 8 manifestiert: Dein Erfolg wartet.',
    ],
    9: [
      'Tag des Loslassens und der Vollendung.',
      'Mitgefuehl und Dienst am Naechsten erfuellen heute.',
      'Die 9 vollendet: Lass los, was nicht mehr dient.',
    ],
  };

  /// Hilfsfunktion: Reduziere auf einzelne Ziffer
  static int _reduceToSingleDigit(int number, {bool keepMaster = false}) {
    // Meisterzahlen beibehalten wenn gewünscht
    if (keepMaster && _masterNumbers.contains(number)) {
      return number;
    }

    while (number > 9) {
      int sum = 0;
      while (number > 0) {
        sum += number % 10;
        number ~/= 10;
      }
      number = sum;

      // Check wieder auf Meisterzahl
      if (keepMaster && _masterNumbers.contains(number)) {
        return number;
      }
    }

    return number;
  }

  /// Themen-Beschreibungen für Zyklen
  static String _getCycleTheme(int number) {
    switch (number) {
      case 1:
        return 'Unabhängigkeit, Führung, Neuanfang';
      case 2:
        return 'Partnerschaft, Diplomatie, Balance';
      case 3:
        return 'Kreativität, Ausdruck, Freude';
      case 4:
        return 'Stabilität, Ordnung, Arbeit';
      case 5:
        return 'Freiheit, Veränderung, Abenteuer';
      case 6:
        return 'Verantwortung, Familie, Dienst';
      case 7:
        return 'Spiritualität, Analyse, Weisheit';
      case 8:
        return 'Macht, Erfolg, Manifestation';
      case 9:
        return 'Vollendung, Humanität, Loslassen';
      default:
        return 'Unbekannt';
    }
  }

  /// Themen-Beschreibungen für Pinnacles
  static String _getPinnacleTheme(int number) {
    return _getCycleTheme(number); // Verwende gleiche Themen
  }

  /// Themen-Beschreibungen für Herausforderungen
  static String _getChallengeTheme(int number) {
    switch (number) {
      case 0:
        return 'Alle Lektionen gemeistert';
      case 1:
        return 'Lernen, selbstständig zu sein';
      case 2:
        return 'Lernen, mit anderen zusammenzuarbeiten';
      case 3:
        return 'Lernen, sich auszudrücken';
      case 4:
        return 'Lernen, diszipliniert zu sein';
      case 5:
        return 'Lernen, Veränderung anzunehmen';
      case 6:
        return 'Lernen, Verantwortung zu übernehmen';
      case 7:
        return 'Lernen, Vertrauen zu entwickeln';
      case 8:
        return 'Lernen, Macht weise einzusetzen';
      default:
        return 'Spezielle Herausforderung';
    }
  }

  /// 🆕 Generiere AUSFÜHRLICHE Numerologie-Analyse
  static String generateDetailedNumerologyAnalysis(
    int lifePathNumber,
    int expressionNumber,
    int soulNumber,
    int personalityNumber,
    int personalYear,
  ) {
    return '''
🔢 AUSFÜHRLICHE NUMEROLOGIE-ANALYSE

═══════════════════════════════════════════════════════

📍 DEINE LEBENSZAHL: $lifePathNumber
${_getLifePathMeaning(lifePathNumber)}

Die Lebenszahl ist der wichtigste numerologische Wert. Sie repräsentiert deinen Lebensweg, deine Mission und die Lektionen, die du in diesem Leben meistern sollst. Diese Zahl begleitet dich von der Geburt bis zum Tod und zeigt die fundamentale Richtung deiner Seele.

🎯 DEINE LEBENSAUFGABE:
${_getLifePathPurpose(lifePathNumber)}

Deine Lebenszahl zeigt nicht nur, wer du bist, sondern auch, wer du werden sollst. Sie ist wie ein Kompass, der dich zu deiner höchsten Erfüllung führt. Je mehr du in Harmonie mit deiner Lebenszahl lebst, desto mehr Fluss und Synchronizität erlebst du.

═══════════════════════════════════════════════════════

💫 DEINE SCHICKSALSZAHL (Expression): $expressionNumber

Die Schicksalszahl zeigt deine natürlichen Talente, Fähigkeiten und wie du dich in der Welt ausdrückst. Sie wird aus deinem vollständigen Geburtsnamen berechnet und repräsentiert das Potenzial, das dir mitgegeben wurde.

🌟 DEINE TALENTE & GABEN:
${_getExpressionTalents(expressionNumber)}

Diese Fähigkeiten sind nicht zufällig - sie sind Werkzeuge, die deine Seele gewählt hat, um ihre Mission zu erfüllen. Kultiviere diese Talente bewusst, denn sie sind der Schlüssel zu deinem Erfolg und deiner Erfüllung.

═══════════════════════════════════════════════════════

❤️ DEINE SEELENZAHL (Soul Urge): $soulNumber

Die Seelenzahl offenbart deine innersten Wünsche, Motivationen und was dein Herz wirklich begehrt. Sie zeigt, was dich auf tiefster Ebene antreibt und erfüllt.

💎 DEINE HERZENS-WÜNSCHE:
${_getSoulDesires(soulNumber)}

Diese Sehnsüchte sind authentische Impulse deiner Seele. Sie zu ignorieren führt zu Unzufriedenheit, sie zu ehren führt zu tiefer Erfüllung. Deine Seelenzahl erinnert dich daran, was wirklich wichtig ist.

═══════════════════════════════════════════════════════

🎭 DEINE PERSÖNLICHKEITSZAHL: $personalityNumber

Die Persönlichkeitszahl zeigt, wie andere dich wahrnehmen und welchen ersten Eindruck du hinterlässt. Sie ist wie die Maske, die du der Welt präsentierst - nicht falsch, aber auch nicht vollständig.

👤 WIE ANDERE DICH SEHEN:
${_getPersonalityImpression(personalityNumber)}

Der Unterschied zwischen deiner Persönlichkeitszahl und Seelenzahl zeigt, wie sehr dein äußeres Bild mit deinem inneren Wesen übereinstimmt. Je größer die Harmonie, desto authentischer lebst du.

═══════════════════════════════════════════════════════

⚡ DEIN PERSÖNLICHES JAHR: $personalYear

Das persönliche Jahr zeigt die aktuelle Energie und die Themen, die in diesem Jahr besonders präsent sind. Jedes Jahr bringt neue Lektionen und Möglichkeiten.

🌈 THEMEN DIESES JAHRES:
${_getPersonalYearThemes(personalYear)}

Nutze die Energie deines persönlichen Jahres bewusst. Schwimme mit dem Strom statt dagegen. Die Numerologie zeigt dir, wann du säen, wann du ernten und wann du ruhen solltest.

═══════════════════════════════════════════════════════

🎯 ZAHLEN-HARMONIE & SYNERGIE:

${_getNumberHarmony(lifePathNumber, expressionNumber, soulNumber)}

═══════════════════════════════════════════════════════

💫 PRAKTISCHE NUMEROLOGIE-ANWENDUNG:

📅 TÄGLICHE PRAXIS:
• Morgens: Meditiere über deine Lebenszahl
• Wichtige Entscheidungen: Konsultiere dein persönliches Jahr
• Beziehungen: Vergleiche Lebenszahlen für Kompatibilität
• Karriere: Nutze deine Schicksalszahl als Wegweiser

🔮 VERTIEFENDE ÜBUNGEN:
• Beobachte, welche Zahlen dir wiederholt begegnen
• Führe ein Numerologie-Tagebuch
• Berechne die Zahlen wichtiger Daten in deinem Leben
• Studiere die Zahlen deiner Familienmitglieder

═══════════════════════════════════════════════════════

🌟 AFFIRMATIONEN FÜR LEBENSZAHL $lifePathNumber:
${_getNumerologyAffirmations(lifePathNumber)}

═══════════════════════════════════════════════════════
''';
  }

  static String _getLifePathMeaning(int number) {
    final meanings = {
      1: 'Du bist ein geborener Pionier und Anführer. Dein Weg ist es, Unabhängigkeit zu entwickeln, neue Wege zu beschreiten und andere durch dein Beispiel zu inspirieren.',
      2: 'Deine Seele sucht nach Harmonie und Partnerschaft. Du bist der Diplomat, der Vermittler, der Brückenbauer zwischen Gegensätzen.',
      3: 'Kreativität ist deine Essenz. Du bist hier, um Freude zu verbreiten, dich auszudrücken und andere durch deine Kunst zu inspirieren.',
      4: 'Stabilität und Ordnung sind deine Gaben. Du bist der Baumeister, der feste Fundamente für eine bessere Zukunft schafft.',
      5: 'Freiheit ist dein höchstes Gut. Deine Seele sehnt sich nach Abenteuer, Veränderung und der Erfahrung aller Facetten des Lebens.',
      6: 'Du bist der Nährende, der Heiler, der Beschützer. Verantwortung für andere zu übernehmen ist nicht Last, sondern Berufung.',
      7: 'Spirituelle Wahrheit ist dein Ziel. Du bist der Mystiker, der Philosoph, der Sucher nach tieferer Bedeutung.',
      8: 'Manifestation und materieller Erfolg sind deine Domäne. Du verstehst die Gesetze von Ursache und Wirkung auf materielle Ebene.',
      9: 'Vollendung und Humanität definieren deinen Weg. Du bist hier, um zu heilen, zu dienen und die Welt zu einem besseren Ort zu machen.',
      11: 'Als Meisterzahl trägst du eine besondere spirituelle Mission. Du bist der Erleuchtete, der Inspirator, der Visionär.',
      22: 'Die Meisterzahl 22 macht dich zum Master Builder. Du kannst Träume in greifbare Realität verwandeln.',
      33: 'Die höchste Meisterzahl - du bist der Master Teacher. Bedingungslose Liebe und universelles Dienen sind deine Berufung.',
    };
    return meanings[number] ?? 'Eine einzigartige Lebensreise wartet auf dich.';
  }

  static String _getLifePathPurpose(int number) {
    return 'Lerne ${_getCycleTheme(number % 10)} zu meistern und verkörpere diese Qualitäten in jedem Aspekt deines Lebens. Deine größte Erfüllung findest du, wenn du diese Energie großzügig mit der Welt teilst.';
  }

  static String _getExpressionTalents(int number) {
    return 'Deine natürlichen Fähigkeiten liegen in ${_getCycleTheme(number % 10)}. Diese Talente sind nicht nur Geschenke, sondern auch Verantwortung. Je mehr du sie entwickelst und einsetzt, desto mehr erfüllst du deine Lebensaufgabe.';
  }

  static String _getSoulDesires(int number) {
    return 'Im Kern deines Wesens sehnst du dich nach ${_getCycleTheme(number % 10)}. Dies ist keine Schwäche, sondern die Stimme deiner Seele. Höre auf sie.';
  }

  static String _getPersonalityImpression(int number) {
    return 'Menschen nehmen dich als jemanden wahr, der ${_getCycleTheme(number % 10)} verkörpert. Dies ist deine natürliche Ausstrahlung, die Art, wie deine Energie in die Welt fließt.';
  }

  static String _getPersonalYearThemes(int number) {
    return 'Dieses Jahr dreht sich um ${_getCycleTheme(number % 10)}. Jedes persönliche Jahr ist ein Kapitel in einem 9-jährigen Zyklus. Verstehe die Lektion dieses Jahres, um optimal zu wachsen.';
  }

  static String _getNumberHarmony(int lifePath, int expression, int soul) {
    if (lifePath == expression && expression == soul) {
      return 'Alle deine Hauptzahlen sind identisch - dies zeigt außergewöhnliche Fokussierung und Klarheit in deiner Lebensrichtung. Du bist vollkommen auf deine Mission ausgerichtet.';
    } else if ((lifePath - expression).abs() <= 1) {
      return 'Deine Lebenszahl und Schicksalszahl harmonieren wunderbar. Was du tun sollst und was du kannst, sind in perfekter Übereinstimmung.';
    } else {
      return 'Deine verschiedenen Zahlen zeigen die Vielschichtigkeit deiner Persönlichkeit. Integration aller Aspekte führt zu Ganzheit.';
    }
  }

  static String _getNumerologyAffirmations(int number) {
    final affirmations = {
      1: '• "Ich bin der Schöpfer meiner Realität"\n• "Ich führe mit Mut und Integrität"\n• "Meine Unabhängigkeit ist meine Stärke"\n• "Ich wage Neues mit Vertrauen"\n• "Ich bin ein Pionier meines Lebens"',
      2: '• "Ich schaffe Harmonie wo ich gehe"\n• "Meine Sensibilität ist eine Gabe"\n• "Ich bin Brückenbauer und Friedensstifter"\n• "Balance ist meine natürliche Natur"\n• "Partnerschaft bereichert mein Leben"',
      3: '• "Meine Kreativität fließt mühelos"\n• "Freude ist mein Geburtsrecht"\n• "Ich drücke mich authentisch aus"\n• "Meine Kunst inspiriert andere"\n• "Leben ist ein kreatives Spiel"',
      4: '• "Ich schaffe stabile Fundamente"\n• "Disziplin führt mich zum Erfolg"\n• "Ich bin zuverlässig und vertrauenswürdig"\n• "Ordnung bringt Frieden in mein Leben"\n• "Ich baue nachhaltige Strukturen"',
      5: '• "Ich umarme Veränderung mit Freude"\n• "Freiheit ist meine Essenz"\n• "Jedes Abenteuer bringt Wachstum"\n• "Ich lebe im Moment"\n• "Flexibilität ist meine Superkraft"',
      6: '• "Ich gebe und empfange Liebe großzügig"\n• "Verantwortung erfüllt mich"\n• "Ich schaffe harmonische Beziehungen"\n• "Dienst an anderen ist Dienst an mir"\n• "Familie und Gemeinschaft nähren mich"',
      7: '• "Ich vertraue meiner inneren Weisheit"\n• "Stille offenbart tiefe Wahrheiten"\n• "Ich bin spirituell erwacht"\n• "Analyse führt zu Klarheit"\n• "Ich bin mit göttlicher Quelle verbunden"',
      8: '• "Ich manifestiere Fülle mühelos"\n• "Erfolg ist mein natürlicher Zustand"\n• "Ich nutze Macht weise und mitfühlend"\n• "Materieller und spiritueller Wohlstand vereinen sich"\n• "Ich bin Meister meiner Realität"',
      9: '• "Ich diene dem höchsten Wohl aller"\n• "Loslassen bringt Erneuerung"\n• "Mein Mitgefühl heilt die Welt"\n• "Vollendung ist Neuanfang"\n• "Ich bin ein Licht für andere"',
    };
    return affirmations[number % 10] ??
        '• "Ich ehre meine einzigartige Zahlen-Signatur"';
  }
}
