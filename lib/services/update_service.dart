// 🟢 UPDATE SERVICE – Steuert In-App-Update-Meldungen
//
// Zwei Modi:
//   1. Release-Update: Neue APK verfügbar (App-Version < latest in Supabase)
//      → Fullscreen-Screen mit Download-/Installer-Flow
//   2. Patch-Ready: Shorebird-OTA-Patch wurde heruntergeladen, Restart nötig
//      → Prominenter Fullscreen-Dialog "App jetzt schließen"
//
// Die aktuelle App-Version kommt via --dart-define=APP_VERSION=... beim Build.
// Fallback: String.fromEnvironment → '0.0.0' (Debug-Build). Bei '0.0.0' wird
// der Release-Check KOMPLETT übersprungen, damit lokale Debug-Builds nicht
// fälschlich einen Force-Update-Screen zeigen.

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Ergebnis des Release-Update-Checks (Supabase app_config vs. APP_VERSION).
class UpdateCheckResult {
  final bool releaseUpdateAvailable;
  final bool isForced;
  final String? latestVersion;
  final String? currentVersion;
  final String? apkDownloadUrl;
  final String? changelog;
  final String? releaseNotesUrl;

  const UpdateCheckResult({
    this.releaseUpdateAvailable = false,
    this.isForced = false,
    this.latestVersion,
    this.currentVersion,
    this.apkDownloadUrl,
    this.changelog,
    this.releaseNotesUrl,
  });

  static const empty = UpdateCheckResult();
}

/// Ergebnis des Patch-Checks (Shorebird).
/// [patchReady] = true ⇢ beim nächsten App-Start wird ein neuer Patch aktiv.
class PatchCheckResult {
  final bool patchReady;
  final int? currentPatchNumber;
  final int? nextPatchNumber;

  const PatchCheckResult({
    this.patchReady = false,
    this.currentPatchNumber,
    this.nextPatchNumber,
  });

  static const empty = PatchCheckResult();
}

class UpdateService {
  UpdateService._();
  static final instance = UpdateService._();

  /// Aktuelle App-Version (Semver ohne Build-Nummer), gesetzt via dart-define.
  /// Beim Build: --dart-define=APP_VERSION=5.35.0
  static const String currentAppVersion =
      String.fromEnvironment('APP_VERSION', defaultValue: '0.0.0');

  /// true wenn APP_VERSION nicht gesetzt wurde (lokaler Debug-Build).
  /// In diesem Fall werden Release-Checks übersprungen, damit nicht
  /// fälschlich ein Force-Update-Screen erscheint.
  bool get isVersionUnknown => currentAppVersion == '0.0.0';

  final ShorebirdUpdater _shorebird = ShorebirdUpdater();

  /// Broadcast-Stream: feuert wenn ein Patch heruntergeladen und installiert
  /// wurde und beim nächsten Start aktiv wird. Das UpdateGate hört hier zu
  /// und zeigt dann den prominenten [PatchReadyDialog].
  final StreamController<PatchCheckResult> _patchReadyController =
      StreamController<PatchCheckResult>.broadcast();

  Stream<PatchCheckResult> get onPatchReady => _patchReadyController.stream;

  /// Schneller Offline-Check bevor wir Supabase/Shorebird kontaktieren.
  /// Ohne Netz bekäme der User einen 5-10s Timeout und die App fühlt sich
  /// hängend an — das verhindern wir hier.
  /// Im Zweifel (Exception) geben wir `true` zurück, damit echte Calls
  /// versucht werden.
  Future<bool> _hasConnectivity() async {
    try {
      final results = await Connectivity().checkConnectivity();
      return results.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      return true;
    }
  }

  /// Prüft Supabase `app_config` für Android und vergleicht mit [currentAppVersion].
  /// Bei Debug-Builds (APP_VERSION='0.0.0') wird sofort empty zurückgegeben.
  Future<UpdateCheckResult> checkReleaseUpdate() async {
    // Debug-Build-Schutz: nie Force-Update in lokalen Builds zeigen.
    if (isVersionUnknown) {
      if (kDebugMode) {
        debugPrint('ℹ️  [UpdateService] APP_VERSION=0.0.0 → Release-Check übersprungen');
      }
      return UpdateCheckResult.empty;
    }

    // Offline-Schutz: kein Timeout-Hänger wenn kein Netz vorhanden.
    if (!await _hasConnectivity()) {
      if (kDebugMode) {
        debugPrint('ℹ️  [UpdateService] Kein Netz → Release-Check übersprungen');
      }
      return UpdateCheckResult.empty;
    }

    try {
      final row = await Supabase.instance.client
          .from('app_config')
          .select()
          .eq('platform', 'android')
          .maybeSingle()
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => null,
          );

      if (row == null) return UpdateCheckResult.empty;

      final latest = (row['latest_version'] as String?)?.trim();
      final minV = (row['min_version'] as String?)?.trim();
      final url = (row['apk_download_url'] as String?)?.trim();
      final changelog = row['changelog'] as String?;
      final notesUrl = row['release_notes_url'] as String?;

      if (latest == null || latest.isEmpty || url == null || url.isEmpty) {
        return UpdateCheckResult.empty;
      }

      final newer = _compareSemver(currentAppVersion, latest) < 0;
      if (!newer) return UpdateCheckResult.empty;

      final forced = minV != null &&
          minV.isNotEmpty &&
          _compareSemver(currentAppVersion, minV) < 0;

      return UpdateCheckResult(
        releaseUpdateAvailable: true,
        isForced: forced,
        latestVersion: latest,
        currentVersion: currentAppVersion,
        apkDownloadUrl: url,
        changelog: changelog,
        releaseNotesUrl: notesUrl,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️  [UpdateService] Release-Check fehlgeschlagen: $e');
      }
      return UpdateCheckResult.empty;
    }
  }

  /// Fragt Shorebird, ob ein Patch bereitliegt, der beim nächsten App-Start
  /// aktiv wird. Gibt ein [PatchCheckResult] zurück (mit Patch-Nummern),
  /// damit das UI Details anzeigen kann.
  Future<PatchCheckResult> checkPatchReady() async {
    try {
      if (!_shorebird.isAvailable) return PatchCheckResult.empty;
      final current = await _shorebird.readCurrentPatch();
      final next = await _shorebird.readNextPatch();
      // Patch wartet, wenn es einen `next` gibt, der nicht dem aktuellen entspricht.
      if (next == null) {
        return PatchCheckResult(currentPatchNumber: current?.number);
      }
      final ready = current == null || next.number != current.number;
      return PatchCheckResult(
        patchReady: ready,
        currentPatchNumber: current?.number,
        nextPatchNumber: next.number,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️  [UpdateService] Patch-Status-Check fehlgeschlagen: $e');
      }
      return PatchCheckResult.empty;
    }
  }

  /// Fragt Shorebird-Server aktiv nach neuem Patch (blockierend bis Download).
  /// Wird idR. vom Auto-Updater erledigt; hier nur als Trigger wenn die App
  /// länger offen ist. Nach erfolgreichem Download wird der Stream befeuert.
  Future<void> checkAndDownloadPatch() async {
    try {
      if (!_shorebird.isAvailable) return;
      // Offline-Schutz: ohne Netz kein Patch-Check.
      if (!await _hasConnectivity()) {
        if (kDebugMode) {
          debugPrint('ℹ️  [UpdateService] Kein Netz → Patch-Check übersprungen');
        }
        return;
      }
      final status = await _shorebird.checkForUpdate();
      if (status == UpdateStatus.outdated) {
        await _shorebird.update();
        // Nach erfolgreichem Download: Patch-Status prüfen und Listener benachrichtigen.
        final result = await checkPatchReady();
        if (result.patchReady && !_patchReadyController.isClosed) {
          _patchReadyController.add(result);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️  [UpdateService] Patch-Download fehlgeschlagen: $e');
      }
    }
  }

  /// Schließt den Stream. Wird idR. nicht aufgerufen (Singleton), steht aber
  /// für Tests zur Verfügung.
  void dispose() {
    _patchReadyController.close();
  }

  // ---------------------------------------------------------------------------
  // Semver-Vergleich (ohne Build-Nummer / Prerelease)
  // ---------------------------------------------------------------------------

  /// Gibt negativ zurück wenn [a] < [b], 0 bei Gleichheit, positiv wenn [a] > [b].
  static int _compareSemver(String a, String b) {
    final pa = _parseSemver(a);
    final pb = _parseSemver(b);
    for (var i = 0; i < 3; i++) {
      final d = pa[i] - pb[i];
      if (d != 0) return d;
    }
    return 0;
  }

  static List<int> _parseSemver(String v) {
    final clean = v.split('+').first.split('-').first;
    final parts = clean.split('.');
    return [
      if (parts.isNotEmpty) int.tryParse(parts[0]) ?? 0 else 0,
      if (parts.length > 1) int.tryParse(parts[1]) ?? 0 else 0,
      if (parts.length > 2) int.tryParse(parts[2]) ?? 0 else 0,
    ];
  }
}
