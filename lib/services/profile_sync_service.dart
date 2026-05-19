// Profile-Sync-Service (v99).
//
// Pusht lokale Materie/Energie-Profil-Daten in die Supabase profiles-
// Tabelle, sobald der User sein Profil ausfuellt oder aendert. Nutzt die
// SECURITY-DEFINER RPC ensure_legacy_profile -- legt Profil an falls
// fehlt, sonst werden username/display_name/avatar_emoji/avatar_url
// abgeglichen.
//
// Wichtig: Der Heartbeat-Ticker (UserPresenceService) ruft diese Klasse
// NICHT mehr auf. Profil-Anlage geschieht ausschliesslich beim aktiven
// Speichern eines Profils -- so erscheinen nur User mit echtem Profil
// im Admin-Dashboard.

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/energie_profile.dart';
import '../models/materie_profile.dart';

class ProfileSyncService {
  ProfileSyncService._();
  static final instance = ProfileSyncService._();

  Future<bool> syncMaterieProfile(MaterieProfile p) async {
    return _sync(
      legacyId: p.userId,
      username: p.username,
      displayName: p.displayName,
      avatarEmoji: p.avatarEmoji,
      avatarUrl: null,
    );
  }

  Future<bool> syncEnergieProfile(EnergieProfile p) async {
    return _sync(
      legacyId: p.userId,
      username: p.username,
      displayName: p.displayName,
      avatarEmoji: null,
      avatarUrl: null,
    );
  }

  Future<bool> _sync({
    required String? legacyId,
    required String username,
    required String displayName,
    required String? avatarEmoji,
    required String? avatarUrl,
  }) async {
    if (username.trim().isEmpty) return false;
    try {
      final supa = Supabase.instance.client;
      final auth = supa.auth.currentUser;

      if (auth != null) {
        await supa.from('profiles').upsert({
          'id': auth.id,
          'username': username,
          'display_name': displayName,
          if (avatarEmoji != null && avatarEmoji.isNotEmpty)
            'avatar_emoji': avatarEmoji,
          if (avatarUrl != null && avatarUrl.isNotEmpty)
            'avatar_url': avatarUrl,
          'last_seen_at': DateTime.now().toUtc().toIso8601String(),
        }, onConflict: 'id');
        return true;
      }

      if (legacyId == null || legacyId.isEmpty) return false;
      await supa.rpc('ensure_legacy_profile', params: {
        'p_legacy_id': legacyId,
        'p_username': username,
        'p_display_name': displayName,
        'p_avatar_emoji': avatarEmoji,
        'p_avatar_url': avatarUrl,
      });
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('Profile-Sync error: $e');
      return false;
    }
  }
}
