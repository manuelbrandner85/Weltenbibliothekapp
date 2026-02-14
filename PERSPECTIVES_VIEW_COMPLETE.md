# 🔮 PERSPECTIVES VIEW WIDGET - COMPLETE

## ✅ Implementierungsstatus: ABGESCHLOSSEN

**Widget erstellt:** lib/widgets/recherche/perspectives_view.dart (14.948 Bytes)  
**Test-Screen:** lib/screens/perspectives_view_test_screen.dart (15.891 Bytes)  
**Test-Route:** `/perspectives_view_test`

**Code-Qualität:**
- ✅ `flutter analyze`: 0 Fehler, 0 Warnungen
- ✅ Material 3 Design
- ✅ Theme-aware
- ✅ Vollständig dokumentiert
- ✅ Alle Features getestet

---

## 📦 Widget-Features

### 1. Perspektiven-Karten
- **Name + Typ-Badge** (Supporting/Opposing/Neutral/Alternative/Controversial)
- **Credibility Score** als Sterne-Anzeige (0-10 → 0-5 Sterne)
- **Viewpoint** (Standpunkt) - gekürzt mit "..." wenn collapsed
- **Expand/Collapse** Funktion per Tap
- **Material-Ripple** Effekt bei Tap

### 2. Typ-spezifische Farben
- **Supporting:** Grün - Unterstützende Perspektive
- **Opposing:** Rot - Gegenperspektive
- **Neutral:** Grau - Neutrale/ausgewogene Sicht
- **Alternative:** Blau - Alternative Perspektive
- **Controversial:** Orange - Kontroverse Perspektive

### 3. Expandierte Details
- **Arguments Liste** mit nummerierten Badges
- **Supporting Sources** als anklickbare Chips
- **Source-Tap Callback** für URL-Navigation

### 4. Filter-System (bei >3 Perspektiven)
- **Horizontale Scrollbar** mit Filter-Chips
- **Filter nach Typ:** Alle, Supporting, Opposing, Neutral, Alternative, Controversial
- **Live-Filterung** beim Tap
- **Selected-State** mit Farb-Highlighting

### 5. Empty State
- **Icon + Text** wenn keine Perspektiven vorhanden
- **Leere Filter-Ergebnisse** mit spezifischer Meldung

---

## 🎨 Design-Details

### Perspektiven-Karte
```dart
Card(
  elevation: 2,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  child: InkWell(
    onTap: () => toggleExpand(),
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Header: Name + Typ-Badge
          Row(
            children: [
              Expanded(Text(perspectiveName, fontWeight: bold)),
              TypeBadge(label, color),
            ],
          ),
          
          // Credibility Stars
          CredibilityStars(credibility), // 0-10 → 0-5 Sterne
          
          // Viewpoint (gekürzt wenn collapsed)
          Text(viewpoint, maxLines: isExpanded ? null : 2),
          
          // Expandierte Details
          if (isExpanded) ...[
            Divider(),
            // Arguments mit nummerierten Badges
            ArgumentsList(arguments, typeColor),
            // Supporting Sources als Chips
            SourcesChips(supportingSources, onSourceTap),
          ],
          
          // Expand/Collapse Icon
          Icon(isExpanded ? expand_less : expand_more),
        ],
      ),
    ),
  ),
)
```

### Typ-Badge
```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  decoration: BoxDecoration(
    color: color.withOpacity(0.15),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: color.withOpacity(0.3)),
  ),
  child: Text(
    label, // Supporting, Opposing, etc.
    style: TextStyle(
      color: color,
      fontWeight: bold,
      fontSize: 11,
    ),
  ),
)
```

### Credibility Stars
```dart
Row(
  children: [
    Text('Glaubwürdigkeit: ', fontSize: 12, color: grey),
    Row(
      children: [
        // 5 Sterne (voll/halb/leer basierend auf credibility/2)
        Icon(Icons.star, size: 16, color: amber),
        Icon(Icons.star_half, size: 16, color: amber),
        Icon(Icons.star_border, size: 16, color: grey),
      ],
    ),
    Text('9.2/10', fontSize: 11, color: grey),
  ],
)
```

### Arguments Liste
```dart
...perspective.arguments.asMap().entries.map((entry) {
  return Row(
    children: [
      // Nummeriertes Badge
      Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: typeColor.withOpacity(0.2),
          shape: circle,
        ),
        child: Text('${entry.key + 1}', color: typeColor),
      ),
      SizedBox(width: 8),
      Expanded(Text(entry.value)),
    ],
  );
})
```

### Sources Chips
```dart
Wrap(
  spacing: 6,
  runSpacing: 6,
  children: sources.map((source) {
    return ActionChip(
      label: Text(source.title.truncate(30)),
      avatar: Icon(Icons.link, size: 14),
      onPressed: () => onSourceTap(source.url),
      backgroundColor: grey[100],
    );
  }),
)
```

---

## 🧪 Test-Szenarien

### 1. Vollständig (4 Perspektiven)
- **Supporting:** Wissenschaftliche Mainstream-Sicht (9.5/10)
- **Opposing:** Klimaskeptische Position (3.8/10)
- **Neutral:** Neutrale Vermittlungsposition (7.2/10)
- **Alternative:** Alternative Systemkritik (6.5/10)
- **Filter aktiv** (>3 Perspektiven)

### 2. Minimal (2 Perspektiven)
- **Supporting:** Befürwortende Position (8.0/10)
- **Opposing:** Kritische Perspektive (7.5/10)
- **Kein Filter** (<= 3 Perspektiven)

### 3. Einzeln (1 Perspektive)
- **Supporting:** Wissenschaftliche Sicht (9.2/10)

### 4. Leer (0 Perspektiven)
- **Empty State:** Icon + Text

---

## 📝 Verwendung im Projekt

### Integration in RechercheScreen
```dart
import 'package:flutter/material.dart';
import '../widgets/recherche/perspectives_view.dart';
import '../models/recherche_view_state.dart';
import 'package:url_launcher/url_launcher.dart';

// In RechercheScreen State:
Widget build(BuildContext context) {
  return Scaffold(
    body: SingleChildScrollView(
      child: Column(
        children: [
          // ... andere Widgets (ModeSelector, ProgressPipeline, etc.)
          
          // Perspectives Section
          if (_rechercheResult?.perspectives.isNotEmpty ?? false) ...[
            SectionHeader(
              title: '🔮 Verschiedene Perspektiven',
              subtitle: '${_rechercheResult!.perspectives.length} Perspektive(n)',
            ),
            SizedBox(height: 12),
            PerspectivesView(
              perspectives: _rechercheResult!.perspectives,
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
    
    if (result?.perspectives.isEmpty ?? true) {
      return EmptyState();
    }
    
    return PerspectivesView(
      perspectives: result!.perspectives,
      onSourceTap: (url) => _handleSourceTap(url),
    );
  },
)
```

---

## 🔧 Technische Details

### Props
```dart
class PerspectivesView extends StatefulWidget {
  final List<Perspective> perspectives;     // REQUIRED: Liste von Perspektiven
  final Function(String)? onSourceTap;      // OPTIONAL: Callback für Source-URL-Tap
  
  const PerspectivesView({
    super.key,
    required this.perspectives,
    this.onSourceTap,
  });
}
```

### State Management
```dart
class _PerspectivesViewState extends State<PerspectivesView> {
  PerspectiveType? _selectedFilter;         // Aktueller Filter (null = alle)
  final Set<int> _expandedIndices = {};     // Expandierte Karten-Indices
  
  List<Perspective> get _filteredPerspectives {
    if (_selectedFilter == null) return widget.perspectives;
    return widget.perspectives.where((p) => p.type == _selectedFilter).toList();
  }
}
```

### Model-Abhängigkeit
```dart
// lib/models/recherche_view_state.dart

class Perspective {
  final String perspectiveName;                  // Name der Perspektive
  final String viewpoint;                        // Standpunkt/Beschreibung
  final List<String> arguments;                  // Liste von Argumenten
  final List<RechercheSource> supportingSources; // Liste von Quellen
  final double credibility;                      // Glaubwürdigkeit 0-10
  final PerspectiveType type;                    // Typ der Perspektive
}

enum PerspectiveType {
  supporting,      // Unterstützend (Grün)
  opposing,        // Gegenperspektive (Rot)
  neutral,         // Neutral (Grau)
  alternative,     // Alternative (Blau)
  controversial,   // Kontrovers (Orange)
}

class RechercheSource {
  final String title;        // Titel der Quelle
  final String url;          // URL
  final String excerpt;      // Auszug
  final double relevance;    // Relevanz 0-1
  final String sourceType;   // Typ (article, document, website, book)
}
```

---

## 🎯 Vorteile

### Benutzerfreundlichkeit
- ✅ **Klare Typ-Kennzeichnung** durch Farben und Badges
- ✅ **Glaubwürdigkeit auf einen Blick** durch Sterne-System
- ✅ **Expand/Collapse** für kompakte Darstellung
- ✅ **Filter-System** bei vielen Perspektiven (>3)
- ✅ **Anklickbare Sources** für direkten Zugriff

### Performance
- ✅ **Lazy Loading** durch Expand/Collapse
- ✅ **Effiziente Filterung** mit Live-Update
- ✅ **Optimierte Render-Pipeline** (keine unnötigen Rebuilds)

### Design-Konsistenz
- ✅ **Material 3 Design** System
- ✅ **Theme-aware** Farben
- ✅ **Konsistent** mit anderen Recherche-Widgets
- ✅ **Responsive** Layout

---

## 📊 Research-UI Fortschritt

**Abgeschlossen: 6/8 Widgets (75%)**

✅ ModeSelector  
✅ ProgressPipeline  
✅ ResultSummaryCard  
✅ FactsList  
✅ SourcesList  
✅ **PerspectivesView** ← NEU FERTIG  
⏳ RabbitHoleView (nächstes Widget)  
⏳ RechercheScreen (finale Integration)

---

## 🚀 Nächster Schritt

**Widget 7/8:** RabbitHoleView Widget (~60 Min)

**Features:**
- Rabbit Layer Visualisierung (Ebenen-Tiefe)
- Expandierbare Layer-Karten
- Depth Indicator (0-1 → 0-100%)
- Discoveries pro Layer
- Layer-Navigation
- Empty State Handling

**Geschätzte Restzeit:** ~90 Min (RabbitHoleView + RechercheScreen)

---

## 📋 Changelog

**v1.0.0 - 2025-02-14**
- ✅ Widget-Implementierung abgeschlossen
- ✅ Test-Screen mit 4 Szenarien erstellt
- ✅ Alle 5 PerspectiveTypes unterstützt
- ✅ Filter-System implementiert
- ✅ Credibility Stars visualisiert
- ✅ Sources als anklickbare Chips
- ✅ Expand/Collapse Funktionalität
- ✅ Empty State Handling
- ✅ Vollständige Dokumentation
- ✅ 0 Fehler, 0 Warnungen

---

**Status:** ✅ PRODUCTION-READY  
**Erstellt:** 2025-02-14  
**Getestet:** ✅ Alle Szenarien bestanden  
**Integration:** Bereit für RechercheScreen
