/// 🎙️ WEBRTC PARTICIPANT WRAPPER
/// Enhanced Participant with WebRTC Stream & Peer Connection
/// 
/// CRITICAL: Each participant MUST have:
/// - Unique userId
/// - Own RTCPeerConnection
/// - Own MediaStream
/// 
/// This prevents stream/peer conflicts and audio overlap
library;

import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../models/chat_models.dart';
import 'webrtc_voice_service.dart'; // ✅ UNIFIED: VoiceParticipant & VoiceRole

class WebRTCParticipant {
  final String userId;
  final String username;
  final String? avatarEmoji;
  
  // ✅ CRITICAL: Each participant has their own peer connection
  RTCPeerConnection? peerConnection;
  
  // ✅ CRITICAL: Each participant has their own media stream
  MediaStream? audioStream;
  
  // State
  bool isMuted;
  bool isSpeaking;
  bool handRaised;
  double volume;
  VoiceRole role;  // ✅ ADD: Voice role for room modes
  
  // Timestamps for debugging
  final DateTime joinedAt;
  DateTime? lastSeenAt;
  
  WebRTCParticipant({
    required this.userId,
    required this.username,
    this.avatarEmoji,
    this.peerConnection,
    this.audioStream,
    this.isMuted = false,
    this.isSpeaking = false,
    this.handRaised = false,
    this.volume = 1.0,
    this.role = VoiceRole.participant,  // ✅ ADD: Default role
    DateTime? joinedAt,
  }) : joinedAt = joinedAt ?? DateTime.now();
  
  /// Convert to VoiceParticipant model for UI
  VoiceParticipant toVoiceParticipant() {
    return VoiceParticipant(
      userId: userId,
      username: username,
      avatarEmoji: avatarEmoji,
      isMuted: isMuted,
      isSpeaking: isSpeaking,
      handRaised: handRaised,
      volume: volume,
      role: role,  // ✅ ADD: Include role
    );
  }
  
  /// Check if participant has audio
  bool get hasAudio => audioStream != null && audioStream!.getAudioTracks().isNotEmpty;
  
  /// Check if peer connection is active
  bool get isConnected => 
      peerConnection != null && 
      peerConnection!.connectionState == RTCPeerConnectionState.RTCPeerConnectionStateConnected;
  
  /// Cleanup resources
  Future<void> dispose() async {
    // Close peer connection
    if (peerConnection != null) {
      await peerConnection!.close();
      peerConnection = null;
    }
    
    // Dispose audio stream
    if (audioStream != null) {
      audioStream!.dispose();
      audioStream = null;
    }
  }
  
  @override
  String toString() {
    return 'WebRTCParticipant('
        'userId: $userId, '
        'username: $username, '
        'hasAudio: $hasAudio, '
        'isConnected: $isConnected, '
        'isSpeaking: $isSpeaking'
        ')';
  }
}
