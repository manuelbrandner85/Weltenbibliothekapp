# 🎤 WELTENBIBLIOTHEK - WebRTC ARCHITECTURE

## ✅ STABLE PRODUCTION SOLUTION

### **Primary WebRTC Service**
- **File**: `lib/services/webrtc_voice_service.dart` (31KB, 63+ methods)
- **Status**: ✅ **STABLE & PRODUCTION-READY**
- **Used by**: Materie & Energie Live Chat Screens
- **Features**:
  - Backend-first flow with session tracking
  - Voice room join/leave with backend sync
  - Mute/unmute with real-time updates
  - Speaking detection & audio visualization
  - Admin controls (kick, ban, mute)
  - Connection state management
  - Error handling & recovery
  - Session tracking & analytics

### **Voice Chat UI**
- **File**: `lib/screens/shared/modern_voice_chat_screen.dart`
- **Status**: ✅ **UNIFIED ACROSS BOTH WORLDS**
- **Features**:
  - 2×5 Grid layout (max 10 participants)
  - Active speaker highlighting
  - Speaking animations
  - Admin controls (long-press menu)
  - Room full indicator
  - Reconnecting state
  - World-specific theming (Materie red, Energie purple)

### **Voice Participant Model**
- **File**: `lib/services/webrtc_voice_service.dart` (class VoiceParticipant)
- **Fields**:
  - `userId` - Unique user identifier
  - `username` - Display name
  - `isMuted` - Microphone state
  - `isSpeaking` - Active speaker detection
  - `peerConnection` - WebRTC peer connection
  - `stream` - Media stream
  - `avatarEmoji` - User avatar
  - `isSelf` - Is current user
  - `handRaised` - Hand raised state
  - `volume` - Volume level (0.0-1.0)
  - `role` - Voice role (speaker, listener, participant)

---

## 🗑️ DEPRECATED (DO NOT USE)

### **Legacy Services** (Kept for compatibility, DO NOT EXTEND)
- `lib/services/simple_voice_service.dart` - Minimalistic WebRTC (14KB)
- `lib/services/simple_voice_controller.dart` - Simple controller (61KB)
- `lib/services/simple_voice_call_controller.dart` - Basic call controller

**Note**: These are kept for some widgets but should NOT be used in new code.
Use `webrtc_voice_service.dart` instead.

### **Removed Redundant Screens**
- ❌ `lib/screens/shared/telegram_voice_screen.dart` - DELETED (used SimpleVoiceController)
- ❌ `lib/screens/shared/telegram_voice_chat_screen.dart` - DELETED (redundant)
- ❌ `lib/screens/test/simple_voice_test_screen.dart` - DELETED (test only)

### **Removed Backup Files**
- ❌ `lib/services/webrtc_voice_service.backup.dart` - DELETED
- ❌ `lib/services/webrtc_voice_service.old.dart` - DELETED
- ❌ `lib/controllers/chat_room_controller_old.dart` - DELETED

---

## 🌍 INTEGRATION - Materie & Energie Worlds

### **Materie World**
- **Chat Screen**: `lib/screens/materie/materie_live_chat_screen.dart`
- **WebRTC Service**: `WebRTCVoiceService()`
- **Voice UI**: `ModernVoiceChatScreen` with `accentColor: Colors.red`
- **Theme**: Red accent, conspiracy-focused

### **Energie World**
- **Chat Screen**: `lib/screens/energie/energie_live_chat_screen.dart`
- **WebRTC Service**: `WebRTCVoiceService()`
- **Voice UI**: `ModernVoiceChatScreen` with `accentColor: Color(0xFF9B51E0)`
- **Theme**: Purple accent, spiritual-focused

### **Consistency**
✅ **Both worlds use identical WebRTC implementation**
✅ **Both worlds use ModernVoiceChatScreen**
✅ **Only theming differs (colors)**

---

## 📋 USAGE GUIDE

### **Joining a Voice Room**
```dart
final voiceService = WebRTCVoiceService();

await voiceService.joinRoom(
  roomId: 'materie_main',
  userId: 'user_123',
  username: 'John Doe',
  avatarEmoji: '👤',
);
```

### **Leaving a Voice Room**
```dart
await voiceService.leaveRoom();
```

### **Mute/Unmute**
```dart
await voiceService.mute();
await voiceService.unmute();
```

### **Opening Voice Chat UI**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ModernVoiceChatScreen(
      roomId: 'room_id',
      roomName: 'Voice Chat',
      userId: _userId,
      username: _username,
      accentColor: Colors.red, // World-specific color
    ),
  ),
);
```

---

## 🔧 MAINTENANCE NOTES

- **DO NOT** create new voice chat screens
- **DO NOT** extend simple_voice_service.dart
- **DO** use webrtc_voice_service.dart for all new features
- **DO** use ModernVoiceChatScreen for UI
- **DO** maintain consistency across both worlds
- **DO** test on both Android and Web platforms

---

## 📊 ARCHITECTURE SUMMARY

```
WELTENBIBLIOTHEK
├── lib/services/
│   ├── webrtc_voice_service.dart ✅ PRIMARY (31KB)
│   ├── simple_voice_service.dart ⚠️  LEGACY (14KB)
│   └── simple_voice_controller.dart ⚠️  LEGACY (61KB)
├── lib/screens/
│   ├── materie/
│   │   └── materie_live_chat_screen.dart ✅ USES WebRTCVoiceService
│   ├── energie/
│   │   └── energie_live_chat_screen.dart ✅ USES WebRTCVoiceService
│   └── shared/
│       └── modern_voice_chat_screen.dart ✅ UNIFIED UI
└── lib/providers/
    └── webrtc_call_provider.dart ✅ RIVERPOD PROVIDER
```

---

**Last Updated**: 2026-02-14
**Architecture Version**: 2.0 (Unified WebRTC)
