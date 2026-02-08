/// 🎙️ SIMPLE VOICE CALL CONTROLLER
/// 
/// Vereinfachter Controller für Voice Calls
/// Nutzt SimpleVoiceService
library;

import 'package:flutter/foundation.dart';
import 'simple_voice_service.dart';

class SimpleVoiceCallController extends ChangeNotifier {
  final SimpleVoiceService _voiceService = SimpleVoiceService();

  /// Getters
  List<VoiceParticipant> get participants => _voiceService.participantsList;
  int get participantCount => _voiceService.participantCount;
  bool get isInCall => _voiceService.isInCall;
  bool get isMuted => _voiceService.isMuted;
  String? get currentRoomId => _voiceService.currentRoomId;

  SimpleVoiceCallController() {
    // Listen to voice service changes
    _voiceService.addListener(_onVoiceServiceChange);
  }

  void _onVoiceServiceChange() {
    notifyListeners();
  }

  /// Join voice room
  Future<bool> joinVoiceRoom({
    required String roomId,
    required String roomName,
    required String userId,
    required String username,
  }) async {
    print('🎙️ [SimpleVoiceCallController] Joining room: $roomName');
    
    final success = await _voiceService.joinVoiceRoom(
      roomId: roomId,
      userId: userId,
      username: username,
    );

    if (success) {
      print('✅ [SimpleVoiceCallController] Join successful');
    } else {
      print('❌ [SimpleVoiceCallController] Join failed');
    }

    return success;
  }

  /// Leave voice room
  Future<void> leaveVoiceRoom() async {
    print('🚪 [SimpleVoiceCallController] Leaving room');
    await _voiceService.leaveVoiceRoom();
  }

  /// Toggle mute
  Future<void> toggleMute() async {
    await _voiceService.toggleMute();
  }

  /// User joined (from signaling)
  void onUserJoined(String userId, String username) {
    print('➕ [SimpleVoiceCallController] User joined: $username');
    _voiceService.onUserJoined(userId: userId, username: username);
  }

  /// User left (from signaling)
  void onUserLeft(String userId) {
    print('➖ [SimpleVoiceCallController] User left: $userId');
    _voiceService.onUserLeft(userId);
  }

  @override
  void dispose() {
    _voiceService.removeListener(_onVoiceServiceChange);
    super.dispose();
  }
}
