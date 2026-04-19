import '../models/knowledge_entry.dart';

/// ENERGIE WISSENSDATENBANK SERVICE
/// Praktiken, Symbole, Rituale, Lexikon für ENERGIE-Welt
class EnergieKnowledgeService {
  static final EnergieKnowledgeService _instance = EnergieKnowledgeService._internal();
  factory EnergieKnowledgeService() => _instance;
  EnergieKnowledgeService._internal();

  /// ALLE EINTRÄGE ABRUFEN
  List<KnowledgeEntry> getAllEntries() {
    return _knowledgeDatabase;
  }

  /// NACH KATEGORIE FILTERN
  List<KnowledgeEntry> getByCategory(KnowledgeCategory category) {
    return _knowledgeDatabase.where((e) => e.category == category).toList();
  }

  /// NACH TYP FILTERN
  List<KnowledgeEntry> getByType(KnowledgeType type) {
    return _knowledgeDatabase.where((e) => e.type == type).toList();
  }

  /// SUCHE
  List<KnowledgeEntry> search(String query) {
    final lowerQuery = query.toLowerCase();
    return _knowledgeDatabase.where((e) {
      return e.title.toLowerCase().contains(lowerQuery) ||
             e.description.toLowerCase().contains(lowerQuery) ||
             e.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  /// EMPFOHLENE EINTRÄGE
  List<KnowledgeEntry> getRecommended() {
    return _knowledgeDatabase.take(5).toList();
  }

  /// WISSENSDATENBANK
  static final List<KnowledgeEntry> _knowledgeDatabase = [
    // PRAKTIKEN
    KnowledgeEntry(
      id: 'practice_1',
      title: 'Vipassana Meditation',
      description: 'Jahrtausendealte Technik zur Selbsterkenntnis durch Achtsamkeit',
      fullContent: '''
# Vipassana Meditation: Der Weg zur Einsicht

## Ursprung

- **Tradition:** Buddhismus (2500 Jahre alt)
- **Bedeutung:** "Dinge sehen, wie sie wirklich sind"
- **Lehrer:** S.N. Goenka (moderne Wiederbelebung)

## Kernprinzip

Durch systematische Beobachtung von Körperempfindungen entwickelt sich Gleichmut und Weisheit.

## Technik (10-Tages-Kurs)

### Tage 1-3: Anapana
- Fokus auf Atmung
- Beobachtung am Naseneingang
- Geist beruhigen und schärfen

### Tage 4-9: Vipassana
- Körper-Scan von Kopf bis Fuß
- Alle Empfindungen wahrnehmen
- Ohne Reaktion (Gleichmut)

### Tag 10: Metta
- Liebende Güte kultivieren
- Verdienste teilen
- Rückkehr in den Alltag

## Die 3 Weisheiten

1. **Anicca** - Vergänglichkeit
   Alles ist im ständigen Wandel

2. **Dukkha** - Leiden
   Anhaftung erzeugt Leid

3. **Anatta** - Nicht-Selbst
   Kein permanentes "Ich"

## Praktische Anleitung

**Tägliche Praxis (30-60 Min):**

1. Setze dich aufrecht hin
2. Schließe die Augen
3. Beobachte natürliche Atmung (5 Min)
4. Scanne Körperempfindungen:
   - Kopf → Gesicht → Nacken
   - Schultern → Arme → Hände
   - Brust → Bauch → Rücken
   - Hüfte → Beine → Füße
5. Nimm ALLES wahr ohne zu reagieren:
   - Kribbeln, Schmerz, Wärme, Kälte
   - Angenehm ↔ Unangenehm
6. Kultiviere Gleichmut: "Dies wird vergehen"

## Fortgeschrittene Technik

- **Stärkere Sammlung** durch längere Sitzungen
- **Subtile Empfindungen** wahrnehmen
- **Tiefes Verständnis** von Anicca entwickeln
- **Integration** in alle Lebensbereiche

## Herausforderungen

- Anfänglicher Schmerz beim Sitzen
- Rastloser Geist
- Ungeduld mit dem Prozess
- Alte Muster kommen hoch

## Nutzen

✅ Geistige Klarheit  
✅ Emotionale Balance  
✅ Tiefe Einsicht in die Natur der Realität  
✅ Befreiung von Leiden  
✅ Mitgefühl und Weisheit

## Wo lernen?

- 10-Tages-Kurse weltweit (kostenlos, Spendenbasis)
- Dhamma.org für Zentren
- Tägliche Praxis zu Hause
''',
      type: KnowledgeType.practice,
      category: KnowledgeCategory.meditation,
      tags: ['Meditation', 'Vipassana', 'Achtsamkeit', 'Buddhismus'],
      difficulty: 3,
      readingTime: 15,
    ),

    KnowledgeEntry(
      id: 'practice_2',
      title: 'Chakra-Aktivierung durch Klang',
      description: 'Jahrtausendealte Praxis mit Mantras und Frequenzen',
      fullContent: '''
# Chakra-Aktivierung durch Klang & Mantras

## Die 7 Hauptchakren

### 1. Wurzelchakra (Muladhara)
- **Frequenz:** 396 Hz
- **Mantra:** LAM
- **Ton:** C
- **Farbe:** Rot
- **Element:** Erde
- **Thema:** Sicherheit, Überleben, Erdung

### 2. Sakralchakra (Svadhisthana)
- **Frequenz:** 417 Hz
- **Mantra:** VAM
- **Ton:** D
- **Farbe:** Orange
- **Element:** Wasser
- **Thema:** Kreativität, Sexualität, Emotion

### 3. Solarplexus (Manipura)
- **Frequenz:** 528 Hz
- **Mantra:** RAM
- **Ton:** E
- **Farbe:** Gelb
- **Element:** Feuer
- **Thema:** Willenskraft, Selbstwert, Macht

### 4. Herzchakra (Anahata)
- **Frequenz:** 639 Hz
- **Mantra:** YAM
- **Ton:** F
- **Farbe:** Grün
- **Element:** Luft
- **Thema:** Liebe, Mitgefühl, Verbindung

### 5. Halschakra (Vishuddha)
- **Frequenz:** 741 Hz
- **Mantra:** HAM
- **Ton:** G
- **Farbe:** Blau
- **Element:** Äther
- **Thema:** Ausdruck, Wahrheit, Kommunikation

### 6. Stirnchakra (Ajna)
- **Frequenz:** 852 Hz
- **Mantra:** OM
- **Ton:** A
- **Farbe:** Indigo
- **Element:** Licht
- **Thema:** Intuition, Weisheit, Vision

### 7. Kronenchakra (Sahasrara)
- **Frequenz:** 963 Hz
- **Mantra:** AH
- **Ton:** H
- **Farbe:** Violett/Weiß
- **Element:** Bewusstsein
- **Thema:** Einheit, Erleuchtung, Spiritualität

## Praktische Übung

**20-Minuten Chakra-Ton-Meditation:**

1. **Vorbereitung** (2 Min)
   - Aufrecht sitzen
   - Tief atmen
   - Intention setzen

2. **Chakren durchgehen** (14 Min - je 2 Min)
   - Fokus auf Chakra-Position
   - Mantra singen/hören
   - Farbe visualisieren
   - Frequenz spüren

3. **Integration** (4 Min)
   - Stille
   - Energie fließen lassen
   - Dankbarkeit

## Solfeggio-Frequenzen

- **174 Hz** - Schmerzlinderung
- **285 Hz** - Geweberegeneration
- **396 Hz** - Befreiung von Angst
- **417 Hz** - Transformation
- **528 Hz** - DNA-Reparatur
- **639 Hz** - Harmonische Beziehungen
- **741 Hz** - Erwachen der Intuition
- **852 Hz** - Rückkehr zur spirituellen Ordnung
- **963 Hz** - Einheit mit dem Göttlichen

## Werkzeuge

✅ Klangschalen  
✅ Stimmgabeln  
✅ Mantra-Gesang  
✅ Binaurale Beats  
✅ Eigene Stimme

## Wissenschaft

Moderne Forschung zeigt:
- Frequenzen beeinflussen Zellschwingung
- Klang ändert Gehirnwellen
- Mantra-Wiederholung beruhigt Nervensystem
''',
      type: KnowledgeType.practice,
      category: KnowledgeCategory.chakra,
      tags: ['Chakra', 'Klang', 'Frequenzen', 'Mantras'],
      difficulty: 2,
      readingTime: 12,
    ),

    // SYMBOLE
    KnowledgeEntry(
      id: 'symbol_1',
      title: 'Blume des Lebens',
      description: 'Heilige Geometrie: Das universelle Schöpfungsmuster',
      fullContent: '''
# Blume des Lebens - Flower of Life

## Das Symbol

Ein Muster aus 19 überlappenden Kreisen, die zusammen eine blütenähnliche Form ergeben.

## Ursprung

- **Alter:** Über 6000 Jahre
- **Fundorte:** Weltweit
  - Ägypten: Tempel von Abydos
  - Israel: Synagogen
  - China: Verbotene Stadt
  - Türkei, Indien, Japan...

## Geometrische Struktur

### Aufbau
1. Ein zentraler Kreis
2. 6 Kreise darum (Saat des Lebens)
3. 12 weitere Kreise (Blume des Lebens)

### Enthaltene Formen
- Platonische Körper (alle 5)
- Vesica Piscis
- Baum des Lebens (Kabbala)
- Metatrons Würfel
- Goldener Schnitt

## Bedeutung

### Schöpfungsprinzip
Die Blume zeigt, wie aus Einheit (1 Kreis) Vielfalt (viele Kreise) entsteht.

### Universelles Muster
Findet sich in:
- Zellentwicklung (Embryo)
- Kristallstrukturen
- Atomaren Mustern
- Pflanzenwachstum
- Planetenbewegungen

## Spirituelle Bedeutung

1. **Einheit** - Alles ist verbunden
2. **Schöpfung** - Das Muster des Werdens
3. **Harmonie** - Perfekte Proportionen
4. **Ewigkeit** - Endlose Wiederholung

## Praktische Anwendung

### Meditation
- Fokus auf das Zentrum
- Folge den Kreisen mit den Augen
- Erkenne das Muster in dir

### Energetisierung
- Symbol auf Wasser legen
- Raumharmonisierung
- Schmuck tragen

### Aktivierung
- Zeichne das Symbol selbst
- Mandala-Meditation
- Visualisierung

## Verwandte Symbole

- **Saat des Lebens** (6 Kreise)
- **Frucht des Lebens** (13 Kreise)
- **Metatrons Würfel** (Verbindungslinien)
- **Sri Yantra** (Dreiecke)

## Wissenschaft & Mythos

**Wissenschaftlich:**
- Mathematisch perfekt
- Universelles Geometrieprinzip
- Basis für Platonische Körper

**Mythologisch:**
- Schöpfungscode
- Blaupause des Universums
- Zugang zu höheren Dimensionen

## Wie nutzen?

1. **Täglich meditieren** (5-10 Min)
2. **Im Raum platzieren** (Wandbild)
3. **Als Amulett tragen**
4. **Selbst zeichnen** (spirituelle Übung)
''',
      type: KnowledgeType.symbol,
      category: KnowledgeCategory.sacred,
      tags: ['Heilige Geometrie', 'Symbol', 'Blume des Lebens', 'Schöpfung'],
      difficulty: 2,
      readingTime: 10,
    ),

    // RITUALE
    KnowledgeEntry(
      id: 'ritual_1',
      title: 'Vollmond-Ritual: Loslassen',
      description: 'Kraftvolles Ritual zum Loslassen und Transformieren',
      fullContent: '''
# Vollmond-Ritual: Die Kunst des Loslassens

## Zeitpunkt

- **Optimal:** Exakte Vollmond-Zeit ±3 Stunden
- **Alternative:** Vollmond-Nacht
- **Häufigkeit:** Monatlich

## Vorbereitung

### Materialien
- Weißes Papier & Stift
- Feuersichere Schale
- Streichhölzer
- Räucherwerk (Salbei, Palo Santo)
- Wasser
- Optional: Kristalle (Selenit, Mondstein)

### Raum vorbereiten
1. Reinige den Raum (räuchern)
2. Kreiere heiligen Raum
3. Platziere Kristalle im Kreis
4. Stelle Wasser für Mondwasser bereit

## Das Ritual (45 Minuten)

### Phase 1: Einstimmung (10 Min)
1. **Setze dich unter dem Mondlicht**
   (Fenster oder draußen)

2. **Atme bewusst**
   - 4 Zählzeiten ein
   - 4 halten
   - 4 aus
   - 4 halten
   - 10 Runden

3. **Verbinde dich mit dem Mond**
   - Spüre seine Energie
   - Danke für seine Unterstützung
   - Öffne dich für Transformation

### Phase 2: Bewusstwerdung (15 Min)
1. **Schreibe auf, was du loslassen möchtest:**
   - Negative Gedankenmuster
   - Toxische Beziehungen
   - Alte Ängste
   - Limitierende Glaubenssätze
   - Vergangene Verletzungen

2. **Sei spezifisch:**
   "Ich lasse los: Die Angst vor... [konkret]"
   "Ich befreie mich von: Der Überzeugung, dass... [konkret]"

3. **Fühle jedes Thema:**
   - Erkenne, wie es dich belastet hat
   - Erkenne, dass es dir nicht mehr dient
   - Sei bereit, es zu transformieren

### Phase 3: Das Loslassen (15 Min)
1. **Lies laut vor, was du geschrieben hast**
   - Mit Intention
   - Mit Emotion
   - Mit Entschlossenheit

2. **Verbrenne das Papier**
   - "Ich übergebe dies dem Feuer"
   - "Möge es zu Licht transformiert werden"
   - "Ich bin frei"

3. **Beobachte die Asche**
   - Sehe, wie es sich auflöst
   - Fühle die Befreiung
   - Atme tief

4. **Wasche deine Hände**
   - Symbolisches Reinigen
   - Loslassen komplettieren

### Phase 4: Integration (5 Min)
1. **Trinke Mondwasser**
   - Mit Dankbarkeit
   - Nimm neue Energie auf

2. **Affirmation:**
   "Ich bin frei. Ich bin leicht. Ich bin offen für Neues."

3. **Schließe das Ritual:**
   - Danke dem Mond
   - Danke dir selbst
   - Öffne die Augen

## Nach dem Ritual

- **Entsorge die Asche** respektvoll (Erde/Wasser)
- **Trinke viel Wasser** (Reinigung)
- **Journaling** über Erkenntnisse
- **Sei sanft mit dir** in den nächsten Tagen

## Mondwasser herstellen

1. Glasflasche mit Wasser füllen
2. Unter Vollmond stellen (mind. 3h)
3. Mit Dankbarkeit trinken
4. Zum Gießen von Pflanzen nutzen

## Häufigkeit & Kontinuität

- **Monatlich** bei Vollmond
- **Verfolge Fortschritt** im Journal
- **Bemerke Muster**, die sich wiederholen
- **Feiere Durchbrüche**

## Wichtig

⚠️ Nur loslassen, was bereit ist zu gehen  
⚠️ Kein Zwang, keine Erwartung  
⚠️ Prozess kann mehrere Zyklen dauern  
⚠️ Sei geduldig und liebevoll mit dir
''',
      type: KnowledgeType.ritual,
      category: KnowledgeCategory.spirituality,
      tags: ['Vollmond', 'Ritual', 'Loslassen', 'Transformation'],
      difficulty: 1,
      readingTime: 12,
    ),

    // LEXIKON
    KnowledgeEntry(
      id: 'lexicon_1',
      title: 'Kundalini Energie',
      description: 'Die schlafende Schlangenkraft an der Basis der Wirbelsäule',
      fullContent: '''
# Kundalini: Die schlafende Schlangenkraft

## Definition

Kundalini ist die primordiale Lebensenergie, die am unteren Ende der Wirbelsäule ruht und durch spirituelle Praxis erweckt werden kann.

## Ursprung & Tradition

- **Sanskrit:** कुण्डलिनी (kuṇḍalinī) = "die Aufgerollte"
- **Tradition:** Tantra, Yoga, Hinduismus
- **Alter:** Über 3000 Jahre
- **Texte:** Upanishaden, Tantra-Schriften

## Symbolik

### Die Schlange
- **3½ Windungen** um Wirbelsäule
- Symbolisiert **schlafendes Potenzial**
- Männliche & weibliche Energie vereint

### Die Reise
- **Start:** Muladhara (Wurzelchakra)
- **Weg:** Sushumna Nadi (zentrale Energiebahn)
- **Ziel:** Sahasrara (Kronenchakra)

## Der Aufstieg durch die Chakren

### 1. Muladhara (Wurzel)
- Erweckung der Kundalini
- Lösung von Überlebensängsten

### 2. Svadhisthana (Sakral)
- Transformation sexueller Energie
- Kreative Kraft

### 3. Manipura (Solarplexus)
- Persönliche Macht
- Egoauflösung

### 4. Anahata (Herz)
- Öffnung des Herzens
- Bedingungslose Liebe

### 5. Vishuddha (Kehle)
- Höherer Ausdruck
- Wahrheit sprechen

### 6. Ajna (Stirn)
- Intuition aktivieren
- Hellsichtigkeit

### 7. Sahasrara (Krone)
- Erleuchtung
- Einheit mit dem Absoluten

## Symptome der Erweckung

### Körperlich
- Hitze an der Wirbelsäule
- Zittern, Kribbeln
- Unwillkürliche Bewegungen
- Energetische Wellen

### Emotional
- Intensive Emotionen
- Alte Trauma kommen hoch
- Tiefe Reinigungsprozesse

### Spirituell
- Erweiterte Wahrnehmung
- Mystische Erfahrungen
- Einheitsbewusstsein
- Tiefe Einsichten

## Sichere Erweckung

### Voraussetzungen
1. **Gereinigter Körper** (Yoga, gesunde Ernährung)
2. **Stabiler Geist** (Meditation)
3. **Ethisches Leben** (Yamas, Niyamas)
4. **Erfahrener Lehrer** (Guru)

### Praktiken
- **Kundalini Yoga** (Kriyas, Asanas)
- **Pranayama** (Atemtechniken)
- **Mantra-Wiederholung**
- **Meditation** (Fokus auf Chakren)

### Vorsichtsmaßnahmen
⚠️ **NICHT erzwingen**  
⚠️ **Respektiere den Prozess**  
⚠️ **Suche Anleitung**  
⚠️ **Gehe langsam vor**

## Gefahren spontaner Erweckung

- **Körperliche Überlastung**
- **Psychische Destabilisierung**
- **Energetische Blockaden**
- **Spirituelle Krise**

**Lösung:** Erdung, professionelle Hilfe, sanfte Integration

## Moderne Perspektive

### Wissenschaft
- Ähnlich zu Nervensystem-Aktivierung
- Neurotransmitter-Freisetzung
- Bewusstseinsveränderung messbar

### Psychologie
- C.G. Jung: Individuationsprozess
- Tiefenpsychologische Transformation
- Integration des Unbewussten

## Praktische Integration

Nach Erweckung:
- **Erdung** (Natur, körperliche Arbeit)
- **Stabilisierung** (Routine, Struktur)
- **Integration** (Erfahrungen verarbeiten)
- **Service** (Weisheit teilen)

## Weiterführende Praxis

- Kundalini Yoga nach Yogi Bhajan
- Tantra-Schulen
- Kriya Yoga
- Pranayama-Meisterung

## Ziel

Nicht die Erweckung selbst, sondern:
- **Vollständige Transformation**
- **Erleuchtung**
- **Dienst an der Menschheit**
''',
      type: KnowledgeType.lexicon,
      category: KnowledgeCategory.spirituality,
      tags: ['Kundalini', 'Energie', 'Chakren', 'Yoga'],
      difficulty: 4,
      readingTime: 15,
    ),
  ];
}
