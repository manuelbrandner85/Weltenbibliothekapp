# 🔌 FLUTTER INTEGRATION GUIDE - WebRTC Signaling Server

## 📋 Übersicht

Dieser Guide zeigt dir, wie du den neuen WebRTC Signaling Server in die Weltenbibliothek Flutter App integrierst.

## 🔧 Schritt 1: API Config aktualisieren

**Datei:** `lib/config/api_config.dart`

```dart
class ApiConfig {
  // Bestehende Config
  static const String baseUrl = 'https://weltenbibliothek-api-v3.brandy13062.workers.dev';
  static const String apiToken = 'y-Xiv3kKeiybDm2CV0yLFu7TSd22co6NBw3udn5Y';
  static const String adminToken = 'XCz3muf7asVj-lBgXXG3ZiY9wJ_TLelzJQZ9jutB';
  static const String webrtcToken = 'XCz3muf7asVj-lBgXXG3ZiY9wJ_TLelzJQZ9jutB';

  // ✨ NEU: WebRTC Signaling Server URLs
  static const String webrtcSignalingUrl = 
    'wss://weltenbibliothek-webrtc-signaling.brandy13062.workers.dev/voice/signaling';
  
  static const String webrtcApiBaseUrl = 
    'https://weltenbibliothek-webrtc-signaling.brandy13062.workers.dev';
  
  // WebRTC API Endpoints
  static String get webrtcRoomsUrl => '$webrtcApiBaseUrl/voice/rooms';
  static String webrtcRoomUrl(String roomId) => '$webrtcApiBaseUrl/voice/rooms/$roomId';
  
  // Admin Endpoints (WebRTC Worker)
  static String adminBanUrl(String userId) => '$webrtcApiBaseUrl/admin/users/$userId/ban';
  static String adminUnbanUrl(String userId) => '$webrtcApiBaseUrl/admin/users/$userId/unban';
  static String adminMuteUrl(String userId) => '$webrtcApiBaseUrl/admin/users/$userId/mute';
  static String adminDeleteUrl(String world, String userId) => 
    '$webrtcApiBaseUrl/api/admin/delete/$world/$userId';

  // Bestehende Getters...
  static String get voiceApiUrl => '$baseUrl/voice';
  static String get websocketUrl => baseUrl.replaceAll('https://', 'wss://');
  
  // ... rest of existing code ...
}
```

## 🎤 Schritt 2: WebRTC Voice Service Migration

**Datei:** `lib/services/webrtc_voice_service.dart`

### **2.1: Signaling WebSocket Connection aktualisieren**

**Finde diese Zeilen (ca. Line 96-100):**
```dart
// WebSocket for signaling
// ⚠️ WICHTIG: WebSocketChatService ist für CHAT, nicht für WebRTC-Signaling konzipiert!
// TODO: Dedizierter WebRTC-Signaling-Server erforderlich (z.B. wss://.../voice/signaling)
// Aktuell werden Voice-Messages über Chat-WebSocket gesendet (Workaround)

final WebSocketChatService _signaling = WebSocketChatService();
```

**Ersetze durch:**
```dart
// ✅ FIXED: Dedizierter WebRTC Signaling Server
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/api_config.dart';

WebSocketChannel? _signalingChannel;
bool _isSignalingConnected = false;
```

### **2.2: Neue Signaling Connection Methode**

**Füge nach Line 460 hinzu:**
```dart
/// Connect to dedicated WebRTC signaling server
Future<void> _connectSignaling() async {
  try {
    // Close existing connection
    await _disconnectSignaling();

    // Connect to dedicated signaling server
    _signalingChannel = WebSocketChannel.connect(
      Uri.parse(ApiConfig.webrtcSignalingUrl),
    );

    _isSignalingConnected = true;
    
    // Listen to signaling messages
    _signalingChannel!.stream.listen(
      (message) {
        _handleSignalingMessage(jsonDecode(message));
      },
      onError: (error) {
        if (kDebugMode) print('❌ WebRTC Signaling error: $error');
        _isSignalingConnected = false;
        // Auto-reconnect
        Future.delayed(Duration(seconds: 2), _connectSignaling);
      },
      onDone: () {
        if (kDebugMode) print('🔌 WebRTC Signaling disconnected');
        _isSignalingConnected = false;
      },
    );

    if (kDebugMode) print('✅ WebRTC Signaling connected');
  } catch (e) {
    if (kDebugMode) print('❌ WebRTC Signaling connection failed: $e');
    _isSignalingConnected = false;
  }
}

/// Disconnect from signaling server
Future<void> _disconnectSignaling() async {
  if (_signalingChannel != null) {
    await _signalingChannel!.sink.close();
    _signalingChannel = null;
    _isSignalingConnected = false;
  }
}

/// Send signaling message
void _sendSignaling(Map<String, dynamic> message) {
  if (_isSignalingConnected && _signalingChannel != null) {
    _signalingChannel!.sink.add(jsonEncode(message));
  } else {
    if (kDebugMode) print('❌ Cannot send signaling: not connected');
  }
}
```

### **2.3: joinRoom() Methode aktualisieren**

**Finde diese Zeilen (ca. Line 264-268):**
```dart
// Setup signaling
_setupSignaling();

// Send join message via WebSocket
await _signaling.sendMessage(
```

**Ersetze durch:**
```dart
// Connect to signaling server
await _connectSignaling();

// Wait for connection
await Future.delayed(Duration(milliseconds: 500));

if (!_isSignalingConnected) {
  throw Exception('Signaling server connection failed');
}

// Send join message
_sendSignaling({
  'type': 'join',
  'roomId': roomId,
  'userId': userId,
  'username': username,
  'world': world,
});
```

### **2.4: leaveRoom() Methode aktualisieren**

**Finde die Zeile (ca. Line 333):**
```dart
await _signaling.sendMessage(
```

**Ersetze durch:**
```dart
_sendSignaling(
```

### **2.5: _handleSignalingMessage() anpassen**

**Finde die Methode (ca. Line 466) und passe an:**
```dart
void _handleSignalingMessage(dynamic message) {
  try {
    final type = message['type'];
    
    switch (type) {
      case 'joined':
        // Room join confirmed
        if (kDebugMode) print('✅ Joined room: ${message['roomId']}');
        _connectionState = VoiceConnectionState.connected;
        _notifyListeners();
        break;
        
      case 'user-joined':
        // New participant joined
        final newUserId = message['userId'];
        final newUsername = message['username'];
        if (kDebugMode) print('👤 User joined: $newUsername');
        // Create offer for new peer
        _createOffer(newUserId);
        break;
        
      case 'user-left':
        // Participant left
        final leftUserId = message['userId'];
        _removeParticipant(leftUserId);
        break;
        
      case 'offer':
        // Received WebRTC offer
        _handleOffer(message['fromUserId'], message['sdp']);
        break;
        
      case 'answer':
        // Received WebRTC answer
        _handleAnswer(message['fromUserId'], message['sdp']);
        break;
        
      case 'ice-candidate':
        // Received ICE candidate
        _handleIceCandidate(message['fromUserId'], message['candidate']);
        break;
        
      case 'user-muted':
        // User mute status changed
        _handleMuteUpdate(message['userId'], message['isMuted']);
        break;
        
      case 'ping':
        // Heartbeat ping
        _sendSignaling({'type': 'pong'});
        break;
        
      case 'error':
        // Error from server
        final error = message['error'];
        final errorMessage = message['message'];
        if (kDebugMode) print('❌ Signaling error: $error - $errorMessage');
        _lastError = errorMessage;
        _connectionState = VoiceConnectionState.error;
        _notifyListeners();
        break;
        
      default:
        if (kDebugMode) print('⚠️ Unknown signaling message type: $type');
    }
  } catch (e) {
    if (kDebugMode) print('❌ WebRTC: Error handling signaling message - $e');
  }
}
```

### **2.6: Offer/Answer senden anpassen**

**Ersetze alle `_signaling.sendMessage()` calls durch `_sendSignaling()` calls:**

```dart
// Example: Creating offer
_sendSignaling({
  'type': 'offer',
  'targetUserId': targetUserId,
  'sdp': offer.sdp,
});

// Example: Creating answer
_sendSignaling({
  'type': 'answer',
  'targetUserId': targetUserId,
  'sdp': answer.sdp,
});

// Example: ICE candidate
_sendSignaling({
  'type': 'ice-candidate',
  'targetUserId': targetUserId,
  'candidate': {
    'candidate': candidate.candidate,
    'sdpMid': candidate.sdpMid,
    'sdpMLineIndex': candidate.sdpMLineIndex,
  },
});
```

## 🛡️ Schritt 3: Admin Service Migration

**Datei:** `lib/services/world_admin_service.dart`

### **3.1: Base URL zu WebRTC Worker ändern**

**Finde diese Zeile (ca. Line 26):**
```dart
static const String _baseUrl = 'https://weltenbibliothek-api-v2.brandy13062.workers.dev';
```

**Ersetze durch:**
```dart
static const String _baseUrl = ApiConfig.webrtcApiBaseUrl;
```

### **3.2: Response Validation hinzufügen**

**Finde die banUser() Methode (ca. Line 870) und ersetze:**
```dart
static Future<bool> banUser(
  String userId, {
  String? reason,
  int durationHours = 24,
}) async {
  try {
    final username = await UnifiedStorageService.getString('username') ?? 'admin';
    
    final url = ApiConfig.adminBanUrl(userId);
    
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${ApiConfig.adminToken}',
        'X-Role': 'root_admin',
        'X-User-ID': username,
      },
      body: jsonEncode({
        'reason': reason ?? 'Admin action',
        'durationHours': durationHours,
      }),
    ).timeout(Duration(seconds: 10));

    // ✅ Response validation
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        if (kDebugMode) {
          print('✅ User banned successfully: $userId');
          print('   Reason: $reason');
          print('   Expires: ${data['expiresAt']}');
        }
        return true;
      } else {
        if (kDebugMode) print('❌ Ban failed: ${data['error'] ?? 'Unknown error'}');
        return false;
      }
    } else {
      if (kDebugMode) print('❌ Ban failed with status: ${response.statusCode}');
      return false;
    }
  } catch (e) {
    if (kDebugMode) print('❌ Exception banning user: $e');
    return false;
  }
}
```

**Wende gleiches Pattern auf muteUser(), unbanUser(), deleteUser() an!**

## ✅ Schritt 4: Dependencies prüfen

**Datei:** `pubspec.yaml`

Stelle sicher, dass diese Dependency vorhanden ist:
```yaml
dependencies:
  web_socket_channel: ^2.4.0
```

Falls nicht vorhanden:
```bash
cd /home/user/flutter_app
flutter pub add web_socket_channel
flutter pub get
```

## 🧪 Schritt 5: Testen

### **5.1: Flutter Analyze**
```bash
cd /home/user/flutter_app
flutter analyze
```

### **5.2: Flutter Clean & Rebuild**
```bash
flutter clean
flutter pub get
flutter build web --release
```

### **5.3: Test Voice Chat Connection**
1. Starte die App
2. Gehe zu einem Voice Chat Room
3. Klicke "Join Voice Chat"
4. Prüfe Logs auf:
   - ✅ WebRTC Signaling connected
   - ✅ Joined room: [roomId]

## 📊 Monitoring

### **WebRTC Connection Status**
```dart
// In deiner UI
final voiceService = WebRTCVoiceService();

// Listen to connection state
voiceService.addListener(() {
  final state = voiceService.connectionState;
  print('WebRTC State: $state');
});
```

### **Cloudflare Worker Logs**
```bash
cd /home/user/flutter_app/cloudflare-worker
wrangler tail --config wrangler-webrtc.toml
```

## 🚨 Troubleshooting

### **Problem: "Signaling server connection failed"**

**Lösung:**
1. Prüfe, ob Worker deployed ist: `curl [WORKER_URL]/health`
2. Prüfe WebSocket URL in `api_config.dart`
3. Prüfe CORS Headers im Worker

### **Problem: "Room full" Fehler**

**Lösung:**
- Max 10 Teilnehmer pro Raum
- Änderbar in `wrangler-webrtc.toml` → `MAX_PARTICIPANTS`

### **Problem: Admin API gibt 401 zurück**

**Lösung:**
- Prüfe `adminToken` in `api_config.dart`
- Prüfe, dass Token mit `AUTH_TOKEN` im Worker übereinstimmt

## ✅ Checkliste

- [ ] `api_config.dart` aktualisiert
- [ ] `webrtc_voice_service.dart` migriert
- [ ] `world_admin_service.dart` migriert
- [ ] `web_socket_channel` dependency hinzugefügt
- [ ] `flutter analyze` erfolgreich
- [ ] App neu gebaut
- [ ] Voice Chat getestet
- [ ] Admin Actions getestet

---

**🎉 FERTIG!** Die Weltenbibliothek App nutzt jetzt den dedizierten WebRTC Signaling Server!
