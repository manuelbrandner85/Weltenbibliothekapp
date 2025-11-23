import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

/// ═══════════════════════════════════════════════════════════════
/// ANALYTICS SERVICE - Weltenbibliothek
/// ═══════════════════════════════════════════════════════════════
/// Client-side analytics tracking service
/// Communicates with Cloudflare Worker analytics endpoint
/// ═══════════════════════════════════════════════════════════════

class AnalyticsService {
  static const String baseUrl =
      'https://weltenbibliothek-webrtc.brandy13062.workers.dev';
  final AuthService _authService = AuthService();

  /// Track an analytics event
  Future<bool> trackEvent({
    required String eventType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final userId =
          _authService.userId; // Fixed: use userId instead of currentUserId

      final response = await http.post(
        Uri.parse('$baseUrl/analytics/track'),
        headers: {
          'Content-Type': 'application/json',
          if (_authService.token != null)
            'Authorization': 'Bearer ${_authService.token}',
        },
        body: jsonEncode({
          'event_type': eventType,
          'user_id': userId,
          'metadata': metadata ?? {},
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (kDebugMode) {
          debugPrint('📊 Analytics: $eventType tracked');
        }
        return true;
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ Analytics tracking failed: ${response.statusCode}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Analytics error: $e');
      }
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // USER EVENTS
  // ═══════════════════════════════════════════════════════════════

  Future<void> trackUserLogin() async {
    await trackEvent(eventType: 'user_login');
  }

  Future<void> trackUserRegister() async {
    await trackEvent(eventType: 'user_register');
  }

  Future<void> trackUserLogout() async {
    await trackEvent(eventType: 'user_logout');
  }

  // ═══════════════════════════════════════════════════════════════
  // LIVESTREAM EVENTS
  // ═══════════════════════════════════════════════════════════════

  Future<void> trackStreamStarted({
    required String roomId,
    required String chatType,
  }) async {
    await trackEvent(
      eventType: 'stream_started',
      metadata: {'room_id': roomId, 'chat_type': chatType},
    );
  }

  Future<void> trackStreamEnded({
    required String roomId,
    required int durationSeconds,
    required int viewerCount,
  }) async {
    await trackEvent(
      eventType: 'stream_ended',
      metadata: {
        'room_id': roomId,
        'duration_seconds': durationSeconds,
        'viewer_count': viewerCount,
      },
    );
  }

  Future<void> trackStreamJoined({
    required String roomId,
    required String hostId,
  }) async {
    await trackEvent(
      eventType: 'stream_joined',
      metadata: {'room_id': roomId, 'host_id': hostId},
    );
  }

  Future<void> trackStreamLeft({
    required String roomId,
    required int watchTimeSeconds,
  }) async {
    await trackEvent(
      eventType: 'stream_left',
      metadata: {'room_id': roomId, 'watch_time_seconds': watchTimeSeconds},
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // CHAT EVENTS
  // ═══════════════════════════════════════════════════════════════

  Future<void> trackMessageSent({
    required String channelId,
    required String messageType,
  }) async {
    await trackEvent(
      eventType: 'message_sent',
      metadata: {'channel_id': channelId, 'message_type': messageType},
    );
  }

  Future<void> trackMessageReaction({
    required String messageId,
    required String emoji,
  }) async {
    await trackEvent(
      eventType: 'message_reaction',
      metadata: {'message_id': messageId, 'emoji': emoji},
    );
  }

  Future<void> trackDMSent({required String recipientId}) async {
    await trackEvent(
      eventType: 'dm_sent',
      metadata: {'recipient_id': recipientId},
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // EVENT MAP EVENTS
  // ═══════════════════════════════════════════════════════════════

  Future<void> trackEventViewed({
    required String eventId,
    required String eventTitle,
    required String category,
  }) async {
    await trackEvent(
      eventType: 'event_viewed',
      metadata: {
        'event_id': eventId,
        'event_title': eventTitle,
        'category': category,
      },
    );
  }

  Future<void> trackEventFavorited({
    required String eventId,
    required bool isFavorited,
  }) async {
    await trackEvent(
      eventType: 'event_favorited',
      metadata: {'event_id': eventId, 'is_favorited': isFavorited},
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // WEBRTC QUALITY EVENTS
  // ═══════════════════════════════════════════════════════════════

  Future<void> trackWebRTCConnectionSuccess({
    required String peerId,
    required double rtt,
    required double packetLoss,
  }) async {
    await trackEvent(
      eventType: 'webrtc_connection_success',
      metadata: {'peer_id': peerId, 'rtt': rtt, 'packet_loss': packetLoss},
    );
  }

  Future<void> trackWebRTCConnectionFailed({
    required String peerId,
    required String reason,
  }) async {
    await trackEvent(
      eventType: 'webrtc_connection_failed',
      metadata: {'peer_id': peerId, 'reason': reason},
    );
  }

  Future<void> trackWebRTCQualityPoor({
    required String peerId,
    required double rtt,
    required double packetLoss,
  }) async {
    await trackEvent(
      eventType: 'webrtc_quality_poor',
      metadata: {'peer_id': peerId, 'rtt': rtt, 'packet_loss': packetLoss},
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ANALYTICS RETRIEVAL
  // ═══════════════════════════════════════════════════════════════

  /// Get analytics summary (admin only)
  Future<Map<String, dynamic>?> getAnalyticsSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/analytics/summary').replace(
          queryParameters: {
            'start_date': startDate.toIso8601String(),
            'end_date': endDate.toIso8601String(),
          },
        ),
        headers: {
          if (_authService.token != null)
            'Authorization': 'Bearer ${_authService.token}',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Analytics summary error: $e');
      }
      return null;
    }
  }

  /// Get user engagement metrics
  Future<Map<String, dynamic>?> getUserEngagement({String? timeRange}) async {
    try {
      final userId = _authService.userId; // Fixed: use userId property
      if (userId == null) return null;

      final uri = Uri.parse('$baseUrl/analytics/engagement/$userId');
      final finalUri = timeRange != null
          ? uri.replace(queryParameters: {'timeRange': timeRange})
          : uri;

      final response = await http.get(
        finalUri,
        headers: {
          if (_authService.token != null)
            'Authorization': 'Bearer ${_authService.token}',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ User engagement error: $e');
      }
      return null;
    }
  }

  /// Get analytics summary with time range
  Future<Map<String, dynamic>?> getSummary({String? timeRange}) async {
    try {
      final uri = Uri.parse('$baseUrl/analytics/summary');
      final finalUri = timeRange != null
          ? uri.replace(queryParameters: {'timeRange': timeRange})
          : uri;

      final response = await http.get(
        finalUri,
        headers: {
          if (_authService.token != null)
            'Authorization': 'Bearer ${_authService.token}',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Analytics summary error: $e');
      }
      return null;
    }
  }

  /// Get WebRTC metrics with time range
  Future<Map<String, dynamic>?> getWebRTCMetrics({String? timeRange}) async {
    try {
      final uri = Uri.parse('$baseUrl/analytics/webrtc');
      final finalUri = timeRange != null
          ? uri.replace(queryParameters: {'timeRange': timeRange})
          : uri;

      final response = await http.get(
        finalUri,
        headers: {
          if (_authService.token != null)
            'Authorization': 'Bearer ${_authService.token}',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ WebRTC metrics error: $e');
      }
      return null;
    }
  }
}
