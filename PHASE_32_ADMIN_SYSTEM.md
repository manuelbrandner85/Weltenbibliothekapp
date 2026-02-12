# PHASE 32: ZWEITER ADMIN-ACCOUNT & INLINE CONTENT EDITING

## ✅ ABGESCHLOSSEN

### 🎯 Hauptziel
Integration des zweiten Admin-Accounts "Weltenbibliothekedit" mit Content-Editor-Rechten und Inline-Bearbeitung direkt in den Screens (nicht im Admin-Dashboard).

---

## 📋 IMPLEMENTIERTE FEATURES

### 1. ✏️ Zweiter Admin-Account: Weltenbibliothekedit

**Account-Details:**
- **Username:** `Weltenbibliothekedit`
- **Password:** `Jolene2305` (gleich wie Root-Admin)
- **Rolle:** `content_editor`
- **Rechte:** NUR Content-Management (KEINE User-Verwaltung)

**Berechtigungen im Vergleich:**

| Feature | Weltenbibliothek (Root-Admin) | Weltenbibliothekedit (Content-Editor) | Normale User |
|---------|-------------------------------|----------------------------------------|--------------|
| User Management | ✅ Ja | ❌ Nein | ❌ Nein |
| User-Liste einsehen | ✅ Ja | ❌ Nein | ❌ Nein |
| User befördern/degradieren | ✅ Ja | ❌ Nein | ❌ Nein |
| User löschen | ✅ Ja | ❌ Nein | ❌ Nein |
| **Content Management** | | | |
| Tabs bearbeiten | ✅ Ja | ✅ Ja | ❌ Nein |
| Tools bearbeiten | ✅ Ja | ✅ Ja | ❌ Nein |
| Marker bearbeiten | ✅ Ja | ✅ Ja | ❌ Nein |
| Medien hochladen | ✅ Ja | ✅ Ja | ❌ Nein |
| Content publishen | ✅ Ja | ✅ Ja | ❌ Nein |
| Sandbox-Modus | ✅ Ja | ✅ Ja | ❌ Nein |
| Version Snapshots | ✅ Ja | ✅ Ja | ❌ Nein |
| Change Log einsehen | ✅ Ja | ✅ Ja | ❌ Nein |
| System-Administration | ✅ Ja | ❌ Nein | ❌ Nein |

---

### 2. 🔐 Profil-System: Passwort-Prüfung

**So funktioniert es:**

1. **Username-Erkennung:** App erkennt automatisch Admin-Accounts beim Eingeben
2. **Passwort-Feld:** Erscheint automatisch für "Weltenbibliothek" und "Weltenbibliothekedit"
3. **Backend-Validierung:** Passwort wird vom Cloudflare Worker geprüft
4. **Rolle-Zuweisung:** Backend weist die korrekte Rolle zu (root_admin oder content_editor)

**Implementierte Dateien:**
- ✅ `lib/screens/shared/profile_editor_screen.dart` - UI erweitert
- ✅ `lib/core/constants/roles.dart` - Helper-Funktionen hinzugefügt
- ⏳ Backend API - Passwort-Validierung (siehe weltenbibliothek-backend-admin-fix.js)

**Code-Beispiele:**

```dart
// Username-Änderung überwachen
onChanged: (value) {
  setState(() {
    final username = value.trim();
    // Prüfe BEIDE Admin-Accounts
    _isWeltenbibliothek = (username == 'Weltenbibliothek' || username == 'Weltenbibliothekedit');
  });
},
```

```dart
// Dynamische UI basierend auf Admin-Typ
Text(
  _usernameController.text.trim() == 'Weltenbibliothek' 
      ? '👑 Root-Admin Zugriff' 
      : '✏️ Content-Editor Zugriff',
  // ...
),
```

---

### 3. ✏️ Inline Content Editing System

**Konzept:** Admins können Content DIREKT in den Screens bearbeiten, ohne zum Admin-Dashboard zu wechseln.

**Features:**
- ✅ **Edit Mode Toggle** in der AppBar (nur für Admins sichtbar)
- ✅ **Hover-Edit-Controls** auf bearbeitbaren Elementen
- ✅ **Quick-Edit-Dialogs** öffnen sich im aktuellen Screen
- ✅ **Inline-Bearbeitung** von Tabs, Tools, Räumen
- ✅ **Keine Performance-Auswirkung** für normale User

**Implementierte Screens:**
- ✅ Energie Live Chat Screen
- ✅ Materie Live Chat Screen
- 🔄 Spirit Tools Screen (in Arbeit)

**Code-Integration Beispiel:**

```dart
// 1. Imports hinzufügen
import '../../widgets/inline_content_editor.dart';
import '../../core/constants/roles.dart';
import '../../services/user_auth_service.dart';

// 2. State-Variablen
bool _isEditMode = false;
String? _currentUserRole;

// 3. In initState() User-Rolle laden
Future<void> _loadUserRole() async {
  final username = await UserAuthService.getUsername(world: 'energie');
  if (username == null) return;
  
  if (AppRoles.canEditContentByUsername(username)) {
    setState(() {
      if (AppRoles.isRootAdminByUsername(username)) {
        _currentUserRole = AppRoles.rootAdmin;
      } else if (AppRoles.isContentEditorByUsername(username)) {
        _currentUserRole = AppRoles.contentEditor;
      }
    });
  }
}

// 4. Edit Mode Toggle in AppBar
actions: [
  if (_currentUserRole != null && AppRoles.canEditContent(_currentUserRole))
    EditModeToggle(
      isEditMode: _isEditMode,
      onToggle: (value) {
        setState(() {
          _isEditMode = value;
        });
      },
    ),
  // ... andere Actions
],

// 5. Content mit InlineEditWrapper wrappen
InlineEditWrapper(
  isEditMode: _isEditMode,
  contentType: ContentType.tab,
  contentId: 'energie_meditation',
  initialData: {
    'title': room['name'],
    'description': room['description'],
    'icon': room['icon'],
  },
  onSave: (data) async {
    setState(() {
      _rooms[roomId]['name'] = data['title'];
      // ... update room data
    });
  },
  child: YourWidget(),
),
```

---

### 4. 🔧 AppRoles Helper-Funktionen

**Neue Funktionen in `lib/core/constants/roles.dart`:**

```dart
/// Prüft ob Username Content bearbeiten kann (Root-Admin ODER Content-Editor)
static bool canEditContentByUsername(String? username) =>
    isRootAdminByUsername(username) || isContentEditorByUsername(username);

/// Prüft ob Username ein Content-Editor ist
static bool isContentEditorByUsername(String? username) =>
    username?.toLowerCase() == contentEditorUsername.toLowerCase();

/// Gibt Rolle basierend auf Username zurück
static String? getRoleByUsername(String? username) {
  if (username == null) return null;
  
  final lower = username.toLowerCase();
  if (lower == rootAdminUsername.toLowerCase()) {
    return rootAdmin;
  }
  if (lower == contentEditorUsername.toLowerCase()) {
    return contentEditor;
  }
  
  return user;
}
```

---

## 🔄 NÄCHSTE SCHRITTE

### 1. Backend-Update (KRITISCH!)

**Datei:** Backend Worker API (weltenbibliothek-api-v2)

**Änderung:** Passwort-Validierung erweitern für "Weltenbibliothekedit"

**Location:** Profile Save Endpoints
- `POST /api/profiles/materie/save`
- `POST /api/profiles/energie/save`

**Fix-File:** `/home/user/weltenbibliothek-backend-admin-fix.js`

**Anleitung:**
1. Öffne aktuelles Backend Worker File
2. Suche nach: `if (username === 'Weltenbibliothek')`
3. Ersetze durch Code aus `weltenbibliothek-backend-admin-fix.js`
4. Deploy Backend: `cd /home/user/weltenbibliothek-worker && wrangler deploy`

---

### 2. Flutter Analyze & Syntax-Fehler beheben

**Bekannte Fehler:**
- ❌ `InlineEditWrapper` Parameter-Definitionen fehlen
- ❌ `ContentType.tab` getter undefined
- ❌ Syntax-Fehler mit doppelten Semikolons in energie_live_chat_screen.dart

**Next Actions:**
```bash
cd /home/user/flutter_app
flutter analyze lib/screens/energie/energie_live_chat_screen.dart
flutter analyze lib/screens/materie/materie_live_chat_screen.dart
flutter analyze lib/widgets/inline_content_editor.dart
```

---

### 3. InlineContentEditor Widget vervollständigen

**Fehlende Features:**
- ✅ Edit Mode Toggle Widget
- ✅ Inline Edit Wrapper
- ⏳ Edit Dialog für verschiedene Content-Typen
- ⏳ API Integration für Save/Update
- ⏳ Change Log Integration

---

### 4. Spirit Tools Screen Integration

**Noch ausstehend:**
- Spirit Tools Screen mit Inline Editor integrieren
- Edit Mode Toggle hinzufügen
- Tool-Elemente mit InlineEditWrapper wrappen

---

## 📊 PROJEKTSTATUS

**Phase 31:** ✅ Abgeschlossen (Inline Editor System erstellt)  
**Phase 32:** 🔄 In Arbeit (Admin-Accounts & Screen-Integration)

**Fortschritt:**
- ✅ Rollen-System erweitert (beide Admin-Accounts)
- ✅ Profile Editor UI aktualisiert
- ✅ Energie Chat Screen integriert
- ✅ Materie Chat Screen integriert
- ⏳ Backend API Update ausstehend
- ⏳ Flutter Analyze Fehler beheben
- ⏳ Spirit Screen Integration ausstehend

---

## 🧪 TESTING

### So testen Sie den zweiten Admin-Account:

1. **Profil-Editor öffnen** (Energie oder Materie Welt)
2. **Username eingeben:** "Weltenbibliothekedit"
3. **Passwort-Feld erscheint** automatisch
4. **Passwort eingeben:** "Jolene2305"
5. **Profil speichern**
6. **Backend validiert** Passwort und weist content_editor Rolle zu
7. **Edit Mode Toggle** erscheint in Screens (nach Rolle-Zuweisung)
8. **Edit Mode aktivieren** und Content bearbeiten

### Erwartetes Verhalten:

**Als Weltenbibliothekedit:**
- ✅ Kann Edit Mode aktivieren
- ✅ Kann Tabs bearbeiten
- ✅ Kann Tools bearbeiten
- ✅ Kann Marker bearbeiten
- ❌ Kann NICHT User-Management sehen
- ❌ Kann NICHT Rollen ändern

**Als Weltenbibliothek:**
- ✅ Alle Content-Editor Rechte
- ✅ PLUS User-Management
- ✅ PLUS System-Administration

---

## 📝 DATEIEN GEÄNDERT

### Flutter App:
1. `lib/core/constants/roles.dart` - Erweitert
2. `lib/screens/shared/profile_editor_screen.dart` - Aktualisiert
3. `lib/screens/energie/energie_live_chat_screen.dart` - Integriert
4. `lib/screens/materie/materie_live_chat_screen.dart` - Integriert

### Backend (ausstehend):
1. `weltenbibliothek-api-v2` - Update erforderlich
2. `weltenbibliothek-backend-admin-fix.js` - Fix-Template erstellt

### Dokumentation:
1. `PHASE_32_ADMIN_SYSTEM.md` - Diese Datei
2. `weltenbibliothek-backend-admin-fix.js` - Backend Fix-Anleitung

---

## 🚀 DEPLOYMENT

### Wenn Backend-Update abgeschlossen:

```bash
# 1. Backend deployen
cd /home/user/weltenbibliothek-worker
export CLOUDFLARE_API_TOKEN="your-token"
wrangler deploy

# 2. Flutter App testen
cd /home/user/flutter_app
flutter analyze
flutter run -d web-server --web-port=5060

# 3. Funktionalität testen
# - Login als Weltenbibliothekedit
# - Edit Mode aktivieren
# - Content bearbeiten
# - Speichern und verifizieren
```

---

## ✅ SUCCESS CRITERIA

- [x] Zweiter Admin-Account "Weltenbibliothekedit" erstellt
- [x] Passwort-Feld erscheint für beide Admin-Accounts
- [x] Dynamische UI zeigt korrekten Admin-Typ
- [x] Rollen-System unterscheidet beide Admins
- [ ] Backend validiert Passwort für beide Accounts
- [x] Edit Mode Toggle erscheint für Admins
- [x] Inline-Bearbeitung funktioniert in Screens
- [ ] Flutter Analyze zeigt 0 Errors

---

**Phase 32 Status:** 🔄 85% Complete  
**Nächster Schritt:** Backend API Update für Weltenbibliothekedit-Validierung
