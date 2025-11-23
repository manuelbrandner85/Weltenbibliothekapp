# 🚀 Backend Migration Guide: Chat Room ID Integration

## 📋 Übersicht

Diese Migration implementiert die **"1 Stream pro Chat-Raum"** Regel durch Hinzufügen eines `chat_room_id` Feldes zur `live_rooms` Tabelle.

## ⚠️ WICHTIG: Cloudflare D1 Datenbank-Migration ERFORDERLICH

**DIESE MIGRATION IST KRITISCH** - Ohne sie wird die neue Validierung fehlschlagen!

---

## 🔧 Schritt 1: Datenbank-Schema aktualisieren

### Option A: Über Cloudflare CLI (Empfohlen)

```bash
# Navigiere zum Backend-Verzeichnis
cd /home/user/flutter_app/cloudflare_backend

# Führe die Migration aus
npx wrangler d1 execute weltenbibliothek --file=add_chat_room_id_migration.sql
```

### Option B: Über Cloudflare Dashboard (Manuell)

1. Gehe zu **Cloudflare Dashboard** → **Workers & Pages** → **D1**
2. Wähle deine **weltenbibliothek** Datenbank
3. Öffne **Console** Tab
4. Führe folgende SQL-Befehle aus:

```sql
-- Add chat_room_id column
ALTER TABLE live_rooms ADD COLUMN chat_room_id TEXT;

-- Create index for fast lookups
CREATE INDEX IF NOT EXISTS idx_live_rooms_chat_room_status 
ON live_rooms(chat_room_id, status);
```

---

## 🚀 Schritt 2: Worker Code deployen

```bash
cd /home/user/flutter_app/cloudflare_backend

# Deploy updated worker
npx wrangler deploy weltenbibliothek_worker.js
```

---

## 📊 Neue Backend-Validierung

### Vor der Migration:
```javascript
// ❌ Alte Validierung: Nur User-Check
const existingRoom = await env.DB.prepare(
  'SELECT room_id FROM live_rooms WHERE host_user_id = ? AND status = ?'
).bind(user.id, 'live').first();
```

**Problem:** User A und User B können beide Streams im "Allgemeiner Chat" erstellen

### Nach der Migration:
```javascript
// ✅ Neue Validierung: Chat-Raum-Check ZUERST
const chatRoomStream = await env.DB.prepare(
  'SELECT room_id, host_username FROM live_rooms 
   WHERE chat_room_id = ? AND status = ?'
).bind(chatRoomId, 'live').first();

if (chatRoomStream) {
  return jsonResponse({ 
    error: 'Dieser Chat-Raum hat bereits einen aktiven Livestream',
    existing_stream: { ... }
  }, 409);
}
```

**Lösung:** Pro Chat-Raum nur 1 Stream möglich! ✅

---

## 🧪 Testing-Szenarien

### Szenario 1: Normaler Flow (Erfolgreich)
1. **User A** öffnet "Allgemeiner Chat" → Startet Stream ✅
2. **User B** öffnet "Allgemeiner Chat" → Sieht Banner → Joined als Viewer ✅

### Szenario 2: Chat-Raum bereits besetzt (409 Conflict)
1. **User A** öffnet "Allgemeiner Chat" → Startet Stream ✅
2. **User B** öffnet "Allgemeiner Chat" → Versucht Stream zu starten ❌
3. **Backend Response:**
```json
{
  "error": "Dieser Chat-Raum hat bereits einen aktiven Livestream",
  "error_type": "chat_room_occupied",
  "existing_stream": {
    "room_id": "room_1_1234567890",
    "host_username": "user_a"
  }
}
```
4. **Flutter App:** Zeigt SnackBar mit "Beitreten"-Button ✅

### Szenario 3: User hat Stream in anderem Chat (409 Conflict)
1. **User A** öffnet "Musik Chat" → Startet Stream ✅
2. **User A** öffnet "Allgemeiner Chat" → Versucht zweiten Stream ❌
3. **Backend Response:**
```json
{
  "error": "Du hast bereits einen aktiven Livestream in einem anderen Chat",
  "error_type": "user_has_stream",
  "existing_room": {
    "room_id": "room_1_1234567890",
    "chat_room_id": "musik_chat"
  }
}
```
4. **Flutter App:** Zeigt SnackBar mit "Öffnen"-Button zu existierendem Stream ✅

---

## 📱 Flutter App Änderungen (Bereits implementiert)

### 1. LiveRoom Model erweitert
```dart
class LiveRoom {
  final String? chatRoomId; // ← NEU
  // ... andere Felder
}
```

### 2. createLiveRoom benötigt jetzt chatRoomId
```dart
await _liveRoomService.createLiveRoom(
  chatRoomId: widget.chatRoom.id, // ← REQUIRED
  title: 'Live: ${widget.chatRoom.name}',
  // ...
);
```

### 3. Bessere Error-Behandlung
```dart
if (errorType == 'chat_room_occupied') {
  // Zeige "Beitreten"-Button
} else if (errorType == 'user_has_stream') {
  // Zeige "Öffnen"-Button zu existierendem Stream
}
```

---

## 🔍 Verifizierung nach Migration

### Test 1: Datenbank-Schema prüfen
```sql
-- In Cloudflare D1 Console
PRAGMA table_info(live_rooms);
```

**Erwartete Ausgabe:** Spalte `chat_room_id` sollte vorhanden sein

### Test 2: Index prüfen
```sql
-- In Cloudflare D1 Console
PRAGMA index_list(live_rooms);
```

**Erwartete Ausgabe:** Index `idx_live_rooms_chat_room_status` sollte existieren

### Test 3: Live-Test mit Flutter App
1. Deploy Backend und starte Flutter App neu
2. Erstelle Stream in "Allgemeiner Chat" mit User A
3. Versuche Stream in "Allgemeiner Chat" mit User B zu erstellen
4. **Erwartetes Ergebnis:** User B sieht SnackBar "user_a streamt bereits in diesem Chat"

---

## 🚨 Rollback-Plan (Falls Migration fehlschlägt)

### Schritt 1: Backend-Code zurücksetzen
```bash
cd /home/user/flutter_app/cloudflare_backend
git checkout HEAD~1 weltenbibliothek_worker.js
npx wrangler deploy weltenbibliothek_worker.js
```

### Schritt 2: Datenbank-Spalte entfernen (Optional)
```sql
-- WARNUNG: SQLite unterstützt ALTER TABLE DROP COLUMN nicht!
-- Stattdessen: Spalte einfach ignorieren (kein Schaden)
```

### Schritt 3: Flutter App Version zurücksetzen
```bash
cd /home/user/flutter_app
git checkout HEAD~1 lib/
flutter clean && flutter pub get
```

---

## 📚 Zusammenfassung

| Komponente | Änderung | Status |
|------------|----------|--------|
| **D1 Schema** | `chat_room_id` Spalte + Index | ⏳ Migration erforderlich |
| **Worker Backend** | Doppelte Validierung (Chat + User) | ✅ Code bereit |
| **Flutter Model** | `LiveRoom.chatRoomId` Feld | ✅ Implementiert |
| **Flutter Service** | `chatRoomId` Parameter required | ✅ Implementiert |
| **UI Error Handling** | Intelligente Fehlerbehandlung | ✅ Implementiert |

---

## 💡 Nächste Schritte

1. ✅ **Migration ausführen** (SQL-Befehle in D1)
2. ✅ **Worker deployen** (`npx wrangler deploy`)
3. ✅ **Flutter App neu starten** (Cache löschen: `flutter clean`)
4. ✅ **Live-Test durchführen** (2 User, gleicher Chat)
5. ✅ **Monitoring prüfen** (Cloudflare Logs für 409 Errors)

---

## 🔗 Verwandte Dateien

- **Migration SQL:** `/home/user/flutter_app/cloudflare_backend/add_chat_room_id_migration.sql`
- **Backend Worker:** `/home/user/flutter_app/cloudflare_backend/weltenbibliothek_worker.js` (Lines 334-422)
- **Flutter Service:** `/home/user/flutter_app/lib/services/live_room_service.dart`
- **Flutter Screen:** `/home/user/flutter_app/lib/screens/chat_room_detail_screen.dart`
- **Banner Widget:** `/home/user/flutter_app/lib/widgets/telegram_live_banner.dart`

---

**Version:** 3.3.0 (Post-Migration)  
**Datum:** 2025-01-XX  
**Autor:** AI Assistant  
**Review:** ⏳ Pending User Testing
