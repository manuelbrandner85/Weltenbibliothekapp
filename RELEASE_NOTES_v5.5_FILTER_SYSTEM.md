# WELTENBIBLIOTHEK v5.5 – FILTER-SYSTEM

**Release-Datum**: 2026-01-04
**Version**: v5.5
**Status**: ✅ Production-Ready

---

## 🎯 KERNFEATURE: INTERAKTIVE DATENFILTERUNG

v5.5 führt ein **leistungsstarkes Filter-System** ein, mit dem Benutzer Recherche-Ergebnisse **dynamisch filtern** können:

### ✨ HAUPTFUNKTIONEN

1. **Quellen-Typ-Filter**
   - ✅ Filter nach Web-Quellen
   - ✅ Filter nach Dokumenten
   - ✅ Filter nach Medien
   - ✅ Filter nach Timeline-Events
   - ✅ Multi-Select mit FilterChips

2. **Detail-Tiefe-Filter**
   - ✅ Slider von 1 (Minimal) bis 5 (Vollständig)
   - ✅ 5 vordefinierte Levels:
     - **1 - Minimal**: Nur Kernfakten
     - **2 - Überblick**: Wichtigste Informationen
     - **3 - Standard**: Wesentliche Details
     - **4 - Detailliert**: Umfassende Informationen
     - **5 - Vollständig**: Alle verfügbaren Details

3. **Schnellfilter (Presets)**
   - 🎯 **Alle**: Alle Quellen, maximale Tiefe
   - 🌐 **Nur Web**: Nur Web-Quellen
   - 📚 **Nur Dokumente**: Nur Dokument-Quellen
   - 👁️ **Überblick**: Alle Quellen, Tiefe 2
   - 🔍 **Tiefe Analyse**: Alle Quellen, Tiefe 5

4. **Live-Filterung**
   - ⚡ Sofortige Anwendung bei Änderungen
   - 📊 Automatische Neuberechnung der Quellen-Counts
   - 🔄 Dynamische Anpassung der angezeigten Daten

---

## 🏗️ TECHNISCHE IMPLEMENTIERUNG

### Neue Komponenten

#### 1. **RechercheFilter** (Model)
```dart
class RechercheFilter {
  final Set<String> enabledSources;
  final int maxDepth;
  
  // Factory-Konstruktoren für Presets
  factory RechercheFilter.all();
  factory RechercheFilter.webOnly();
  factory RechercheFilter.documentsOnly();
  factory RechercheFilter.overview();
  factory RechercheFilter.deep();
  
  // Filter-Anwendung
  List<Map<String, dynamic>> apply(List items);
  List<Map<String, dynamic>> applyToTimeline(List events);
  Map<String, dynamic> applyToStructured(Map structured);
}
```

**Pfad**: `lib/utils/recherche_filter.dart`

#### 2. **Filter-UI-Panel**

```dart
Widget _buildFilterPanel() {
  // Quellen-Typ-Filter mit FilterChips
  // Detail-Tiefe-Slider
  // Schnellfilter-Buttons
  // Reset-Button
}
```

**Integration**: `lib/screens/recherche_screen_hybrid.dart`

#### 3. **State-Management**

```dart
class _RechercheScreenHybridState {
  RechercheFilter _filter = const RechercheFilter();
  bool _showFilters = false;
  Map<String, dynamic>? _rawData; // Ungefilterte Rohdaten
  
  void _applyFilters() {
    // Filter auf alle Daten-Strukturen anwenden
  }
  
  void _updateFormattedResult() {
    // Formatiertes Ergebnis mit Filter-Status aktualisieren
  }
}
```

---

## 🔧 FILTER-ALGORITHMUS

### 1. Daten-Struktur mit Metadaten
```dart
{
  'icon': Icons.language,
  'label': 'Web-Quellen',
  'count': 10,
  'type': 'web',      // 🆕 Für Quellen-Filter
  'depth': 3          // 🆕 Für Tiefe-Filter
}
```

### 2. Filter-Anwendung
```dart
List<Map<String, dynamic>> apply(List<Map<String, dynamic>> items) {
  return items.where((item) {
    // Quellen-Filter
    final type = item['type'] as String?;
    if (type != null && !enabledSources.contains(type.toLowerCase())) {
      return false;
    }
    
    // Tiefe-Filter
    final depth = item['depth'] as int? ?? 1;
    if (depth > maxDepth) {
      return false;
    }
    
    return true;
  }).toList();
}
```

### 3. Strukturierte Daten filtern
```dart
Map<String, dynamic> applyToStructured(Map<String, dynamic> structured) {
  // Faktenbasis durchfiltern
  // Sichtweisen behalten (immer anzeigen)
  // Verschachtelte Listen auf maxDepth begrenzen
}
```

---

## 🎨 UI/UX-VERBESSERUNGEN

### Filter-Button im AppBar
```dart
IconButton(
  icon: Badge(
    label: _filter.isActive ? Text('${_filter.activeCount}') : null,
    child: const Icon(Icons.filter_list),
  ),
  onPressed: () {
    setState(() { _showFilters = !_showFilters; });
  },
)
```

**Features**:
- ✅ Badge zeigt Anzahl aktiver Filter
- ✅ Nur sichtbar wenn `_status == RechercheStatus.done`
- ✅ Toggle-Verhalten für Filter-Panel

### Filter-Panel
```
┌─────────────────────────────────────┐
│ 🔽 Filter                  [Reset]  │
├─────────────────────────────────────┤
│ Quellen-Typen                       │
│ [🌐 Web] [📚 Dokumente]             │
│ [🎥 Medien] [📅 Timeline]           │
│                                     │
│ Detail-Tiefe                    [3] │
│ 1 ─────●─────────── 5               │
│ Standardumfang mit wesentl. Details │
│                                     │
│ Schnellfilter                       │
│ [∞ Alle] [🌐 Nur Web] [📚 Nur Dok]│
│ [👁️ Überblick] [🔍 Tiefe Analyse]  │
└─────────────────────────────────────┘
```

### Gefilterte Ergebnis-Anzeige
```
📊 RECHERCHE-ERGEBNIS: MK Ultra

🔍 AKTIVE FILTER: 2

📈 QUELLEN-STATUS (gefiltert):
  🌐 Web: 10
  📚 Dokumente: 0    ← Ausgefiltert
  🎥 Medien: 0       ← Ausgefiltert
  📅 Timeline: 5

─────────────────────────────────────
```

---

## 📊 FILTER-WIRKUNG

### Beispiel: Nur Web-Quellen (Tiefe 2)

**Vorher** (Ohne Filter):
- Web: 10
- Dokumente: 5
- Medien: 3
- Timeline: 15 Events
- Analyse: 2500 Wörter

**Nachher** (Mit Filter):
- Web: 10 ✅
- Dokumente: 0 ❌ (ausgefiltert)
- Medien: 0 ❌ (ausgefiltert)
- Timeline: 8 Events (wichtigste)
- Analyse: 800 Wörter (reduziert)

---

## 🔄 DATENFLUSS

```
Cloudflare Worker
    ↓
Standard/SSE-Modus
    ↓
_rawData speichern (ungefiltert)
    ↓
Filter anwenden
    ↓
_analyseData, _timeline, _intermediateResults (gefiltert)
    ↓
UI-Rendering mit gefilterten Daten
```

### Bei Filter-Änderung
```
Benutzer ändert Filter
    ↓
_applyFilters() aufrufen
    ↓
Filter auf _rawData anwenden
    ↓
Gefilterte Daten in State speichern
    ↓
_updateFormattedResult() aufrufen
    ↓
setState() → UI-Update
```

---

## 🧪 TESTING

### Test-Szenario 1: Quellen-Filter
1. Recherche starten (z.B. "MK Ultra")
2. Filter-Button öffnen
3. "Dokumente" deaktivieren
4. **Erwartung**: Dokument-Count wird 0, Timeline bleibt sichtbar

### Test-Szenario 2: Tiefe-Filter
1. Recherche starten
2. Filter auf Tiefe 2 setzen
3. **Erwartung**: Weniger Details in Analyse, kürzere Timeline

### Test-Szenario 3: Schnellfilter
1. Recherche starten
2. "Nur Web" Preset wählen
3. **Erwartung**: Nur Web-Quellen sichtbar, alle anderen 0

### Test-Szenario 4: Filter zurücksetzen
1. Mehrere Filter anwenden
2. "Zurücksetzen" klicken
3. **Erwartung**: Alle Daten wieder sichtbar

---

## 🚀 PERFORMANCE-OPTIMIERUNG

### Effiziente Filter-Anwendung
- ✅ Filter nur auf bereits geladene Daten
- ✅ Keine neuen API-Requests bei Filter-Änderung
- ✅ Verwendung von `where()` für O(n) Komplexität
- ✅ Vermeidung unnötiger State-Updates

### Memory-Management
- ✅ Rohdaten in `_rawData` speichern (nur 1x)
- ✅ Gefilterte Daten in separaten Variablen
- ✅ Keine Duplikation großer Datenmengen

---

## 📱 RESPONSIVE DESIGN

### Mobile
- ✅ Filter-Panel als Overlay/Card
- ✅ FilterChips in Wrap-Widget (automatischer Umbruch)
- ✅ Touch-optimierte Slider-Größe

### Tablet/Desktop
- ✅ Filter-Panel in Sidebar möglich
- ✅ Größere Interaktionsflächen
- ✅ Mehr sichtbare Schnellfilter

---

## 🔐 DATENINTEGRITÄT

### Unveränderlichkeit der Rohdaten
```dart
// Rohdaten bleiben unverändert
_rawData = Map<String, dynamic>.from(data);

// Filter-Anwendung erzeugt neue Listen/Maps
final filtered = _filter.apply(_intermediateResults);
```

### Reset-Funktionalität
```dart
TextButton(
  onPressed: () {
    setState(() {
      _filter = RechercheFilter.all();
      _applyFilters();
    });
  },
  child: const Text('Zurücksetzen'),
)
```

---

## 🎯 BENUTZER-SZENARIEN

### Szenario 1: Schneller Überblick
**Ziel**: Nur wichtigste Informationen anzeigen

**Workflow**:
1. Recherche starten
2. Schnellfilter "Überblick" wählen
3. **Ergebnis**: Tiefe 2, alle Quellen-Typen, kompakte Darstellung

### Szenario 2: Nur wissenschaftliche Quellen
**Ziel**: Nur Dokumente anzeigen (keine Web-Artikel oder Medien)

**Workflow**:
1. Recherche starten
2. Filter öffnen
3. Nur "Dokumente" aktivieren
4. **Ergebnis**: Fokus auf wissenschaftliche Papers, Archive

### Szenario 3: Tiefe Recherche mit allen Quellen
**Ziel**: Maximale Informationen

**Workflow**:
1. Recherche starten
2. Schnellfilter "Tiefe Analyse" wählen
3. **Ergebnis**: Tiefe 5, alle Quellen, vollständige Timeline

---

## 🔄 KOMPATIBILITÄT MIT BESTEHENDEN FEATURES

### v5.4 Strukturierte JSON-Extraktion
✅ Filter berücksichtigen `analyse.structured`:
```dart
Map<String, dynamic> applyToStructured(Map<String, dynamic> structured) {
  // Faktenbasis, Sichtweisen, Vergleich durchfiltern
}
```

### v5.3 Neutrale Perspektiven
✅ Sichtweisen bleiben immer erhalten (nicht filterbar):
```dart
// Sichtweisen durchfiltern
for (final key in ['sichtweise1_offiziell', 'sichtweise2_alternativ']) {
  filtered[key] = structured[key]; // Immer behalten
}
```

### v5.1 Timeline-Visualisierung
✅ Timeline-Events nach Wichtigkeit filtern:
```dart
List<Map<String, dynamic>> applyToTimeline(List events) {
  return events.where((event) {
    final depth = event['importance'] as int? ?? 1;
    return depth <= maxDepth;
  }).toList();
}
```

### v5.0 Hybrid-SSE
✅ Filter funktionieren in beiden Modi:
- **Standard-Modus**: Filter auf JSON-Response
- **SSE-Modus**: Filter auf finale SSE-Daten

---

## 📖 API-REFERENZ

### RechercheFilter-Klasse

**Konstruktor**:
```dart
const RechercheFilter({
  this.enabledSources = const {'web', 'documents', 'media', 'timeline'},
  this.maxDepth = 5,
})
```

**Factory-Methoden**:
- `RechercheFilter.all()` – Alle Quellen, Tiefe 5
- `RechercheFilter.webOnly()` – Nur Web, Tiefe 5
- `RechercheFilter.documentsOnly()` – Nur Dokumente, Tiefe 5
- `RechercheFilter.overview()` – Alle Quellen, Tiefe 2
- `RechercheFilter.deep()` – Alle Quellen, Tiefe 5

**Methoden**:
- `copyWith({Set<String>? enabledSources, int? maxDepth})` – Kopie mit Änderungen
- `bool get isActive` – Ist Filter aktiv? (von Standard abweichend)
- `int get activeCount` – Anzahl aktiver Filter
- `List<Map> apply(List items)` – Filter auf Liste anwenden
- `List<Map> applyToTimeline(List events)` – Filter auf Timeline anwenden
- `Map<String, dynamic> applyToStructured(Map structured)` – Filter auf strukturierte Daten anwenden

---

## 🔍 DEBUGGING

### Filter-Status prüfen
```dart
debugPrint('Filter aktiv: ${_filter.isActive}');
debugPrint('Aktive Filter: ${_filter.activeCount}');
debugPrint('Aktivierte Quellen: ${_filter.enabledSources}');
debugPrint('Max-Tiefe: ${_filter.maxDepth}');
```

### Datenfluss tracken
```dart
debugPrint('Rohdaten: ${_rawData?.keys}');
debugPrint('Gefilterte Intermediate: ${_intermediateResults.length}');
debugPrint('Gefilterte Timeline: ${_timeline.length}');
```

---

## 🎯 ZUSAMMENFASSUNG

### Was ist NEU in v5.5?
- ✅ **Quellen-Typ-Filter** (Web, Dokumente, Medien, Timeline)
- ✅ **Detail-Tiefe-Filter** (1-5 Levels)
- ✅ **5 Schnellfilter-Presets**
- ✅ **Live-Filterung** ohne neue API-Requests
- ✅ **Filter-Status-Badge** im AppBar
- ✅ **Interaktives Filter-Panel** mit Reset-Funktion
- ✅ **Responsive Design** für Mobile/Tablet/Desktop

### Vorteile für Benutzer
- 🎯 **Fokussierte Recherche**: Nur relevante Quellen anzeigen
- ⚡ **Schneller Überblick**: Detail-Tiefe reduzieren
- 🔍 **Tiefe Analyse**: Alle Details bei Bedarf
- 📊 **Transparenz**: Filter-Status klar sichtbar
- 🔄 **Flexibilität**: Schnelle Preset-Wechsel

### Technische Highlights
- ✅ **Saubere Architektur**: Filter als eigenes Model
- ✅ **Effiziente Implementierung**: O(n) Filter-Algorithmen
- ✅ **Datenintegrität**: Rohdaten bleiben unverändert
- ✅ **Kompatibilität**: Funktioniert mit allen v5.x Features
- ✅ **Erweiterbar**: Neue Filter-Typen einfach hinzufügbar

---

## 🔗 DEPLOYMENT

**Live-URL**: https://5060-i6i6g94lpb9am6y5rb4gp-0e616f0a.sandbox.novita.ai
**Worker-API**: https://weltenbibliothek-worker.brandy13062.workers.dev
**Version**: v5.5
**Status**: ✅ Production-Ready

---

## 📚 VERWANDTE DOKUMENTATION

- v5.4: Strukturierte JSON-Extraktion (`RELEASE_NOTES_v5.4_STRUCTURED_JSON.md`)
- v5.4 UI: Perspektiven-Card (`RELEASE_NOTES_v5.4_UI_PERSPEKTIVEN.md`)
- v5.3: Neutrale Perspektiven (`RELEASE_NOTES_v5.3_NEUTRAL.md`)
- v5.2: Fakten-Trennung (`RELEASE_NOTES_v5.2_FAKTEN_TRENNUNG.md`)
- v5.1: Timeline-Integration (`RELEASE_NOTES_v5.1_TIMELINE.md`)
- v5.0: Hybrid-SSE-System (`RELEASE_NOTES_v5.0_HYBRID.md`)

---

**🎉 WELTENBIBLIOTHEK v5.5 – Intelligente Filter für fokussierte Recherche!**
