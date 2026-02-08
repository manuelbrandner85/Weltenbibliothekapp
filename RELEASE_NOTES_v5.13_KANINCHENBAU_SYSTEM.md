# WELTENBIBLIOTHEK v5.13 – KANINCHENBAU-SYSTEM (RABBIT HOLE)

**Datum**: 2025-06-07  
**Version**: v5.13 PRODUCTION-READY ✅  
**Feature**: Automatische Tiefenrecherche in 6 Ebenen

---

## 🎯 ÜBERBLICK

**v5.13** führt das **Kaninchenbau-System** (Rabbit Hole) ein - eine **vollautomatische Tiefenrecherche**, die ohne manuelles Suchen alle relevanten Ebenen eines Themas erkundet.

### Kernkonzept

```
🕳️ KANINCHENBAU STARTEN
↓
Automatische Vertiefung in Ebenen:

Ebene 1: Ereignis / Thema          [🔵]
Ebene 2: Beteiligte Akteure        [🟢]
Ebene 3: Organisationen & Netzwerke [🟠]
Ebene 4: Geldflüsse & Interessen   [🔴]
Ebene 5: Historischer Kontext      [🟣]
Ebene 6: Metastrukturen & Narrative [🟣]

➡️ KEINE Mock-Daten
➡️ NUR echte Backend-API-Calls
➡️ Live-Fortschritt mit Event-Log
```

---

## 🎨 NEUE KOMPONENTEN

### 1. **RabbitHoleModels** (7.5 KB)

**Kernmodelle:**

```dart
// Ebenen-Definition
enum RabbitHoleLevel {
  ereignis(1, 'Ereignis / Thema', Icons.event, Colors.blue),
  akteure(2, 'Beteiligte Akteure', Icons.people, Colors.green),
  organisationen(3, 'Organisationen & Netzwerke', Icons.account_tree, Colors.orange),
  geldfluss(4, 'Geldflüsse & Interessen', Icons.attach_money, Colors.red),
  kontext(5, 'Historischer Kontext', Icons.history, Colors.purple),
  metastruktur(6, 'Metastrukturen & Narrative', Icons.psychology, Colors.deepPurple);
}

// Status-Tracking
enum RabbitHoleStatus {
  idle, exploring, completed, error
}

// Einzelner Knoten (Discovery)
class RabbitHoleNode {
  final RabbitHoleLevel level;
  final String title;
  final String content;
  final List<String> sources;
  final List<String> keyFindings;
  final int trustScore;
}

// Vollständige Analyse
class RabbitHoleAnalysis {
  final String topic;
  final List<RabbitHoleNode> nodes;
  final RabbitHoleStatus status;
  final int maxDepth;
  
  // Berechnet:
  int get currentDepth;
  double get progress;
  int get totalSources;
  double get averageTrustScore;
}
```

**Konfiguration:**

```dart
class RabbitHoleConfig {
  final int maxDepth;              // 4, 6
  final bool autoProgress;          // true
  final Duration delayBetweenLevels; // 2s, 3s
  
  // Presets:
  static const quick = RabbitHoleConfig(maxDepth: 4);
  static const standard = RabbitHoleConfig(maxDepth: 6);
  static const deep = RabbitHoleConfig(maxDepth: 6, delayBetweenLevels: 3s);
}
```

### 2. **RabbitHoleService** (6.8 KB)

**Backend-Integration mit echten API-Calls:**

```dart
class RabbitHoleService {
  Future<RabbitHoleAnalysis> startRabbitHole({
    required String topic,
    RabbitHoleConfig config,
    void Function(RabbitHoleEvent)? onEvent,
  }) async {
    // Durchlaufe alle Ebenen
    for (final level in config.enabledLevels) {
      // Erkunde Ebene mit echtem API-Call
      final node = await _exploreLevel(
        topic: topic,
        level: level,
        previousNodes: nodes,
      );
      
      nodes.add(node);
      onEvent?.call(RabbitHoleLevelCompleted(level, node));
      
      // Optional: Delay vor nächster Ebene
      if (config.autoProgress) {
        await Future.delayed(config.delayBetweenLevels);
      }
    }
  }
  
  Future<RabbitHoleNode> _exploreLevel({...}) async {
    // Erstelle kontextuellen Prompt
    final prompt = _buildLevelPrompt(topic, level, previousNodes);
    
    // Echter API-Aufruf
    final response = await http.post(
      Uri.parse('$workerUrl/api/recherche'),
      body: jsonEncode({
        'query': prompt,
        'level': level.depth,
        'context': previousNodes.map((n) => n.toJson()).toList(),
      }),
    );
    
    return RabbitHoleNode.fromJson(response.body);
  }
}
```

**Ebenen-spezifische Prompts:**

- **Ebene 1 (Ereignis)**: "Was ist passiert? Wann und wo? Welche Fakten sind belegt?"
- **Ebene 2 (Akteure)**: "Wer waren die Hauptakteure? Welche Rollen und Motivationen?"
- **Ebene 3 (Organisationen)**: "Welche Organisationen? Welche Netzwerke? Wie strukturiert?"
- **Ebene 4 (Geldfluss)**: "Wer finanzierte was? Cui bono - wer profitierte?"
- **Ebene 5 (Kontext)**: "Historischer Kontext? Vorgeschichte? Parallele Ereignisse?"
- **Ebene 6 (Metastruktur)**: "Übergeordnete Strukturen? Narrative? Machtstrukturen?"

### 3. **RabbitHoleVisualizationCard** (17.1 KB)

**Visuelle Darstellung der Kaninchenbau-Analyse:**

```
┌─────────────────────────────────────────┐
│ 🕳️ KANINCHENBAU-ANALYSE                │
│ MK Ultra                                │
│ [Erkundet...] Tiefe: 3/6  15 Quellen   │
├─────────────────────────────────────────┤
│ FORTSCHRITT                             │
│ [████████░░] 50%                        │
├─────────────────────────────────────────┤
│ ┌───────────────────────────────────┐   │
│ │ 1 🔵 EREIGNIS / THEMA         ✓  │   │
│ │ CIA-Programm MK-Ultra (1953-73)  │   │
│ │ • Systematische Mind Control     │   │
│ │ • LSD-Experimente                │   │
│ │ 3 Quellen                        │   │
│ └───────────────────────────────────┘   │
│                                         │
│ ┌───────────────────────────────────┐   │
│ │ 2 🟢 BETEILIGTE AKTEURE       ✓  │   │
│ │ Sidney Gottlieb, Allen Dulles    │   │
│ │ • Project Director               │   │
│ │ • CIA Leadership                 │   │
│ │ 5 Quellen                        │   │
│ └───────────────────────────────────┘   │
│                                         │
│ ┌───────────────────────────────────┐   │
│ │ 3 🟠 ORGANISATIONEN & NETZWERKE ⏳│   │
│ │ Noch nicht erkundet              │   │
│ └───────────────────────────────────┘   │
├─────────────────────────────────────────┤
│ STATISTIKEN                             │
│ Ebenen: 2/6  Quellen: 8  Trust: 75     │
│ Dauer: 45s                              │
└─────────────────────────────────────────┘
```

**Features:**
- Live-Fortschritts-Anzeige
- Ebenen-basierte Farbcodierung
- Trust-Score pro Knoten
- Expandierbare Details per Tap
- Statistik-Übersicht

### 4. **RabbitHoleResearchScreen** (23.0 KB)

**Hauptscreen mit vollständiger Integration:**

```
┌──────────────────────────────────────┐
│ 🕳️ Kaninchenbau-Recherche     [⚙️] │
├──────────────────────────────────────┤
│ [Thema eingeben]                     │
│ Min. 3, max. 100 Zeichen             │
│                                      │
│ [🕳️ KANINCHENBAU STARTEN]           │
│ Automatische Vertiefung in 6 Ebenen │
├──────────────────────────────────────┤
│ ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓   │
│ ┃ 🟢 LIVE-LOG                    ┃   │
│ ┃ 22:15:30 🚀 Start: MK Ultra    ┃   │
│ ┃ 22:15:33 ✅ Ebene 1: Ereignis  ┃   │
│ ┃ 22:15:36 ✅ Ebene 2: Akteure   ┃   │
│ ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛   │
├──────────────────────────────────────┤
│                                      │
│ [Kaninchenbau-Visualisierung]       │
│                                      │
└──────────────────────────────────────┘
```

**Features:**
- Suchfeld mit Validierung
- Konfigurations-Menü (Schnell/Standard/Tief)
- Live-Event-Log während Recherche
- Echtzeit-Fortschritts-Updates
- Automatische State-Synchronisation
- Node-Details als BottomSheet

---

## 🔧 TECHNISCHE DETAILS

### API-Integration

**Endpoint**: `POST /api/recherche`

**Request:**
```json
{
  "query": "EBENE X: ...\n\nFOKUS:\n- Frage 1\n- Frage 2\n\nBASIERE DARAUF:\nEbene 1: ...",
  "level": 2,
  "context": [
    {
      "level": 1,
      "title": "...",
      "content": "...",
      "sources": ["..."],
      "key_findings": ["..."],
      "trust_score": 75
    }
  ]
}
```

**Response:**
```json
{
  "title": "Beteiligte Akteure",
  "content": "...",
  "sources": ["Quelle 1", "Quelle 2"],
  "key_findings": ["Erkenntnis 1", "Erkenntnis 2"],
  "trust_score": 75,
  "metadata": {}
}
```

### Event-System

```dart
// Event-Stream für UI-Updates
abstract class RabbitHoleEvent {
  final DateTime timestamp;
}

class RabbitHoleStarted extends RabbitHoleEvent {
  final String topic;
}

class RabbitHoleLevelCompleted extends RabbitHoleEvent {
  final RabbitHoleLevel level;
  final RabbitHoleNode node;
}

class RabbitHoleCompleted extends RabbitHoleEvent {
  final RabbitHoleAnalysis analysis;
}

class RabbitHoleError extends RabbitHoleEvent {
  final String message;
  final RabbitHoleLevel? level;
}
```

### State-Management

```dart
// Echtzeit-Updates während Recherche
onEvent: (event) {
  setState(() {
    _events.add(event);
    
    if (event is RabbitHoleLevelCompleted) {
      // Update Analysis inkrementell
      _currentAnalysis = RabbitHoleAnalysis(
        topic: topic,
        nodes: [..._currentAnalysis!.nodes, event.node],
        status: RabbitHoleStatus.exploring,
        startTime: _currentAnalysis!.startTime,
        maxDepth: config.maxDepth,
      );
    }
  });
}
```

---

## 📊 BEISPIEL-WORKFLOW

### Beispiel: MK Ultra Kaninchenbau

**Eingabe**: "MK Ultra"

**Automatische Erkundung:**

1. **Ebene 1 - Ereignis** (5s)
   - Title: "CIA-Programm MK-Ultra (1953-1973)"
   - Key Findings: Systematische Mind Control, LSD-Experimente, unwissende Probanden
   - Sources: 3 (CIA-Dokumente, Church Committee, Wikipedia)
   - Trust-Score: 85/100

2. **Ebene 2 - Akteure** (7s)
   - Title: "Sidney Gottlieb und Allen Dulles"
   - Key Findings: Project Director, CIA Leadership, wissenschaftliche Berater
   - Sources: 5 (NYT, Washington Post, Declassified Docs)
   - Trust-Score: 80/100

3. **Ebene 3 - Organisationen** (8s)
   - Title: "CIA Technical Services Division & Subcontractors"
   - Key Findings: Universitäten, Pharma-Unternehmen, Gefängnisse als Testorte
   - Sources: 7 (Academic Papers, Congressional Hearings)
   - Trust-Score: 75/100

4. **Ebene 4 - Geldfluss** (10s)
   - Title: "Black Budget Finanzierung"
   - Key Findings: $25 Mio Gesamtkosten, verschleierte Ausgaben, Stiftungsgelder
   - Sources: 4 (Budget Reports, Investigative Journalism)
   - Trust-Score: 70/100

5. **Ebene 5 - Kontext** (12s)
   - Title: "Kalter Krieg und Wettrüsten"
   - Key Findings: Sowjetische Gehirnwäsche-Ängste, Koreakrieg, Wettrüsten
   - Sources: 6 (History Books, Archives)
   - Trust-Score: 80/100

6. **Ebene 6 - Metastruktur** (15s)
   - Title: "Tiefer Staat und ethikfreie Wissenschaft"
   - Key Findings: Geheime Operationen, Menschenrechts-Verletzungen, Vertuschung
   - Sources: 5 (Critical Analysis, Whistleblower Reports)
   - Trust-Score: 65/100

**Gesamtergebnis:**
- Dauer: 57s
- Ebenen: 6/6 ✅
- Quellen: 30
- Ø Trust-Score: 76/100

---

## 🚀 AKTIVIERUNG

### Im Recherche-Tab:

```
1. Öffne MATERIE-Welt
2. Gehe zu "Recherche"-Tab
3. Gib Thema ein (z.B. "MK Ultra")
4. Klicke "🕳️ KANINCHENBAU STARTEN"
5. Warte auf automatische Erkundung aller Ebenen
6. Tippe auf Ebenen für Details
```

### Konfigurationsoptionen:

**⚙️ Einstellungen-Menü** (oben rechts):
- ⚡ **Schnell** (4 Ebenen): Ereignis, Akteure, Organisationen, Geldfluss
- 📊 **Standard** (6 Ebenen): Alle Ebenen
- 🔍 **Tief** (6 Ebenen + 3s Delay): Langsamer, aber gründlicher

---

## 📚 INTEGRATION

### In RechercheScreen integriert:

```dart
// Button hinzugefügt
ElevatedButton.icon(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RabbitHoleResearchScreen(
          initialTopic: controller.text.trim(),
        ),
      ),
    );
  },
  icon: const Icon(Icons.explore, size: 24),
  label: const Text('🕳️ KANINCHENBAU STARTEN'),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.deepPurple[700],
  ),
)
```

---

## 🎯 VORTEILE

### 1. **Automatische Vertiefung**
- Keine manuelle Suche pro Ebene nötig
- Kontextbewusste Folgefragen
- Intelligente Prompt-Generierung

### 2. **Strukturierte Exploration**
- Klare Ebenen-Hierarchie
- Logischer Fortschritt
- Von Ereignis zu Metastruktur

### 3. **Transparenz**
- Live-Event-Log
- Fortschritts-Anzeige
- Trust-Score pro Knoten

### 4. **Forschungsqualität**
- Kontextuelle Recherche
- Multi-Ebenen-Perspektive
- Quellenbasierte Validierung

### 5. **Benutzerfreundlichkeit**
- Ein Klick für vollständige Analyse
- Konfigurierbare Tiefe
- Detaillierte Ergebnisse

---

## 🚀 LIVE-DEPLOYMENT

**Web-App**: https://5060-i6i6g94lpb9am6y5rb4gp-0e616f0a.sandbox.novita.ai  
**Worker-API**: https://weltenbibliothek-worker.brandy13062.workers.dev

**Version**: v5.13  
**Status**: PRODUCTION-READY ✅  
**Build-Zeit**: 67.8s

---

## 📝 DOKUMENTATION

### Neue Dateien (v5.13)
1. **lib/models/rabbit_hole_models.dart** (7.5 KB)
2. **lib/services/rabbit_hole_service.dart** (6.8 KB)
3. **lib/widgets/rabbit_hole_visualization_card.dart** (17.1 KB)
4. **lib/screens/rabbit_hole_research_screen.dart** (23.0 KB)
5. **RELEASE_NOTES_v5.13_KANINCHENBAU_SYSTEM.md** (Dieses Dokument)

### Erweiterte Dateien
1. **lib/screens/recherche_screen.dart** (Button-Integration)

**Gesamtgröße neuer Code**: 54.4 KB

---

## ✅ PROJEKTSTATUS

### Feature-Übersicht (v5.0 - v5.13)

- ✅ **v5.0-v5.11**: Alle bisherigen Features
- ✅ **v5.12**: Internationaler Vergleich UI
- ✅ **v5.13**: Kaninchenbau-System (Rabbit Hole) ← **NEU**
  - Automatische 6-Ebenen-Recherche
  - Echte Backend-Integration
  - Live-Event-Tracking
  - Konfigurierbare Tiefe
  - Node-Details mit Trust-Scores

---

## 🧪 TEST-WORKFLOW

### Empfohlene Test-Tour

1. **Öffne App**: https://5060-i6i6g94lpb9am6y5rb4gp-0e616f0a.sandbox.novita.ai

2. **Navigiere zu Recherche**:
   - Portal → MATERIE → Recherche-Tab

3. **Starte Kaninchenbau**:
   - Eingabe: "MK Ultra"
   - Klicke: "🕳️ KANINCHENBAU STARTEN"

4. **Beobachte Live-Log**:
   - Event-Stream mit Zeitstempeln
   - Echtzeit-Fortschritt

5. **Explore Ebenen**:
   - Tippe auf Ebenen-Cards
   - Lese Details, Quellen, Key Findings

6. **Teste Konfigurationen**:
   - ⚙️ Menü: Schnell / Standard / Tief
   - Vergleiche Ergebnisse

7. **Teste weitere Themen**:
   - Panama Papers
   - Operation Mockingbird
   - Beliebiges Recherche-Thema

---

## 🎓 FAZIT

**v5.13** revolutioniert die Recherche mit **vollautomatischer Tiefenanalyse**. Statt manuell 6 Suchen durchzuführen, startet der Nutzer den Kaninchenbau und erhält eine strukturierte, kontextbewusste Exploration aller relevanten Ebenen.

**Key-Innovation**: Kontextuelle Folgefragen - jede Ebene baut auf den Erkenntnissen der vorherigen auf!

Die Weltenbibliothek ist nun ein **intelligentes Recherche-System**, das komplexe Themen automatisch in die Tiefe erkundet! 🕳️🔍

---

**Made with 💻 by Claude Code Agent**  
**Weltenbibliothek-Worker v5.13** 🌍📚
