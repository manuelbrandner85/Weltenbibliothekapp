import '../config/api_config.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import '../models/materie_profile.dart';
import '../models/energie_profile.dart';
import '../core/network/http_helper.dart';
import '../core/storage/unified_storage_service.dart';

/// Cloudflare Profile Service
/// Synchronisiert Profile-Daten mit Cloudflare D1 Backend
///
/// ✅ PUBLIC ENDPOINTS (Keine Auth-Headers erforderlich):
/// - POST /api/profile/materie - Profil erstellen/aktualisieren
/// - POST /api/profile/energie - Profil erstellen/aktualisieren
/// - GET /api/profile/:world/:username - Profil abrufen
///
/// 🔐 PROTECTED ENDPOINTS (Auth-Headers erforderlich):
/// - Siehe WorldAdminService für Admin-Endpoints
///
/// ⚠️  WICHTIG: Profile Sync ist absichtlich public, da:
/// - Jeder User muss sein erstes Profil erstellen können
/// - Root-Admin Passwort wird backend-seitig validiert
/// - Admin Endpoints sind separat geschützt (WorldAdminService)
///
/// 🆕 NEUE METHODEN (FIX 2):
/// - saveMaterieProfileAndGetUpdated() - Save + Get in einem (mit Backend-Rollen)
/// - saveEnergieProfileAndGetUpdated() - Save + Get in einem (mit Backend-Rollen)
class ProfileSyncService {
  // Cloudflare Worker URL (v2 - World-Based Multi-Profile System)
  static const String _baseUrl = ApiConfig.workerUrl;

  // ════════════════════════════════════════════════════════════
  // MATERIE PROFILE
  // ════════════════════════════════════════════════════════════

  /// Save Materie Profile to Cloud
  ///
  /// ✅ FAIL-SAFE: Optional password parameter for Root Admin validation
  /// - password: Optional, only required for username "Weltenbibliothek"
  /// - Rückwärtskompatibel: Bestehende Aufrufe funktionieren weiter
  Future<bool> saveMaterieProfile(MaterieProfile profile,
      {String? password} // ✅ NEU: Optional Root-Admin Passwort
      ) async {
    try {
      final url = Uri.parse('$_baseUrl/api/profile/materie');

      // v5.44.3: legacy_user_id mitschicken damit Worker InvisibleAuth-IDs
      // in profiles.legacy_user_id schreiben kann (siehe Migration v91).
      final invisibleId = await UnifiedStorageService().getCurrentUserId();

      // ✅ Build request body (additiv)
      // v118: 'display_name' (echte profiles-Spalte) statt 'name' -- 'name'
      // existiert in profiles NICHT und liess den INSERT mit 42703 scheitern,
      // wodurch Materie-Profile nie persistierten.
      final body = <String, dynamic>{
        'username': profile.username,
        'display_name': profile.name,
        'avatar_url': profile.avatarUrl,
        'avatar_emoji': profile.avatarEmoji,
        'bio': profile.bio,
        if (invisibleId != null && invisibleId.isNotEmpty)
          'userId': invisibleId,
      };

      // ✅ NEU: Passwort nur hinzufügen wenn vorhanden
      if (password != null && password.isNotEmpty) {
        body['password'] = password;
        if (kDebugMode) {
          debugPrint('🔐 Root-Admin Passwort wird gesendet');
        }
      }

      return await HttpHelper.post<bool>(
        uri: url,
        headers: {'Content-Type': 'application/json'},
        body: body,
        parseResponse: (responseBody) {
          final data = jsonDecode(responseBody) as Map<String, dynamic>;

          if (kDebugMode) {
            debugPrint('✅ Materie-Profil gespeichert: ${profile.username}');
            if (data['userId'] != null) {
              debugPrint('   User ID: ${data['userId']}');
            }
            if (data['role'] != null) {
              debugPrint('   Rolle: ${data['role']}');
            }
            if (data['isAdmin'] == true) {
              debugPrint('   ⭐ Admin-Status erkannt');
            }
            if (data['isRootAdmin'] == true) {
              debugPrint('   👑 Root-Admin-Status erkannt');
            }
          }
          return true;
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Netzwerk-Fehler beim Speichern: $e');
      }
      return false;
    }
  }

  /// Save Materie Profile to Cloud und return aktualisiertes Profil mit Backend-Daten
  ///
  /// ✅ NEUE METHODE (FIX 2): Kombiniert Save + Get für kompletten Flow
  /// Returns: Updated MaterieProfile mit userId und role vom Backend
  Future<MaterieProfile?> saveMaterieProfileAndGetUpdated(
      MaterieProfile profile,
      {String? password}) async {
    // 1. Speichern
    final success = await saveMaterieProfile(profile, password: password);

    if (!success) {
      return null;
    }

    // 2. Aktualisiertes Profil vom Backend holen
    final updatedProfile = await getMaterieProfile(profile.username);

    return updatedProfile;
  }

  /// Get Materie Profile from Cloud
  Future<MaterieProfile?> getMaterieProfile(String username) async {
    try {
      final url = Uri.parse('$_baseUrl/api/profile/materie/$username');

      return await HttpHelper.get<MaterieProfile?>(
        uri: url,
        headers: {},
        parseResponse: (body) {
          // v118: Der Worker proxied roh zu Supabase -> Antwort ist ein ARRAY
          // [{...}] (nicht {success, profile}). Beide Formen tolerieren.
          final decoded = jsonDecode(body);
          Map<String, dynamic>? profileData;
          if (decoded is List && decoded.isNotEmpty) {
            profileData = decoded.first as Map<String, dynamic>;
          } else if (decoded is Map && decoded['profile'] != null) {
            profileData = decoded['profile'] as Map<String, dynamic>;
          } else if (decoded is Map && decoded['username'] != null) {
            profileData = decoded.cast<String, dynamic>();
          }
          if (profileData == null) return null;

          return MaterieProfile(
            username: profileData['username'] as String,
            // Backend userId: profiles.id (UUID).
            userId: (profileData['id'] ?? profileData['user_id']) as String?,
            role: profileData['role'] as String?,
            // Spalte heisst display_name (frueher faelschlich 'name').
            name: (profileData['display_name'] ?? profileData['name'])
                as String?,
            avatarUrl: profileData['avatar_url'] as String?,
            avatarEmoji: profileData['avatar_emoji'] as String?,
            bio: profileData['bio'] as String?,
          );
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Laden: $e');
      }
      return null;
    }
  }

  /// Get All Materie Profiles
  Future<List<MaterieProfile>> getAllMaterieProfiles() async {
    try {
      final url = Uri.parse('$_baseUrl/api/profiles/materie');

      return await HttpHelper.get<List<MaterieProfile>>(
        uri: url,
        headers: {},
        parseResponse: (body) {
          final data = jsonDecode(body);
          if (data['success'] == true && data['profiles'] != null) {
            final profilesList = data['profiles'] as List<dynamic>;

            return profilesList
                .map((p) => MaterieProfile(
                      username: p['username'] as String,
                      name: p['name'] as String?,
                      avatarUrl: p['avatar_url'] as String?,
                      avatarEmoji: p['avatar_emoji'] as String?,
                      bio: p['bio'] as String?,
                    ))
                .toList();
          }
          return [];
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Laden aller Profile: $e');
      }
      return [];
    }
  }

  // ════════════════════════════════════════════════════════════
  // ENERGIE PROFILE
  // ════════════════════════════════════════════════════════════

  /// Save Energie Profile to Cloud
  ///
  /// ✅ FAIL-SAFE: Optional password parameter for Root Admin validation
  /// - password: Optional, only required for username "Weltenbibliothek"
  /// - Rückwärtskompatibel: Bestehende Aufrufe funktionieren weiter
  Future<bool> saveEnergieProfile(EnergieProfile profile,
      {String? password} // ✅ NEU: Optional Root-Admin Passwort
      ) async {
    try {
      final url = Uri.parse('$_baseUrl/api/profile/energie');

      // v5.44.3: legacy_user_id mitschicken (siehe Materie)
      final invisibleId = await UnifiedStorageService().getCurrentUserId();

      // ✅ Build request body - SNAKE_CASE matching profiles-Spalten
      // (vorher camelCase: firstName/birthDate/birthPlace wurden silent
      // gedropt von Supabase REST weil Spalten anders heissen!)
      final birthDateOnly = '${profile.birthDate.year}-'
          '${profile.birthDate.month.toString().padLeft(2, '0')}-'
          '${profile.birthDate.day.toString().padLeft(2, '0')}';
      final fullName = '${profile.firstName} ${profile.lastName}'.trim();
      final body = <String, dynamic>{
        'username': profile.username,
        'full_name': fullName.isEmpty ? null : fullName,
        'birth_date': birthDateOnly,
        'birth_place': profile.birthPlace.isEmpty ? null : profile.birthPlace,
        if (profile.birthTime != null && profile.birthTime!.isNotEmpty)
          'birth_time': profile.birthTime!.length == 5
              ? '${profile.birthTime}:00' // HH:mm -> HH:mm:ss
              : profile.birthTime,
        'avatar_url': profile.avatarUrl,
        'avatar_emoji': profile.avatarEmoji,
        'bio': profile.bio,
        // ✨ v93 Spirit-Tools-Extras
        if (profile.birthLatitude != null)
          'birth_latitude': profile.birthLatitude,
        if (profile.birthLongitude != null)
          'birth_longitude': profile.birthLongitude,
        if (profile.timezoneOffsetHours != null)
          'timezone_offset_hours': profile.timezoneOffsetHours,
        'birth_time_unknown': profile.birthTimeUnknown,
        if (profile.gender != null) 'gender': profile.gender,
        if (invisibleId != null && invisibleId.isNotEmpty)
          'userId': invisibleId,
      };

      // ✅ NEU: Passwort nur hinzufügen wenn vorhanden
      if (password != null && password.isNotEmpty) {
        body['password'] = password;
        if (kDebugMode) {
          debugPrint('🔐 Root-Admin Passwort wird gesendet');
        }
      }

      return await HttpHelper.post<bool>(
        uri: url,
        headers: {'Content-Type': 'application/json'},
        body: body,
        parseResponse: (responseBody) {
          final data = jsonDecode(responseBody) as Map<String, dynamic>;

          if (kDebugMode) {
            debugPrint('✅ Energie-Profil gespeichert: ${profile.username}');
            if (data['userId'] != null) {
              debugPrint('   User ID: ${data['userId']}');
            }
            if (data['role'] != null) {
              debugPrint('   Rolle: ${data['role']}');
            }
            if (data['isAdmin'] == true) {
              debugPrint('   ⭐ Admin-Status erkannt');
            }
            if (data['isRootAdmin'] == true) {
              debugPrint('   👑 Root-Admin-Status erkannt');
            }
          }
          return true;
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Netzwerk-Fehler beim Speichern: $e');
      }
      return false;
    }
  }

  /// Save Energie Profile to Cloud und return aktualisiertes Profil mit Backend-Daten
  ///
  /// ✅ NEUE METHODE (FIX 2): Kombiniert Save + Get für kompletten Flow
  /// Returns: Updated EnergieProfile mit userId und role vom Backend
  Future<EnergieProfile?> saveEnergieProfileAndGetUpdated(
      EnergieProfile profile,
      {String? password}) async {
    // 1. Speichern
    final success = await saveEnergieProfile(profile, password: password);

    if (!success) {
      return null;
    }

    // 2. Aktualisiertes Profil vom Backend holen
    final updatedProfile = await getEnergieProfile(profile.username);

    return updatedProfile;
  }

  /// Get Energie Profile from Cloud
  Future<EnergieProfile?> getEnergieProfile(String username) async {
    try {
      final url = Uri.parse('$_baseUrl/api/profile/energie/$username');

      return await HttpHelper.get<EnergieProfile?>(
        uri: url,
        headers: {},
        parseResponse: (body) {
          // v118: Worker proxied roh zu Supabase -> Antwort ist ein ARRAY.
          final decoded = jsonDecode(body);
          Map<String, dynamic>? p;
          if (decoded is List && decoded.isNotEmpty) {
            p = decoded.first as Map<String, dynamic>;
          } else if (decoded is Map && decoded['profile'] != null) {
            p = (decoded['profile'] as Map).cast<String, dynamic>();
          } else if (decoded is Map && decoded['username'] != null) {
            p = decoded.cast<String, dynamic>();
          }
          if (p != null) {
            // v93: full_name aufsplitten in first/last (Convention: erstes Wort = first)
            final fullName = (p['full_name'] as String?) ?? '';
            final nameParts = fullName.split(' ');
            final firstName = (p['first_name'] as String?) ??
                (nameParts.isNotEmpty ? nameParts.first : '');
            final lastName = (p['last_name'] as String?) ??
                (nameParts.length > 1 ? nameParts.skip(1).join(' ') : '');
            return EnergieProfile(
              username: p['username'] as String,
              userId: (p['user_id'] ?? p['id']) as String?,
              role: p['role'] as String?,
              firstName: firstName,
              lastName: lastName,
              birthDate: p['birth_date'] != null
                  ? DateTime.parse(p['birth_date'] as String)
                  : DateTime.now(),
              birthPlace: (p['birth_place'] as String?) ?? '',
              birthTime: p['birth_time'] as String?,
              avatarUrl: p['avatar_url'] as String?,
              avatarEmoji: p['avatar_emoji'] as String?,
              bio: p['bio'] as String?,
              // ✨ v93 Spirit-Tools-Extras
              birthLatitude: (p['birth_latitude'] as num?)?.toDouble(),
              birthLongitude: (p['birth_longitude'] as num?)?.toDouble(),
              timezoneOffsetHours:
                  (p['timezone_offset_hours'] as num?)?.toDouble(),
              birthTimeUnknown: p['birth_time_unknown'] == true,
              gender: p['gender'] as String?,
            );
          }
          return null;
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Laden: $e');
      }
      return null;
    }
  }

  /// Get All Energie Profiles
  Future<List<EnergieProfile>> getAllEnergieProfiles() async {
    try {
      final url = Uri.parse('$_baseUrl/api/profiles/energie');

      return await HttpHelper.get<List<EnergieProfile>>(
        uri: url,
        headers: {},
        parseResponse: (body) {
          final data = jsonDecode(body);
          if (data['success'] == true && data['profiles'] != null) {
            final profilesList = data['profiles'] as List<dynamic>;

            return profilesList.map((p) {
              final fullName = (p['full_name'] as String?) ?? '';
              final nameParts = fullName.split(' ');
              return EnergieProfile(
                username: p['username'] as String,
                firstName: (p['first_name'] as String?) ??
                    (nameParts.isNotEmpty ? nameParts.first : ''),
                lastName: (p['last_name'] as String?) ??
                    (nameParts.length > 1 ? nameParts.skip(1).join(' ') : ''),
                birthDate: p['birth_date'] != null
                    ? DateTime.parse(p['birth_date'] as String)
                    : DateTime.now(),
                birthPlace: (p['birth_place'] as String?) ?? '',
                birthTime: p['birth_time'] as String?,
                avatarUrl: p['avatar_url'] as String?,
                avatarEmoji: p['avatar_emoji'] as String?,
                bio: p['bio'] as String?,
              );
            }).toList();
          }
          return [];
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Laden aller Profile: $e');
      }
      return [];
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// SUPABASE-DIRECT PROFILE SYNC (v99)
// ═══════════════════════════════════════════════════════════════════════
// Direkter Push lokaler Profile in die Supabase profiles-Tabelle via
// RPC ensure_legacy_profile (InvisibleAuth) bzw. Auth-Upsert.
//
// Wird vom StorageService nach jedem saveMaterie/EnergieProfile als
// unawaited Best-Effort aufgerufen. Fehler werden geloggt, nicht
// propagiert -- der lokale Save bleibt die Source of Truth.

class SupabaseProfileSync {
  SupabaseProfileSync._();
  static final instance = SupabaseProfileSync._();

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
      // v103 Ghost-User-Fix: Wenn legacyId aus dem Profil-Objekt null ist
      // (Altnutzer ohne userId-Feld), holen wir die InvisibleAuth-ID aus
      // SharedPreferences als Fallback. Damit kommen ALLE Altnutzer in die
      // profiles-Tabelle, sobald sie irgendwas im Profil-Editor speichern
      // oder die einmalige Migration laeuft.
      String? effectiveLegacyId = legacyId;
      if (effectiveLegacyId == null || effectiveLegacyId.isEmpty) {
        try {
          final prefs = await SharedPreferences.getInstance();
          effectiveLegacyId = prefs.getString('auth_user_id');
          if (kDebugMode && effectiveLegacyId != null) {
            debugPrint(
                '🔄 SupabaseProfileSync: Fallback auf InvisibleAuth-ID: $effectiveLegacyId');
          }
        } catch (_) {}
      }
      if (effectiveLegacyId == null || effectiveLegacyId.isEmpty) return false;
      await supa.rpc('ensure_legacy_profile', params: {
        'p_legacy_id': effectiveLegacyId,
        'p_username': username,
        'p_display_name': displayName,
        'p_avatar_emoji': avatarEmoji,
        'p_avatar_url': avatarUrl,
      });
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('SupabaseProfileSync: $e');
      return false;
    }
  }
}
