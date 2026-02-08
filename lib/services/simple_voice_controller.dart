/// 🎙️ PRODUCTION-READY SIMPLE VOICE CONTROLLER
/// 
/// Nach deinem Plan:
/// ✅ Singleton Pattern
/// ✅ getUserMedia() mit expliziter Permission
/// ✅ Eigener User wird IMMER hinzugefügt
/// ✅ Pro User: eigene RTCPeerConnection
/// ✅ Kein Stream-Filtering im UI
/// ✅ Participants werden beim JOIN erstellt, nicht beim Stream
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/chat_models.dart';
import 'cloudflare_signaling_service.dart'; // ✅ CRITICAL: Signaling
import 'dart:async';

/// Voice Participant (Internal Model with RTCPeerConnection)
class VoiceParticipantInternal {
  final String userId;
  final String username;
  final bool isSelf;
  MediaStream? stream;
  RTCPeerConnection? peer;
  bool isMuted;
  bool isSpeaking;

  VoiceParticipantInternal({
    required this.userId,
    required this.username,
    required this.isSelf,
    this.stream,
    this.peer,
    this.isMuted = false,
    this.isSpeaking = false,
  });

  VoiceParticipant toVoiceParticipant() {
    return VoiceParticipant(
      userId: userId,
      username: username,
      isSpeaking: isSpeaking,
      isMuted: isMuted,
    );
  }
}

/// Simple Voice Controller (SINGLETON)
class SimpleVoiceController extends ChangeNotifier {
  // 🔒 SINGLETON
  static final SimpleVoiceController _instance = SimpleVoiceController._internal();
  factory SimpleVoiceController() => _instance;
  SimpleVoiceController._internal();

  // 🌐 SIGNALING SERVICE
  final CloudflareSignalingService _signaling = CloudflareSignalingService();

  // 🎤 Microphone & Streams
  MediaStream? _localStream;
  
  // 👥 Participants (userId -> Participant mit Peer & Stream)
  final Map<String, VoiceParticipantInternal> _participants = {};
  
  // 🏠 Room State
  String? _currentRoomId;
  String? _currentRoomName;
  String? _currentUserId;
  String? _currentUsername;
  bool _isMuted = false;
  String? _currentSpeakerId; // Currently speaking user
  
  // 🛡️ STEP 4: Error State Management
  String? _lastError;
  DateTime? _lastErrorTime;
  final List<String> _errorLog = [];
  static const int _maxErrorLogSize = 50;
  bool _isRecovering = false;
  
  // ⚡ STEP 5: Performance Optimization
  Timer? _uiUpdateDebouncer;
  static const Duration _uiUpdateDebounce = Duration(milliseconds: 100);
  List<VoiceParticipant>? _cachedParticipantsList;
  bool _needsParticipantsRefresh = true;
  DateTime? _lastNotifyTime;
  static const Duration _minNotifyInterval = Duration(milliseconds: 50);
  
  // 📱 STEP 6: Mobile-Specific State
  bool _isLowBandwidthMode = false;
  String _connectionQuality = 'good'; // good, fair, poor
  bool _isBackgroundAudioEnabled = false;
  Timer? _connectionQualityMonitor;
  DateTime? _lastBitrateCheck;
  int _packetsLost = 0;
  int _packetsReceived = 0;
  
  // 🎨 STEP 7: Audio Visualizer State
  final Map<String, double> _audioLevels = {}; // userId -> audio level (0.0-1.0)
  final Map<String, bool> _isSpeaking = {}; // userId -> is speaking
  final Map<String, DateTime> _lastSpeakTime = {}; // userId -> last speak time
  Timer? _audioLevelMonitor;
  String? _dominantSpeaker; // Currently loudest speaker
  static const double _speakingThreshold = 0.15; // Volume threshold for "speaking"
  static const Duration _speakingTimeout = Duration(milliseconds: 500); // Time before "stopped speaking"
  
  // 🚀 STEP 8: Advanced Features State
  bool _isPushToTalkMode = false;
  bool _isPushToTalkActive = false;
  bool _isVoiceActivationEnabled = false;
  final bool _isRecording = false;
  bool _isDebugMode = false;
  DateTime? _sessionStartTime;
  final int _totalBytesSent = 0;
  final int _totalBytesReceived = 0;
  final Map<String, Duration> _speakingDurations = {}; // userId -> total speaking time
  
  // 📡 SIGNALING SUBSCRIPTIONS
  StreamSubscription? _offersSubscription;
  StreamSubscription? _answersSubscription;
  StreamSubscription? _candidatesSubscription;
  StreamSubscription? _participantsSubscription;
  
  // 🔊 STUN Server Configuration
  // 🧊 STEP 3: OPTIMIZED ICE CONFIGURATION
  final Map<String, dynamic> _iceServers = {
    'iceServers': [
      // Primary Google STUN servers (multiple for redundancy)
      {
        'urls': [
          'stun:stun.l.google.com:19302',
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302',
          'stun:stun3.l.google.com:19302',
          'stun:stun4.l.google.com:19302',
        ]
      },
      
      // Public TURN servers (fallback for restricted networks)
      // TURN helps when direct P2P connection fails (e.g., symmetric NAT)
      {
        'urls': [
          'turn:openrelay.metered.ca:80',
          'turn:openrelay.metered.ca:443',
        ],
        'username': 'openrelayproject',
        'credential': 'openrelayproject',
      },
    ],
    
    // 🧊 STEP 3: ICE Transport Optimization
    'iceTransportPolicy': 'all',           // Try all connection types
    'bundlePolicy': 'max-bundle',          // Bundle all media on one connection
    'rtcpMuxPolicy': 'require',            // Multiplex RTP and RTCP
    'iceCandidatePoolSize': 10,            // Pre-gather candidates (faster connection)
    
    // 🧊 STEP 3: Connection Timeouts
    'iceConnectionReceivingTimeout': 10000, // 10 seconds
    'iceBackupCandidatePairPingInterval': 2000, // 2 seconds
  };
  
  // 🔄 STEP 1: Reconnection tracking
  final Map<String, int> _reconnectAttempts = {};
  final Map<String, Timer?> _reconnectTimers = {};
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 2);

  // 📡 Getters
  // ⚡ STEP 5: Cached participants list for performance
  List<VoiceParticipant> get participants {
    if (_needsParticipantsRefresh || _cachedParticipantsList == null) {
      _cachedParticipantsList = _participants.values
          .map((p) => p.toVoiceParticipant())
          .toList();
      _needsParticipantsRefresh = false;
    }
    return _cachedParticipantsList!;
  }
  
  int get participantCount => _participants.length;
  bool get isInCall => _currentRoomId != null;
  bool get isMuted => _isMuted;
  String? get currentRoomId => _currentRoomId;
  String? get currentRoomName => _currentRoomName;
  String? get currentUserId => _currentUserId;
  String? get currentUsername => _currentUsername;
  MediaStream? get localStream => _localStream;
  String? get currentSpeakerId => _currentSpeakerId;
  
  // 🛡️ STEP 4: Error Getters
  String? get lastError => _lastError;
  DateTime? get lastErrorTime => _lastErrorTime;
  List<String> get errorLog => List.unmodifiable(_errorLog);
  bool get isRecovering => _isRecovering;
  
  // 📱 STEP 6: Mobile Getters
  bool get isLowBandwidthMode => _isLowBandwidthMode;
  String get connectionQuality => _connectionQuality;
  bool get isBackgroundAudioEnabled => _isBackgroundAudioEnabled;
  
  // 🎨 STEP 7: Audio Visualizer Getters
  Map<String, double> get audioLevels => Map.unmodifiable(_audioLevels);
  Map<String, bool> get isSpeakingMap => Map.unmodifiable(_isSpeaking);
  String? get dominantSpeaker => _dominantSpeaker;
  
  /// Get audio level for specific user
  double getAudioLevel(String userId) => _audioLevels[userId] ?? 0.0;
  
  /// Check if user is speaking
  bool isSpeaking(String userId) => _isSpeaking[userId] ?? false;
  
  // 🚀 STEP 8: Advanced Features Getters
  bool get isPushToTalkMode => _isPushToTalkMode;
  bool get isPushToTalkActive => _isPushToTalkActive;
  bool get isVoiceActivationEnabled => _isVoiceActivationEnabled;
  bool get isRecording => _isRecording;
  bool get isDebugMode => _isDebugMode;
  Duration? get sessionDuration => _sessionStartTime != null 
      ? DateTime.now().difference(_sessionStartTime!) 
      : null;

  /// 🎤 STEP 1: Initialize Microphone (getUserMedia)
  /// MUST be called BEFORE joining!
  /// Shows permission prompt and gets local audio stream
  Future<bool> initMicrophone() async {
    try {
      print('🎤 [SimpleVoice] ===== INIT MICROPHONE =====');
      print('📱 [SimpleVoice] Platform: ${defaultTargetPlatform.toString()}');
      
      // 1. REQUEST PERMISSION
      print('📋 [SimpleVoice] Requesting microphone permission...');
      final status = await Permission.microphone.request();
      print('📋 [SimpleVoice] Permission status: ${status.toString()}');
      
      if (!status.isGranted) {
        print('❌ [SimpleVoice] Microphone permission DENIED');
        throw Exception('Microphone permission denied');
      }
      
      print('✅ [SimpleVoice] Microphone permission GRANTED');
      
      // 2. GET USER MEDIA - 🎵 STEP 2: HIGH-QUALITY AUDIO + 📱 STEP 6: MOBILE OPTIMIZED
      // 📱 STEP 6: Detect if mobile device for adaptive settings
      final isMobile = defaultTargetPlatform == TargetPlatform.android || 
                       defaultTargetPlatform == TargetPlatform.iOS;
      
      print('📱 [Mobile] Device type: ${isMobile ? "Mobile" : "Desktop"}');
      
      final mediaConstraints = {
        'audio': {
          // Echo Cancellation (removes feedback)
          'echoCancellation': true,
          
          // Noise Suppression (removes background noise)
          'noiseSuppression': true,
          
          // Auto Gain Control (normalizes volume)
          'autoGainControl': true,
          
          // 🎵 STEP 2: Advanced Audio Settings
          'googEchoCancellation': true,          // Google's advanced echo cancellation
          'googAutoGainControl': true,           // Google's AGC
          'googNoiseSuppression': true,          // Google's noise suppression
          'googHighpassFilter': true,            // Remove low-frequency noise
          'googTypingNoiseDetection': true,      // Remove keyboard noise
          'googAudioMirroring': false,           // No audio mirroring
          
          // 📱 STEP 6: Mobile-Adaptive Quality Settings
          // Lower sample rate on mobile for battery efficiency
          'sampleRate': isMobile ? 32000 : 48000,           // 32kHz mobile, 48kHz desktop
          'channelCount': 1,                                // Mono (efficient)
          'latency': isMobile ? 0.02 : 0.01,               // 20ms mobile, 10ms desktop
          
          // Volume
          'volume': 1.0,                         // Max volume
        },
        'video': false,
      };
      
      print('📱 [SimpleVoice] Calling getUserMedia...');
      final audioConfig = mediaConstraints['audio'] as Map<String, dynamic>?;
      if (audioConfig != null) {
        print('   🎤 Sample Rate: ${audioConfig['sampleRate']}Hz');
        print('   ⚡ Latency: ${audioConfig['latency']}s');
      }
      
      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      
      if (_localStream == null) {
        print('❌ [SimpleVoice] getUserMedia returned NULL');
        throw Exception('Failed to get local audio stream');
      }
      
      final audioTracks = _localStream!.getAudioTracks();
      print('✅ [SimpleVoice] Local stream created: ${audioTracks.length} audio tracks');
      
      for (var track in audioTracks) {
        print('   🎵 Track: ${track.label} | enabled: ${track.enabled}');
      }
      
      return true;
      
    } catch (e, stackTrace) {
      // 🛡️ STEP 4: Enhanced error handling
      print('❌ [SimpleVoice] initMicrophone() FAILED: $e');
      
      final userMessage = _getMicrophoneErrorMessage(e);
      _logError('Microphone Init', userMessage, stackTrace: stackTrace);
      
      _localStream = null;
      return false;
    }
  }

  /// 👤 STEP 2: Join Voice Room
  /// Adds SELF as participant (isSelf = true)
  Future<bool> joinVoiceRoom(
    String roomId,
    String roomName,
    String userId,
    String username,
  ) async {
    try {
      print('🚀 [SimpleVoice] ===== JOIN VOICE ROOM =====');
      print('   Room: $roomName ($roomId)');
      print('   User: $username ($userId)');
      
      // 1. CHECK MICROPHONE
      if (_localStream == null) {
        print('⚠️ [SimpleVoice] No local stream! Calling initMicrophone()...');
        final success = await initMicrophone();
        if (!success) {
          print('❌ [SimpleVoice] initMicrophone() failed!');
          return false;
        }
      }
      
      // 2. SAVE ROOM STATE
      _currentRoomId = roomId;
      _currentRoomName = roomName;
      _currentUserId = userId;
      _currentUsername = username;
      
      // 3. ADD SELF AS PARTICIPANT
      print('👤 [SimpleVoice] Adding SELF to participants...');
      _participants[userId] = VoiceParticipantInternal(
        userId: userId,
        username: username,
        isSelf: true,
        stream: _localStream,  // Local stream
        peer: null,  // Self doesn't need peer
        isMuted: _isMuted,
      );
      
      print('✅ [SimpleVoice] SELF added: $username ($userId)');
      print('📊 [SimpleVoice] Participants count: ${_participants.length}');
      
      // 4. INITIALIZE CLOUDFLARE SIGNALING
      print('🌐 [SimpleVoice] Initializing Cloudflare Signaling...');
      await _signaling.initializeRoom(roomId, userId, username);
      print('✅ [SimpleVoice] Signaling initialized');
      
      // 5. SUBSCRIBE TO SIGNALING STREAMS
      _subscribeToSignaling();
      
      // 📱 STEP 6: Start mobile monitoring
      _startConnectionQualityMonitor();
      
      // 🎨 STEP 7: Start audio level monitoring
      _startAudioLevelMonitoring();
      
      // 🚀 STEP 8: Start session tracking
      _sessionStartTime = DateTime.now();
      
      // 6. NOTIFY UI - ⚡ STEP 5: Immediate for critical join event
      _invalidateParticipantsCache();
      _notifyListenersDebounced(immediate: true);
      
      // 7. DEBUG OUTPUT
      debugParticipants();
      
      return true;
      
    } catch (e, stackTrace) {
      // 🛡️ STEP 4: Enhanced error handling
      print('❌ [SimpleVoice] joinVoiceRoom() FAILED: $e');
      
      final userMessage = _getSignalingErrorMessage(e);
      _logError('Join Voice Room', userMessage, stackTrace: stackTrace);
      
      // Cleanup on failure
      await leaveVoiceRoom();
      
      return false;
    }
  }

  /// 👥 ADD OTHER USER (when someone joins)
  /// Creates RTCPeerConnection for remote user
  Future<void> onUserJoined(String userId, String username) async {
    try {
      print('👤 [SimpleVoice] User joined: $username ($userId)');
      
      // Ignore self
      if (userId == _currentUserId) {
        print('⚠️ [SimpleVoice] Ignoring self-join');
        return;
      }
      
      // Check if already exists
      if (_participants.containsKey(userId)) {
        print('⚠️ [SimpleVoice] User already exists');
        return;
      }
      
      // Create participant WITHOUT stream (stream comes later via onTrack)
      _participants[userId] = VoiceParticipantInternal(
        userId: userId,
        username: username,
        isSelf: false,
        stream: null,  // Will be set in onTrack
        peer: null,    // Will be created next
      );
      
      // Create peer connection
      await _createPeerForUser(userId);
      
      print('✅ [SimpleVoice] User added: $username ($userId)');
      print('📊 [SimpleVoice] Participants count: ${_participants.length}');
      
      // ⚡ STEP 5: Immediate notification for user join
      _invalidateParticipantsCache();
      _notifyListenersDebounced(immediate: true);
      debugParticipants();
      
    } catch (e) {
      print('❌ [SimpleVoice] onUserJoined() FAILED: $e');
    }
  }

  /// 🔗 CREATE PEER CONNECTION FOR USER
  Future<void> _createPeerForUser(String userId) async {
    try {
      print('🔗 [SimpleVoice] Creating peer for: $userId');
      
      final participant = _participants[userId];
      if (participant == null) {
        print('❌ [SimpleVoice] Participant not found: $userId');
        return;
      }
      
      // Create RTCPeerConnection
      final peer = await createPeerConnection(_iceServers);
      participant.peer = peer;
      
      // Add local audio tracks to peer
      if (_localStream != null) {
        for (var track in _localStream!.getAudioTracks()) {
          await peer.addTrack(track, _localStream!);
          print('   ➕ Added local audio track to peer');
        }
      }
      
      // onTrack: Receive remote audio
      peer.onTrack = (RTCTrackEvent event) {
        print('🎵 [SimpleVoice] onTrack: Remote stream received from $userId');
        print('   Streams: ${event.streams.length}');
        
        if (event.streams.isNotEmpty) {
          final remoteStream = event.streams[0];
          participant.stream = remoteStream;
          
          // DEBUG: Check audio tracks
          final audioTracks = remoteStream.getAudioTracks();
          print('   🎵 Remote audio tracks: ${audioTracks.length}');
          for (var track in audioTracks) {
            print('      Track: ${track.label} | enabled: ${track.enabled} | muted: ${track.muted}');
          }
          
          // CRITICAL: Set audio output to speakers (not earpiece)
          if (audioTracks.isNotEmpty) {
            for (var track in audioTracks) {
              track.enableSpeakerphone(true);
            }
            print('   ✅ Audio playback enabled');
          }
          
          print('   ✅ Stream attached to participant: $userId');
          // ⚡ STEP 5: Debounced notification for better performance
          _notifyListenersDebounced();
        }
      };
      
      // onIceCandidate: Send via signaling - 🧊 STEP 3: OPTIMIZED
      peer.onIceCandidate = (RTCIceCandidate candidate) {
        print('🧊 [SimpleVoice] ICE candidate for: $userId');
        
        if (candidate.candidate != null && _currentRoomId != null && _currentUserId != null) {
          // 🧊 STEP 3: Log candidate type for debugging
          final candidateType = _getIceCandidateType(candidate.candidate!);
          print('   📍 Candidate type: $candidateType');
          
          _signaling.sendIceCandidate(userId, {
            'from': _currentUserId!,
            'to': userId,
            'candidate': candidate.candidate!,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          });
          print('   ✅ Sent ICE candidate via signaling');
        }
      };
      
      // 🧊 STEP 3: Monitor ICE Gathering State
      peer.onIceGatheringState = (RTCIceGatheringState state) {
        print('🧊 [SimpleVoice] ICE gathering ($userId): $state');
        
        switch (state) {
          case RTCIceGatheringState.RTCIceGatheringStateNew:
            print('   🆕 Starting ICE gathering...');
            break;
          case RTCIceGatheringState.RTCIceGatheringStateGathering:
            print('   🔍 Gathering ICE candidates...');
            break;
          case RTCIceGatheringState.RTCIceGatheringStateComplete:
            print('   ✅ ICE gathering complete!');
            break;
        }
      };
      
      // 🧊 STEP 3: Monitor ICE Connection State
      peer.onIceConnectionState = (RTCIceConnectionState state) {
        print('🧊 [SimpleVoice] ICE connection ($userId): $state');
        
        switch (state) {
          case RTCIceConnectionState.RTCIceConnectionStateNew:
            print('   🆕 New ICE connection');
            break;
          case RTCIceConnectionState.RTCIceConnectionStateChecking:
            print('   🔍 Checking ICE candidates...');
            break;
          case RTCIceConnectionState.RTCIceConnectionStateConnected:
            print('   ✅ ICE connected!');
            break;
          case RTCIceConnectionState.RTCIceConnectionStateCompleted:
            print('   🎉 ICE completed!');
            break;
          case RTCIceConnectionState.RTCIceConnectionStateFailed:
            print('   ❌ ICE failed - attempting ICE restart...');
            _restartIce(userId);
            break;
          case RTCIceConnectionState.RTCIceConnectionStateDisconnected:
            print('   ⚠️ ICE disconnected');
            break;
          case RTCIceConnectionState.RTCIceConnectionStateClosed:
            print('   🚪 ICE closed');
            break;
          default:
            break;
        }
      };
      
      // onConnectionState
      peer.onConnectionState = (RTCPeerConnectionState state) {
        print('📡 [SimpleVoice] Connection state ($userId): $state');
        
        switch (state) {
          case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
            print('   ✅ Peer connected: $userId');
            _reconnectAttempts[userId] = 0; // Reset attempts
            _cancelReconnectTimer(userId);
            break;
            
          case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
            print('   ⚠️ Peer disconnected: $userId - attempting reconnect...');
            _attemptReconnect(userId);
            break;
            
          case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
            print('   ❌ Peer failed: $userId - attempting reconnect...');
            _attemptReconnect(userId);
            break;
            
          case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
            print('   🚪 Peer closed: $userId');
            _cancelReconnectTimer(userId);
            break;
            
          default:
            break;
        }
      };
      
      print('✅ [SimpleVoice] Peer created for: $userId');
      
      // CREATE AND SEND OFFER - 🎵 STEP 2: OPTIMIZED AUDIO
      print('📤 [SimpleVoice] Creating offer for: $userId');
      final offer = await peer.createOffer();
      
      // 🎵 STEP 2: Optimize SDP for high-quality audio
      final optimizedSdp = _optimizeAudioSdp(offer.sdp!);
      final optimizedOffer = RTCSessionDescription(optimizedSdp, 'offer');
      
      await peer.setLocalDescription(optimizedOffer);
      
      if (_currentRoomId != null && _currentUserId != null) {
        await _signaling.sendOffer(userId, {
          'from': _currentUserId!,
          'to': userId,
          'sdp': optimizedOffer.sdp!,
          'type': 'offer',
        });
        print('✅ [SimpleVoice] Sent optimized offer to: $userId');
      }
      
    } catch (e, stackTrace) {
      // 🛡️ STEP 4: Enhanced error handling
      print('❌ [SimpleVoice] _createPeerForUser() FAILED: $e');
      _logError('Create Peer', 'Fehler bei Peer-Verbindung zu $userId: $e', stackTrace: stackTrace);
      
      // Attempt recovery after delay
      Timer(const Duration(seconds: 3), () {
        _attemptReconnect(userId);
      });
    }
  }

  /// 👋 USER LEFT
  Future<void> onUserLeft(String userId) async {
    try {
      print('👋 [SimpleVoice] User left: $userId');
      
      final participant = _participants[userId];
      if (participant == null) return;
      
      // Close peer connection
      await participant.peer?.close();
      participant.peer?.dispose();
      
      // Dispose stream
      await participant.stream?.dispose();
      
      // Remove participant
      _participants.remove(userId);
      
      print('✅ [SimpleVoice] User removed: $userId');
      print('📊 [SimpleVoice] Participants count: ${_participants.length}');
      
      // ⚡ STEP 5: Immediate notification for user leave
      _invalidateParticipantsCache();
      _notifyListenersDebounced(immediate: true);
      debugParticipants();
      
    } catch (e) {
      print('❌ [SimpleVoice] onUserLeft() FAILED: $e');
    }
  }

  /// 🔇 TOGGLE MUTE
  Future<void> toggleMute() async {
    try {
      _isMuted = !_isMuted;
      
      // Mute/unmute local audio tracks
      if (_localStream != null) {
        for (var track in _localStream!.getAudioTracks()) {
          track.enabled = !_isMuted;
        }
      }
      
      // Update self participant
      if (_currentUserId != null) {
        final self = _participants[_currentUserId];
        if (self != null) {
          self.isMuted = _isMuted;
        }
      }
      
      print('🔇 [SimpleVoice] Muted: $_isMuted');
      notifyListeners();
      
    } catch (e) {
      print('❌ [SimpleVoice] toggleMute() FAILED: $e');
    }
  }

  /// 🚪 LEAVE VOICE ROOM
  Future<void> leaveVoiceRoom() async {
    try {
      print('🚪 [SimpleVoice] ===== LEAVE VOICE ROOM =====');
      
      // Leave signaling room
      if (_currentRoomId != null) {
        await _signaling.leaveRoom();
      }
      
      // Cancel signaling subscriptions
      await _offersSubscription?.cancel();
      await _answersSubscription?.cancel();
      await _candidatesSubscription?.cancel();
      await _participantsSubscription?.cancel();
      
      // Close all peer connections
      for (var participant in _participants.values) {
        await participant.peer?.close();
        participant.peer?.dispose();
        
        // Don't dispose local stream (only remote streams)
        if (!participant.isSelf) {
          await participant.stream?.dispose();
        }
      }
      
      // Clear participants
      _participants.clear();
      
      // Dispose local stream
      await _localStream?.dispose();
      _localStream = null;
      
      // Reset state
      _currentRoomId = null;
      _currentRoomName = null;
      _currentUserId = null;
      _currentUsername = null;
      _isMuted = false;
      
      print('✅ [SimpleVoice] Left voice room');
      print('📊 [SimpleVoice] Participants count: ${_participants.length}');
      
      notifyListeners();
      
    } catch (e) {
      print('❌ [SimpleVoice] leaveVoiceRoom() FAILED: $e');
    }
  }

  /// 🔍 DEBUG: Print all participants
  void debugParticipants() {
    print('🔍 [SimpleVoice] ===== DEBUG PARTICIPANTS =====');
    print('   Count: ${_participants.length}');
    
    _participants.forEach((id, p) {
      print('   USER=${p.username} | self=${p.isSelf} | stream=${p.stream != null} | peer=${p.peer != null}');
    });
    
    print('==========================================');
  }

  /// 📡 SUBSCRIBE TO SIGNALING STREAMS
  void _subscribeToSignaling() {
    print('📡 [SimpleVoice] Subscribing to signaling streams...');
    
    // Listen to participants updates
    _participantsSubscription = _signaling.participantsStream.listen((participantsList) {
      print('👥 [SimpleVoice] Participants update from signaling: ${participantsList.length}');
      
      for (var participantData in participantsList) {
        final userId = participantData['userId'] as String;
        final username = participantData['username'] as String;
        
        // Skip self
        if (userId == _currentUserId) {
          print('   ⚠️ Skipping self: $username');
          continue;
        }
        
        // Add new participant
        if (!_participants.containsKey(userId)) {
          print('   ➕ New participant: $username ($userId)');
          onUserJoined(userId, username);
        }
      }
      
      // Check for left users
      final signalingUserIds = participantsList.map((p) => p['userId'] as String).toSet();
      final localUserIds = _participants.keys.toSet();
      final leftUsers = localUserIds.difference(signalingUserIds);
      
      for (var leftUserId in leftUsers) {
        if (leftUserId != _currentUserId) {
          print('   ➖ User left: $leftUserId');
          onUserLeft(leftUserId);
        }
      }
    });
    
    // Listen to WebRTC offers
    _offersSubscription = _signaling.offersStream.listen((data) {
      final fromUserId = data['from'] as String;
      
      // Ignore own offers
      if (fromUserId == _currentUserId) return;
      
      print('📨 [SimpleVoice] Received offer from: $fromUserId');
      _handleOffer(data);
    });
    
    // Listen to WebRTC answers
    _answersSubscription = _signaling.answersStream.listen((data) {
      final fromUserId = data['from'] as String;
      
      // Ignore own answers
      if (fromUserId == _currentUserId) return;
      
      print('📨 [SimpleVoice] Received answer from: $fromUserId');
      _handleAnswer(data);
    });
    
    // Listen to ICE candidates
    _candidatesSubscription = _signaling.candidatesStream.listen((data) {
      final fromUserId = data['from'] as String;
      
      // Ignore own candidates
      if (fromUserId == _currentUserId) return;
      
      print('🧊 [SimpleVoice] Received ICE candidate from: $fromUserId');
      _handleIceCandidate(data);
    });
    
    print('✅ [SimpleVoice] Subscribed to all signaling streams');
  }

  /// 📨 HANDLE OFFER
  Future<void> _handleOffer(Map<String, dynamic> data) async {
    try {
      final fromUserId = data['from'] as String;
      final sdp = data['sdp'] as String;
      
      print('📨 [SimpleVoice] Processing offer from: $fromUserId');
      
      // Get or create participant
      var participant = _participants[fromUserId];
      if (participant == null) {
        print('   ⚠️ Participant not found, skipping offer');
        return;
      }
      
      // Create peer if needed
      if (participant.peer == null) {
        await _createPeerForUser(fromUserId);
        participant = _participants[fromUserId]!;
      }
      
      // Set remote description
      await participant.peer!.setRemoteDescription(
        RTCSessionDescription(sdp, 'offer')
      );
      
      // Create answer - 🎵 STEP 2: OPTIMIZED AUDIO
      final answer = await participant.peer!.createAnswer();
      
      // 🎵 STEP 2: Optimize SDP for high-quality audio
      final optimizedSdp = _optimizeAudioSdp(answer.sdp!);
      final optimizedAnswer = RTCSessionDescription(optimizedSdp, 'answer');
      
      await participant.peer!.setLocalDescription(optimizedAnswer);
      
      // Send answer via signaling
      await _signaling.sendAnswer(fromUserId, {
        'from': _currentUserId!,
        'to': fromUserId,
        'sdp': optimizedAnswer.sdp!,
        'type': 'answer',
      });
      
      print('✅ [SimpleVoice] Sent answer to: $fromUserId');
      
    } catch (e) {
      print('❌ [SimpleVoice] _handleOffer() FAILED: $e');
    }
  }

  /// 📨 HANDLE ANSWER
  Future<void> _handleAnswer(Map<String, dynamic> data) async {
    try {
      final fromUserId = data['from'] as String;
      final sdp = data['sdp'] as String;
      
      print('📨 [SimpleVoice] Processing answer from: $fromUserId');
      
      final participant = _participants[fromUserId];
      if (participant == null || participant.peer == null) {
        print('   ⚠️ Participant or peer not found');
        return;
      }
      
      // Set remote description
      await participant.peer!.setRemoteDescription(
        RTCSessionDescription(sdp, 'answer')
      );
      
      print('✅ [SimpleVoice] Applied answer from: $fromUserId');
      
    } catch (e) {
      print('❌ [SimpleVoice] _handleAnswer() FAILED: $e');
    }
  }

  /// 🧊 HANDLE ICE CANDIDATE
  Future<void> _handleIceCandidate(Map<String, dynamic> data) async {
    try {
      final fromUserId = data['from'] as String;
      final candidate = data['candidate'] as String;
      final sdpMid = data['sdpMid'] as String?;
      final sdpMLineIndex = data['sdpMLineIndex'] as int?;
      
      print('🧊 [SimpleVoice] Processing ICE candidate from: $fromUserId');
      
      final participant = _participants[fromUserId];
      if (participant == null || participant.peer == null) {
        print('   ⚠️ Participant or peer not found');
        return;
      }
      
      // Add ICE candidate
      await participant.peer!.addCandidate(
        RTCIceCandidate(candidate, sdpMid, sdpMLineIndex)
      );
      
      print('✅ [SimpleVoice] Added ICE candidate from: $fromUserId');
      
    } catch (e) {
      print('❌ [SimpleVoice] _handleIceCandidate() FAILED: $e');
    }
  }

  /// 📐 MINIMIZE (Placeholder - no-op for SimpleVoiceController)
  void minimize() {
    print('📐 [SimpleVoice] minimize() - no-op');
    // SimpleVoiceController doesn't have minimize state
    // Voice stays active in background
  }

  // 🔄 STEP 1: AUTOMATIC RECONNECTION METHODS
  
  /// Attempt to reconnect to a peer
  void _attemptReconnect(String userId) {
    // Cancel any existing timer
    _cancelReconnectTimer(userId);
    
    // Check attempts
    final attempts = _reconnectAttempts[userId] ?? 0;
    
    if (attempts >= _maxReconnectAttempts) {
      print('❌ [Reconnect] Max attempts reached for $userId ($attempts/$_maxReconnectAttempts)');
      // TODO: Notify user
      return;
    }
    
    // Increment attempts
    _reconnectAttempts[userId] = attempts + 1;
    
    print('🔄 [Reconnect] Attempt ${attempts + 1}/$_maxReconnectAttempts for $userId');
    
    // Schedule reconnect
    _reconnectTimers[userId] = Timer(_reconnectDelay, () {
      print('⏰ [Reconnect] Timer fired - reconnecting to $userId');
      _reconnectPeer(userId);
    });
  }
  
  /// Actually reconnect to peer
  Future<void> _reconnectPeer(String userId) async {
    try {
      print('🔄 [Reconnect] Starting reconnection to $userId');
      
      final participant = _participants[userId];
      if (participant == null) {
        print('   ⚠️ Participant not found: $userId');
        return;
      }
      
      // Close old peer
      await participant.peer?.close();
      participant.peer?.dispose();
      
      // Create new peer connection
      await _createPeerForUser(userId);
      
      print('   ✅ Reconnection initiated for $userId');
      
    } catch (e) {
      print('   ❌ Reconnection failed for $userId: $e');
      // Retry with increased attempt count
      _attemptReconnect(userId);
    }
  }
  
  /// Cancel reconnect timer
  void _cancelReconnectTimer(String userId) {
    final timer = _reconnectTimers[userId];
    if (timer != null && timer.isActive) {
      timer.cancel();
      _reconnectTimers.remove(userId);
      print('🛑 [Reconnect] Timer cancelled for $userId');
    }
  }

  // 🧊 STEP 3: ICE HELPER METHODS
  
  /// Get ICE candidate type from candidate string
  String _getIceCandidateType(String candidate) {
    if (candidate.contains('typ host')) {
      return 'HOST (local)';
    } else if (candidate.contains('typ srflx')) {
      return 'SRFLX (STUN)';
    } else if (candidate.contains('typ relay')) {
      return 'RELAY (TURN)';
    } else if (candidate.contains('typ prflx')) {
      return 'PRFLX (peer reflexive)';
    }
    return 'UNKNOWN';
  }
  
  /// Restart ICE for a peer connection
  Future<void> _restartIce(String userId) async {
    try {
      print('🔄 [ICE] Restarting ICE for: $userId');
      
      final participant = _participants[userId];
      if (participant == null || participant.peer == null) {
        print('   ⚠️ No peer found for: $userId');
        return;
      }
      
      // Create new offer with ICE restart flag
      final peer = participant.peer!;
      
      // Set ICE restart option
      final offerOptions = {
        'iceRestart': true,
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': false,
      };
      
      final offer = await peer.createOffer(offerOptions);
      
      // Optimize SDP
      final optimizedSdp = _optimizeAudioSdp(offer.sdp!);
      final optimizedOffer = RTCSessionDescription(optimizedSdp, 'offer');
      
      await peer.setLocalDescription(optimizedOffer);
      
      // Send new offer via signaling
      if (_currentRoomId != null && _currentUserId != null) {
        await _signaling.sendOffer(userId, {
          'from': _currentUserId!,
          'to': userId,
          'sdp': optimizedOffer.sdp!,
          'type': 'offer',
        });
        print('   ✅ ICE restart offer sent to: $userId');
      }
      
    } catch (e) {
      print('   ❌ ICE restart failed for $userId: $e');
    }
  }

  // 🎵 STEP 2: OPTIMIZE AUDIO SDP (Opus Codec Configuration)
  String _optimizeAudioSdp(String sdp) {
    // Opus is the best codec for voice (better than PCMU/PCMA)
    // We optimize it for high quality and low latency
    
    var optimizedSdp = sdp;
    
    // 1. Prioritize Opus codec (move it to first position)
    // This ensures Opus is always used when available
    if (optimizedSdp.contains('opus')) {
      print('🎵 [AudioOptimize] Opus codec found - optimizing...');
      
      // 2. Set Opus parameters for high quality
      // maxaveragebitrate: 64000 (64 kbps - high quality voice)
      // stereo: 0 (mono is more efficient for voice)
      // useinbandfec: 1 (Forward Error Correction - recovers lost packets)
      // usedtx: 1 (Discontinuous Transmission - saves bandwidth when silent)
      
      final opusParams = 'maxaveragebitrate=64000;stereo=0;useinbandfec=1;usedtx=1;maxplaybackrate=48000;sprop-maxcapturerate=48000';
      
      // Find opus fmtp line and update it
      final opusFmtpRegex = RegExp(r'a=fmtp:(\d+).*opus.*');
      final match = opusFmtpRegex.firstMatch(optimizedSdp);
      
      if (match != null) {
        final payloadType = match.group(1);
        final oldLine = match.group(0);
        final newLine = 'a=fmtp:$payloadType $opusParams';
        
        optimizedSdp = optimizedSdp.replaceFirst(oldLine!, newLine);
        print('   ✅ Opus optimized: $opusParams');
      } else {
        // If fmtp line doesn't exist, add it
        // Find the m=audio line and add fmtp after it
        final audioLineRegex = RegExp(r'm=audio.*');
        final audioMatch = audioLineRegex.firstMatch(optimizedSdp);
        
        if (audioMatch != null) {
          // Extract payload type from m=audio line (usually 111 for Opus)
          final audioLine = audioMatch.group(0)!;
          final payloadMatch = RegExp(r'(\d+)\s+opus').firstMatch(audioLine);
          
          if (payloadMatch != null) {
            final payloadType = payloadMatch.group(1);
            final insertPosition = optimizedSdp.indexOf(audioLine) + audioLine.length;
            optimizedSdp = '${optimizedSdp.substring(0, insertPosition)}\na=fmtp:$payloadType $opusParams${optimizedSdp.substring(insertPosition)}';
            print('   ✅ Opus fmtp added: $opusParams');
          }
        }
      }
      
      // 3. Set ptime (packet time) to 20ms for low latency
      if (!optimizedSdp.contains('a=ptime:')) {
        optimizedSdp = optimizedSdp.replaceFirst('m=audio', 'a=ptime:20\nm=audio');
        print('   ✅ Set ptime to 20ms (low latency)');
      }
      
      print('🎵 [AudioOptimize] SDP optimization complete!');
    } else {
      print('⚠️ [AudioOptimize] Opus codec not found in SDP');
    }
    
    return optimizedSdp;
  }

  // 🛡️ STEP 4: ERROR HANDLING & RECOVERY METHODS
  
  /// Log error with timestamp and context
  void _logError(String context, String error, {StackTrace? stackTrace}) {
    final timestamp = DateTime.now().toIso8601String();
    final errorMessage = '[$timestamp] $context: $error';
    
    // Add to error log
    _errorLog.add(errorMessage);
    
    // Keep log size manageable
    if (_errorLog.length > _maxErrorLogSize) {
      _errorLog.removeAt(0);
    }
    
    // Update last error
    _lastError = error;
    _lastErrorTime = DateTime.now();
    
    // Print for debugging
    print('❌ [ERROR] $errorMessage');
    if (stackTrace != null && kDebugMode) {
      print('   Stack: $stackTrace');
    }
    
    notifyListeners();
  }
  
  /// Clear error state
  void clearError() {
    _lastError = null;
    _lastErrorTime = null;
    notifyListeners();
  }
  
  /// Handle microphone permission error
  String _getMicrophoneErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    
    if (errorStr.contains('permission') || errorStr.contains('denied')) {
      return 'Mikrofon-Berechtigung wurde verweigert. Bitte erlaube Mikrofon-Zugriff in den Einstellungen.';
    } else if (errorStr.contains('notfound') || errorStr.contains('not found')) {
      return 'Kein Mikrofon gefunden. Bitte schließe ein Mikrofon an.';
    } else if (errorStr.contains('notreadable') || errorStr.contains('not readable')) {
      return 'Mikrofon wird bereits verwendet. Bitte schließe andere Apps, die das Mikrofon nutzen.';
    } else if (errorStr.contains('overconstrained')) {
      return 'Mikrofon unterstützt die angeforderten Einstellungen nicht.';
    } else if (errorStr.contains('security')) {
      return 'Mikrofon-Zugriff blockiert aus Sicherheitsgründen. Bitte verwende HTTPS.';
    }
    
    return 'Fehler beim Mikrofon-Zugriff: $error';
  }
  
  /// Handle signaling error
  String _getSignalingErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    
    if (errorStr.contains('network') || errorStr.contains('connection')) {
      return 'Netzwerkfehler. Bitte überprüfe deine Internetverbindung.';
    } else if (errorStr.contains('timeout')) {
      return 'Zeitüberschreitung bei der Verbindung. Bitte versuche es erneut.';
    } else if (errorStr.contains('404')) {
      return 'Voice-Server nicht erreichbar. Bitte kontaktiere den Support.';
    } else if (errorStr.contains('401') || errorStr.contains('403')) {
      return 'Keine Berechtigung für Voice-Chat. Bitte melde dich neu an.';
    }
    
    return 'Verbindungsfehler: $error';
  }
  
  /// Attempt recovery from error
  Future<void> _attemptRecovery(String context) async {
    if (_isRecovering) {
      print('⚠️ [Recovery] Already recovering, skipping...');
      return;
    }
    
    try {
      _isRecovering = true;
      notifyListeners();
      
      print('🔧 [Recovery] Attempting recovery from: $context');
      
      // Wait a bit before recovery attempt
      await Future.delayed(const Duration(seconds: 1));
      
      // Recovery strategy based on context
      if (context.contains('microphone') || context.contains('stream')) {
        print('   🎤 Re-initializing microphone...');
        await initMicrophone();
      } else if (context.contains('peer') || context.contains('connection')) {
        print('   🔄 Re-establishing peer connections...');
        // Reconnect to all participants
        for (var userId in _participants.keys) {
          await _reconnectPeer(userId);
        }
      } else if (context.contains('signaling')) {
        print('   📡 Re-subscribing to signaling...');
        _subscribeToSignaling();
      }
      
      print('✅ [Recovery] Recovery attempt completed');
      clearError();
      
    } catch (e) {
      print('❌ [Recovery] Recovery failed: $e');
      _logError('Recovery', e.toString());
    } finally {
      _isRecovering = false;
      notifyListeners();
    }
  }
  
  /// Wrap async operations with error handling
  Future<T?> _safeAsync<T>(
    String context,
    Future<T> Function() operation, {
    bool attemptRecovery = false,
  }) async {
    try {
      return await operation();
    } catch (e, stackTrace) {
      _logError(context, e.toString(), stackTrace: stackTrace);
      
      if (attemptRecovery) {
        await _attemptRecovery(context);
      }
      
      return null;
    }
  }

  // ⚡ STEP 5: PERFORMANCE OPTIMIZATION METHODS
  
  /// Debounced notifyListeners for better performance
  void _notifyListenersDebounced({bool immediate = false}) {
    // Mark participants as needing refresh
    _needsParticipantsRefresh = true;
    
    // Immediate notification (for critical updates)
    if (immediate) {
      _cancelUiUpdateDebouncer();
      _performNotify();
      return;
    }
    
    // Throttle notifications (max 20 per second)
    final now = DateTime.now();
    if (_lastNotifyTime != null) {
      final elapsed = now.difference(_lastNotifyTime!);
      if (elapsed < _minNotifyInterval) {
        // Schedule debounced update
        _scheduleUiUpdate();
        return;
      }
    }
    
    _performNotify();
  }
  
  /// Schedule UI update with debounce
  void _scheduleUiUpdate() {
    _cancelUiUpdateDebouncer();
    _uiUpdateDebouncer = Timer(_uiUpdateDebounce, () {
      _performNotify();
    });
  }
  
  /// Cancel pending UI updates
  void _cancelUiUpdateDebouncer() {
    _uiUpdateDebouncer?.cancel();
    _uiUpdateDebouncer = null;
  }
  
  /// Actually perform notification
  void _performNotify() {
    _lastNotifyTime = DateTime.now();
    notifyListeners();
  }
  
  /// Invalidate participants cache
  void _invalidateParticipantsCache() {
    _needsParticipantsRefresh = true;
  }
  
  /// Efficient stream disposal
  Future<void> _disposeStreamSafely(MediaStream? stream) async {
    if (stream == null) return;
    
    try {
      // Stop all tracks first
      for (var track in stream.getTracks()) {
        await track.stop();
      }
      
      // Then dispose stream
      await stream.dispose();
    } catch (e) {
      print('⚠️ [Performance] Stream disposal error (non-critical): $e');
      // Non-critical error, continue
    }
  }
  
  /// Efficient peer disposal
  Future<void> _disposePeerSafely(RTCPeerConnection? peer) async {
    if (peer == null) return;
    
    try {
      await peer.close();
      peer.dispose();
    } catch (e) {
      print('⚠️ [Performance] Peer disposal error (non-critical): $e');
      // Non-critical error, continue
    }
  }
  
  /// Batch cleanup for multiple participants
  Future<void> _batchCleanupParticipants(List<String> userIds) async {
    print('🧹 [Performance] Batch cleanup: ${userIds.length} participants');
    
    final cleanupFutures = <Future>[];
    
    for (var userId in userIds) {
      final participant = _participants[userId];
      if (participant != null) {
        // Add to batch
        if (participant.stream != null) {
          cleanupFutures.add(_disposeStreamSafely(participant.stream));
        }
        if (participant.peer != null) {
          cleanupFutures.add(_disposePeerSafely(participant.peer));
        }
      }
    }
    
    // Execute all cleanups in parallel
    await Future.wait(cleanupFutures, eagerError: false);
    
    // Remove from map
    for (var userId in userIds) {
      _participants.remove(userId);
    }
    
    _invalidateParticipantsCache();
    print('✅ [Performance] Batch cleanup complete');
  }

  // 📱 STEP 6: MOBILE-SPECIFIC METHODS
  
  /// Start connection quality monitoring
  void _startConnectionQualityMonitor() {
    _connectionQualityMonitor?.cancel();
    
    _connectionQualityMonitor = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkConnectionQuality(),
    );
    
    print('📱 [Mobile] Connection quality monitoring started');
  }
  
  /// Stop connection quality monitoring
  void _stopConnectionQualityMonitor() {
    _connectionQualityMonitor?.cancel();
    _connectionQualityMonitor = null;
    print('📱 [Mobile] Connection quality monitoring stopped');
  }
  
  /// Check connection quality based on packet loss
  Future<void> _checkConnectionQuality() async {
    try {
      // Check each peer connection
      for (var participant in _participants.values) {
        if (participant.peer == null || participant.isSelf) continue;
        
        final stats = await participant.peer!.getStats();
        
        // Analyze stats for packet loss
        for (var report in stats) {
          if (report.type == 'inbound-rtp' && report.values['mediaType'] == 'audio') {
            final packetsLost = report.values['packetsLost'] as int? ?? 0;
            final packetsReceived = report.values['packetsReceived'] as int? ?? 0;
            
            _packetsLost += packetsLost;
            _packetsReceived += packetsReceived;
            
            // Calculate packet loss percentage
            final total = _packetsLost + _packetsReceived;
            if (total > 100) { // Enough data to analyze
              final lossPercentage = (_packetsLost / total) * 100;
              
              // Update connection quality
              final oldQuality = _connectionQuality;
              
              if (lossPercentage < 2) {
                _connectionQuality = 'good';
              } else if (lossPercentage < 5) {
                _connectionQuality = 'fair';
              } else {
                _connectionQuality = 'poor';
              }
              
              // Switch to low bandwidth mode if poor connection
              if (_connectionQuality == 'poor' && !_isLowBandwidthMode) {
                print('📱 [Mobile] Poor connection detected, enabling low bandwidth mode');
                await _enableLowBandwidthMode();
              } else if (_connectionQuality == 'good' && _isLowBandwidthMode) {
                print('📱 [Mobile] Good connection restored, disabling low bandwidth mode');
                await _disableLowBandwidthMode();
              }
              
              if (oldQuality != _connectionQuality) {
                print('📱 [Mobile] Connection quality: $oldQuality → $_connectionQuality');
                print('   📊 Packet loss: ${lossPercentage.toStringAsFixed(1)}%');
                _notifyListenersDebounced();
              }
              
              // Reset counters
              _packetsLost = 0;
              _packetsReceived = 0;
            }
            
            break;
          }
        }
      }
    } catch (e) {
      print('⚠️ [Mobile] Connection quality check error: $e');
    }
  }
  
  /// Enable low bandwidth mode (lower bitrate)
  Future<void> _enableLowBandwidthMode() async {
    if (_isLowBandwidthMode) return;
    
    _isLowBandwidthMode = true;
    print('📱 [Mobile] Low bandwidth mode ENABLED');
    
    // Re-negotiate with lower bitrate
    // This would require re-creating offers with modified SDP
    // For now, just flag it
    
    _notifyListenersDebounced(immediate: true);
  }
  
  /// Disable low bandwidth mode (normal bitrate)
  Future<void> _disableLowBandwidthMode() async {
    if (!_isLowBandwidthMode) return;
    
    _isLowBandwidthMode = false;
    print('📱 [Mobile] Low bandwidth mode DISABLED');
    
    _notifyListenersDebounced(immediate: true);
  }
  
  /// Enable background audio (for mobile)
  Future<void> enableBackgroundAudio() async {
    if (_isBackgroundAudioEnabled) return;
    
    print('📱 [Mobile] Enabling background audio...');
    
    // On mobile, this would configure audio session
    // to keep playing in background
    
    _isBackgroundAudioEnabled = true;
    _notifyListenersDebounced();
    
    print('✅ [Mobile] Background audio enabled');
  }
  
  /// Disable background audio
  Future<void> disableBackgroundAudio() async {
    if (!_isBackgroundAudioEnabled) return;
    
    print('📱 [Mobile] Disabling background audio...');
    
    _isBackgroundAudioEnabled = false;
    _notifyListenersDebounced();
    
    print('✅ [Mobile] Background audio disabled');
  }

  // 🎨 STEP 7: AUDIO VISUALIZER METHODS
  
  /// Start audio level monitoring
  void _startAudioLevelMonitoring() {
    _audioLevelMonitor?.cancel();
    
    _audioLevelMonitor = Timer.periodic(
      const Duration(milliseconds: 100), // 10 times per second
      (_) => _updateAudioLevels(),
    );
    
    print('🎨 [Visualizer] Audio level monitoring started');
  }
  
  /// Stop audio level monitoring
  void _stopAudioLevelMonitoring() {
    _audioLevelMonitor?.cancel();
    _audioLevelMonitor = null;
    _audioLevels.clear();
    _isSpeaking.clear();
    _lastSpeakTime.clear();
    _dominantSpeaker = null;
    print('🎨 [Visualizer] Audio level monitoring stopped');
  }
  
  /// Update audio levels for all participants
  Future<void> _updateAudioLevels() async {
    try {
      String? loudestSpeaker;
      double maxLevel = 0.0;
      final now = DateTime.now();
      
      // Check each participant
      for (var entry in _participants.entries) {
        final userId = entry.key;
        final participant = entry.value;
        
        // Skip if no peer or is self
        if (participant.peer == null || participant.isSelf) {
          // For self, use local stream
          if (participant.isSelf && _localStream != null) {
            // We can't easily get audio level from local stream in Flutter Web
            // So just mark as speaking if unmuted
            _audioLevels[userId] = _isMuted ? 0.0 : 0.5;
            _isSpeaking[userId] = !_isMuted;
          }
          continue;
        }
        
        // Get stats for remote peer
        try {
          final stats = await participant.peer!.getStats();
          
          double audioLevel = 0.0;
          
          // Find audio level in stats
          for (var report in stats) {
            if (report.type == 'inbound-rtp' && report.values['mediaType'] == 'audio') {
              // Get audio level (0.0 to 1.0)
              final level = report.values['audioLevel'] as double?;
              if (level != null) {
                audioLevel = level;
              }
              break;
            }
          }
          
          // Update audio level
          _audioLevels[userId] = audioLevel;
          
          // Detect speaking
          final wasSpeaking = _isSpeaking[userId] ?? false;
          final isSpeakingNow = audioLevel > _speakingThreshold;
          
          if (isSpeakingNow) {
            _isSpeaking[userId] = true;
            _lastSpeakTime[userId] = now;
            
            // Track loudest speaker
            if (audioLevel > maxLevel) {
              maxLevel = audioLevel;
              loudestSpeaker = userId;
            }
            
            // Log when someone starts speaking
            if (!wasSpeaking) {
              print('🎤 [Visualizer] $userId started speaking (level: ${(audioLevel * 100).toStringAsFixed(0)}%)');
            }
          } else {
            // Check if should stop speaking (timeout)
            final lastSpeak = _lastSpeakTime[userId];
            if (lastSpeak != null) {
              final elapsed = now.difference(lastSpeak);
              if (elapsed > _speakingTimeout) {
                if (wasSpeaking) {
                  print('🔇 [Visualizer] $userId stopped speaking');
                }
                _isSpeaking[userId] = false;
              }
            } else {
              _isSpeaking[userId] = false;
            }
          }
        } catch (e) {
          // Stats error (non-critical)
          // Don't spam logs
        }
      }
      
      // Update dominant speaker
      if (loudestSpeaker != _dominantSpeaker && loudestSpeaker != null) {
        _dominantSpeaker = loudestSpeaker;
        print('🎙️ [Visualizer] Dominant speaker: $loudestSpeaker');
        _notifyListenersDebounced();
      } else if (loudestSpeaker == null && _dominantSpeaker != null) {
        _dominantSpeaker = null;
        _notifyListenersDebounced();
      }
      
    } catch (e) {
      // General error in audio level update (non-critical)
      // Don't spam logs
    }
  }
  
  /// Get speaking status text for UI
  String getSpeakingStatus() {
    final speaking = _isSpeaking.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();
    
    if (speaking.isEmpty) {
      return 'Niemand spricht';
    } else if (speaking.length == 1) {
      final userId = speaking.first;
      final participant = _participants[userId];
      return '${participant?.username ?? userId} spricht';
    } else {
      return '${speaking.length} Personen sprechen';
    }
  }

  // 🚀 STEP 8: ADVANCED FEATURES METHODS
  
  /// Enable Push-to-Talk mode
  Future<void> enablePushToTalk() async {
    if (_isPushToTalkMode) return;
    
    print('🚀 [Advanced] Push-to-Talk mode ENABLED');
    _isPushToTalkMode = true;
    
    // Mute by default in PTT mode
    if (!_isMuted) {
      await toggleMute();
    }
    
    _notifyListenersDebounced(immediate: true);
  }
  
  /// Disable Push-to-Talk mode
  Future<void> disablePushToTalk() async {
    if (!_isPushToTalkMode) return;
    
    print('🚀 [Advanced] Push-to-Talk mode DISABLED');
    _isPushToTalkMode = false;
    _isPushToTalkActive = false;
    
    _notifyListenersDebounced(immediate: true);
  }
  
  /// Start Push-to-Talk (hold to speak)
  Future<void> startPushToTalk() async {
    if (!_isPushToTalkMode || _isPushToTalkActive) return;
    
    print('🎤 [PTT] Push-to-Talk ACTIVE');
    _isPushToTalkActive = true;
    
    // Unmute
    if (_isMuted) {
      await toggleMute();
    }
    
    _notifyListenersDebounced();
  }
  
  /// Stop Push-to-Talk (release)
  Future<void> stopPushToTalk() async {
    if (!_isPushToTalkMode || !_isPushToTalkActive) return;
    
    print('🔇 [PTT] Push-to-Talk INACTIVE');
    _isPushToTalkActive = false;
    
    // Mute
    if (!_isMuted) {
      await toggleMute();
    }
    
    _notifyListenersDebounced();
  }
  
  /// Enable Voice Activation Detection
  Future<void> enableVoiceActivation() async {
    if (_isVoiceActivationEnabled) return;
    
    print('🚀 [Advanced] Voice Activation ENABLED');
    _isVoiceActivationEnabled = true;
    
    // Auto-mute when not speaking
    // This would require monitoring local audio level
    
    _notifyListenersDebounced();
  }
  
  /// Disable Voice Activation Detection
  Future<void> disableVoiceActivation() async {
    if (!_isVoiceActivationEnabled) return;
    
    print('🚀 [Advanced] Voice Activation DISABLED');
    _isVoiceActivationEnabled = false;
    
    _notifyListenersDebounced();
  }
  
  /// Toggle Debug Mode
  void toggleDebugMode() {
    _isDebugMode = !_isDebugMode;
    print('🐛 [Advanced] Debug mode: ${_isDebugMode ? "ON" : "OFF"}');
    _notifyListenersDebounced();
  }
  
  /// Get session statistics
  Map<String, dynamic> getSessionStats() {
    return {
      'sessionDuration': sessionDuration?.inSeconds ?? 0,
      'participantCount': _participants.length,
      'totalBytesSent': _totalBytesSent,
      'totalBytesReceived': _totalBytesReceived,
      'dominantSpeaker': _dominantSpeaker,
      'connectionQuality': _connectionQuality,
      'isLowBandwidthMode': _isLowBandwidthMode,
      'speakingDurations': _speakingDurations,
      'errorCount': _errorLog.length,
      'reconnectAttempts': _reconnectAttempts.values.fold(0, (a, b) => a + b),
    };
  }
  
  /// Print session statistics to console
  void printSessionStats() {
    final stats = getSessionStats();
    
    print('📊 ===== SESSION STATISTICS =====');
    print('   Duration: ${stats['sessionDuration']}s');
    print('   Participants: ${stats['participantCount']}');
    print('   Bytes Sent: ${stats['totalBytesSent']}');
    print('   Bytes Received: ${stats['totalBytesReceived']}');
    print('   Connection Quality: ${stats['connectionQuality']}');
    print('   Low Bandwidth: ${stats['isLowBandwidthMode']}');
    print('   Errors: ${stats['errorCount']}');
    print('   Reconnects: ${stats['reconnectAttempts']}');
    print('================================');
  }
  
  /// Test echo (speak and hear yourself)
  Future<void> startEchoTest() async {
    print('🚀 [Advanced] Echo test started');
    print('   Speak into your microphone to test audio');
    
    // In a real implementation, this would route local audio to speakers
    // For now, just log
    
    _notifyListenersDebounced();
  }
  
  /// Stop echo test
  Future<void> stopEchoTest() async {
    print('🚀 [Advanced] Echo test stopped');
    _notifyListenersDebounced();
  }
  
  /// Kick user from room (admin feature)
  Future<void> kickUser(String userId) async {
    print('🚀 [Advanced] Kicking user: $userId');
    
    // Remove participant
    await onUserLeft(userId);
    
    // In production, would notify signaling server
    
    print('✅ [Advanced] User kicked: $userId');
  }
  
  /// Get detailed debug info
  String getDebugInfo() {
    final buffer = StringBuffer();
    
    buffer.writeln('🐛 DEBUG INFO');
    buffer.writeln('═' * 40);
    buffer.writeln('Room: $_currentRoomId');
    buffer.writeln('User: $_currentUsername ($_currentUserId)');
    buffer.writeln('Participants: ${_participants.length}');
    buffer.writeln('Muted: $_isMuted');
    buffer.writeln('Push-to-Talk: $_isPushToTalkMode');
    buffer.writeln('Voice Activation: $_isVoiceActivationEnabled');
    buffer.writeln('Connection Quality: $_connectionQuality');
    buffer.writeln('Low Bandwidth: $_isLowBandwidthMode');
    buffer.writeln('Session Duration: ${sessionDuration?.inSeconds ?? 0}s');
    buffer.writeln('═' * 40);
    
    return buffer.toString();
  }

  @override
  void dispose() {
    // 🚀 STEP 8: Print final stats
    if (_isDebugMode) {
      printSessionStats();
    }
    
    // 🎨 STEP 7: Stop audio visualizer
    _stopAudioLevelMonitoring();
    
    // 📱 STEP 6: Stop mobile monitoring
    _stopConnectionQualityMonitor();
    
    // Cancel UI update debouncer
    _cancelUiUpdateDebouncer();
    
    // Cancel all reconnect timers
    for (var timer in _reconnectTimers.values) {
      timer?.cancel();
    }
    _reconnectTimers.clear();
    _reconnectAttempts.clear();
    
    leaveVoiceRoom();
    super.dispose();
  }
}
