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
    'A': 1, 'J': 1, 'S': 1,
    'B': 2, 'K': 2, 'T': 2,
    'C': 3, 'L': 3, 'U': 3,
    'D': 4, 'M': 4, 'V': 4,
    'E': 5, 'N': 5, 'W': 5,
    'F': 6, 'O': 6, 'X': 6,
    'G': 7, 'P': 7, 'Y': 7,
    'H': 8, 'Q': 8, 'Z': 8,
    'I': 9, 'R': 9,
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
    final currentYear = _reduceToSingleDigit(currentDate.year, keepMaster: false);
    
    final sum = birthDay + birthMonth + currentYear;
    return _reduceToSingleDigit(sum, keepMaster: false);
  }

  /// Berechne Persönlichen Monat (Personal Month)
  /// Methode: Persönliches Jahr + aktueller Monat
  static int calculatePersonalMonth(DateTime birthDate, DateTime currentDate) {
    final personalYear = calculatePersonalYear(birthDate, currentDate);
    final currentMonth = _reduceToSingleDigit(currentDate.month, keepMaster: false);
    
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
  static List<Map<String, dynamic>> calculatePinnacleCycles(DateTime birthDate) {
    final lifePathNumber = calculateLifePath(birthDate);
    final month = _reduceToSingleDigit(birthDate.month, keepMaster: false);
    final day = _reduceToSingleDigit(birthDate.day, keepMaster: false);
    final year = _reduceToSingleDigit(birthDate.year, keepMaster: false);

    final firstDuration = 36 - lifePathNumber;
    
    final pinnacle1 = _reduceToSingleDigit(month + day, keepMaster: false);
    final pinnacle2 = _reduceToSingleDigit(day + year, keepMaster: false);
    final pinnacle3 = _reduceToSingleDigit(pinnacle1 + pinnacle2, keepMaster: false);
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
      {'challenge': 1, 'number': challenge1, 'theme': _getChallengeTheme(challenge1)},
      {'challenge': 2, 'number': challenge2, 'theme': _getChallengeTheme(challenge2)},
      {'challenge': 3, 'number': challenge3, 'theme': _getChallengeTheme(challenge3)},
      {'challenge': 4, 'number': challenge4, 'theme': _getChallengeTheme(challenge4)},
    ];
  }

  /// Prüfe auf Meisterzahlen im Namen oder Geburtsdatum
  static List<int> findMasterNumbers(String firstName, String lastName, DateTime birthDate) {
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
  static List<int> findKarmaNumbers(String firstName, String lastName, DateTime birthDate) {
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
      case 1: return 'Unabhängigkeit, Führung, Neuanfang';
      case 2: return 'Partnerschaft, Diplomatie, Balance';
      case 3: return 'Kreativität, Ausdruck, Freude';
      case 4: return 'Stabilität, Ordnung, Arbeit';
      case 5: return 'Freiheit, Veränderung, Abenteuer';
      case 6: return 'Verantwortung, Familie, Dienst';
      case 7: return 'Spiritualität, Analyse, Weisheit';
      case 8: return 'Macht, Erfolg, Manifestation';
      case 9: return 'Vollendung, Humanität, Loslassen';
      default: return 'Unbekannt';
    }
  }

  /// Themen-Beschreibungen für Pinnacles
  static String _getPinnacleTheme(int number) {
    return _getCycleTheme(number); // Verwende gleiche Themen
  }

  /// Themen-Beschreibungen für Herausforderungen
  static String _getChallengeTheme(int number) {
    switch (number) {
      case 0: return 'Alle Lektionen gemeistert';
      case 1: return 'Lernen, selbstständig zu sein';
      case 2: return 'Lernen, mit anderen zusammenzuarbeiten';
      case 3: return 'Lernen, sich auszudrücken';
      case 4: return 'Lernen, diszipliniert zu sein';
      case 5: return 'Lernen, Veränderung anzunehmen';
      case 6: return 'Lernen, Verantwortung zu übernehmen';
      case 7: return 'Lernen, Vertrauen zu entwickeln';
      case 8: return 'Lernen, Macht weise einzusetzen';
      default: return 'Spezielle Herausforderung';
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
    return affirmations[number % 10] ?? '• "Ich ehre meine einzigartige Zahlen-Signatur"';
  }
}
