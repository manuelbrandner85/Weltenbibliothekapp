/// 🎙️ WEBRTC CALL STATE PROVIDER
/// Riverpod StateNotifier for deterministic WebRTC state management
/// 
/// Features:
/// - Single source of truth for call state
/// - Deterministic state transitions
/// - Participant management (max 10)
/// - Auto-reconnect logic
/// - Admin action integration
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/webrtc_call_state.dart';
import '../services/webrtc_participant.dart';
import '../services/webrtc_voice_service.dart';

/// WebRTC Call StateNotifier
class WebRTCCallNotifier extends StateNotifier<WebRTCCallState> {
  final WebRTCVoiceService _voiceService;
  
  WebRTCCallNotifier(this._voiceService) : super(const WebRTCCallState()) {
    _initializeListeners();
  }
  
  /// Initialize listeners from voice service
  void _initializeListeners() {
    // Listen to participants stream
    _voiceService.participantsStream.listen((voiceParticipants) {
      // Convert VoiceParticipant to WebRTCParticipant
      final webrtcParticipants = voiceParticipants.map((vp) {
        return WebRTCParticipant(
          userId: vp.userId,
          username: vp.username,
          avatarEmoji: vp.avatarEmoji,
          isMuted: vp.isMuted,
          isSpeaking: vp.isSpeaking,
          peerConnection: vp.peerConnection,
          audioStream: vp.stream,
        );
      }).toList();
      
      state = state.copyWith(participants: webrtcParticipants);
      _updateActiveSpeaker();
    });
    
    // Listen to speaking stream (convert bool to double volume)
    _voiceService.speakingStream.listen((speakingMap) {
      final volumeMap = speakingMap.map((userId, isSpeaking) {
        return MapEntry(userId, isSpeaking ? 1.0 : 0.0);
      });
      
      state = state.copyWith(speakingLevels: volumeMap);
      _updateActiveSpeaker();
    });
  }
  
  /// Update active speaker based on speaking levels
  void _updateActiveSpeaker() {
    if (state.speakingLevels.isEmpty) {
      state = state.copyWith(activeSpeakerId: null);
      return;
    }
    
    // Find participant with highest speaking level
    final sorted = state.speakingLevels.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    if (sorted.isNotEmpty && sorted.first.value > 0.3) {
      state = state.copyWith(activeSpeakerId: sorted.first.key);
    } else {
      state = state.copyWith(activeSpeakerId: null);
    }
  }
  
  /// Join room with participant limit enforcement
  Future<void> joinRoom({
    required String roomId,
    required String roomName,
    required String userId,
    required String username,
    required String world,  // 🆕 World parameter
    bool isPushToTalk = false,
  }) async {
    try {
      // Check if already in a call
      if (state.isCallActive) {
        throw Exception('Already in an active call');
      }
      
      // Set connecting state
      state = state.copyWith(
        connectionState: CallConnectionState.connecting,
        roomId: roomId,
        roomName: roomName,
        localUserId: userId,
        isPushToTalk: isPushToTalk,
        errorMessage: null,
      );
      
      // Join via voice service (Backend-First Flow)
      await _voiceService.joinRoom(
        roomId: roomId,
        userId: userId,
        username: username,
        world: world,  // 🆕 Pass world parameter
        pushToTalk: isPushToTalk,
      );
      
      // Set connected state
      state = state.copyWith(
        connectionState: CallConnectionState.connected,
        connectedAt: DateTime.now(),
        reconnectAttempts: 0,
      );
      
      if (kDebugMode) {
        debugPrint('✅ WebRTC: Joined room $roomId as $username');
      }
      
    } on RoomFullException catch (e) {
      state = state.copyWith(
        connectionState: CallConnectionState.error,
        errorMessage: e.message,
        errorOccurredAt: DateTime.now(),
      );
      rethrow;
      
    } catch (e) {
      state = state.copyWith(
        connectionState: CallConnectionState.error,
        errorMessage: e.toString(),
        errorOccurredAt: DateTime.now(),
      );
      rethrow;
    }
  }
  
  /// Leave room
  Future<void> leaveRoom() async {
    try {
      await _voiceService.leaveRoom();
      
      state = state.copyWith(
        connectionState: CallConnectionState.disconnected,
        disconnectedAt: DateTime.now(),
        activeSpeakerId: null,
      );
      
      if (kDebugMode) {
        debugPrint('✅ WebRTC: Left room ${state.roomId}');
      }
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ WebRTC: Error leaving room: $e');
      }
    }
  }
  
  /// Toggle mute
  Future<void> toggleMute() async {
    try {
      if (state.isLocalMuted) {
        await _voiceService.unmute();
      } else {
        await _voiceService.mute();
      }
      
      state = state.copyWith(isLocalMuted: !state.isLocalMuted);
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ WebRTC: Error toggling mute: $e');
      }
    }
  }
  
  /// Auto-reconnect logic
  Future<void> attemptReconnect() async {
    if (!state.shouldReconnect) {
      if (kDebugMode) {
        debugPrint('⚠️ WebRTC: Cannot reconnect (max attempts reached)');
      }
      return;
    }
    
    state = state.copyWith(
      connectionState: CallConnectionState.reconnecting,
      reconnectAttempts: state.reconnectAttempts + 1,
      lastReconnectAt: DateTime.now(),
    );
    
    try {
      // Exponential backoff: 2^attempt seconds (4s, 8s, 16s)
      final delay = Duration(seconds: 2 << state.reconnectAttempts);
      await Future.delayed(delay);
      
      // Try to rejoin
      if (state.roomId != null && state.localUserId != null) {
        // Extract world from roomId (e.g., "materie_politik" → "materie")
        final world = state.roomId!.startsWith('materie') ? 'materie' : 'energie';
        
        await _voiceService.joinRoom(
          roomId: state.roomId!,
          userId: state.localUserId!,
          username: 'User', // TODO: Get from profile
          world: world,  // 🆕 World parameter
          pushToTalk: state.isPushToTalk,
        );
        
        state = state.copyWith(
          connectionState: CallConnectionState.connected,
          reconnectAttempts: 0,
          errorMessage: null,
        );
        
        if (kDebugMode) {
          debugPrint('✅ WebRTC: Reconnected successfully');
        }
      }
      
    } catch (e) {
      if (state.reconnectAttempts >= state.maxReconnectAttempts) {
        state = state.copyWith(
          connectionState: CallConnectionState.error,
          errorMessage: 'Reconnection failed after ${state.maxReconnectAttempts} attempts',
        );
      }
      
      if (kDebugMode) {
        debugPrint('❌ WebRTC: Reconnect attempt ${state.reconnectAttempts} failed: $e');
      }
    }
  }
  
  /// Admin: Kick user
  Future<void> kickUser(String userId) async {
    if (!state.isAdmin && !state.isRootAdmin) {
      throw Exception('Only admins can kick users');
    }
    
    if (state.localUserId == null) {
      throw Exception('Local user ID not set');
    }
    
    try {
      await _voiceService.kickUser(
        userId: userId,
        adminId: state.localUserId!,
      );
      
      if (kDebugMode) {
        debugPrint('✅ WebRTC: Kicked user $userId');
      }
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ WebRTC: Error kicking user: $e');
      }
      rethrow;
    }
  }
  
  /// Admin: Mute user
  Future<void> muteUser(String userId) async {
    if (!state.isAdmin && !state.isRootAdmin) {
      throw Exception('Only admins can mute users');
    }
    
    if (state.localUserId == null) {
      throw Exception('Local user ID not set');
    }
    
    try {
      await _voiceService.muteUser(
        userId: userId,
        adminId: state.localUserId!,
      );
      
      if (kDebugMode) {
        debugPrint('✅ WebRTC: Muted user $userId');
      }
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ WebRTC: Error muting user: $e');
      }
      rethrow;
    }
  }
  
  /// Set admin status
  void setAdminStatus(bool isAdmin, bool isRootAdmin) {
    state = state.copyWith(
      isAdmin: isAdmin,
      isRootAdmin: isRootAdmin,
    );
  }
  
  /// Reset state
  void reset() {
    state = const WebRTCCallState();
  }
}

/// Provider for WebRTC call state
final webrtcCallProvider = StateNotifierProvider<WebRTCCallNotifier, WebRTCCallState>((ref) {
  // Get voice service (assuming it's already a provider)
  final voiceService = WebRTCVoiceService.instance;
  return WebRTCCallNotifier(voiceService);
});

/// Convenience providers
final isInCallProvider = Provider<bool>((ref) {
  return ref.watch(webrtcCallProvider).isCallActive;
});

final participantCountProvider = Provider<int>((ref) {
  return ref.watch(webrtcCallProvider).participantCount;
});

final isRoomFullProvider = Provider<bool>((ref) {
  return ref.watch(webrtcCallProvider).isRoomFull;
});

final activeSpeakerProvider = Provider<WebRTCParticipant?>((ref) {
  return ref.watch(webrtcCallProvider).activeSpeaker;
});
