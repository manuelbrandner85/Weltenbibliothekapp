/// 🎙️ SIMPLE VOICE CONTROLLER - Backward Compatibility Wrapper
/// 
/// This is a compatibility layer for widgets still using SimpleVoiceController.
/// All functionality is delegated to SimpleVoiceService.
library;

import 'simple_voice_service.dart';

/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// 🔄 BACKWARD COMPATIBILITY WRAPPER
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// 
/// Widgets können weiterhin SimpleVoiceController verwenden.
/// Intern wird SimpleVoiceService genutzt.
class SimpleVoiceController {
  // Delegate to SimpleVoiceService singleton
  static final SimpleVoiceService _service = SimpleVoiceService();

  // Expose all public methods from SimpleVoiceService
  Future<bool> joinRoom({
    required String roomId,
    required String userId,
    required String username,
    required String world,
    bool pushToTalk = false,
  }) => _service.joinRoom(
    roomId: roomId,
    userId: userId,
    username: username,
    world: world,
    pushToTalk: pushToTalk,
  );

  Future<void> leaveRoom() => _service.leaveRoom();
  Future<void> toggleMute() => _service.toggleMute();
  Future<void> setMuted(bool muted) => _service.setMuted(muted);
  
  // Expose getters
  bool get isMuted => _service.isMuted;
  bool get isConnected => _service.isConnected;
  List<VoiceParticipant> get participants => _service.participants;
}

/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// 📦 EXPORT
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// 
/// Widgets können jetzt beide Klassen verwenden:
/// 
/// ```dart
/// // Option 1: Alte API (funktioniert weiterhin)
/// final controller = SimpleVoiceController();
/// 
/// // Option 2: Neue API (empfohlen)
/// final service = SimpleVoiceService();
/// ```
export 'simple_voice_service.dart';
