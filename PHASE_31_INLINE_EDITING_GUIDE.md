# 🎨 INLINE CONTENT EDITING - INTEGRATION GUIDE

## Weltenbibliothek Phase 31 - Direct Screen Editing

**Version:** 31.0  
**Datum:** 2025-02-08  
**Status:** ✅ IMPLEMENTIERT

---

## 📋 KONZEPT

Content-Bearbeitung findet **direkt in den jeweiligen Screens** statt:
- ✅ Energie Screen → Energie-Inhalte bearbeiten
- ✅ Materie Screen → Materie-Inhalte bearbeiten
- ✅ Spirit Screen → Spirit-Inhalte bearbeiten
- ✅ KEIN separates Admin-Dashboard
- ✅ Edit-Controls erscheinen bei Hover (nur für Admins)
- ✅ Quick-Edit-Dialoge öffnen sich im aktuellen Screen

---

## 🔧 INTEGRATION IN BESTEHENDE SCREENS

### 1. **Energie Live Chat Screen**

```dart
import '../widgets/inline_content_editor.dart';

class EnergieLiveChatScreen extends StatefulWidget {
  // ... existing code ...
}

class _EnergieLiveChatScreenState extends State<EnergieLiveChatScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Existing content
          _buildChatContent(),
          
          // ✅ NEU: Edit-Mode Toggle (nur für Admins sichtbar)
          const EditModeToggle(),
        ],
      ),
    );
  }

  Widget _buildChatContent() {
    return Column(
      children: [
        // ✅ NEU: Wrap Tab-Header mit InlineEditWrapper
        InlineEditWrapper(
          contentType: 'tab',
          contentId: 'energie_live_chat',
          onEdit: () => _editTab(),
          child: _buildTabHeader(),
        ),
        
        // ✅ NEU: Wrap jedes Tool mit InlineEditWrapper
        InlineEditWrapper(
          contentType: 'tool',
          contentId: 'voice_chat',
          onEdit: () => _editVoiceChat(),
          child: VoiceChatWidget(),
        ),
        
        // Existing chat list
        Expanded(child: _buildChatList()),
      ],
    );
  }

  void _editTab() {
    showDialog(
      context: context,
      builder: (context) => InlineEditDialog(
        contentType: 'tab',
        contentId: 'energie_live_chat',
      ),
    );
  }

  void _editVoiceChat() {
    showDialog(
      context: context,
      builder: (context) => InlineEditDialog(
        contentType: 'tool',
        contentId: 'voice_chat',
      ),
    );
  }
}
```

### 2. **Materie Screen - Map Markers**

```dart
import '../widgets/inline_content_editor.dart';

class MaterieScreen extends StatefulWidget {
  // ... existing code ...
}

class _MaterieScreenState extends State<MaterieScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map with markers
          FlutterMap(
            children: [
              MarkerLayer(
                markers: _buildMarkers(),
              ),
            ],
          ),
          
          // ✅ NEU: Edit-Mode Toggle
          const EditModeToggle(),
          
          // ✅ NEU: Quick Add Marker Button
          Positioned(
            bottom: 16,
            right: 16,
            child: QuickAddButton(
              contentType: 'marker',
              onAdd: () => _addNewMarker(),
            ),
          ),
        ],
      ),
    );
  }

  List<Marker> _buildMarkers() {
    return markers.map((marker) {
      return Marker(
        point: LatLng(marker.latitude, marker.longitude),
        // ✅ NEU: Wrap Marker-Content mit InlineEditWrapper
        child: InlineEditWrapper(
          contentType: 'marker',
          contentId: marker.id,
          onEdit: () => _editMarker(marker),
          onDelete: () => _deleteMarker(marker),
          child: _buildMarkerIcon(marker),
        ),
      );
    }).toList();
  }

  void _editMarker(DynamicMarker marker) {
    showDialog(
      context: context,
      builder: (context) => MarkerEditDialog(marker: marker),
    );
  }

  void _addNewMarker() {
    showDialog(
      context: context,
      builder: (context) => MarkerCreateDialog(),
    );
  }
}
```

### 3. **Spirit Tools Screen**

```dart
import '../widgets/inline_content_editor.dart';

class SpiritToolsScreen extends StatefulWidget {
  // ... existing code ...
}

class _SpiritToolsScreenState extends State<SpiritToolsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Tools Grid
          GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
            ),
            itemCount: tools.length,
            itemBuilder: (context, index) {
              final tool = tools[index];
              
              // ✅ NEU: Wrap jedes Tool mit InlineEditWrapper
              return InlineEditWrapper(
                contentType: 'tool',
                contentId: tool.id,
                onEdit: () => _editTool(tool),
                onDelete: () => _deleteTool(tool),
                child: ToolCard(tool: tool),
              );
            },
          ),
          
          // ✅ NEU: Edit-Mode Toggle
          const EditModeToggle(),
          
          // ✅ NEU: Quick Add Tool Button
          Positioned(
            bottom: 16,
            right: 16,
            child: QuickAddButton(
              contentType: 'tool',
              onAdd: () => _addNewTool(),
            ),
          ),
        ],
      ),
    );
  }

  void _editTool(Tool tool) {
    showDialog(
      context: context,
      builder: (context) => ToolEditDialog(tool: tool),
    );
  }

  void _addNewTool() {
    showDialog(
      context: context,
      builder: (context) => ToolCreateDialog(),
    );
  }
}
```

### 4. **Text & Button Editing (beliebiger Screen)**

```dart
// ✅ Editierbare Überschrift
InlineEditWrapper(
  contentType: 'text',
  contentId: 'section_title',
  child: Text(
    'Energie Live Chat',
    style: Theme.of(context).textTheme.headlineMedium,
  ),
)

// ✅ Editierbarer Button
InlineEditWrapper(
  contentType: 'button',
  contentId: 'cta_button',
  child: ElevatedButton(
    onPressed: () => _doSomething(),
    child: const Text('Jetzt starten'),
  ),
)

// ✅ Editierbare Section
InlineEditWrapper(
  contentType: 'section',
  contentId: 'welcome_section',
  child: Column(
    children: [
      const Text('Willkommen!'),
      const Text('Hier findest du...'),
    ],
  ),
)
```

---

## 🎯 WIE ES FUNKTIONIERT

### Für Root-Admin / Content-Editor:

1. **Screen öffnen** (z.B. Energie Live Chat)
2. **Edit-Modus aktivieren** via Floating Button
3. **Über Element hovern** → Edit-Controls erscheinen
4. **Bearbeiten klicken** → Quick-Edit-Dialog öffnet sich
5. **Änderungen vornehmen** und speichern
6. **Sofort live** für alle User

### Für normale User:

- **Keine Edit-Controls sichtbar**
- **Keine Edit-Mode-Button**
- **Nur finale Inhalte sichtbar**

---

## 🎨 UI/UX PATTERN

### Hover-Effekt (nur für Admins)
```
┌─────────────────────────────┐
│  Element-Inhalt             │ ← Normal
└─────────────────────────────┘

        ⬇️  Hover

┌─────────────────────────────┐
│  Element-Inhalt          ┌─┐│
│                          │✏││ ← Edit-Controls
│                          │🗑│ 
└─────────────────────────────┘
   ↑ Lila Border erscheint
```

### Quick-Edit-Dialog
```
┌────────────────────────────────┐
│ ✏️  TAB bearbeiten          ✕  │
├────────────────────────────────┤
│                                │
│ Titel:                         │
│ ┌────────────────────────────┐ │
│ │ Energie Live Chat          │ │
│ └────────────────────────────┘ │
│                                │
│ Beschreibung:                  │
│ ┌────────────────────────────┐ │
│ │ Real-time Voice Chat...    │ │
│ │                            │ │
│ └────────────────────────────┘ │
│                                │
│ [Abbrechen]   [Speichern]     │
└────────────────────────────────┘
```

---

## 📦 INTEGRATION CHECKLIST

### Pro Screen:

- [ ] Import `inline_content_editor.dart`
- [ ] Wrap editierbare Elemente mit `InlineEditWrapper`
- [ ] `EditModeToggle` zum Screen hinzufügen
- [ ] Optional: `QuickAddButton` für neue Inhalte
- [ ] Edit/Delete Callbacks implementieren
- [ ] API-Integration für Speichern/Löschen

### Beispiel-Screens die angepasst werden müssen:

#### Energie Welt:
- [ ] `energie_live_chat_screen.dart` - Voice Chat, Messages
- [ ] `energie_meditation_screen.dart` - Meditation Tools
- [ ] `energie_frequency_screen.dart` - Frequency Generator

#### Materie Welt:
- [ ] `materie_live_chat_screen.dart` - Chat, Tools
- [ ] `materie_map_screen.dart` - Karten-Marker
- [ ] `materie_research_screen.dart` - Research Tools

#### Spirit Welt:
- [ ] `spirit_tools_screen.dart` - Spirit Tools Grid
- [ ] `spirit_meditation_screen.dart` - Meditation
- [ ] `spirit_calendar_screen.dart` - Kalender Events

#### Shared:
- [ ] `welcome_screen.dart` - Intro-Texte, CTAs
- [ ] `profile_screen.dart` - Profil-Sections

---

## 🔧 ERWEITERTE EDIT-DIALOGE

### Marker-Edit-Dialog (mit Map-Picker)

```dart
class MarkerEditDialog extends StatefulWidget {
  final DynamicMarker marker;
  
  const MarkerEditDialog({super.key, required this.marker});

  @override
  State<MarkerEditDialog> createState() => _MarkerEditDialogState();
}

class _MarkerEditDialogState extends State<MarkerEditDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late LatLng _position;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.marker.title);
    _descriptionController = TextEditingController(text: widget.marker.description);
    _position = LatLng(widget.marker.latitude, widget.marker.longitude);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Text('Marker bearbeiten', style: Theme.of(context).textTheme.titleLarge),
            const Divider(),
            
            // Form
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Titel'),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Beschreibung'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            
            // Map Picker
            Expanded(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: _position,
                  onTap: (tapPos, latLng) {
                    setState(() => _position = latLng);
                  },
                ),
                children: [
                  TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _position,
                        child: const Icon(Icons.location_pin, size: 40, color: Colors.red),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Abbrechen'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveMarker,
                    child: const Text('Speichern'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveMarker() async {
    // TODO: Save to API
    Navigator.pop(context);
  }
}
```

---

## ⚡ PERFORMANCE OPTIMIERUNG

### Lazy Loading für Edit-Controls
```dart
// Edit-Controls nur laden wenn Admin
class InlineEditWrapper extends StatefulWidget {
  // ... code ...
  
  @override
  Widget build(BuildContext context) {
    if (!_canEdit) {
      return widget.child;  // ← Keine Edit-Controls für normale User
    }
    
    // Edit-Controls nur für Admins
    return MouseRegion(/* ... */);
  }
}
```

### Conditional Rendering
```dart
// Nur editierbare Elemente wrappen
Widget _buildContent() {
  final canEdit = await DynamicContentService().canEditContent();
  
  if (canEdit) {
    // Admin-Version mit Edit-Wrappern
    return InlineEditWrapper(/* ... */);
  } else {
    // User-Version ohne Edit-Controls
    return _buildNormalContent();
  }
}
```

---

## 🎯 VORTEILE

### ✅ Direktes Editing
- Änderungen im Kontext
- Keine Navigation zu Admin-Dashboard
- WYSIWYG-Erfahrung

### ✅ Schneller Workflow
- Hover → Edit → Speichern
- Minimale Klicks
- Sofortiges Feedback

### ✅ Kein separates Admin-Dashboard nötig
- Weniger Code
- Einfachere Wartung
- Natürlicherer Workflow

### ✅ Für User unsichtbar
- Keine Edit-Controls
- Keine Performance-Einbußen
- Normale App-Erfahrung

---

## 📊 ZUSAMMENFASSUNG

**Phase 31 - Inline Content Editing:**

✅ Content-Bearbeitung direkt in Screens  
✅ Hover-basierte Edit-Controls  
✅ Quick-Edit-Dialoge  
✅ Edit-Mode Toggle  
✅ Quick-Add Buttons  
✅ Für User komplett unsichtbar  

**BEREIT FÜR INTEGRATION** in alle Screens!

---

**Ende** - Inline Content Editing Integration Guide
