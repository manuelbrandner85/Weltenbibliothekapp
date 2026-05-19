// Mantra-Datenbank mit Wirkungs- + Situations-Tags fuer den Mantra-Guide.
// Bereich M-Datenanteil.

library;

class MantraEntry {
  final String id;
  final String sanskrit;       // ॐ नमः शिवाय
  final String translit;        // Om Namah Shivaya
  final String pronunciation;   // Om Nah-mah Shi-vai-ah
  final String simpleTranslation; // Verneigung vor Shiva (Bewusstsein)
  final String beginnerExplanation; // Was bedeutet das fuer mich?
  final List<String> effects;   // 'Beruhigung','Mut','Konzentration'
  final List<String> situations; // 'Vor Auftritt','Beim Einschlafen'
  final int? recommendedReps;   // 9/27/54/108
  final String emoji;

  const MantraEntry({
    required this.id,
    required this.sanskrit,
    required this.translit,
    required this.pronunciation,
    required this.simpleTranslation,
    required this.beginnerExplanation,
    required this.effects,
    required this.situations,
    this.recommendedReps,
    this.emoji = '🕉️',
  });
}

const List<MantraEntry> mantraLibrary = [
  MantraEntry(
    id: 'om',
    sanskrit: 'ॐ',
    translit: 'OM (AUM)',
    pronunciation: 'Aaa-Uuu-Mmm (drei Klang-Phasen)',
    simpleTranslation: 'Der Urklang -- Vibration aus der alles entsteht',
    beginnerExplanation: 'Das einfachste und maechtigste Mantra. Wenn du nicht '
        'weisst womit anfangen: nimm OM. Drei Klangphasen (Aa-Uu-Mmm) entsprechen '
        'Schoepfung, Erhaltung, Aufloesung. Jeder kann OM toenen -- selbst leise '
        'gedacht wirkt es.',
    effects: ['Beruhigung','Erdung','Meditation','Klarheit'],
    situations: ['Beim Einschlafen','Vor Meditation','Bei innerer Unruhe',
        'Beim Spazieren'],
    recommendedReps: 108,
    emoji: '🕉️',
  ),
  MantraEntry(
    id: 'soham',
    sanskrit: 'सो ऽहम्',
    translit: 'So Ham',
    pronunciation: 'Sooo (Einatmen) - Hammm (Ausatmen)',
    simpleTranslation: 'Ich bin Das -- der natuerliche Atem',
    beginnerExplanation: 'Das natuerliche Atem-Mantra. Beim Einatmen denkst du '
        '"So", beim Ausatmen "Ham". Dein Atem macht das ohnehin schon -- du '
        'machst es nur bewusst. Perfekt fuer Anfaenger und beim Einschlafen.',
    effects: ['Beruhigung','Schlaf','Atemarbeit','Sanfte Praxis'],
    situations: ['Beim Einschlafen','Bei Schlafproblemen','In der U-Bahn',
        'Bei Angst-Wellen','Vor schwerem Gespraech'],
    recommendedReps: 27,
    emoji: '🌬️',
  ),
  MantraEntry(
    id: 'omnamahshivaya',
    sanskrit: 'ॐ नमः शिवाय',
    translit: 'Om Namah Shivaya',
    pronunciation: 'Om Nah-mah Shi-vai-ah',
    simpleTranslation: 'Verneigung vor dem reinen Bewusstsein',
    beginnerExplanation: 'Eines der bekanntesten Mantras. Shiva ist hier kein '
        'Gott "da oben", sondern das reine Bewusstsein in dir. Du verneigst '
        'dich vor deinem eigenen tiefsten Wesen. Wirkt transformativ bei '
        'tiefen Lebensumbruechen.',
    effects: ['Transformation','Loslassen','Mut','Spirituelle Vertiefung'],
    situations: ['Bei Lebenswende','Nach Trennung','Vor wichtiger Entscheidung',
        'Bei Sinnsuche'],
    recommendedReps: 108,
    emoji: '🔱',
  ),
  MantraEntry(
    id: 'manipadme',
    sanskrit: 'ॐ मणि पद्मे हूँ',
    translit: 'Om Mani Padme Hum',
    pronunciation: 'Om Mah-ni Pad-meh Hum',
    simpleTranslation: 'Das Juwel im Lotus -- universelles Mitgefuehl',
    beginnerExplanation: 'Das Mitgefuehls-Mantra des tibetischen Buddhismus. '
        'Du rufst die Qualitaet des Mitgefuehls in dir wach -- fuer dich und '
        'fuer andere. Besonders schoen wenn du wuetend, urteilend oder hart '
        'gegen dich selbst bist.',
    effects: ['Mitgefuehl','Selbstmitgefuehl','Versoehnung','Sanftheit'],
    situations: ['Bei Streit','Bei Selbstkritik','Bei Trauer',
        'Beim Gehen mit anderen','Vor Versoehnungs-Gespraech'],
    recommendedReps: 108,
    emoji: '🪷',
  ),
  MantraEntry(
    id: 'gayatri',
    sanskrit: 'ॐ भूर्भुवः स्वः',
    translit: 'Gayatri-Mantra',
    pronunciation: 'Om Bhuur Bhuu-vah Sva-ha. Tat Sa-vee-tur Va-rein-yam.',
    simpleTranslation: 'Anrufung des Sonnen-Lichts -- Erleuchtung des Geistes',
    beginnerExplanation: 'Das aelteste und ehrwuerdigste Mantra der vedischen '
        'Tradition. Du rufst das Licht der Sonne in deinen Geist. '
        'Klassisch bei Sonnenaufgang gesungen. Wirkt klaerend und erhebend.',
    effects: ['Klarheit','Erleuchtung','Konzentration','Morgenenergie'],
    situations: ['Morgens beim Aufstehen','Vor Pruefung','Vor wichtiger Arbeit',
        'Beim Lernen'],
    recommendedReps: 27,
    emoji: '☀️',
  ),
  MantraEntry(
    id: 'ganapati',
    sanskrit: 'ॐ गं गणपतये नमः',
    translit: 'Om Gam Ganapataye Namaha',
    pronunciation: 'Om Gam Ga-na-pa-tai-eh Na-ma-ha',
    simpleTranslation: 'Anrufung Ganeshas -- der die Hindernisse beseitigt',
    beginnerExplanation: 'Vor jedem Neubeginn klassisch gesungen. Ganesha (der '
        'Elefantenkopf-Gott) steht fuer die Beseitigung von Hindernissen. '
        'Innerlich gesehen: du raeumst innere Blockaden weg.',
    effects: ['Neuanfang','Hindernis-Loesung','Mut','Klarheit'],
    situations: ['Vor neuem Projekt','Vor Geschaeftsstart','Bei Blockade',
        'Vor Job-Wechsel','Vor Umzug'],
    recommendedReps: 108,
    emoji: '🐘',
  ),
  MantraEntry(
    id: 'shanti',
    sanskrit: 'ॐ शान्तिः शान्तिः शान्तिः',
    translit: 'Om Shanti Shanti Shanti',
    pronunciation: 'Om Shaaan-ti Shaaan-ti Shaaan-ti',
    simpleTranslation: 'Friede in Koerper, Geist und Seele',
    beginnerExplanation: 'Friedens-Mantra. Drei Shanti = Friede auf drei Ebenen '
        '(Koerper, Geist, Seele). Ideal als Abschluss von Meditation oder '
        'wenn du zur Ruhe kommen willst.',
    effects: ['Friede','Beruhigung','Abschluss','Sanftheit'],
    situations: ['Nach stressigem Tag','Vor dem Schlafen',
        'Nach Streit','Als Meditations-Abschluss'],
    recommendedReps: 9,
    emoji: '🕊️',
  ),
  MantraEntry(
    id: 'lokah',
    sanskrit: 'लोकाः समस्ताः सुखिनो भवन्तु',
    translit: 'Lokah Samastah Sukhino Bhavantu',
    pronunciation: 'Lo-kah Sa-mas-taah Sukh-ee-no Bha-van-tu',
    simpleTranslation: 'Moegen alle Wesen gluecklich sein',
    beginnerExplanation: 'Wunsch fuer alle Wesen. Du sendest gutes mit deinem '
        'Atem in die Welt. Wirkt erstaunlich tief auch fuer dich selbst -- '
        'wenn du Gluck wuenscht, wirst du selbst empfaenglicher dafuer.',
    effects: ['Mitgefuehl','Verbundenheit','Freude','Grosszuegigkeit'],
    situations: ['Wenn du einsam bist','Bei Frust mit anderen',
        'Beim Beten','Bei Naturwanderung'],
    recommendedReps: 27,
    emoji: '🌍',
  ),
  // Neue Mantras (M-Erweiterung)
  MantraEntry(
    id: 'sat-nam',
    sanskrit: 'सत् नाम',
    translit: 'Sat Nam',
    pronunciation: 'Saaat Naaam',
    simpleTranslation: 'Wahrheit ist mein Name -- ich bin Wahrheit',
    beginnerExplanation: 'Kundalini-Yoga-Mantra. Sehr direkt: du erinnerst '
        'dich daran, dass dein innerstes Wesen wahr und echt ist. Bei '
        'Unsicherheit ueber dich selbst sehr klaerend.',
    effects: ['Authentizitaet','Selbstvertrauen','Klarheit'],
    situations: ['Vor wichtigem Gespraech','Bei Selbstzweifel',
        'Morgens als Affirmation'],
    recommendedReps: 27,
    emoji: '💫',
  ),
  MantraEntry(
    id: 'om-shrim',
    sanskrit: 'ॐ श्रीं महालक्ष्म्यै नमः',
    translit: 'Om Shrim Mahalakshmiyei Namaha',
    pronunciation: 'Om Shriim Ma-ha-laksh-mi-jei Na-ma-ha',
    simpleTranslation: 'Anrufung der Fuelle (Lakshmi-Mantra)',
    beginnerExplanation: 'Klassisches Wohlstands- und Fuelle-Mantra. Lakshmi '
        'steht fuer Reichtum in allen Formen -- Liebe, Gesundheit, materiell. '
        'Bei chronischer Mangel-Stimmung sehr nuetzlich.',
    effects: ['Wohlstand','Fuelle','Empfaenglichkeit','Dankbarkeit'],
    situations: ['Bei Geldsorgen','Vor Verhandlungen','Bei Karriere-Themen',
        'Beim Vision-Boarding'],
    recommendedReps: 108,
    emoji: '💰',
  ),
  MantraEntry(
    id: 'om-tare',
    sanskrit: 'ॐ तारे तुत्तारे तुरे स्वाहा',
    translit: 'Om Tare Tuttare Ture Soha',
    pronunciation: 'Om Ta-reh Tut-ta-reh Tu-reh So-ha',
    simpleTranslation: 'Anrufung von Tara -- der Mutter der Befreiung',
    beginnerExplanation: 'Tibetisches Mantra der Gruenen Tara. Sie ist die '
        'schnelle, mitfuehlende Beschuetzerin. Bei akuter Angst oder Panik '
        'sehr stark.',
    effects: ['Schutz','Mut','Angstaufloesung','Sanftheit'],
    situations: ['Bei Angstattacke','Bei Reise-Angst','Bei Krankheit',
        'Bei Gefahr'],
    recommendedReps: 108,
    emoji: '🛡️',
  ),
  MantraEntry(
    id: 'wahe-guru',
    sanskrit: 'वाहे गुरू',
    translit: 'Wahe Guru',
    pronunciation: 'Wa-heh Guu-ruu',
    simpleTranslation: 'Wow -- das Lehrende! Ehrfurcht vor der Weisheit',
    beginnerExplanation: 'Sikh-Mantra des Staunens. "Wahe" ist der Ausruf von '
        'Wow -- das tiefe Staunen vor dem Wunder des Lebens. Wenn du in '
        'Trockenheit lebst, erweckt es Lebendigkeit.',
    effects: ['Freude','Staunen','Ekstase','Lebendigkeit'],
    situations: ['Bei depressiver Stimmung','Bei Routine-Stress',
        'Beim Naturerlebnis','Vor wichtigem Erlebnis'],
    recommendedReps: 27,
    emoji: '✨',
  ),
];

/// Alle einzigartigen Wirkungen aus der Datenbank.
List<String> get allMantraEffects {
  final set = <String>{};
  for (final m in mantraLibrary) {
    set.addAll(m.effects);
  }
  return set.toList()..sort();
}

/// Alle einzigartigen Situationen.
List<String> get allMantraSituations {
  final set = <String>{};
  for (final m in mantraLibrary) {
    set.addAll(m.situations);
  }
  return set.toList()..sort();
}

/// Mantras gefiltert nach Wirkung.
List<MantraEntry> mantrasForEffect(String effect) =>
    mantraLibrary.where((m) => m.effects.contains(effect)).toList();

/// Mantras gefiltert nach Situation.
List<MantraEntry> mantrasForSituation(String s) =>
    mantraLibrary.where((m) => m.situations.contains(s)).toList();

// ── 21-Tage-Beruhigungs-Praxis ────────────────────────────────────────
// Bereich M6: Anfaenger-Plan, leichte Steigerung.
const List<Map<String, String>> mantraJourney21Days = [
  {'day':'1','mantra':'om','focus':'Erste Beruehrung','reps':'9'},
  {'day':'2','mantra':'om','focus':'Atem spueren','reps':'9'},
  {'day':'3','mantra':'soham','focus':'Atem als Mantra','reps':'27'},
  {'day':'4','mantra':'soham','focus':'Beim Einschlafen','reps':'27'},
  {'day':'5','mantra':'shanti','focus':'Frieden-Schluss','reps':'9'},
  {'day':'6','mantra':'om','focus':'Vor dem Frueh-stueck','reps':'27'},
  {'day':'7','mantra':'soham','focus':'7-Tage-Reflexion','reps':'27'},
  {'day':'8','mantra':'manipadme','focus':'Selbstmitgefuehl','reps':'27'},
  {'day':'9','mantra':'manipadme','focus':'Anderen wohlgesonnen','reps':'27'},
  {'day':'10','mantra':'lokah','focus':'Wuensche fuer alle','reps':'27'},
  {'day':'11','mantra':'om','focus':'Vertiefen','reps':'54'},
  {'day':'12','mantra':'soham','focus':'Stille zwischen Atem','reps':'54'},
  {'day':'13','mantra':'shanti','focus':'Friede mit dem Tag','reps':'27'},
  {'day':'14','mantra':'manipadme','focus':'2-Wochen-Reflexion','reps':'54'},
  {'day':'15','mantra':'om-tare','focus':'Schutz fuer dich','reps':'27'},
  {'day':'16','mantra':'lokah','focus':'Welt-Heilsformel','reps':'27'},
  {'day':'17','mantra':'wahe-guru','focus':'Staunen','reps':'27'},
  {'day':'18','mantra':'soham','focus':'Tiefer Atem','reps':'108'},
  {'day':'19','mantra':'manipadme','focus':'Volles Mitgefuehl','reps':'108'},
  {'day':'20','mantra':'om','focus':'Mit allem verbunden','reps':'108'},
  {'day':'21','mantra':'shanti','focus':'Abschluss & Friede','reps':'108'},
];
