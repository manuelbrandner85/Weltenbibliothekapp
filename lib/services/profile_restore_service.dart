import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/materie_profile.dart';
import '../models/energie_profile.dart';
import '../services/storage_service.dart';
import '../services/profile_sync_service.dart';

/// 🔄 PROFIL-WIEDERHERSTELLUNGS-SERVICE
///
/// Problem: App ist öffentlich – jeder kann ein Profil anlegen.
/// Profil liegt in Hive (lokal). Bei Deinstallation → Hive weg → Profil weg.
///
/// Lösung: Bei Profil-Erstellung wird der Username in SharedPreferences gespeichert.
/// SharedPreferences überlebt Deinstallation auf Android NICHT (Standard),
/// ABER das Profil liegt auch im Cloudflare-Worker-Backend.
///
/// Beim nächsten App-Start:
/// 1. Hive leer? → letzten Username aus SharedPrefs lesen
/// 2. Profil vom Worker/Supabase holen → lokal in Hive speichern
/// 3. User merkt nichts → nahtlose Wiederherstellung
///
/// Falls SharedPrefs auch leer (Neuinstallation auf neuem Gerät):
/// → Normaler Onboarding-Flow (Profil neu anlegen ODER Username eingeben)
class ProfileRestoreService {
  static final ProfileRestoreService _instance = ProfileRestoreService._internal();
  factory ProfileRestoreService() => _instance;
  ProfileRestoreService._internal();

  final _storage = StorageService();
  final _sync = ProfileSyncService();

  // SharedPreferences Keys (überleben App-Updates, aber NICHT Deinstallation)
  static const String _keyMaterieUsername = 'wb_last_materie_username';
  static const String _keyEnergieUsername = 'wb_last_energie_username';

  // ═══════════════════════════════════════════════════════════
  // HAUPT-METHODE: App-Start Wiederherstellung
  // Wird in main.dart aufgerufen (non-blocking, im Hintergrund)
  // ═══════════════════════════════════════════════════════════

  Future<ProfileRestoreResult> checkAndRestoreProfiles() async {
    bool materieRestored = false;
    bool energieRestored = false;
    bool hasMaterieLocal = false;
    bool hasEnergieLocal = false;

    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Lokalen Stand prüfen
      hasMaterieLocal = _storage.getMaterieProfile() != null;
      hasEnergieLocal = _storage.getEnergieProfile() != null;

      if (kDebugMode) {
        debugPrint('🔄 ProfileRestore: Start-Check');
        debugPrint('   Materie lokal: $hasMaterieLocal');
        debugPrint('   Energie lokal: $hasEnergieLocal');
      }

      // 2. Vorhandene Profile: Username für nächstes Mal sichern + Background-Sync
      if (hasMaterieLocal) {
        final p = _storage.getMaterieProfile();
        if (p != null && p.username.isNotEmpty) {
          await prefs.setString(_keyMaterieUsername, p.username);
          _backgroundSync('materie', p.username);
        }
      }
      if (hasEnergieLocal) {
        final p = _storage.getEnergieProfile();
        if (p != null && p.username.isNotEmpty) {
          await prefs.setString(_keyEnergieUsername, p.username);
          _backgroundSync('energie', p.username);
        }
      }

      // 3. Fehlende Profile wiederherstellen
      if (!hasMaterieLocal) {
        final lastUser = prefs.getString(_keyMaterieUsername);
        if (lastUser != null && lastUser.isNotEmpty) {
          materieRestored = await _restoreMaterie(lastUser);
        }
      }
      if (!hasEnergieLocal) {
        final lastUser = prefs.getString(_keyEnergieUsername);
        if (lastUser != null && lastUser.isNotEmpty) {
          energieRestored = await _restoreEnergie(lastUser);
        }
      }

      if (kDebugMode && (materieRestored || energieRestored)) {
        debugPrint('✅ ProfileRestore: Wiederhergestellt – Materie=$materieRestored, Energie=$energieRestored');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ ProfileRestore Fehler: $e');
    }

    return ProfileRestoreResult(
      materieRestored: materieRestored,
      energieRestored: energieRestored,
      anyProfilePresent: hasMaterieLocal || hasEnergieLocal || materieRestored || energieRestored,
    );
  }

  // ═══════════════════════════════════════════════════════════
  // INTERNE RESTORE-HELFER
  // ═══════════════════════════════════════════════════════════

  Future<bool> _restoreMaterie(String username) async {
    try {
      if (kDebugMode) debugPrint('🔄 Versuche Materie-Profil wiederherzustellen: $username');
      final profile = await _sync.getMaterieProfile(username);
      if (profile != null && profile.username.isNotEmpty) {
        await _storage.saveMaterieProfile(profile);
        if (kDebugMode) debugPrint('✅ Materie wiederhergestellt: ${profile.username}');
        return true;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Materie-Restore fehlgeschlagen: $e');
    }
    return false;
  }

  Future<bool> _restoreEnergie(String username) async {
    try {
      if (kDebugMode) debugPrint('🔄 Versuche Energie-Profil wiederherzustellen: $username');
      final profile = await _sync.getEnergieProfile(username);
      if (profile != null && profile.username.isNotEmpty) {
        await _storage.saveEnergieProfile(profile);
        if (kDebugMode) debugPrint('✅ Energie wiederhergestellt: ${profile.username}');
        return true;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Energie-Restore fehlgeschlagen: $e');
    }
    return false;
  }

  /// Hält das Backend-Profil aktuell (non-blocking)
  void _backgroundSync(String world, String username) {
    Future.microtask(() async {
      try {
        if (world == 'materie') {
          final p = _storage.getMaterieProfile();
          if (p != null) await _sync.saveMaterieProfile(p);
        } else {
          final p = _storage.getEnergieProfile();
          if (p != null) await _sync.saveEnergieProfile(p);
        }
        if (kDebugMode) debugPrint('☁️ Background-Sync OK: $world/$username');
      } catch (_) {}
    });
  }

  // ═══════════════════════════════════════════════════════════
  // ÖFFENTLICHE API – bei Profil-Erstellung aufrufen
  // ═══════════════════════════════════════════════════════════

  /// Registriert einen Username für zukünftige Wiederherstellung.
  /// Muss nach jeder Profilerstellung/-änderung aufgerufen werden.
  Future<void> registerProfileForRestore(String world, String username) async {
    if (username.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = world == 'materie' ? _keyMaterieUsername : _keyEnergieUsername;
      await prefs.setString(key, username);
      if (kDebugMode) debugPrint('💾 Restore-Username gespeichert: $world → $username');
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ registerProfileForRestore Fehler: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // MANUELL: User gibt seinen Username ein (neues Gerät)
  // ═══════════════════════════════════════════════════════════

  Future<MaterieProfile?> restoreMaterieByUsername(String username) async {
    final profile = await _restoreMaterie(username.trim()) ? _storage.getMaterieProfile() : null;
    if (profile != null) await registerProfileForRestore('materie', profile.username);
    return profile;
  }

  Future<EnergieProfile?> restoreEnergieByUsername(String username) async {
    final profile = await _restoreEnergie(username.trim()) ? _storage.getEnergieProfile() : null;
    if (profile != null) await registerProfileForRestore('energie', profile.username);
    return profile;
  }
}

// ═══════════════════════════════════════════════════════════
// ERGEBNIS-KLASSE
// ═══════════════════════════════════════════════════════════

class ProfileRestoreResult {
  final bool materieRestored;
  final bool energieRestored;
  final bool anyProfilePresent;

  const ProfileRestoreResult({
    required this.materieRestored,
    required this.energieRestored,
    required this.anyProfilePresent,
  });

  bool get anyRestored => materieRestored || energieRestored;

  @override
  String toString() =>
      'ProfileRestoreResult(materie=$materieRestored, energie=$energieRestored, present=$anyProfilePresent)';
}
