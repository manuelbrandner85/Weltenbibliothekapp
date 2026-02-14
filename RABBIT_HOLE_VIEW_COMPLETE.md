# 🐰🕳️ RABBIT HOLE VIEW WIDGET - COMPLETE

## ✅ Implementierungsstatus: ABGESCHLOSSEN

**Widget erstellt:** lib/widgets/recherche/rabbit_hole_view.dart (17.874 Bytes)  
**Test-Screen:** lib/screens/rabbit_hole_view_test_screen.dart (15.912 Bytes)  
**Test-Route:** `/rabbit_hole_view_test`

**Code-Qualität:**
- ✅ `flutter analyze`: 0 Fehler, 0 Warnungen
- ✅ Material 3 Design
- ✅ Theme-aware
- ✅ Vollständig dokumentiert
- ✅ Alle Features getestet

---

## 📦 Widget-Features

### 1. Overall Depth Indicator
- **Gesamttiefe-Anzeige** mit Gradient-Container
- **Progress Bar** (0-100%)
- **Max Depth Badge** mit Prozent-Anzeige
- **Layer Count** Information
- **Primary Color** Theme-aware Design

### 2. Layer Navigation (bei >1 Layer)
- **Previous/Next Buttons** mit Icon-Pfeilen
- **Current Layer Info** mit Nummer und Namen
- **Disabled State** für Endpunkte
- **Grey Background** Container
- **Tooltip Support** für Buttons

### 3. Layer Cards
- **Ebenen-Nummer Badge** (Circle mit Depth-Color)
- **Layer Name** als Titel
- **Depth Badge** mit Prozent (0-100%)
- **Depth Progress Bar** (Layer-spezifisch)
- **Gradient Header** mit Depth-Color
- **Border** in Depth-Color
- **Expand/Collapse** per Tap

### 4. Depth Color-Coding
- **0-30% (Grün):** Oberflächlich - leicht zugängliche Informationen
- **30-60% (Orange):** Mittel - tiefere Analyse erforderlich
- **60-100% (Rot):** Tief - fundamentale Strukturen, hochgradig interpretativ

### 5. Expandierte Layer-Details
- **Description** (immer sichtbar, gekürzt wenn collapsed)
- **Sources** als ActionChips mit Depth-Color
  - Titel (max 25 Zeichen)
  - Article Icon
  - onSourceTap Callback
- **Connections** als Pfeil-Liste
  - Arrow Icon in Depth-Color
  - Text-Beschreibung

### 6. Empty State
- **Landscape Icon** (64px)
- **Titel:** "Kein Rabbit Hole verfügbar"
- **Beschreibung:** Erklärungstext
- **Centered Layout**

---

## 🎨 Design-Details

### Overall Depth Indicator
```dart
Container(
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [primaryColor.withOpacity(0.1), primaryColor.withOpacity(0.05)],
    ),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: primaryColor.withOpacity(0.3)),
  ),
  child: Column(
    children: [
      Row(
        children: [
          Icon(Icons.psychology, color: primaryColor),
          Text('🐰 Rabbit Hole Tiefe'),
          Spacer(),
          Badge('95%'), // Max depth
        ],
      ),
      LinearProgressIndicator(value: maxDepth), // 0-1
      Text('4 Ebene(n) erkundet'),
    ],
  ),
)
```

### Layer Navigation
```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  decoration: BoxDecoration(
    color: grey[100],
    borderRadius: BorderRadius.circular(12),
  ),
  child: Row(
    children: [
      IconButton(Icons.arrow_back_ios), // Previous
      Expanded(
        child: Column(
          children: [
            Text('Ebene 2 von 4'),
            Text(layerName, style: small),
          ],
        ),
      ),
      IconButton(Icons.arrow_forward_ios), // Next
    ],
  ),
)
```

### Layer Card Header
```dart
Container(
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [depthColor.withOpacity(0.2), depthColor.withOpacity(0.05)],
    ),
    borderRadius: BorderRadius.only(topLeft: ..., topRight: ...),
  ),
  child: Column(
    children: [
      Row(
        children: [
          // Layer Number Badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: depthColor,
              shape: circle,
            ),
            child: Text('2', color: white),
          ),
          SizedBox(width: 12),
          Expanded(Text(layerName, fontWeight: bold)),
          // Depth Badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: depthColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('45%', color: white),
          ),
        ],
      ),
      SizedBox(height: 12),
      // Depth Progress Bar
      LinearProgressIndicator(
        value: layer.depth, // 0-1
        backgroundColor: white.withOpacity(0.5),
        valueColor: AlwaysStoppedAnimation(depthColor),
      ),
    ],
  ),
)
```

### Layer Card Body
```dart
Padding(
  padding: EdgeInsets.all(16),
  child: Column(
    children: [
      // Description (gekürzt wenn collapsed)
      Text(
        layer.description,
        maxLines: isExpanded ? null : 2,
        overflow: isExpanded ? null : TextOverflow.ellipsis,
      ),
      
      if (isExpanded) ...[
        Divider(),
        
        // Sources
        Row([Icon(Icons.link), Text('Quellen (4):')]),
        Wrap(
          children: sources.map((source) =>
            ActionChip(
              label: Text(source.title.truncate(25)),
              avatar: Icon(Icons.article, color: depthColor),
              onPressed: () => onSourceTap(source.url),
              backgroundColor: depthColor.withOpacity(0.1),
            ),
          ),
        ),
        
        // Connections
        Row([Icon(Icons.hub), Text('Verbindungen (3):')]),
        ...connections.map((conn) =>
          Row([
            Icon(Icons.arrow_right, color: depthColor),
            Text(conn),
          ]),
        ),
      ],
      
      // Expand/Collapse Icon
      Icon(isExpanded ? expand_less : expand_more),
    ],
  ),
)
```

### Depth Color Logic
```dart
Color _getDepthColor(double depth) {
  if (depth < 0.3) return Colors.green;      // Oberflächlich
  else if (depth < 0.6) return Colors.orange; // Mittel
  else return Colors.red;                     // Tief
}
```

---

## 🧪 Test-Szenarien

### 1. Multi-Layer (4 Ebenen)
**Realistische Conspiracy-Research Simulation:**

**Ebene 1: Oberflächenanalyse (20% Tiefe - Grün)**
- Wikipedia, BBC News, Government Statements
- 3 Sources, 3 Connections
- Offizielle Narrative und allgemein akzeptierte Fakten

**Ebene 2: Versteckte Verbindungen (45% Tiefe - Orange)**
- Follow The Money, Investigative Journalism, Leaked Documents
- 4 Sources, 4 Connections
- Finanzielle Verflechtungen, Think Tanks, Lobbyisten

**Ebene 3: Systemische Muster (70% Tiefe - Rot)**
- Systems Theory, Historical Patterns, Power Structures
- 5 Sources, 5 Connections
- Elite-Netzwerke, wiederkehrende Muster, Langzeitstrategien

**Ebene 4: Fundamentale Strukturen (95% Tiefe - Rot)**
- Deep Politics, Shadow Government, Occult Symbolism
- 6 Sources, 7 Connections
- Geheime Gesellschaften, NWO-Agenda, hochgradig interpretativ

### 2. Single Layer (1 Ebene)
- **Oberflächenanalyse** (25% Tiefe - Grün)
- 2 Sources, 2 Connections
- Keine Navigation

### 3. Empty State
- **Landscape Icon** + Text
- "Kein Rabbit Hole verfügbar"

---

## 📝 Verwendung im Projekt

### Integration in RechercheScreen
```dart
import 'package:flutter/material.dart';
import '../widgets/recherche/rabbit_hole_view.dart';
import '../models/recherche_view_state.dart';
import 'package:url_launcher/url_launcher.dart';

// In RechercheScreen State:
Widget build(BuildContext context) {
  return Scaffold(
    body: SingleChildScrollView(
      child: Column(
        children: [
          // ... andere Widgets
          
          // Rabbit Hole Section (nur bei Deep/Conspiracy Mode)
          if (_rechercheResult?.rabbitLayers.isNotEmpty ?? false) ...[
            SectionHeader(
              title: '🐰🕳️ Rabbit Hole Analyse',
              subtitle: '${_rechercheResult!.rabbitLayers.length} Ebene(n)',
            ),
            SizedBox(height: 12),
            RabbitHoleView(
              layers: _rechercheResult!.rabbitLayers,
              onSourceTap: (url) async {
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('URL kann nicht geöffnet werden')),
                  );
                }
              },
            ),
          ],
        ],
      ),
    ),
  );
}
```

### Mit RechercheController
```dart
Consumer<RechercheController>(
  builder: (context, controller, child) {
    final result = controller.state.result;
    
    // Zeige Rabbit Hole nur bei Deep/Conspiracy Modes
    if (result == null || 
        result.mode == RechercheMode.simple || 
        result.mode == RechercheMode.advanced) {
      return SizedBox.shrink();
    }
    
    if (result.rabbitLayers.isEmpty) {
      return EmptyState();
    }
    
    return RabbitHoleView(
      layers: result.rabbitLayers,
      onSourceTap: (url) => _handleSourceTap(url),
    );
  },
)
```

---

## 🔧 Technische Details

### Props
```dart
class RabbitHoleView extends StatefulWidget {
  final List<RabbitLayer> layers;        // REQUIRED: Liste von Rabbit Layers
  final Function(String)? onSourceTap;   // OPTIONAL: Callback für Source-URL-Tap
  
  const RabbitHoleView({
    super.key,
    required this.layers,
    this.onSourceTap,
  });
}
```

### State Management
```dart
class _RabbitHoleViewState extends State<RabbitHoleView> {
  final Set<int> _expandedIndices = {};  // Expandierte Layer-Indices
  int _currentLayerIndex = 0;            // Aktueller Layer bei Navigation
  
  // Zeige entweder nur current layer (bei Navigation) oder alle
  List<RabbitLayer> get _layersToShow {
    return widget.layers.length > 1
        ? [widget.layers[_currentLayerIndex]]
        : widget.layers;
  }
}
```

### Model-Abhängigkeit
```dart
// lib/models/recherche_view_state.dart

class RabbitLayer {
  final int layerNumber;                   // Ebenen-Nummer (1, 2, 3, ...)
  final String layerName;                  // Name der Ebene
  final String description;                // Beschreibung
  final List<RechercheSource> sources;     // Quellen
  final List<String> connections;          // Verbindungen/Zusammenhänge
  final double depth;                      // Tiefe 0-1 (0% - 100%)
  
  const RabbitLayer({
    required this.layerNumber,
    required this.layerName,
    required this.description,
    required this.sources,
    this.connections = const [],
    required this.depth,
  });
}
```

---

## 🎯 Vorteile

### Benutzerfreundlichkeit
- ✅ **Depth Visualization** durch Progress Bars und Color-Coding
- ✅ **Layer Navigation** für einfache Exploration
- ✅ **Expand/Collapse** für kompakte Darstellung
- ✅ **Source Integration** mit direktem Zugriff
- ✅ **Clear Hierarchy** durch Ebenen-Nummern

### Performance
- ✅ **Lazy Loading** durch Expand/Collapse
- ✅ **Optimierte Navigation** (zeigt nur 1 Layer bei >1 Ebenen)
- ✅ **Effiziente Render-Pipeline**

### Design-Konsistenz
- ✅ **Material 3 Design** System
- ✅ **Theme-aware** Farben
- ✅ **Depth Color-Coding** für schnelles Scannen
- ✅ **Konsistent** mit anderen Recherche-Widgets
- ✅ **Gradient Backgrounds** für visuelle Hierarchie

---

## 📊 Research-UI Fortschritt

**Abgeschlossen: 7/8 Widgets (87.5%)**

✅ ModeSelector  
✅ ProgressPipeline  
✅ ResultSummaryCard  
✅ FactsList  
✅ SourcesList  
✅ PerspectivesView  
✅ **RabbitHoleView** ← NEU FERTIG  
⏳ RechercheScreen (finale Integration)

---

## 🚀 Nächster Schritt

**Widget 8/8:** RechercheScreen - Finale Integration (~60 Min)

**Features:**
- Alle 7 Widgets integrieren
- RechercheController Consumer
- Conditional Rendering (basierend auf Mode)
- Sections mit Headers
- ScrollView mit SafeArea
- Error State Handling
- Loading State mit ProgressPipeline
- Empty State für keine Ergebnisse

**Komponenten:**
1. AppBar mit Mode-Indikator
2. RechercheInputBar (bereits vorhanden)
3. ModeSelector
4. ProgressPipeline (während Loading)
5. ResultSummaryCard (wenn Result vorhanden)
6. FactsList (wenn facts.isNotEmpty)
7. SourcesList (wenn sources.isNotEmpty)
8. PerspectivesView (wenn perspectives.isNotEmpty)
9. RabbitHoleView (wenn rabbitLayers.isNotEmpty und Deep/Conspiracy Mode)

**Geschätzte Restzeit:** ~60 Minuten

---

## 📋 Changelog

**v1.0.0 - 2025-02-14**
- ✅ Widget-Implementierung abgeschlossen
- ✅ Test-Screen mit 3 Szenarien erstellt
- ✅ Depth Color-Coding (Grün/Orange/Rot)
- ✅ Layer Navigation implementiert
- ✅ Overall Depth Indicator
- ✅ Expandable Layer Details
- ✅ Sources als ActionChips
- ✅ Connections als Pfeil-Liste
- ✅ Empty State Handling
- ✅ Vollständige Dokumentation
- ✅ 0 Fehler, 0 Warnungen

---

**Status:** ✅ PRODUCTION-READY  
**Erstellt:** 2025-02-14  
**Getestet:** ✅ Alle Szenarien bestanden  
**Integration:** Bereit für RechercheScreen  
**Nächstes Widget:** RechercheScreen (finale Integration)
