# 🚀 WebRTC Setup Guide - Weltenbibliothek

## 📋 Voraussetzungen

- Flutter 3.35.4 installiert
- Dart 3.9.2
- Android SDK (für APK Build)
- Cloudflare Account (für Signaling Server)

## 🔧 Schritt-für-Schritt Setup

### **Schritt 1: Projekt klonen/herunterladen**

```bash
# Projekt-Verzeichnis
cd /home/user/flutter_app
```

### **Schritt 2: Dependencies installieren**

```bash
# Flutter Dependencies holen
flutter pub get

# Überprüfung
flutter doctor -v
```

### **Schritt 3: Cloudflare Worker deployen**

#### 3.1 Wrangler CLI installieren
```bash
npm install -g wrangler
```

#### 3.2 Cloudflare Login
```bash
wrangler login
```

#### 3.3 Worker-Konfiguration erstellen

Erstelle `wrangler.toml` im Projekt-Root:

```toml
name = "weltenbibliothek-signaling"
main = "cloudflare_workers/webrtc_signaling_worker.js"
compatibility_date = "2024-01-01"

# Durable Objects Binding
[[durable_objects.bindings]]
name = "WEBRTC_ROOMS"
class_name = "WebRTCRoom"
script_name = "weltenbibliothek-signaling"

# Durable Object Migration
[[migrations]]
tag = "v1"
new_classes = ["WebRTCRoom"]
```

#### 3.4 Worker deployen
```bash
# Worker veröffentlichen
wrangler publish

# Output:
# ✨  Successfully published your script to
# https://weltenbibliothek-signaling.YOUR-ACCOUNT.workers.dev
```

**WICHTIG**: Notiere dir die Worker-URL!

### **Schritt 4: Flutter App konfigurieren**

#### 4.1 Signaling-URL aktualisieren

In `lib/services/webrtc_broadcast_service.dart`:

```dart
// Zeile ~250
final String _signalingUrl = 'wss://weltenbibliothek-signaling.YOUR-ACCOUNT.workers.dev';
```

**Ersetze `YOUR-ACCOUNT` mit deinem Cloudflare Account!**

#### 4.2 Überprüfung der ICE-Server

In `lib/services/webrtc_broadcast_service.dart` (Zeile ~74):

```dart
final Map<String, dynamic> _iceServers = {
  'iceServers': [
    {
      'urls': ['stun:stun.cloudflare.com:3478']
    },
    {
      'urls': ['turn:relay.cloudflare.com:3478?transport=udp'],
      'username': 'cf_turn',
      'credential': 'cf_turn'
    }
  ],
  'iceCandidatePoolSize': 10,
  'sdpSemantics': 'unified-plan'
};
```

✅ **Bereits konfiguriert!**

### **Schritt 5: App bauen**

#### 5.1 Android APK Build
```bash
# Release Build
flutter build apk --release

# Output:
# ✓ Built build/app/outputs/flutter-apk/app-release.apk (165.7MB)
```

#### 5.2 APK installieren
```bash
# APK auf Gerät installieren (via adb)
adb install build/app/outputs/flutter-apk/app-release.apk
```

### **Schritt 6: Testen**

#### 6.1 Host-Stream starten

1. **App auf Gerät 1 öffnen**
2. **Zum "Allgemeiner Chat" navigieren**
3. **"Live"-Button antippen**
4. **"Start Broadcast" auswählen**
5. **Stream startet (Kamera ist standardmäßig AUS)**

#### 6.2 Viewer beitreten

1. **App auf Gerät 2 öffnen**
2. **Zum gleichen Chat navigieren**
3. **"Live"-Indikator sollte sichtbar sein**
4. **"Join Live Stream" antippen**
5. **Viewer sieht Host-Video (falls Host Kamera an hat)**

#### 6.3 Multi-User Test

1. **Gerät 3 hinzufügen**
2. **Livestream beitreten**
3. **Alle sollten sich gegenseitig sehen können**

**Erwartetes Verhalten:**
- ✅ Host sieht alle Viewer im Grid (rechts oben)
- ✅ Viewer sehen Host im Hauptbereich
- ✅ Viewer sehen andere Viewer im Grid (rechts oben)
- ✅ Jeder kann seine Kamera ein-/ausschalten

### **Schritt 7: Debugging**

#### 7.1 Android Logcat

```bash
# WebRTC Logs filtern
adb logcat | grep "WebRTC"

# Wichtige Log-Ausgaben:
# 🚀 Joining as: user_123 (role: host)
# 👥 Existing peers: 2
# 🤝 Creating peer connection for: user_456
# ➕ Added local video track to peer user_456
# 📺 Received remote video track from user_456
# ✅ Renderer initialized for peer user_456. Total renderers: 2
```

#### 7.2 Signaling-Server Logs

```bash
# Cloudflare Worker Logs
wrangler tail

# Erwartete Ausgaben:
# 📥 [user_123] join
# 👤 Peer joined: user_123 (Room: room_456)
# 📊 Total peers in room: 1
# 📥 [user_789] join
# 📤 Forwarded offer to user_789
# 📤 Forwarded answer to user_123
```

#### 7.3 Häufige Probleme

**Problem: "Keine Verbindung zum Signaling-Server"**
```
Lösung:
1. Überprüfe _signalingUrl in webrtc_broadcast_service.dart
2. Teste Worker-URL im Browser: https://your-worker.workers.dev/health
3. Prüfe Netzwerk-Verbindung des Geräts
```

**Problem: "Viewer sehen sich nicht gegenseitig"**
```
Lösung:
1. Logcat nach "peers-list" Event durchsuchen
2. Sicherstellen, dass _handlePeersList() aufgerufen wird
3. Überprüfen, dass peerConnections Map gefüllt wird
4. Debug-Ausgabe für remoteRenderers.length prüfen
```

**Problem: "ICE Connection Failed"**
```
Lösung:
1. TURN-Server aktiviert? (Firewall/NAT-Umgehung)
2. Netzwerk erlaubt UDP-Traffic?
3. ICE Candidates werden ausgetauscht? (Logcat prüfen)
```

## 📊 Performance-Monitoring

### Bandwidth-Monitor

In `lib/services/bandwidth_monitor.dart`:

```dart
// Automatisches Monitoring aktiv
// Logs:
// 📊 [bandwidth_456] Video bitrate: 1234 kbps
// 📊 [bandwidth_456] Audio bitrate: 128 kbps
```

### Connection Quality Tracking

```dart
// In webrtc_broadcast_service.dart
pc.getStats().then((stats) {
  stats.forEach((report) {
    if (report.type == 'inbound-rtp') {
      debugPrint('📈 Inbound: ${report.values}');
    }
  });
});
```

## 🔐 Production Deployment

### Security Checklist

- [ ] **Eigene TURN-Server** (nicht cf_turn für Production!)
- [ ] **Authentifizierung** für Signaling-Server
- [ ] **Rate Limiting** auf Cloudflare Worker
- [ ] **HTTPS** für alle Verbindungen
- [ ] **Token-basierte** Raum-Zugangskontrolle

### Skalierung

**Mesh Network Limits:**
- ✅ **1-5 Nutzer**: Optimal
- ⚠️ **6-8 Nutzer**: Möglich (hohe Bandbreite erforderlich)
- ❌ **>10 Nutzer**: SFU-Server empfohlen

**SFU Migration** (für große Gruppen):
- Medooze
- Janus Gateway
- Jitsi Videobridge

## 📚 Weitere Ressourcen

- **WebRTC Dokumentation**: https://webrtc.org/getting-started/overview
- **Flutter WebRTC**: https://pub.dev/packages/flutter_webrtc
- **Cloudflare Durable Objects**: https://developers.cloudflare.com/durable-objects/

## ✅ Vollständige Feature-Liste

### Implementierte Anforderungen:

#### 1. WebRTC Konfiguration ✅
- [x] Cloudflare STUN Server: `stun:stun.cloudflare.com:3478`
- [x] Cloudflare TURN Server: `turn:relay.cloudflare.com:3478`
- [x] iceCandidatePoolSize: 10
- [x] sdpSemantics: unified-plan

#### 2. Core-Funktionen ✅
- [x] `createPeerConnection()` - Zeile 871
- [x] `addLocalTracks()` - Automatisch in createPeerConnection (Zeile 887)
- [x] `createOffer()` - Zeile 975
- [x] `createAnswer()` - Zeile 1044
- [x] `handleRemoteDescription()` - In handleOffer/handleAnswer
- [x] `handleIceCandidates()` - Zeile 1093
- [x] `addRemoteTracks()` - onTrack Handler (Zeile 877)
- [x] `closeConnection()` - In leaveRoom() (Zeile 325)

#### 3. Signaling-System ✅
- [x] Cloudflare Workers WebSocket
- [x] Nutzer tritt bei (`join` Message)
- [x] Nutzer verlässt (`leave` Message)
- [x] Peer-IDs verteilen (`peers-list` Response)
- [x] SDP Routing (`offer`/`answer` Forwarding)
- [x] ICE Routing (`ice-candidate` Forwarding)
- [x] Mesh Network (jeder mit jedem)

#### 4. Multi-User Support ✅
- [x] `Map<String, RTCPeerConnection> peerConnections`
- [x] Separate PeerConnection pro Peer
- [x] Remote Video Renderer pro Peer

#### 5. UI ✅
- [x] Remote-Videos Liste (Viewer Grid)
- [x] Lokales Video (Selfie-Ansicht)
- [x] Join/Leave Buttons
- [x] Kamera-Toggle
- [x] Mikrofon-Toggle

#### 6. Fehlerbehandlung ✅
- [x] WebSocket Wiederverbindung (AutoReconnectManager)
- [x] ICE Restart bei Connection Failed
- [x] ICE State Logging (`onIceConnectionState`)
- [x] Signaling State Logging (`onSignalingState`)
- [x] Connection State Logging (`onConnectionState`)

## 🎉 Fertig!

Deine WebRTC-App ist jetzt vollständig konfiguriert und einsatzbereit!

**Bei Fragen oder Problemen:**
- Überprüfe die Logs (Schritt 7)
- Konsultiere WEBRTC_ARCHITECTURE.md
- Teste mit curl/Postman die Worker-Endpoints
