// 🟢 UPDATE CONFIRMATION SERVICE
//
// Vergleicht beim App-Start die aktuell aktive Version/Patch-Nummer mit dem
// zuletzt bekannten Stand aus SharedPreferences. Wenn sich etwas geändert hat,
// wurde ein Update oder Patch erfolgreich aktiviert → UI zeigt Erfolgsbanner.
//
// Gespeicherte Keys:
//   update_confirm_patch   = letzter bekannter Patch-Index (int)
//   update_confirm_version = letzte bekannte APP_VERSION (String)

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

import 'update_service.dart';

enum UpdateConfirmationType { none, patch, version }

class UpdateConfirmationResult {
  final UpdateConfirmationType type;
  final String? previousVersion;
  final String? currentVersion;
  final int? previousPatch;
  final int? currentPatch;

  const UpdateConfirmationResult({
    required this.type,
    this.previousVersion,
    this.currentVersion,
    this.previousPatch,
    this.currentPatch,
  });

  static const none = UpdateConfirmationResult(type: UpdateConfirmationType.none);

  bool get wasUpdated => type != UpdateConfirmationType.none;
}

class UpdateConfirmationService {
  UpdateConfirmationService._();
  static final instance = UpdateConfirmationService._();

  static const _keyPatch = 'update_confirm_patch';
  static const _keyVersion = 'update_confirm_version';

  final ShorebirdUpdater _shorebird = ShorebirdUpdater();

  /// Prüft ob seit dem letzten Start ein Patch oder eine neue APK-Version aktiv wurde.
  /// Speichert den neuen Stand direkt danach (einmalige Anzeige pro Update).
  Future<UpdateConfirmationResult> checkAndConfirm() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedVersion = prefs.getString(_keyVersion);
      final storedPatch = prefs.getInt(_keyPatch);
      final currentVersion = UpdateService.currentAppVersion;

      // Patch-Aktivierung prüfen (Shorebird)
      int? currentPatch;
      if (_shorebird.isAvailable) {
        final patch = await _shorebird.readCurrentPatch();
        currentPatch = patch?.number;
      }

      // Versionswechsel (neue APK installiert)
      if (storedVersion != null &&
          storedVersion != currentVersion &&
          currentVersion != '0.0.0') {
        await _saveState(prefs, currentVersion, currentPatch);
        return UpdateConfirmationResult(
          type: UpdateConfirmationType.version,
          previousVersion: storedVersion,
          currentVersion: currentVersion,
        );
      }

      // Patch-Aktivierung (OTA-Patch wurde beim Start aktiv)
      if (currentPatch != null &&
          storedPatch != null &&
          currentPatch > storedPatch) {
        await _saveState(prefs, currentVersion, currentPatch);
        return UpdateConfirmationResult(
          type: UpdateConfirmationType.patch,
          previousPatch: storedPatch,
          currentPatch: currentPatch,
        );
      }

      // Ersten Start merken (kein Erfolgs-Banner, nur speichern)
      if (storedVersion == null) {
        await _saveState(prefs, currentVersion, currentPatch);
      }

      return UpdateConfirmationResult.none;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️  [UpdateConfirmationService] Check fehlgeschlagen: $e');
      }
      return UpdateConfirmationResult.none;
    }
  }

  /// Speichert die aktuelle Version + Patch-Nummer für den nächsten Vergleich.
  /// Wird auch nach erfolgreichem Patch-Download aufgerufen, damit der Download-
  /// Zähler korrekt hochgezählt wird.
  Future<void> saveCurrentState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int? currentPatch;
      if (_shorebird.isAvailable) {
        final next = await _shorebird.readNextPatch();
        currentPatch = next?.number;
      }
      await _saveState(prefs, UpdateService.currentAppVersion, currentPatch);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️  [UpdateConfirmationService] saveCurrentState fehlgeschlagen: $e');
      }
    }
  }

  Future<void> _saveState(
      SharedPreferences prefs, String version, int? patch) async {
    await prefs.setString(_keyVersion, version);
    if (patch != null) {
      await prefs.setInt(_keyPatch, patch);
    }
  }
}
