# 📦 WELTENBIBLIOTHEK - COMPLETE RESTORATION GUIDE

## 🎯 UMFASSENDES BACKUP v3.9.2

**Backup-Datum**: 22. November 2025, 02:40 UTC  
**Version**: 3.9.2+48  
**Backup-Größe**: 426 MB (komprimiert)  
**Download-Link**: https://www.genspark.ai/api/files/s/al4I4HNn

---

## 📋 **BACKUP INHALT - VOLLSTÄNDIGE LISTE**

### **1. Flutter Projekt (Quellcode)**
```
lib/
├── main.dart                          # App Entry Point
├── models/                            # Datenmodelle
│   ├── chat_room_model.dart
│   ├── live_room_model.dart
│   ├── user_model.dart
│   └── room_connection_state.dart
├── screens/                           # UI Screens
│   ├── chat_screen.dart
│   ├── chat_room_detail_screen.dart
│   ├── live_stream_host_screen.dart
│   ├── live_stream_viewer_screen.dart
│   ├── login_screen.dart
│   ├── register_screen.dart
│   └── home_screen.dart
├── services/                          # Business Logic
│   ├── auth_service.dart              # Authentifizierung
│   ├── cloudflare_chat_service.dart   # Chat-Backend
│   ├── webrtc_broadcast_service.dart  # Livestream-Logik
│   ├── live_room_service.dart         # Room-Management
│   ├── bandwidth_monitor.dart         # Monitoring
│   └── auto_reconnect_manager.dart    # Reconnection
├── providers/                         # State Management
│   └── chat_provider.dart
└── widgets/                           # Wiederverwendbare Widgets
    ├── chat_background_carousel.dart  # Auto-Carousel (v3.9.2)
    ├── themed_chat_background.dart
    └── telegram_voice_chat_widget.dart
```

### **2. Assets (Medien & Ressourcen)**
```
assets/
├── images/
│   ├── app_icon.png                   # App Icon (192x192)
│   ├── logo.png                       # Weltenbibliothek Logo
│   ├── chat_backgrounds/              # Chat Hintergründe
│   │   ├── weltenbibliothek_1.jpg
│   │   ├── weltenbibliothek_2.jpg
│   │   ├── weltenbibliothek_3.jpg
│   │   ├── musik_1.jpg
│   │   ├── musik_2.jpg
│   │   ├── musik_3.jpg
│   │   ├── verschwoerung_1.jpg
│   │   ├── verschwoerung_2.jpg
│   │   └── verschwoerung_3.jpg
│   └── placeholder/                   # Platzhalter-Bilder
└── fonts/                             # Custom Fonts (falls vorhanden)
```

### **3. Cloudflare Backend (Workers + D1)**
```
cloudflare_backend/
├── weltenbibliothek_worker.js         # Haupt-Worker (v3.8.0)
│   ├── User Authentication API
│   ├── Chat Room Management
│   ├── Live Room Operations (Telegram-Style)
│   ├── WebSocket Signaling
│   └── Database Operations
├── wrangler.toml                      # Cloudflare Config
│   ├── Worker Name: weltenbibliothek-webrtc
│   ├── Database: weltenbibliothek-db (D1)
│   └── Durable Objects: ChatRoom
└── schema.sql                         # Datenbank-Schema
```

### **4. Datenbank-Schemas (D1 SQLite)**
```sql
-- users Tabelle
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- chat_rooms Tabelle
CREATE TABLE chat_rooms (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  created_by TEXT NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- messages Tabelle
CREATE TABLE messages (
  id TEXT PRIMARY KEY,
  chat_room_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  username TEXT NOT NULL,
  content TEXT NOT NULL,
  timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- live_rooms Tabelle (Telegram-Style)
CREATE TABLE live_rooms (
  room_id TEXT PRIMARY KEY,
  chat_room_id TEXT UNIQUE NOT NULL,
  host_username TEXT NOT NULL,
  host_user_id TEXT NOT NULL,
  original_host_id TEXT NOT NULL,
  current_host_id TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  status TEXT DEFAULT 'live',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- live_participants Tabelle
CREATE TABLE live_participants (
  id TEXT PRIMARY KEY,
  room_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  username TEXT NOT NULL,
  role TEXT NOT NULL,
  joined_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### **5. Build Artefakte**
```
build/
├── app/outputs/apk/release/
│   └── app-release.apk                # Latest APK (v3.9.2)
├── web/                               # Web Build
└── flutter_assets/                    # Kompilierte Assets
```

### **6. Android Konfiguration**
```
android/
├── app/
│   ├── build.gradle.kts               # Build Config
│   ├── google-services.json           # Firebase Config
│   ├── src/main/
│   │   ├── AndroidManifest.xml        # App Manifest
│   │   └── kotlin/com/example/weltenbibliothek/
│   │       └── MainActivity.kt
│   └── release/
│       ├── release-key.jks            # Release Signing Key
│       └── key.properties             # Key Properties
└── gradle/                            # Gradle Wrapper
```

### **7. Dokumentation**
```
documentation/
├── CHANGELOG.md                       # Version History
├── ARCHITECTURE_FLOW_v3.3.0.txt      # System Architecture
├── BACKEND_MIGRATION_GUIDE.md        # Backend Setup
├── README_AUTH_SYSTEM.md             # Auth Documentation
├── DEPLOYMENT_QUICK_COMMANDS.txt     # Deploy Commands
├── CLOUDFLARE_DEPLOYMENT_COMPLETE.md # Cloudflare Guide
└── WIEDERHERSTELLUNG_ANLEITUNG.md    # Recovery Guide
```

### **8. Deployment Scripts**
```
deployment_scripts/
├── deploy.sh                          # Cloudflare Deploy
├── BACKEND_DEPLOYMENT_COMMANDS.sh     # Backend Commands
└── setup_firebase.sh                  # Firebase Setup (falls verwendet)
```

### **9. WebRTC & Livestream Logik**
```
WebRTC Implementation:
├── webrtc_broadcast_service.dart      # Core WebRTC Service
│   ├── Multi-Room Support
│   ├── Camera Switching (v3.9.1 Aggressive Fix)
│   ├── Peer Connection Management
│   ├── MediaStream Handling
│   └── Auto-Reconnect Logic
├── bandwidth_monitor.dart             # Connection Quality
├── auto_reconnect_manager.dart        # Reconnection Strategy
└── Cloudflare WebSocket Signaling
    ├── Offer/Answer Exchange
    ├── ICE Candidate Handling
    └── Room-Based Isolation
```

### **10. Authentifizierungs-System**
```
Authentication System:
├── Frontend (Flutter)
│   ├── auth_service.dart              # Auth Service
│   ├── login_screen.dart              # Login UI
│   └── register_screen.dart           # Register UI
├── Backend (Cloudflare Worker)
│   ├── /api/auth/register             # User Registration
│   ├── /api/auth/login                # User Login
│   ├── JWT Token Generation
│   └── Password Hashing (bcrypt)
└── Database (D1)
    └── users table                    # User Storage
```

---

## 🔧 **WIEDERHERSTELLUNG IN NEUER UMGEBUNG**

### **SCHRITT 1: Backup Herunterladen**

```bash
# Download des Complete Backup
wget https://www.genspark.ai/api/files/s/al4I4HNn -O weltenbibliothek_backup.tar.gz

# Backup entpacken
tar -xzf weltenbibliothek_backup.tar.gz

# Zum Projekt-Verzeichnis wechseln
cd home/user/flutter_app
```

### **SCHRITT 2: Flutter Environment Setup**

```bash
# Flutter SDK installieren (Version 3.35.4)
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# Flutter SDK verifizieren
flutter --version
# Erwartete Ausgabe: Flutter 3.35.4 • Dart 3.9.2

# Dependencies installieren
flutter pub get

# Flutter Doctor ausführen
flutter doctor -v
```

### **SCHRITT 3: Android SDK Setup**

```bash
# Android SDK installieren
# Erforderlich: Android SDK 35, Build Tools 35.0.0, JDK 17

# ODER: Android Studio installieren (beinhaltet SDK)
# Download: https://developer.android.com/studio

# Signing Key wiederherstellen (bereits im Backup)
# Datei: android/app/release-key.jks
# Properties: android/app/key.properties
```

### **SCHRITT 4: Cloudflare Backend Deploy**

```bash
# Zum Backend-Verzeichnis wechseln
cd cloudflare_backend

# Wrangler installieren (Cloudflare CLI)
npm install -g wrangler

# Cloudflare Login
wrangler login

# WICHTIG: Cloudflare Account-ID und Database-ID aktualisieren
# In wrangler.toml:
# - account_id = "DEINE_ACCOUNT_ID"
# - database_id = "DEINE_DATABASE_ID"

# D1 Datenbank erstellen
wrangler d1 create weltenbibliothek-db

# Schema importieren
wrangler d1 execute weltenbibliothek-db --file=schema.sql

# Worker deployen
wrangler deploy
```

### **SCHRITT 5: Firebase Setup (Optional)**

```bash
# Nur wenn Firebase verwendet wird

# Firebase Admin SDK Key platzieren
cp /pfad/zu/firebase-admin-sdk.json /opt/flutter/

# Google Services JSON platzieren
cp /pfad/zu/google-services.json android/app/

# Firebase in Flutter initialisieren (bereits im Code)
```

### **SCHRITT 6: APK Build**

```bash
# Zurück zum Flutter Projekt
cd /home/user/flutter_app

# Release APK bauen
flutter build apk --release

# APK Location:
# build/app/outputs/flutter-apk/app-release.apk
```

### **SCHRITT 7: Web Preview (Optional)**

```bash
# Web Build erstellen
flutter build web --release

# Mit Python Server starten
python3 -m http.server 5060 --directory build/web --bind 0.0.0.0

# Zugriff über http://localhost:5060
```

---

## 🔐 **WICHTIGE KONFIGURATIONEN**

### **Cloudflare Worker Endpoint**
```
Production: https://weltenbibliothek-webrtc.brandy13062.workers.dev
```

**API Endpoints**:
- POST `/api/auth/register` - User Registration
- POST `/api/auth/login` - User Login
- GET `/api/chat/rooms` - List Chat Rooms
- POST `/api/live/create` - Create Livestream (Telegram-Style)
- POST `/api/live/join/:roomId` - Join Livestream
- POST `/api/live/leave/:roomId` - Leave Livestream
- WebSocket `/ws/:roomId` - WebRTC Signaling

### **Cloudflare D1 Database**
```
Database Name: weltenbibliothek-db
Database ID: 5c2bcefe-d89b-48b8-8174-858195c0375c
Binding: DB
```

### **Durable Objects**
```
Class: ChatRoom
Binding: CHAT_ROOM
Script: weltenbibliothek-webrtc
```

### **Flutter Service Endpoints (im Code)**
```dart
// lib/services/cloudflare_chat_service.dart
static const String baseUrl = 'https://weltenbibliothek-webrtc.brandy13062.workers.dev';

// lib/services/webrtc_broadcast_service.dart
WebSocket Signaling: wss://weltenbibliothek-webrtc.brandy13062.workers.dev/ws
```

---

## 🎯 **FEATURES & FUNKTIONEN**

### **1. Authentifizierung**
- ✅ User Registration (Email + Password)
- ✅ User Login (JWT Tokens)
- ✅ Password Hashing (bcrypt)
- ✅ Session Management

### **2. Chat System**
- ✅ Multiple Chat Rooms
- ✅ Real-time Messaging
- ✅ Message History
- ✅ User Presence
- ✅ Auto-Background Carousel (v3.9.2 - 5 Min)

### **3. Livestream (Telegram-Style)**
- ✅ ONE STREAM PER CHAT
- ✅ Persistent Streams (no auto-end)
- ✅ Host Transfer
- ✅ Multi-Viewer Support
- ✅ WebRTC P2P Connections
- ✅ Camera Switching (v3.9.1 Aggressive Fix)
- ✅ Microphone Toggle
- ✅ Bandwidth Monitoring
- ✅ Auto-Reconnect

### **4. WebRTC Implementierung**
- ✅ Multi-Room Support
- ✅ Peer Connection Management
- ✅ MediaStream Handling
- ✅ ICE Candidate Exchange
- ✅ Offer/Answer Signaling
- ✅ Room Isolation
- ✅ Connection Quality Monitoring

### **5. Camera Switching (v3.9.1)**
- ✅ Aggressive Fix Pattern
- ✅ Manual facingMode Toggle
- ✅ Complete Renderer Reset
- ✅ 500ms Warm-Up Delays
- ✅ No Helper.switchCamera()
- ✅ 11-Step Debug Logging

### **6. Chat Backgrounds (v3.9.2)**
- ✅ Automatic 5-Minute Carousel
- ✅ 3 Images per Chat Type
- ✅ Smooth 800ms Transitions
- ✅ Endless Loop
- ✅ Passive Indicators
- ❌ No Manual Controls

---

## 📊 **VERSIONS-ÜBERSICHT**

### **v3.9.2 (Current)**
- 🎨 Automatischer Hintergrund-Wechsel (5 Min)
- ❌ Manuelle Carousel-Buttons entfernt
- ✅ Endlos-Loop implementiert

### **v3.9.1**
- 🚀 Aggressive Camera Switch Fix
- ❌ Helper.switchCamera() entfernt
- ✅ Kompletter Renderer-Reset
- ✅ Längere Warm-Up Zeiten (500ms)

### **v3.9.0**
- 🔬 Research-Based Camera Fix
- ✅ Replace-First Pattern
- ✅ Chromium Bug Research

### **v3.8.0**
- 🎯 Telegram-Style Architecture
- ✅ ONE STREAM PER CHAT
- ✅ Persistent Streams
- ❌ No Auto-End

---

## 🛠️ **TROUBLESHOOTING**

### **Problem: Flutter Dependencies Fehler**
```bash
# Cache löschen
flutter clean
flutter pub cache repair
flutter pub get
```

### **Problem: Android Build Fehler**
```bash
# Nur Android Build Cache löschen
rm -rf android/build android/app/build android/.gradle
flutter pub get
flutter build apk --release
```

### **Problem: Cloudflare Worker Deploy Fehler**
```bash
# Wrangler neu installieren
npm install -g wrangler@latest

# Login erneuern
wrangler login

# Deploy mit Verbose-Output
wrangler deploy --verbose
```

### **Problem: WebRTC Verbindung schlägt fehl**
```bash
# STUN Server erreichbar?
# Test: stun:stun.l.google.com:19302

# WebSocket Verbindung prüfen
# wss://weltenbibliothek-webrtc.brandy13062.workers.dev/ws/:roomId
```

### **Problem: Database Connection Error**
```bash
# D1 Database Status prüfen
wrangler d1 list

# Schema neu importieren
wrangler d1 execute weltenbibliothek-db --file=schema.sql
```

---

## 📦 **PAKET-ABHÄNGIGKEITEN**

### **Flutter Packages (Fixed Versions)**
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # WebRTC
  flutter_webrtc: 1.2.0
  
  # Networking
  http: 1.5.0
  web_socket_channel: 3.0.1
  
  # State Management
  provider: 6.1.5+1
  
  # Storage
  shared_preferences: 2.5.3
  hive: 2.2.3
  hive_flutter: 1.1.0
  
  # UI
  cupertino_icons: 1.0.8
  
  # Map Integration
  flutter_map: 7.0.2
  latlong2: 0.9.1
  
  # Permissions
  permission_handler: 11.3.1
  
  # Media
  just_audio: 0.9.40
  video_player: 2.9.2
```

### **Cloudflare Dependencies**
```json
{
  "wrangler": "latest",
  "bcryptjs": "^2.4.3"
}
```

---

## 🔗 **WICHTIGE LINKS**

### **Backup Download**
- **Complete Backup**: https://www.genspark.ai/api/files/s/al4I4HNn
- **Size**: 426 MB (komprimiert)
- **Format**: tar.gz

### **APK Download (Latest)**
- **v3.9.2**: https://8080-i9cf5hyz0u2x7z3di04cz-0e616f0a.sandbox.novita.ai/weltenbibliothek-v3.9.2-auto-carousel.apk
- **v3.9.1**: https://8080-i9cf5hyz0u2x7z3di04cz-0e616f0a.sandbox.novita.ai/weltenbibliothek-v3.9.1-aggressive-fix.apk

### **Production Backend**
- **Worker**: https://weltenbibliothek-webrtc.brandy13062.workers.dev
- **WebSocket**: wss://weltenbibliothek-webrtc.brandy13062.workers.dev/ws

### **Cloudflare Dashboard**
- **Workers**: https://dash.cloudflare.com/workers
- **D1 Database**: https://dash.cloudflare.com/d1

---

## ✅ **BACKUP VALIDIERUNG**

### **Checklist - Was ist enthalten?**

- ✅ **Flutter Quellcode** (lib/, main.dart, pubspec.yaml)
- ✅ **Assets** (Bilder, Hintergründe, Icons)
- ✅ **APK Builds** (build/app/outputs/)
- ✅ **Cloudflare Worker** (weltenbibliothek_worker.js, wrangler.toml)
- ✅ **Database Schema** (schema.sql)
- ✅ **Android Config** (AndroidManifest.xml, build.gradle.kts, MainActivity.kt)
- ✅ **Signing Keys** (release-key.jks, key.properties)
- ✅ **WebRTC Logik** (webrtc_broadcast_service.dart)
- ✅ **Auth System** (auth_service.dart, Login/Register Screens)
- ✅ **Chat Backgrounds** (9 Bilder, 3 pro Typ)
- ✅ **Dokumentation** (CHANGELOG, README, Guides)
- ✅ **Deployment Scripts** (deploy.sh, Commands)
- ✅ **Web Build** (build/web/)
- ✅ **Livestream Logik** (live_room_service.dart, Telegram-Style)
- ✅ **Camera Fix** (v3.9.1 Aggressive Implementation)
- ✅ **Auto-Carousel** (v3.9.2 5-Minuten Wechsel)

### **Verifizierung nach Wiederherstellung**

```bash
# 1. Projekt-Struktur prüfen
ls -la
# Sollte zeigen: lib/, assets/, android/, cloudflare_backend/, etc.

# 2. Dependencies installieren
flutter pub get
# Sollte erfolgreich abschließen

# 3. Code analysieren
flutter analyze
# Sollte keine Fehler zeigen

# 4. APK bauen
flutter build apk --release
# Sollte erfolgreich kompilieren

# 5. Worker deployen
cd cloudflare_backend && wrangler deploy
# Sollte erfolgreich deployen
```

---

## 🎯 **QUICK START IN NEUER UMGEBUNG**

### **Minimale Schritte für sofortigen Start:**

```bash
# 1. Backup download & entpacken
wget https://www.genspark.ai/api/files/s/al4I4HNn -O backup.tar.gz
tar -xzf backup.tar.gz
cd home/user/flutter_app

# 2. Flutter Setup
flutter pub get

# 3. APK bauen (Cloudflare Worker läuft bereits!)
flutter build apk --release

# 4. APK testen
# APK: build/app/outputs/flutter-apk/app-release.apk
```

**Das wars!** Die App ist einsatzbereit, da der Cloudflare Worker bereits deployed ist.

---

## 📞 **SUPPORT**

Bei Problemen während der Wiederherstellung:

1. **Logs prüfen**: `flutter build apk --verbose`
2. **Dependencies**: `flutter pub get`
3. **Clean Build**: `flutter clean && flutter pub get`
4. **Worker Status**: Cloudflare Dashboard prüfen

---

**Backup erstellt**: 22. November 2025, 02:40 UTC  
**Gültig für**: Flutter 3.35.4, Dart 3.9.2, Android SDK 35  
**Wiederherstellung getestet**: ✅ Erfolgreich  

**Download jetzt**: https://www.genspark.ai/api/files/s/al4I4HNn
