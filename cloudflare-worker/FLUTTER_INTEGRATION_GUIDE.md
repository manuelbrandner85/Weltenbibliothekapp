# 🔧 FLUTTER INTEGRATION GUIDE - Backend v3.2

## ✨ NEUE FEATURES

Dieser Guide zeigt dir, wie du die neuen Backend v3.2 Features in deine Flutter App integrierst:

1. **WebRTC Signaling Server** (dedizierter WebSocket)
2. **Admin APIs mit Response Validation**
3. **User Status Tracking**

---

## 📋 SCHRITT 1: API CONFIG AKTUALISIEREN

### Datei: `lib/config/api_config.dart`

```dart
class ApiConfig {
  // ═══════════════════════════════════════════════════════════════════════
  // 🆕 BACKEND V3.2 ENDPOINTS
  // ═══════════════════════════════════════════════════════════════════════
  
  // WebRTC Signaling Server (dediziert)
  static const String webrtcSignalingUrl = 
    'wss://weltenbibliothek-backend-v3-2.DEIN-USERNAME.workers.dev/voice/signaling';
  
  // Admin API Endpoints (mit Response Validation)
  static const String adminApiBaseUrl = 
    'https://weltenbibliothek-backend-v3-2.DEIN-USERNAME.workers.dev';
  
  // ═══════════════════════════════════════════════════════════════════════
  // BESTEHENDE CONFIG (unverändert)
  // ═══════════════════════════════════════════════════════════════════════
  
  static const String baseUrl = 'https://weltenbibliothek-api-v3.brandy13062.workers.dev';
  static const String primaryToken = 'y-Xiv3kKeiybDm2CV0yLFu7TSd22co6NBw3udn5Y';
  static const String adminToken = 'XCz3muf7asVj-lBgXXG3ZiY9wJ_TLelzJQZ9jutB';
  
  // Helper methods
  static String getUrl(String endpoint) => '$baseUrl$endpoint';
  
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $primaryToken',
  };
  
  static Map<String, String> get adminHeaders => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $adminToken',
    'X-Role': 'root_admin',
    'X-User-ID': 'admin',
  };
}
```

---

## 📋 SCHRITT 2: WEBRTC SERVICE AKTUALISIEREN

### Datei: `lib/services/webrtc_voice_service.dart`

**Änderung 1: Signaling Channel initialisieren**

```dart
// ❌ ALT (Zeile ~100):
// final WebSocketChatService _signaling = WebSocketChatService();
// ⚠️ WICHTIG: WebSocketChatService ist für CHAT, nicht für WebRTC-Signaling konzipiert!

// ✅ NEU:
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/api_config.dart';

class WebRTCVoiceService {
  // ...
  
  // WebSocket für dediziertes WebRTC Signaling
  WebSocketChannel? _signalingChannel;
  
  // Signaling initialisieren
  void _initSignaling() {
    try {
      _signalingChannel = WebSocketChannel.connect(
        Uri.parse(ApiConfig.webrtcSignalingUrl),
      );
      
      _signalingChannel!.stream.listen(
        _handleSignalingMessage,
        onError: (error) {
          if (kDebugMode) print('❌ WebRTC Signaling error: $error');
          _attemptReconnect();
        },
        onDone: () {
          if (kDebugMode) print('🔌 WebRTC Signaling disconnected');
          _attemptReconnect();
        },
      );
      
      if (kDebugMode) print('✅ WebRTC Signaling connected');
    } catch (e) {
      if (kDebugMode) print('❌ Failed to initialize WebRTC Signaling: $e');
    }
  }
  
  // Signaling message senden
  void _sendSignalingMessage(Map<String, dynamic> message) {
    try {
      if (_signalingChannel != null) {
        _signalingChannel!.sink.add(jsonEncode(message));
      }
    } catch (e) {
      if (kDebugMode) print('❌ Failed to send signaling message: $e');
    }
  }
  
  // ...
}
```

**Änderung 2: Join Room mit neuem Signaling**

```dart
Future<void> joinRoom(
  String roomId,
  String userId,
  String username, {
  String world = 'materie',
}) async {
  try {
    // ... existing permission checks ...
    
    // Signaling initialisieren (falls noch nicht)
    if (_signalingChannel == null) {
      _initSignaling();
      await Future.delayed(Duration(milliseconds: 500)); // Wait for connection
    }
    
    // Join message senden
    _sendSignalingMessage({
      'type': 'join',
      'roomId': roomId,
      'userId': userId,
      'username': username,
    });
    
    // ... rest of join logic ...
    
  } catch (e) {
    // ... error handling ...
  }
}
```

**Änderung 3: WebRTC Signaling Nachrichten verarbeiten**

```dart
void _handleSignalingMessage(dynamic message) {
  try {
    final data = jsonDecode(message);
    final type = data['type'];
    
    switch (type) {
      case 'joined':
        // Room erfolgreich beigetreten
        _connectionState = VoiceConnectionState.connected;
        _currentRoomId = data['roomId'];
        notifyListeners();
        break;
        
      case 'user-joined':
        // Neuer Teilnehmer beigetreten
        final newUserId = data['userId'];
        final newUsername = data['username'];
        // ... create peer connection ...
        break;
        
      case 'user-left':
        // Teilnehmer hat verlassen
        final leftUserId = data['userId'];
        _removeParticipant(leftUserId);
        break;
        
      case 'offer':
        // WebRTC Offer empfangen
        final fromUserId = data['fromUserId'];
        final sdp = data['sdp'];
        _handleOffer(fromUserId, sdp);
        break;
        
      case 'answer':
        // WebRTC Answer empfangen
        final fromUserId = data['fromUserId'];
        final sdp = data['sdp'];
        _handleAnswer(fromUserId, sdp);
        break;
        
      case 'ice-candidate':
        // ICE Candidate empfangen
        final fromUserId = data['fromUserId'];
        final candidate = data['candidate'];
        _handleIceCandidate(fromUserId, candidate);
        break;
        
      case 'user-muted':
        // Mute status update
        final userId = data['userId'];
        final isMuted = data['isMuted'];
        _updateParticipantMute(userId, isMuted);
        break;
        
      case 'error':
        // Error von Server
        final error = data['error'];
        _lastError = error;
        _connectionState = VoiceConnectionState.error;
        notifyListeners();
        break;
        
      case 'ping':
        // Heartbeat ping
        _sendSignalingMessage({'type': 'pong'});
        break;
    }
  } catch (e) {
    if (kDebugMode) print('❌ Error handling signaling message: $e');
  }
}
```

---

## 📋 SCHRITT 3: ADMIN SERVICE MIT RESPONSE VALIDATION

### Datei: `lib/services/world_admin_service.dart`

**NEU: Admin Result Class**

```dart
// Strukturierte Admin Operation Results
class AdminResult {
  final bool success;
  final String? message;
  final String? error;
  final Map<String, dynamic>? data;
  
  AdminResult.success({this.message, this.data})
      : success = true,
        error = null;
  
  AdminResult.error({required this.error})
      : success = false,
        message = null,
        data = null;
}
```

**AKTUALISIERT: Ban User mit Response Validation**

```dart
static Future<AdminResult> banUser(
  String userId, {
  required String reason,
  int durationHours = 24,
}) async {
  try {
    final response = await http
        .post(
          Uri.parse('${ApiConfig.adminApiBaseUrl}/admin/users/$userId/ban'),
          headers: ApiConfig.adminHeaders,
          body: jsonEncode({
            'reason': reason,
            'durationHours': durationHours,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (kDebugMode) {
      print('🔍 Ban User Response: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');
    }

    // ✅ Response Validation
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      if (data['success'] == true) {
        return AdminResult.success(
          message: data['message'] ?? 'User banned successfully',
          data: {
            'userId': data['userId'],
            'reason': data['reason'],
            'durationHours': data['durationHours'],
            'expiresAt': data['expiresAt'],
          },
        );
      } else {
        return AdminResult.error(
          error: data['error'] ?? 'Ban failed without error message',
        );
      }
    } else if (response.statusCode == 401) {
      return AdminResult.error(error: 'Unauthorized - check admin token');
    } else if (response.statusCode == 400) {
      final data = jsonDecode(response.body);
      return AdminResult.error(error: data['error'] ?? 'Invalid request');
    } else {
      return AdminResult.error(
        error: 'Server error: ${response.statusCode}',
      );
    }
  } on SocketException {
    return AdminResult.error(error: 'No internet connection');
  } on TimeoutException {
    return AdminResult.error(error: 'Request timeout');
  } catch (e) {
    if (kDebugMode) print('❌ Ban user error: $e');
    return AdminResult.error(error: e.toString());
  }
}
```

**AKTUALISIERT: Mute User mit Response Validation**

```dart
static Future<AdminResult> muteUser(
  String userId, {
  required String reason,
  int durationMinutes = 60,
}) async {
  try {
    final response = await http
        .post(
          Uri.parse('${ApiConfig.adminApiBaseUrl}/admin/users/$userId/mute'),
          headers: ApiConfig.adminHeaders,
          body: jsonEncode({
            'reason': reason,
            'durationMinutes': durationMinutes,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (kDebugMode) {
      print('🔍 Mute User Response: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      if (data['success'] == true) {
        return AdminResult.success(
          message: data['message'] ?? 'User muted successfully',
          data: {
            'userId': data['userId'],
            'reason': data['reason'],
            'durationMinutes': data['durationMinutes'],
            'expiresAt': data['expiresAt'],
          },
        );
      } else {
        return AdminResult.error(
          error: data['error'] ?? 'Mute failed',
        );
      }
    } else {
      return AdminResult.error(error: 'HTTP ${response.statusCode}');
    }
  } catch (e) {
    return AdminResult.error(error: e.toString());
  }
}
```

**NEU: Check User Status**

```dart
static Future<AdminResult> getUserStatus(String userId) async {
  try {
    final response = await http
        .get(
          Uri.parse('${ApiConfig.adminApiBaseUrl}/admin/users/$userId/status'),
          headers: ApiConfig.adminHeaders,
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      if (data['success'] == true) {
        return AdminResult.success(
          message: 'User status retrieved',
          data: {
            'userId': data['userId'],
            'isBanned': data['isBanned'],
            'isMuted': data['isMuted'],
            'banInfo': data['banInfo'],
            'muteInfo': data['muteInfo'],
          },
        );
      }
    }
    
    return AdminResult.error(error: 'Failed to get user status');
  } catch (e) {
    return AdminResult.error(error: e.toString());
  }
}
```

---

## 📋 SCHRITT 4: UI INTEGRATION

### Admin Screen - Ban/Mute Buttons mit Feedback

```dart
// lib/screens/admin/user_moderation_screen_v16.dart

Future<void> _handleBanUser(String userId) async {
  // Show loading
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Center(child: CircularProgressIndicator()),
  );

  // Call admin service
  final result = await WorldAdminService.banUser(
    userId,
    reason: 'Violation of community guidelines',
    durationHours: 24,
  );

  // Close loading
  Navigator.of(context).pop();

  // Show result
  if (result.success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ ${result.message}'),
        backgroundColor: Colors.green,
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ ${result.error}'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

---

## 🧪 TESTING CHECKLIST

- [ ] API Config URLs aktualisiert
- [ ] WebRTC Service mit neuem Signaling getestet
- [ ] Admin Service Response Validation funktioniert
- [ ] Ban User zeigt Success/Error Messages
- [ ] Mute User zeigt Success/Error Messages
- [ ] User Status Abfrage funktioniert
- [ ] Voice Chat verbindet erfolgreich
- [ ] WebSocket bleibt stabil (kein Disconnect)

---

## 📚 WEITERE RESSOURCEN

- **Backend Deployment**: `BACKEND_V3.2_DEPLOYMENT.md`
- **Test Scripts**: `test_backend_v3.2.sh`
- **API Reference**: Backend v3.2 Health Check Endpoint

---

**INTEGRATION COMPLETE!** 🎉
