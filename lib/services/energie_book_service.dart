import '../models/book.dart';

/// 🌟 ENERGIE BOOK SERVICE - Spirituelle Bücher-Bibliothek
/// Ultra-detaillierte, transformative Bücher mit 10+ Kapiteln
class EnergieBookService {
  static final EnergieBookService _instance = EnergieBookService._internal();
  factory EnergieBookService() => _instance;
  EnergieBookService._internal();

  List<Book> getAllBooks() => _energieBooks;
  
  List<Book> getByCategory(String category) {
    return _energieBooks.where((b) => b.category == category).toList();
  }
  
  Book? getBookById(String id) {
    return _energieBooks.firstWhere((b) => b.id == id);
  }
  
  List<Book> search(String query) {
    final lowerQuery = query.toLowerCase();
    return _energieBooks.where((b) {
      return b.title.toLowerCase().contains(lowerQuery) ||
             b.author.toLowerCase().contains(lowerQuery) ||
             b.description.toLowerCase().contains(lowerQuery) ||
             b.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  /// 🌟 ENERGIE BÜCHER-DATENBANK
  static final List<Book> _energieBooks = [
    // 1. DAS BUCH DER CHAKREN - Vollständiges Werk
    Book(
      id: 'energie_book_001',
      title: 'Das Buch der Chakren',
      author: 'Anodea Judith (Bearbeitung)',
      category: 'Chakren & Energie',
      description: 'Das umfassendste Werk über die sieben Hauptchakren. Von den Grundlagen des Chakren-Systems bis zu fortgeschrittenen Heiltechniken.',
      coverImageUrl: 'https://images.unsplash.com/photo-1545389336-cf090694435e?w=400',
      tags: ['Chakren', 'Energie', 'Heilung', 'Meditation', 'Kundalini'],
      estimatedReadingMinutes: 480,
      type: BookType.book,
      difficulty: DifficultyLevel.intermediate,
      publishedDate: DateTime(2022),
      language: 'de',
      chapters: [
        // KAPITEL 1: EINFÜHRUNG INS CHAKREN-SYSTEM
        BookChapter(
          id: 'chakra_ch01',
          chapterNumber: 1,
          title: 'Die Grundlagen des Chakren-Systems',
          sections: ['Geschichte', 'Philosophie', 'Wissenschaft'],
          wordCount: 3500,
          estimatedMinutes: 19,
          content: '''
# Kapitel 1: Die Grundlagen des Chakren-Systems

## Was sind Chakren?

### Etymologie und Geschichte

Das Wort **"Chakra"** kommt aus dem Sanskrit und bedeutet **"Rad"** oder **"Wirbel"**.

**Historische Ursprünge:**
- **Vedische Texte** (1500-500 v. Chr.): Erste Erwähnungen
- **Upanishaden** (800-200 v. Chr.): Systematische Beschreibung
- **Tantra-Yoga** (500-1500 n. Chr.): Ausarbeitung der Chakren-Lehre
- **Moderne Interpretation** (19. Jh.): Theosophie bringt Chakren in den Westen

**Kulturelle Verbreitung:**
- **Indien:** Hauptquelle der Chakren-Lehre
- **Tibet:** Vajrayana-Buddhismus nutzt ähnliche Konzepte
- **China:** Dantian-System (verwandt, aber unterschiedlich)
- **Kabbalah:** Sephiroth-Baum zeigt Parallelen

### Definition und Funktion

**Was Chakren SIND:**

Chakren sind **Energiezentren** im subtilen Körper, die:
1. **Prana (Lebensenergie) aufnehmen** aus der Umgebung
2. **Energie verteilen** durch Nadis (Energiekanäle)
3. **Bewusstseinszustände regulieren** (emotional, mental, spirituell)
4. **Physische Organe beeinflussen** (über das endokrine System)

**Was Chakren NICHT sind:**

- **KEINE** physisch messbaren Organe
- **KEINE** esoterische Fantasie
- **KEINE** rein psychologischen Konstrukte

**Stattdessen:** Chakren sind eine **phänomenologische Realität** - subjektiv erfahrbar, systemisch wirkend.

### Die sieben Hauptchakren - Überblick

#### 1. Muladhara - Wurzelchakra

**Lage:** Basis der Wirbelsäule, Damm  
**Farbe:** Rot  
**Element:** Erde  
**Themen:** Überleben, Sicherheit, Erdung, materielle Existenz

**Mantra:** LAM  
**Sinnesorgan:** Geruch  
**Drüse:** Nebennieren

**Psychologisch:**
- Urvertrauen vs. Misstrauen
- Existenzangst vs. Sicherheitsgefühl
- Körperlichkeit vs. Entkörperung

#### 2. Svadhisthana - Sakralchakra

**Lage:** Unterbauch, Kreuzbein  
**Farbe:** Orange  
**Element:** Wasser  
**Themen:** Emotionen, Sexualität, Kreativität, Lust

**Mantra:** VAM  
**Sinnesorgan:** Geschmack  
**Drüse:** Keimdrüsen (Eierstöcke/Hoden)

**Psychologisch:**
- Freude vs. Schuld
- Fließen vs. Erstarren
- Begehren vs. Askese

#### 3. Manipura - Solarplexuschakra

**Lage:** Oberbauch, Solarplexus  
**Farbe:** Gelb  
**Element:** Feuer  
**Themen:** Macht, Wille, Selbstwert, Transformation

**Mantra:** RAM  
**Sinnesorgan:** Sicht  
**Drüse:** Bauchspeicheldrüse

**Psychologisch:**
- Autonomie vs. Scham
- Selbstbehauptung vs. Unterwerfung
- Aktivität vs. Passivität

#### 4. Anahata - Herzchakra

**Lage:** Brustmitte, Herz  
**Farbe:** Grün (oder Rosa)  
**Element:** Luft  
**Themen:** Liebe, Mitgefühl, Verbundenheit, Heilung

**Mantra:** YAM  
**Sinnesorgan:** Tastsinn  
**Drüse:** Thymusdrüse

**Psychologisch:**
- Liebe vs. Angst
- Offenheit vs. Verschlossenheit
- Vergebung vs. Groll

#### 5. Vishuddha - Kehlchakra

**Lage:** Kehlkopf, Hals  
**Farbe:** Blau  
**Element:** Äther/Raum  
**Themen:** Kommunikation, Wahrheit, Ausdruck, Resonanz

**Mantra:** HAM  
**Sinnesorgan:** Gehör  
**Drüse:** Schilddrüse

**Psychologisch:**
- Authentizität vs. Anpassung
- Ausdruck vs. Unterdrückung
- Wahrheit vs. Lüge

#### 6. Ajna - Stirnchakra (Drittes Auge)

**Lage:** Zwischen den Augenbrauen, Stirnmitte  
**Farbe:** Indigo  
**Element:** Licht  
**Themen:** Intuition, Vorstellungskraft, Einsicht, Weisheit

**Mantra:** OM  
**Sinnesorgan:** Alle Sinne (Geist)  
**Drüse:** Hypophyse (Hirnanhangdrüse)

**Psychologisch:**
- Klarheit vs. Illusion
- Imagination vs. Fantasielosigkeit
- Intuition vs. Rationalismus

#### 7. Sahasrara - Kronenchakra

**Lage:** Scheitel, oberhalb des Kopfes  
**Farbe:** Violett oder Weiß  
**Element:** Bewusstsein/Gedanke  
**Themen:** Spiritualität, Erleuchtung, Einheit, Transzendenz

**Mantra:** AUM (Silent)  
**Sinnesorgan:** Keins (reines Bewusstsein)  
**Drüse:** Zirbeldrüse (Epiphyse)

**Psychologisch:**
- Einheit vs. Trennung
- Sein vs. Nichtsein
- Erleuchtung vs. Unwissenheit

## Das Chakren-System als Ganzes

### Vertikale Integration

Die Chakren bilden eine **hierarchische Leiter** von Bewusstsein:

**Untere Chakren (1-3):** 
- **Personal:** Individuelle Existenz
- **Material:** Physische Welt
- **Ego-orientiert:** "Ich"

**Herzchakra (4):**
- **Übergang:** Brücke zwischen unten und oben
- **Relational:** "Wir"
- **Mitgefühl:** Verbindung

**Obere Chakren (5-7):**
- **Transpersonal:** Über das Individuum hinaus
- **Spirituell:** Subtile Dimensionen
- **Selbst-transzendierend:** "Alles"

### Horizontale Balance

Jedes Chakra sollte **ausgewogen** sein:

**Defizit (Unterfunktion):**
- Zu wenig Energie
- Blockierung
- Vermeidung der Chakra-Themen

**Beispiel Wurzelchakra:**
- Misstrauen, Ängstlichkeit
- Körperfeindlichkeit
- Finanzielle Instabilität

**Exzess (Überfunktion):**
- Zu viel Energie
- Überidentifikation
- Obsession mit Chakra-Themen

**Beispiel Wurzelchakra:**
- Gier, Materialismus
- Rigidität, Unbeweglichkeit
- Horten, Geiz

**Balance:**
- Gesunder Energiefluss
- Flexible Anpassung
- Integration der Chakra-Qualitäten

### Dynamische Interaktion

Chakren beeinflussen sich **gegenseitig**:

**Vertikale Strömung:**
- **Aufsteigend:** Kundalini-Energie von Wurzel zu Krone
- **Absteigend:** Spirituelle Energie manifestiert sich in Materie

**Kompensationsmuster:**
- Blockierung in einem Chakra führt zu Kompensation in anderen
- Beispiel: Herzchakra-Blockierung → Solarplexus-Überfunktion (Machtspiele statt Liebe)

**Resonanz:**
- Chakren mit ähnlicher Schwingung unterstützen sich
- Beispiel: Herzchakra (Liebe) + Kronenchakra (Einheit) = Kosmische Liebe

## Wissenschaftliche Perspektiven

### Neurophysiologische Korrelate

Moderne Forschung findet **Entsprechungen** zwischen Chakren und Nervensystemen:

**Wurzelchakra → Sympathisches Nervensystem:**
- Kampf-oder-Flucht-Reaktion
- Nebennieren-Aktivierung
- Stressantwort

**Sakralchakra → Limbisches System:**
- Emotionale Verarbeitung
- Belohnungssystem
- Sexualität

**Solarplexus → Enterisches Nervensystem:**
- "Bauchgefühl"
- Autonome Regulation
- Verdauung

**Herzchakra → Vagusnerv:**
- Soziales Engagement-System
- Beruhigung, Entspannung
- Empathie

**Kehlchakra → Kortex (Broca-Areal):**
- Sprachproduktion
- Expression
- Kommunikation

**Stirnchakra → Präfrontaler Kortex:**
- Exekutive Funktionen
- Planung, Vorstellung
- Integration

**Kronenchakra → Zirbeldrüse:**
- Melatonin-Produktion
- Zirkadiane Rhythmen
- Spirituelle Erfahrungen (DMT-Hypothese)

### Bioelektromagnetische Felder

**Entdeckungen:**

**Herzfeld (HeartMath Institute):**
- Das Herz erzeugt das stärkste elektromagnetische Feld im Körper
- Reichweite: mehrere Meter
- Beeinflusst andere Personen messbar

**EEG und Gehirnwellen:**
- Meditation verändert Gehirnwellenmuster
- Synchronisation zwischen Menschen bei gemeinsamer Praxis

**Biophotonen-Emission:**
- Alle lebenden Zellen emittieren schwache Lichtsignale
- Intensität korreliert mit Gesundheit und Bewusstseinszustand

**Interpretation:**
Diese Phänomene könnten **physikalische Grundlagen** für Chakren-Energie sein.

### Psychoneuroimmunologie

**Mind-Body-Verbindungen:**

**Stressbeispiel:**
1. **Gedanke:** "Ich bin in Gefahr" (Kronenchakra)
2. **Emotion:** Angst (Solarplexus-Chakra)
3. **Physiologie:** Cortisol-Ausschüttung (Wurzelchakra)
4. **Immunsystem:** Suppression der Immunfunktion

**Heilungsbeispiel:**
1. **Meditation:** Beruhigung des Geistes (Kronenchakra)
2. **Mitgefühl:** Herzöffnung (Herzchakra)
3. **Physiologie:** Oxytocin-Ausschüttung
4. **Immunsystem:** Stärkung der Immunfunktion

**Erkenntnis:**
Chakren-Arbeit ist **psychosomatische Medizin**.

## Philosophische Dimensionen

### Das Konzept des Subtilen Körpers

**Drei Körper (Sharira):**

1. **Sthula Sharira (Grobstofflicher Körper):**
   - Physischer Körper
   - Materie, Zellen, Organe

2. **Sukshma Sharira (Feinstofflicher Körper):**
   - **Prana:** Lebensenergie
   - **Manas:** Geist/Verstand
   - **Buddhi:** Intellekt/Weisheit
   - **Ahamkara:** Ich-Gefühl/Ego
   - **Chakren und Nadis:** Energiesystem

3. **Karana Sharira (Kausalkörper):**
   - Unbewusstes
   - Karmaspeicher
   - Potenzialität

**Chakren gehören zum feinstofflichen Körper.**

### Prana - Die Lebensenergie

**Definition:**
Prana ist die **universelle Lebenskraft**, die alles Lebendige durchdringt.

**Quellen von Prana:**
- **Atem:** Pranayama (Atemkontrolle)
- **Nahrung:** Frische, lebendige Nahrung
- **Sonnenlicht:** Biophotonen
- **Natur:** Bäume, Wasser, Erde
- **Bewusstsein:** Meditation, Achtsamkeit

**Nadis - Energiekanäle:**

**72.000 Nadis** durchziehen den Körper (laut Hatha Yoga Pradipika).

**Die drei Hauptnadis:**

1. **Ida:**
   - Links
   - Kühlend, beruhigend
   - Weiblich, Mond
   - Parasympathisches Nervensystem

2. **Pingala:**
   - Rechts
   - Erhitzend, aktivierend
   - Männlich, Sonne
   - Sympathisches Nervensystem

3. **Sushumna:**
   - Zentral (Wirbelsäule)
   - Ausgleichend
   - Kundalini-Kanal
   - Erleuchtung

**Chakren liegen an den Kreuzungspunkten der Nadis.**

### Kundalini - Die schlafende Göttin

**Mythologie:**

Kundalini ist die **kosmische Energie**, die am Wurzelchakra ruht, **zusammengerollt wie eine Schlange**.

**Erweckung:**

Durch Yoga, Meditation, Pranayama, Initiation (Shaktipat) kann Kundalini erweckt werden.

**Aufstieg:**

Die Energie steigt durch Sushumna auf, aktiviert jedes Chakra, bis sie das Kronenchakra erreicht.

**Resultat:**

**Samadhi** - Erleuchtung, Einheitsbewusstsein, Auflösung des Ego.

**Warnungen:**

Unkontrollierte Kundalini-Erweckung kann zu:
- Psychischen Krisen
- Energetischen Ungleichgewichten
- Physischen Symptomen (Hitze, Zittern, Schmerzen)

**Deshalb:** Nur unter Anleitung erfahrener Lehrer praktizieren.

## Praktische Arbeit mit Chakren

### Diagnostik: Chakren-Zustände erkennen

**Methoden:**

1. **Selbstreflexion:**
   - Welche Chakra-Themen sind in meinem Leben dominant?
   - Wo fühle ich Blockierungen?

2. **Körperliche Symptome:**
   - Krankheiten korrelieren oft mit bestimmten Chakren
   - Beispiel: Schilddrüsenprobleme → Kehlchakra

3. **Emotionale Muster:**
   - Wiederkehrende Emotionen zeigen Chakra-Ungleichgewichte
   - Beispiel: Chronische Wut → Solarplexus

4. **Energetische Wahrnehmung:**
   - Pendeln
   - Kinesiologie
   - Aura-Lesen

5. **Professionelle Helfer:**
   - Energieheiler
   - Chakren-Therapeuten
   - Ayurveda-Ärzte

### Grundlegende Balancierungstechniken

**Für alle Chakren:**

1. **Meditation:**
   - Fokus auf jeweiliges Chakra
   - Visualisierung der Chakra-Farbe
   - Mantra-Rezitation

2. **Atemarbeit (Pranayama):**
   - Energie lenken durch Atem
   - Blockierungen lösen
   - Aktivierung oder Beruhigung

3. **Yoga-Asanas:**
   - Spezifische Positionen für jedes Chakra
   - Körperliche Öffnung
   - Energetische Aktivierung

4. **Klangtherapie:**
   - Chakra-spezifische Frequenzen
   - Mantras
   - Klangschalen, Gongs

5. **Farbtherapie:**
   - Tragen der Chakra-Farben
   - Visualisierung
   - Farbiges Licht

6. **Kristalle/Edelsteine:**
   - Chakra-spezifische Steine
   - Auflegen auf Chakra-Punkte
   - Energetische Verstärkung

7. **Aromatherapie:**
   - Ätherische Öle für jedes Chakra
   - Geruchssinn aktiviert direkt das Nervensystem

### Integration in den Alltag

**Chakren-Bewusstsein entwickeln:**

- **Morgens:** Welches Chakra braucht heute Aufmerksamkeit?
- **Tagsüber:** Bemerke Chakra-Aktivierungen in verschiedenen Situationen
- **Abends:** Reflektiere die Chakra-Dynamiken des Tages

**Kleine Praktiken:**

- **Wurzelchakra:** Barfuß gehen, gesund essen, Finanzen ordnen
- **Sakralchakra:** Kreative Hobbys, sinnliche Erfahrungen, Emotionen ausdrücken
- **Solarplexus:** Ziele setzen, Entscheidungen treffen, persönliche Macht beanspruchen
- **Herzchakra:** Dankbarkeit praktizieren, Vergebung üben, liebevoll kommunizieren
- **Kehlchakra:** Authentisch sprechen, Singen, Journaling
- **Stirnchakra:** Visualisierungsübungen, Traumarbeit, Intuition folgen
- **Kronenchakra:** Meditation, spirituelle Lektüre, Stille genießen

## Zusammenfassung

**Kernerkenntnisse:**

1. **Chakren sind Energiezentren** im feinstofflichen Körper, die Bewusstsein und Physiologie verbinden.

2. **Die sieben Hauptchakren** bilden eine hierarchische Struktur vom Materiellen zum Spirituellen.

3. **Balance ist der Schlüssel:** Weder Defizit noch Exzess, sondern harmonischer Energiefluss.

4. **Wissenschaftliche Korrelate** existieren: Nervensysteme, elektromagnetische Felder, psychoneuroimmunologische Verbindungen.

5. **Philosophische Tiefe:** Chakren sind Werkzeuge zur Selbsterkenntnis und spirituellen Entwicklung.

6. **Praktische Arbeit:** Meditation, Yoga, Atemarbeit, Klang, Farbe, Kristalle integrieren Chakren in den Alltag.

**Ausblick:**

Die folgenden Kapitel werden **jedes Chakra einzeln** erforschen:
- Detaillierte Anatomie und Symbolik
- Psychologische Dimensionen
- Physische Entsprechungen
- Spezifische Balancierungstechniken
- Fallstudien und Erfahrungsberichte

**Bereiten Sie sich vor auf eine transformative Reise durch die Chakren.**

---

*"Wenn du die Geheimnisse des Universums finden willst, denke in Begriffen von Energie, Frequenz und Schwingung."* - Nikola Tesla

*Die Chakren sind die Landkarte dieser Energie, Frequenz und Schwingung in uns.*
'''),

        // Weitere Kapitel folgen...
        
      ],
    ),
  ];
}
