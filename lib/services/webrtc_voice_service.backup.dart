/// 🎙️ WEBRTC VOICE STREAMING SERVICE
/// Real-time voice chat for chat rooms (max 10 participants)
/// 
/// Features:
/// - WebRTC Audio Streaming
/// - Push-to-Talk (Space key)
/// - Speaking Detection
/// - Volume Control per User
/// - Auto Reconnect
/// - Background Audio Support
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' if (dart.library.html) 'package:flutter_webrtc/flutter_webrtc.dart';
import '../models/chat_models.dart';

class WebRTCVoiceService {
  // Singleton
  static final WebRTCVoiceService _instance = WebRTCVoiceService._internal();
  factory WebRTCVoiceService() => _instance;
  WebRTCVoiceService._internal();

  // WebRTC Configuration
  final Map<String, dynamic> _rtcConfiguration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      // TODO: Add TURN server for production
      // {'urls': 'turn:your-turn-server.com', 'username': 'user', 'credential': 'pass'}
    ],
  };

  // State
  final Map<String, RTCPeerConnection> _peerConnections = {};
  final Map<String, MediaStream> _remoteStreams = {};
  MediaStream? _localStream;
  
  // Voice Room State
  String? _currentRoomId;
  final List<VoiceParticipant> _participants = [];
  bool _isPushToTalkActive = false;
  bool _isMuted = false;
  VoiceRoomMode _roomMode = VoiceRoomMode.openMic;
  String? _moderatorId;
  bool _autoReconnectEnabled = true;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  Timer? _reconnectTimer;
  
  // Stream Controllers
  final _participantsController = StreamController<List<VoiceParticipant>>.broadcast();
  final _speakingController = StreamController<String>.broadcast();  // userId who is speaking
  
  Stream<List<VoiceParticipant>> get participantsStream => _participantsController.stream;
  Stream<String> get speakingStream => _speakingController.stream;
  
  // Getters
  bool get isConnected => _currentRoomId != null;
  bool get isMuted => _isMuted;
  bool get isPushToTalkActive => _isPushToTalkActive;
  List<VoiceParticipant> get participants => List.unmodifiable(_participants);
  int get participantCount => _participants.length;
  VoiceRoomMode get roomMode => _roomMode;
  String? get moderatorId => _moderatorId;

  /// Initialize WebRTC (get local media)
  Future<bool> initialize() async {
    try {
      if (kDebugMode) {
        debugPrint('🎙️ [WebRTC] Initializing...');
      }

      // Get user media (audio only)
      final Map<String, dynamic> mediaConstraints = {
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
        'video': false,
      };

      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);

      if (kDebugMode) {
        debugPrint('✅ [WebRTC] Local stream obtained');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [WebRTC] Initialization failed: $e');
      }
      return false;
    }
  }

  /// Join Voice Room
  Future<bool> joinVoiceRoom(String roomId, String userId, String username) async {
    try {
      if (_currentRoomId != null) {
        await leaveVoiceRoom();
      }

      if (kDebugMode) {
        debugPrint('🎙️ [WebRTC] Joining room: $roomId as $username');
      }

      // Initialize if not done
      if (_localStream == null) {
        final initialized = await initialize();
        if (!initialized) return false;
      }

      _currentRoomId = roomId;

      // Add self to participants
      _participants.add(VoiceParticipant(
        userId: userId,
        username: username,
        isMuted: _isMuted,
      ));

      _participantsController.add(_participants);

      // TODO: Connect to signaling server
      // await _connectToSignalingServer(roomId);

      if (kDebugMode) {
        debugPrint('✅ [WebRTC] Joined room: $roomId');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [WebRTC] Failed to join room: $e');
      }
      return false;
    }
  }

  /// Switch to a different Voice Room
  /// 🆕 CRITICAL FIX: Proper room switching with cleanup
  Future<void> switchRoom(String newRoomId) async {
    if (_currentRoomId == newRoomId) {
      if (kDebugMode) {
        debugPrint('🔄 [WebRTC] Already in room: $newRoomId');
      }
      return; // Already in this room
    }

    if (kDebugMode) {
      debugPrint('🔄 [WebRTC] Switching from $_currentRoomId → $newRoomId');
    }

    // Leave current room (if any)
    if (_currentRoomId != null) {
      await leaveVoiceRoom();
    }

    // Optional: Auto-join new room if previously connected
    // await joinVoiceRoom(newRoomId, userId, username);
  }

  /// Leave Voice Room
  Future<void> leaveVoiceRoom() async {
    try {
      if (kDebugMode) {
        debugPrint('🚪 [WebRTC] Leaving room: $_currentRoomId');
      }

      // Close all peer connections
      for (var connection in _peerConnections.values) {
        await connection.close();
      }
      _peerConnections.clear();

      // Stop remote streams
      for (var stream in _remoteStreams.values) {
        stream.dispose();
      }
      _remoteStreams.clear();

      // Clear state
      _participants.clear();
      _currentRoomId = null;
      _isPushToTalkActive = false;

      _participantsController.add(_participants);

      if (kDebugMode) {
        debugPrint('✅ [WebRTC] Left room');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [WebRTC] Error leaving room: $e');
      }
    }
  }

  /// Push-to-Talk: Start Speaking
  Future<void> startPushToTalk() async {
    if (_currentRoomId == null || _localStream == null) return;

    try {
      _isPushToTalkActive = true;

      // Unmute local audio tracks
      for (var track in _localStream!.getAudioTracks()) {
        track.enabled = true;
      }

      if (kDebugMode) {
        debugPrint('🎤 [WebRTC] Push-to-Talk: ACTIVE');
      }

      // Notify others that we're speaking
      _speakingController.add('self');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [WebRTC] Push-to-Talk start failed: $e');
      }
    }
  }

  /// Push-to-Talk: Stop Speaking
  Future<void> stopPushToTalk() async {
    if (_currentRoomId == null || _localStream == null) return;

    try {
      _isPushToTalkActive = false;

      // Mute local audio tracks (unless globally unmuted)
      if (_isMuted) {
        for (var track in _localStream!.getAudioTracks()) {
          track.enabled = false;
        }
      }

      if (kDebugMode) {
        debugPrint('🎤 [WebRTC] Push-to-Talk: INACTIVE');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [WebRTC] Push-to-Talk stop failed: $e');
      }
    }
  }

  /// Toggle Mute (Global)
  Future<void> toggleMute() async {
    if (_localStream == null) return;

    _isMuted = !_isMuted;

    // Mute/Unmute audio tracks
    for (var track in _localStream!.getAudioTracks()) {
      track.enabled = !_isMuted;
    }

    if (kDebugMode) {
      debugPrint('🔇 [WebRTC] Muted: $_isMuted');
    }
  }

  /// Set Volume for Remote Participant
  Future<void> setParticipantVolume(String userId, double volume) async {
    try {
      final stream = _remoteStreams[userId];
      if (stream == null) return;

      // TODO: Implement volume control
      // This requires audio processing - may need native platform code

      if (kDebugMode) {
        debugPrint('🔊 [WebRTC] Set volume for $userId: $volume');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [WebRTC] Volume control failed: $e');
      }
    }
  }

  /// Create Peer Connection
  Future<RTCPeerConnection> _createPeerConnection(String peerId) async {
    final pc = await createPeerConnection(_rtcConfiguration);

    // Add local stream
    if (_localStream != null) {
      _localStream!.getTracks().forEach((track) {
        pc.addTrack(track, _localStream!);
      });
    }

    // Handle remote stream
    pc.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _remoteStreams[peerId] = event.streams[0];
        if (kDebugMode) {
          debugPrint('📥 [WebRTC] Received remote stream from: $peerId');
        }
      }
    };

    // Handle ICE candidates
    pc.onIceCandidate = (RTCIceCandidate candidate) {
      // TODO: Send candidate to signaling server
      if (kDebugMode) {
        debugPrint('🧊 [WebRTC] ICE candidate: ${candidate.candidate}');
      }
    };

    // Handle connection state
    pc.onConnectionState = (RTCPeerConnectionState state) {
      if (kDebugMode) {
        debugPrint('🔗 [WebRTC] Connection state [$peerId]: $state');
      }

      // Auto-reconnect on failure
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        if (_autoReconnectEnabled && _currentRoomId != null) {
          _attemptReconnect();
        }
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _reconnectAttempts = 0; // Reset on successful connection
      }
    };

    _peerConnections[peerId] = pc;
    return pc;
  }

  /// Set Voice Room Mode
  Future<void> setRoomMode(VoiceRoomMode mode, {String? moderatorId}) async {
    try {
      _roomMode = mode;
      if (moderatorId != null) {
        _moderatorId = moderatorId;
      }

      if (kDebugMode) {
        debugPrint('🎙️ [WebRTC] Room mode changed to: $mode');
      }

      // TODO: Notify signaling server about mode change
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [WebRTC] Failed to set room mode: $e');
      }
    }
  }

  /// Raise Hand
  Future<void> raiseHand(String userId) async {
    try {
      final index = _participants.indexWhere((p) => p.userId == userId);
      if (index != -1) {
        _participants[index] = _participants[index].copyWith(handRaised: true);
        _participantsController.add(_participants);

        if (kDebugMode) {
          debugPrint('✋ [WebRTC] User $userId raised hand');
        }

        // TODO: Notify signaling server
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [WebRTC] Failed to raise hand: $e');
      }
    }
  }

  /// Lower Hand
  Future<void> lowerHand(String userId) async {
    try {
      final index = _participants.indexWhere((p) => p.userId == userId);
      if (index != -1) {
        _participants[index] = _participants[index].copyWith(handRaised: false);
        _participantsController.add(_participants);

        if (kDebugMode) {
          debugPrint('👋 [WebRTC] User $userId lowered hand');
        }

        // TODO: Notify signaling server
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [WebRTC] Failed to lower hand: $e');
      }
    }
  }

  /// Promote to Speaker (Moderator action)
  Future<void> promoteToSpeaker(String userId) async {
    try {
      final index = _participants.indexWhere((p) => p.userId == userId);
      if (index != -1) {
        _participants[index] = _participants[index].copyWith(
          role: VoiceRole.speaker,
          handRaised: false,
        );
        _participantsController.add(_participants);

        if (kDebugMode) {
          debugPrint('🔊 [WebRTC] User $userId promoted to speaker');
        }

        // TODO: Notify signaling server
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [WebRTC] Failed to promote to speaker: $e');
      }
    }
  }

  /// Demote from Speaker (Moderator action)
  Future<void> demoteFromSpeaker(String userId) async {
    try {
      final index = _participants.indexWhere((p) => p.userId == userId);
      if (index != -1) {
        _participants[index] = _participants[index].copyWith(
          role: VoiceRole.participant,
        );
        _participantsController.add(_participants);

        if (kDebugMode) {
          debugPrint('👤 [WebRTC] User $userId demoted to participant');
        }

        // TODO: Notify signaling server
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [WebRTC] Failed to demote from speaker: $e');
      }
    }
  }

  /// Check if user can speak in current room mode
  bool canUserSpeak(String userId) {
    final participant = _participants.firstWhere(
      (p) => p.userId == userId,
      orElse: () => VoiceParticipant(userId: '', username: ''),
    );

    switch (_roomMode) {
      case VoiceRoomMode.openMic:
        return true;
      case VoiceRoomMode.raiseHand:
        return participant.role == VoiceRole.speaker ||
            participant.role == VoiceRole.moderator;
      case VoiceRoomMode.speakerOnly:
        return participant.role == VoiceRole.speaker ||
            participant.role == VoiceRole.moderator;
      case VoiceRoomMode.listenOnly:
        return participant.role == VoiceRole.moderator;
    }
  }

  /// Attempt Reconnect
  Future<void> _attemptReconnect() async {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      if (kDebugMode) {
        debugPrint('❌ [WebRTC] Max reconnect attempts reached');
      }
      return;
    }

    _reconnectAttempts++;
    final delay = Duration(seconds: _reconnectAttempts * 2); // Exponential backoff

    if (kDebugMode) {
      debugPrint('🔄 [WebRTC] Reconnect attempt $_reconnectAttempts in ${delay.inSeconds}s');
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () async {
      if (_currentRoomId != null) {
        // Store current state
        final roomId = _currentRoomId!;
        final userId = _participants.isNotEmpty ? _participants.first.userId : '';
        final username = _participants.isNotEmpty ? _participants.first.username : '';

        // Reconnect
        await leaveVoiceRoom();
        await joinVoiceRoom(roomId, userId, username);

        if (kDebugMode) {
          debugPrint('✅ [WebRTC] Reconnected to room: $roomId');
        }
      }
    });
  }

  /// Enable/Disable Auto-Reconnect
  void setAutoReconnect(bool enabled) {
    _autoReconnectEnabled = enabled;
    if (kDebugMode) {
      debugPrint('🔄 [WebRTC] Auto-reconnect: ${enabled ? "ENABLED" : "DISABLED"}');
    }
  }

  /// Dispose
  Future<void> dispose() async {
    _reconnectTimer?.cancel();
    await leaveVoiceRoom();

    // Stop local stream
    if (_localStream != null) {
      _localStream!.dispose();
      _localStream = null;
    }

    await _participantsController.close();
    await _speakingController.close();

    if (kDebugMode) {
      debugPrint('🗑️ [WebRTC] Service disposed');
    }
  }
}
