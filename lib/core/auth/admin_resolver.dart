/// 🔐 ADMIN-RESOLVER
///
/// Ermittelt die effektive User-Rolle für den App-Admin-Check.
/// Funktioniert mit ALLEN Auth-Pfaden:
///   1. Supabase Auth Session vorhanden → role aus profiles-Tabelle
///   2. Mobile-App via InvisibleAuth (auth.currentUser=null) → Username
///      aus StorageService-Profil → Root-Admin-Check per
///      AppRoles.isRootAdminByUsername()
///   3. Web via WebAuthGate (auth.currentUser=null) → Username aus
///      SharedPreferences `web_user_name` → gleicher Root-Admin-Check
///
/// Genutzt von den 4 World-Wrappers (materie/energie/vorhang/ursprung)
/// damit der Root-Admin in JEDER Welt das Dashboard sieht.
library;

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint, kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/roles.dart';
import '../storage/unified_storage_service.dart';
import '../../services/storage_service.dart';

class AdminResolver {
  AdminResolver._();

  /// Liefert die effektive Rolle des aktuellen Users.
  /// Returns `AppRoles.user` als Default wenn nichts gefunden.
  static Future<String> resolveCurrentRole() async {
    // 1. Supabase Auth Session (für User mit echtem Supabase-Account)
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // v103 FIX 5: select username UND role -- damit wir hier schon
        // den Username-Override anwenden koennen.
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('role, username')
            .eq('id', user.id)
            .maybeSingle()
            .timeout(const Duration(seconds: 6));
        var role = profile?['role'] as String?;
        if (role != null && role.isNotEmpty) {
          // v103 FIX 5: Username-Override -- wenn Supabase 'user' sagt
          // aber der Username einem bekannten Admin-Account entspricht,
          // wird die Rolle hier korrigiert.
          final username = profile?['username'] as String? ?? '';
          if (role == AppRoles.user &&
              AppRoles.isRootAdminByUsername(username)) {
            role = AppRoles.rootAdmin;
            if (kDebugMode) {
              debugPrint(
                  '🔐 [AdminResolver] Supabase-Override: user→root_admin für $username');
            }
          } else if (role == AppRoles.user &&
              AppRoles.isContentEditorByUsername(username)) {
            role = AppRoles.contentEditor;
            if (kDebugMode) {
              debugPrint(
                  '🔐 [AdminResolver] Supabase-Override: user→content_editor für $username');
            }
          }
          if (kDebugMode) {
            debugPrint('🔐 [AdminResolver] Supabase-Session: role=$role');
          }
          // AUTH-REFACTOR-FIX: Nur eine ECHTE Admin-Rolle aus der Supabase-
          // Session beendet die Aufloesung. Die anonyme Geraete-Session
          // (signInAnonymously -> role='user') darf eine lokal etablierte
          // Admin-Identitaet NICHT ueberschatten -- sonst faellt der Owner
          // faelschlich auf 'user' und der Worker lehnt Admin-Calls mit 403 ab.
          if (AppRoles.isAdmin(role)) {
            return role;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [AdminResolver] Supabase-Lookup-Fehler: $e');
      }
    }

    // 2. Mobile-App via InvisibleAuth → Username/Cache-Rolle aus lokalem Profil
    try {
      // TEIL 1A: single unified profile -- one source, no Materie/Energie split.
      final storage = StorageService();
      final profile = storage.getProfile();
      final localUsername = profile?.username;
      if (localUsername != null && localUsername.isNotEmpty) {
        if (AppRoles.isRootAdminByUsername(localUsername)) {
          if (kDebugMode) {
            debugPrint(
                '🔐 [AdminResolver] Local profile: ROOT_ADMIN ($localUsername)');
          }
          await _persistUnifiedRole(localUsername, AppRoles.rootAdmin);
          return AppRoles.rootAdmin;
        }
        if (AppRoles.isContentEditorByUsername(localUsername)) {
          if (kDebugMode) {
            debugPrint('🔐 [AdminResolver] Local profile: CONTENT_EDITOR');
          }
          await _persistUnifiedRole(localUsername, AppRoles.contentEditor);
          return AppRoles.contentEditor;
        }
      }

      // AUTH-REFACTOR-FIX: Lokal gecachte Admin-Rolle ehren. Nach dem Refactor
      // laeuft das Geraet auf einer anonymen Supabase-Session (role='user'),
      // waehrend die zuvor aufgeloeste Admin-Rolle des Owners lokal im Profil
      // gecacht ist. Ohne dies wuerde die anon-Session den Owner auf 'user'
      // downgraden und Admin-Worker-Calls mit 403 brechen.
      final cachedRole = profile?.role;
      if (cachedRole != null &&
          cachedRole.isNotEmpty &&
          AppRoles.isAdmin(cachedRole)) {
        if (kDebugMode) {
          debugPrint('🔐 [AdminResolver] Lokale Cache-Rolle: $cachedRole');
        }
        return cachedRole;
      }

      // v104: Auch fuer Nicht-Admin-User den Username persistieren damit
      // AdminStateNotifier Schritt 2 beim naechsten Aufruf sofort trifft.
      if (localUsername != null && localUsername.isNotEmpty) {
        await _persistUnifiedRole(localUsername, AppRoles.user);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [AdminResolver] Local-Profile-Fehler: $e');
    }

    // 3. Web via WebAuthGate → SharedPreferences `web_user_name`
    if (kIsWeb) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final webName = prefs.getString('web_user_name');
        final webIsAdmin = prefs.getBool('web_is_admin') ?? false;
        if (webName != null && webName.isNotEmpty) {
          if (AppRoles.isRootAdminByUsername(webName)) {
            if (kDebugMode) {
              debugPrint(
                  '🔐 [AdminResolver] Web: ROOT_ADMIN ($webName, web_is_admin=$webIsAdmin)');
            }
            return AppRoles.rootAdmin;
          }
          if (AppRoles.isContentEditorByUsername(webName)) {
            return AppRoles.contentEditor;
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ [AdminResolver] Web-Fallback-Fehler: $e');
        }
      }
    }

    return AppRoles.user;
  }

  /// Convenience: ist current User Admin (irgendeine Admin-Rolle)?
  static Future<bool> isCurrentUserAdmin() async {
    final role = await resolveCurrentRole();
    return AppRoles.isAdmin(role);
  }

  /// v104: Schreibt den aufgeloesten Username + Rolle in
  /// UnifiedStorageService damit AdminStateNotifier Schritt 2 beim
  /// naechsten Aufruf sofort trifft. Wird nach jedem erfolgreichen
  /// Username-basierten Resolve aufgerufen. Beide Welten persistieren
  /// dieselbe Identity (single profile per user).
  static Future<void> _persistUnifiedRole(String username, String role) async {
    try {
      final unified = UnifiedStorageService();
      await unified.saveProfile('materie', {
        'username': username,
        'role': role,
      });
      await unified.saveProfile('energie', {
        'username': username,
        'role': role,
      });
    } catch (_) {/* best-effort, NICHT crashen */}
  }
}
