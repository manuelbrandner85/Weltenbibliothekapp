import '../models/knowledge_entry.dart';

/// MATERIE WISSENSDATENBANK SERVICE
/// Bücher, Quellen, Methoden, Lexikon für MATERIE-Welt
class MaterieKnowledgeService {
  static final MaterieKnowledgeService _instance = MaterieKnowledgeService._internal();
  factory MaterieKnowledgeService() => _instance;
  MaterieKnowledgeService._internal();

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

  /// EMPFOHLENE EINTRÄGE (Top 5 nach Relevanz)
  List<KnowledgeEntry> getRecommended() {
    return _knowledgeDatabase.take(5).toList();
  }

  /// WISSENSDATENBANK
  static final List<KnowledgeEntry> _knowledgeDatabase = [
    // BÜCHER
    KnowledgeEntry(
      id: 'book_1',
      title: 'Manufacturing Consent',
      description: 'Noam Chomskys Standardwerk über Medienkontrolle und Propaganda',
      fullContent: '''
# Manufacturing Consent: The Political Economy of the Mass Media

**Autor:** Noam Chomsky & Edward S. Herman  
**Veröffentlicht:** 1988

## Kernthese

Die Massenmedien dienen als Propagandainstrument der Elite. Durch strukturelle Filter wird bestimmt, welche Nachrichten die Öffentlichkeit erreichen.

## Die 5 Filter

1. **Eigentumsverhältnisse** - Medien gehören Konzernen
2. **Werbeeinnahmen** - Abhängigkeit von Anzeigenkunden
3. **Quellenabhängigkeit** - Offizielle Quellen dominieren
4. **Flak** - Kritik wird unterdrückt
5. **Antikommunismus** - Ideologische Kontrollmechanismen

## Relevanz heute

Das Modell erklärt moderne Phänomene wie:
- Mainstream-Narrativ-Kontrolle
- Zensur in sozialen Medien
- Gleichschaltung der Berichterstattung
- Ausgrenzung alternativer Perspektiven

## Praktische Anwendung

- Hinterfrage ALLE Medienberichte
- Suche nach alternativen Quellen
- Analysiere, WER profitiert
- Erkenne Propaganda-Muster
''',
      type: KnowledgeType.book,
      category: KnowledgeCategory.alternativeMedia,
      tags: ['Medien', 'Propaganda', 'Chomsky', 'Analyse'],
      author: 'Noam Chomsky',
      publishedDate: DateTime(1988),
      difficulty: 4,
      readingTime: 20,
    ),
    
    KnowledgeEntry(
      id: 'book_2',
      title: 'Confessions of an Economic Hit Man',
      description: 'John Perkins enthüllt die wahren Mechanismen der Globalisierung',
      fullContent: '''
# Bekenntnisse eines Economic Hit Man

**Autor:** John Perkins  
**Veröffentlicht:** 2004

## Kernaussage

Perkins arbeitete als "Economic Hit Man" - seine Aufgabe war es, Entwicklungsländer in Schuldenfallen zu locken, um deren Ressourcen zu kontrollieren.

## Methoden

1. **Überhöhte Wachstumsprognosen** erstellen
2. **Massive Kredite** für Infrastruktur vergeben
3. **Korruption** von Entscheidungsträgern
4. **Schulden-Kontrolle** über Ressourcen

## Das System

- IWF & Weltbank als Instrumente
- Konzerne profitieren von Projekten
- Länder bleiben in Abhängigkeit
- Ressourcen fließen in den Westen

## Geopolitische Relevanz

Erklärt viele aktuelle Konflikte:
- Rohstoffkriege
- "Regime Change" Operationen
- Schuldenfallen in Afrika
- Neue Seidenstraße als Alternative

## Quellen-Validierung

Perkins war Insider - seine Aussagen sind durch Dokumente belegt und wurden nie widerlegt.
''',
      type: KnowledgeType.book,
      category: KnowledgeCategory.geopolitics,
      tags: ['Geopolitik', 'Wirtschaft', 'IWF', 'Imperialismus'],
      author: 'John Perkins',
      publishedDate: DateTime(2004),
      difficulty: 3,
      readingTime: 15,
    ),

    // METHODEN
    KnowledgeEntry(
      id: 'method_1',
      title: 'Quellenanalyse nach CRAAP-Test',
      description: 'Wissenschaftliche Methode zur Bewertung von Informationsquellen',
      fullContent: '''
# CRAAP-Test für Quellenanalyse

Eine systematische Methode zur Bewertung der Glaubwürdigkeit von Quellen.

## Die 5 Kriterien

### C - Currency (Aktualität)
- Wann wurde die Information veröffentlicht?
- Ist sie noch aktuell?
- Gibt es neuere Erkenntnisse?

### R - Relevance (Relevanz)
- Passt die Information zu meiner Frage?
- Ist das Niveau angemessen?
- Habe ich mehrere Quellen verglichen?

### A - Authority (Autorität)
- Wer ist der Autor?
- Welche Qualifikationen hat er?
- Gibt es Interessenkonflikte?

### A - Accuracy (Genauigkeit)
- Sind Behauptungen belegt?
- Gibt es Quellenangaben?
- Wurde die Info von anderen bestätigt?

### P - Purpose (Zweck)
- Was ist die Absicht der Quelle?
- Gibt es versteckte Agenda?
- Wer profitiert von dieser Info?

## Anwendung

1. Jedes Kriterium mit 1-5 bewerten
2. Summe bilden (max. 25 Punkte)
3. > 20: Hohe Glaubwürdigkeit
4. 15-19: Mittel, vorsichtig verwenden
5. < 15: Kritisch hinterfragen

## Praktisches Beispiel

**Quelle:** "Great Reset" Artikel

- Currency: ✅ 2023 (5 Punkte)
- Relevance: ✅ Direkt relevant (5 Punkte)
- Authority: ⚠️ WEF-Dokument (3 Punkte - Bias)
- Accuracy: ✅ Belegt mit Zitaten (4 Punkte)
- Purpose: ⚠️ Agenda erkennbar (3 Punkte)

**TOTAL: 20/25** - Verwertbar, aber Agenda beachten
''',
      type: KnowledgeType.method,
      category: KnowledgeCategory.research,
      tags: ['Analyse', 'Quellen', 'Methodik', 'Kritisches Denken'],
      difficulty: 2,
      readingTime: 10,
    ),

    // LEXIKON
    KnowledgeEntry(
      id: 'lexicon_1',
      title: 'Operation Mockingbird',
      description: 'CIA-Programm zur Infiltration der Medienlandschaft',
      fullContent: '''
# Operation Mockingbird

## Definition

Ein CIA-Programm zur Beeinflussung und Kontrolle von Medien, das in den 1950er Jahren begann.

## Historischer Kontext

- **Start:** 1950er Jahre
- **Leitung:** Frank Wisner (CIA)
- **Ziel:** Kontrolle des öffentlichen Narrativs

## Methoden

1. **Journalisten rekrutieren**
   - Bezahlung von Redakteuren
   - Platzierung von CIA-Agenten
   - Kooperation mit Verlagen

2. **Geschichten platzieren**
   - Propaganda als News tarnen
   - Dissidenten diskreditieren
   - Pro-US Narrativ fördern

3. **Internationale Reichweite**
   - Ausländische Medien infiltrieren
   - "Front"-Organisationen nutzen
   - Kulturelle Beeinflussung

## Aufdeckung

- **1975:** Church Committee Untersuchung
- **Beweise:** Interne CIA-Dokumente
- **Umfang:** Über 400 Journalisten involviert

## Moderne Relevanz

Parallelen zu heute:
- "Embedded Journalism"
- Geheimdienst-PR-Abteilungen
- Koordinierte Narrativ-Kampagnen
- Social Media Manipulation

## Quellen

- Church Committee Report (1975)
- Carl Bernstein: "The CIA and the Media" (1977)
- Freigegebene CIA-Dokumente

## Verschwörungstheorie?

**Status:** BESTÄTIGT durch offizielle Dokumente
**Beweis-Level:** ⭐⭐⭐⭐⭐ Wasserdicht
''',
      type: KnowledgeType.lexicon,
      category: KnowledgeCategory.conspiracy,
      tags: ['CIA', 'Medien', 'Propaganda', 'Geschichte'],
      difficulty: 3,
      readingTime: 8,
    ),

    KnowledgeEntry(
      id: 'lexicon_2',
      title: 'MK-Ultra',
      description: 'CIA Mind-Control Experimente (1950-1973)',
      fullContent: '''
# MK-Ultra: CIA Mind-Control Programm

## Überblick

Geheimes CIA-Programm zur Erforschung und Anwendung von Bewusstseinskontrolle.

## Zeitraum

- **Start:** 1953
- **Ende:** Offiziell 1973
- **Dauer:** 20 Jahre
- **Budget:** Millionen Dollar

## Methoden

### 1. LSD-Experimente
- Unfreiwillige Verabreichung
- Langzeit-Dosierung
- Verhaltensänderungen testen

### 2. Hypnose
- Tiefe Trance-Zustände
- Post-hypnotische Suggestionen
- Persönlichkeitsspaltung

### 3. Elektroschocks
- Gedächtnis löschen
- "Depatterning"
- Neu-Programmierung

### 4. Sensorische Deprivation
- Isolationskammern
- Wahrnehmungsmanipulation
- Psychische Folter

## Opfer

- Unwissende Zivilisten
- Gefängnisinsassen
- Psychiatrie-Patienten
- Prostituierte
- Eigene CIA-Mitarbeiter

## Aufdeckung

- **1974:** New York Times Enthüllung
- **1975:** Church Committee
- **1977:** FOIA-Freigabe von Dokumenten
- **Problem:** 90% der Akten wurden vernichtet

## Beweise

✅ Freigegebene CIA-Dokumente  
✅ Aussagen von Überlebenden  
✅ Wissenschaftliche Publikationen  
✅ Gerichtsurteile & Entschädigungen

## Moderne Relevanz

Nachfolge-Programme:
- BLUEBIRD
- ARTICHOKE
- MKNAOMI
- Moderne Neurotechnologie?

## Verschwörungstheorie?

**Status:** VOLLSTÄNDIG BESTÄTIGT  
**Beweis-Level:** ⭐⭐⭐⭐⭐ Offiziell dokumentiert  
**CIA-Statement:** Programm existierte, wurde beendet
''',
      type: KnowledgeType.lexicon,
      category: KnowledgeCategory.conspiracy,
      tags: ['CIA', 'Mind Control', 'Experimente', 'Geschichte'],
      difficulty: 4,
      readingTime: 12,
    ),

    // QUELLEN
    KnowledgeEntry(
      id: 'source_1',
      title: 'WikiLeaks Archive',
      description: 'Zentrale Quelle für Whistleblower-Dokumente',
      fullContent: '''
# WikiLeaks: Transparenz-Plattform

## Überblick

WikiLeaks veröffentlicht geheime Dokumente von Regierungen und Konzernen seit 2006.

## Wichtigste Veröffentlichungen

### 1. Collateral Murder (2010)
- US-Helikopter tötet Zivilisten im Irak
- Video-Beweis für Kriegsverbrechen
- Weltweite Empörung

### 2. Afghanistan War Logs (2010)
- 91.000 interne Militärberichte
- Zivile Opferzahlen verschwiegen
- Kriegsverbrechen dokumentiert

### 3. Iraq War Logs (2010)
- 400.000 Militärdokumente
- Systematische Folter
- 15.000 zusätzliche zivile Tote

### 4. Cablegate (2010)
- 251.000 diplomatische Depeschen
- Geheime Absprachen enthüllt
- Korruption dokumentiert

### 5. Vault 7 (2017)
- CIA Hacking-Tools
- Überwachungsprogramme
- Zero-Day Exploits

## Zugang

🔗 **Website:** wikileaks.org  
🔐 **Sicher:** Tor Hidden Service  
💾 **Archive:** Mehrfach gespiegelt

## Nutzung für Recherche

1. **Dokumenten-Suche** durchführen
2. **Original-Dateien** herunterladen
3. **Kontext** recherchieren
4. **Cross-Referenz** mit anderen Quellen

## Kontroverse

- Whistleblower-Schutz vs. Staatsgeheimnisse
- Julian Assange Verfolgung
- Politische Instrumentalisierung

## Glaubwürdigkeit

✅ **100% Veröffentlichungsquote** - Keine Fälschung nachgewiesen  
✅ **Original-Dokumente** mit Metadaten  
✅ **Mehrfach bestätigt** durch Regierungen  
✅ **Journalismus-Preise** weltweit
''',
      type: KnowledgeType.source,
      category: KnowledgeCategory.alternativeMedia,
      tags: ['Whistleblower', 'Dokumente', 'Transparenz', 'Assange'],
      difficulty: 2,
      readingTime: 10,
    ),
  ];
}
