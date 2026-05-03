import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/unified_storage_service.dart';
import '../../../services/sqlite_storage_service.dart';
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
          final role = profile['role'] as String? ?? AppRoles.user;

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
      if (kDebugMode) debugPrint('⚠️ AdminState: Supabase-Load fehlgeschlagen: $e');
    }

    // ──────────────────────────────────────────────────────────────
    // SCHRITT 2: Hive-Cache als Offline-Fallback
    // ──────────────────────────────────────────────────────────────
    String? username = _storage.getUsername(world);
    String? role = _storage.getRole(world);

    if (username == null || username.isEmpty) {
      try {
        final boxName = world == 'materie' ? 'materie_profiles' : 'energie_profiles';
        final raw = SqliteStorageService.instance.getSync(boxName, 'current_profile');
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

    if (username == null || username.isEmpty) {
      if (kDebugMode) debugPrint('⚠️ AdminState: Kein Profil gefunden ($world)');
      state = AdminState.empty(world);
      return;
    }

    state = AdminState.fromCache(world, username, role);
    if (kDebugMode) debugPrint('📦 AdminState: Offline-Cache geladen – $state');
  }

  void refresh() => load();

  /// Alias für explizites Re-Sync mit Supabase.
  Future<void> refreshAdminStatus() => load();
}

/// Provider (pro Welt)
final adminStateProvider =
    StateNotifierProvider.family<AdminStateNotifier, AdminState, String>(
  (ref, world) => AdminStateNotifier(ref, world),
);
