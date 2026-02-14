# 🔧 **Exception-Handling Integration - Praktische Beispiele**

**Datum:** 2025-02-13  
**Projekt:** Weltenbibliothek V101

---

## 📚 **Erstellte Dateien**

✅ **lib/core/exceptions/app_exception.dart** (4.2 KB)
- Basis-Exception-Klasse
- ExceptionSeverity Enum
- JSON-Export für Analytics

✅ **lib/core/exceptions/specialized_exceptions.dart** (10.9 KB)
- NetworkException
- BackendException
- ValidationException
- AuthException
- StorageException
- VoiceException / RoomFullException
- ConfigurationException
- BusinessLogicException
- TimeoutException

✅ **lib/core/exceptions/exception_guard.dart** (10.8 KB)
- guard() - Async Guard-Funktion
- guardSync() - Synchrone Guard-Funktion
- guardApi() - Spezialisiert für API-Calls
- guardStorage() - Spezialisiert für Storage
- guardWithRetry() - Mit automatischem Retry
- guardWithTimeout() - Mit Timeout

---

## 🎯 **Integration in VoiceBackendService**

### **Vorher: Ohne Guard**

```dart
// lib/services/voice_backend_service.dart (ALT)
static Future<BackendJoinResponse> join({
  required String roomId,
  required String userId,
  required String username,
  required String world,
}) async {
  final url = Uri.parse('$_baseUrl/api/voice/join');
  
  final response = await http.post(
    url,
    headers: {
      'Authorization': 'Bearer $_apiToken',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'room_id': roomId,
      'user_id': userId,
      'username': username,
      'world': world,
    }),
  ).timeout(_timeout);
  
  // ... Rest des Codes
}
```

---

### **Nachher: Mit Guard & Exceptions**

```dart
// lib/services/voice_backend_service.dart (NEU)
import '../core/exceptions/exception_guard.dart';
import '../core/exceptions/specialized_exceptions.dart';

class VoiceBackendService {
  // ... bestehende Konstanten

  /// Join Voice Room mit verbessertem Error-Handling
  static Future<BackendJoinResponse> join({
    required String roomId,
    required String userId,
    required String username,
    required String world,
  }) async {
    return guardApi(
      () async {
        final url = Uri.parse('$_baseUrl/api/voice/join');
        
        if (kDebugMode) {
          debugPrint('📞 [VOICE API] Joining voice room');
          debugPrint('   Room: $roomId');
          debugPrint('   User: $username ($userId)');
          debugPrint('   World: $world');
        }
        
        final response = await http.post(
          url,
          headers: {
            'Authorization': 'Bearer $_apiToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'room_id': roomId,
            'user_id': userId,
            'username': username,
            'world': world,
          }),
        ).timeout(
          _timeout,
          onTimeout: () {
            throw TimeoutException(
              'Voice join request timed out',
              timeout: _timeout,
              operation: 'Voice Join',
            );
          },
        );
        
        // HTTP-Status prüfen
        if (response.statusCode == 401) {
          throw AuthException('Unauthorized API access');
        }
        
        if (response.statusCode == 404) {
          throw BackendException.notFound('/api/voice/join');
        }
        
        if (response.statusCode >= 500) {
          throw BackendException.serverError('/api/voice/join');
        }
        
        if (response.statusCode != 200) {
          throw BackendException(
            'Voice join failed with status ${response.statusCode}',
            statusCode: response.statusCode,
            endpoint: '/api/voice/join',
            responseBody: response.body,
          );
        }
        
        // Response parsen
        final data = jsonDecode(response.body);
        
        if (data['success'] != true) {
          // Spezielle Behandlung für "Room Full"
          if (data['error']?.contains('full') == true) {
            throw RoomFullException(
              roomId: roomId,
              currentCount: data['current_participant_count'] ?? 10,
              maxCount: data['max_participants'] ?? 10,
            );
          }
          
          throw BackendException(
            data['error'] ?? 'Voice join failed',
            statusCode: response.statusCode,
            endpoint: '/api/voice/join',
          );
        }
        
        return BackendJoinResponse(
          sessionId: data['session_id'],
          currentParticipantCount: data['current_participant_count'],
          maxParticipants: data['max_participants'],
          participants: (data['participants'] as List? ?? [])
              .map((p) => VoiceParticipant.fromJson(p))
              .toList(),
        );
      },
      operationName: 'Voice Join',
      url: '$_baseUrl/api/voice/join',
      method: 'POST',
      context: {
        'roomId': roomId,
        'userId': userId,
        'username': username,
        'world': world,
      },
    );
  }
}
```

---

## 🎯 **Integration in WebRTCVoiceService**

### **Vorher: try-catch mit generischen Exceptions**

```dart
// lib/services/webrtc_voice_service.dart (ALT)
Future<bool> joinRoom({...}) async {
  try {
    // Backend-First: Phase 1
    final backendResponse = await VoiceBackendService.join(...);
    
    // Phase 2: Session Tracking
    await _sessionTracker.startSession(...);
    
    // Phase 3: WebRTC Connection
    await _setupWebRTC();
    
    return true;
    
  } catch (e) {
    if (kDebugMode) {
      debugPrint('❌ WebRTC: Error joining room - $e');
    }
    _callState = CallConnectionState.error;
    return false;
  }
}
```

---

### **Nachher: Mit spezifischen Exception-Typen**

```dart
// lib/services/webrtc_voice_service.dart (NEU)
import '../core/exceptions/exception_guard.dart';
import '../core/exceptions/specialized_exceptions.dart';

Future<bool> joinRoom({
  required String roomId,
  required String userId,
  required String username,
  required String world,
  bool pushToTalk = false,
}) async {
  return guard(
    () async {
      _setState(CallConnectionState.connecting);
      
      // ✅ PHASE 1: Backend Session Creation
      if (kDebugMode) {
        debugPrint('📞 [VOICE] Phase 1: Backend session creation');
      }
      
      final backendResponse = await VoiceBackendService.join(
        roomId: roomId,
        userId: userId,
        username: username,
        world: world,
      );
      
      if (kDebugMode) {
        debugPrint('✅ [VOICE] Backend session created: ${backendResponse.sessionId}');
      }
      
      // ✅ PHASE 2: Session Tracking
      if (kDebugMode) {
        debugPrint('📊 [VOICE] Phase 2: Starting session tracker');
      }
      
      await _sessionTracker.startSession(
        roomId: roomId,
        userId: userId,
        username: username,
        world: world,
        sessionId: backendResponse.sessionId,
      );
      
      // ✅ PHASE 3: WebRTC Connection
      if (kDebugMode) {
        debugPrint('🔌 [VOICE] Phase 3: Establishing WebRTC connection');
      }
      
      await _setupWebRTCConnection();
      
      // ✅ PHASE 4: Provider Update
      if (kDebugMode) {
        debugPrint('🔄 [VOICE] Phase 4: Updating provider state');
      }
      
      _setState(CallConnectionState.connected);
      _participants.addAll({
        for (var p in backendResponse.participants)
          p.userId: p
      });
      
      if (kDebugMode) {
        debugPrint('🎉 [VOICE] All phases complete! Connected to room: $roomId');
      }
      
      return true;
    },
    operationName: 'Join Voice Room',
    context: {
      'roomId': roomId,
      'userId': userId,
      'username': username,
      'world': world,
      'pushToTalk': pushToTalk,
    },
    onError: (error, stackTrace) async {
      // Error-Recovery: Cleanup
      if (kDebugMode) {
        debugPrint('🧹 [VOICE] Error occurred, performing cleanup...');
      }
      
      await _cleanup();
      _setState(CallConnectionState.error);
      
      // Log spezifischen Fehler-Typ
      if (error is RoomFullException) {
        if (kDebugMode) {
          debugPrint('⚠️ [VOICE] Room is full: ${error.currentCount}/${error.maxCount}');
        }
      } else if (error is AuthException) {
        if (kDebugMode) {
          debugPrint('🔒 [VOICE] Authentication failed');
        }
      } else if (error is NetworkException) {
        if (kDebugMode) {
          debugPrint('🌐 [VOICE] Network error: ${error.statusCode}');
        }
      }
      
      return false; // Fallback-Wert
    },
  );
}
```

---

## 🎨 **UI Integration - Error-Handling**

### **Beispiel: Voice-Chat-Screen**

```dart
// lib/screens/materie/materie_live_chat_screen.dart
Future<void> _joinVoiceRoom() async {
  setState(() => _isJoining = true);
  
  try {
    final success = await _voiceService.joinRoom(
      roomId: _selectedRoom,
      userId: _userId,
      username: _username,
      world: 'materie',
    );
    
    if (success) {
      setState(() => _isInVoiceChat = true);
      _showSnackBar('✅ Voice-Chat beigetreten!', Colors.green);
    }
    
  } on RoomFullException catch (e) {
    // Raum voll - Spezifische Nachricht
    _showSnackBar(
      '⚠️ Voice-Room ist voll (${e.currentCount}/${e.maxCount})',
      Colors.orange,
    );
    
  } on AuthException catch (e) {
    // Auth-Fehler - Neu anmelden
    _showDialog(
      title: 'Authentifizierung fehlgeschlagen',
      message: 'Bitte melden Sie sich erneut an.',
      actions: [
        TextButton(
          onPressed: () => _handleLogout(),
          child: const Text('Neu anmelden'),
        ),
      ],
    );
    
  } on NetworkException catch (e) {
    // Netzwerk-Fehler - Retry-Option
    _showDialog(
      title: 'Netzwerkfehler',
      message: 'Verbindung fehlgeschlagen. Erneut versuchen?',
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            _joinVoiceRoom(); // Retry
          },
          child: const Text('Erneut versuchen'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
      ],
    );
    
  } on TimeoutException catch (e) {
    // Timeout - Server-Probleme
    _showSnackBar(
      '⏱️ Zeitüberschreitung (${e.timeout.inSeconds}s)',
      Colors.red,
    );
    
  } on VoiceException catch (e) {
    // Voice-spezifischer Fehler
    _showSnackBar('🎤 Voice-Fehler: ${e.message}', Colors.red);
    
  } on AppException catch (e) {
    // Generischer App-Fehler
    _showSnackBar('❌ ${e.message}', Colors.red);
    
  } finally {
    setState(() => _isJoining = false);
  }
}
```

---

## 📊 **Vergleich: Fehler-Behandlung**

| Szenario | Vorher | Nachher |
|----------|--------|---------|
| **Raum voll** | Generic "Error joining room" | ✅ "Room voll (10/10)" mit Teilnehmerzahl |
| **Netzwerk-Fehler** | Generic Exception | ✅ NetworkException mit Status-Code & URL |
| **Auth-Fehler** | Nicht unterscheidbar | ✅ AuthException → Logout-Flow |
| **Timeout** | Generic timeout | ✅ TimeoutException mit Dauer |
| **Kontext** | ❌ Keine Infos | ✅ roomId, userId, world, etc. |
| **Recovery** | ❌ Nicht möglich | ✅ Automatisches Cleanup |
| **Logging** | Manuell | ✅ Automatisch mit Debug-Prints |

---

## 🎯 **Verwendungs-Empfehlungen**

### **Wann welchen Exception-Typ?**

| Fehler-Typ | Verwendung | Exception-Klasse |
|------------|------------|------------------|
| HTTP-Request-Fehler | API-Calls, Downloads | `NetworkException` |
| Backend-API-Fehler | REST-API, GraphQL | `BackendException` |
| Validierungs-Fehler | Form-Inputs, User-Daten | `ValidationException` |
| Auth-Probleme | Login, Token, Permissions | `AuthException` |
| Storage-Fehler | Hive, SharedPrefs, Files | `StorageException` |
| Voice/WebRTC-Fehler | Voice-Chat, WebRTC | `VoiceException` |
| Timeout-Probleme | Lange Operations | `TimeoutException` |
| Config-Fehler | Setup, Initialization | `ConfigurationException` |
| Business-Logic | Domain-Rules | `BusinessLogicException` |

---

## 🚀 **Migrations-Plan**

### **Phase 1: Core Services (Diese Woche)**
- [x] Exception-Klassen erstellt
- [ ] VoiceBackendService migrieren
- [ ] WebRTCVoiceService migrieren
- [ ] StorageService migrieren

### **Phase 2: UI Integration (Nächste Woche)**
- [ ] Voice-Chat-Screens aktualisieren
- [ ] Error-Dialogs implementieren
- [ ] SnackBar-Messages anpassen

### **Phase 3: Testing (Danach)**
- [ ] Error-Szenarien testen
- [ ] Recovery-Flows validieren
- [ ] Analytics-Integration

---

## 📝 **Checkliste für neue Services**

Wenn du einen neuen Service erstellst:

- [ ] `import '../core/exceptions/exception_guard.dart';`
- [ ] `import '../core/exceptions/specialized_exceptions.dart';`
- [ ] Verwende `guard()` für async Methoden
- [ ] Werfe spezifische Exception-Typen statt generic Exception
- [ ] Gib `operationName` und `context` mit
- [ ] Implementiere `onError` für Recovery (falls sinnvoll)
- [ ] Teste Error-Szenarien

---

## 🎉 **Zusammenfassung**

✅ **3 neue Exception-Dateien** erstellt (26 KB Code)  
✅ **10 spezialisierte Exception-Typen** implementiert  
✅ **6 Guard-Funktionen** mit verschiedenen Features  
✅ **Beispiel-Integrationen** für VoiceBackendService & WebRTC  
✅ **UI Error-Handling** Patterns dokumentiert  

**Nächster Schritt:** Beginne mit der Migration von `VoiceBackendService`!

---

*Erstellt am: 2025-02-13*  
*Autor: AI Development Team*
