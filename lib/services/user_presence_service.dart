// UserPresenceService — Heartbeat für Online-Status im Admin-Dashboard.
//
// Tickt alle 90 Sekunden während die App im Foreground ist und
// aktualisiert last_seen_at.
//
// v99: Erstellt KEIN Profil mehr automatisch. Wenn der User noch kein
// Profil ausgefuellt hat, ist der Heartbeat ein no-op. Profil-Anlage
// erfolgt nur ueber ProfileSyncService -- ausgeloest beim aktiven
// Speichern eines Materie/Energie/Vorhang/Ursprung-Profils.

import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'storage_service.dart';

class UserPresenceService {
  UserPresenceService._();
  static final instance = UserPresenceService._();

  static const _heartbeatInterval = Duration(seconds: 90);
  Timer? _timer;

  /// Startet den Heartbeat. Idempotent.
  void start() {
    if (_timer != null && _timer!.isActive) return;
    _tick();
    _timer = Timer.periodic(_heartbeatInterval, (_) => _tick());
  }

  /// Stoppt den Heartbeat und macht einen letzten Tick.
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
      if (username.isEmpty) return; // Kein Profil -> nichts zu tun.

      final supa = Supabase.instance.client;

      // Auth-User: per Session-ID -- RLS erlaubt das eigene Update.
      final auth = supa.auth.currentUser;
      if (auth != null) {
        await supa.rpc('touch_auth_presence');
        return;
      }

      // InvisibleAuth-User: touch_legacy_presence aktualisiert nur
      // last_seen_at, legt aber kein neues Profil an. Wenn der User
      // sein Profil noch nicht gespeichert hat, passiert nichts.
      final legacyId = (m?.userId ?? e?.userId ?? '').trim();
      if (legacyId.isEmpty) return;
      await supa.rpc('touch_legacy_presence', params: {
        'p_legacy_id': legacyId,
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Presence heartbeat: $e');
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
