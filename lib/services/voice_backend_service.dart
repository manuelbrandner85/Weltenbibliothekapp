/// 🌐 WELTENBIBLIOTHEK - VOICE BACKEND SERVICE
/// Backend-First WebRTC Flow: Backend-Session vor WebRTC-Verbindung
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../services/webrtc_voice_service.dart' show VoiceParticipant;
import '../core/exceptions/exception_guard.dart';
import '../core/exceptions/specialized_exceptions.dart';

/// Backend Service für Voice Chat (Backend-First Flow)
class VoiceBackendService {
  static const String _baseUrl = 'https://weltenbibliothek-api-v3.brandy13062.workers.dev'; // ✅ MIGRATED to v3.1
  static const String _apiToken = 'y-Xiv3kKeiybDm2CV0yLFu7TSd22co6NBw3udn5Y';
  
  /// Backend-Join: Session im Backend erstellen, Session-ID erhalten
  /// 
  /// Flow: backend.join() → sessionId → tracking → webrtc → provider
  /// 
  /// Returns: [BackendJoinResponse] mit sessionId, participants, currentCount
  /// Throws: [RoomFullException] wenn Raum voll, [BackendException] bei Server-Fehler
  Future<BackendJoinResponse> joinVoiceRoom({
    required String roomId,
    required String userId,
    required String username,
    required String world,
  }) async {
    return guardApi(
      () async {
        if (kDebugMode) {
          debugPrint('🌐 [BACKEND] Voice Join Request');
          debugPrint('   Room: $roomId');
          debugPrint('   User: $username ($userId)');
          debugPrint('   World: $world');
        }
        
        final response = await http.post(
          Uri.parse('$_baseUrl/voice/join'),
          headers: {
            'Authorization': 'Bearer $_apiToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'room_id': roomId,
            'user_id': userId,
            'username': username,
            'world': world,
          }),
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException(
              'Backend voice join request timed out',
              timeout: const Duration(seconds: 10),
              operation: 'Voice Join',
            );
          },
        );
        
        if (kDebugMode) {
          debugPrint('🌐 [BACKEND] Response: ${response.statusCode}');
        }
        
        // HTTP-Status-Code prüfen
        if (response.statusCode == 401) {
          throw AuthException('Unauthorized API access');
        }
        
        if (response.statusCode == 404) {
          // ✅ FALLBACK: Voice-Endpoint nicht verfügbar → Mock-Session erstellen
          if (kDebugMode) {
            debugPrint('⚠️ [BACKEND] Voice endpoint not available (404) - using fallback mode');
          }
          
          // Mock-Response für offline/fallback operation
          return BackendJoinResponse(
            success: true,
            sessionId: 'fallback_${DateTime.now().millisecondsSinceEpoch}',
            roomId: roomId,
            maxParticipants: 10,
            currentParticipantCount: 1, // Just the current user
            participants: [], // Empty initial participants
            joinedAt: DateTime.now().toIso8601String(),
          );
        }
        
        if (response.statusCode >= 500) {
          throw BackendException.serverError('/voice/join');
        }
        
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (response.statusCode != 200) {
          final error = data['error'] ?? 'Unknown error';
          final message = data['message'] ?? error;
          
          if (kDebugMode) {
            debugPrint('❌ [BACKEND] Join failed: $message');
          }
          
          throw BackendException(
            message,
            statusCode: response.statusCode,
            endpoint: '/voice/join',
            responseBody: response.body,
          );
        }
        
        // Response parsen
        final joinResponse = BackendJoinResponse.fromJson(data);
        
        if (!joinResponse.success) {
          // Spezielle Behandlung für "Room Full"
          if (joinResponse.error?.contains('full') == true || 
              joinResponse.message?.contains('full') == true) {
            throw RoomFullException(
              roomId: roomId,
              currentCount: joinResponse.currentParticipantCount ?? 10,
              maxCount: joinResponse.maxParticipants ?? 10,
            );
          }
          
          throw BackendException(
            joinResponse.message ?? 'Backend-Join failed',
            statusCode: response.statusCode,
            endpoint: '/voice/join',
          );
        }
        
        if (kDebugMode) {
          debugPrint('✅ [BACKEND] Join successful');
          debugPrint('   Session-ID: ${joinResponse.sessionId}');
          debugPrint('   Participants: ${joinResponse.currentParticipantCount}/${joinResponse.maxParticipants}');
        }
        
        return joinResponse;
      },
      operationName: 'Voice Join (Backend)',
      url: '$_baseUrl/voice/join',
      method: 'POST',
      context: {
        'roomId': roomId,
        'userId': userId,
        'username': username,
        'world': world,
      },
    );
  }
  
  /// Backend-Leave: Session im Backend beenden
  /// 
  /// Sollte aufgerufen werden wenn:
  /// - User den Raum verlässt
  /// - WebRTC-Verbindung fehlschlägt (Rollback)
  /// - Permission verweigert (Rollback)
  /// 
  /// Returns: [BackendLeaveResponse] mit duration, left_at
  Future<BackendLeaveResponse> leaveVoiceRoom(String sessionId) async {
    return guardApi(
      () async {
        if (kDebugMode) {
          debugPrint('🌐 [BACKEND] Voice Leave Request: $sessionId');
        }
        
        final response = await http.post(
          Uri.parse('$_baseUrl/voice/leave'),
          headers: {
            'Authorization': 'Bearer $_apiToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'session_id': sessionId,
          }),
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException(
              'Backend voice leave request timed out',
              timeout: const Duration(seconds: 10),
              operation: 'Voice Leave',
            );
          },
        );
        
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (response.statusCode != 200) {
          if (kDebugMode) {
            debugPrint('⚠️ [BACKEND] Leave warning: ${data['error']}');
          }
          
          throw BackendException(
            data['error'] ?? 'Leave request failed',
            statusCode: response.statusCode,
            endpoint: '/voice/leave',
          );
        }
        
        final leaveResponse = BackendLeaveResponse.fromJson(data);
        
        if (kDebugMode) {
          debugPrint('✅ [BACKEND] Leave successful');
          debugPrint('   Session-ID: ${leaveResponse.sessionId}');
          debugPrint('   Duration: ${leaveResponse.durationSeconds}s');
        }
        
        return leaveResponse;
      },
      operationName: 'Voice Leave (Backend)',
      url: '$_baseUrl/voice/leave',
      method: 'POST',
      context: {'sessionId': sessionId},
      // Error-Recovery: Bei Fehler trotzdem "erfolgreich" zurückgeben
      // (Session könnte bereits beendet sein)
      onError: (error, stackTrace) async {
        if (kDebugMode) {
          debugPrint('⚠️ [BACKEND] Leave error (non-critical): $error');
        }
        return BackendLeaveResponse(
          success: false,
          sessionId: sessionId,
          error: error.toString(),
        );
      },
    );
  }
  
  /// Get Active Rooms
  Future<List<VoiceRoomInfo>> getActiveRooms(String world) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/voice/rooms/$world'),
        headers: {
          'Authorization': 'Bearer $_apiToken',
        },
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to get active rooms: ${response.statusCode}');
      }
      
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final rooms = (data['rooms'] as List)
          .map((r) => VoiceRoomInfo.fromJson(r as Map<String, dynamic>))
          .toList();
      
      return rooms;
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Get active rooms error: $e');
      }
      throw Exception('Failed to get active rooms: $e');
    }
  }
  
  /// Fetch current participants in a voice room
  /// 
  /// Returns: List of [VoiceParticipant] currently in the room
  /// Throws: [BackendException] bei Server-Fehler, [NetworkException] bei Netzwerk-Fehler
  Future<List<VoiceParticipant>> fetchParticipants(String roomId) async {
    return guardApi(
      () async {
        if (kDebugMode) {
          debugPrint('🌐 [BACKEND] Fetch Participants Request: $roomId');
        }
        
        final response = await http.get(
          Uri.parse('$_baseUrl/voice/participants/$roomId'),
          headers: {
            'Authorization': 'Bearer $_apiToken',
            'Content-Type': 'application/json',
          },
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException(
              'Backend participants fetch timed out',
              timeout: const Duration(seconds: 10),
              operation: 'Fetch Participants',
            );
          },
        );
        
        if (response.statusCode == 401) {
          throw AuthException('Unauthorized API access');
        }
        
        if (response.statusCode == 404) {
          throw BackendException.notFound('/voice/participants/$roomId');
        }
        
        if (response.statusCode >= 500) {
          throw BackendException.serverError('/voice/participants/$roomId');
        }
        
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (response.statusCode != 200) {
          final error = data['error'] ?? 'Unknown error';
          final message = data['message'] ?? error;
          
          throw BackendException(
            message,
            statusCode: response.statusCode,
            endpoint: '/voice/participants/$roomId',
            responseBody: response.body,
          );
        }
        
        // Parse participants list
        final participantsList = data['participants'] as List<dynamic>?;
        
        if (participantsList == null) {
          if (kDebugMode) {
            debugPrint('✅ [BACKEND] No participants in room');
          }
          return [];
        }
        
        final participants = participantsList
            .map((p) => VoiceParticipant.fromBackendJson(p as Map<String, dynamic>))
            .toList();
        
        if (kDebugMode) {
          debugPrint('✅ [BACKEND] Fetched ${participants.length} participants');
        }
        
        return participants;
      },
      operationName: 'Fetch Participants (Backend)',
      url: '$_baseUrl/voice/participants/$roomId',
      method: 'GET',
      context: {'roomId': roomId},
    );
  }
}

// ============================================================================
// BACKEND RESPONSE MODELS
// ============================================================================

/// Backend-Join Response
class BackendJoinResponse {
  final bool success;
  final String sessionId;
  final String roomId;
  final int maxParticipants;
  final int currentParticipantCount;
  final List<VoiceParticipant> participants;
  final String? joinedAt;
  final String? message;
  final String? error;
  
  BackendJoinResponse({
    required this.success,
    required this.sessionId,
    required this.roomId,
    required this.maxParticipants,
    required this.currentParticipantCount,
    required this.participants,
    this.joinedAt,
    this.message,
    this.error,
  });
  
  factory BackendJoinResponse.fromJson(Map<String, dynamic> json) {
    return BackendJoinResponse(
      success: json['success'] ?? false,
      sessionId: json['session_id'] ?? '',
      roomId: json['room_id'] ?? '',
      maxParticipants: json['max_participants'] ?? 10,
      currentParticipantCount: json['current_participant_count'] ?? 0,
      participants: (json['participants'] as List?)
          ?.map((p) => VoiceParticipant(
                userId: p['userId'] ?? '',
                username: p['username'] ?? '',
                isMuted: p['isMuted'] ?? false,
                isSpeaking: p['isSpeaking'] ?? false,
              ))
          .toList() ?? [],
      joinedAt: json['joined_at'],
      message: json['message'],
      error: json['error'],
    );
  }
}

/// Backend-Leave Response
class BackendLeaveResponse {
  final bool success;
  final String sessionId;
  final String? roomId;
  final String? userId;
  final int? durationSeconds;
  final String? leftAt;
  final String? message;
  final String? error;
  
  BackendLeaveResponse({
    required this.success,
    required this.sessionId,
    this.roomId,
    this.userId,
    this.durationSeconds,
    this.leftAt,
    this.message,
    this.error,
  });
  
  factory BackendLeaveResponse.fromJson(Map<String, dynamic> json) {
    return BackendLeaveResponse(
      success: json['success'] ?? false,
      sessionId: json['session_id'] ?? '',
      roomId: json['room_id'],
      userId: json['user_id'],
      durationSeconds: json['duration_seconds'],
      leftAt: json['left_at'],
      message: json['message'],
      error: json['error'],
    );
  }
}

/// Voice Room Info
class VoiceRoomInfo {
  final String roomId;
  final int participantCount;
  final int maxParticipants;
  final bool isFull;
  final String? firstJoinedAt;
  
  VoiceRoomInfo({
    required this.roomId,
    required this.participantCount,
    required this.maxParticipants,
    required this.isFull,
    this.firstJoinedAt,
  });
  
  factory VoiceRoomInfo.fromJson(Map<String, dynamic> json) {
    return VoiceRoomInfo(
      roomId: json['room_id'] ?? '',
      participantCount: json['participant_count'] ?? 0,
      maxParticipants: json['max_participants'] ?? 10,
      isFull: json['is_full'] ?? false,
      firstJoinedAt: json['first_joined_at'],
    );
  }
}

// ============================================================================
// EXCEPTIONS

// ✅ MIGRATION COMPLETE: BackendJoinException wurde ersetzt durch:
// - BackendException (allgemeine Backend-Fehler)
// - RoomFullException (Raum voll)
// - AuthException (Authentifizierungs-Fehler)
// - TimeoutException (Timeout-Fehler)
//
// Siehe: lib/core/exceptions/specialized_exceptions.dart


