// ModerationQueueService — Reports + Moderation-Queue (M3).

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';

class MessageReport {
  final String id;
  final String messageId;
  final String? roomId;
  final String reporterId;
  final String? reporterName;
  final String? targetUser;
  final String reason;
  final String? notes;
  final String status; // 'open' | 'reviewed' | 'dismissed' | 'actioned'
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;
  const MessageReport({
    required this.id,
    required this.messageId,
    required this.roomId,
    required this.reporterId,
    required this.reporterName,
    required this.targetUser,
    required this.reason,
    required this.notes,
    required this.status,
    required this.reviewedBy,
    required this.reviewedAt,
    required this.createdAt,
  });

  factory MessageReport.fromJson(Map<String, dynamic> j) => MessageReport(
        id: j['id'] as String,
        messageId: j['message_id'] as String? ?? '',
        roomId: j['room_id'] as String?,
        reporterId: j['reporter_id'] as String? ?? '',
        reporterName: j['reporter_name'] as String?,
        targetUser: j['target_user'] as String?,
        reason: j['reason'] as String? ?? 'other',
        notes: j['notes'] as String?,
        status: j['status'] as String? ?? 'open',
        reviewedBy: j['reviewed_by'] as String?,
        reviewedAt: j['reviewed_at'] != null
            ? DateTime.tryParse(j['reviewed_at'] as String)
            : null,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

class ModerationQueueService {
  ModerationQueueService._();
  static final instance = ModerationQueueService._();

  SupabaseClient get _s => Supabase.instance.client;

  Future<bool> report({
    required String messageId,
    String? roomId,
    required String reporterId,
    String? reporterName,
    String? targetUser,
    required String reason,
    String? notes,
  }) async {
    try {
      await _s.from('reported_messages').insert({
        'message_id': messageId,
        'room_id': roomId,
        'reporter_id': reporterId,
        'reporter_name': reporterName,
        'target_user': targetUser,
        'reason': reason,
        'notes': notes,
      });
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Report: $e');
      return false;
    }
  }

  Future<List<MessageReport>> queue({
    String status = 'open',
    int limit = 100,
  }) async {
    try {
      final res = await _s
          .from('reported_messages')
          .select()
          .eq('status', status)
          .order('created_at', ascending: false)
          .limit(limit);
      return (res as List)
          .map((r) => MessageReport.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Queue: $e');
      return const [];
    }
  }

  Future<bool> review({
    required String reportId,
    required String status, // 'dismissed' | 'actioned'
    required String reviewedBy,
  }) async {
    try {
      await _s.from('reported_messages').update({
        'status': status,
        'reviewed_by': reviewedBy,
        'reviewed_at': DateTime.now().toIso8601String(),
      }).eq('id', reportId);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Review: $e');
      return false;
    }
  }

  // v103 Phase 4h: Community-Post-Reports (analog zu Message-Reports).
  Future<bool> reportPost({
    required String postId,
    required String reporterId,
    String? reporterName,
    String? authorUsername,
    required String reason,
    String? notes,
  }) async {
    try {
      await _s.from('reported_posts').insert({
        'post_id': postId,
        'reporter_id': reporterId,
        'reporter_name': reporterName,
        'author_username': authorUsername,
        'reason': reason,
        'notes': notes,
      });
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Post-Report: $e');
      return false;
    }
  }

  Future<List<PostReport>> postQueue({
    String status = 'open',
    int limit = 100,
  }) async {
    try {
      final res = await _s
          .from('reported_posts')
          .select()
          .eq('status', status)
          .order('created_at', ascending: false)
          .limit(limit);
      return (res as List)
          .map((r) => PostReport.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Post-Queue: $e');
      return const [];
    }
  }

  Future<bool> reviewPost({
    required String reportId,
    required String status,
    required String reviewedBy,
  }) async {
    try {
      await _s.from('reported_posts').update({
        'status': status,
        'reviewed_by': reviewedBy,
        'reviewed_at': DateTime.now().toIso8601String(),
      }).eq('id', reportId);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Post-Review: $e');
      return false;
    }
  }
}

class PostReport {
  final String id;
  final String postId;
  final String reporterId;
  final String? reporterName;
  final String? authorUsername;
  final String reason;
  final String? notes;
  final String status;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;
  const PostReport({
    required this.id,
    required this.postId,
    required this.reporterId,
    required this.reporterName,
    required this.authorUsername,
    required this.reason,
    required this.notes,
    required this.status,
    required this.reviewedBy,
    required this.reviewedAt,
    required this.createdAt,
  });

  factory PostReport.fromJson(Map<String, dynamic> j) => PostReport(
        id: j['id'] as String,
        postId: j['post_id'] as String? ?? '',
        reporterId: j['reporter_id'] as String? ?? '',
        reporterName: j['reporter_name'] as String?,
        authorUsername: j['author_username'] as String?,
        reason: j['reason'] as String? ?? 'other',
        notes: j['notes'] as String?,
        status: j['status'] as String? ?? 'open',
        reviewedBy: j['reviewed_by'] as String?,
        reviewedAt: j['reviewed_at'] != null
            ? DateTime.tryParse(j['reviewed_at'] as String)
            : null,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}
