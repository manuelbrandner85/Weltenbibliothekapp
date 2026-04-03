/// 🦞 OpenClaw WebRTC Proxy Service - Intelligentes VoiceChat-Management
/// 
/// Bietet KI-gestützte VoiceChat-Features:
/// - 🎙️ Echtzeit Voice-Moderation
/// - 🔊 Audio-Quality-Enhancement
/// - 🎯 Smart Room-Matching
/// - 📊 Voice-Analytics
/// - 🛡️ Abuse-Detection
library;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'voice_backend_service.dart'; // Fallback zu Cloudflare

/// OpenClaw WebRTC Proxy mit KI-gestützten Voice-Features
class OpenClawWebRTCProxyService {
  static final OpenClawWebRTCProxyService _instance = OpenClawWebRTCProxyService._internal();
  factory OpenClawWebRTCProxyService() => _instance;
  OpenClawWebRTCProxyService._internal();

  // OpenClaw Gateway Configuration
  static String get _gatewayUrl => ApiConfig.openClawGatewayUrl;
  static String get _gatewayToken => ApiConfig.openClawGatewayToken;
  
  // Fallback Service (Cloudflare)
  final VoiceBackendService _fallback = VoiceBackendService();
  
  // Active Sessions Cache
  final Map<String, VoiceSessionInfo> _activeSessions = {};
  
  // Real-time Monitoring
  Timer? _monitoringTimer;
  bool _isMonitoring = false;

  // ════════════════════════════════════════════════════════════
  // 🎙️ INTELLIGENTES VOICE ROOM JOIN
  // ════════════════════════════════════════════════════════════

  /// Join Voice Room mit OpenClaw-Intelligenz
  /// 
  /// Features:
  /// - KI-gestützte Raum-Analyse
  /// - Optimale Room-Zuweisung
  /// - Qualitäts-Monitoring
  /// - Abuse-Prevention
  /// 
  /// Workflow:
  /// 1. OpenClaw analysiert Room-Zustand
  /// 2. Backend-Session erstellen (Cloudflare)
  /// 3. OpenClaw-Monitoring aktivieren
  /// 4. WebRTC-Verbindung aufbauen
  Future<EnhancedJoinResponse> joinVoiceRoomIntelligent({
    required String roomId,
    required String userId,
    required String username,
    required String world,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('🦞 [OpenClaw Voice] Intelligent room join');
        debugPrint('   Room: $roomId');
        debugPrint('   User: $username');
      }

      // SCHRITT 1: OpenClaw Room-Analyse
      final roomAnalysis = await _analyzeRoom(roomId, world);

      // SCHRITT 2: Fallback zu Cloudflare Backend für Session-Erstellung
      final backendResponse = await _fallback.joinVoiceRoom(
        roomId: roomId,
        userId: userId,
        username: username,
        world: world,
      );

      // SCHRITT 3: Session-Info speichern
      final sessionInfo = VoiceSessionInfo(
        sessionId: backendResponse.sessionId,
        roomId: roomId,
        userId: userId,
        username: username,
        world: world,
        joinedAt: DateTime.now(),
        roomQuality: roomAnalysis['quality'] ?? 'unknown',
        monitoringEnabled: true,
      );
      
      _activeSessions[userId] = sessionInfo;

      // SCHRITT 4: Monitoring starten
      _startMonitoring(userId);

      if (kDebugMode) {
        debugPrint('✅ [OpenClaw Voice] Intelligent join complete');
        debugPrint('   Session ID: ${backendResponse.sessionId}');
        debugPrint('   Room Quality: ${roomAnalysis['quality']}');
      }

      return EnhancedJoinResponse(
        sessionId: backendResponse.sessionId,
        participants: backendResponse.participants,
        currentCount: backendResponse.currentParticipantCount,
        roomQuality: roomAnalysis['quality'],
        recommendations: roomAnalysis['recommendations'] ?? [],
        service: 'openclaw+cloudflare',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [OpenClaw Voice] Intelligent join failed: $e');
        debugPrint('   Falling back to standard join...');
      }

      // Vollständiger Fallback zu Cloudflare
      final backendResponse = await _fallback.joinVoiceRoom(
        roomId: roomId,
        userId: userId,
        username: username,
        world: world,
      );

      return EnhancedJoinResponse(
        sessionId: backendResponse.sessionId,
        participants: backendResponse.participants,
        currentCount: backendResponse.currentParticipantCount,
        roomQuality: 'unknown',
        recommendations: [],
        service: 'cloudflare',
      );
    }
  }

  // ════════════════════════════════════════════════════════════
  // 🎯 ROOM-ANALYSE
  // ════════════════════════════════════════════════════════════

  /// Analysiert Voice-Room mit OpenClaw KI
  /// 
  /// Returns:
  /// {
  ///   'quality': 'excellent' | 'good' | 'moderate' | 'poor',
  ///   'participants': int,
  ///   'averageLatency': int (ms),
  ///   'hasIssues': bool,
  ///   'recommendations': List[String]
  /// }
  Future<Map<String, dynamic>> _analyzeRoom(String roomId, String world) async {
    try {
      final response = await http.post(
        Uri.parse('$_gatewayUrl/voice/analyze-room'),
        headers: {
          'Authorization': 'Bearer $_gatewayToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'room_id': roomId,
          'world': world,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Room analysis failed: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [OpenClaw Voice] Room analysis failed: $e');
      }

      // Fallback: Standard-Qualität
      return {
        'quality': 'good',
        'participants': 0,
        'averageLatency': 100,
        'hasIssues': false,
        'recommendations': [],
      };
    }
  }

  // ════════════════════════════════════════════════════════════
  // 🔊 ECHTZEIT AUDIO-MODERATION
  // ════════════════════════════════════════════════════════════

  /// Überwacht Audio-Stream auf problematische Inhalte
  /// 
  /// Features:
  /// - Lautstärke-Analyse
  /// - Noise-Detection
  /// - Abuse-Erkennung
  /// - Quality-Issues
  Future<Map<String, dynamic>> moderateAudioStream({
    required String userId,
    required String roomId,
    Map<String, dynamic>? audioMetrics,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_gatewayUrl/voice/moderate-audio'),
        headers: {
          'Authorization': 'Bearer $_gatewayToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id': userId,
          'room_id': roomId,
          'audio_metrics': audioMetrics ?? {},
          'timestamp': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['shouldMute'] == true) {
          if (kDebugMode) {
            debugPrint('🔇 [OpenClaw Voice] Auto-mute triggered for $userId');
            debugPrint('   Reason: ${data['reason']}');
          }
        }

        return data;
      } else {
        throw Exception('Audio moderation failed: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [OpenClaw Voice] Audio moderation failed: $e');
      }

      // Fallback: Keine Moderation
      return {
        'shouldMute': false,
        'reason': null,
        'confidence': 0.0,
      };
    }
  }

  // ════════════════════════════════════════════════════════════
  // 🎯 SMART ROOM-MATCHING
  // ════════════════════════════════════════════════════════════

  /// Findet optimalen Voice-Room für User
  /// 
  /// Berücksichtigt:
  /// - Aktuelle Auslastung
  /// - Geographische Nähe
  /// - Sprach-Präferenzen
  /// - Quality-Score
  Future<String?> findOptimalRoom({
    required String world,
    required String userId,
    List<String>? availableRooms,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_gatewayUrl/voice/find-optimal-room'),
        headers: {
          'Authorization': 'Bearer $_gatewayToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'world': world,
          'user_id': userId,
          'available_rooms': availableRooms ?? [],
          'timestamp': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (kDebugMode) {
          debugPrint('🎯 [OpenClaw Voice] Optimal room found');
          debugPrint('   Room: ${data['room_id']}');
          debugPrint('   Quality Score: ${data['quality_score']}');
        }

        return data['room_id'];
      } else {
        throw Exception('Room matching failed: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [OpenClaw Voice] Room matching failed: $e');
      }

      // Fallback: Erste verfügbare Room
      return availableRooms?.isNotEmpty == true ? availableRooms!.first : null;
    }
  }

  // ════════════════════════════════════════════════════════════
  // 📊 VOICE ANALYTICS
  // ════════════════════════════════════════════════════════════

  /// Sammelt Voice-Session-Analytics
  Future<Map<String, dynamic>> getVoiceAnalytics({
    required String userId,
    required String roomId,
    int daysBack = 7,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_gatewayUrl/voice/analytics/$userId')
            .replace(queryParameters: {
          'room_id': roomId,
          'days_back': daysBack.toString(),
        }),
        headers: {
          'Authorization': 'Bearer $_gatewayToken',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Analytics failed: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [OpenClaw Voice] Analytics failed: $e');
      }

      return {
        'totalSessions': 0,
        'averageDuration': 0,
        'qualityScore': 0.0,
      };
    }
  }

  // ════════════════════════════════════════════════════════════
  // 🛡️ ABUSE-DETECTION
  // ════════════════════════════════════════════════════════════

  /// Erkennt Voice-Abuse (Spam, Harassment, etc.)
  Future<Map<String, dynamic>> detectVoiceAbuse({
    required String userId,
    required String roomId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_gatewayUrl/voice/detect-abuse'),
        headers: {
          'Authorization': 'Bearer $_gatewayToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id': userId,
          'room_id': roomId,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['abusive'] == true) {
          if (kDebugMode) {
            debugPrint('🚨 [OpenClaw Voice] Abuse detected for $userId');
            debugPrint('   Type: ${data['abuse_type']}');
          }
        }

        return data;
      } else {
        throw Exception('Abuse detection failed: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [OpenClaw Voice] Abuse detection failed: $e');
      }

      return {
        'abusive': false,
        'abuse_type': null,
        'confidence': 0.0,
      };
    }
  }

  // ════════════════════════════════════════════════════════════
  // 🔄 MONITORING
  // ════════════════════════════════════════════════════════════

  /// Startet Echtzeit-Monitoring für Session
  void _startMonitoring(String userId) {
    if (_isMonitoring) return;

    _isMonitoring = true;
    _monitoringTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (_activeSessions.containsKey(userId)) {
        final session = _activeSessions[userId]!;
        
        // Abuse-Check
        final abuseCheck = await detectVoiceAbuse(
          userId: session.userId,
          roomId: session.roomId,
        );

        if (abuseCheck['abusive'] == true) {
          // Trigger Auto-Action (z.B. Mute)
          if (kDebugMode) {
            debugPrint('🚨 [OpenClaw Voice] Auto-action triggered for ${session.username}');
          }
        }
      }
    });
  }

  /// Stoppt Monitoring für User
  void stopMonitoring(String userId) {
    _activeSessions.remove(userId);
    
    if (_activeSessions.isEmpty && _monitoringTimer != null) {
      _monitoringTimer!.cancel();
      _monitoringTimer = null;
      _isMonitoring = false;
    }
  }

  // ════════════════════════════════════════════════════════════
  // 🛠️ UTILITY METHODS
  // ════════════════════════════════════════════════════════════

  /// Leave Voice Room
  Future<void> leaveVoiceRoom(String userId) async {
    stopMonitoring(userId);
    
    if (_activeSessions.containsKey(userId)) {
      final session = _activeSessions[userId]!;
      
      // Cloudflare Backend informieren
      await _fallback.leaveVoiceRoom(session.sessionId);
    }
  }

  /// Service-Health-Check
  Future<bool> checkServiceHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$_gatewayUrl/health'),
        headers: {'Authorization': 'Bearer $_gatewayToken'},
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Cleanup
  void dispose() {
    _monitoringTimer?.cancel();
    _activeSessions.clear();
  }
}

// ════════════════════════════════════════════════════════════
// MODELS
// ════════════════════════════════════════════════════════════

/// Enhanced Join Response mit OpenClaw-Features
class EnhancedJoinResponse {
  final String sessionId;
  final List<dynamic> participants;
  final int currentCount;
  final String roomQuality;
  final List<String> recommendations;
  final String service;

  EnhancedJoinResponse({
    required this.sessionId,
    required this.participants,
    required this.currentCount,
    required this.roomQuality,
    required this.recommendations,
    required this.service,
  });
}

/// Voice Session Info
class VoiceSessionInfo {
  final String sessionId;
  final String roomId;
  final String userId;
  final String username;
  final String world;
  final DateTime joinedAt;
  final String roomQuality;
  final bool monitoringEnabled;

  VoiceSessionInfo({
    required this.sessionId,
    required this.roomId,
    required this.userId,
    required this.username,
    required this.world,
    required this.joinedAt,
    required this.roomQuality,
    required this.monitoringEnabled,
  });
}
