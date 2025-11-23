import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

/// ═══════════════════════════════════════════════════════════════
/// LIVE ROOM SERVICE - Weltenbibliothek
/// ═══════════════════════════════════════════════════════════════
/// Manages live streaming rooms with D1 backend integration
/// ═══════════════════════════════════════════════════════════════

class LiveRoom {
  final String roomId;
  final String? chatRoomId; // NEW: Chat room this stream belongs to
  final String title;
  final String description;
  final String hostUsername;
  final String status; // 'live', 'ended', 'scheduled'
  final int createdAt;
  final int? startedAt;
  final int? endedAt;
  final int participantCount;
  final int maxParticipants;
  final bool isPrivate;
  final String? category;

  LiveRoom({
    required this.roomId,
    this.chatRoomId,
    required this.title,
    required this.description,
    required this.hostUsername,
    required this.status,
    required this.createdAt,
    this.startedAt,
    this.endedAt,
    this.participantCount = 0,
    this.maxParticipants = 50,
    this.isPrivate = false,
    this.category,
  });

  factory LiveRoom.fromJson(Map<String, dynamic> json) {
    return LiveRoom(
      roomId: json['room_id'] as String,
      chatRoomId: json['chat_room_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      hostUsername: json['host_username'] as String,
      status: json['status'] as String,
      createdAt: json['created_at'] as int,
      startedAt: json['started_at'] as int?,
      endedAt: json['ended_at'] as int?,
      participantCount:
          json['participant_count'] as int? ??
          json['current_participants'] as int? ??
          0,
      maxParticipants: json['max_participants'] as int? ?? 50,
      isPrivate: (json['is_private'] as int?) == 1,
      category: json['category'] as String?,
    );
  }

  DateTime get createdAtDate =>
      DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
  DateTime? get startedAtDate => startedAt != null
      ? DateTime.fromMillisecondsSinceEpoch(startedAt! * 1000)
      : null;
  DateTime? get endedAtDate => endedAt != null
      ? DateTime.fromMillisecondsSinceEpoch(endedAt! * 1000)
      : null;

  bool get isLive => status == 'live';
  bool get hasEnded => status == 'ended';
}

class LiveRoomService {
  // 🔧 CONFIGURATION - Unified Master Worker URL
  static const String webrtcBaseUrl =
      'https://weltenbibliothek.brandy13062.workers.dev';

  final AuthService _authService = AuthService();

  // Singleton pattern
  static final LiveRoomService _instance = LiveRoomService._internal();
  factory LiveRoomService() => _instance;
  LiveRoomService._internal();

  // ═══════════════════════════════════════════════════════════════
  // GET LIVE ROOMS
  // ═══════════════════════════════════════════════════════════════

  /// Get all active live rooms
  Future<List<LiveRoom>> getActiveLiveRooms() async {
    try {
      final response = await http.get(
        Uri.parse('$webrtcBaseUrl/api/live/rooms'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final rooms = data['rooms'] as List<dynamic>;

        return rooms
            .map((room) => LiveRoom.fromJson(room as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to fetch live rooms: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching live rooms: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CREATE LIVE ROOM
  // ═══════════════════════════════════════════════════════════════

  /// Create new live room (host only, one active room per chat)
  /// 🚀 TELEGRAM-STYLE v3.8.0: Returns existing_stream if chat has active stream
  Future<Map<String, dynamic>> createLiveRoom({
    required String chatRoomId, // REQUIRED: Chat room ID for this stream
    required String title,
    String? description,
    String? category,
    bool forceCleanup = false, // DEPRECATED: No longer needed in Telegram-style
  }) async {
    try {
      // Get auth token
      final token = _authService.token;
      if (token == null) {
        throw Exception('Not authenticated');
      }

      // Use WebRTC Worker for live room creation
      final response = await http.post(
        Uri.parse('$webrtcBaseUrl/api/live/rooms'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'chatRoomId': chatRoomId, // Send chat room ID to backend
          'title': title,
          'description': description ?? '',
          'category': category ?? 'general',
        }),
      );

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 201) {
        // ✅ New stream created
        return {
          'success': true,
          'room': LiveRoom.fromJson(data['room'] as Map<String, dynamic>),
        };
      } else if (response.statusCode == 200 &&
          data['existing_stream'] == true) {
        // 🚀 TELEGRAM-STYLE: Chat already has stream → Join it!
        return {
          'success': true,
          'existing_stream': true,
          'message': data['message'] ?? 'Trete bestehendem Stream bei',
          'room': LiveRoom.fromJson(data['room'] as Map<String, dynamic>),
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Fehler beim Erstellen des Live-Raums',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // JOIN LIVE ROOM
  // ═══════════════════════════════════════════════════════════════

  /// Join an existing live room
  Future<Map<String, dynamic>> joinLiveRoom(String roomId) async {
    try {
      // Get auth token
      final token = _authService.token;
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('$webrtcBaseUrl/api/live/rooms/$roomId/join'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({}),
      );

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Joined room successfully',
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'error': 'Live-Raum nicht gefunden oder beendet',
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Fehler beim Beitreten',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // LEAVE LIVE ROOM
  // ═══════════════════════════════════════════════════════════════

  /// Leave a live room
  Future<Map<String, dynamic>> leaveLiveRoom(String roomId) async {
    try {
      // Get auth token
      final token = _authService.token;
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('$webrtcBaseUrl/api/live/rooms/$roomId/leave'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({}),
      );

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Left room successfully',
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Fehler beim Verlassen',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // END LIVE ROOM
  // ═══════════════════════════════════════════════════════════════

  /// End live room (host only)
  Future<Map<String, dynamic>> endLiveRoom(String roomId) async {
    try {
      // Get auth token
      final token = _authService.token;
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('$webrtcBaseUrl/api/live/rooms/$roomId/end'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({}),
      );

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Room ended successfully',
        };
      } else if (response.statusCode == 403) {
        return {
          'success': false,
          'error': 'Nur der Host kann den Live-Stream beenden',
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Fehler beim Beenden',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }
}
