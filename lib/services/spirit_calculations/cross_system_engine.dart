// Cross-System-Engine: verbindet Numerologie mit Kabbala, Hebraeisch,
// Tarot, Planeten und Solfeggio-Frequenzen.
// Jeder Mapper liefert eine Map<String, dynamic> mit name, symbol,
// description und ggf. Verknuepfung zu anderen Screens.

library;

class CrossSystemEngine {
  // ── Kabbala-Sephiroth ────────────────────────────────────────────────
  static Map<String, dynamic> getKabbalisticCorrespondence(int lifePathNumber) {
    final map = <int, Map<String, dynamic>>{
      1: {
        'sephira': 'Kether',
        'sephiraName': 'Krone',
        'symbol': 'כתר',
        'description':
            'Deine Lebenszahl 1 resoniert mit Kether, der goettlichen Quelle. Du traegst Schoepferenergie.',
      },
      2: {
        'sephira': 'Chokmah',
        'sephiraName': 'Weisheit',
        'symbol': 'חכמה',
        'description':
            'Die 2 verbindet dich mit Chokmah, der dynamischen Weisheit und dem ersten Impuls.',
      },
      3: {
        'sephira': 'Binah',
        'sephiraName': 'Verstaendnis',
        'symbol': 'בינה',
        'description':
            'Die 3 fuehrt zu Binah, der empfangenden Intelligenz und dem Formgeben.',
      },
      4: {
        'sephira': 'Chesed',
        'sephiraName': 'Gnade',
        'symbol': 'חסד',
        'description':
            'Die 4 resoniert mit Chesed, der expansiven Guete und dem Aufbauen.',
      },
      5: {
        'sephira': 'Geburah',
        'sephiraName': 'Staerke',
        'symbol': 'גבורה',
        'description':
            'Die 5 verbindet mit Geburah, der Kraft der Begrenzung und Transformation.',
      },
      6: {
        'sephira': 'Tiphareth',
        'sephiraName': 'Schoenheit',
        'symbol': 'תפארת',
        'description':
            'Die 6 ist Tiphareth, das harmonische Herzzentrum des Lebensbaums.',
      },
      7: {
        'sephira': 'Netzach',
        'sephiraName': 'Sieg',
        'symbol': 'נצח',
        'description':
            'Die 7 resoniert mit Netzach, der Ausdauer und emotionalen Kraft.',
      },
      8: {
        'sephira': 'Hod',
        'sephiraName': 'Glanz',
        'symbol': 'הוד',
        'description':
            'Die 8 verbindet mit Hod, dem analytischen Verstand und der Kommunikation.',
      },
      9: {
        'sephira': 'Yesod',
        'sephiraName': 'Fundament',
        'symbol': 'יסוד',
        'description':
            'Die 9 fuehrt zu Yesod, dem Fundament der astralen Welt und dem Unterbewusstsein.',
      },
      11: {
        'sephira': 'Kether/Chokmah',
        'sephiraName': 'Bruecke Krone-Weisheit',
        'symbol': 'כתר-חכמה',
        'description':
            'Die Meisterzahl 11 ueberbrueckt Kether und Chokmah - direkte Inspiration aus der Quelle.',
      },
      22: {
        'sephira': 'Alle Sephiroth',
        'sephiraName': 'Gesamter Lebensbaum',
        'symbol': 'עץ החיים',
        'description':
            'Die Meisterzahl 22 umfasst den gesamten Lebensbaum - Master-Builder-Energie.',
      },
      33: {
        'sephira': 'Tiphareth+',
        'sephiraName': 'Erleuchtetes Herz',
        'symbol': 'תפארת',
        'description':
            'Die Meisterzahl 33 verkoerpert das erleuchtete Herzzentrum - bedingungslose Liebe.',
      },
    };
    return map[lifePathNumber] ??
        map[lifePathNumber % 9 == 0 ? 9 : lifePathNumber % 9]!;
  }

  // ── Hebraeische Buchstaben ───────────────────────────────────────────
  static Map<String, dynamic> getHebrewLetterCorrespondence(int number) {
    final map = <int, Map<String, dynamic>>{
      1: {
        'letter': 'Aleph',
        'symbol': 'א',
        'element': 'Luft',
        'tarot': '0 - Der Narr',
        'description': 'Die Quelle, der erste Atem, unendliches Potenzial.',
      },
      2: {
        'letter': 'Beth',
        'symbol': 'ב',
        'element': 'Merkur',
        'tarot': 'I - Der Magier',
        'description':
            'Das Haus, der Behaelter, der erste Akt der Manifestation.',
      },
      3: {
        'letter': 'Gimel',
        'symbol': 'ג',
        'element': 'Mond',
        'tarot': 'II - Die Hohepriesterin',
        'description':
            'Das Kamel, Bruecke zwischen Bewusstsein und Unbewusstem.',
      },
      4: {
        'letter': 'Daleth',
        'symbol': 'ד',
        'element': 'Venus',
        'tarot': 'III - Die Herrscherin',
        'description': 'Die Tuer, der Eingang in fruchtbare Schoepfung.',
      },
      5: {
        'letter': 'Heh',
        'symbol': 'ה',
        'element': 'Widder',
        'tarot': 'IV - Der Herrscher',
        'description': 'Das Fenster, Erleuchtung durch Offenbarung.',
      },
      6: {
        'letter': 'Vav',
        'symbol': 'ו',
        'element': 'Stier',
        'tarot': 'V - Der Hierophant',
        'description': 'Der Nagel, Verbindung von Himmel und Erde.',
      },
      7: {
        'letter': 'Zayin',
        'symbol': 'ז',
        'element': 'Zwillinge',
        'tarot': 'VI - Die Liebenden',
        'description': 'Das Schwert, Entscheidung und Trennung des Wahren.',
      },
      8: {
        'letter': 'Cheth',
        'symbol': 'ח',
        'element': 'Krebs',
        'tarot': 'VII - Der Wagen',
        'description': 'Der Zaun, schuetzender Raum fuer Wachstum.',
      },
      9: {
        'letter': 'Teth',
        'symbol': 'ט',
        'element': 'Loewe',
        'tarot': 'VIII - Die Kraft',
        'description': 'Die Schlange, gezaehmte instinktive Kraft.',
      },
      11: {
        'letter': 'Kaph',
        'symbol': 'כ',
        'element': 'Jupiter',
        'tarot': 'X - Das Rad des Schicksals',
        'description': 'Die Handflaeche, die das Schicksal greift.',
      },
      22: {
        'letter': 'Tav',
        'symbol': 'ת',
        'element': 'Saturn',
        'tarot': 'XXI - Die Welt',
        'description': 'Das Zeichen, Vollendung und Siegel.',
      },
    };
    return map[number] ?? map[number % 9 == 0 ? 9 : number % 9]!;
  }

  // ── Tarot Grosse Arkana ──────────────────────────────────────────────
  static Map<String, dynamic> getTarotCorrespondence(int number) {
    final map = <int, Map<String, dynamic>>{
      1: {
        'card': 'Der Magier',
        'roman': 'I',
        'description':
            'Manifestationskraft - du verbindest Himmel und Erde durch deinen Willen.',
      },
      2: {
        'card': 'Die Hohepriesterin',
        'roman': 'II',
        'description':
            'Intuitive Weisheit - das verborgene Wissen offenbart sich.',
      },
      3: {
        'card': 'Die Herrscherin',
        'roman': 'III',
        'description': 'Schoepferische Fuelle und naehrende Energie.',
      },
      4: {
        'card': 'Der Herrscher',
        'roman': 'IV',
        'description': 'Struktur, Autoritaet und stabile Fundamente.',
      },
      5: {
        'card': 'Der Hierophant',
        'roman': 'V',
        'description': 'Traditioneller Lehrer, Weisheit der Ahnen.',
      },
      6: {
        'card': 'Die Liebenden',
        'roman': 'VI',
        'description': 'Werte-orientierte Entscheidungen und tiefe Bindung.',
      },
      7: {
        'card': 'Der Wagen',
        'roman': 'VII',
        'description':
            'Triumph durch fokussierten Willen und Selbstbeherrschung.',
      },
      8: {
        'card': 'Die Kraft',
        'roman': 'VIII',
        'description': 'Sanfte Staerke zaehmt rohe Energie - innere Macht.',
      },
      9: {
        'card': 'Der Eremit',
        'roman': 'IX',
        'description': 'Inneres Licht, Rueckzug fuer hoehere Weisheit.',
      },
      11: {
        'card': 'Gerechtigkeit',
        'roman': 'XI',
        'description': 'Wahrheit, Ausgleich, karmische Balance.',
      },
      22: {
        'card': 'Die Welt',
        'roman': 'XXI',
        'description': 'Vollendung des Zyklus, Ganzheit und Erfuellung.',
      },
    };
    return map[number] ?? map[number % 9 == 0 ? 9 : number % 9]!;
  }

  // ── Planetarische Zuordnungen ────────────────────────────────────────
  static Map<String, dynamic> getPlanetaryCorrespondence(int number) {
    final map = <int, Map<String, dynamic>>{
      1: {
        'planet': 'Sonne',
        'symbol': '☉',
        'description': 'Lebenskraft, Wille, Ego, Selbstausdruck.',
      },
      2: {
        'planet': 'Mond',
        'symbol': '☽',
        'description': 'Gefuehle, Intuition, Reflexion, Empfindsamkeit.',
      },
      3: {
        'planet': 'Jupiter',
        'symbol': '♃',
        'description': 'Expansion, Weisheit, Glueck, Ueberfluss.',
      },
      4: {
        'planet': 'Uranus / Rahu',
        'symbol': '♅',
        'description':
            'Disziplin, ploetzliche Erkenntnis, technische Praezision.',
      },
      5: {
        'planet': 'Merkur',
        'symbol': '☿',
        'description': 'Kommunikation, Reise, Lernen, Vielseitigkeit.',
      },
      6: {
        'planet': 'Venus',
        'symbol': '♀',
        'description': 'Liebe, Harmonie, Aesthetik, Beziehungen.',
      },
      7: {
        'planet': 'Neptun / Ketu',
        'symbol': '♆',
        'description': 'Mystik, Traum, Aufloesung, spirituelle Tiefe.',
      },
      8: {
        'planet': 'Saturn',
        'symbol': '♄',
        'description': 'Karma, Verantwortung, Meisterschaft, Zeit.',
      },
      9: {
        'planet': 'Mars',
        'symbol': '♂',
        'description': 'Aktion, Mut, Vollendung, gerechter Kampf.',
      },
    };
    return map[number] ?? map[number % 9 == 0 ? 9 : number % 9]!;
  }

  // ── Solfeggio-Frequenzen ─────────────────────────────────────────────
  static double getResonanceFrequency(int number) {
    const freqs = <int, double>{
      1: 174,
      2: 285,
      3: 396,
      4: 417,
      5: 528,
      6: 639,
      7: 741,
      8: 852,
      9: 963,
    };
    return freqs[number] ?? freqs[number % 9 == 0 ? 9 : number % 9]!;
  }

  static String getFrequencyEffect(int number) {
    const map = {
      1: 'Schmerzlinderung, Fundament-Energie',
      2: 'Heilung von Trauma, Geweberegeneration',
      3: 'Befreiung von Schuld und Angst',
      4: 'Erleichterung von Veraenderung',
      5: 'Transformation, DNS-Reparatur (Wunder)',
      6: 'Verbindung in Beziehungen, Liebe',
      7: 'Intuition, spirituelles Erwachen',
      8: 'Rueckkehr zur spirituellen Ordnung',
      9: 'Einheit mit dem Hoeheren Selbst',
    };
    return map[number] ?? map[number % 9 == 0 ? 9 : number % 9]!;
  }
}
