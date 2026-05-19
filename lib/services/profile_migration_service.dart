// Ghost-User-Migration (v103).
//
// One-time migration: sync the single local user profile to Supabase.
// Each user has exactly ONE profile for all worlds -- MaterieProfile and
// EnergieProfile are mirrored copies of the same identity. We pick
// whichever exists and push it via Worker + Direct-Supabase, then mark
// the device as migrated so we never re-run.

import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:shared_preferences/shared_preferences.dart';

import 'profile_sync_service.dart';
import 'storage_service.dart';

class ProfileMigrationService {
  static const String _migrationFlag = 'profiles_migrated_v1';

  /// Runs once per device on app start. Safe: ensure_legacy_profile is an
  /// upsert and the Worker save-Endpoint is idempotent -- repeated runs
  /// never overwrite existing rows with stale data.
  static Future<void> migrateIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_migrationFlag) == true) return;
      if (kDebugMode) {
        debugPrint('🔄 ProfileMigration: Starte Altnutzer-Sync...');
      }

      final storage = StorageService();

      // ONE profile per user -- MaterieProfile and EnergieProfile are
      // mirrored copies of the same identity. Pick whichever exists.
      final materie = storage.getMaterieProfile();
      final energie = storage.getEnergieProfile();
      final username = materie?.username ?? energie?.username;

      if (username == null || username.isEmpty) {
        await prefs.setBool(_migrationFlag, true);
        if (kDebugMode) {
          debugPrint('✅ ProfileMigration: Kein lokales Profil → Skip');
        }
        return;
      }

      // InvisibleAuth-ID as fallback when profile.userId is null
      // (legacy users where the field didn't exist yet).
      final legacyId = prefs.getString('auth_user_id');
      final profileUserId = materie?.userId ?? energie?.userId;
      final effectiveUserId =
          (profileUserId != null && profileUserId.isNotEmpty)
              ? profileUserId
              : legacyId;

      bool synced = false;

      // 1. Worker-Sync (writes via Cloudflare Worker -> Supabase).
      try {
        if (materie != null) {
          synced = await ProfileSyncService().saveMaterieProfile(materie);
        } else if (energie != null) {
          synced = await ProfileSyncService().saveEnergieProfile(energie);
        }
        if (kDebugMode) {
          debugPrint('   Worker-Sync: ${synced ? "✅" : "⚠️"}');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('   ⚠️ Worker-Sync fehlgeschlagen: $e');
        }
      }

      // 2. Direct Supabase sync as backup. Reichert das Profil-Objekt
      // mit der InvisibleAuth-ID an, falls userId fehlt -- damit
      // ensure_legacy_profile RPC die Zeile via legacy_user_id findet.
      try {
        if (materie != null) {
          final profileWithId =
              (materie.userId == null || materie.userId!.isEmpty)
                  ? materie.copyWith(userId: effectiveUserId)
                  : materie;
          final supaOk = await SupabaseProfileSync.instance
              .syncMaterieProfile(profileWithId);
          if (supaOk) synced = true;
          if (kDebugMode) {
            debugPrint('   Supabase-Sync: ${supaOk ? "✅" : "⚠️"}');
          }
        } else if (energie != null) {
          final profileWithId =
              (energie.userId == null || energie.userId!.isEmpty)
                  ? energie.copyWith(userId: effectiveUserId)
                  : energie;
          final supaOk = await SupabaseProfileSync.instance
              .syncEnergieProfile(profileWithId);
          if (supaOk) synced = true;
          if (kDebugMode) {
            debugPrint('   Supabase-Sync: ${supaOk ? "✅" : "⚠️"}');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('   ⚠️ Supabase-Sync fehlgeschlagen: $e');
        }
      }

      if (synced) {
        await prefs.setBool(_migrationFlag, true);
        if (kDebugMode) {
          debugPrint('✅ ProfileMigration: Profil "$username" synchronisiert');
        }
      } else {
        if (kDebugMode) {
          debugPrint(
              '⚠️ ProfileMigration: Fehlgeschlagen → nächster Start versucht erneut');
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ ProfileMigration: $e');
    }
  }
}
