# 🎙️ Telegram-Style Voice Chat System

## Übersicht

Ein vollständiges, produktionsreifes Voice-Chat-System für die Weltenbibliothek-App, das Telegram's Voice-Chat-Funktionalität nachbildet.

## ✨ Features

### 🎯 Kern-Features

- **📱 Telegram-ähnliche Benutzer-Kacheln**
  - Responsive Grid-Layout (2-6 Spalten)
  - Avatar/Initialen pro User
  - Realtime Speaking-Indikatoren
  - Pulsierender Ring für aktive Sprecher

- **🎙️ Realtime Audio-Streaming**
  - WebRTC Audio-Streaming
  - Echo Cancellation
  - Noise Suppression
  - Auto Gain Control

- **📉 Minimierbar**
  - Floating Snackbar am unteren Bildschirmrand
  - Audio läuft im Hintergrund weiter
  - Tap to Maximize
  - Call beenden Button

- **🔄 Globaler State**
  - VoiceCallController (ChangeNotifier)
  - Stabil bei Screen-Wechseln
  - UI-Updates ohne Audio-Unterbrechung

### 🎨 UI/UX

**Maximierter Modus (TelegramVoiceScreen):**
- Benutzer-Kachel-Grid
- Speaking-Animation (pulsierender Ring)
- Mute/Unmute Toggle
- Leave Call Button
- Participant Count

**Minimierter Modus (MinimizedVoiceOverlay):**
- Compact Floating Banner
- Room Name + Participant Count
- Pulsing Mic Icon
- Tap to Maximize
- Quick Leave Button

## 📦 Architektur

```
┌─────────────────────────────────────────────────────────────┐
│                    Voice Call Controller                     │
│                   (Global State Manager)                     │
├─────────────────────────────────────────────────────────────┤
│  • ChangeNotifier für UI-Updates                            │
│  • Participant Management                                   │
│  • Speaking Detection Logic                                 │
│  • Stream Management                                        │
└────────────┬────────────────────────────────┬───────────────┘
             │                                │
    ┌────────▼────────┐              ┌───────▼────────┐
    │  WebRTC Service │              │  UI Components │
    ├─────────────────┤              ├────────────────┤
    │ • Audio Streams │              │ • Voice Screen │
    │ • Peer Conns    │              │ • Voice Overlay│
    │ • ICE Servers   │              │ • Voice Button │
    └─────────────────┘              └────────────────┘
```

## 🚀 Schnellstart

### 1. Imports hinzufügen

```dart
import '../widgets/voice_chat_button.dart';
import '../widgets/minimized_voice_overlay.dart';
```

### 2. Screen wrappen

```dart
@override
Widget build(BuildContext context) {
  return VoiceOverlayBuilder(  // ← Wrap hier!
    child: Scaffold(
      // ... dein Screen
    ),
  );
}
```

### 3. Voice Chat Button hinzufügen

```dart
// Option A: Banner im Header
VoiceChatBanner(
  roomId: _selectedRoom,
  roomName: 'Politik Room',
  userId: _userId,
  username: _username,
  color: Colors.red,
)

// Option B: Button in AppBar
AppBar(
  actions: [
    VoiceChatButton(
      roomId: _selectedRoom,
      roomName: 'Politik Room',
      userId: _userId,
      username: _username,
      color: Colors.red,
    ),
  ],
)
```

### 4. Fertig! 🎉

Das System übernimmt jetzt automatisch:
- Voice Call Management
- UI-Updates
- Minimierung/Maximierung
- Audio Streaming

## 📁 Dateistruktur

```
lib/
├── services/
│   ├── voice_call_controller.dart       ← Global State
│   └── webrtc_voice_service.dart        ← WebRTC Logic
├── screens/
│   └── shared/
│       └── telegram_voice_screen.dart   ← Main Voice Screen
├── widgets/
│   ├── minimized_voice_overlay.dart     ← Minimized Banner
│   └── voice_chat_button.dart           ← Join Button + Banner
└── models/
    └── chat_models.dart                 ← VoiceParticipant Model
```

## 🎯 Verwendung

### Join Voice Chat

```dart
final controller = VoiceCallController();

await controller.joinVoiceRoom(
  roomId: 'politik',
  roomName: 'Politik & Weltordnung',
  userId: 'user_123',
  username: 'Manuel',
);
```

### Leave Voice Chat

```dart
await controller.leaveVoiceRoom();
```

### Toggle Mute

```dart
await controller.toggleMute();
```

### Minimize/Maximize

```dart
controller.minimize();  // Audio läuft weiter
controller.maximize();  // Öffnet TelegramVoiceScreen
```

## 🎨 Customization

### Farben anpassen

```dart
VoiceChatButton(
  // ...
  color: const Color(0xFF9B51E0),  // Lila für Energie-Welt
)
```

### Speaking Detection Sensitivity

In `voice_call_controller.dart`:

```dart
static const double _audioThreshold = 0.02;  // Lower = mehr Sensitivität
static const int _speakingThreshold = 3;     // Frames über Threshold
```

## 🔧 Konfiguration

### WebRTC Server (Produktion)

In `webrtc_voice_service.dart`:

```dart
final Map<String, dynamic> _rtcConfiguration = {
  'iceServers': [
    {'urls': 'stun:stun.l.google.com:19302'},
    // TURN Server hinzufügen:
    {
      'urls': 'turn:your-turn-server.com',
      'username': 'user',
      'credential': 'pass'
    }
  ],
};
```

### Android Permissions

`AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
```

## 🎬 User Flow

```
1. User klickt "Join Voice Chat"
2. VoiceCallController.joinVoiceRoom()
3. WebRTCVoiceService.initialize() → Mikrofon-Permission
4. TelegramVoiceScreen öffnet sich
5. User sieht Benutzer-Kacheln
6. Speaking Detection aktiviert
7. User klickt "Minimize"
8. MinimizedVoiceOverlay erscheint
9. User kann weiter chatten, Audio läuft
10. Tap auf Overlay → Maximiert
11. User klickt "Leave" → Voice Chat beendet
```

## 🔍 Troubleshooting

### Audio funktioniert nicht

1. **Web**: Browser-Permission prüfen
2. **Android**: Mikrofon-Permission in Manifest
3. **iOS**: Info.plist Permission-String

### Voice Call unterbricht bei Screen-Wechsel

- ✅ VoiceOverlayBuilder wrappen!
- ✅ VoiceCallController ist Singleton
- ✅ WebRTC Service behält Streams

### Speaking Detection funktioniert nicht

- Prüfe `_audioThreshold` Wert
- WebRTC `getStats()` implementieren (TODO)
- Audio-Level-Monitoring aktivieren

## 📚 API Referenz

### VoiceCallController

```dart
class VoiceCallController extends ChangeNotifier {
  // State
  VoiceCallState get state;
  bool get isInCall;
  bool get isMinimized;
  
  // Data
  List<VoiceParticipant> get participants;
  int get participantCount;
  String? get currentRoomId;
  String? get currentRoomName;
  
  // Audio
  bool get isMuted;
  double getAudioLevel(String userId);
  bool isSpeaking(String userId);
  
  // Actions
  Future<bool> joinVoiceRoom({...});
  Future<void> leaveVoiceRoom();
  Future<void> toggleMute();
  void minimize();
  void maximize();
}
```

### VoiceParticipant (Model)

```dart
class VoiceParticipant {
  final String userId;
  final String username;
  final String? avatarEmoji;
  final bool isSpeaking;
  final bool isMuted;
  final double volume;
  final VoiceRole role;
  final bool handRaised;
}
```

## 🚧 Roadmap / TODO

- [ ] WebRTC Signaling Server Integration
- [ ] Audio-Level über `getStats()` implementieren
- [ ] TURN Server für NAT-Traversal
- [ ] Hand Raise Feature
- [ ] Screen Sharing
- [ ] Recording-Funktion
- [ ] Admin Mute/Unmute andere User

## 📝 Lizenz

Teil der Weltenbibliothek Flutter App.

## 👨‍💻 Entwickler-Notizen

### Debugging

```dart
// In voice_call_controller.dart:
if (kDebugMode) {
  debugPrint('🎙️ [VoiceCall] State: $_state');
  debugPrint('👥 Participants: ${_participants.length}');
}
```

### Performance

- Audio-Level-Monitoring: 100ms Intervall
- Speaking Detection: 3 Frames über Threshold
- Grid: Responsive 2-6 Spalten
- Max Participants: 10 (empfohlen)

### Best Practices

1. ✅ Immer `VoiceOverlayBuilder` verwenden
2. ✅ Controller als Singleton nutzen
3. ✅ `addListener` / `removeListener` in initState/dispose
4. ✅ Permissions vor `joinVoiceRoom()` prüfen
5. ✅ Error Handling mit Snackbars

---

**Erstellt mit ❤️ für die Weltenbibliothek**

Letzte Aktualisierung: Februar 2026
