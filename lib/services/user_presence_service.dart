// UserPresenceService — Heartbeat für Online-Status im Admin-Dashboard.
//
// Tickt alle 90 Sekunden während die App im Foreground ist und schreibt
// last_seen_at auf das eigene profile. Im Background (pausiert) stoppt
// der Timer; ein letzter Tick beim Pausieren markiert "gerade weg".
//
// v98: nutzt ensure_legacy_profile RPC um Profile fuer InvisibleAuth-User
// automatisch anzulegen falls fehlt -- so erscheinen sie sicher im
// Admin-Dashboard, sobald sie die App das erste Mal oeffnen.

import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'storage_service.dart';

class UserPresenceService {
  UserPresenceService._();
  static final instance = UserPresenceService._();

  static const _heartbeatInterval = Duration(seconds: 90);
  Timer? _timer;

  /// Startet den Heartbeat. Idempotent — mehrfacher Aufruf macht nichts.
  void start() {
    if (_timer != null && _timer!.isActive) return;
    _tick();
    _timer = Timer.periodic(_heartbeatInterval, (_) => _tick());
  }

  /// Stoppt den Heartbeat. Setzt last_seen einmal noch (User ist gerade
  /// gegangen). Aufrufen z.B. wenn App in den Background geht.
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    await _tick();
  }

  Future<void> _tick() async {
    try {
      final storage = StorageService();
      final m = storage.getMaterieProfile();
      final e = storage.getEnergieProfile();
      final username = (m?.username ?? e?.username ?? '').trim();
      if (username.isEmpty) return;

      final displayName =
          (m?.displayName ?? e?.displayName ?? username).trim();
      final now = DateTime.now().toUtc().toIso8601String();

      final supa = Supabase.instance.client;

      // Wenn Supabase Session da ist: per ID updaten (genauer).
      final auth = supa.auth.currentUser;
      if (auth != null) {
        await supa.from('profiles')
            .update({'last_seen_at': now})
            .eq('id', auth.id);
        return;
      }

      // InvisibleAuth: ensure_legacy_profile RPC legt Profil an falls
      // fehlt und aktualisiert last_seen_at atomar (v98).
      final legacyId = (m?.userId ?? e?.userId ?? '').trim();
      if (legacyId.isNotEmpty) {
        try {
          await supa.rpc('ensure_legacy_profile', params: {
            'p_legacy_id': legacyId,
            'p_username': username,
            'p_display_name': displayName,
          });
          return;
        } catch (rpcErr) {
          if (kDebugMode) {
            debugPrint(
                '⚠️ ensure_legacy_profile RPC fail, fallback: $rpcErr');
          }
        }
      }

      // Fallback (ohne RPC verfuegbar): per username.
      await supa.from('profiles')
          .update({'last_seen_at': now})
          .ilike('username', username);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Presence heartbeat: $e');
    }
  }
}

/// Status-Klassifikation für UI.
enum OnlineStatus { online, recent, offline, never }

OnlineStatus classifyPresence(DateTime? lastSeen, {DateTime? now}) {
  if (lastSeen == null) return OnlineStatus.never;
  final n = now ?? DateTime.now().toUtc();
  final delta = n.difference(lastSeen.toUtc());
  if (delta.inMinutes < 2) return OnlineStatus.online;
  if (delta.inMinutes < 15) return OnlineStatus.recent;
  return OnlineStatus.offline;
}
