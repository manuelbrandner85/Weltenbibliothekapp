/// v5.40 - Hidden Facts Data (2.1)
/// Conspiracy and historical facts for Easter Egg menu
class HiddenFacts {
  static final List<Map<String, String>> facts = [
    {
      'title': '🏛️ Operation Ajax (1953)',
      'fact':
          'Die CIA orchestrierte einen Staatsstreich im Iran, um Premier Mosaddegh zu stürzen und den Schah an die Macht zu bringen. Dies legte den Grundstein für die iranische Revolution von 1979.',
      'category': 'Geopolitik',
    },
    {
      'title': '🧠 MK-Ultra (1953-1973)',
      'fact':
          'Die CIA führte über 150 geheime Experimente zur Bewusstseinskontrolle durch, darunter LSD-Tests an unwissenden US-Bürgern. Viele Akten wurden 1973 vernichtet.',
      'category': 'Wissenschaft',
    },
    {
      'title': '📡 Operation Mockingbird',
      'fact':
          'Die CIA infiltrierte in den 1950er Jahren große US-Medien, um die öffentliche Meinung zu beeinflussen. Hunderte Journalisten arbeiteten für den Geheimdienst.',
      'category': 'Medien',
    },
    {
      'title': '🚀 Operation Paperclip (1945)',
      'fact':
          'Nach dem 2. Weltkrieg rekrutierte die USA über 1.600 deutsche Wissenschaftler (inkl. Ex-Nazis) für ihr Raketenprogramm. Wernher von Braun wurde NASA-Direktor.',
      'category': 'Geschichte',
    },
    {
      'title': '💰 Panama Papers (2016)',
      'fact':
          '11,5 Millionen Dokumente enthüllten, wie Eliten und Politiker Offshore-Firmen für Steuerhinterziehung nutzten. 140 Politiker aus 50 Ländern waren betroffen.',
      'category': 'Finanzen',
    },
    {
      'title': '🔬 Tuskegee-Experiment (1932-1972)',
      'fact':
          'Die US-Regierung ließ 40 Jahre lang 399 afroamerikanische Männer mit Syphilis unbehandelt, um den Krankheitsverlauf zu studieren – trotz verfügbarer Heilmittel.',
      'category': 'Medizin',
    },
    {
      'title': '🌍 COINTELPRO (1956-1971)',
      'fact':
          'Das FBI führte illegale Operationen gegen Bürgerrechtsbewegungen durch, darunter Überwachung, Infiltration und Sabotage von Martin Luther King Jr.',
      'category': 'Politik',
    },
    {
      'title': '🛢️ Iran-Contra-Affäre (1985-1987)',
      'fact':
          'Die Reagan-Administration verkaufte heimlich Waffen an den Iran und finanzierte damit illegale Contras in Nicaragua – trotz US-Kongressverbot.',
      'category': 'Geopolitik',
    },
    {
      'title': '📞 NSA-Überwachung (seit 2001)',
      'fact':
          'Edward Snowden enthüllte 2013, dass die NSA Milliarden Telefonate und Internetaktivitäten weltweit überwacht – auch von US-Bürgern ohne Durchsuchungsbefehl.',
      'category': 'Technologie',
    },
    {
      'title': '🎭 Operation Northwoods (1962)',
      'fact':
          'Das US-Militär plante gefälschte Terroranschläge gegen eigene Bürger, um einen Krieg gegen Kuba zu rechtfertigen. Präsident Kennedy lehnte den Plan ab.',
      'category': 'Militär',
    },
    {
      'title': '🔐 PRISM-Programm (2007)',
      'fact':
          'Die NSA sammelte direkt von Tech-Giganten (Google, Facebook, Apple) Nutzerdaten. 9 große Tech-Firmen waren beteiligt.',
      'category': 'Technologie',
    },
    {
      'title': '💣 Tonkin-Zwischenfall (1964)',
      'fact':
          'Der angebliche Angriff nordvietnamesischer Boote auf US-Schiffe war teilweise erfunden, diente aber als Vorwand für den Vietnamkrieg.',
      'category': 'Militär',
    },
  ];

  /// Get a random fact
  static Map<String, String> getRandomFact() {
    facts.shuffle();
    return facts.first;
  }

  /// Get all facts
  static List<Map<String, String>> getAllFacts() {
    return facts;
  }
}
