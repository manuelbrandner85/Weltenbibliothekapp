import 'dart:math';

/// ============================================
/// SPIRIT PRACTICES DATABASE
/// Übungs-Templates für alle Kategorien
/// ============================================

class SpiritPracticesDatabase {
  /// KATEGORIE 1: MEDITATION (15 Übungen)
  static List<Map<String, dynamic>> get meditationPractices => [
    {
      'title': 'Achtsamkeitsmeditation',
      'description': 'Konzentriere dich auf deinen Atem und beobachte deine Gedanken ohne Bewertung. Kehre sanft zum Atem zurück, wenn dein Geist wandert.',
      'duration': 10,
      'chakra': 'Krone',
    },
    {
      'title': 'Liebende-Güte-Meditation (Metta)',
      'description': 'Sende Liebe und Mitgefühl zu dir selbst, dann zu geliebten Menschen, dann zu allen Wesen. Wiederhole: "Möge ich/du/alle glücklich sein".',
      'duration': 15,
      'chakra': 'Herz',
    },
    {
      'title': 'Body-Scan-Meditation',
      'description': 'Scanne deinen Körper von Kopf bis Fuß. Spüre in jeden Bereich hinein und löse Verspannungen mit deinem Atem auf.',
      'duration': 20,
      'chakra': 'Wurzel',
    },
    {
      'title': 'Mantra-Meditation (OM)',
      'description': 'Wiederhole das Mantra "OM" innerlich oder laut. Spüre die Vibration im ganzen Körper. Lass den Klang dich in tiefe Ruhe führen.',
      'duration': 10,
      'chakra': 'Stirn',
    },
    {
      'title': 'Zen-Meditation (Zazen)',
      'description': 'Sitz aufrecht, Augen halb geschlossen. Zähle deine Atemzüge von 1-10, dann beginne von vorn. Sei einfach präsent.',
      'duration': 15,
      'chakra': 'Krone',
    },
    {
      'title': 'Walking Meditation',
      'description': 'Gehe langsam und achtsam. Spüre jeden Schritt, die Bewegung deiner Füße, den Kontakt mit dem Boden. Sei ganz im Moment.',
      'duration': 15,
      'chakra': 'Wurzel',
    },
    {
      'title': 'Chakra-Meditation',
      'description': 'Visualisiere jedes der 7 Chakren nacheinander als leuchtendes Licht. Beginne beim Wurzel-Chakra und arbeite dich zur Krone hoch.',
      'duration': 25,
      'chakra': 'Alle',
    },
    {
      'title': 'Inneres-Licht-Meditation',
      'description': 'Visualisiere ein strahlendes Licht in deinem Herzen. Lass es mit jedem Atemzug wachsen, bis es deinen ganzen Körper erfüllt.',
      'duration': 12,
      'chakra': 'Herz',
    },
    {
      'title': 'Stille-Meditation (Vipassana)',
      'description': 'Beobachte alles, was in dir aufsteigt - Gedanken, Gefühle, Empfindungen - ohne zu urteilen oder festzuhalten. Sei stiller Zeuge.',
      'duration': 20,
      'chakra': 'Stirn',
    },
    {
      'title': 'Dankbarkeits-Meditation',
      'description': 'Bringe deine Aufmerksamkeit zu allem, wofür du dankbar bist. Fühle die Dankbarkeit in deinem Herzen wachsen und ausstrahlen.',
      'duration': 10,
      'chakra': 'Herz',
    },
    {
      'title': 'Berg-Meditation',
      'description': 'Visualisiere dich als stabilen, unbeweglichen Berg. Wetter kommt und geht, aber der Berg bleibt fest. Finde diese Stabilität in dir.',
      'duration': 15,
      'chakra': 'Wurzel',
    },
    {
      'title': 'Atem-Bewusstseins-Meditation',
      'description': 'Folge deinem Atem auf seiner Reise - durch die Nase, in die Lungen, zurück nach außen. Spüre jede Nuance der Bewegung.',
      'duration': 10,
      'chakra': 'Hals',
    },
    {
      'title': 'Loslassen-Meditation',
      'description': 'Mit jedem Ausatmen lass los, was dich belastet. Visualisiere, wie Sorgen und Ängste wie Rauch davonziehen.',
      'duration': 12,
      'chakra': 'Solarplexus',
    },
    {
      'title': 'Einheits-Meditation',
      'description': 'Fühle die Verbundenheit mit allem Leben. Du bist nicht getrennt, sondern Teil des großen Ganzen. Spüre diese Einheit.',
      'duration': 15,
      'chakra': 'Krone',
    },
    {
      'title': 'Anahata-Meditation (Herzraum)',
      'description': 'Atme in deinen Herzraum. Mit jedem Atemzug wird er weiter und weiter. Lass Liebe und Mitgefühl von dort ausstrahlen.',
      'duration': 12,
      'chakra': 'Herz',
    },
  ];

  /// KATEGORIE 2: BREATHING (12 Übungen)
  static List<Map<String, dynamic>> get breathingPractices => [
    {
      'title': '4-7-8 Atemtechnik',
      'description': 'Atme 4 Sekunden ein, halte 7 Sekunden, atme 8 Sekunden aus. Wiederhole 4 Runden. Beruhigt das Nervensystem.',
      'duration': 5,
      'chakra': 'Hals',
    },
    {
      'title': 'Box-Breathing (4-4-4-4)',
      'description': 'Atme 4 Sekunden ein, halte 4 Sekunden, atme 4 Sekunden aus, halte 4 Sekunden. Ideal für Fokus und Klarheit.',
      'duration': 5,
      'chakra': 'Stirn',
    },
    {
      'title': 'Wechselatmung (Nadi Shodhana)',
      'description': 'Schließe abwechselnd linkes und rechtes Nasenloch. Balanciert die Gehirnhälften und beruhigt den Geist.',
      'duration': 10,
      'chakra': 'Stirn',
    },
    {
      'title': 'Feuer-Atem (Kapalabhati)',
      'description': 'Schnelle, kraftvolle Ausatmungen durch die Nase. Einatmung passiv. Reinigt und energetisiert. 30 Atemzüge pro Runde.',
      'duration': 5,
      'chakra': 'Solarplexus',
    },
    {
      'title': 'Drei-Teil-Atem',
      'description': 'Atme in 3 Teilen: Bauch, Brustkorb, oberer Brustbereich. Ausatmen in umgekehrter Reihenfolge. Füllt die Lungen vollständig.',
      'duration': 8,
      'chakra': 'Hals',
    },
    {
      'title': 'Ozean-Atem (Ujjayi)',
      'description': 'Atme durch die Nase mit leichter Verengung im Rachen. Erzeuge ein sanftes, ozeanähnliches Rauschen. Beruhigt und wärmt.',
      'duration': 10,
      'chakra': 'Hals',
    },
    {
      'title': 'Bienen-Atem (Bhramari)',
      'description': 'Atme ein, dann summe beim Ausatmen wie eine Biene. Ohren sanft verschließen. Beruhigt den Geist sofort.',
      'duration': 5,
      'chakra': 'Stirn',
    },
    {
      'title': 'Kohärenz-Atem (5-5)',
      'description': 'Atme 5 Sekunden ein, 5 Sekunden aus. Fördert Herz-Gehirn-Kohärenz und emotionale Balance. 6 Atemzüge pro Minute.',
      'duration': 10,
      'chakra': 'Herz',
    },
    {
      'title': 'Energie-Atem (Bastrika)',
      'description': 'Schnelle, kräftige Ein- und Ausatmungen. Wie ein Blasebalg. Erhöht die Energie und weckt die Lebenskraft.',
      'duration': 3,
      'chakra': 'Solarplexus',
    },
    {
      'title': 'Kühlender Atem (Sitali)',
      'description': 'Rolle die Zunge zu einem U, atme durch die Zunge ein (kühlende Luft), atme durch die Nase aus. Kühlt und beruhigt.',
      'duration': 5,
      'chakra': 'Hals',
    },
    {
      'title': 'Mondschein-Atem',
      'description': 'Atme nur durch das linke Nasenloch (rechtes schließen). Aktiviert die beruhigende, weibliche Energie (Ida Nadi).',
      'duration': 8,
      'chakra': 'Sakral',
    },
    {
      'title': 'Sonnen-Atem',
      'description': 'Atme nur durch das rechte Nasenloch (linkes schließen). Aktiviert die energetisierende, männliche Energie (Pingala Nadi).',
      'duration': 8,
      'chakra': 'Solarplexus',
    },
  ];

  /// KATEGORIE 3: CHAKRA (10 Übungen)
  static List<Map<String, dynamic>> get chakraPractices => [
    {
      'title': 'Wurzel-Chakra Erdung',
      'description': 'Visualisiere rotes Licht am Steißbein. Fühle die Verbindung zur Erde. Mantra: LAM. Thema: Sicherheit, Überleben, Stabilität.',
      'duration': 10,
      'chakra': 'Wurzel',
    },
    {
      'title': 'Sakral-Chakra Aktivierung',
      'description': 'Visualisiere orangenes Licht im Unterbauch. Fließende Bewegungen. Mantra: VAM. Thema: Kreativität, Sexualität, Freude.',
      'duration': 12,
      'chakra': 'Sakral',
    },
    {
      'title': 'Solarplexus-Chakra Stärkung',
      'description': 'Visualisiere gelbes Licht im Magenbereich. Atme Kraft ein. Mantra: RAM. Thema: Willenskraft, Selbstwert, Macht.',
      'duration': 10,
      'chakra': 'Solarplexus',
    },
    {
      'title': 'Herz-Chakra Öffnung',
      'description': 'Visualisiere grünes/rosa Licht in der Brustmitte. Atme Liebe ein. Mantra: YAM. Thema: Liebe, Mitgefühl, Vergebung.',
      'duration': 15,
      'chakra': 'Herz',
    },
    {
      'title': 'Hals-Chakra Befreiung',
      'description': 'Visualisiere blaues Licht an der Kehle. Singe, summe oder spreche deine Wahrheit. Mantra: HAM. Thema: Kommunikation, Ausdruck.',
      'duration': 10,
      'chakra': 'Hals',
    },
    {
      'title': 'Stirn-Chakra Erweckung',
      'description': 'Visualisiere indigo Licht zwischen den Augenbrauen. Fokus auf das dritte Auge. Mantra: OM. Thema: Intuition, Weisheit.',
      'duration': 12,
      'chakra': 'Stirn',
    },
    {
      'title': 'Kronen-Chakra Verbindung',
      'description': 'Visualisiere violettes/weißes Licht am Scheitel. Fühle die Verbindung zum Göttlichen. Mantra: AH. Thema: Spiritualität, Einheit.',
      'duration': 15,
      'chakra': 'Krone',
    },
    {
      'title': 'Komplette Chakra-Reinigung',
      'description': 'Gehe durch alle 7 Chakren (Wurzel bis Krone). Visualisiere jedes als leuchtende, rotierende Lichtkugel. Reinige Blockaden.',
      'duration': 25,
      'chakra': 'Alle',
    },
    {
      'title': 'Chakra-Balance mit Kristallen',
      'description': 'Lege Kristalle auf jedes Chakra (rot=Wurzel, orange=Sakral, etc.). Spüre, wie sie die Energie harmonisieren.',
      'duration': 20,
      'chakra': 'Alle',
    },
    {
      'title': 'Chakra-Tanz',
      'description': 'Bewege dich frei, während du dich auf ein Chakra konzentrierst. Lass die Bewegung aus diesem Energiezentrum entstehen.',
      'duration': 15,
      'chakra': 'Alle',
    },
  ];

  /// KATEGORIE 4: JOURNAL (10 Übungen)
  static List<Map<String, dynamic>> get journalPractices => [
    {
      'title': 'Dankbarkeits-Journal',
      'description': 'Schreibe 3-5 Dinge auf, für die du heute dankbar bist. Reflektiere, warum sie dir wichtig sind und wie sie dich bereichern.',
      'duration': 5,
      'chakra': 'Herz',
    },
    {
      'title': 'Traum-Journal',
      'description': 'Notiere deine Träume von letzter Nacht. Welche Symbole, Emotionen oder Botschaften waren präsent? Was könnten sie bedeuten?',
      'duration': 10,
      'chakra': 'Stirn',
    },
    {
      'title': 'Intentions-Journal',
      'description': 'Setze eine klare Intention für den Tag. Was möchtest du manifestieren? Wie möchtest du dich fühlen? Schreibe es auf.',
      'duration': 5,
      'chakra': 'Solarplexus',
    },
    {
      'title': 'Schatten-Arbeit Journal',
      'description': 'Was hat dich heute getriggert? Welche verborgenen Teile von dir zeigen sich? Schreibe ohne Zensur und mit Mitgefühl.',
      'duration': 15,
      'chakra': 'Wurzel',
    },
    {
      'title': 'Freier Strom (Stream of Consciousness)',
      'description': 'Schreibe 5 Minuten ohne Pause. Lass alles fließen, was kommt - Gedanken, Gefühle, Bilder. Kein Filter, keine Bewertung.',
      'duration': 5,
      'chakra': 'Stirn',
    },
    {
      'title': 'Selbstmitgefühls-Brief',
      'description': 'Schreibe einen liebevollen Brief an dich selbst. Sprich zu dir wie zu einem geliebten Freund. Was würdest du ihm sagen?',
      'duration': 10,
      'chakra': 'Herz',
    },
    {
      'title': 'Visions-Journal',
      'description': 'Beschreibe dein ideales Leben in 1, 5, 10 Jahren. Sei spezifisch. Wie fühlt es sich an? Was siehst, hörst, tust du?',
      'duration': 15,
      'chakra': 'Stirn',
    },
    {
      'title': 'Loslassen-Liste',
      'description': 'Schreibe auf, was du loslassen möchtest - Ängste, Glaubenssätze, Beziehungen, Gewohnheiten. Dann verbrenne (symbolisch) die Liste.',
      'duration': 8,
      'chakra': 'Solarplexus',
    },
    {
      'title': 'Synchronizitäts-Tagebuch',
      'description': 'Notiere bedeutungsvolle Zufälle, Zeichen oder wiederkehrende Muster. Welche Botschaft könnte das Universum dir senden?',
      'duration': 10,
      'chakra': 'Krone',
    },
    {
      'title': 'Heilungs-Journal',
      'description': 'Schreibe über eine Wunde, die heilen möchte. Gib ihr Raum, erkenne sie an. Was brauchst du, um zu heilen?',
      'duration': 15,
      'chakra': 'Herz',
    },
  ];

  /// Template holen nach Kategorie
  static Map<String, dynamic> getTemplate(String category, String? preferredChakra) {
    List<Map<String, dynamic>> practices;
    
    switch (category) {
      case 'meditation':
        practices = meditationPractices;
        break;
      case 'breathing':
        practices = breathingPractices;
        break;
      case 'chakra':
        practices = chakraPractices;
        break;
      case 'journal':
        practices = journalPractices;
        break;
      default:
        practices = meditationPractices;
    }
    
    // Filter nach Chakra wenn gewünscht
    if (preferredChakra != null && preferredChakra != 'Alle') {
      final filtered = practices.where((p) => p['chakra'] == preferredChakra).toList();
      if (filtered.isNotEmpty) {
        practices = filtered;
      }
    }
    
    // Zufällige Auswahl
    final random = Random();
    return practices[random.nextInt(practices.length)];
  }
  
  /// Anzahl Übungen pro Kategorie
  static Map<String, int> get counts => {
    'meditation': meditationPractices.length,
    'breathing': breathingPractices.length,
    'chakra': chakraPractices.length,
    'journal': journalPractices.length,
  };
}
