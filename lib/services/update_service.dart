// 🟢 UPDATE SERVICE – Steuert In-App-Update-Meldungen
//
// Zwei Modi:
//   1. Release-Update: Neue APK verfügbar (App-Version < latest in Supabase)
//      → Dialog mit Download-Link (user lädt + installiert APK manuell)
//   2. Patch-Ready: Shorebird-OTA-Patch wurde heruntergeladen, Restart nötig
//      → Snackbar/Dialog "App neu starten"
//
// Die aktuelle App-Version kommt via --dart-define=APP_VERSION=... beim Build.
// Fallback: lese aus pubspec (nicht zur Laufzeit) → String.fromEnvironment.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Ergebnis des Update-Checks
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

class UpdateService {
  UpdateService._();
  static final instance = UpdateService._();

  /// Aktuelle App-Version (Semver ohne Build-Nummer), gesetzt via dart-define.
  /// Beim Build: --dart-define=APP_VERSION=5.31.0
  static const String currentAppVersion =
      String.fromEnvironment('APP_VERSION', defaultValue: '0.0.0');

  final ShorebirdUpdater _shorebird = ShorebirdUpdater();

  /// Prüft Supabase `app_config` für Android und vergleicht mit [currentAppVersion].
  Future<UpdateCheckResult> checkReleaseUpdate() async {
    try {
      final row = await Supabase.instance.client
          .from('app_config')
          .select()
          .eq('platform', 'android')
          .maybeSingle();

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

  /// true = Shorebird hat einen Patch heruntergeladen, der beim nächsten
  /// App-Start aktiv wird.
  Future<bool> isPatchReady() async {
    try {
      if (!_shorebird.isAvailable) return false;
      final status = await _shorebird.readCurrentPatch();
      final next = await _shorebird.readNextPatch();
      // Patch wartet, wenn es einen `next` gibt, der nicht dem aktuellen entspricht.
      if (next == null) return false;
      if (status == null) return true;
      return next.number != status.number;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️  [UpdateService] Patch-Status-Check fehlgeschlagen: $e');
      }
      return false;
    }
  }

  /// Fragt Shorebird-Server aktiv nach neuem Patch (blockierend bis Download).
  /// Wird idR. vom Auto-Updater erledigt; hier nur als Trigger wenn die App
  /// länger offen ist.
  Future<void> checkAndDownloadPatch() async {
    try {
      if (!_shorebird.isAvailable) return;
      final status = await _shorebird.checkForUpdate();
      if (status == UpdateStatus.outdated) {
        await _shorebird.update();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️  [UpdateService] Patch-Download fehlgeschlagen: $e');
      }
    }
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
