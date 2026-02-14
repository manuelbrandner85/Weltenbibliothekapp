/// 🎤 WELTENBIBLIOTHEK - WEBRTC VOICE CHAT SERVICE
/// Real-time voice communication using WebRTC
/// Features: 1-to-1 calls, group rooms (max 10), echo cancellation, quality monitoring
library;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/exceptions/exception_guard.dart';
import '../core/exceptions/specialized_exceptions.dart';
import '../services/websocket_chat_service.dart';
import '../services/error_reporting_service.dart';
import '../services/admin_action_service.dart';
import '../services/voice_session_tracker.dart'; // 🆕 Session Tracking
import '../services/voice_backend_service.dart';  // 🆕 Backend-First Flow
import '../models/webrtc_call_state.dart' hide RoomFullException; // CallConnectionState

// ⚠️ MIGRATION: VoiceConnectionState removed, using CallConnectionState instead

/// Participant in voice room
class VoiceParticipant {
  final String userId;
  final String username;
  final bool isMuted;
  final bool isSpeaking;
  final RTCPeerConnection? peerConnection;
  final MediaStream? stream;
  final String? avatarEmoji; // 🆕 Avatar emoji for UI
  
  VoiceParticipant({
    required this.userId,
    required this.username,
    this.isMuted = false,
    this.isSpeaking = false,
    this.peerConnection,
    this.stream,
    this.avatarEmoji,
  });
  
  VoiceParticipant copyWith({
    bool? isMuted,
    bool? isSpeaking,
    RTCPeerConnection? peerConnection,
    MediaStream? stream,
    String? avatarEmoji,
  }) {
    return VoiceParticipant(
      userId: userId,
      username: username,
      isMuted: isMuted ?? this.isMuted,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      peerConnection: peerConnection ?? this.peerConnection,
      stream: stream ?? this.stream,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
    );
  }
  
  /// Factory from backend JSON response
  factory VoiceParticipant.fromBackendJson(Map<String, dynamic> json) {
    return VoiceParticipant(
      userId: json['user_id'] as String? ?? json['userId'] as String,
      username: json['username'] as String,
      isMuted: json['is_muted'] as bool? ?? json['isMuted'] as bool? ?? false,
      isSpeaking: json['is_speaking'] as bool? ?? json['isSpeaking'] as bool? ?? false,
      avatarEmoji: json['avatar_emoji'] as String? ?? json['avatarEmoji'] as String?,
      // peerConnection and stream are null for backend participants
    );
  }
}

/// WebRTC Voice Chat Service
class WebRTCVoiceService {
  static final WebRTCVoiceService _instance = WebRTCVoiceService._internal();
  factory WebRTCVoiceService() => _instance;
  static WebRTCVoiceService get instance => _instance; // ✅ PHASE A: Static getter
  WebRTCVoiceService._internal() {
    // 🆕 Listen to speaking events for session tracking
    _speakingController.stream.listen((speakingMap) {
      final myUserId = _currentUserId;
      if (myUserId != null && speakingMap.containsKey(myUserId)) {
        final isSpeaking = speakingMap[myUserId] ?? false;
        if (isSpeaking) {
          _sessionTracker.startSpeaking();
        } else {
          _sessionTracker.stopSpeaking();
        }
      }
    });
  }

  // WebSocket for signaling
  final WebSocketChatService _signaling = WebSocketChatService();
  
  // Admin Action Service
  final AdminActionService _adminService = AdminActionService();
  
  // 🆕 Voice Backend Service (Backend-First Flow)
  final VoiceBackendService _backendService = VoiceBackendService();
  
  // 🆕 Voice Session Tracker
  final VoiceSessionTracker _sessionTracker = VoiceSessionTracker();
  
  // Local media stream
  MediaStream? _localStream;
  
  // Peer connections (userId -> RTCPeerConnection)
  final Map<String, RTCPeerConnection> _peerConnections = {};
  
  // Remote streams (userId -> MediaStream)
  final Map<String, MediaStream> _remoteStreams = {};
  
  // Participants
  final Map<String, VoiceParticipant> _participants = {};
  
  // State
  CallConnectionState _state = CallConnectionState.idle;
  String? _currentRoomId;
  String? _currentUserId;
  String? _currentSessionId;  // 🆕 Backend Session-ID
  String? _currentWorld;       // 🆕 Current World (materie/energie)
  bool _isMuted = false;
  bool _isPushToTalk = false;
  
  // Stream controllers
  final _stateController = StreamController<CallConnectionState>.broadcast();
  final _participantsController = StreamController<List<VoiceParticipant>>.broadcast();
  final _speakingController = StreamController<Map<String, bool>>.broadcast();
  
  // Streams
  Stream<CallConnectionState> get stateStream => _stateController.stream;
  Stream<List<VoiceParticipant>> get participantsStream => _participantsController.stream;
  Stream<Map<String, bool>> get speakingStream => _speakingController.stream;
  
  // Getters
  CallConnectionState get state => _state;
  bool get isMuted => _isMuted;
  bool get isConnected => _state == CallConnectionState.connected || _state == CallConnectionState.reconnecting;
  List<VoiceParticipant> get participants => _participants.values.toList();
  AdminActionService get adminService => _adminService;  // 🆕 Admin Service Access
  
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

  /// Join voice room (Backend-First Flow)
  /// 
  /// Flow: backend.join() → sessionId → tracking → webrtc → provider
  /// 
  /// PHASE 1: Backend-Session erstellen
  /// PHASE 2: Session-Tracking starten
  /// PHASE 3: WebRTC-Verbindung aufbauen
  /// PHASE 4: Provider aktualisieren
  /// Join Voice Room - Backend-First Flow mit 4 Phasen
  /// 
  /// PHASE 1: Backend-Session erstellen
  /// PHASE 2: Session Tracking starten
  /// PHASE 3: WebRTC-Verbindung aufbauen
  /// PHASE 4: Provider aktualisieren
  Future<bool> joinRoom({
    required String roomId,
    required String userId,
    required String username,
    required String world,  // 🆕 World parameter (materie/energie)
    bool pushToTalk = false,
  }) async {
    return guard(
      () async {
        // ==========================================
        // PHASE 1: BACKEND SESSION ERSTELLEN
        // ==========================================
        
        if (kDebugMode) {
          debugPrint('🚀 [VOICE] Backend-First Flow gestartet');
          debugPrint('   Room: $roomId');
          debugPrint('   User: $username');
          debugPrint('   World: $world');
        }
        
        _setState(CallConnectionState.connecting);
        
        // 1.1 Backend-Join Request (guardApi bereits im Service)
        final backendResponse = await _backendService.joinVoiceRoom(
          roomId: roomId,
          userId: userId,
          username: username,
          world: world,
        );
        
        if (!backendResponse.success) {
          throw VoiceException(
            'Backend-Join failed: ${backendResponse.error}',
            roomId: roomId,
            userId: userId,
          );
        }
        
        // 1.2 Session-ID erhalten
        final sessionId = backendResponse.sessionId;
        final maxParticipants = backendResponse.maxParticipants;
        final currentCount = backendResponse.currentParticipantCount;
        
        if (kDebugMode) {
          debugPrint('✅ [VOICE] Phase 1: Backend-Session erstellt');
          debugPrint('   Session-ID: $sessionId');
          debugPrint('   Teilnehmer: $currentCount/$maxParticipants');
        }
        
        // 1.3 Session-ID speichern
        _currentSessionId = sessionId;
        _currentWorld = world;
        
        // ==========================================
        // PHASE 2: SESSION TRACKING STARTEN
        // ==========================================
        
        await _sessionTracker.startSession(
          sessionId: sessionId,
          roomId: roomId,
          userId: userId,
          username: username,
          world: world,
        );
        
        if (kDebugMode) {
          debugPrint('✅ [VOICE] Phase 2: Session Tracking gestartet');
        }
        
        // ==========================================
        // PHASE 3: WEBRTC VERBINDUNG
        // ==========================================
        
        // 3.1 Permission Check
        final permission = await Permission.microphone.request();
        
        if (!permission.isGranted) {
          if (kDebugMode) {
            debugPrint('❌ [VOICE] Phase 3: Mikrofon-Berechtigung verweigert');
          }
          
          // Backend-Session wieder beenden (Rollback!)
          await _backendService.leaveVoiceRoom(sessionId);
          
          throw VoiceException.permissionDenied();
        }
        
        // 3.2 Media Stream
        try {
          _localStream = await navigator.mediaDevices.getUserMedia(_mediaConstraints);
        } catch (mediaError) {
          if (kDebugMode) {
            debugPrint('❌ [VOICE] Phase 3: getUserMedia failed - $mediaError');
          }
          
          // Backend-Session wieder beenden (Rollback!)
          await _backendService.leaveVoiceRoom(sessionId);
          
          throw VoiceException(
            'Mikrofon konnte nicht aktiviert werden',
            roomId: roomId,
            userId: userId,
            cause: mediaError,
          );
        }
        
        if (_localStream == null) {
          if (kDebugMode) {
            debugPrint('❌ [VOICE] Phase 3: Failed to get local stream');
          }
          
          // Backend-Session wieder beenden (Rollback!)
          await _backendService.leaveVoiceRoom(sessionId);
          
          throw VoiceException(
            'Mikrofon-Stream konnte nicht erstellt werden',
            roomId: roomId,
            userId: userId,
          );
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
        
        // 3.3 WebSocket Signaling (mit Session-ID!)
        await _signaling.sendMessage(
          room: roomId,
          message: jsonEncode({
            'type': 'voice_join',
            'sessionId': sessionId,
            'userId': userId,
            'username': username,
          }),
          username: username,
          realm: 'voice',
        );
        
        if (kDebugMode) {
          debugPrint('✅ [VOICE] Phase 3: WebRTC verbunden mit Session: $sessionId');
        }
        
        // ==========================================
        // PHASE 4: PROVIDER AKTUALISIEREN
        // ==========================================
        
        _setState(CallConnectionState.connected);
        
        // Participants aus Backend-Response verwenden
        for (final participant in backendResponse.participants) {
          _participants[participant.userId] = participant;
        }
        
        if (kDebugMode) {
          debugPrint('✅ [VOICE] Phase 4: Provider aktualisiert');
          debugPrint('   Participants: ${_participants.length}');
          debugPrint('🎉 [VOICE] Backend-First Flow komplett!');
        }
        
        return true;
      },
      operationName: 'Join Voice Room (Backend-First)',
      context: {
        'roomId': roomId,
        'userId': userId,
        'username': username,
        'world': world,
        'pushToTalk': pushToTalk,
      },
      onError: (error, stackTrace) async {
        // Error-Recovery: Cleanup durchführen
        if (kDebugMode) {
          debugPrint('🧹 [VOICE] Error occurred, performing cleanup...');
          debugPrint('   Error Type: ${error.runtimeType}');
          debugPrint('   Error: $error');
        }
        
        // Cleanup: Backend-Session beenden falls vorhanden
        if (_currentSessionId != null) {
          try {
            await _backendService.leaveVoiceRoom(_currentSessionId!);
            if (kDebugMode) {
              debugPrint('🔄 [VOICE] Backend-Session rolled back: $_currentSessionId');
            }
          } catch (rollbackError) {
            if (kDebugMode) {
              debugPrint('⚠️ [VOICE] Rollback error: $rollbackError');
            }
          }
        }
        
        // Error Reporting
        ErrorReportingService().reportError(
          error: error,
          stackTrace: stackTrace,
          context: 'WebRTC Voice - Backend-First Join Flow',
        );
        
        // State cleanup
        _setState(CallConnectionState.error);
        _currentSessionId = null;
        
        // Log specific error types
        if (error is RoomFullException) {
          if (kDebugMode) {
            debugPrint('⚠️ [VOICE] Room is full: ${error.currentCount}/${error.maxCount}');
          }
        } else if (error is VoiceException) {
          if (kDebugMode) {
            debugPrint('🎤 [VOICE] Voice-specific error: ${error.message}');
          }
        } else if (error is NetworkException) {
          if (kDebugMode) {
            debugPrint('🌐 [VOICE] Network error: ${error.statusCode}');
          }
        } else if (error is TimeoutException) {
          if (kDebugMode) {
            debugPrint('⏱️ [VOICE] Timeout after ${error.timeout.inSeconds}s');
          }
        }
        
        return false; // Fallback-Wert
      },
    );
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
      _setState(CallConnectionState.disconnected);
      
      // 🆕 End session tracking
      await _sessionTracker.endSession();
      
      if (kDebugMode) {
        print('👋 WebRTC: Left voice room');
        print('📊 Session tracking ended');
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
  void _setState(CallConnectionState newState) {
    _state = newState;
    _stateController.add(_state);
    
    if (kDebugMode) {
      debugPrint('🎤 WebRTC: State changed to ${newState.name}');
    }
  }
  
  // ✅ PHASE 2: Connection Health Check
  Future<bool> checkConnection() async {
    try {
      // Check if we have local stream
      if (_localStream != null) {
        final tracks = _localStream!.getAudioTracks();
        if (tracks.isNotEmpty) {
          if (kDebugMode) {
            print('✅ WebRTC: Connection healthy - local stream active');
          }
          return true;
        }
      }
      
      // Check WebSocket connection
      // TODO: Add WebSocket health check
      
      if (kDebugMode) {
        print('⚠️ WebRTC: Connection check - no active stream');
      }
      
      return _state == CallConnectionState.connected || _state == CallConnectionState.reconnecting;
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ WebRTC: Connection check failed - $e');
      }
      return false;
    }
  }
  
  // ✅ PHASE 2: Auto-Recovery
  Future<bool> attemptReconnect() async {
    if (kDebugMode) {
      print('🔄 WebRTC: Attempting reconnection...');
    }
    
    try {
      // Save current room info
      final savedRoomId = _currentRoomId;
      final savedUserId = _currentUserId;
      
      if (savedRoomId == null || savedUserId == null) {
        if (kDebugMode) {
          print('❌ WebRTC: Cannot reconnect - no previous room info');
        }
        return false;
      }
      
      // Clean up current connection
      await leaveRoom();
      
      // Wait a bit
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Attempt rejoin
      final success = await joinRoom(
        roomId: savedRoomId,
        userId: savedUserId,
        username: 'user',
        world: _currentWorld ?? 'materie',  // 🆕 Use saved world or default
        pushToTalk: _isPushToTalk,
      );
      
      if (success && kDebugMode) {
        print('✅ WebRTC: Reconnection successful');
      } else if (!success && kDebugMode) {
        print('❌ WebRTC: Reconnection failed');
      }
      
      return success;
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ WebRTC: Reconnection error - $e');
      }
      return false;
    }
  }
  
  // ✅ PHASE 2: Get Error Message
  String? getLastError() {
    if (_state == CallConnectionState.error) {
      return 'Voice Chat Verbindung fehlgeschlagen';
    }
    return null;
  }

  /// Dispose
  Future<void> dispose() async {
    await leaveRoom();
    await _stateController.close();
    await _participantsController.close();
    await _speakingController.close();
  }
  
  // ============================================================================
  // ADDITIONAL METHODS (for compatibility with live chat screens)
  // ============================================================================
  
  /// Initialize voice service
  Future<void> initialize() async {
    if (kDebugMode) {
      print('🎤 WebRTC Voice Service initialized');
    }
    // Service is already initialized via singleton
  }
  
  /// Join voice room (alias for joinRoom)
  Future<bool> joinVoiceRoom({
    required String roomId,
    required String userId,
    required String username,
    required String world,  // 🆕 World parameter
    bool pushToTalk = false,
  }) async {
    return await joinRoom(
      roomId: roomId,
      userId: userId,
      username: username,
      world: world,  // 🆕 Pass world parameter
      pushToTalk: pushToTalk,
    );
  }
  
  /// Leave voice room (alias for leaveRoom)
  Future<void> leaveVoiceRoom() async {
    await leaveRoom();
  }
  
  /// Switch to different room
  Future<bool> switchRoom(String newRoomId) async {
    if (kDebugMode) {
      print('🔄 Switching voice room: $_currentRoomId → $newRoomId');
    }
    
    // Leave current room
    await leaveRoom();
    
    // Join new room with current user info
    if (_currentUserId != null && _currentWorld != null) {
      return await joinRoom(
        roomId: newRoomId,
        userId: _currentUserId!,
        username: 'user', // TODO: Get actual username
        world: _currentWorld!,  // 🆕 Use saved world
        pushToTalk: _isPushToTalk,
      );
    }
    
    return false;
  }
  
  // ✅ PHASE 3: Admin Controls
  
  /// Kick user from voice room (Admin only)
  Future<bool> kickUser({
    required String userId,
    required String adminId,
  }) async {
    try {
      if (_currentRoomId == null) {
        if (kDebugMode) {
          print('❌ WebRTC: Cannot kick - not in room');
        }
        return false;
      }
      
      // Send kick message via signaling
      await _signaling.sendMessage(
        room: _currentRoomId!,
        message: jsonEncode({
          'type': 'voice_kick',
          'userId': userId,
          'adminId': adminId,
        }),
        username: 'admin',
        realm: 'voice',
      );
      
      // Remove from participants
      _participants.remove(userId);
      _participantsController.add(participants);
      
      if (kDebugMode) {
        print('🚫 WebRTC: User $userId kicked by admin $adminId');
      }
      
      return true;
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ WebRTC: Kick user error - $e');
      }
      return false;
    }
  }
  
  /// Mute another user (Admin only)
  Future<bool> muteUser({
    required String userId,
    required String adminId,
  }) async {
    try {
      if (_currentRoomId == null) {
        if (kDebugMode) {
          print('❌ WebRTC: Cannot mute - not in room');
        }
        return false;
      }
      
      // Send admin mute message
      await _signaling.sendMessage(
        room: _currentRoomId!,
        message: jsonEncode({
          'type': 'voice_admin_mute',
          'userId': userId,
          'adminId': adminId,
          'muted': true,
        }),
        username: 'admin',
        realm: 'voice',
      );
      
      // Update participant state
      if (_participants.containsKey(userId)) {
        _participants[userId] = _participants[userId]!.copyWith(isMuted: true);
        _participantsController.add(participants);
      }
      
      if (kDebugMode) {
        print('🔇 WebRTC: User $userId muted by admin $adminId');
      }
      
      return true;
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ WebRTC: Mute user error - $e');
      }
      return false;
    }
  }
  
  // ✅ PHASE 3: Audio Quality Settings
  
  /// Set audio quality
  Future<void> setAudioQuality(String quality) async {
    // low, medium, high
    Map<String, dynamic> newConstraints;
    
    switch (quality) {
      case 'low':
        newConstraints = {
          'audio': {
            'echoCancellation': true,
            'noiseSuppression': true,
            'autoGainControl': true,
            'sampleRate': 16000,
            'channelCount': 1,
          },
          'video': false,
        };
        break;
        
      case 'high':
        newConstraints = {
          'audio': {
            'echoCancellation': true,
            'noiseSuppression': true,
            'autoGainControl': true,
            'sampleRate': 48000,
            'channelCount': 2,
          },
          'video': false,
        };
        break;
        
      default: // medium
        newConstraints = _mediaConstraints;
    }
    
    if (kDebugMode) {
      print('🎧 WebRTC: Audio quality set to $quality');
    }
    
    // TODO: Apply new constraints to existing stream
    // This requires recreating the media stream
  }
}
