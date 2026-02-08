import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/materie_profile.dart';
import '../../models/energie_profile.dart';
import '../constants/roles.dart';

/// 🔐 UNIFIED STORAGE SERVICE - WORLD-AGNOSTIC
///
/// Dieser Service abstrahiert die Profil-Speicherung für BEIDE Welten.
/// Er nutzt den bestehenden StorageService als Backend, bietet aber
/// eine einheitliche API für Admin-System.
///
/// VORTEILE:
/// - Kein Code-Duplikation zwischen Materie & Energie
/// - Type-safe world parameter
/// - Konsistente Admin-Status-Checks
/// - Offline-First mit Fallbacks

class UnifiedStorageService {
  // Singleton Pattern
  static final UnifiedStorageService _instance = UnifiedStorageService._internal();
  factory UnifiedStorageService() => _instance;
  UnifiedStorageService._internal();

  // Box-Namen (konsistent mit StorageService - PLURAL!)
  static const String _materieProfileBox = 'materie_profiles';
  static const String _energieProfileBox = 'energie_profiles';

  /// World-agnostisches Profil laden
  /// Returns null wenn kein Profil existiert
  dynamic getProfile(String world) {
    try {
      final boxName = _getBoxName(world);
      final box = Hive.box(boxName);
      final data = box.get('current_profile');  // Raw Map from Hive
      
      if (data == null) return null;

      // Convert Map to Profile Object
      dynamic profile;
      if (world.toLowerCase() == 'materie') {
        profile = MaterieProfile.fromJson(Map<String, dynamic>.from(data as Map));
      } else if (world.toLowerCase() == 'energie') {
        profile = EnergieProfile.fromJson(Map<String, dynamic>.from(data as Map));
      } else {
        return null;
      }

      if (kDebugMode && profile != null) {
        debugPrint('✅ UnifiedStorage: Profil geladen ($world)');
        debugPrint('   Username: ${_getUsername(profile, world)}');
        debugPrint('   Role: ${_getRole(profile, world) ?? 'null'}');
      }

      return profile;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ UnifiedStorage: Fehler beim Laden ($world): $e');
      }
      return null;
    }
  }

  /// World-agnostisches Profil speichern
  Future<void> saveProfile(String world, dynamic profile) async {
    try {
      final boxName = _getBoxName(world);
      final box = Hive.box(boxName);
      await box.put('current_profile', profile);  // ✅ FIXED: Use 'current_profile' key

      if (kDebugMode) {
        debugPrint('✅ UnifiedStorage: Profil gespeichert ($world)');
        debugPrint('   Username: ${_getUsername(profile, world)}');
        debugPrint('   Role: ${_getRole(profile, world) ?? 'null'}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ UnifiedStorage: Fehler beim Speichern ($world): $e');
      }
      rethrow;
    }
  }

  /// Admin-Status prüfen (world-agnostic)
  bool isAdmin(String world) {
    final profile = getProfile(world);
    if (profile == null) return false;

    final role = _getRole(profile, world);

    // Offline-Fallback für Root-Admin
    final username = _getUsername(profile, world);
    if (AppRoles.isRootAdminByUsername(username)) {
      if (kDebugMode) {
        debugPrint('👑 UnifiedStorage: Root-Admin erkannt (Offline-Fallback)');
      }
      return true;
    }

    return AppRoles.isAdmin(role);
  }

  /// Root-Admin-Status prüfen (world-agnostic)
  bool isRootAdmin(String world) {
    final profile = getProfile(world);
    if (profile == null) return false;

    final role = _getRole(profile, world);

    // Offline-Fallback für Root-Admin
    final username = _getUsername(profile, world);
    if (AppRoles.isRootAdminByUsername(username)) {
      if (kDebugMode) {
        debugPrint('👑 UnifiedStorage: Root-Admin erkannt (Offline-Fallback)');
      }
      return true;
    }

    return AppRoles.isRootAdmin(role);
  }

  /// Username abrufen (world-agnostic)
  String? getUsername(String world) {
    final profile = getProfile(world);
    if (profile == null) return null;
    return _getUsername(profile, world);
  }

  /// Role abrufen (world-agnostic)
  String? getRole(String world) {
    final profile = getProfile(world);
    if (profile == null) return null;
    return _getRole(profile, world);
  }

  /// UserId abrufen (world-agnostic)
  String? getUserId(String world) {
    final profile = getProfile(world);
    if (profile == null) return null;
    return _getUserId(profile, world);
  }

  /// Profil existiert?
  bool hasProfile(String world) {
    return getProfile(world) != null;
  }

  /// Profil löschen (world-agnostic)
  Future<void> deleteProfile(String world) async {
    try {
      final boxName = _getBoxName(world);
      final box = Hive.box(boxName);
      await box.delete('current_profile');  // ✅ FIXED: Use 'current_profile' key

      if (kDebugMode) {
        debugPrint('✅ UnifiedStorage: Profil gelöscht ($world)');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ UnifiedStorage: Fehler beim Löschen ($world): $e');
      }
      rethrow;
    }
  }

  // ========== PRIVATE HELPER METHODS ==========

  String _getBoxName(String world) {
    switch (world.toLowerCase()) {
      case 'materie':
        return _materieProfileBox;
      case 'energie':
        return _energieProfileBox;
      default:
        throw ArgumentError('Ungültige Welt: $world (erwartet: materie, energie)');
    }
  }

  String _getUsername(dynamic profile, String world) {
    if (world.toLowerCase() == 'materie' && profile is MaterieProfile) {
      return profile.username;
    } else if (world.toLowerCase() == 'energie' && profile is EnergieProfile) {
      return profile.username;
    }
    return '';
  }

  String? _getRole(dynamic profile, String world) {
    if (world.toLowerCase() == 'materie' && profile is MaterieProfile) {
      return profile.role;
    } else if (world.toLowerCase() == 'energie' && profile is EnergieProfile) {
      return profile.role;
    }
    return null;
  }

  String? _getUserId(dynamic profile, String world) {
    if (world.toLowerCase() == 'materie' && profile is MaterieProfile) {
      return profile.userId;
    } else if (world.toLowerCase() == 'energie' && profile is EnergieProfile) {
      return profile.userId;
    }
    return null;
  }
}
