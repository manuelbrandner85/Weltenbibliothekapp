/// 📞 WEBRTC CALL STATE - SINGLE SOURCE OF TRUTH
/// Deterministic state model for WebRTC group calls
/// 
/// Features:
/// - Max 10 participants enforcement
/// - Deterministic state machine
/// - Active speaker detection
/// - Auto-reconnect tracking
/// - Admin role integration
library;

import 'package:freezed_annotation/freezed_annotation.dart';
import '../services/webrtc_participant.dart';

part 'webrtc_call_state.freezed.dart';
// ⚠️ NO JSON: WebRTCParticipant contains non-serializable WebRTC objects

/// Connection state enum with deterministic transitions
enum CallConnectionState {
  idle,          // No active call
  connecting,    // Establishing connection
  connected,     // Active call
  reconnecting,  // 🆕 Auto-reconnect in progress
  disconnected,  // Call ended
  error         // Error occurred
}

/// Exception for room capacity limit
class RoomFullException implements Exception {
  final String message;
  final int currentCount;
  final int maxCapacity;
  
  RoomFullException(this.message, {this.currentCount = 0, this.maxCapacity = 10});
  
  @override
  String toString() => 'RoomFullException: $message ($currentCount/$maxCapacity)';
}

/// Immutable WebRTC call state
@freezed
class WebRTCCallState with _$WebRTCCallState {
  const factory WebRTCCallState({
    // Connection
    @Default(CallConnectionState.idle) CallConnectionState connectionState,
    String? roomId,
    String? roomName,
    
    // Participants (max 10)
    @Default([]) List<WebRTCParticipant> participants,
    @Default(10) int maxParticipants,
    
    // Active speaker
    String? activeSpeakerId,
    @Default({}) Map<String, double> speakingLevels, // userId -> volume level
    
    // Local user state
    String? localUserId,
    @Default(false) bool isLocalMuted,
    @Default(false) bool isPushToTalk,
    
    // Admin
    @Default(false) bool isAdmin,
    @Default(false) bool isRootAdmin,
    
    // Reconnection
    @Default(0) int reconnectAttempts,
    @Default(3) int maxReconnectAttempts,
    DateTime? lastReconnectAt,
    
    // Error tracking
    String? errorMessage,
    DateTime? errorOccurredAt,
    
    // Timestamps
    DateTime? connectedAt,
    DateTime? disconnectedAt,
  }) = _WebRTCCallState;
  
  // ⚠️ NO fromJson: State contains non-serializable WebRTC objects
}

/// Extension methods for business logic
extension WebRTCCallStateX on WebRTCCallState {
  /// Check if room is full
  bool get isRoomFull => participants.length >= maxParticipants;
  
  /// Check if can join room
  bool get canJoinRoom => !isRoomFull && connectionState == CallConnectionState.idle;
  
  /// Check if should reconnect
  bool get shouldReconnect => 
      connectionState == CallConnectionState.reconnecting &&
      reconnectAttempts < maxReconnectAttempts;
  
  /// Check if call is active
  bool get isCallActive => 
      connectionState == CallConnectionState.connected ||
      connectionState == CallConnectionState.reconnecting;
  
  /// Get participant by userId
  WebRTCParticipant? getParticipant(String userId) {
    try {
      return participants.firstWhere((p) => p.userId == userId);
    } catch (_) {
      return null;
    }
  }
  
  /// Get participant count
  int get participantCount => participants.length;
  
  /// Get active speaker
  WebRTCParticipant? get activeSpeaker => 
      activeSpeakerId != null ? getParticipant(activeSpeakerId!) : null;
  
  /// Check if user is active speaker
  bool isActiveSpeaker(String userId) => activeSpeakerId == userId;
  
  /// Get connected participants only
  List<WebRTCParticipant> get connectedParticipants =>
      participants.where((p) => p.isConnected).toList();
  
  /// Get speaking participants
  List<WebRTCParticipant> get speakingParticipants =>
      participants.where((p) => p.isSpeaking && !p.isMuted).toList();
}
