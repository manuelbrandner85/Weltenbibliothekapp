import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase-Realtime-Presence pro Raum.
///
/// Meldet den aktuellen User als „online" im Raum an und liefert eine
/// Live-Liste aller aktuell anwesenden Nutzer zurück. Nutzung:
///
/// ```dart
/// await PresenceService.instance.join(
///   roomId: 'energie-meditation',
///   userId: uid,
///   username: name,
///   avatar: '🧘',
/// );
/// // später:
/// await PresenceService.instance.leave();
/// ```
///
/// Der Service notiert sich nur EINEN aktiven Raum — beim Raumwechsel
/// wird der alte Kanal automatisch geschlossen.
class PresenceService extends ChangeNotifier {
  PresenceService._();
  static final PresenceService instance = PresenceService._();

  RealtimeChannel? _channel;
  String? _roomId;
  final List<PresenceEntry> _members = <PresenceEntry>[];

  List<PresenceEntry> get members => List.unmodifiable(_members);
  int get onlineCount => _members.length;
  String? get currentRoom => _roomId;

  Future<void> join({
    required String roomId,
    required String userId,
    required String username,
    String? avatar,
  }) async {
    if (_roomId == roomId && _channel != null) return;
    await leave();

    final client = Supabase.instance.client;
    final channel = client.channel(
      'presence-$roomId',
      opts: RealtimeChannelConfig(key: userId),
    );

    channel.onPresenceSync((_) {
      _members
        ..clear()
        ..addAll(_extract(channel.presenceState()));
      notifyListeners();
    });

    channel.subscribe((status, error) async {
      if (status == RealtimeSubscribeStatus.subscribed) {
        await channel.track(<String, dynamic>{
          'user_id': userId,
          'username': username,
          'avatar': avatar ?? '',
          'joined_at': DateTime.now().toUtc().toIso8601String(),
        });
      } else if (error != null) {
        debugPrint('[Presence] subscribe error: $error');
      }
    });

    _channel = channel;
    _roomId = roomId;
  }

  Future<void> leave() async {
    final ch = _channel;
    _channel = null;
    _roomId = null;
    _members.clear();
    notifyListeners();
    if (ch != null) {
      try {
        await ch.untrack();
      } catch (_) {}
      await Supabase.instance.client.removeChannel(ch);
    }
  }

  List<PresenceEntry> _extract(List<SinglePresenceState> states) {
    final out = <PresenceEntry>[];
    final seen = <String>{};
    for (final s in states) {
      for (final p in s.presences) {
        final payload = p.payload;
        final id = payload['user_id']?.toString() ?? '';
        if (id.isEmpty || !seen.add(id)) continue;
        out.add(PresenceEntry(
          userId: id,
          username: payload['username']?.toString() ?? 'Anonym',
          avatar: payload['avatar']?.toString() ?? '',
          joinedAt:
              DateTime.tryParse(payload['joined_at']?.toString() ?? '') ??
                  DateTime.now().toUtc(),
        ));
      }
    }
    return out;
  }
}

class PresenceEntry {
  const PresenceEntry({
    required this.userId,
    required this.username,
    required this.avatar,
    required this.joinedAt,
  });

  final String userId;
  final String username;
  final String avatar;
  final DateTime joinedAt;
}
