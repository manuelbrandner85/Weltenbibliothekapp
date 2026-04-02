import 'dart:convert';
import 'package:weltenbibliothek/config/api_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/storage/unified_storage_service.dart';
import '../../../core/constants/roles.dart';
import '../../../services/world_admin_service.dart';

/// 🔐 ADMIN STATE - SINGLE SOURCE OF TRUTH
///
/// Dieser State repräsentiert den Admin-Status für eine bestimmte Welt.
/// Er ist die einzige Wahrheitsquelle für Admin-Berechtigungen.
///
/// PROPERTIES:
/// - isAdmin: Hat User Admin-Rechte?
/// - isRootAdmin: Hat User Root-Admin-Rechte?
/// - world: Für welche Welt gilt dieser Status?
/// - backendVerified: Wurde der Status vom Backend bestätigt?
/// - username: Aktueller Username (für Debug)
/// - role: Aktuelle Rolle (für Debug)

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

  /// Factory: Leerer State (kein Admin)
  static AdminState empty(String world) => AdminState(
        isAdmin: false,
        isRootAdmin: false,
        world: world,
        backendVerified: false,
        username: null,
        role: null,
      );

  /// Factory: Local State (ohne Backend-Verifizierung)
  factory AdminState.fromLocal(String world, String? username, String? role) {
    // Offline-Fallback für Root-Admin
    final isRootByUsername = AppRoles.isRootAdminByUsername(username);
    final isRootByRole = AppRoles.isRootAdmin(role);
    final isAdminByRole = AppRoles.isAdmin(role);

    return AdminState(
      isAdmin: isRootByUsername || isAdminByRole,
      isRootAdmin: isRootByUsername || isRootByRole,
      world: world,
      backendVerified: false,
      username: username,
      role: role,
    );
  }

  /// CopyWith für Updates
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
  String toString() {
    return 'AdminState('
        'world: $world, '
        'isAdmin: $isAdmin, '
        'isRootAdmin: $isRootAdmin, '
        'backendVerified: $backendVerified, '
        'username: $username, '
        'role: $role'
        ')';
  }
}

/// 🔐 ADMIN STATE NOTIFIER
///
/// Verwaltet den Admin-Status für eine Welt.
/// Nutzt Offline-First-Architektur mit Backend-Sync.
///
/// WORKFLOW:
/// 1. Lokales Profil laden (instant)
/// 2. Admin-Status aus Profil berechnen
/// 3. Backend-Check im Hintergrund (non-blocking)
/// 4. State aktualisieren wenn Backend antwortet
/// 5. Bei Timeout: Lokaler State bleibt gültig

class AdminStateNotifier extends StateNotifier<AdminState> {
  final Ref ref;
  final String world;
  final _storage = UnifiedStorageService();

  AdminStateNotifier(this.ref, this.world) : super(AdminState.empty(world)) {
    // Auto-Load beim Erstellen
    load();
  }

  /// Admin-Status laden (Offline-First)
  Future<void> load() async {
    if (kDebugMode) {
      debugPrint('🔐 AdminStateNotifier: Lade Status ($world)...');
    }

    // SCHRITT 1: Lokales Profil laden (instant)
    final username = _storage.getUsername(world);
    final role = _storage.getRole(world);

    if (username == null || username.isEmpty) {
      if (kDebugMode) {
        debugPrint('⚠️ AdminStateNotifier: Kein Profil gefunden ($world)');
      }
      state = AdminState.empty(world);
      return;
    }

    // SCHRITT 2: Lokalen State setzen (instant)
    state = AdminState.fromLocal(world, username, role);

    if (kDebugMode) {
      debugPrint('✅ AdminStateNotifier: Lokaler Status geladen');
      debugPrint('   $state');
    }

    // SCHRITT 3: Backend-Check (non-blocking)
    _verifyWithBackend(username);
  }

  /// Backend-Verifizierung (non-blocking)
  Future<void> _verifyWithBackend(String username) async {
    try {
      if (kDebugMode) {
        debugPrint('🌐 AdminStateNotifier: Backend-Check starten ($world)...');
      }

      final response = await WorldAdminService.checkAdminStatus(
        world,
        username,
      ).timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          if (kDebugMode) {
            debugPrint('⏱️ AdminStateNotifier: Backend-Timeout (lokaler State bleibt)');
          }
          return {
            'success': false,
            'isAdmin': state.isAdmin,
            'isRootAdmin': state.isRootAdmin,
          };
        },
      );

      if (response['success'] == true) {
        // Backend hat geantwortet - State aktualisieren
        state = state.copyWith(
          isAdmin: response['isAdmin'] ?? state.isAdmin,
          isRootAdmin: response['isRootAdmin'] ?? state.isRootAdmin,
          backendVerified: true,
        );

        if (kDebugMode) {
          debugPrint('✅ AdminStateNotifier: Backend-Verifizierung erfolgreich');
          debugPrint('   $state');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ AdminStateNotifier: Backend-Fehler: $e');
        debugPrint('   Verwende lokalen State (Offline-First)');
      }
      // State bleibt unverändert (Offline-First)
    }
  }

  /// Admin-Status neu laden (z.B. nach Profil-Update)
  void refresh() {
    if (kDebugMode) {
      debugPrint('🔄 AdminStateNotifier: Refresh ($world)');
    }
    load();
  }
  
  /// Admin-Status refresh (Alias für refresh) + Backend-Sync
  Future<void> refreshAdminStatus() async {
    if (kDebugMode) {
      debugPrint('🔄 AdminStateNotifier: refreshAdminStatus ($world)');
      debugPrint('   Synchronisiere Profil mit Backend...');
    }
    
    // CRITICAL: Lade Profil vom Backend um aktuelle Role zu bekommen
    try {
      final username = _storage.getUsername(world);
      if (username != null && username.isNotEmpty) {
        final response = await http.get(
          Uri.parse('${ApiConfig.workerUrl}/api/profile/$world/$username'),
          headers: {'Authorization': 'Bearer sync_token'},
        ).timeout(const Duration(seconds: 5));
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true && data['profile'] != null) {
            final profile = data['profile'];
            final newRole = profile['role'] as String?;
            
            if (kDebugMode) {
              debugPrint('✅ Backend-Profil geladen: role=$newRole');
            }
            
            // Aktualisiere lokales Profil mit neuer Role
            if (newRole != null) {
              // Lade aktuelles Profil
              final currentProfile = _storage.getProfile(world);
              if (currentProfile != null) {
                // Update role im Profil
                if (world == 'materie') {
                  currentProfile['role'] = newRole;
                } else if (world == 'energie') {
                  currentProfile['role'] = newRole;
                }
                
                // Speichere aktualisiertes Profil
                await _storage.saveProfile(world, currentProfile);
                
                if (kDebugMode) {
                  debugPrint('✅ Lokales Profil aktualisiert mit role=$newRole');
                }
              }
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Backend-Sync fehlgeschlagen: $e');
      }
    }
    
    // Dann normalen Load durchführen
    await load();
  }
}

/// 🔐 RIVERPOD PROVIDER - FAMILY (pro Welt)
///
/// Dieser Provider erstellt einen separaten AdminStateNotifier
/// für jede Welt (materie, energie).
///
/// USAGE:
/// ```dart
/// final adminState = ref.watch(adminStateProvider('materie'));
/// if (adminState.isAdmin) {
///   // Show admin button
/// }
/// ```

final adminStateProvider = StateNotifierProvider.family<AdminStateNotifier, AdminState, String>(
  (ref, world) => AdminStateNotifier(ref, world),
);
