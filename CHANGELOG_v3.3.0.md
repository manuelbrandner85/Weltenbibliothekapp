# 📝 Changelog v3.3.0 - "1 Stream Pro Chat-Raum" Update

## 🎯 Hauptziel
**Problem behoben:** Mehrere User konnten gleichzeitig Streams im selben Chat-Raum erstellen.  
**Lösung:** Backend-Validierung implementiert, die nur **1 aktiven Stream pro Chat-Raum** erlaubt.

---

## 🔧 Backend-Änderungen

### 1. Datenbank-Schema (D1)

**Neue Spalte:** `chat_room_id TEXT`
```sql
ALTER TABLE live_rooms ADD COLUMN chat_room_id TEXT;
```

**Neuer Index:** Schnelle Suche nach Chat-Raum + Status
```sql
CREATE INDEX idx_live_rooms_chat_room_status 
ON live_rooms(chat_room_id, status);
```

### 2. Worker API (`weltenbibliothek_worker.js`)

#### Funktion: `handleCreateLiveRoom()`
**Änderungen:**
- ✅ Neuer Request-Parameter: `chatRoomId` (REQUIRED)
- ✅ Erste Validierung: Prüft ob Chat-Raum bereits Stream hat
- ✅ Zweite Validierung: Prüft ob User bereits Stream in anderem Chat hat
- ✅ INSERT Statement erweitert mit `chat_room_id`

**Vor:**
```javascript
const { title, description, category } = await request.json();

// Nur User-Check
const existingRoom = await env.DB.prepare(
  'SELECT room_id FROM live_rooms WHERE host_user_id = ? AND status = ?'
).bind(user.id, 'live').first();
```

**Nach:**
```javascript
const { title, description, category, chatRoomId } = await request.json();

// Chat-Raum-Check ZUERST
const chatRoomStream = await env.DB.prepare(
  'SELECT room_id, host_username, host_user_id 
   FROM live_rooms WHERE chat_room_id = ? AND status = ?'
).bind(chatRoomId, 'live').first();

if (chatRoomStream) {
  return jsonResponse({ 
    error: 'Dieser Chat-Raum hat bereits einen aktiven Livestream',
    existing_stream: { ... }
  }, 409);
}

// DANN User-Check
const userActiveRoom = await env.DB.prepare(
  'SELECT room_id, chat_room_id 
   FROM live_rooms WHERE host_user_id = ? AND status = ?'
).bind(user.id, 'live').first();
```

#### Funktion: `handleGetLiveRooms()`
**Änderungen:**
- ✅ SELECT erweitert mit `lr.chat_room_id`

**Vor:**
```javascript
SELECT lr.room_id, lr.title, lr.description, ...
```

**Nach:**
```javascript
SELECT lr.room_id, lr.chat_room_id, lr.title, lr.description, ...
```

---

## 📱 Flutter App Änderungen

### 1. Model: `LiveRoom` (`lib/services/live_room_service.dart`)

**Neues Feld:**
```dart
class LiveRoom {
  final String? chatRoomId; // ← NEU: Chat room ID
  // ... andere Felder
  
  LiveRoom({
    required this.roomId,
    this.chatRoomId, // ← Nullable, da alte Streams kein chatRoomId haben
    // ...
  });
  
  factory LiveRoom.fromJson(Map<String, dynamic> json) {
    return LiveRoom(
      roomId: json['room_id'] as String,
      chatRoomId: json['chat_room_id'] as String?, // ← Parse from backend
      // ...
    );
  }
}
```

### 2. Service: `createLiveRoom()` (`lib/services/live_room_service.dart`)

**Signatur-Änderung:**
```dart
// Vor
Future<Map<String, dynamic>> createLiveRoom({
  required String title,
  String? description,
  String? category,
})

// Nach
Future<Map<String, dynamic>> createLiveRoom({
  required String chatRoomId, // ← NEU & REQUIRED
  required String title,
  String? description,
  String? category,
})
```

**Request-Body erweitert:**
```dart
final response = await _authService.authenticatedPost(
  '/api/live/rooms',
  {
    'chatRoomId': chatRoomId, // ← Sende an Backend
    'title': title,
    'description': description ?? '',
    'category': category ?? 'general',
  },
);
```

**Besseres Error-Handling:**
```dart
else if (response.statusCode == 409) {
  final errorMessage = data['error'] as String?;
  
  if (errorMessage != null && errorMessage.contains('Chat-Raum')) {
    // Chat room occupied
    return {
      'success': false,
      'error': errorMessage,
      'error_type': 'chat_room_occupied', // ← Typ für UI-Logik
      'existing_stream': data['existing_stream'],
    };
  } else {
    // User has stream elsewhere
    return {
      'success': false,
      'error': errorMessage,
      'error_type': 'user_has_stream', // ← Typ für UI-Logik
      'existing_room': data['existing_room'],
    };
  }
}
```

### 3. Widget: `TelegramLiveBanner` (`lib/widgets/telegram_live_banner.dart`)

**Filter-Logik korrigiert:**
```dart
// Vor (FALSCH - filterte nach liveRoomId)
final activeLiveRoom = liveRooms.cast<LiveRoom?>().firstWhere(
  (room) => room?.roomId == widget.roomId && room?.isLive == true,
  orElse: () => null,
);

// Nach (RICHTIG - filtert nach chatRoomId)
final activeLiveRoom = liveRooms.cast<LiveRoom?>().firstWhere(
  (room) => room?.chatRoomId == widget.roomId && room?.isLive == true,
  orElse: () => null,
);
```

**Wichtig:** `widget.roomId` ist die **Chat-Raum-ID** (z.B. "allgemeiner_chat"), NICHT die Live-Stream-ID!

### 4. Screen: `ChatRoomDetailScreen` (`lib/screens/chat_room_detail_screen.dart`)

**createLiveRoom Call aktualisiert:**
```dart
final result = await _liveRoomService.createLiveRoom(
  chatRoomId: widget.chatRoom.id, // ← Chat Room ID übergeben
  title: 'Live: ${widget.chatRoom.name}',
  description: 'Live-Stream in ${widget.chatRoom.name}',
  category: 'chat',
);
```

**Intelligente Error-Behandlung:**
```dart
if (result['success'] == true) {
  // Navigate to host screen
} else {
  final errorType = result['error_type'] as String?;
  
  if (errorType == 'chat_room_occupied') {
    // SnackBar mit "Beitreten"-Button
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
  } else if (errorType == 'user_has_stream') {
    // SnackBar mit "Öffnen"-Button zu eigenem Stream
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['error']),
        action: SnackBarAction(
          label: 'Öffnen',
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) => LiveStreamHostScreen(
                roomId: existingRoom['room_id'],
                roomTitle: widget.chatRoom.name,
              ),
            ));
          },
        ),
      ),
    );
  }
}
```

### 5. Screen: `LiveStreamsScreen` (`lib/screens/live_streams_screen.dart`)

**Allgemeine Livestreams (nicht Chat-gebunden):**
```dart
final createResult = await _liveRoomService.createLiveRoom(
  chatRoomId: 'general_livestream', // ← Standard für allgemeine Streams
  title: titleController.text.trim(),
  description: descriptionController.text.trim(),
  category: selectedCategory,
);
```

---

## 🧪 Testing-Checklist

### ✅ Backend Tests (Cloudflare)
- [ ] Migration erfolgreich ausgeführt (`chat_room_id` Spalte existiert)
- [ ] Index erstellt (`idx_live_rooms_chat_room_status`)
- [ ] Worker deployed (neue Version aktiv)

### ✅ Flutter App Tests
- [ ] Stream erstellen in "Allgemeiner Chat" → Erfolgreich
- [ ] Zweiter User versucht Stream in "Allgemeiner Chat" → 409 Error mit SnackBar
- [ ] SnackBar "Beitreten"-Button → Öffnet Viewer Screen
- [ ] User erstellt Stream in "Musik Chat" → Erfolgreich
- [ ] Gleicher User versucht Stream in "Allgemeiner Chat" → 409 Error
- [ ] SnackBar "Öffnen"-Button → Öffnet Host Screen von existierendem Stream
- [ ] Live Banner erscheint wenn Stream aktiv
- [ ] Live Banner verschwindet 3s nach Stream-Ende

---

## 📊 Geänderte Dateien

### Backend
```
cloudflare_backend/
├── add_chat_room_id_migration.sql (NEU)
└── weltenbibliothek_worker.js (GEÄNDERT)
    ├── handleCreateLiveRoom() - Zeile 334-422
    └── handleGetLiveRooms() - Zeile 305-328
```

### Flutter
```
lib/
├── services/
│   └── live_room_service.dart (GEÄNDERT)
│       ├── LiveRoom class - chatRoomId Feld
│       ├── createLiveRoom() - chatRoomId Parameter
│       └── Error handling erweitert
├── screens/
│   ├── chat_room_detail_screen.dart (GEÄNDERT)
│   │   └── _startLiveStream() - Zeile 390-465
│   └── live_streams_screen.dart (GEÄNDERT)
│       └── _createNewStream() - Zeile 190-217
└── widgets/
    └── telegram_live_banner.dart (GEÄNDERT)
        └── _checkActiveLiveRoom() - Zeile 63-87
```

### Dokumentation
```
/
├── BACKEND_MIGRATION_GUIDE.md (NEU)
└── CHANGELOG_v3.3.0.md (NEU - diese Datei)
```

---

## 🚀 Deployment-Schritte

### 1. Backend Migration
```bash
cd /home/user/flutter_app/cloudflare_backend
npx wrangler d1 execute weltenbibliothek --file=add_chat_room_id_migration.sql
npx wrangler deploy weltenbibliothek_worker.js
```

### 2. Flutter App Update
```bash
cd /home/user/flutter_app
flutter clean
flutter pub get
flutter build apk --release
```

### 3. Verifizierung
- ✅ Backend Logs prüfen (Cloudflare Dashboard)
- ✅ Live-Test mit 2 Usern durchführen
- ✅ Error-Handling testen (409 Responses)

---

## 🔄 Breaking Changes

### ⚠️ API-Änderung
**POST /api/live/rooms** benötigt jetzt `chatRoomId` Parameter!

**Alte Flutter Versionen (v3.2.0 und früher):**
- ❌ Werden **NICHT** funktionieren nach Backend-Update
- ❌ Fehler: `400 Bad Request - Chat Room ID is required`

**Lösung:** Alle Clients auf v3.3.0+ updaten!

---

## 📈 Auswirkungen

### Vor v3.3.0
- ❌ User A und User B können beide Streams in "Allgemeiner Chat" erstellen
- ❌ Banner zeigt beide Streams (verwirrend)
- ❌ Viewer wissen nicht, welchem Stream sie beitreten sollen

### Nach v3.3.0
- ✅ Nur 1 Stream pro Chat-Raum möglich
- ✅ Klare Fehlermeldung wenn Chat besetzt
- ✅ "Beitreten"-Button für schnellen Viewer-Join
- ✅ Banner zeigt immer den richtigen Stream für diesen Chat

---

## 🎉 User Experience Verbesserungen

### Szenario: User versucht Stream in besetztem Chat zu erstellen

**Vorher:**
```
User klickt "Live starten"
→ Stream wird erstellt
→ Zwei Streams existieren parallel
→ Chaos! 😵
```

**Nachher:**
```
User klickt "Live starten"
→ SnackBar: "⚠️ manuel_brandner streamt bereits in diesem Chat"
→ [Beitreten]-Button angezeigt
→ User klickt → Joined als Viewer
→ Perfekt! ✅
```

---

**Version:** 3.3.0  
**Release-Datum:** 2025-01-XX  
**Kritikalität:** 🔴 HIGH (Breaking Changes)  
**Migrations-Aufwand:** ⏱️ 10-15 Minuten  
**Rollback-Möglichkeit:** ✅ Ja (siehe BACKEND_MIGRATION_GUIDE.md)
