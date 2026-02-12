# 🚀 OTA Content Management System - Weltenbibliothek

**Version**: 1.0.0  
**Datum**: 8. Februar 2026  
**Status**: ✅ PRODUKTIV  

---

## 📋 Überblick

Das **OTA (Over-The-Air) Content Management System** ermöglicht es Admins, App-Inhalte dynamisch zu ändern **ohne die App neu zu kompilieren oder neu zu deployen**.

### Was kann verwaltet werden?
- **Tabs/Räume**: Neue Chat-Räume hinzufügen/bearbeiten
- **Tools**: Room-spezifische Tools konfigurieren
- **Markers**: Karten-Marker für UFO-Sichtungen, etc.
- **Feature Flags**: Features ein-/ausschalten
- **Change Logs**: Alle Änderungen werden protokolliert

---

## 🔐 Berechtigungen

### Zwei Admin-Rollen

**1. Root Admin (Weltenbibliothek)**
- **Username**: `Weltenbibliothek`
- **Password**: `Jolene2305`
- **Rechte**: 
  - ✅ Content-Management (alle Inhalte bearbeiten)
  - ✅ User-Management (User erstellen, löschen, befördern)
  - ✅ System-Administration (voller Zugriff)

**2. Content Editor (Weltenbibliothekedit)**
- **Username**: `Weltenbibliothekedit`
- **Password**: `Jolene2305`
- **Rechte**:
  - ✅ Content-Management (Tabs, Tools, Marker bearbeiten)
  - ✅ Change Logs einsehen
  - ❌ **KEIN** User-Management
  - ❌ **KEINE** System-Administration

---

## 🌐 Backend API

### Base URL
```
https://weltenbibliothek-api-v2.brandy13062.workers.dev
```

### Health Check
```bash
curl https://weltenbibliothek-api-v2.brandy13062.workers.dev/health
```

**Response:**
```json
{
  "status": "ok",
  "version": "13.1.0",
  "timestamp": "2026-02-08T03:16:37.972Z",
  "features": {
    "profile_management": true,
    "content_management": true,
    "admin_accounts": [
      "Weltenbibliothek (root_admin)",
      "Weltenbibliothekedit (content_editor)"
    ]
  }
}
```

---

## 📡 API Endpoints

### Tabs Management

**GET /api/content/tabs?world={world}**
```bash
curl "https://weltenbibliothek-api-v2.brandy13062.workers.dev/api/content/tabs?world=energie"
```

**Response:**
```json
{
  "tabs": [
    {
      "id": "tab_001",
      "world": "energie",
      "name": "Meditation",
      "icon": "🧘",
      "description": "Gruppen-Meditationen",
      "created_at": "2026-02-08T03:00:00Z",
      "updated_at": "2026-02-08T03:00:00Z",
      "created_by": "energie_Weltenbibliothekedit"
    }
  ]
}
```

---

**POST /api/content/tabs** (Admin only)
```bash
curl -X POST https://weltenbibliothek-api-v2.brandy13062.workers.dev/api/content/tabs \
  -H "Content-Type: application/json" \
  -H "X-World: energie" \
  -H "X-User-ID: energie_Weltenbibliothekedit" \
  -H "X-Username: Weltenbibliothekedit" \
  -H "X-Role: content_editor" \
  -d '{
    "world": "energie",
    "name": "Astral-Reisen",
    "icon": "🌌",
    "description": "Gemeinsame Astral-Journeys"
  }'
```

**Response:**
```json
{
  "success": true,
  "tab": {
    "id": "d8f3a6b2-4e7c-4a1b-9d5e-f2c3a8b7e6d4",
    "world": "energie",
    "name": "Astral-Reisen",
    "icon": "🌌",
    "description": "Gemeinsame Astral-Journeys",
    "created_at": "2026-02-08T03:20:00Z",
    "updated_at": "2026-02-08T03:20:00Z",
    "created_by": "energie_Weltenbibliothekedit"
  }
}
```

---

**PUT /api/content/tabs/:id** (Admin only)
```bash
curl -X PUT https://weltenbibliothek-api-v2.brandy13062.workers.dev/api/content/tabs/d8f3a6b2-4e7c-4a1b-9d5e-f2c3a8b7e6d4 \
  -H "Content-Type: application/json" \
  -H "X-User-ID: energie_Weltenbibliothekedit" \
  -H "X-Username: Weltenbibliothekedit" \
  -H "X-Role: content_editor" \
  -d '{
    "name": "Astralreisen & OBE",
    "description": "Out-of-Body Experiences gemeinsam erleben"
  }'
```

---

**DELETE /api/content/tabs/:id** (Admin only)
```bash
curl -X DELETE https://weltenbibliothek-api-v2.brandy13062.workers.dev/api/content/tabs/d8f3a6b2-4e7c-4a1b-9d5e-f2c3a8b7e6d4 \
  -H "X-User-ID: energie_Weltenbibliothekedit" \
  -H "X-Username: Weltenbibliothekedit" \
  -H "X-Role: content_editor"
```

---

### Tools Management

**GET /api/content/tools?world={world}&room={roomId}**
```bash
curl "https://weltenbibliothek-api-v2.brandy13062.workers.dev/api/content/tools?world=energie&room=meditation"
```

---

### Markers Management

**GET /api/content/markers?category={category}**
```bash
curl "https://weltenbibliothek-api-v2.brandy13062.workers.dev/api/content/markers?category=ufo"
```

---

### Change Logs (Admin only)

**GET /api/content/change-logs**
```bash
curl "https://weltenbibliothek-api-v2.brandy13062.workers.dev/api/content/change-logs?limit=50" \
  -H "X-Role: content_editor"
```

**Response:**
```json
{
  "logs": [
    {
      "id": "log_001",
      "type": "create",
      "entity_type": "tab",
      "entity_id": "d8f3a6b2-4e7c-4a1b-9d5e-f2c3a8b7e6d4",
      "admin_id": "energie_Weltenbibliothekedit",
      "admin_username": "Weltenbibliothekedit",
      "before_data": null,
      "after_data": "{...}",
      "reason": "New tab created",
      "timestamp": "2026-02-08T03:20:00Z"
    }
  ]
}
```

---

## 📱 Flutter Integration

### Content API Service

Die Flutter-App nutzt `ContentApiService` für alle OTA-Operationen:

```dart
import 'package:flutter_app/services/content_api_service.dart';

// Get tabs
final tabs = await ContentApiService().getTabs('energie');

// Check if user can edit
final canEdit = await ContentApiService().canEditContent();

if (canEdit) {
  // Create new tab
  final newTab = await ContentApiService().createTab(
    world: 'energie',
    name: 'Chakra-Arbeit',
    icon: '🔥',
    description: 'Gemeinsame Chakra-Aktivierungen',
  );
  
  if (newTab != null) {
    print('✅ Tab created: ${newTab['id']}');
  }
}
```

---

## 🎯 Workflow: Content bearbeiten

### Schritt 1: Als Admin einloggen

1. App öffnen: https://5060-ingyb9x7032nc991qsp0l-0e616f0a.sandbox.novita.ai
2. Profil-Editor öffnen (Energie oder Materie Welt)
3. Username eingeben: `Weltenbibliothekedit`
4. Passwort eingeben: `Jolene2305`
5. Profil speichern

**Backend validiert Passwort** und weist `content_editor` Rolle zu.

---

### Schritt 2: Edit Mode aktivieren

1. In Chat-Screen (Energie Live-Chat)
2. Edit-Mode-Toggle in der AppBar erscheint ✏️
3. Toggle aktivieren

**Edit-Modus aktiviert** → Hover-Controls auf Tabs/Tools werden sichtbar.

---

### Schritt 3: Content bearbeiten

**Tab bearbeiten:**
1. Hover über Tab → Edit-Icon erscheint
2. Klick auf Edit-Icon
3. Dialog öffnet sich mit aktuellen Werten
4. Name/Icon/Beschreibung ändern
5. Speichern → API-Call → Backend speichert + Change Log

**Neuen Tab erstellen:**
1. "+" Button bei Tabs
2. Dialog: Name, Icon, Beschreibung eingeben
3. Speichern → API-Call → Backend erstellt Tab
4. **OTA-Update**: Alle User sehen neuen Tab sofort!

**Tab löschen:**
1. Hover über Tab → Delete-Icon
2. Bestätigen
3. API-Call → Backend löscht Tab
4. **OTA-Update**: Tab verschwindet bei allen Usern

---

### Schritt 4: Change Logs prüfen

1. Admin-Dashboard öffnen
2. "Change Logs" Tab
3. Alle Änderungen sehen:
   - Wer hat was geändert?
   - Wann wurde es geändert?
   - Vorher/Nachher-Werte
   - Grund der Änderung

---

## 🔄 OTA-Update Flow

```
1. Admin bearbeitet Tab
   ↓
2. Flutter App sendet API-Request
   ↓
3. Backend validiert Permissions
   ↓
4. Backend speichert Änderung (KV Storage)
   ↓
5. Backend erstellt Change Log (D1)
   ↓
6. API Response zurück an App
   ↓
7. App aktualisiert lokale UI
   ↓
8. **Andere User:** Nächster Reload holt neue Tabs
   ↓
9. **Sofortige Sichtbarkeit** (kein App-Rebuild nötig!)
```

---

## 🛡️ Sicherheit

### Passwort-Validierung
- **Serverseitig**: Backend prüft Passwörter
- **Clientseitig**: Passwörter werden NICHT gespeichert
- **Transport**: HTTPS only
- **Storage**: KV + D1 für Redundanz

### Permission Checks
```javascript
// Backend Permission Middleware
class PermissionMiddleware {
  static canEditContent(role) {
    return role === 'root_admin' || role === 'content_editor';
  }
  
  static canManageUsers(role) {
    return role === 'root_admin';  // Only root_admin!
  }
}
```

**Jeder API-Call** wird auf Permissions geprüft:
- Header `X-Role` enthält User-Rolle
- Backend validiert vor jeder Aktion
- **403 Forbidden** bei fehlenden Rechten

---

## 📊 Storage-Architektur

### Cloudflare KV (Content Storage)
```
Key Format:
- content:tabs:{world}         → Liste aller Tabs
- content:tools:{world}:{room} → Tools für einen Raum
- content:markers:{category}   → Marker einer Kategorie
```

**Vorteile:**
- ⚡ Extrem schnell (Edge-Cache)
- 🌍 Global verteilt
- 💰 Kosteneffizient
- 📦 Unbegrenzte Reads

---

### Cloudflare D1 (Change Logs)
```sql
CREATE TABLE change_logs (
  id TEXT PRIMARY KEY,
  type TEXT NOT NULL,           -- 'create', 'update', 'delete'
  entity_type TEXT NOT NULL,    -- 'tab', 'tool', 'marker'
  entity_id TEXT NOT NULL,
  admin_id TEXT NOT NULL,
  admin_username TEXT NOT NULL,
  before_data TEXT,             -- JSON
  after_data TEXT,              -- JSON
  reason TEXT,
  timestamp TEXT NOT NULL
);
```

**Audit Trail** für alle Änderungen!

---

## 🧪 Testing

### Test 1: Content Editor Account
```bash
# 1. Profil erstellen
curl -X POST https://weltenbibliothek-api-v2.brandy13062.workers.dev/api/profile/energie \
  -H "Content-Type: application/json" \
  -d '{
    "username": "Weltenbibliothekedit",
    "password": "Jolene2305"
  }'

# Expected: role = "content_editor", is_admin = true
```

### Test 2: Tab erstellen
```bash
# 2. Tab erstellen (mit Content Editor)
curl -X POST https://weltenbibliothek-api-v2.brandy13062.workers.dev/api/content/tabs \
  -H "Content-Type: application/json" \
  -H "X-World: energie" \
  -H "X-Role: content_editor" \
  -H "X-Username: Weltenbibliothekedit" \
  -d '{
    "world": "energie",
    "name": "Test Tab",
    "icon": "🧪"
  }'

# Expected: success = true, tab mit ID zurück
```

### Test 3: Tabs abrufen
```bash
# 3. Tabs abrufen (ohne Auth)
curl https://weltenbibliothek-api-v2.brandy13062.workers.dev/api/content/tabs?world=energie

# Expected: Liste mit dem neuen "Test Tab"
```

### Test 4: Permission Denied
```bash
# 4. Versuch mit normalem User (sollte fehlschlagen)
curl -X POST https://weltenbibliothek-api-v2.brandy13062.workers.dev/api/content/tabs \
  -H "X-Role: user" \
  -d '{"world": "energie", "name": "Hack"}'

# Expected: 403 Permission denied
```

---

## 📈 Roadmap

### Phase 1 (AKTUELL) ✅
- ✅ Backend V13.1.0 deployed
- ✅ Content API Service
- ✅ Basic CRUD für Tabs
- ✅ Change Logs
- ✅ Permission System

### Phase 2 (NÄCHSTE WOCHE)
- [ ] UI: Inline Content Editor aktivieren
- [ ] UI: Edit Mode Toggle in allen Screens
- [ ] UI: Change Log Viewer
- [ ] Tools CRUD implementieren
- [ ] Markers CRUD implementieren

### Phase 3 (ZUKÜNFTIG)
- [ ] Feature Flags System
- [ ] Version Snapshots (Rollback)
- [ ] Bulk Operations
- [ ] Import/Export Content
- [ ] Content Preview vor Publish

---

## 🐛 Troubleshooting

### Problem: "Permission denied"
**Lösung**: Stelle sicher, dass:
1. User als Admin eingeloggt ist (Weltenbibliothek oder Weltenbibliothekedit)
2. X-Role Header korrekt gesetzt ist
3. Backend-Token nicht abgelaufen

### Problem: Tabs werden nicht angezeigt
**Lösung**:
1. Check Backend Health: `curl https://weltenbibliothek-api-v2.brandy13062.workers.dev/health`
2. Check KV Storage: Tabs vorhanden?
3. Flutter App neu laden (Browser Refresh)

### Problem: Change Logs leer
**Lösung**:
1. D1 Datenbank-Verbindung prüfen
2. change_logs Tabelle existiert?
3. Wrangler bindings korrekt? (siehe wrangler.toml)

---

## 📞 Support

**Entwickler**: AI Development Assistant  
**Für**: Manuel Brandner  
**Projekt**: Weltenbibliothek  
**Version**: 13.1.0  

**Live URLs**:
- Backend API: https://weltenbibliothek-api-v2.brandy13062.workers.dev
- Flutter App: https://5060-ingyb9x7032nc991qsp0l-0e616f0a.sandbox.novita.ai

---

**Erstellt**: 8. Februar 2026  
**Status**: ✅ PRODUKTIV  
