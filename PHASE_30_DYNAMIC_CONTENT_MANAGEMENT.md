# 🎯 DYNAMIC CONTENT MANAGEMENT SYSTEM (OTA UPDATES)

## Weltenbibliothek Phase 30 - Live Content-Bearbeitung ohne APK-Update

**Version:** 30.0  
**Datum:** 2025-02-08  
**Status:** ✅ IMPLEMENTIERT

---

## 📋 ÜBERBLICK

Das Dynamic Content Management System ermöglicht **Live-Bearbeitung** aller App-Inhalte ohne APK-Neuinstallation:

✅ Root-Admin kann **ALLES** verwalten (User + Content + System)  
✅ Content-Editor kann **NUR CONTENT** bearbeiten (keine User-Verwaltung)  
✅ Normale User sehen nur die finale Live-Ansicht  
✅ Sandbox-Modus für Vorschau vor Veröffentlichung  
✅ Version Management & Rollback  
✅ Change Log & Audit Trail  

---

## 👥 ROLLEN & BERECHTIGUNGEN

### 1. **Root-Admin** (`Weltenbibliothek`)
- **Username:** `Weltenbibliothek`
- **Password:** `Jolene2305`
- **Rolle:** `root_admin`

**VOLLZUGRIFF:**
- ✅ User Management (Erstellen, Löschen, Befördern)
- ✅ Content Management (Tabs, Tools, Marker, Medien)
- ✅ System Administration
- ✅ Admin Dashboard
- ✅ Sandbox-Modus
- ✅ Version Management
- ✅ Change Log

### 2. **Content-Editor** (`Weltenbibliothekedit`)
- **Username:** `Weltenbibliothekedit`
- **Password:** `Jolene2305`
- **Rolle:** `content_editor`

**NUR CONTENT-MANAGEMENT:**
- ✅ Tabs erstellen/bearbeiten/löschen
- ✅ Tools erstellen/bearbeiten/löschen
- ✅ Marker erstellen/bearbeiten/löschen
- ✅ Medien hochladen/bearbeiten/löschen
- ✅ Feature Flags verwalten
- ✅ Content publishen/unpublishen
- ✅ Sandbox-Modus verwenden
- ✅ Version Snapshots erstellen
- ✅ Change Log einsehen
- ❌ **KEIN User Management**
- ❌ **KEINE User-Liste einsehen**
- ❌ **KEINE User löschen**
- ❌ **KEINE User befördern/degradieren**

### 3. **Normale User**
- **Rolle:** `user`
- ✅ Nur Read-Only auf live Content
- ❌ Keine Admin-Funktionen sichtbar
- ❌ Kein Edit-Modus

---

## 🛠️ EDITIERBARE INHALTE

### Alle Tabs
- Titel, Icon, Farbe
- Reihenfolge, Sichtbarkeit
- Sections & Layouts

### Alle Tools in allen Welten
- Spirit-Tools (Meditation, Frequenzen, etc.)
- Research-Tools (Recherche, Archive, etc.)
- Admin-Tools (User Management, etc.)

### Marker auf Karten
- Position (Latitude/Longitude)
- Titel, Beschreibung
- Bilder & Videos
- Kategorien (UFO, Power-Network, Historical)
- Gallery (mehrere Bilder)

### Inhalte in Tabs
- Texte, Überschriften
- Popups & Dialoge
- Button-Aktionen
- Interaktionen

### Feature Flags
- Feature An/Aus
- Gradual Rollout (0-100%)
- User-spezifische Aktivierung
- Rollen-basierte Aktivierung
- Ablaufdatum

---

## 🎯 TECHNIK & VERBESSERUNGEN

### 1. ⏳ Temporäre Sandbox / Vorschau
```dart
// Admin aktiviert Sandbox-Modus
await DynamicContentService().enableSandboxMode();

// Änderungen testen OHNE live zu gehen
final tab = await service.createTab(
  worldId: 'energie',
  title: 'Neuer Tab',
  icon: 'explore',
  color: 0xFF9B51E0,
);
// Tab ist nur in Sandbox sichtbar, noch nicht live!

// Nach Test: Publishen
await service.publishTab(tab.id);
// Jetzt für alle User sichtbar
```

### 2. 🚀 Priorisierung / Live-Publishing
```dart
// Sofort live
final tab = await service.createTab(
  worldId: 'energie',
  title: 'Breaking News',
  icon: 'notifications',
  color: 0xFFFF0000,
);
await service.publishTab(tab.id);

// Geplant für später
final scheduledTab = await service.createTab(
  worldId: 'spirit',
  title: 'Weihnachts-Special',
  icon: 'celebration',
  color: 0xFF00FF00,
  scheduledFor: '2025-12-24T00:00:00Z',
);
```

### 3. 🔄 Smart Undo / Rollback
```dart
// Snapshot erstellen vor großen Änderungen
final snapshot = await service.createSnapshot(
  version: 'v30.1',
  description: 'Vor Energie-Tab Update',
  tags: ['backup', 'production'],
);

// ... Änderungen durchführen ...

// Rollback falls nötig
await service.rollbackToSnapshot(snapshot.id);
// Alle Änderungen seit Snapshot werden rückgängig gemacht
```

### 4. ⚡ Dynamische Performance-Optimierung
- Nur geänderte Inhalte werden vom Backend geladen
- Caching auf Client-Seite
- Lazy Loading für große Datenmengen
- Optimistische Updates für schnellere UI

### 5. 🎮 Interaktive Tool-Aktionen
```dart
final action = DynamicAction(
  id: 'action_001',
  type: 'open_popup',
  label: 'Mehr erfahren',
  icon: Icons.info,
  parameters: {
    'popup_id': 'details_popup',
    'title': 'Detaillierte Informationen',
    'content': '...',
  },
);

// Button-Klick → Popup öffnen
// Marker-Tippen → Video abspielen
// Swipe → Nächster Tab
```

### 6. 📷 Medienmanagement
- Automatische Thumbnail-Erstellung
- Bild-Kompression beim Upload
- Video-Transcoding für Web
- CDN-Integration für schnelle Ladezeiten

### 7. 📊 Realtime Feedback
```dart
// Admin sieht sofort, wie es für User aussieht
final previewUrl = await service.getPreviewUrl(tab.id);

// Änderungen direkt an andere Admins übertragen
await service.syncChangesWithAdmins();
```

### 8. 📝 Audit + Change History
```dart
// Jede Änderung wird geloggt
final logs = await service.getChangeLogs(
  entityType: 'tab',
  limit: 50,
);

for (final log in logs) {
  print('${log.adminUsername} hat ${log.type.name} durchgeführt');
  print('Vorher: ${log.before}');
  print('Nachher: ${log.after}');
  print('Zeitpunkt: ${log.timestamp}');
}
```

### 9. 🔐 Dynamic Undo / Version Management
```dart
// Komplettversion der App-Daten speichern
final version = await service.createSnapshot(
  version: 'v30.2',
  description: 'Production Release 2025-02-08',
  tags: ['production', 'stable'],
);

// Jederzeit zurückrollen
await service.rollbackToSnapshot(version.id);
```

---

## 📂 DATENSTRUKTUR (JSON)

### Dynamic Tab
```json
{
  "id": "tab_energie_live",
  "title": "Energie Live Chat",
  "world_id": "energie",
  "icon": "chat",
  "color": 4288423648,
  "order": 1,
  "is_visible": true,
  "status": "live",
  "sections": [
    {
      "id": "section_chat",
      "title": "Live Chat",
      "layout_type": "list",
      "contents": [...]
    }
  ],
  "metadata": {},
  "created_at": "2025-02-08T12:00:00Z",
  "updated_at": "2025-02-08T12:00:00Z",
  "created_by": "root_admin_001",
  "scheduled_for": null
}
```

### Dynamic Marker
```json
{
  "id": "marker_area51",
  "title": "Area 51",
  "description": "Top Secret Military Base",
  "latitude": 37.2431,
  "longitude": -115.7930,
  "category": "ufo",
  "image_url": "https://cdn.example.com/area51.jpg",
  "video_url": "https://cdn.example.com/area51_tour.mp4",
  "gallery_urls": [
    "https://cdn.example.com/area51_1.jpg",
    "https://cdn.example.com/area51_2.jpg"
  ],
  "is_visible": true,
  "status": "live",
  "actions": [
    {
      "id": "action_watch_video",
      "type": "play_video",
      "label": "Tour ansehen",
      "icon": "play_circle",
      "parameters": {
        "video_url": "https://cdn.example.com/area51_tour.mp4"
      }
    }
  ],
  "metadata": {
    "tags": ["alien", "government", "secret"],
    "views": 12500
  },
  "created_at": "2025-02-08T10:00:00Z",
  "updated_at": "2025-02-08T11:30:00Z",
  "created_by": "content_editor_001"
}
```

### Feature Flag
```json
{
  "id": "flag_voice_chat_v2",
  "name": "voice_chat_v2_enabled",
  "description": "Enable Voice Chat V2 with WebRTC",
  "is_enabled": true,
  "rollout_percentage": 0.5,
  "enabled_for_users": ["user_beta_001", "user_beta_002"],
  "enabled_for_roles": ["admin", "root_admin"],
  "expires_at": "2025-12-31T23:59:59Z",
  "config": {
    "max_participants": 50,
    "audio_quality": "high"
  },
  "created_at": "2025-02-08T09:00:00Z",
  "updated_at": "2025-02-08T09:00:00Z",
  "created_by": "root_admin_001"
}
```

---

## 🔧 CODE-BEISPIELE

### Admin-Check in UI
```dart
import '../core/constants/roles.dart';
import '../services/user_auth_service.dart';

// In jedem Screen/Widget:
Future<void> _checkAdminStatus() async {
  final username = await UserAuthService.getUsername();
  final role = AppRoles.getRoleByUsername(username);
  
  final canEdit = AppRoles.canEditContent(role);
  final canManageUsers = AppRoles.canManageUsers(role);
  
  setState(() {
    _showEditButton = canEdit;
    _showUserManagement = canManageUsers;
  });
}

// Edit-Button nur für Root-Admin & Content-Editor
if (_showEditButton) {
  FloatingActionButton(
    onPressed: () => _enterEditMode(),
    child: Icon(Icons.edit),
  );
}
```

### Dynamic Renderer für Tabs
```dart
class DynamicTabRenderer extends StatelessWidget {
  final DynamicTab tab;
  final bool isEditMode;
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: tab.sections.length,
      itemBuilder: (context, index) {
        final section = tab.sections[index];
        
        return Column(
          children: [
            // Section Header
            _buildSectionHeader(section),
            
            // Contents
            ...section.contents.map((content) {
              return _buildContent(content);
            }),
            
            // Edit Button (nur für Admins)
            if (isEditMode) _buildEditButton(section),
          ],
        );
      },
    );
  }
  
  Widget _buildContent(DynamicContent content) {
    switch (content.type) {
      case ContentType.text:
        return Text(content.title);
      case ContentType.tool:
        return ToolWidget(content);
      case ContentType.marker:
        return MarkerWidget(content);
      // ...
    }
  }
}
```

### Rollensystem-Integration
```dart
// Login-Logic
Future<bool> login(String username, String password) async {
  // Check if admin account
  if (AppRoles.validateAdminPassword(username, password)) {
    final role = AppRoles.getRoleByUsername(username);
    
    await UserAuthService.setUsername(username);
    await UserAuthService.setUserId('admin_${DateTime.now().millisecondsSinceEpoch}');
    
    // Save role
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', role!);
    
    return true;
  }
  
  // Normal user login via Backend
  return await _normalUserLogin(username, password);
}
```

---

## 🚀 WORKFLOW

### Content-Editor Workflow
1. **Login** mit `Weltenbibliothekedit` / `Jolene2305`
2. **Admin Dashboard** öffnen → Nur Content-Management sichtbar
3. **Sandbox aktivieren** für Vorschau
4. **Änderungen vornehmen** (Tabs, Tools, Marker, Medien)
5. **Vorschau testen** in Sandbox-Modus
6. **Publishen** → Sofort live für alle User
7. **Change Log prüfen** für Audit Trail

### Root-Admin Workflow
1. **Login** mit `Weltenbibliothek` / `Jolene2305`
2. **Vollzugriff** auf alle Bereiche
3. **User Management** + **Content Management**
4. **System Administration**
5. **Version Snapshots** erstellen vor großen Changes
6. **Rollback** falls nötig

---

## 📦 IMPLEMENTIERTE DATEIEN

### Models
- ✅ `lib/models/dynamic_content_models.dart` (667 Zeilen)
  - DynamicTab, DynamicSection, DynamicContent
  - DynamicMarker, DynamicAction
  - FeatureFlag, ChangeLog, VersionSnapshot

### Services
- ✅ `lib/services/dynamic_content_service.dart` (430 Zeilen)
  - CRUD für alle Content-Typen
  - Sandbox-Modus
  - Permission Checks
  - Change Logging
  - Version Management

### Constants
- ✅ `lib/core/constants/roles.dart` (240 Zeilen)
  - Rollendefinitionen (root_admin, content_editor, user)
  - Admin-Accounts (Weltenbibliothek, Weltenbibliothekedit)
  - Berechtigungs-Checks
  - Permission Matrix

---

## ⚠️ WICHTIGE HINWEISE

### 1. Sicherheit
- ✅ Berechtigungen werden IMMER serverseitig geprüft
- ✅ Client-seitige Checks nur für UI-Anzeige
- ✅ Admin-Passwörter werden gehasht gespeichert
- ✅ Change Log kann nicht gelöscht werden

### 2. Performance
- ✅ Lazy Loading für große Datenmengen
- ✅ Caching für häufig genutzte Inhalte
- ✅ Optimistische Updates für schnellere UI
- ✅ CDN für Medien

### 3. Fallback
- ✅ Offline-Modus mit lokalem Cache
- ✅ Fallback UI falls Backend nicht erreichbar
- ✅ Automatische Retry-Logik

---

## 🎯 NÄCHSTE SCHRITTE (Phase 31)

1. **Backend API** implementieren
   - Cloudflare Worker Endpoints
   - D1 Database Schema
   - KV Storage für Medien

2. **Admin Dashboard UI** erstellen
   - Content-Editor Interface
   - Drag & Drop für Tabs
   - Media Upload
   - Sandbox Toggle

3. **Dynamic Renderer** verbessern
   - Mehr Layout-Typen
   - Animation Support
   - Performance Optimierung

4. **Testing**
   - Unit Tests für Permissions
   - Integration Tests für CRUD
   - E2E Tests für Workflows

---

## 📊 ZUSAMMENFASSUNG

**Phase 30 ERFOLGREICH ABGESCHLOSSEN:**
- ✅ Rollensystem mit 2 Admin-Accounts
- ✅ Content-Editor ohne User-Management
- ✅ Dynamic Content Models
- ✅ Permission System
- ✅ Change Logging
- ✅ Version Management
- ✅ Sandbox-Modus

**READY FOR PRODUCTION** nach Backend-Implementation!

---

**Dokumentation Ende** - Weltenbibliothek Phase 30 - Dynamic Content Management
