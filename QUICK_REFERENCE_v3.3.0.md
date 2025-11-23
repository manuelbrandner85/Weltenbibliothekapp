# 🚀 Quick Reference: v3.3.0 "1 Stream Pro Chat-Raum"

## 🎯 Was wurde geändert?

**Problem:** Mehrere User konnten gleichzeitig Streams im selben Chat erstellen.  
**Lösung:** Backend prüft jetzt, ob Chat-Raum bereits einen aktiven Stream hat.

---

## 📋 Änderungs-Checkliste

### Backend (Cloudflare)
- [x] `chat_room_id TEXT` Spalte zur `live_rooms` Tabelle hinzugefügt
- [x] Index `idx_live_rooms_chat_room_status` erstellt
- [x] `handleCreateLiveRoom()` mit 2-Stufen-Validierung:
  1. Chat-Raum-Check (neu)
  2. User-Check (bestehend)
- [x] `handleGetLiveRooms()` SELECT erweitert mit `chat_room_id`
- [x] 409 Error-Responses mit `error_type` für intelligente UI-Behandlung

### Flutter App
- [x] `LiveRoom.chatRoomId` Feld hinzugefügt
- [x] `createLiveRoom(chatRoomId: ...)` Parameter REQUIRED
- [x] Error-Handling mit `error_type` für 2 Fälle:
  - `chat_room_occupied`: Chat hat bereits Stream
  - `user_has_stream`: User hat Stream in anderem Chat
- [x] `TelegramLiveBanner` filtert nach `chatRoomId` (nicht `roomId`)
- [x] UI zeigt "Beitreten" / "Öffnen"-Buttons bei Konflikten

---

## 🔧 Migration Schnell-Guide

### 1️⃣ Datenbank migrieren
```bash
cd /home/user/flutter_app/cloudflare_backend
npx wrangler d1 execute weltenbibliothek --file=add_chat_room_id_migration.sql
```

### 2️⃣ Worker deployen
```bash
npx wrangler deploy weltenbibliothek_worker.js
```

### 3️⃣ Flutter App builden
```bash
cd /home/user/flutter_app
flutter clean && flutter pub get
flutter build apk --release
```

---

## 🧪 Test-Szenarien

| Szenario | User A | User B | Erwartetes Ergebnis |
|----------|--------|--------|---------------------|
| **Normal** | Öffnet "Allgemeiner Chat" → Stream starten | Öffnet "Allgemeiner Chat" → Sieht Banner → Joined | ✅ SUCCESS |
| **Chat besetzt** | Öffnet "Allgemeiner Chat" → Stream starten | Öffnet "Allgemeiner Chat" → Stream starten | ❌ 409: "user_a streamt bereits" + [Beitreten] |
| **User hat Stream** | Öffnet "Musik Chat" → Stream starten | (gleicher User) Öffnet "Allgemeiner Chat" → Stream starten | ❌ 409: "Du hast bereits Stream" + [Öffnen] |

---

## 📊 Code-Beispiele

### Backend: Neue Validierung
```javascript
// ZUERST: Chat-Raum-Check
const chatRoomStream = await env.DB.prepare(
  'SELECT room_id, host_username FROM live_rooms 
   WHERE chat_room_id = ? AND status = ?'
).bind(chatRoomId, 'live').first();

if (chatRoomStream) {
  return jsonResponse({ 
    error: 'Dieser Chat-Raum hat bereits einen aktiven Livestream',
    error_type: 'chat_room_occupied',
    existing_stream: { ... }
  }, 409);
}

// DANN: User-Check
const userActiveRoom = await env.DB.prepare(
  'SELECT room_id FROM live_rooms 
   WHERE host_user_id = ? AND status = ?'
).bind(user.id, 'live').first();
```

### Flutter: createLiveRoom Call
```dart
final result = await _liveRoomService.createLiveRoom(
  chatRoomId: widget.chatRoom.id, // ← NEU & REQUIRED
  title: 'Live: ${widget.chatRoom.name}',
  description: 'Live-Stream in ${widget.chatRoom.name}',
  category: 'chat',
);
```

### Flutter: Error-Handling
```dart
if (errorType == 'chat_room_occupied') {
  // Chat hat bereits Stream → Zeige "Beitreten"-Button
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('⚠️ $hostUsername streamt bereits in diesem Chat'),
      action: SnackBarAction(
        label: 'Beitreten',
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => LiveStreamViewerScreen(
              roomId: existingStream['room_id'],
              roomTitle: widget.chatRoom.name,
            ),
          ));
        },
      ),
    ),
  );
}
```

---

## ⚠️ Breaking Changes

### API-Änderung
**POST /api/live/rooms** benötigt jetzt `chatRoomId` im Request-Body!

**Alte Versionen (v3.2.0-):**
- ❌ Request ohne `chatRoomId` → `400 Bad Request`
- ❌ App wird nicht funktionieren nach Backend-Update

**Neue Version (v3.3.0+):**
- ✅ Request mit `chatRoomId` → Funktioniert
- ✅ Intelligentes Error-Handling

---

## 📁 Wichtige Dateien

| Datei | Typ | Beschreibung |
|-------|-----|--------------|
| `cloudflare_backend/add_chat_room_id_migration.sql` | NEU | SQL-Migration für D1 |
| `cloudflare_backend/weltenbibliothek_worker.js` | GEÄNDERT | Backend-Validierung |
| `lib/services/live_room_service.dart` | GEÄNDERT | Flutter Service mit chatRoomId |
| `lib/widgets/telegram_live_banner.dart` | GEÄNDERT | Filter nach chatRoomId |
| `lib/screens/chat_room_detail_screen.dart` | GEÄNDERT | UI Error-Handling |
| `BACKEND_MIGRATION_GUIDE.md` | NEU | Detaillierte Migration |
| `CHANGELOG_v3.3.0.md` | NEU | Vollständiger Changelog |

---

## 🚨 Häufige Fehler

### ❌ "400 Bad Request - Chat Room ID is required"
**Ursache:** Alte Flutter App-Version nach Backend-Update  
**Lösung:** App auf v3.3.0+ updaten

### ❌ "Live-Banner erscheint nicht"
**Ursache:** Banner filtert nach `chatRoomId`, aber DB hat NULL-Werte  
**Lösung:** Migration ausführen + bestehende Streams neu erstellen

### ❌ "Mehrere User können noch Streams erstellen"
**Ursache:** Backend nicht deployed oder Migration nicht ausgeführt  
**Lösung:** 
1. Migration prüfen: `PRAGMA table_info(live_rooms);` → `chat_room_id` vorhanden?
2. Worker neu deployen: `npx wrangler deploy`

---

## 📞 Support & Debugging

### Backend Logs prüfen
```bash
# Cloudflare Dashboard → Workers & Pages → weltenbibliothek → Logs
# Filter: "409" (Conflict Errors)
```

### Flutter Debug-Output
```dart
// In createLiveRoom() Error-Handling:
print('Error Type: ${result['error_type']}');
print('Existing Stream: ${result['existing_stream']}');
```

### Datenbank-Zustand prüfen
```sql
-- Cloudflare D1 Console
SELECT room_id, chat_room_id, host_username, status 
FROM live_rooms 
WHERE status = 'live';
```

---

## ✅ Verifizierung

Nach Migration und Deployment:

- [ ] D1-Schema hat `chat_room_id` Spalte
- [ ] Index `idx_live_rooms_chat_room_status` existiert
- [ ] Worker deployed (neue Version aktiv)
- [ ] Flutter App auf v3.3.0 geupdatet
- [ ] Test 1: Stream erstellen → SUCCESS
- [ ] Test 2: Zweiter Stream im gleichen Chat → 409 Error
- [ ] Test 3: SnackBar mit "Beitreten"-Button → Funktioniert
- [ ] Test 4: Live-Banner erscheint → Funktioniert
- [ ] Test 5: Banner verschwindet nach Stream-Ende → Funktioniert

---

**Version:** 3.3.0+44  
**Kritikalität:** 🔴 HIGH  
**Migrations-Zeit:** ⏱️ 10-15 Min  
**Rollback:** ✅ Möglich (siehe BACKEND_MIGRATION_GUIDE.md)
