/// 🎤 WELTENBIBLIOTHEK - WEBRTC VOICE CHAT SERVICE
/// Real-time voice communication using WebRTC
/// Features: 1-to-1 calls, group rooms (max 10), echo cancellation, quality monitoring
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/webrtc_signaling_service.dart'; // ✅ FIXED: Dedicated WebRTC signaling
import '../services/error_reporting_service.dart';
import '../services/admin_action_service.dart';
import '../services/voice_session_tracker.dart'; // 🆕 Session Tracking
import '../models/webrtc_call_state.dart'; // RoomFullException

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
  
  /// ✅ Factory constructor from backend JSON
  factory VoiceParticipant.fromBackendJson(Map<String, dynamic> json) {
    return VoiceParticipant(
      userId: json['user_id'] as String? ?? json['userId'] as String,
      username: json['username'] as String,
      isMuted: json['is_muted'] as bool? ?? json['isMuted'] as bool? ?? false,
      isSpeaking: json['is_speaking'] as bool? ?? json['isSpeaking'] as bool? ?? false,
      avatarEmoji: json['avatar_emoji'] as String? ?? json['avatarEmoji'] as String?,
    );
  }
}

/// WebRTC Voice Chat Service
class WebRTCVoiceService with ChangeNotifier {
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
  // ✅ FIXED: Verwende dedizierten WebRTC Signaling Service (Backend v3.2)
  // Der WebRTCSignalingService verbindet zu wss://.../voice/signaling
  // und ist speziell für WebRTC SDP/ICE Austausch konzipiert
  final WebRTCSignalingService _signaling = WebRTCSignalingService();
  
  // Admin Action Service
  final AdminActionService _adminService = AdminActionService();
  
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
  VoiceConnectionState _state = VoiceConnectionState.disconnected;
  String? _currentRoomId;
  String? _currentUserId;
  String? _currentUsername; // ✅ Store username for switchRoom
  bool _isMuted = false;
  bool _isPushToTalk = false;
  String? _lastErrorMessage;  // ✅ ADD: Track last error message
  
  // Stream controllers
  final _stateController = StreamController<VoiceConnectionState>.broadcast();
  final _participantsController = StreamController<List<VoiceParticipant>>.broadcast();
  final _speakingController = StreamController<Map<String, bool>>.broadcast();
  final _audioLevelController = StreamController<Map<String, double>>.broadcast();
  
  // Streams
  Stream<VoiceConnectionState> get stateStream => _stateController.stream;
  Stream<List<VoiceParticipant>> get participantsStream => _participantsController.stream;
  Stream<Map<String, bool>> get speakingStream => _speakingController.stream;

  /// 🎙️ Audio Level Stream: userId → Level (0.0–1.0)
  /// Wird alle 200ms aktualisiert und treibt den Speaking Indicator
  Stream<Map<String, double>> get audioLevelStream => _audioLevelController.stream;

  // Audio-Level Detection Timer
  Timer? _audioLevelTimer;

  // Threshold für Speaking-Detection (0.0–1.0)
  static const double _speakingThreshold = 0.05;
  
  // Getters
  VoiceConnectionState get state => _state;
  bool get isMuted => _isMuted;
  bool get isConnected => _state == VoiceConnectionState.connected;
  List<VoiceParticipant> get participants => _participants.values.toList();
  String? get currentRoomId => _currentRoomId; // ✅ ADD: Public getter
  MediaStream? get localStream => _localStream; // ✅ ADD: Public getter
  AdminActionService get adminService => _adminService;  // 🆕 Admin Service Access
  
  // 🔧 NEW: Additional getters for widgets
  bool get isInCall => _currentRoomId != null && isConnected;
  int get participantCount => _participants.length;
  String? get currentSpeakerId => _participants.entries
      .firstWhere(
        (e) => e.value.isSpeaking,
        orElse: () => MapEntry('', VoiceParticipant(userId: '', username: '', isMuted: false, isSpeaking: false)),
      )
      .key
      .isEmpty
      ? null
      : _participants.entries.firstWhere((e) => e.value.isSpeaking).key;
  String? get currentUserId => _currentUserId;
  
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

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// 🎙️ INITIALIZE MICROPHONE (Public API)
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// 
  /// Initialize microphone and get local audio stream.
  /// This is a separate method that can be called before joinRoom.
  /// Useful for checking microphone permissions and testing audio.
  Future<bool> initMicrophone() async {
    try {
      // Request microphone permission
      final permissionStatus = await Permission.microphone.request();
      if (!permissionStatus.isGranted) {
        debugPrint('❌ WebRTC: Microphone permission denied');
        return false;
      }

      // Get user media
      _localStream = await navigator.mediaDevices.getUserMedia(_mediaConstraints);
      
      if (_localStream != null) {
        debugPrint('✅ WebRTC: Microphone initialized successfully');
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('❌ WebRTC: initMicrophone failed - $e');
      return false;
    }
  }

  /// Join voice room
  Future<bool> joinRoom({
    required String roomId,
    required String userId,
    required String username,
    required String world,  // ✅ ADD: world parameter
    bool pushToTalk = false,
  }) async {
    try {
      // ✅ PHASE A: Check participant limit BEFORE connecting
      final currentParticipantCount = _participants.length;
      const maxParticipants = 10;
      
      if (currentParticipantCount >= maxParticipants) {
        if (kDebugMode) {
          print('❌ WebRTC: Room full ($currentParticipantCount/$maxParticipants)');
        }
        _setState(VoiceConnectionState.error);
        throw RoomFullException(
          'Raum ist voll (max. $maxParticipants Teilnehmer)',
          currentCount: currentParticipantCount,
          maxCapacity: maxParticipants,
        );
      }
      
      _setState(VoiceConnectionState.connecting);
      
      // ✅ PHASE 2: Enhanced Permission Handling
      final permissionStatus = await Permission.microphone.status;
      
      if (kDebugMode) {
        print('🎤 WebRTC: Current permission status: $permissionStatus');
      }
      
      // Request microphone permission
      final permission = await Permission.microphone.request();
      
      if (kDebugMode) {
        print('🎤 WebRTC: Permission result: ${permission.toString()}');
      }
      
      if (!permission.isGranted) {
        if (kDebugMode) {
          print('❌ WebRTC: Microphone permission denied');
        }
        _setState(VoiceConnectionState.error);
        
        // ✅ PHASE 2: Provide user-friendly error message
        throw Exception(
          permission.isPermanentlyDenied
              ? 'Mikrofon-Berechtigung dauerhaft verweigert. Bitte in Einstellungen aktivieren.'
              : 'Mikrofon-Berechtigung erforderlich für Voice Chat.'
        );
      }
      
      // ✅ PHASE 2: Enhanced Media Stream Error Handling
      try {
        _localStream = await navigator.mediaDevices.getUserMedia(_mediaConstraints);
      } catch (mediaError) {
        if (kDebugMode) {
          print('❌ WebRTC: getUserMedia failed - $mediaError');
        }
        throw Exception('Mikrofon konnte nicht aktiviert werden: $mediaError');
      }
      
      if (_localStream == null) {
        if (kDebugMode) {
          print('❌ WebRTC: Failed to get local stream');
        }
        _setState(VoiceConnectionState.error);
        throw Exception('Mikrofon-Stream konnte nicht erstellt werden.');
      }
      
      if (kDebugMode) {
        print('✅ WebRTC: Local stream acquired successfully');
      }
      
      _currentRoomId = roomId;
      _currentUserId = userId;
      _currentUsername = username; // ✅ Store username
      _isPushToTalk = pushToTalk;
      
      // Mute if push-to-talk
      if (_isPushToTalk) {
        await mute();
      }
      
      // Setup signaling
      _setupSignaling();
      
      // ✅ FIXED: Connect to dedicated WebRTC signaling server
      await _signaling.connect();
      
      // ✅ FIXED: Use proper WebRTC signaling API
      _signaling.joinRoom(roomId, userId, username);
      
      _setState(VoiceConnectionState.connected);
      _clearError();  // ✅ Clear error on successful connection

      // 🎙️ Audio-Level Detection starten
      _startAudioLevelDetection(userId);
      
      // 🆕 Start session tracking (use world parameter)
      await _sessionTracker.startSession(
        sessionId: '$roomId-$userId-${DateTime.now().millisecondsSinceEpoch}', // Generate unique session ID
        roomId: roomId,
        userId: userId,
        username: username,
        world: world,  // ✅ Use parameter instead of deriving
      );
      
      if (kDebugMode) {
        print('✅ WebRTC: Joined room $roomId');
        print('📊 Session tracking started');
      }
      
      return true;
      
    } catch (e, stack) {
      if (kDebugMode) {
        print('❌ WebRTC: Error joining room - $e');
      }
      
      // ✅ SET: Detailed error message for UI
      if (e.toString().contains('Berechtigung') || e.toString().contains('permission')) {
        _lastErrorMessage = 'Mikrofon-Berechtigung erforderlich. Bitte in Einstellungen aktivieren.';
      } else if (e.toString().contains('aktiviert') || e.toString().contains('getUserMedia')) {
        _lastErrorMessage = 'Mikrofon konnte nicht aktiviert werden. Bitte überprüfen Sie die Geräteeinstellungen.';
      } else if (e.toString().contains('WebSocket') || e.toString().contains('connection')) {
        _lastErrorMessage = 'Verbindung zum Voice-Server fehlgeschlagen. Bitte überprüfen Sie Ihre Internetverbindung.';
      } else if (e.toString().contains('voll') || e.toString().contains('RoomFullException')) {
        _lastErrorMessage = 'Voice-Raum ist voll. Bitte versuchen Sie es später erneut.';
      } else if (e.toString().contains('timeout')) {
        _lastErrorMessage = 'Verbindungs-Timeout. Bitte versuchen Sie es erneut.';
      } else {
        _lastErrorMessage = 'Voice Chat konnte nicht gestartet werden: ${e.toString()}';
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
      // 🎙️ Audio-Level Detection stoppen
      _audioLevelTimer?.cancel();
      _audioLevelTimer = null;

      if (_currentRoomId != null && _currentUserId != null) {
        // ✅ FIXED: Use proper WebRTC signaling API
        _signaling.leaveRoom();
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
      _notifyParticipantsChanged();
      
      _currentRoomId = null;
      _currentUserId = null;
      _setState(VoiceConnectionState.disconnected);
      
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
        _signaling.sendMessage({
          'type': 'voice_mute',
          'userId': _currentUserId!,
          'muted': true,
        });
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
        _signaling.sendMessage({
          'type': 'voice_mute',
          'userId': _currentUserId!,
          'muted': false,
        });
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
    _notifyParticipantsChanged();
    
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
    _notifyParticipantsChanged();
    
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
            _notifyParticipantsChanged();
          }
        }
      };
      
      // Handle ICE candidate
      pc.onIceCandidate = (RTCIceCandidate candidate) {
        _signaling.sendMessage({
          'type': 'voice_ice_candidate',
          'userId': _currentUserId!,
          'targetUserId': userId,
          'candidate': candidate.toMap(),
        });
      };
      
      // 🆕 Handle connection state changes for auto-reconnect
      pc.onConnectionState = (RTCPeerConnectionState state) {
        if (kDebugMode) {
          print('🔌 WebRTC: Peer connection state changed to $state');
        }
        
        // Auto-reconnect on failed/disconnected
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
            state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
          if (kDebugMode) {
            print('⚠️ WebRTC: Connection lost, attempting reconnect...');
          }
          // Trigger auto-reconnect after short delay
          Future.delayed(const Duration(seconds: 2), () {
            if (_currentRoomId != null && _state != VoiceConnectionState.connected) {
              attemptReconnect();
            }
          });
        }
      };
      
      // If initiator, create offer
      if (initiator) {
        final offer = await pc.createOffer();
        await pc.setLocalDescription(offer);
        
        _signaling.sendMessage({
          'type': 'voice_offer',
          'userId': _currentUserId!,
          'targetUserId': userId,
          'sdp': offer.toMap(),
        });
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
    
    _signaling.sendMessage({
      'type': 'voice_answer',
      'userId': _currentUserId!,
      'targetUserId': userId,
      'sdp': answer.toMap(),
    });
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
      _notifyParticipantsChanged();
    }
  }

  /// Set state
  void _setState(VoiceConnectionState newState) {
    _state = newState;
    _stateController.add(_state);
    notifyListeners(); // 🔧 Notify widgets listening to this service
    
    if (kDebugMode) {
      print('🎤 WebRTC: State changed to ${newState.toString()}');
    }
  }
  
  /// 🔧 Notify participants change
  void _notifyParticipantsChanged() {
    _participantsController.add(_participants.values.toList());
    notifyListeners();
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
      
      return _state == VoiceConnectionState.connected;
      
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
      
      // Determine world from roomId
      final world = savedRoomId.contains('materie') ? 'materie' : 'energie';
      
      // Attempt rejoin
      final success = await joinRoom(
        roomId: savedRoomId,
        userId: savedUserId,
        username: 'user',
        world: world,  // 🔧 ADD: Derived world parameter
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
  
  // ✅ ENHANCED: Get Detailed Error Message
  String? getLastError() {
    if (_state == VoiceConnectionState.error && _lastErrorMessage != null) {
      return _lastErrorMessage;  // Return detailed error
    }
    if (_state == VoiceConnectionState.error) {
      return 'Voice Chat Verbindung fehlgeschlagen. Bitte versuchen Sie es erneut.';
    }
    return null;
  }
  
  // ✅ CLEAR: Clear error when connection is successful
  void _clearError() {
    _lastErrorMessage = null;
  }

  // ============================================================================
  // 🎙️ AUDIO LEVEL DETECTION (Speaking Indicator)
  // ============================================================================

  /// Startet die periodische Audio-Level-Erkennung.
  /// Liest RTCStats alle 200ms und erkennt Sprecher.
  void _startAudioLevelDetection(String localUserId) {
    _audioLevelTimer?.cancel();
    _audioLevelTimer = Timer.periodic(const Duration(milliseconds: 200), (_) async {
      if (_audioLevelController.isClosed) return;

      final Map<String, double> levels = {};
      bool speakingChanged = false;

      // ── Lokale Spur über RTCPeerConnection.getStats() ──────────────────
      for (final entry in _peerConnections.entries) {
        final peerId = entry.key;
        final pc = entry.value;
        try {
          final statsReport = await pc.getStats();
          for (final stat in statsReport) {
            final type = stat.type;
            // inbound-rtp → Remote-Sprecher-Level
            if (type == 'inbound-rtp') {
              final audioLevel = stat.values['audioLevel'] as double?;
              if (audioLevel != null) {
                levels[peerId] = audioLevel;
                _updateParticipantSpeaking(peerId, audioLevel > _speakingThreshold);
                speakingChanged = true;
              }
            }
            // media-source → Lokales Mikrofon-Level
            if (type == 'media-source') {
              final audioLevel = stat.values['audioLevel'] as double?;
              if (audioLevel != null && !_isMuted) {
                levels[localUserId] = audioLevel;
                _updateParticipantSpeaking(localUserId, audioLevel > _speakingThreshold);
                speakingChanged = true;
              }
            }
          }
        } catch (_) {
          // Stats nicht verfügbar (z.B. Peer noch nicht verbunden)
        }
      }

      // Lokales Mikrofon-Fallback: AudioTrack-Aktivitäts-Heuristik
      // (für Plattformen ohne getStats-Unterstützung)
      if (_localStream != null && !_isMuted && !levels.containsKey(localUserId)) {
        final audioTracks = _localStream!.getAudioTracks();
        if (audioTracks.isNotEmpty) {
          final track = audioTracks.first;
          // Einfache Heuristik: Wenn Track enabled und nicht muted → 0.1 Level
          final enabled = track.enabled;
          final trackMuted = track.muted ?? false;
          final estimatedLevel = (enabled && !trackMuted) ? 0.06 : 0.0;
          levels[localUserId] = estimatedLevel;
          _updateParticipantSpeaking(localUserId, estimatedLevel > _speakingThreshold);
          speakingChanged = true;
        }
      }

      // Streams aktualisieren
      if (levels.isNotEmpty && !_audioLevelController.isClosed) {
        _audioLevelController.add(levels);
      }
      if (speakingChanged) {
        final speakingMap = Map.fromEntries(
          _participants.entries.map((e) => MapEntry(e.key, e.value.isSpeaking)),
        );
        if (!_speakingController.isClosed) {
          _speakingController.add(speakingMap);
        }
      }
    });
  }

  /// Aktualisiert den isSpeaking-Status eines Teilnehmers.
  void _updateParticipantSpeaking(String userId, bool isSpeaking) {
    if (_participants.containsKey(userId)) {
      if (_participants[userId]!.isSpeaking != isSpeaking) {
        _participants[userId] = _participants[userId]!.copyWith(isSpeaking: isSpeaking);
        _notifyParticipantsChanged();
      }
    } else if (userId == _currentUserId) {
      // Lokaler User noch nicht in Participants → hinzufügen
      _participants[userId] = VoiceParticipant(
        userId: userId,
        username: _currentUsername ?? 'Ich',
        isMuted: _isMuted,
        isSpeaking: isSpeaking,
      );
      _notifyParticipantsChanged();
    }
  }

  /// Dispose
  @override
  Future<void> dispose() async {
    _audioLevelTimer?.cancel();
    _audioLevelTimer = null;
    await leaveRoom();
    await _stateController.close();
    await _participantsController.close();
    await _speakingController.close();
    if (!_audioLevelController.isClosed) {
      await _audioLevelController.close();
    }
    super.dispose();
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
    required String world,  // ✅ ADD: world parameter
    bool pushToTalk = false,
  }) async {
    return await joinRoom(
      roomId: roomId,
      userId: userId,
      username: username,
      world: world,  // ✅ Pass world parameter
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
    
    // Determine world from newRoomId
    final world = newRoomId.contains('materie') ? 'materie' : 'energie';
    
    // Join new room with current user info
    if (_currentUserId != null) {
      return await joinRoom(
        roomId: newRoomId,
        userId: _currentUserId!,
        username: _currentUsername ?? 'user', // ✅ Use stored username
        world: world,
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
      _signaling.sendMessage({
        'type': 'voice_kick',
        'userId': userId,
        'adminId': adminId,
      });
      
      // Remove from participants
      _participants.remove(userId);
      _notifyParticipantsChanged();
      
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
      _signaling.sendMessage({
        'type': 'voice_admin_mute',
        'userId': userId,
        'adminId': adminId,
        'muted': true,
      });
      
      // Update participant state
      if (_participants.containsKey(userId)) {
        _participants[userId] = _participants[userId]!.copyWith(isMuted: true);
        _notifyParticipantsChanged();
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
    Map<String, dynamic> newConstraints; // ignore: unused_local_variable
    
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
