# 🔄 Weltenbibliothek - Komplette Wiederherstellungs-Anleitung

**Version:** 5.0 - Livestream Korrigiert  
**Backup Datum:** 20. November 2024  
**Backup Größe:** ~260 MB (komprimiert)

---

## 📦 Was ist in diesem Backup enthalten?

### **1. Kompletter Quellcode**
- ✅ `lib/` - Alle Dart-Dateien (Screens, Widgets, Providers, Services, Models)
- ✅ `assets/` - Bilder, Icons, Schriftarten
- ✅ `android/` - Android-Konfiguration (Gradle, Manifest, MainActivity)
- ✅ `web/` - Web-Konfiguration (index.html, manifest.json)
- ✅ `pubspec.yaml` - Dependencies und Projekt-Konfiguration
- ✅ `pubspec.lock` - Exakte Dependency-Versionen

### **2. APK Builds**
- ✅ `weltenbibliothek-v5.0.apk` (117 MB) - Universal APK
- ✅ `app-arm64-v8a-release.apk` (49 MB) - ARM 64-bit
- ✅ `app-armeabi-v7a-release.apk` (41 MB) - ARM 32-bit

### **3. Cloudflare Workers (WebRTC Signaling Server)**
- ✅ `webrtc_signaling_worker.js` (8,246 Bytes) - Vollständiger Signaling Server
- ✅ `wrangler.toml` (534 Bytes) - Cloudflare Konfiguration

### **4. Deployment-Skripte**
- ✅ `quick_deploy.sh` (4.8 KB) - Schnelles Deployment
- ✅ `deploy_via_api.sh` (3.2 KB) - API-basiertes Deployment
- ✅ `auto_deploy_non_interactive.sh` (6.9 KB) - Vollautomatisches Deployment
- ✅ `deploy_signaling_server.sh` (2.1 KB) - Signaling Server Deployment

### **5. Dokumentationen**
- ✅ Deployment Guides (4 Dateien)
- ✅ Feature-Listen (2 Dateien)
- ✅ README-Dateien

---

## 🚀 Schritt-für-Schritt Wiederherstellung

### **Option 1: Komplette Neuinstallation (Empfohlen)**

#### **Schritt 1: Flutter-Projekt erstellen**
```bash
# Neues Flutter-Projekt erstellen
flutter create weltenbibliothek
cd weltenbibliothek
```

#### **Schritt 2: Backup-Dateien wiederherstellen**
```bash
# Quellcode kopieren
cp -r /pfad/zum/backup/lib/* lib/
cp -r /pfad/zum/backup/assets/* assets/
cp -r /pfad/zum/backup/android/* android/
cp -r /pfad/zum/backup/web/* web/

# Projekt-Konfiguration kopieren
cp /pfad/zum/backup/pubspec.yaml .
cp /pfad/zum/backup/pubspec.lock .
```

#### **Schritt 3: Dependencies installieren**
```bash
# Flutter Dependencies installieren
flutter pub get

# Android Gradle Build (falls nötig)
cd android && ./gradlew clean && cd ..
```

#### **Schritt 4: Web Preview starten**
```bash
# Web Build
flutter build web --release

# HTTP Server starten (Port 5060)
cd build/web && python3 -m http.server 5060 --bind 0.0.0.0
```

#### **Schritt 5: Android APK bauen**
```bash
# APK bauen
flutter build apk --release

# APK finden
ls -lh build/app/outputs/flutter-apk/app-release.apk
```

---

### **Option 2: Schnell-Wiederherstellung (Nur APK)**

Falls du nur die fertige APK brauchst:

```bash
# APK aus Backup kopieren
cp /pfad/zum/backup/apk_builds/weltenbibliothek-v5.0.apk .

# Auf Android-Gerät installieren
# (Via USB, ADB, oder manuell übertragen)
```

---

### **Option 3: WebRTC Signaling Server wiederherstellen**

#### **Cloudflare Workers Deployment:**

**Schritt 1: Wrangler installieren (falls nicht vorhanden)**
```bash
npm install -g wrangler
```

**Schritt 2: Cloudflare Login**
```bash
wrangler login
```

**Schritt 3: Worker deployen**
```bash
# In Backup-Ordner wechseln
cd /pfad/zum/backup/cloudflare_workers/

# Worker deployen
wrangler deploy webrtc_signaling_worker.js
```

**Schritt 4: Worker-URL notieren**
```
Deployment-URL: https://weltenbibliothek-webrtc-signaling.DEIN_ACCOUNT.workers.dev
```

**Schritt 5: Flutter App konfigurieren**
```dart
// lib/services/webrtc_service.dart
static const String signalingServerUrl = 
  'wss://weltenbibliothek-webrtc-signaling.DEIN_ACCOUNT.workers.dev/ws';
```

---

## 🛠️ Wichtige Konfigurationen

### **1. Firebase Konfiguration (falls verwendet)**

**Benötigte Dateien:**
- `google-services.json` → `android/app/google-services.json`
- `firebase-admin-sdk.json` → Für Backend-Services

**WICHTIG:** Diese Dateien NICHT im Backup enthalten (Sicherheit!)  
→ Neu aus Firebase Console herunterladen

### **2. Android Package Name**

**Aktueller Package Name:**
```
com.example.flutter_app
```

**Wo zu finden:**
- `android/app/build.gradle.kts` → `applicationId`
- `android/app/src/main/AndroidManifest.xml` → `package`
- `android/app/src/main/kotlin/com/example/flutter_app/MainActivity.kt`

### **3. WebRTC Signaling Server**

**Aktuell deployed:**
```
URL: wss://weltenbibliothek-webrtc-signaling.brandy13062.workers.dev/ws
Status: 🟢 LIVE
```

**Bei Neu-Deployment:**
1. Verwende Skripte aus `deployment_scripts/`
2. Update URL in `lib/services/webrtc_service.dart`

---

## 📱 Features die nach Wiederherstellung funktionieren

### **✅ Sofort funktionsfähig:**
- 7-Tab Navigation (Home, Karte, Chats, Telegram, DM, Timeline, Mehr)
- 50+ Events Datenbank (offline, in Code gespeichert)
- Material Design 3 UI + Glassmorphism
- Interaktive Karte mit GPS
- Musik-Player

### **⚠️ Benötigt Cloudflare Deployment:**
- WebRTC Video-Streaming
- Livestream-Funktionen
- PiP-Modus (funktioniert, aber ohne echte Streams)
- Chat-Nachrichten (benötigt Cloudflare D1)

### **⚠️ Benötigt Firebase:**
- Firebase Firestore (falls Backend-Daten genutzt werden)
- Firebase Storage (falls Cloud-Speicher genutzt wird)

---

## 🔧 Troubleshooting

### **Problem: Flutter Dependencies nicht installiert**
```bash
# Lösung:
flutter pub get
flutter pub upgrade
```

### **Problem: Android Build schlägt fehl**
```bash
# Lösung: Gradle Cache leeren
cd android
./gradlew clean
./gradlew build
cd ..

# Alternativ:
flutter clean
flutter pub get
flutter build apk --release
```

### **Problem: Web Build zeigt leere Seite**
```bash
# Lösung: Build-Cache leeren
rm -rf build/web
flutter build web --release
```

### **Problem: WebRTC funktioniert nicht**
```bash
# Prüfe Signaling Server Status:
curl https://weltenbibliothek-webrtc-signaling.brandy13062.workers.dev/health

# Erwartete Antwort: {"status":"healthy","timestamp":"..."}
```

---

## 📊 Versions-Informationen

**Flutter Version:** 3.35.4 (LOCKED - nicht updaten!)  
**Dart Version:** 3.9.2 (LOCKED - nicht updaten!)  
**Java Version:** OpenJDK 17.0.2  
**Android API Level:** 35 (Android 15)  
**Android Build Tools:** 35.0.0

**WICHTIG:** Diese Versionen sind fixiert für Stabilität!

---

## 🎯 Empfohlene Reihenfolge für vollständige Wiederherstellung

1. **Flutter-Projekt erstellen** (5 Minuten)
2. **Quellcode wiederherstellen** (2 Minuten)
3. **Dependencies installieren** (`flutter pub get`) (3 Minuten)
4. **Web Preview testen** (`flutter build web --release`) (2 Minuten)
5. **Cloudflare Worker deployen** (Optional, 10 Minuten)
6. **APK bauen** (`flutter build apk --release`) (2 Minuten)
7. **Fertig!** ✅

**Gesamtzeit:** ~25 Minuten (ohne Cloudflare), ~35 Minuten (mit Cloudflare)

---

## 📞 Support-Informationen

**Cloudflare Workers:**
- Account: brandy13062.workers.dev
- Projekt: weltenbibliothek-webrtc-signaling
- Durable Objects: Aktiviert (WebRTCRoom)

**WebRTC STUN Server:**
- Google STUN: stun:stun.l.google.com:19302

**Build-Ausgaben:**
- APK Universal: `build/app/outputs/flutter-apk/app-release.apk` (117 MB)
- APK ARM64: `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` (49 MB)
- Web Build: `build/web/` (ca. 20 MB)

---

## ✅ Backup-Inhalt Checkliste

- [x] Kompletter Quellcode (lib/, assets/, android/, web/)
- [x] APK Builds (Universal, ARM64, ARMv7)
- [x] Cloudflare Worker Code (webrtc_signaling_worker.js)
- [x] Deployment-Skripte (4 Skripte)
- [x] Dokumentationen (8 Markdown-Dateien)
- [x] Projekt-Konfiguration (pubspec.yaml, pubspec.lock)
- [x] Wiederherstellungs-Anleitung (diese Datei)

---

**Backup erstellt am:** 20. November 2024, 21:53 UTC  
**Version:** 5.0 - Livestream Korrigiert  
**Status:** ✅ PRODUKTIONSREIF

Dieses Backup enthält ALLES was benötigt wird um die App vollständig wiederherzustellen! 🚀
