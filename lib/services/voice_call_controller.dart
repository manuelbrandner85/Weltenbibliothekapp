/// 🎙️ VOICE CALL CONTROLLER
/// Global state management for Telegram-style voice chats
/// 
/// Features:
/// - Single global voice call state
/// - User tile management
/// - Speaking detection
/// - Minimized overlay support
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/chat_models.dart';
import 'webrtc_voice_service.dart';

/// Voice Call State
enum VoiceCallState {
  idle,        // Not in any call
  connecting,  // Joining a call
  connected,   // In a call
  minimized,   // Call minimized (background)
}

/// Voice Call Controller (Singleton)
class VoiceCallController extends ChangeNotifier {
  static final VoiceCallController _instance = VoiceCallController._internal();
  factory VoiceCallController() => _instance;
  VoiceCallController._internal();

  // WebRTC Service
  final WebRTCVoiceService _webrtcService = WebRTCVoiceService();

  // State
  VoiceCallState _state = VoiceCallState.idle;
  String? _currentRoomId;
  String? _currentRoomName;
  String? _currentUserId;
  String? _currentUsername;
  
  // Participants
  List<VoiceParticipant> _participants = [];
  
  // Audio Levels (for visualizations)
  final Map<String, double> _audioLevels = {};
  
  // Speaking Detection
  String? _currentSpeakerId;
  final Map<String, int> _speakingFrames = {};
  static const int _speakingThreshold = 3;
  static const double _audioThreshold = 0.02;
  Timer? _speakingDetectionTimer;
  
  // Subscriptions
  StreamSubscription? _participantsSubscription;
  StreamSubscription? _speakingSubscription;

  // Getters
  VoiceCallState get state => _state;
  bool get isIdle => _state == VoiceCallState.idle;
  bool get isConnecting => _state == VoiceCallState.connecting;
  bool get isConnected => _state == VoiceCallState.connected;
  bool get isMinimized => _state == VoiceCallState.minimized;
  bool get isInCall => _state == VoiceCallState.connected || _state == VoiceCallState.minimized;
  bool get isInVoiceRoom => isInCall; // Alias for better API
  
  String? get currentRoomId => _currentRoomId;
  String? get currentRoomName => _currentRoomName;
  String? get currentUserId => _currentUserId;
  String? get currentUsername => _currentUsername;
  
  List<VoiceParticipant> get participants => List.unmodifiable(_participants);
  int get participantCount => _participants.length;
  
  String? get currentSpeakerId => _currentSpeakerId;
  
  bool get isMuted => _webrtcService.isMuted;

  /// Join Voice Room
  Future<bool> joinVoiceRoom(String roomId, String roomName, String userId, String username) async {
    try {
      // ✅ FORCE LOGGING (even in release mode for debugging)
      print('🚀 [VoiceCall] ===== JOIN VOICE ROOM START =====');
      print('🎙️ [VoiceCall] Joining room: $roomName ($roomId)');
      print('   👤 User: $username ($userId)');
      
      if (kDebugMode) {
        debugPrint('🚀 [VoiceCall] ===== JOIN VOICE ROOM START =====');
        debugPrint('🎙️ [VoiceCall] Joining room: $roomName ($roomId)');
        debugPrint('   👤 User: $username ($userId)');
      }

      // Leave existing call first
      if (_currentRoomId != null) {
        print('⚠️ [VoiceCall] Already in room $_currentRoomId, leaving first');
        if (kDebugMode) {
          debugPrint('⚠️ [VoiceCall] Already in room $_currentRoomId, leaving first');
        }
        await leaveVoiceRoom();
      }

      _state = VoiceCallState.connecting;
      _currentRoomId = roomId;
      _currentRoomName = roomName;
      _currentUserId = userId;
      _currentUsername = username;
      notifyListeners();

      print('📞 [VoiceCall] Calling WebRTC Service...');
      if (kDebugMode) {
        debugPrint('📞 [VoiceCall] Calling WebRTC Service...');
      }

      // Join via WebRTC Service
      final success = await _webrtcService.joinVoiceRoom(roomId, userId, username);

      print('📡 [VoiceCall] WebRTC Service returned: $success');
      if (kDebugMode) {
        debugPrint('📡 [VoiceCall] WebRTC Service returned: $success');
      }

      if (success) {
        _state = VoiceCallState.connected;
        
        // ✅ CRITICAL: Add self as first participant immediately
        _participants.clear();
        _participants.add(VoiceParticipant(
          userId: userId,
          username: username,
          isMuted: false,
        ));
        
        print('✅ [VoiceCall] Joined successfully');
        print('   🔢 Initial participants count: ${_participants.length}');
        print('   👤 Participants: ${_participants.map((p) => p.username).join(", ")}');
        
        if (kDebugMode) {
          debugPrint('✅ [VoiceCall] Joined successfully');
          debugPrint('   🔢 Initial participants count: ${_participants.length}');
          debugPrint('   👤 Participants: ${_participants.map((p) => p.username).join(", ")}');
        }
        
        _startSpeakingDetection();
        _subscribeToStreams();
        
        // ✅ CRITICAL: Notify listeners AFTER adding self
        notifyListeners();

        print('🚀 [VoiceCall] ===== JOIN VOICE ROOM SUCCESS =====');
        if (kDebugMode) {
          debugPrint('🚀 [VoiceCall] ===== JOIN VOICE ROOM SUCCESS =====');
        }

        return true;
      } else {
        _state = VoiceCallState.idle;
        _currentRoomId = null;
        _currentRoomName = null;
        _currentUserId = null;
        _currentUsername = null;
        notifyListeners();

        print('❌ [VoiceCall] Failed to join');
        print('🚀 [VoiceCall] ===== JOIN VOICE ROOM FAILED =====');
        
        if (kDebugMode) {
          debugPrint('❌ [VoiceCall] Failed to join');
          debugPrint('🚀 [VoiceCall] ===== JOIN VOICE ROOM FAILED =====');
        }

        return false;
      }
    } catch (e, stackTrace) {
      print('❌ [VoiceCall] Error joining: $e');
      print('   Stack trace: $stackTrace');
      print('🚀 [VoiceCall] ===== JOIN VOICE ROOM ERROR =====');
      
      if (kDebugMode) {
        debugPrint('❌ [VoiceCall] Error joining: $e');
        debugPrint('   Stack trace: $stackTrace');
        debugPrint('🚀 [VoiceCall] ===== JOIN VOICE ROOM ERROR =====');
      }
      _state = VoiceCallState.idle;
      notifyListeners();
      return false;
    }
  }

  /// Leave Voice Room
  Future<void> leaveVoiceRoom() async {
    try {
      if (kDebugMode) {
        debugPrint('🚪 [VoiceCall] Leaving room: $_currentRoomId');
      }

      await _webrtcService.leaveVoiceRoom();
      _stopSpeakingDetection();
      
      _state = VoiceCallState.idle;
      _currentRoomId = null;
      _currentRoomName = null;
      _currentUserId = null;
      _currentUsername = null;
      _participants.clear();
      _audioLevels.clear();
      _currentSpeakerId = null;
      
      notifyListeners();

      if (kDebugMode) {
        debugPrint('✅ [VoiceCall] Left room');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [VoiceCall] Error leaving: $e');
      }
    }
  }

  /// Minimize Call
  void minimize() {
    if (_state == VoiceCallState.connected) {
      _state = VoiceCallState.minimized;
      notifyListeners();
    }
  }

  /// Maximize Call
  void maximize() {
    if (_state == VoiceCallState.minimized) {
      _state = VoiceCallState.connected;
      notifyListeners();
    }
  }

  /// Toggle Mute
  Future<void> toggleMute() async {
    await _webrtcService.toggleMute();
    notifyListeners();
  }

  /// Start Push-to-Talk
  Future<void> startPushToTalk() async {
    await _webrtcService.startPushToTalk();
    notifyListeners();
  }

  /// Stop Push-to-Talk
  Future<void> stopPushToTalk() async {
    await _webrtcService.stopPushToTalk();
    notifyListeners();
  }

  /// Subscribe to WebRTC Streams
  void _subscribeToStreams() {
    _participantsSubscription = _webrtcService.participantsStream.listen((participants) {
      if (kDebugMode) {
        debugPrint('🔄 [VoiceCall] Participants stream update: ${participants.length} users');
        for (var p in participants) {
          debugPrint('   👤 ${p.username} (${p.userId})');
        }
      }
      
      // Detect new participants (join notifications)
      final newParticipants = participants.where(
        (p) => !_participants.any((old) => old.userId == p.userId)
      ).toList();
      
      // Trigger join notifications for new participants
      for (var participant in newParticipants) {
        if (participant.userId != _currentUserId) {
          _onParticipantJoined?.call(participant.username);
        }
      }
      
      // ✅ CRITICAL: Merge with current user if not in list
      if (participants.isEmpty || !participants.any((p) => p.userId == _currentUserId)) {
        if (kDebugMode) {
          debugPrint('⚠️ [VoiceCall] Self not in participants list from WebRTC - keeping self');
        }
        // Keep self in list
        final self = VoiceParticipant(
          userId: _currentUserId!,
          username: _currentUsername!,
          isMuted: false,
        );
        _participants = [self, ...participants];
      } else {
        _participants = participants;
      }
      
      if (kDebugMode) {
        debugPrint('🔢 [VoiceCall] Final participants count: ${_participants.length}');
      }
      
      notifyListeners();
    });

    _speakingSubscription = _webrtcService.speakingStream.listen((speakingUserId) {
      updateSpeakingStatus(speakingUserId, true);
    });
  }
  
  // Join notification callback
  void Function(String username)? _onParticipantJoined;
  
  /// Set join notification callback
  void setOnParticipantJoined(void Function(String username)? callback) {
    _onParticipantJoined = callback;
  }

  /// Update Speaking Status
  void updateSpeakingStatus(String userId, bool isSpeaking) {
    if (isSpeaking) {
      _speakingFrames[userId] = (_speakingFrames[userId] ?? 0) + 1;
      
      if (_speakingFrames[userId]! >= _speakingThreshold) {
        if (_currentSpeakerId != userId) {
          _currentSpeakerId = userId;
          notifyListeners();
        }
      }
    } else {
      _speakingFrames[userId] = 0;
      if (_currentSpeakerId == userId) {
        _currentSpeakerId = null;
        notifyListeners();
      }
    }
  }

  /// Start Speaking Detection
  void _startSpeakingDetection() {
    _speakingDetectionTimer?.cancel();
    _speakingDetectionTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _detectSpeaking();
    });
  }

  /// Stop Speaking Detection
  void _stopSpeakingDetection() {
    _speakingDetectionTimer?.cancel();
    _speakingDetectionTimer = null;
  }

  /// Detect Speaking
  Future<void> _detectSpeaking() async {
    for (final participant in _participants) {
      final userId = participant.userId;
      
      // Get audio level
      double level = 0.0;
      
      // Local user
      if (userId == _currentUserId) {
        // TODO: Get local audio level
        level = 0.0;
      }
      
      // Update speaking status
      updateSpeakingStatus(userId, level > _audioThreshold);
    }
  }

  @override
  void dispose() {
    _stopSpeakingDetection();
    _participantsSubscription?.cancel();
    _speakingSubscription?.cancel();
    super.dispose();
  }
}
