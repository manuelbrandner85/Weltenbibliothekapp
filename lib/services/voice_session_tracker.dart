/// 📊 VOICE SESSION TRACKER
/// Automatically tracks WebRTC voice sessions and stores them in backend database
/// 
/// Features:
/// - Session start/end tracking
/// - Speaking time calculation
/// - Admin action logging
/// - Automatic error recovery
library;

import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// Voice Session Tracker Service
/// Tracks and stores voice chat sessions in backend D1 database
class VoiceSessionTracker {
  
  static const Duration _timeout = Duration(seconds: 10);
  
  // Current session tracking
  String? _currentSessionId;
  String? _currentRoomId;
  String? _currentUserId;
  DateTime? _sessionStartTime;
  int _totalSpeakingSeconds = 0;
  Timer? _speakingTimer;
  bool _isSpeaking = false;
  
  /// Start tracking a new voice session
  /// Called when user joins a voice room
  /// 
  /// 🆕 sessionId: Session-ID vom Backend (Backend-First Flow)
  Future<bool> startSession({
    required String sessionId,  // 🆕 Backend Session-ID
    required String roomId,
    required String userId,
    required String username,
    required String world, // 'materie' or 'energie'
  }) async {
    try {
      // 🆕 Use Backend Session-ID instead of generating one
      _currentSessionId = sessionId;
      _currentRoomId = roomId;
      _currentUserId = userId;
      _sessionStartTime = DateTime.now();
      _totalSpeakingSeconds = 0;
      
      if (kDebugMode) {
        debugPrint('🎤 Starting voice session tracking: $_currentSessionId');
        debugPrint('   Room: $roomId');
        debugPrint('   User: $username ($userId)');
        debugPrint('   World: $world');
        debugPrint('   ⭐ Backend Session-ID: $sessionId');
      }
      
      // Send session start to backend
      final url = Uri.parse('${ApiConfig.baseUrl}/api/admin/voice-session/start');
      
      final response = await http.post(
        url,
        headers: {
          
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'session_id': sessionId,  // 🆕 Backend Session-ID
          'room_id': roomId,
          'user_id': userId,
          'username': username,
          'world': world,
          'joined_at': _sessionStartTime!.toIso8601String(),
        }),
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        if (kDebugMode) {
          debugPrint('✅ Voice session started: $_currentSessionId');
        }
        return true;
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ Failed to start session: ${response.statusCode}');
          debugPrint('   Response: ${response.body}');
        }
        return false;
      }
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error starting voice session: $e');
      }
      return false;
    }
  }
  
  /// End current voice session
  /// Called when user leaves voice room
  Future<bool> endSession() async {
    if (_currentSessionId == null) {
      if (kDebugMode) {
        debugPrint('⚠️ No active session to end');
      }
      return false;
    }
    
    try {
      final duration = DateTime.now().difference(_sessionStartTime!).inSeconds;
      
      if (kDebugMode) {
        debugPrint('🎤 Ending voice session: $_currentSessionId');
        debugPrint('   Duration: ${duration}s');
        debugPrint('   Speaking time: ${_totalSpeakingSeconds}s');
      }
      
      // Stop speaking timer if active
      _speakingTimer?.cancel();
      
      // Send session end to backend
      final url = Uri.parse('${ApiConfig.baseUrl}/api/admin/voice-session/end');
      
      final response = await http.post(
        url,
        headers: {
          
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'session_id': _currentSessionId,
          'room_id': _currentRoomId,
          'user_id': _currentUserId,
          'left_at': DateTime.now().toIso8601String(),
          'duration_seconds': duration,
          'speaking_seconds': _totalSpeakingSeconds,
        }),
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        if (kDebugMode) {
          debugPrint('✅ Voice session ended: $_currentSessionId');
        }
        
        // Clear current session
        _currentSessionId = null;
        _currentRoomId = null;
        _currentUserId = null;
        _sessionStartTime = null;
        _totalSpeakingSeconds = 0;
        
        return true;
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ Failed to end session: ${response.statusCode}');
          debugPrint('   Response: ${response.body}');
        }
        return false;
      }
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error ending voice session: $e');
      }
      return false;
    }
  }
  
  /// Start tracking speaking time
  /// Called when user starts speaking
  void startSpeaking() {
    if (_isSpeaking) return;
    
    _isSpeaking = true;
    
    if (kDebugMode) {
      debugPrint('🗣️ User started speaking');
    }
    
    // Start 1-second timer to track speaking time
    _speakingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isSpeaking) {
        _totalSpeakingSeconds++;
        
        if (kDebugMode && _totalSpeakingSeconds % 10 == 0) {
          debugPrint('🗣️ Total speaking time: ${_totalSpeakingSeconds}s');
        }
      }
    });
  }
  
  /// Stop tracking speaking time
  /// Called when user stops speaking
  void stopSpeaking() {
    if (!_isSpeaking) return;
    
    _isSpeaking = false;
    _speakingTimer?.cancel();
    
    if (kDebugMode) {
      debugPrint('🤫 User stopped speaking (total: ${_totalSpeakingSeconds}s)');
    }
  }
  
  /// Log admin action (kick, mute, ban, warn)
  Future<bool> logAdminAction({
    required String actionType, // 'kick', 'mute', 'ban', 'warn'
    required String targetUserId,
    required String targetUsername,
    required String adminUserId,
    required String adminUsername,
    required String world,
    String? reason,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('👮 Logging admin action: $actionType');
        debugPrint('   Admin: $adminUsername ($adminUserId)');
        debugPrint('   Target: $targetUsername ($targetUserId)');
        debugPrint('   Reason: ${reason ?? "(none)"}');
      }
      
      final url = Uri.parse('${ApiConfig.baseUrl}/api/admin/action/log');
      
      final response = await http.post(
        url,
        headers: {
          
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'action_type': actionType,
          'target_user_id': targetUserId,
          'target_username': targetUsername,
          'admin_user_id': adminUserId,
          'admin_username': adminUsername,
          'world': world,
          'room_id': _currentRoomId,
          'reason': reason,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        if (kDebugMode) {
          debugPrint('✅ Admin action logged');
        }
        return true;
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ Failed to log admin action: ${response.statusCode}');
        }
        return false;
      }
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error logging admin action: $e');
      }
      return false;
    }
  }
  
  /// Get current session info
  Map<String, dynamic>? getCurrentSession() {
    if (_currentSessionId == null) return null;
    
    return {
      'session_id': _currentSessionId,
      'room_id': _currentRoomId,
      'user_id': _currentUserId,
      'started_at': _sessionStartTime?.toIso8601String(),
      'duration_seconds': _sessionStartTime != null 
          ? DateTime.now().difference(_sessionStartTime!).inSeconds 
          : 0,
      'speaking_seconds': _totalSpeakingSeconds,
      'is_speaking': _isSpeaking,
    };
  }
  
  /// Dispose resources
  void dispose() {
    _speakingTimer?.cancel();
  }
}
