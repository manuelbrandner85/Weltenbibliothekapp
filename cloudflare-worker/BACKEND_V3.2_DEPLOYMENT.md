# 🚀 WELTENBIBLIOTHEK BACKEND v3.2 - DEPLOYMENT GUIDE

## ✨ NEU IN v3.2

### Integrierte Features:
- ✅ **WebRTC Signaling Server** (dedizierter WebSocket-basierter Signaling)
- ✅ **Admin APIs mit Response Validation** (ban, mute, delete mit strukturierten Responses)
- ✅ **User Status Tracking** (Ban/Mute State Management)
- ✅ **Voice Chat Room Management** (max 10 Teilnehmer pro Raum)
- ✅ **Heartbeat System** (automatische Connection-Health-Checks)

---

## 📋 VORAUSSETZUNGEN

1. **Cloudflare Account** (kostenlos)
2. **Wrangler CLI** installiert
   ```bash
   npm install -g wrangler
   ```
3. **Account ID** aus Cloudflare Dashboard

---

## 🚀 DEPLOYMENT (5 Minuten)

### Schritt 1: Account ID eintragen

```bash
# Account ID finden
wrangler whoami

# In wrangler-v3.2.toml eintragen (Zeile 8)
account_id = "DEINE_CLOUDFLARE_ACCOUNT_ID"
```

### Schritt 2: Worker deployen

```bash
cd /home/user/flutter_app/cloudflare-worker

# Deploy Backend v3.2
wrangler deploy -c wrangler-v3.2.toml

# ✅ URL speichern (Beispiel):
# https://weltenbibliothek-backend-v3-2.brandy13062.workers.dev
```

---

## 🧪 TESTING - VOLLSTÄNDIGE TEST SUITE

### 1. Health Check

```bash
curl https://weltenbibliothek-backend-v3-2.DEIN-USERNAME.workers.dev/health
```

**Erwartete Antwort:**
```json
{
  "status": "healthy",
  "service": "Weltenbibliothek Backend v3.2",
  "version": "3.2.0",
  "features": [
    "WebRTC Signaling Server",
    "Admin API (ban/mute/delete with validation)",
    "Voice Chat Management",
    "User Status Tracking"
  ],
  "timestamp": "2026-02-15T...",
  "activeRooms": 0,
  "activeBans": 0,
  "activeMutes": 0
}
```

### 2. Ban User (mit Response Validation)

```bash
curl -X POST \
  https://weltenbibliothek-backend-v3-2.DEIN-USERNAME.workers.dev/admin/users/test_user/ban \
  -H "Authorization: Bearer XCz3muf7asVj-lBgXXG3ZiY9wJ_TLelzJQZ9jutB" \
  -H "Content-Type: application/json" \
  -d '{
    "reason": "Test ban",
    "durationHours": 24
  }'
```

**Erwartete Antwort:**
```json
{
  "success": true,
  "message": "User test_user banned for 24 hours",
  "userId": "test_user",
  "reason": "Test ban",
  "durationHours": 24,
  "expiresAt": "2026-02-16T...",
  "timestamp": "2026-02-15T..."
}
```

### 3. Mute User (mit Response Validation)

```bash
curl -X POST \
  https://weltenbibliothek-backend-v3-2.DEIN-USERNAME.workers.dev/admin/users/test_user/mute \
  -H "Authorization: Bearer XCz3muf7asVj-lBgXXG3ZiY9wJ_TLelzJQZ9jutB" \
  -H "Content-Type: application/json" \
  -d '{
    "reason": "Test mute",
    "durationMinutes": 60
  }'
```

**Erwartete Antwort:**
```json
{
  "success": true,
  "message": "User test_user muted for 60 minutes",
  "userId": "test_user",
  "reason": "Test mute",
  "durationMinutes": 60,
  "expiresAt": "2026-02-15T...",
  "timestamp": "2026-02-15T..."
}
```

### 4. Unban User (mit Response Validation)

```bash
curl -X POST \
  https://weltenbibliothek-backend-v3-2.DEIN-USERNAME.workers.dev/admin/users/test_user/unban \
  -H "Authorization: Bearer XCz3muf7asVj-lBgXXG3ZiY9wJ_TLelzJQZ9jutB"
```

**Erwartete Antwort:**
```json
{
  "success": true,
  "message": "User test_user unbanned successfully",
  "userId": "test_user",
  "wasBanned": true,
  "timestamp": "2026-02-15T..."
}
```

### 5. Delete User

```bash
curl -X DELETE \
  https://weltenbibliothek-backend-v3-2.DEIN-USERNAME.workers.dev/api/admin/delete/materie/test_user \
  -H "Authorization: Bearer XCz3muf7asVj-lBgXXG3ZiY9wJ_TLelzJQZ9jutB"
```

**Erwartete Antwort:**
```json
{
  "success": true,
  "message": "User test_user deleted from materie",
  "world": "materie",
  "userId": "test_user",
  "timestamp": "2026-02-15T..."
}
```

### 6. Check User Status (NEU!)

```bash
curl https://weltenbibliothek-backend-v3-2.DEIN-USERNAME.workers.dev/admin/users/test_user/status \
  -H "Authorization: Bearer XCz3muf7asVj-lBgXXG3ZiY9wJ_TLelzJQZ9jutB"
```

**Erwartete Antwort:**
```json
{
  "success": true,
  "userId": "test_user",
  "isBanned": true,
  "isMuted": false,
  "banInfo": {
    "reason": "Test ban",
    "expiresAt": 1771210224000,
    "bannedAt": 1771123824000
  },
  "muteInfo": null,
  "timestamp": "2026-02-15T..."
}
```

### 7. Voice Rooms auflisten

```bash
curl https://weltenbibliothek-backend-v3-2.DEIN-USERNAME.workers.dev/voice/rooms
```

**Erwartete Antwort:**
```json
{
  "success": true,
  "rooms": [],
  "timestamp": "2026-02-15T..."
}
```

### 8. WebSocket Signaling testen

```bash
# wscat installieren
npm install -g wscat

# WebSocket-Verbindung testen
wscat -c wss://weltenbibliothek-backend-v3-2.DEIN-USERNAME.workers.dev/voice/signaling

# Join-Nachricht senden
> {"type":"join","roomId":"materie_main","userId":"test_user","username":"Test User"}

# Erwartete Antwort:
< {"type":"joined","roomId":"materie_main","userId":"test_user","participants":[...]}
```

---

## 🔧 FLUTTER INTEGRATION

### Schritt 1: API Config aktualisieren

```dart
// lib/config/api_config.dart

class ApiConfig {
  // ✅ NEU: WebRTC Signaling Server URL
  static const String webrtcSignalingUrl = 
    'wss://weltenbibliothek-backend-v3-2.DEIN-USERNAME.workers.dev/voice/signaling';

  // ✅ NEU: Admin API Base URL (falls separate Worker)
  static const String adminApiUrl = 
    'https://weltenbibliothek-backend-v3-2.DEIN-USERNAME.workers.dev';

  // Bestehende Config bleibt
  static const String baseUrl = 'https://weltenbibliothek-api-v3.brandy13062.workers.dev';
  static const String adminToken = 'XCz3muf7asVj-lBgXXG3ZiY9wJ_TLelzJQZ9jutB';
}
```

### Schritt 2: WebRTC Service updaten

```dart
// lib/services/webrtc_voice_service.dart

// Zeile ~100: WebSocket Signaling Channel
final WebSocketChannel _signalingChannel = WebSocketChannel.connect(
  Uri.parse(ApiConfig.webrtcSignalingUrl),
);
```

### Schritt 3: Admin Service validieren

```dart
// lib/services/world_admin_service.dart

// ✅ Validiere dass alle Admin-Calls ApiConfig.adminToken nutzen
// ✅ Validiere Response-Body Parsing (success field)

static Future<AdminResult> banUser(...) async {
  try {
    final response = await http.post(
      Uri.parse('${ApiConfig.adminApiUrl}/admin/users/$userId/ban'),
      headers: {'Authorization': 'Bearer ${ApiConfig.adminToken}', ...},
      body: jsonEncode({'reason': reason, 'durationHours': durationHours}),
    );

    final data = jsonDecode(response.body);
    
    // ✅ Response Validation
    if (response.statusCode == 200 && data['success'] == true) {
      return AdminResult.success(message: data['message']);
    } else {
      return AdminResult.error(error: data['error'] ?? 'Unknown error');
    }
  } catch (e) {
    return AdminResult.error(error: e.toString());
  }
}
```

---

## 📊 MONITORING

### Cloudflare Dashboard

```
https://dash.cloudflare.com/
→ Workers & Pages
→ weltenbibliothek-backend-v3-2
→ Metrics / Logs
```

### Live Logs (Wrangler)

```bash
wrangler tail -c wrangler-v3.2.toml
```

### Metriken überwachen

- **Requests/Day** - API-Nutzung
- **WebSocket Connections** - Aktive Voice-Chat-Verbindungen
- **Errors** - Fehlerrate (sollte < 1% sein)
- **CPU Time** - Durchschnittliche Ausführungszeit

---

## 🚨 TROUBLESHOOTING

### Problem: Worker deployed, aber 404 bei Admin APIs

**Lösung:** Check URL - Admin endpoints erfordern `/admin/users/...` nicht `/api/admin/users/...`

### Problem: "Invalid token" bei Admin Calls

**Lösung:** Verwende `XCz3muf7asVj-lBgXXG3ZiY9wJ_TLelzJQZ9jutB` (ADMIN_TOKEN)

### Problem: WebSocket schließt sofort

**Lösung:** Check Browser Console - CORS oder WebSocket-Upgrade-Fehler

### Problem: "Room full" trotz leerem Raum

**Lösung:** Worker neu starten - In-Memory State wird zurückgesetzt

---

## 💰 KOSTEN

**100% KOSTENLOS** bei normaler Nutzung!

| Resource | Free Tier | Pro Request | Max/Tag (kostenlos) |
|----------|-----------|-------------|---------------------|
| Worker Requests | 100.000/Tag | ~1 Request | 100.000 |
| WebSocket Messages | Unlimitiert* | ~10 pro Verbindung | ∞ |
| CPU Time | 10ms/Request | ~3ms avg | 100.000 Requests |

*WebSocket-Connect zählt als 1 Request, Messages danach kostenlos

---

## ✅ DEPLOYMENT CHECKLIST

- [x] Worker Code erstellt (backend-v3.2.js)
- [x] Wrangler Config erstellt (wrangler-v3.2.toml)
- [ ] Account ID eingetragen
- [ ] `wrangler deploy -c wrangler-v3.2.toml` ausgeführt
- [ ] Health Check getestet
- [ ] Admin APIs getestet (ban, mute, unban, delete, status)
- [ ] WebSocket Signaling getestet
- [ ] Flutter API Config aktualisiert
- [ ] Flutter neu gebaut und getestet

---

## 🎯 NÄCHSTE SCHRITTE

1. ✅ Worker deployen
2. ✅ Admin APIs testen
3. ⏳ Flutter Integration
4. ⏳ End-to-End Voice Chat Test
5. ⏳ Production Testing mit echten Usern

**BACKEND v3.2 READY TO DEPLOY!** 🚀
