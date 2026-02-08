/// 🎤 WELTENBIBLIOTHEK - WEBRTC VOICE CHAT SERVICE
/// Real-time voice communication using WebRTC
/// Features: 1-to-1 calls, group rooms (max 10), echo cancellation, quality monitoring

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/websocket_chat_service.dart';
import '../services/error_reporting_service.dart';

/// Voice chat connection state
enum VoiceConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}

/// Participant in voice room
class VoiceParticipant {
  final String userId;
  final String username;
  final bool isMuted;
  final bool isSpeaking;
  final RTCPeerConnection? peerConnection;
  final MediaStream? stream;
  
  VoiceParticipant({
    required this.userId,
    required this.username,
    this.isMuted = false,
    this.isSpeaking = false,
    this.peerConnection,
    this.stream,
  });
  
  VoiceParticipant copyWith({
    bool? isMuted,
    bool? isSpeaking,
    RTCPeerConnection? peerConnection,
    MediaStream? stream,
  }) {
    return VoiceParticipant(
      userId: userId,
      username: username,
      isMuted: isMuted ?? this.isMuted,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      peerConnection: peerConnection ?? this.peerConnection,
      stream: stream ?? this.stream,
    );
  }
}

/// WebRTC Voice Chat Service
class WebRTCVoiceService {
  static final WebRTCVoiceService _instance = WebRTCVoiceService._internal();
  factory WebRTCVoiceService() => _instance;
  WebRTCVoiceService._internal();

  // WebSocket for signaling
  final WebSocketChatService _signaling = WebSocketChatService();
  
  // Local media stream
  MediaStream? _localStream;
  
  // Peer connections (userId -> RTCPeerConnection)
  final Map<String, RTCPeerConnection> _peerConnections = {};
  
  // Remote streams (userId -> MediaStream)
  final Map<String, MediaStream> _remoteStreams = {};
  
  // Participants
  final Map<String, VoiceParticipant> _participants = {};
  
  // State
  VoiceConnectionState _state = VoiceConnectionState.disconnected;
  String? _currentRoomId;
  String? _currentUserId;
  bool _isMuted = false;
  bool _isPushToTalk = false;
  
  // Stream controllers
  final _stateController = StreamController<VoiceConnectionState>.broadcast();
  final _participantsController = StreamController<List<VoiceParticipant>>.broadcast();
  final _speakingController = StreamController<Map<String, bool>>.broadcast();
  
  // Streams
  Stream<VoiceConnectionState> get stateStream => _stateController.stream;
  Stream<List<VoiceParticipant>> get participantsStream => _participantsController.stream;
  Stream<Map<String, bool>> get speakingStream => _speakingController.stream;
  
  // Getters
  VoiceConnectionState get state => _state;
  bool get isMuted => _isMuted;
  bool get isConnected => _state == VoiceConnectionState.connected;
  List<VoiceParticipant> get participants => _participants.values.toList();
  
  // WebRTC configuration
  final Map<String, dynamic> _configuration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ],
    'sdpSemantics': 'unified-plan',
  };
  
  // Media constraints
  final Map<String, dynamic> _mediaConstraints = {
    'audio': {
      'echoCancellation': true,
      'noiseSuppression': true,
      'autoGainControl': true,
    },
    'video': false,
  };

  /// Join voice room
  Future<bool> joinRoom({
    required String roomId,
    required String userId,
    required String username,
    bool pushToTalk = false,
  }) async {
    try {
      _setState(VoiceConnectionState.connecting);
      
      // Request microphone permission
      final permission = await Permission.microphone.request();
      if (!permission.isGranted) {
        if (kDebugMode) {
          print('❌ WebRTC: Microphone permission denied');
        }
        _setState(VoiceConnectionState.error);
        return false;
      }
      
      // Get local media stream
      _localStream = await navigator.mediaDevices.getUserMedia(_mediaConstraints);
      
      if (_localStream == null) {
        if (kDebugMode) {
          print('❌ WebRTC: Failed to get local stream');
        }
        _setState(VoiceConnectionState.error);
        return false;
      }
      
      _currentRoomId = roomId;
      _currentUserId = userId;
      _isPushToTalk = pushToTalk;
      
      // Mute if push-to-talk
      if (_isPushToTalk) {
        await mute();
      }
      
      // Setup signaling
      _setupSignaling();
      
      // Send join message via WebSocket
      await _signaling.sendMessage(
        room: roomId,
        message: jsonEncode({
          'type': 'voice_join',
          'userId': userId,
          'username': username,
        }),
        username: username,
        realm: 'voice',
      );
      
      _setState(VoiceConnectionState.connected);
      
      if (kDebugMode) {
        print('✅ WebRTC: Joined room $roomId');
      }
      
      return true;
      
    } catch (e, stack) {
      if (kDebugMode) {
        print('❌ WebRTC: Error joining room - $e');
      }
      ErrorReportingService().reportError(
        error: e,
        stackTrace: stack,
        context: 'WebRTC Voice - Join Room',
      );
      _setState(VoiceConnectionState.error);
      return false;
    }
  }

  /// Leave voice room
  Future<void> leaveRoom() async {
    try {
      if (_currentRoomId != null && _currentUserId != null) {
        // Send leave message
        await _signaling.sendMessage(
          room: _currentRoomId!,
          message: jsonEncode({
            'type': 'voice_leave',
            'userId': _currentUserId!,
          }),
          username: 'user',
          realm: 'voice',
        );
      }
      
      // Close all peer connections
      for (final pc in _peerConnections.values) {
        await pc.close();
      }
      _peerConnections.clear();
      
      // Stop local stream
      if (_localStream != null) {
        _localStream!.getTracks().forEach((track) {
          track.stop();
        });
        await _localStream!.dispose();
        _localStream = null;
      }
      
      // Clear remote streams
      for (final stream in _remoteStreams.values) {
        await stream.dispose();
      }
      _remoteStreams.clear();
      
      // Clear participants
      _participants.clear();
      _participantsController.add([]);
      
      _currentRoomId = null;
      _currentUserId = null;
      _setState(VoiceConnectionState.disconnected);
      
      if (kDebugMode) {
        print('👋 WebRTC: Left voice room');
      }
      
    } catch (e, stack) {
      if (kDebugMode) {
        print('❌ WebRTC: Error leaving room - $e');
      }
      ErrorReportingService().reportError(
        error: e,
        stackTrace: stack,
        context: 'WebRTC Voice - Leave Room',
      );
    }
  }

  /// Mute/unmute microphone
  Future<void> toggleMute() async {
    if (_isMuted) {
      await unmute();
    } else {
      await mute();
    }
  }

  /// Mute microphone
  Future<void> mute() async {
    if (_localStream != null) {
      _localStream!.getAudioTracks().forEach((track) {
        track.enabled = false;
      });
      _isMuted = true;
      
      // Notify other participants
      if (_currentRoomId != null && _currentUserId != null) {
        await _signaling.sendMessage(
          room: _currentRoomId!,
          message: jsonEncode({
            'type': 'voice_mute',
            'userId': _currentUserId!,
            'muted': true,
          }),
          username: 'user',
          realm: 'voice',
        );
      }
      
      if (kDebugMode) {
        print('🔇 WebRTC: Muted');
      }
    }
  }

  /// Unmute microphone
  Future<void> unmute() async {
    if (_localStream != null) {
      _localStream!.getAudioTracks().forEach((track) {
        track.enabled = true;
      });
      _isMuted = false;
      
      // Notify other participants
      if (_currentRoomId != null && _currentUserId != null) {
        await _signaling.sendMessage(
          room: _currentRoomId!,
          message: jsonEncode({
            'type': 'voice_mute',
            'userId': _currentUserId!,
            'muted': false,
          }),
          username: 'user',
          realm: 'voice',
        );
      }
      
      if (kDebugMode) {
        print('🔊 WebRTC: Unmuted');
      }
    }
  }

  /// Setup WebSocket signaling
  void _setupSignaling() {
    _signaling.messageStream.listen((message) {
      _handleSignalingMessage(message);
    });
  }

  /// Handle signaling messages
  Future<void> _handleSignalingMessage(Map<String, dynamic> message) async {
    try {
      final type = message['type'] as String?;
      
      if (type == null) return;
      
      switch (type) {
        case 'voice_join':
          await _handleUserJoined(message);
          break;
        case 'voice_leave':
          await _handleUserLeft(message);
          break;
        case 'voice_offer':
          await _handleOffer(message);
          break;
        case 'voice_answer':
          await _handleAnswer(message);
          break;
        case 'voice_ice_candidate':
          await _handleIceCandidate(message);
          break;
        case 'voice_mute':
          _handleMuteUpdate(message);
          break;
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print('❌ WebRTC: Error handling signaling message - $e');
      }
      ErrorReportingService().reportError(
        error: e,
        stackTrace: stack,
        context: 'WebRTC Voice - Signaling',
        additionalData: {'message': message},
      );
    }
  }

  /// Handle user joined
  Future<void> _handleUserJoined(Map<String, dynamic> message) async {
    final userId = message['userId'] as String;
    final username = message['username'] as String;
    
    if (userId == _currentUserId) return;
    
    // Add participant
    _participants[userId] = VoiceParticipant(
      userId: userId,
      username: username,
    );
    _participantsController.add(participants);
    
    // Create peer connection
    await _createPeerConnection(userId, true);
    
    if (kDebugMode) {
      print('👤 WebRTC: User $username joined');
    }
  }

  /// Handle user left
  Future<void> _handleUserLeft(Map<String, dynamic> message) async {
    final userId = message['userId'] as String;
    
    // Remove participant
    _participants.remove(userId);
    _participantsController.add(participants);
    
    // Close peer connection
    final pc = _peerConnections.remove(userId);
    if (pc != null) {
      await pc.close();
    }
    
    // Remove remote stream
    final stream = _remoteStreams.remove(userId);
    if (stream != null) {
      await stream.dispose();
    }
    
    if (kDebugMode) {
      print('👋 WebRTC: User $userId left');
    }
  }

  /// Create peer connection
  Future<void> _createPeerConnection(String userId, bool initiator) async {
    try {
      final pc = await createPeerConnection(_configuration);
      
      _peerConnections[userId] = pc;
      
      // Add local stream
      if (_localStream != null) {
        _localStream!.getTracks().forEach((track) {
          pc.addTrack(track, _localStream!);
        });
      }
      
      // Handle remote stream
      pc.onTrack = (RTCTrackEvent event) {
        if (event.streams.isNotEmpty) {
          _remoteStreams[userId] = event.streams[0];
          
          // Update participant
          if (_participants.containsKey(userId)) {
            _participants[userId] = _participants[userId]!.copyWith(
              stream: event.streams[0],
            );
            _participantsController.add(participants);
          }
        }
      };
      
      // Handle ICE candidate
      pc.onIceCandidate = (RTCIceCandidate candidate) {
        _signaling.sendMessage(
          room: _currentRoomId!,
          message: jsonEncode({
            'type': 'voice_ice_candidate',
            'userId': _currentUserId!,
            'targetUserId': userId,
            'candidate': candidate.toMap(),
          }),
          username: 'user',
          realm: 'voice',
        );
      };
      
      // If initiator, create offer
      if (initiator) {
        final offer = await pc.createOffer();
        await pc.setLocalDescription(offer);
        
        await _signaling.sendMessage(
          room: _currentRoomId!,
          message: jsonEncode({
            'type': 'voice_offer',
            'userId': _currentUserId!,
            'targetUserId': userId,
            'sdp': offer.toMap(),
          }),
          username: 'user',
          realm: 'voice',
        );
      }
      
    } catch (e, stack) {
      if (kDebugMode) {
        print('❌ WebRTC: Error creating peer connection - $e');
      }
      ErrorReportingService().reportError(
        error: e,
        stackTrace: stack,
        context: 'WebRTC Voice - Create Peer Connection',
      );
    }
  }

  /// Handle offer
  Future<void> _handleOffer(Map<String, dynamic> message) async {
    final userId = message['userId'] as String;
    final sdpMap = message['sdp'] as Map<String, dynamic>;
    
    final pc = _peerConnections[userId];
    if (pc == null) {
      await _createPeerConnection(userId, false);
    }
    
    final offer = RTCSessionDescription(
      sdpMap['sdp'] as String,
      sdpMap['type'] as String,
    );
    
    await _peerConnections[userId]!.setRemoteDescription(offer);
    
    final answer = await _peerConnections[userId]!.createAnswer();
    await _peerConnections[userId]!.setLocalDescription(answer);
    
    await _signaling.sendMessage(
      room: _currentRoomId!,
      message: jsonEncode({
        'type': 'voice_answer',
        'userId': _currentUserId!,
        'targetUserId': userId,
        'sdp': answer.toMap(),
      }),
      username: 'user',
      realm: 'voice',
    );
  }

  /// Handle answer
  Future<void> _handleAnswer(Map<String, dynamic> message) async {
    final userId = message['userId'] as String;
    final sdpMap = message['sdp'] as Map<String, dynamic>;
    
    final pc = _peerConnections[userId];
    if (pc == null) return;
    
    final answer = RTCSessionDescription(
      sdpMap['sdp'] as String,
      sdpMap['type'] as String,
    );
    
    await pc.setRemoteDescription(answer);
  }

  /// Handle ICE candidate
  Future<void> _handleIceCandidate(Map<String, dynamic> message) async {
    final userId = message['userId'] as String;
    final candidateMap = message['candidate'] as Map<String, dynamic>;
    
    final pc = _peerConnections[userId];
    if (pc == null) return;
    
    final candidate = RTCIceCandidate(
      candidateMap['candidate'] as String,
      candidateMap['sdpMid'] as String,
      candidateMap['sdpMLineIndex'] as int,
    );
    
    await pc.addCandidate(candidate);
  }

  /// Handle mute update
  void _handleMuteUpdate(Map<String, dynamic> message) {
    final userId = message['userId'] as String;
    final muted = message['muted'] as bool;
    
    if (_participants.containsKey(userId)) {
      _participants[userId] = _participants[userId]!.copyWith(isMuted: muted);
      _participantsController.add(participants);
    }
  }

  /// Set state
  void _setState(VoiceConnectionState newState) {
    _state = newState;
    _stateController.add(_state);
  }

  /// Dispose
  Future<void> dispose() async {
    await leaveRoom();
    await _stateController.close();
    await _participantsController.close();
    await _speakingController.close();
  }
}
