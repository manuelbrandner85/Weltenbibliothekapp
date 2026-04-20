import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Serverseitige „Gelesen bis"-Marker pro User+Raum.
///
/// Flow:
/// 1. Client ruft [markRead] auf, wenn er den Raum öffnet oder bis ans
///    unteren Ende gescrollt ist → upsert gegen `chat_read_receipts`.
/// 2. Client abonniert [watchRoom] und bekommt live alle Receipts für
///    den aktuellen Raum gestreamt.
/// 3. [readersCountAtOrAfter] zählt, wie viele andere User eine eigene
///    Nachricht gelesen haben („✓✓ N").
///
/// Der Service hält pro aktivem Raum ein Snapshot `{userId: timestamp}`
/// im Speicher und notifiziert Listener (ChangeNotifier), wenn sich
/// etwas ändert.
class ReadReceiptService extends ChangeNotifier {
  ReadReceiptService._();
  static final ReadReceiptService instance = ReadReceiptService._();

  RealtimeChannel? _channel;
  String? _roomId;
  final Map<String, DateTime> _byUser = <String, DateTime>{};

  SupabaseClient get _client => Supabase.instance.client;

  /// Snapshot: wann hat [userId] den aktuellen Raum zuletzt gelesen?
  DateTime? lastReadFor(String userId) => _byUser[userId];

  /// Wie viele andere User haben bereits bis [messageCreatedAt] gelesen
  /// (also der eigene User wird ausgeschlossen)?
  int readersCountAtOrAfter({
    required DateTime messageCreatedAt,
    required String ownUserId,
  }) {
    var n = 0;
    _byUser.forEach((uid, ts) {
      if (uid == ownUserId) return;
      if (!ts.isBefore(messageCreatedAt)) n++;
    });
    return n;
  }

  /// Setzt einen neuen Timestamp für [userId] in der internen Map.
  /// Intern verwendet; nach außen nur via Realtime aufgerufen.
  void _apply(String userId, DateTime ts) {
    final prev = _byUser[userId];
    if (prev == null || prev.isBefore(ts)) {
      _byUser[userId] = ts;
      notifyListeners();
    }
  }

  /// Aktiven Raum wechseln. Lädt den initialen Snapshot, abonniert
  /// Realtime-Inserts/Updates.
  Future<void> watchRoom(String roomId) async {
    if (_roomId == roomId && _channel != null) return;
    await _disposeChannel();
    _roomId = roomId;

    // Initial-Snapshot
    try {
      final rows = await _client
          .from('chat_read_receipts')
          .select('user_id,last_read_at')
          .eq('room_id', roomId);
      _byUser.clear();
      for (final r in List<Map<String, dynamic>>.from(rows)) {
        final uid = r['user_id']?.toString();
        final ts = DateTime.tryParse(r['last_read_at']?.toString() ?? '');
        if (uid != null && ts != null) _byUser[uid] = ts;
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('[ReadReceipt] initial load error: $e');
    }

    // Realtime-Stream
    final ch = _client.channel('chat_read_receipts_$roomId');
    ch.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'chat_read_receipts',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'room_id',
        value: roomId,
      ),
      callback: (payload) {
        final rec = payload.newRecord;
        final uid = rec['user_id']?.toString();
        final ts = DateTime.tryParse(rec['last_read_at']?.toString() ?? '');
        if (uid != null && ts != null) _apply(uid, ts);
      },
    );
    ch.subscribe();
    _channel = ch;
  }

  /// Client-Upsert: eigener User hat bis jetzt [ts] gelesen.
  /// Braucht eine eingeloggte Supabase-Session (RLS: auth.uid() = user_id).
  Future<void> markRead({
    required String roomId,
    required String userId,
    DateTime? at,
  }) async {
    final ts = (at ?? DateTime.now().toUtc()).toUtc();
    // Lokal sofort reflektieren, damit eigene UI nicht auf Roundtrip wartet.
    _apply(userId, ts);
    try {
      await _client.from('chat_read_receipts').upsert(
        <String, dynamic>{
          'user_id': userId,
          'room_id': roomId,
          'last_read_at': ts.toIso8601String(),
        },
        onConflict: 'user_id,room_id',
      );
    } catch (e) {
      // Kein Session / Netzwerkfehler → no-op, nächste Auto-Markierung
      // versucht es erneut. Wir loggen nur in Debug.
      if (kDebugMode) debugPrint('[ReadReceipt] upsert failed: $e');
    }
  }

  Future<void> _disposeChannel() async {
    final ch = _channel;
    _channel = null;
    if (ch != null) {
      try {
        await _client.removeChannel(ch);
      } catch (_) {}
    }
  }

  Future<void> leave() async {
    await _disposeChannel();
    _roomId = null;
    _byUser.clear();
    notifyListeners();
  }
}
