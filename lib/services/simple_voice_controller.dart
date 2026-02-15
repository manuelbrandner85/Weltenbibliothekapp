/// 🎙️ SIMPLE VOICE CONTROLLER - Backward Compatibility Wrapper
/// 
/// This is a compatibility layer for widgets still using SimpleVoiceController.
/// All functionality is delegated to WebRTCVoiceService.
library;

import 'webrtc_voice_service.dart';

/// Export WebRTCVoiceService for direct access
export 'webrtc_voice_service.dart';

/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// 🔄 BACKWARD COMPATIBILITY WRAPPER
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// 
/// Widgets können weiterhin SimpleVoiceController verwenden.
/// Intern wird WebRTCVoiceService genutzt.
class SimpleVoiceController {
  // Delegate to WebRTCVoiceService singleton
  static final WebRTCVoiceService _service = WebRTCVoiceService();

  // Expose all public methods from WebRTCVoiceService
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
  Future<void> setMuted(bool muted) => _service.toggleMute();
  
  // Push-to-talk methods
  Future<void> startPushToTalk() async {
    await _service.toggleMute(); // Unmute
  }
  
  Future<void> stopPushToTalk() async {
    await _service.toggleMute(); // Mute
  }
  
  // Expose getters
  bool get isMuted => _service.isMuted;
  bool get isConnected => _service.state == VoiceConnectionState.connected;
  bool get isInCall => _service.state == VoiceConnectionState.connected;
  List<VoiceParticipant> get participants => _service.participants;
}
