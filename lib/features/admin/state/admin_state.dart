import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/supabase_service.dart';
import '../../../core/constants/roles.dart';

class AdminState {
  final bool isAdmin;
  final bool isRootAdmin;
  final String world;
  final bool backendVerified;
  final String? username;
  final String? role;

  const AdminState({
    required this.isAdmin,
    required this.isRootAdmin,
    required this.world,
    required this.backendVerified,
    this.username,
    this.role,
  });

  static AdminState empty(String world) => AdminState(
        isAdmin: false,
        isRootAdmin: false,
        world: world,
        backendVerified: false,
        username: null,
        role: null,
      );

  AdminState copyWith({
    bool? isAdmin,
    bool? isRootAdmin,
    bool? backendVerified,
    String? username,
    String? role,
  }) {
    return AdminState(
      isAdmin: isAdmin ?? this.isAdmin,
      isRootAdmin: isRootAdmin ?? this.isRootAdmin,
      world: world,
      backendVerified: backendVerified ?? this.backendVerified,
      username: username ?? this.username,
      role: role ?? this.role,
    );
  }

  @override
  String toString() => 'AdminState('
      'world: $world, isAdmin: $isAdmin, isRootAdmin: $isRootAdmin, '
      'backendVerified: $backendVerified, username: $username, role: $role)';
}

class AdminStateNotifier extends StateNotifier<AdminState> {
  final String world;
  bool _isLoading = false;

  AdminStateNotifier(this.world) : super(AdminState.empty(world)) {
    load();
  }

  Future<void> load() async {
    if (_isLoading) return;
    _isLoading = true;

    final user = supabase.auth.currentUser;
    if (user == null) {
      state = AdminState.empty(world);
      _isLoading = false;
      return;
    }

    // Username aus Supabase Auth metadata
    final meta = user.userMetadata;
    final username = meta?['username'] as String?
        ?? user.email?.split('@').first
        ?? '';

    // Root-Admin-Check über Username (hardcoded fallback)
    final isRootByUsername = AppRoles.isRootAdminByUsername(username);

    state = AdminState(
      isAdmin: isRootByUsername,
      isRootAdmin: isRootByUsername,
      world: world,
      backendVerified: false,
      username: username,
      role: isRootByUsername ? AppRoles.rootAdmin : AppRoles.user,
    );

    if (kDebugMode) debugPrint('🔐 AdminState: local ($world) username=$username isRoot=$isRootByUsername');

    _isLoading = false;
    _verifyWithSupabase(user.id, username);
  }

  Future<void> _verifyWithSupabase(String userId, String username) async {
    try {
      final profile = await supabase
          .from('user_profiles')
          .select('is_admin')
          .eq('id', userId)
          .maybeSingle()
          .timeout(const Duration(seconds: 4));

      final isAdminFromDb = profile?['is_admin'] == true;
      final isRootByUsername = AppRoles.isRootAdminByUsername(username);

      state = state.copyWith(
        isAdmin: isAdminFromDb || isRootByUsername,
        isRootAdmin: isRootByUsername,
        backendVerified: true,
        role: (isAdminFromDb || isRootByUsername) ? AppRoles.admin : AppRoles.user,
      );

      if (kDebugMode) {
        debugPrint('✅ AdminState: backend verified ($world) isAdmin=${state.isAdmin}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ AdminState: backend check failed: $e');
    }
  }

  void refresh() => load();

  Future<void> refreshAdminStatus() => load();
}

final adminStateProvider =
    StateNotifierProvider.family<AdminStateNotifier, AdminState, String>(
  (ref, world) => AdminStateNotifier(world),
);
