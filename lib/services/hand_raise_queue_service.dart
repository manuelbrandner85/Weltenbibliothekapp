// HandRaiseQueueService — Reihenfolge der Hand-Hebungen pro LiveKit-Room (E4).
//
// raise()  → Eintrag in queue (raised_at = now).
// clear()  → cleared_at setzen (Moderator hat verarbeitet).
// list()   → offene Queue (cleared_at IS NULL), sortiert nach raised_at.

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';

class HandRaiseEntry {
  final String id;
  final String roomName;
  final String identity;
  final String? username;
  final DateTime raisedAt;
  const HandRaiseEntry({
    required this.id,
    required this.roomName,
    required this.identity,
    required this.username,
    required this.raisedAt,
  });

  factory HandRaiseEntry.fromJson(Map<String, dynamic> j) => HandRaiseEntry(
        id: j['id'] as String,
        roomName: j['room_name'] as String? ?? '',
        identity: j['identity'] as String? ?? '',
        username: j['username'] as String?,
        raisedAt: DateTime.tryParse(j['raised_at'] as String? ?? '') ?? DateTime.now(),
      );
}

class HandRaiseQueueService {
  HandRaiseQueueService._();
  static final instance = HandRaiseQueueService._();

  SupabaseClient get _s => Supabase.instance.client;

  Future<bool> raise({
    required String roomName,
    required String identity,
    String? username,
  }) async {
    try {
      await _s.from('hand_raise_queue').insert({
        'room_name': roomName,
        'identity': identity,
        'username': username,
      });
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ HandRaise raise: $e');
      return false;
    }
  }

  Future<bool> clear(String entryId) async {
    try {
      await _s
          .from('hand_raise_queue')
          .update({'cleared_at': DateTime.now().toIso8601String()})
          .eq('id', entryId);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ HandRaise clear: $e');
      return false;
    }
  }

  Future<List<HandRaiseEntry>> open(String roomName) async {
    try {
      final res = await _s
          .from('hand_raise_queue')
          .select()
          .eq('room_name', roomName)
          .isFilter('cleared_at', null)
          .order('raised_at', ascending: true);
      return (res as List)
          .map((r) => HandRaiseEntry.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ HandRaise open: $e');
      return const [];
    }
  }

  RealtimeChannel subscribe(
    String roomName, {
    required void Function() onChange,
  }) {
    return _s
        .channel('hand-raise-$roomName-${DateTime.now().millisecondsSinceEpoch}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'hand_raise_queue',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_name',
            value: roomName,
          ),
          callback: (_) => onChange(),
        )
        .subscribe();
  }
}
