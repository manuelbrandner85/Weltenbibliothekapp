// PinnedMessageService — Sticky-Pins pro Chat-Room (E2).

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';

class PinnedMessage {
  final String id;
  final String roomId;
  final String messageId;
  final String pinnedBy;
  final String? pinnedByRole;
  final String? preview;
  final DateTime createdAt;
  const PinnedMessage({
    required this.id,
    required this.roomId,
    required this.messageId,
    required this.pinnedBy,
    required this.pinnedByRole,
    required this.preview,
    required this.createdAt,
  });

  factory PinnedMessage.fromJson(Map<String, dynamic> j) => PinnedMessage(
        id: j['id'] as String,
        roomId: j['room_id'] as String? ?? '',
        messageId: j['message_id'] as String? ?? '',
        pinnedBy: j['pinned_by'] as String? ?? '',
        pinnedByRole: j['pinned_by_role'] as String?,
        preview: j['preview'] as String?,
        createdAt: DateTime.tryParse(j['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
}

class PinnedMessageService {
  PinnedMessageService._();
  static final instance = PinnedMessageService._();

  SupabaseClient get _s => Supabase.instance.client;

  Future<List<PinnedMessage>> listForRoom(String roomId) async {
    try {
      final res = await _s
          .from('pinned_messages')
          .select()
          .eq('room_id', roomId)
          .order('created_at', ascending: false);
      return (res as List)
          .map((r) =>
              PinnedMessage.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Pinned list: $e');
      return const [];
    }
  }

  Future<bool> pin({
    required String roomId,
    required String messageId,
    required String pinnedBy,
    String? pinnedByRole,
    String? preview,
  }) async {
    try {
      await _s.from('pinned_messages').upsert({
        'room_id': roomId,
        'message_id': messageId,
        'pinned_by': pinnedBy,
        'pinned_by_role': pinnedByRole,
        'preview':
            (preview ?? '').substring(0, (preview ?? '').length.clamp(0, 280)),
      }, onConflict: 'room_id,message_id');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Pin: $e');
      return false;
    }
  }

  Future<bool> unpin(
      {required String roomId, required String messageId}) async {
    try {
      await _s
          .from('pinned_messages')
          .delete()
          .eq('room_id', roomId)
          .eq('message_id', messageId);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Unpin: $e');
      return false;
    }
  }

  /// Realtime-Subscription für Pin-Änderungen pro Room.
  RealtimeChannel subscribe(
    String roomId, {
    required void Function() onChange,
  }) {
    return _s
        .channel('pinned-$roomId-${DateTime.now().millisecondsSinceEpoch}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'pinned_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: roomId,
          ),
          callback: (_) => onChange(),
        )
        .subscribe();
  }
}
