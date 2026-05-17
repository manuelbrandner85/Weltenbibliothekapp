import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/energie_profile.dart';
import '../models/materie_profile.dart';

/// Profile Sync Service — Direct-Supabase Variante.
///
/// War zuvor an /api/profile/* am Cloudflare Worker gebunden. Während Worker
/// Free-Plan-Quota-Lock (HTTP 429 / Error 1027) sind alle Profile-Operationen
/// ausgefallen. Seit Worker-Bypass: läuft direkt gegen supabase-flutter, was
/// auch langfristig robuster ist (eine API-Hop weniger).
///
/// Backwards compatible: alle public Methoden behalten dieselbe Signatur und
/// Rückgabewerte, sodass die ~6 Aufrufer (profile_onboarding_screen,
/// profile_editor_screen, *_live_chat_screen) unverändert weiterlaufen.
///
/// Sicherheits-Hinweis: die alte Worker-Variante validierte Root-Admin per
/// Passwort gegen einen Server-Hash. Dieser Bypass kann das nicht — neue
/// Profile werden mit role='user' angelegt. Eine bestehende root_admin-Rolle
/// (z.B. via v71_admin_role_trigger) bleibt unberührt: wir lesen die Rolle
/// aus der DB, überschreiben sie aber nicht.
class ProfileSyncService {
  static SupabaseClient get _supa => Supabase.instance.client;

  // ════════════════════════════════════════════════════════════
  // MATERIE PROFILE
  // ════════════════════════════════════════════════════════════

  /// Save Materie Profile to Supabase.
  ///
  /// password-Parameter bleibt aus Backwards-Compat — wird hier nicht
  /// genutzt (Root-Admin-Validierung erfolgte server-seitig im Worker).
  Future<bool> saveMaterieProfile(
    MaterieProfile profile, {
    String? password,
  }) async {
    return await _saveProfile(
      username: profile.username,
      world: 'materie',
      fields: {
        'full_name': profile.name,
        'avatar_url': profile.avatarUrl,
        'avatar_emoji': profile.avatarEmoji,
        'bio': profile.bio,
      },
    );
  }

  /// Save Materie Profile + return aktualisiertes Profil mit Backend-Daten.
  Future<MaterieProfile?> saveMaterieProfileAndGetUpdated(
    MaterieProfile profile, {
    String? password,
  }) async {
    final success = await saveMaterieProfile(profile, password: password);
    if (!success) return null;
    return await getMaterieProfile(profile.username);
  }

  /// Get Materie Profile by username.
  Future<MaterieProfile?> getMaterieProfile(String username) async {
    try {
      final row = await _supa
          .from('profiles')
          .select()
          .eq('username', username)
          .eq('world', 'materie')
          .maybeSingle();
      if (row == null) return null;
      return MaterieProfile(
        username: row['username'] as String,
        userId: row['id'] as String?,
        role: row['role'] as String?,
        name: row['full_name'] as String?,
        avatarUrl: row['avatar_url'] as String?,
        avatarEmoji: row['avatar_emoji'] as String?,
        bio: row['bio'] as String?,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('❌ getMaterieProfile: $e');
      return null;
    }
  }

  /// Get all Materie Profiles.
  Future<List<MaterieProfile>> getAllMaterieProfiles() async {
    try {
      final rows = await _supa
          .from('profiles')
          .select()
          .eq('world', 'materie')
          .order('created_at', ascending: false);
      return (rows as List)
          .cast<Map<String, dynamic>>()
          .map((p) => MaterieProfile(
                username: p['username'] as String,
                userId: p['id'] as String?,
                role: p['role'] as String?,
                name: p['full_name'] as String?,
                avatarUrl: p['avatar_url'] as String?,
                avatarEmoji: p['avatar_emoji'] as String?,
                bio: p['bio'] as String?,
              ))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ getAllMaterieProfiles: $e');
      return <MaterieProfile>[];
    }
  }

  // ════════════════════════════════════════════════════════════
  // ENERGIE PROFILE
  // ════════════════════════════════════════════════════════════

  /// Save Energie Profile to Supabase.
  Future<bool> saveEnergieProfile(
    EnergieProfile profile, {
    String? password,
  }) async {
    return await _saveProfile(
      username: profile.username,
      world: 'energie',
      fields: {
        'full_name': '${profile.firstName} ${profile.lastName}'.trim(),
        'birth_date': profile.birthDate.toIso8601String().substring(0, 10),
        'birth_place': profile.birthPlace,
        'birth_time': profile.birthTime,
        'avatar_url': profile.avatarUrl,
        'avatar_emoji': profile.avatarEmoji,
        'bio': profile.bio,
      },
    );
  }

  /// Save Energie Profile + return aktualisiertes Profil.
  Future<EnergieProfile?> saveEnergieProfileAndGetUpdated(
    EnergieProfile profile, {
    String? password,
  }) async {
    final success = await saveEnergieProfile(profile, password: password);
    if (!success) return null;
    return await getEnergieProfile(profile.username);
  }

  /// Get Energie Profile by username.
  Future<EnergieProfile?> getEnergieProfile(String username) async {
    try {
      final row = await _supa
          .from('profiles')
          .select()
          .eq('username', username)
          .eq('world', 'energie')
          .maybeSingle();
      if (row == null) return null;
      final fullName = (row['full_name'] as String?) ?? '';
      final parts = fullName.split(' ');
      final firstName = parts.isNotEmpty ? parts.first : '';
      final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      return EnergieProfile(
        username: row['username'] as String,
        userId: row['id'] as String?,
        role: row['role'] as String?,
        firstName: firstName,
        lastName: lastName,
        birthDate: row['birth_date'] != null
            ? DateTime.parse(row['birth_date'] as String)
            : DateTime(1970),
        birthPlace: (row['birth_place'] as String?) ?? '',
        birthTime: row['birth_time'] as String?,
        avatarUrl: row['avatar_url'] as String?,
        avatarEmoji: row['avatar_emoji'] as String?,
        bio: row['bio'] as String?,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('❌ getEnergieProfile: $e');
      return null;
    }
  }

  /// Get all Energie Profiles.
  Future<List<EnergieProfile>> getAllEnergieProfiles() async {
    try {
      final rows = await _supa
          .from('profiles')
          .select()
          .eq('world', 'energie')
          .order('created_at', ascending: false);
      return (rows as List).cast<Map<String, dynamic>>().map((p) {
        final fullName = (p['full_name'] as String?) ?? '';
        final parts = fullName.split(' ');
        final firstName = parts.isNotEmpty ? parts.first : '';
        final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
        return EnergieProfile(
          username: p['username'] as String,
          firstName: firstName,
          lastName: lastName,
          birthDate: p['birth_date'] != null
              ? DateTime.parse(p['birth_date'] as String)
              : DateTime(1970),
          birthPlace: (p['birth_place'] as String?) ?? '',
          birthTime: p['birth_time'] as String?,
          avatarUrl: p['avatar_url'] as String?,
          avatarEmoji: p['avatar_emoji'] as String?,
          bio: p['bio'] as String?,
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ getAllEnergieProfiles: $e');
      return <EnergieProfile>[];
    }
  }

  // ════════════════════════════════════════════════════════════
  // INTERNAL: shared insert-or-update flow
  // ════════════════════════════════════════════════════════════

  Future<bool> _saveProfile({
    required String username,
    required String world,
    required Map<String, dynamic> fields,
  }) async {
    try {
      final existing = await _supa
          .from('profiles')
          .select('id')
          .eq('username', username)
          .eq('world', world)
          .maybeSingle();

      final updatedFields = <String, dynamic>{
        ...fields,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      if (existing != null) {
        await _supa
            .from('profiles')
            .update(updatedFields)
            .eq('id', existing['id'] as Object);
        if (kDebugMode) debugPrint('✅ $world profile updated: $username');
      } else {
        await _supa.from('profiles').insert({
          ...updatedFields,
          'username': username,
          'world': world,
          'role': 'user',
          'is_banned': false,
        });
        if (kDebugMode) debugPrint('✅ $world profile created: $username');
      }
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ _saveProfile($world): $e');
      return false;
    }
  }
}
