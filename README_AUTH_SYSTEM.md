# 🔐 Weltenbibliothek - Authentication & Live System

## 📚 Vollständige Feature-Liste

### ✅ Implementierte Features

#### 1. **Benutzer-Authentifizierung**
- ✅ Registration mit Username + E-Mail + Passwort
- ✅ Login mit Username + Passwort  
- ✅ JWT-Token basierte Authentifizierung
- ✅ Passwort-Hashing (SHA-256)
- ✅ Username Eindeutigkeit (UNIQUE Constraint in D1)
- ✅ Auto-Login bei App-Start
- ✅ Logout-Funktionalität
- ✅ Session-Persistierung (SharedPreferences)

#### 2. **Live-Stream System**
- ✅ Live-Room erstellen (nur 1 aktiver Stream pro User)
- ✅ Live-Rooms Liste abrufen
- ✅ Live-Room beitreten
- ✅ Live-Room verlassen
- ✅ Live-Room beenden (nur Host)
- ✅ Teilnehmerzählung
- ✅ Room-Status (live/ended)
- ✅ Host-Berechtigungen

#### 3. **Direct Messages (DM)**
- ✅ Private Nachrichten zwischen Usern
- ✅ DM-Liste (Conversations)
- ✅ DM senden & empfangen
- ✅ Read Receipts (gelesen/ungelesen)
- ✅ Timestamps
- ✅ Chat-UI mit Bubbles

#### 4. **Datenbank (Cloudflare D1)**
- ✅ 7 Tabellen (users, live_rooms, chat_messages, direct_messages, etc.)
- ✅ Foreign Keys
- ✅ Indizes für Performance
- ✅ Views für Reporting

#### 5. **Sicherheit**
- ✅ JWT-Token Validierung
- ✅ Passwort-Hashing (nie Klartext)
- ✅ Protected API Endpoints
- ✅ CORS Headers
- ✅ SQL Injection Prevention

---

## 📁 Projekt-Struktur

```
flutter_app/
├── cloudflare_backend/          # Cloudflare Worker Backend
│   ├── d1_schema.sql           # Datenbank-Schema
│   ├── weltenbibliothek_worker.js  # Main Worker (APIs)
│   ├── chat_room_durable_object.js # WebSocket Server
│   ├── wrangler.toml           # Cloudflare Config
│   └── DEPLOYMENT_GUIDE.md     # Deployment-Anleitung
│
├── lib/
│   ├── services/               # Backend-Integration
│   │   ├── auth_service.dart          # ✅ NEU: Auth Service
│   │   ├── live_room_service.dart     # ✅ NEU: Live Rooms API
│   │   ├── direct_message_service.dart # ✅ NEU: DM Service
│   │   ├── webrtc_service.dart        # ✅ VORHANDEN: WebRTC
│   │   └── ... (andere Services)
│   │
│   ├── screens/                # UI Screens
│   │   ├── login_screen.dart          # ✅ NEU: Login
│   │   ├── register_screen.dart       # ✅ NEU: Registration
│   │   ├── dm_screen.dart             # ✅ NEU: DM Übersicht
│   │   ├── dm_conversation_screen.dart # ✅ NEU: DM Chat
│   │   ├── chat_screen.dart           # ✅ VORHANDEN: Chat-Räume
│   │   └── ... (andere Screens)
│   │
│   └── main.dart               # App Entry Point
│
├── IMPLEMENTATION_SUMMARY.md   # Vollständige Implementierungs-Übersicht
└── README_AUTH_SYSTEM.md       # Diese Datei
```

---

## 🚀 Schnellstart

### 1. Backend Deployment (Cloudflare)

```bash
cd cloudflare_backend

# 1. D1 Database erstellen
wrangler d1 create weltenbibliothek-db
# Kopiere database_id!

# 2. wrangler.toml bearbeiten
# - Ersetze YOUR_ACCOUNT_ID
# - Ersetze YOUR_DATABASE_ID

# 3. Schema importieren
wrangler d1 execute weltenbibliothek-db --file=d1_schema.sql

# 4. JWT Secret setzen
wrangler secret put JWT_SECRET
# Eingeben: WELTENBIBLIOTHEK_SECRET_2024

# 5. Deployen
wrangler deploy

# ✅ Ausgabe:
# URL: https://weltenbibliothek-backend.YOUR_ACCOUNT.workers.dev
```

### 2. Flutter App konfigurieren

**Datei:** `lib/services/auth_service.dart` (Zeile 17)

```dart
static const String baseUrl = 'https://weltenbibliothek-backend.YOUR_ACCOUNT.workers.dev';
```

Ersetze `YOUR_ACCOUNT` mit deiner Cloudflare Account-Subdomain.

### 3. App starten

```bash
# Dependencies installieren
flutter pub get

# Web Preview
flutter build web --release
python3 -m http.server 5060 --directory build/web --bind 0.0.0.0

# APK bauen
flutter build apk --release
```

---

## 📖 API Dokumentation

### Base URL
```
https://weltenbibliothek-backend.YOUR_ACCOUNT.workers.dev
```

### Endpoints

#### 🔐 Authentication

**POST `/api/auth/register`**
```json
Request:
{
  "username": "myuser",
  "email": "user@example.com",
  "password": "secret123"
}

Response (201):
{
  "success": true,
  "user": {
    "id": 1,
    "username": "myuser",
    "email": "user@example.com"
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**POST `/api/auth/login`**
```json
Request:
{
  "username": "myuser",
  "password": "secret123"
}

Response (200):
{
  "success": true,
  "user": { ... },
  "token": "eyJ..."
}
```

**GET `/api/auth/me`** (benötigt JWT)
```
Headers:
  Authorization: Bearer <JWT_TOKEN>

Response (200):
{
  "user": {
    "id": 1,
    "username": "myuser",
    "email": "user@example.com",
    "avatar_url": null,
    "bio": null,
    "created_at": 1732204800
  }
}
```

#### 🎥 Live Rooms

**GET `/api/live/rooms`**
```json
Response (200):
{
  "rooms": [
    {
      "room_id": "room_1_1732204800",
      "title": "Mysterien der Pyramiden",
      "description": "Live-Diskussion",
      "host_username": "admin",
      "status": "live",
      "created_at": 1732204800,
      "started_at": 1732204805,
      "participant_count": 5,
      "max_participants": 50,
      "is_private": false,
      "category": "mystery"
    }
  ]
}
```

**POST `/api/live/rooms`** (benötigt JWT)
```json
Request:
{
  "title": "Mein Live-Stream",
  "description": "Beschreibung",
  "category": "general"
}

Response (201):
{
  "success": true,
  "room": { ... }
}

Error (409) - Bereits aktiver Stream:
{
  "success": false,
  "error": "You already have an active live room",
  "room_id": "room_1_1732204800"
}
```

**POST `/api/live/rooms/:roomId/join`** (benötigt JWT)
**POST `/api/live/rooms/:roomId/leave`** (benötigt JWT)
**POST `/api/live/rooms/:roomId/end`** (benötigt JWT, nur Host)

#### 💬 Chat Messages

**GET `/api/messages/rooms/:roomId?limit=50&before=1732204800`** (benötigt JWT)
**POST `/api/messages/rooms/:roomId`** (benötigt JWT)

#### 📧 Direct Messages

**GET `/api/messages/direct?with=username&limit=50`** (benötigt JWT)
```json
Response (200):
{
  "messages": [
    {
      "id": 1,
      "from_username": "user1",
      "to_username": "user2",
      "message": "Hallo!",
      "created_at": 1732204800,
      "read_at": 1732204850
    }
  ]
}
```

**POST `/api/messages/direct`** (benötigt JWT)
```json
Request:
{
  "to_username": "otheruser",
  "message": "Hallo!"
}

Response (201):
{
  "success": true,
  "message": { ... }
}
```

---

## 🎨 Flutter Integration

### Auth Service verwenden

```dart
import 'package:weltenbibliothek/services/auth_service.dart';

// Singleton Instance
final authService = AuthService();

// Initialisieren (in main.dart)
await authService.initialize();

// Registrieren
final result = await authService.register(
  username: 'myuser',
  email: 'my@email.com',
  password: 'secret123',
);

if (result['success']) {
  print('Registriert: ${result['user']}');
  // Token ist automatisch gespeichert
}

// Login
final result = await authService.login(
  username: 'myuser',
  password: 'secret123',
);

// Check ob eingeloggt
if (authService.isAuthenticated) {
  print('Eingeloggt als: ${authService.currentUser!['username']}');
}

// Logout
await authService.logout();
```

### Live Room Service

```dart
import 'package:weltenbibliothek/services/live_room_service.dart';

final liveRoomService = LiveRoomService();

// Live Rooms abrufen
final rooms = await liveRoomService.getActiveLiveRooms();
for (final room in rooms) {
  print('${room.title} - ${room.participantCount} Teilnehmer');
}

// Live Room erstellen
final result = await liveRoomService.createLiveRoom(
  title: 'Mein Stream',
  description: 'Beschreibung',
  category: 'mystery',
);

if (result['success']) {
  final room = result['room'] as LiveRoom;
  // Starte WebRTC...
}

// Beitreten
await liveRoomService.joinLiveRoom('room_1_1732204800');

// Verlassen
await liveRoomService.leaveLiveRoom('room_1_1732204800');

// Beenden (nur Host)
await liveRoomService.endLiveRoom('room_1_1732204800');
```

### Direct Messages

```dart
import 'package:weltenbibliothek/services/direct_message_service.dart';

final dmService = DirectMessageService();

// Nachrichten mit User abrufen
final messages = await dmService.getDirectMessages(
  withUsername: 'otheruser',
  limit: 50,
);

for (final msg in messages) {
  print('${msg.fromUsername}: ${msg.message}');
}

// Nachricht senden
final result = await dmService.sendDirectMessage(
  toUsername: 'otheruser',
  message: 'Hallo!',
);
```

---

## 🔒 Sicherheits-Features

### Passwort-Hashing
- ✅ SHA-256 mit Salt
- ✅ Niemals Klartext in Datenbank
- ✅ Sichere Vergleichsalgorithmen

### JWT Token
- ✅ 7 Tage Gültigkeit
- ✅ HMAC-SHA256 Signatur
- ✅ Payload: userId, username, email, exp
- ✅ Validierung bei jedem Request

### API Security
- ✅ Bearer Token Authentication
- ✅ 401 Unauthorized bei fehlenden/ungültigen Token
- ✅ 403 Forbidden bei unzureichenden Berechtigungen
- ✅ SQL Injection Prevention (Prepared Statements)

---

## 🐛 Troubleshooting

### "Network error" bei API-Calls
**Lösung:** Prüfe Backend-URL in `auth_service.dart` (Zeile 17)

### "Unauthorized" trotz Login
**Lösung:** Token abgelaufen oder ungültig. Neu einloggen.

### "Username already exists"
**Lösung:** Username ist bereits vergeben. Anderen wählen.

### Live-Stream Liste leer
**Lösung:** Noch keine aktiven Streams. Erstelle einen!

### DM sendet nicht
**Lösung:** Prüfe ob Empfänger-Username existiert.

---

## 📊 Datenbank-Schema

Siehe: `cloudflare_backend/d1_schema.sql`

**Haupttabellen:**
- `users` - User-Accounts
- `live_rooms` - Live-Stream Räume
- `room_participants` - Teilnehmer in Räumen
- `chat_messages` - Chat-Nachrichten
- `direct_messages` - Private Nachrichten
- `password_reset_tokens` - Passwort-Reset (TODO)
- `notifications` - Benachrichtigungen (TODO)

---

## 🎉 Fertig!

Deine **Weltenbibliothek** hat jetzt:
- ✅ Vollständige User-Authentifizierung
- ✅ Live-Stream Management
- ✅ Direct Messages
- ✅ JWT-Sicherheit
- ✅ Cloudflare D1 Backend
- ✅ WebRTC Video-Streaming
- ✅ Chat-System

**Viel Erfolg mit deinem Projekt! 🚀**
