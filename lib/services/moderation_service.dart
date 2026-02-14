import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import '../core/network/http_helper.dart';

/// Moderation Service für Admin Content Moderation
/// 
/// Features:
/// - Content flaggen (inappropriate)
/// - User muten (24h / permanent)
/// - Moderation Log abrufen
/// - Flagged Content verwalten
class ModerationService {
  static const String _baseUrl = 'https://weltenbibliothek-api-v2.brandy13062.workers.dev';
  
  // ═══════════════════════════════════════════════════════════════
  // FLAG CONTENT
  // ═══════════════════════════════════════════════════════════════
  
  /// Flag Content als inappropriate
  /// 
  /// [world] - 'materie' oder 'energie'
  /// [contentType] - 'post' oder 'comment'
  /// [contentId] - ID des Contents
  /// [reason] - Grund für die Meldung
  Future<Map<String, dynamic>> flagContent({
    required String world,
    required String contentType,
    required String contentId,
    String? contentAuthorId,
    String? contentAuthorUsername,
    required String reason,
    required String adminToken,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/api/moderation/flag-content');
      
      return await HttpHelper.post<Map<String, dynamic>>(
        uri: url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
        body: {
          'world': world,
          'content_type': contentType,
          'content_id': contentId,
          'content_author_id': contentAuthorId,
          'content_author_username': contentAuthorUsername,
          'reason': reason,
        },
        parseResponse: (body) {
          final data = jsonDecode(body) as Map<String, dynamic>;
          if (data['success'] == true) {
            if (kDebugMode) {
              debugPrint('✅ Content flagged: $contentType $contentId');
              debugPrint('   Flag ID: ${data['flag_id']}');
            }
            return {'success': true, 'flag_id': data['flag_id']};
          } else {
            throw Exception(data['error'] ?? 'Unknown error');
          }
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Network error flagging content: $e');
      }
      return {'success': false, 'error': 'Network error: $e'};
    }
  }
  
  // ═══════════════════════════════════════════════════════════════
  // GET FLAGGED CONTENT
  // ═══════════════════════════════════════════════════════════════
  
  /// Hole gemeldete Inhalte
  /// 
  /// [world] - 'materie' oder 'energie'
  /// [status] - 'pending', 'resolved', oder 'dismissed'
  Future<Map<String, dynamic>> getFlaggedContent({
    required String world,
    String status = 'pending',
    required String adminToken,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/api/moderation/flagged-content/$world?status=$status');
      
      return await HttpHelper.get<Map<String, dynamic>>(
        uri: url,
        headers: {
          'Authorization': 'Bearer $adminToken',
        },
        parseResponse: (body) {
          final data = jsonDecode(body) as Map<String, dynamic>;
          if (data['success'] == true) {
            if (kDebugMode) {
              debugPrint('✅ Loaded flagged content: ${data['count']} items');
            }
            return {
              'success': true,
              'flagged_content': data['flagged_content'] as List<dynamic>,
              'count': data['count'],
            };
          } else {
            throw Exception(data['error'] ?? 'Unknown error');
          }
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Network error loading flagged content: $e');
      }
      return {'success': false, 'error': 'Network error: $e'};
    }
  }
  
  // ═══════════════════════════════════════════════════════════════
  // RESOLVE / DISMISS FLAG
  // ═══════════════════════════════════════════════════════════════
  
  /// Resolve Flag (Root Admin only)
  Future<Map<String, dynamic>> resolveFlag({
    required int flagId,
    required String world,
    required String resolutionAction,
    String? resolutionNotes,
    required String adminToken,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/api/moderation/resolve-flag');
      
      return await HttpHelper.post<Map<String, dynamic>>(
        uri: url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
        body: {
          'flag_id': flagId,
          'world': world,
          'resolution_action': resolutionAction,
          'resolution_notes': resolutionNotes,
        },
        parseResponse: (body) {
          final data = jsonDecode(body) as Map<String, dynamic>;
          if (data['success'] == true) {
            if (kDebugMode) {
              debugPrint('✅ Flag resolved: $flagId → $resolutionAction');
            }
            return {'success': true};
          } else {
            throw Exception(data['error'] ?? 'Unknown error');
          }
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Network error resolving flag: $e');
      }
      return {'success': false, 'error': 'Network error: $e'};
    }
  }
  
  /// Dismiss Flag (Root Admin only)
  Future<Map<String, dynamic>> dismissFlag({
    required int flagId,
    required String world,
    String? notes,
    required String adminToken,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/api/moderation/dismiss-flag');
      
      return await HttpHelper.post<Map<String, dynamic>>(
        uri: url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
        body: {
          'flag_id': flagId,
          'world': world,
          'notes': notes,
        },
        parseResponse: (body) {
          final data = jsonDecode(body) as Map<String, dynamic>;
          if (data['success'] == true) {
            if (kDebugMode) {
              debugPrint('✅ Flag dismissed: $flagId');
            }
            return {'success': true};
          } else {
            throw Exception(data['error'] ?? 'Unknown error');
          }
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Network error dismissing flag: $e');
      }
      return {'success': false, 'error': 'Network error: $e'};
    }
  }
  
  // ═══════════════════════════════════════════════════════════════
  // USER MUTING
  // ═══════════════════════════════════════════════════════════════
  
  /// Mute User
  /// 
  /// [muteType] - '24h' oder 'permanent'
  /// Normal-Admin: nur '24h'
  /// Root-Admin: beides
  Future<Map<String, dynamic>> muteUser({
    required String world,
    required String userId,
    required String username,
    required String muteType,
    String? reason,
    required String adminToken,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/api/moderation/mute-user');
      
      return await HttpHelper.post<Map<String, dynamic>>(
        uri: url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
        body: {
          'world': world,
          'user_id': userId,
          'username': username,
          'mute_type': muteType,
          'reason': reason,
        },
        parseResponse: (body) {
          final data = jsonDecode(body) as Map<String, dynamic>;
          if (data['success'] == true) {
            if (kDebugMode) {
              debugPrint('✅ User muted: $username ($muteType)');
              if (data['expires_at'] != null) {
                debugPrint('   Expires: ${data['expires_at']}');
              }
            }
            return {
              'success': true,
              'mute_id': data['mute_id'],
              'mute_type': data['mute_type'],
              'expires_at': data['expires_at'],
            };
          } else {
            throw Exception(data['error'] ?? 'Unknown error');
          }
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Network error muting user: $e');
      }
      return {'success': false, 'error': 'Network error: $e'};
    }
  }
  
  /// Unmute User
  Future<Map<String, dynamic>> unmuteUser({
    required String world,
    required String userId,
    required String adminToken,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/api/moderation/unmute-user');
      
      return await HttpHelper.post<Map<String, dynamic>>(
        uri: url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
        body: {
          'world': world,
          'user_id': userId,
        },
        parseResponse: (body) {
          final data = jsonDecode(body) as Map<String, dynamic>;
          if (data['success'] == true) {
            if (kDebugMode) {
              debugPrint('✅ User unmuted: $userId');
            }
            return {'success': true};
          } else {
            throw Exception(data['error'] ?? 'Unknown error');
          }
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Network error unmuting user: $e');
      }
      return {'success': false, 'error': 'Network error: $e'};
    }
  }
  
  /// Check if User is Muted (Public - kein Auth nötig)
  Future<Map<String, dynamic>> isUserMuted({
    required String world,
    required String userId,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/api/moderation/check-mute/$world/$userId');
      
      return await HttpHelper.get<Map<String, dynamic>>(
        uri: url,
        headers: {},
        parseResponse: (body) {
          final data = jsonDecode(body) as Map<String, dynamic>;
          if (data['success'] == true) {
            return {
              'success': true,
              'is_muted': data['is_muted'] as bool,
              'mute_info': data['mute_info'],
            };
          } else {
            throw Exception(data['error'] ?? 'Unknown error');
          }
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Network error checking mute status: $e');
      }
      return {'success': false, 'error': 'Network error: $e'};
    }
  }
  
  // ═══════════════════════════════════════════════════════════════
  // MODERATION LOG
  // ═══════════════════════════════════════════════════════════════
  
  /// Get Moderation Log
  /// 
  /// Root-Admin: Alle Logs
  /// Normal-Admin: Nur eigene Logs
  Future<Map<String, dynamic>> getModerationLog({
    required String world,
    int limit = 50,
    required String adminToken,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/api/moderation/log/$world?limit=$limit');
      
      return await HttpHelper.get<Map<String, dynamic>>(
        uri: url,
        headers: {
          'Authorization': 'Bearer $adminToken',
        },
        parseResponse: (body) {
          final data = jsonDecode(body) as Map<String, dynamic>;
          if (data['success'] == true) {
            if (kDebugMode) {
              debugPrint('✅ Loaded moderation log: ${data['count']} entries');
              if (data['is_filtered'] == true) {
                debugPrint('   (Filtered: Only own actions)');
              }
            }
            return {
              'success': true,
              'logs': data['logs'] as List<dynamic>,
              'count': data['count'],
              'is_filtered': data['is_filtered'],
            };
          } else {
            throw Exception(data['error'] ?? 'Unknown error');
          }
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Network error loading moderation log: $e');
      }
      return {'success': false, 'error': 'Network error: $e'};
    }
  }
}
