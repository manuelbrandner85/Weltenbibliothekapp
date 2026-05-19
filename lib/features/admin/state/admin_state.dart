import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/unified_storage_service.dart';
import '../../../services/sqlite_storage_service.dart';
import '../../../services/storage_service.dart';
import '../../../core/auth/admin_resolver.dart';
import '../../../core/constants/roles.dart';
import '../../../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthChangeEvent;

/// 🔐 ADMIN STATE – Single Source of Truth
///
/// Rolle kommt immer aus Supabase profiles.role (backend-verifiziert).
/// Hive wird nur als Offline-Cache genutzt – NIEMALS als Rollenbasis ohne Backend-Check.

class AdminState {
  final bool isAdmin;
  final bool isRootAdmin;
  final bool isModerator;
  final String world;
  final bool backendVerified;
  final String? username;
  final String? role;

  const AdminState({
    required this.isAdmin,
    required this.isRootAdmin,
    required this.isModerator,
    required this.world,
    required this.backendVerified,
    this.username,
    this.role,
  });

  static AdminState empty(String world) => AdminState(
        isAdmin: false,
        isRootAdmin: false,
        isModerator: false,
        world: world,
        backendVerified: false,
        username: null,
        role: null,
      );

  factory AdminState.fromCache(String world, String? username, String? role) {
    return AdminState(
      isAdmin: AppRoles.isAdmin(role),
      isRootAdmin: AppRoles.isRootAdmin(role),
      isModerator: AppRoles.isModerator(role),
      world: world,
      backendVerified: false,
      username: username,
      role: role,
    );
  }

  AdminState copyWith({
    bool? isAdmin,
    bool? isRootAdmin,
    bool? isModerator,
    bool? backendVerified,
    String? username,
    String? role,
  }) {
    return AdminState(
      isAdmin: isAdmin ?? this.isAdmin,
      isRootAdmin: isRootAdmin ?? this.isRootAdmin,
      isModerator: isModerator ?? this.isModerator,
      world: world,
      backendVerified: backendVerified ?? this.backendVerified,
      username: username ?? this.username,
      role: role ?? this.role,
    );
  }

  @override
  String toString() => 'AdminState('
      'world: $world, '
      'isAdmin: $isAdmin, '
      'isRootAdmin: $isRootAdmin, '
      'backendVerified: $backendVerified, '
      'username: $username, '
      'role: $role'
      ')';
}

/// 🔐 ADMIN STATE NOTIFIER
///
/// Workflow:
/// 1. Supabase-Session prüfen (primary – backend-verifiziert)
///    → profiles.role ist die einzige Wahrheitsquelle
/// 2. Ergebnis in Hive cachen für nächsten Cold-Start
/// 3. Kein Netz: Hive-Cache verwenden (backendVerified = false)

class AdminStateNotifier extends StateNotifier<AdminState> {
  final Ref ref;
  final String world;
  final _storage = UnifiedStorageService();
  // v103: Race-Condition-Schutz. Verhindert dass parallele load()-Aufrufe
  // (Constructor + onAuthStateChange) sich gegenseitig ueberschreiben.
  bool _isLoading = false;

  AdminStateNotifier(this.ref, this.world) : super(AdminState.empty(world)) {
    load();
    supabase.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn ||
          data.event == AuthChangeEvent.signedOut ||
          data.event == AuthChangeEvent.tokenRefreshed) {
        load();
      }
    });
  }

  Future<void> load() async {
    if (_isLoading) {
      if (kDebugMode)
        debugPrint('🔐 AdminState: load() skipped (already running)');
      return;
    }
    _isLoading = true;
    try {
      await _loadInternal();
    } finally {
      _isLoading = false;
    }
  }

  Future<void> _loadInternal() async {
    if (kDebugMode) debugPrint('🔐 AdminState: load() für $world');

    // ──────────────────────────────────────────────────────────────
    // SCHRITT 1: Supabase-Session als primäre Quelle
    // ──────────────────────────────────────────────────────────────
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final profile = await supabase
            .from('profiles')
            .select('username, role, display_name')
            .eq('id', user.id)
            .maybeSingle();

        if (profile != null) {
          final username = profile['username'] as String? ?? '';
          var role = profile['role'] as String? ?? AppRoles.user;

          // v103 FIX 1: Username-basierter Override falls Supabase-Rolle
          // 'user' ist aber Username einem bekannten Admin-Account
          // entspricht. Passiert wenn profiles.role nie auf root_admin
          // gesetzt wurde oder durch einen Bug zurueckgesetzt wurde.
          if (role == AppRoles.user || role.isEmpty) {
            if (AppRoles.isRootAdminByUsername(username)) {
              role = AppRoles.rootAdmin;
              if (kDebugMode) {
                debugPrint(
                    '🔐 AdminState: Username-Override → root_admin für $username');
              }
              _fixSupabaseRole(user.id, AppRoles.rootAdmin);
            } else if (AppRoles.isContentEditorByUsername(username)) {
              role = AppRoles.contentEditor;
              if (kDebugMode) {
                debugPrint(
                    '🔐 AdminState: Username-Override → content_editor für $username');
              }
              _fixSupabaseRole(user.id, AppRoles.contentEditor);
            }
          }

          // In Hive cachen für Offline-Nutzung
          await _storage.saveProfile(world, {
            'username': username,
            'role': role,
            'user_id': user.id,
            'display_name': profile['display_name'],
          });

          state = AdminState(
            isAdmin: AppRoles.isAdmin(role),
            isRootAdmin: AppRoles.isRootAdmin(role),
            isModerator: AppRoles.isModerator(role),
            world: world,
            backendVerified: true,
            username: username,
            role: role,
          );

          if (kDebugMode) {
            debugPrint('✅ AdminState: Supabase verifiziert – $state');
          }
          return;
        }
      }
    } catch (e) {
      if (kDebugMode)
        debugPrint('⚠️ AdminState: Supabase-Load fehlgeschlagen: $e');
    }

    // ──────────────────────────────────────────────────────────────
    // SCHRITT 2: Hive-Cache als Offline-Fallback
    // ──────────────────────────────────────────────────────────────
    String? username = _storage.getUsername(world);
    String? role = _storage.getRole(world);

    if (username == null || username.isEmpty) {
      try {
        final boxName =
            world == 'materie' ? 'materie_profiles' : 'energie_profiles';
        final raw =
            SqliteStorageService.instance.getSync(boxName, 'current_profile');
        if (raw != null) {
          final data = Map<String, dynamic>.from(raw as Map);
          username = data['username'] as String?;
          role = data['role'] as String?;
          if (username != null && username.isNotEmpty) {
            await _storage.saveProfile(world, data);
          }
        }
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ AdminState: Profil-Box Fallback: $e');
      }
    }

    // v104 FIX: SharedPreferences-Fallback fuer InvisibleAuth-User.
    // StorageService speichert das Profil in SharedPreferences
    // (sp_materie_profile / sp_energie_profile). UnifiedStorageService
    // (SQLite user_data) wird nur vom Supabase-Path befuellt. Ohne
    // diesen Block hat ein InvisibleAuth-User keinen Username im
    // AdminState -- und Schritt 2.5 + die Admin-Resolution greifen nie.
    if (username == null || username.isEmpty) {
      try {
        final storage = StorageService();
        final mProfile = storage.getMaterieProfile();
        final eProfile = storage.getEnergieProfile();
        username = mProfile?.username ?? eProfile?.username;
        role = mProfile?.role ?? eProfile?.role;
        if (username != null && username.isNotEmpty) {
          // Persistiere ins UnifiedStorage damit zukuenftige Aufrufe
          // sofort treffen (kein erneuter SharedPreferences-Lookup).
          await _storage.saveProfile(world, {
            'username': username,
            'role': role ?? AppRoles.user,
          });
          if (kDebugMode) {
            debugPrint(
                '🔐 AdminState: SharedPreferences-Fallback: username=$username, role=$role');
          }
        }
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ AdminState: SP-Fallback-Fehler: $e');
      }
    }

    // ──────────────────────────────────────────────────────────────
    // SCHRITT 2.5: Username-basierter Role-Override (Offline-Sicherheit)
    // ──────────────────────────────────────────────────────────────
    // v103 FIX 1: Wenn Hive/SQLite role='user' oder fehlt, aber Username
    // ist bekannter Root-Admin/Content-Editor -> auf entsprechende Rolle
    // anheben. Damit funktioniert Admin-Zugriff auch komplett offline.
    if (username != null && username.isNotEmpty) {
      if ((role == null || role == AppRoles.user || role.isEmpty) &&
          AppRoles.isRootAdminByUsername(username)) {
        role = AppRoles.rootAdmin;
        if (kDebugMode) {
          debugPrint(
              '🔐 AdminState: Offline-Override → root_admin für $username');
        }
      }
      if ((role == null || role == AppRoles.user || role.isEmpty) &&
          AppRoles.isContentEditorByUsername(username)) {
        role = AppRoles.contentEditor;
        if (kDebugMode) {
          debugPrint(
              '🔐 AdminState: Offline-Override → content_editor für $username');
        }
      }
    }

    // ──────────────────────────────────────────────────────────────
    // SCHRITT 3: AdminResolver — InvisibleAuth + Web SharedPref + Role-by-Username
    // ──────────────────────────────────────────────────────────────
    // Fängt Root-Admin und Content-Editor auch wenn Supabase-Session fehlt
    // (Mobile via InvisibleAuth, Web via WebAuthGate). Ohne diesen Schritt
    // wurde der Root-Admin als 'user' interpretiert → "Kein Zugriff" im
    // Dashboard. Resolver checkt 3 Pfade, gibt 'user' wenn nichts greift.
    try {
      final resolverRole = await AdminResolver.resolveCurrentRole();
      if (AppRoles.isAdmin(resolverRole)) {
        // Username: behalte was wir aus Hive/SQLite haben — sonst leer.
        state =
            AdminState.fromCache(world, username ?? '(admin)', resolverRole);
        if (kDebugMode) {
          debugPrint(
              '🛡️ AdminState: AdminResolver-Pfad – role=$resolverRole, $state');
        }
        return;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ AdminState: AdminResolver-Fehler: $e');
    }

    if (username == null || username.isEmpty) {
      if (kDebugMode) {
        debugPrint('⚠️ AdminState: Kein Profil gefunden ($world)');
      }
      state = AdminState.empty(world);
      return;
    }

    // v104 FIX: Finaler Hard-Username-Override als absoluter Last Resort.
    // Falls trotz aller vorherigen Schritte role weiterhin null/'user'
    // ist, aber der Username einem bekannten Admin-Account entspricht,
    // setze die Rolle hart. Schliesst die letzte Race-Condition-Luecke.
    if ((role == null || role == AppRoles.user || role.isEmpty) &&
        username.isNotEmpty) {
      if (AppRoles.isRootAdminByUsername(username)) {
        role = AppRoles.rootAdmin;
        if (kDebugMode) {
          debugPrint(
              '🔐 AdminState: FINAL Override → root_admin für $username');
        }
      } else if (AppRoles.isContentEditorByUsername(username)) {
        role = AppRoles.contentEditor;
        if (kDebugMode) {
          debugPrint(
              '🔐 AdminState: FINAL Override → content_editor für $username');
        }
      }
    }

    state = AdminState.fromCache(world, username, role);
    if (kDebugMode) debugPrint('📦 AdminState: Offline-Cache geladen – $state');
  }

  void refresh() => load();

  /// Alias für explizites Re-Sync mit Supabase.
  Future<void> refreshAdminStatus() => load();

  /// v103 FIX 1: Korrigiert die Rolle in Supabase profiles im Hintergrund.
  /// Wird vom Username-Override aufgerufen wenn Supabase falsche Rolle
  /// hatte. Fire-and-forget -- Fehler werden nur geloggt, nie geworfen.
  /// Service-Role-Bypass durch v71-Trigger (auto_set_admin_role) oder
  /// RLS-Policy profiles_role_update_admin_only mit Service-Role.
  void _fixSupabaseRole(String supabaseUserId, String correctRole) {
    Future(() async {
      try {
        await supabase
            .from('profiles')
            .update({'role': correctRole}).eq('id', supabaseUserId);
        if (kDebugMode) {
          debugPrint(
              '✅ AdminState: Supabase role korrigiert → $correctRole');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ AdminState: Supabase role fix failed: $e');
        }
      }
    });
  }
}

/// Provider (pro Welt)
final adminStateProvider =
    StateNotifierProvider.family<AdminStateNotifier, AdminState, String>(
  (ref, world) => AdminStateNotifier(ref, world),
);
