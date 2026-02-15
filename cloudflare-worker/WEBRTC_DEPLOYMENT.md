# 🚀 DEPLOYMENT GUIDE - WebRTC Signaling Server

## 📋 VORAUSSETZUNGEN

1. **Cloudflare Account** - Kostenloser Account ausreichend
2. **Wrangler CLI** - Installiert und konfiguriert
3. **Node.js** - Version 16+ empfohlen

---

## ⚡ SCHNELL-DEPLOYMENT (5 Minuten)

### Schritt 1: Wrangler Login

```bash
# Falls noch nicht eingeloggt
wrangler login
```

### Schritt 2: Account ID eintragen

```bash
# Account ID finden
wrangler whoami

# Account ID in wrangler-webrtc.toml eintragen (Zeile 17)
account_id = "DEINE_ACCOUNT_ID"
```

### Schritt 3: Worker deployen

```bash
cd /home/user/flutter_app/cloudflare-worker

# Deploy WebRTC Signaling Worker
wrangler deploy -c wrangler-webrtc.toml

# ✅ URL kopieren (Beispiel):
# https://weltenbibliothek-webrtc-signaling.brandy13062.workers.dev
```

---

## 🧪 TESTEN

### Test 1: Health Check

```bash
curl https://weltenbibliothek-webrtc-signaling.DEIN-USERNAME.workers.dev/health
```

**Erwartete Antwort:**
```json
{
  "status": "healthy",
  "service": "weltenbibliothek-webrtc-signaling",
  "version": "1.0.0",
  "timestamp": 1234567890,
  "activeRooms": 0
}
```

### Test 2: Rooms auflisten

```bash
curl https://weltenbibliothek-webrtc-signaling.DEIN-USERNAME.workers.dev/voice/rooms
```

**Erwartete Antwort:**
```json
{
  "success": true,
  "rooms": [],
  "timestamp": 1234567890
}
```

### Test 3: WebSocket Signaling (mit wscat)

```bash
# wscat installieren (falls nötig)
npm install -g wscat

# WebSocket testen
wscat -c wss://weltenbibliothek-webrtc-signaling.DEIN-USERNAME.workers.dev/voice/signaling

# Nachricht senden
> {"type":"join","roomId":"materie_main","userId":"test_user","username":"Test User"}

# Erwartete Antwort:
< {"type":"joined","roomId":"materie_main","userId":"test_user","participants":[...]}
```

---

## 🔐 ADMIN API TESTEN

### Ban User

```bash
curl -X POST \
  https://weltenbibliothek-webrtc-signaling.DEIN-USERNAME.workers.dev/admin/users/user123/ban \
  -H "Authorization: Bearer XCz3muf7asVj-lBgXXG3ZiY9wJ_TLelzJQZ9jutB" \
  -H "Content-Type: application/json" \
  -d '{
    "reason": "Spam",
    "durationHours": 24
  }'
```

**Erwartete Antwort:**
```json
{
  "success": true,
  "message": "User user123 banned for 24 hours",
  "userId": "user123",
  "reason": "Spam",
  "expiresAt": 1234567890
}
```

### Mute User

```bash
curl -X POST \
  https://weltenbibliothek-webrtc-signaling.DEIN-USERNAME.workers.dev/admin/users/user123/mute \
  -H "Authorization: Bearer XCz3muf7asVj-lBgXXG3ZiY9wJ_TLelzJQZ9jutB" \
  -H "Content-Type: application/json" \
  -d '{
    "reason": "Inappropriate language",
    "durationMinutes": 60
  }'
```

**Erwartete Antwort:**
```json
{
  "success": true,
  "message": "User user123 muted for 60 minutes",
  "userId": "user123",
  "reason": "Inappropriate language",
  "expiresAt": 1234567890
}
```

### Delete User

```bash
curl -X DELETE \
  https://weltenbibliothek-api-v3.brandy13062.workers.dev/api/admin/delete/materie/user123 \
  -H "Authorization: Bearer XCz3muf7asVj-lBgXXG3ZiY9wJ_TLelzJQZ9jutB" \
  -H "X-Role: root_admin" \
  -H "X-User-ID: admin"
```

**Erwartete Antwort:**
```json
{
  "success": true,
  "message": "User user123 deleted from materie",
  "world": "materie",
  "userId": "user123"
}
```

---

## 🔧 FLUTTER INTEGRATION

Nach erfolgreichem Deployment:

### 1. API Config aktualisieren

```dart
// lib/config/api_config.dart

class ApiConfig {
  // ✅ WebRTC Signaling Server URL hinzufügen
  static const String webrtcSignalingUrl = 
    'wss://weltenbibliothek-webrtc-signaling.DEIN-USERNAME.workers.dev/voice/signaling';
  
  // ... restliche Config
}
```

### 2. WebRTC Service aktualisieren

```dart
// lib/services/webrtc_voice_service.dart

// TODO: Zeile ~100 ersetzen
final WebSocketChannel _signalingChannel = WebSocketChannel.connect(
  Uri.parse(ApiConfig.webrtcSignalingUrl),
);
```

### 3. Flutter neu bauen

```bash
cd /home/user/flutter_app
flutter clean
flutter pub get
flutter build web --release
python3 -m http.server 5060 --directory build/web --bind 0.0.0.0 &
```

---

## 📊 MONITORING

### Cloudflare Dashboard

```
https://dash.cloudflare.com/
→ Workers & Pages
→ weltenbibliothek-webrtc-signaling
→ Metrics
```

### Live Logs

```bash
wrangler tail -c wrangler-webrtc.toml
```

### Metriken

- **Requests/Day** - Anzahl API-Calls
- **WebSocket Connections** - Aktive Verbindungen
- **Errors** - Fehlerrate überwachen
- **CPU Time** - Ausführungszeit pro Request

---

## 🚨 TROUBLESHOOTING

### Problem: "Room full" Error

**Ursache:** Mehr als 10 Teilnehmer versuchen beizutreten

**Lösung:** MAX_PARTICIPANTS in wrangler-webrtc.toml erhöhen

### Problem: WebSocket schließt sofort

**Ursache:** CORS oder Authorization fehlt

**Lösung:** Check ALLOWED_ORIGINS in webrtc-signaling-worker.js

### Problem: ICE Candidates kommen nicht an

**Ursache:** Signaling funktioniert, aber Peers finden sich nicht

**Lösung:** STUN/TURN Server konfigurieren (siehe Flutter WebRTC Config)

---

## 💰 KOSTEN

**100% KOSTENLOS** bei normaler Nutzung!

| Resource | Free Tier | Pro Voice Chat | Max/Tag (kostenlos) |
|----------|-----------|----------------|---------------------|
| Worker Requests | 100.000/Tag | ~10 per User | 10.000 User |
| WebSocket Connections | Unlimitiert* | 1 per User | ∞ |
| CPU Time | 10ms/Request | ~5ms | 100.000 Requests |

*WebSocket Verbindungen zählen als 1 Request beim Connect, danach kostenlos

---

## ✅ NÄCHSTE SCHRITTE

1. ✅ Worker deployen
2. ✅ Health Check testen
3. ✅ Admin APIs validieren
4. ⏳ Flutter Integration
5. ⏳ End-to-End Test

**DEPLOYMENT BEREIT!** 🚀
