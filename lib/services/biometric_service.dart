import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart'
    if (dart.library.html) '../stubs/health_stub.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// 💓 BiometricService — Apple HealthKit + Android Health Connect bridge.
///
/// Reads heart rate and heart-rate-variability (HRV) before & after meditation
/// or breath sessions to compute a Wirkungs-Score (effectiveness score).
///
/// Usage:
/// ```dart
/// final svc = BiometricService();
/// if (await svc.requestPermissions()) {
///   final comparison = await svc.measureSessionEffect(
///     sessionStart: DateTime.now().subtract(const Duration(minutes: 15)),
///     sessionEnd: DateTime.now(),
///   );
///   print('Score: ${comparison.effectivenessScore}%');
/// }
/// ```
class BiometricService {
  /// The `health` package replaced the old `HealthFactory` with a singleton
  /// `Health()`. We expose it under the historic name so call-sites match the
  /// AUFGABE 6 spec.
  final Health health = Health();

  static const List<HealthDataType> _types = [
    HealthDataType.HEART_RATE,
    HealthDataType.HEART_RATE_VARIABILITY_SDNN,
    HealthDataType.RESTING_HEART_RATE,
  ];

  static const List<HealthDataAccess> _permissions = [
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
  ];

  bool _configured = false;

  /// Initialises the underlying Health platform channel.
  /// Safe to call multiple times.
  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await health.configure();
    _configured = true;
  }

  /// Requests READ permissions for heart rate and HRV.
  ///
  /// Returns `true` when the user granted permissions, `false` otherwise.
  /// On platforms where Health is unsupported (web / desktop) this returns
  /// `false` without throwing — callers should treat the absence of biometric
  /// data as a normal degraded path.
  Future<bool> requestPermissions() async {
    try {
      await _ensureConfigured();
      final already =
          await health.hasPermissions(_types, permissions: _permissions) ??
              false;
      if (already) return true;
      return await health.requestAuthorization(
        _types,
        permissions: _permissions,
      );
    } catch (e, st) {
      debugPrint('BiometricService.requestPermissions failed: $e\n$st');
      return false;
    }
  }

  /// Detaillierte Diagnose des Health-Setups.
  ///
  /// Liefert einen [HealthDiagnosis]-Snapshot zurück, der erklärt warum
  /// Health-Reading aktuell (nicht) funktioniert — inklusive empfohlener
  /// User-Action ([HealthFixAction]).
  ///
  /// Sicher auf allen Plattformen aufrufbar: Web/Desktop liefert
  /// [HealthFixAction.webNotSupported], iOS-Web/Desktop ohne Plugin liefert
  /// [HealthFixAction.iosBuildMissing].
  Future<HealthDiagnosis> diagnose() async {
    // ─── 1) Web/Desktop früh herausfiltern ────────────────────────
    if (kIsWeb) {
      return const HealthDiagnosis(
        isPluginAvailable: false,
        isHealthConnectInstalled: false,
        permissionStatus: HealthPermissionStatus.unknown,
        hasAnyDataSource: false,
        detectedDataSources: <String>[],
        latestSampleAt: null,
        summary:
            'Health-Reading ist im Browser nicht verfügbar — bitte die mobile App nutzen.',
        recommendedAction: HealthFixAction.webNotSupported,
      );
    }
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return const HealthDiagnosis(
        isPluginAvailable: false,
        isHealthConnectInstalled: false,
        permissionStatus: HealthPermissionStatus.unknown,
        hasAnyDataSource: false,
        detectedDataSources: <String>[],
        latestSampleAt: null,
        summary: 'Health-Reading ist auf dieser Plattform nicht verfügbar.',
        recommendedAction: HealthFixAction.webNotSupported,
      );
    }

    // ─── 2) Plugin konfigurieren ──────────────────────────────────
    bool pluginAvailable = true;
    try {
      await _ensureConfigured();
    } catch (e, st) {
      debugPrint('BiometricService.diagnose configure failed: $e\n$st');
      pluginAvailable = false;
    }

    // iOS ohne Build/Plugin -> klar kommunizieren
    if (!pluginAvailable && defaultTargetPlatform == TargetPlatform.iOS) {
      return const HealthDiagnosis(
        isPluginAvailable: false,
        isHealthConnectInstalled: true,
        permissionStatus: HealthPermissionStatus.unknown,
        hasAnyDataSource: false,
        detectedDataSources: <String>[],
        latestSampleAt: null,
        summary: 'Apple HealthKit erfordert einen iOS-Build — bald verfügbar.',
        recommendedAction: HealthFixAction.iosBuildMissing,
      );
    }
    if (!pluginAvailable && defaultTargetPlatform == TargetPlatform.android) {
      // Plugin-Channel selbst nicht erreichbar — sehr selten, meist deutet das
      // auf eine fehlende Health-Connect-Provider-App hin.
      return const HealthDiagnosis(
        isPluginAvailable: false,
        isHealthConnectInstalled: false,
        permissionStatus: HealthPermissionStatus.unknown,
        hasAnyDataSource: false,
        detectedDataSources: <String>[],
        latestSampleAt: null,
        summary:
            'Health Connect ist nicht erreichbar — bitte aus dem Play Store hinzufügen.',
        recommendedAction: HealthFixAction.installHealthConnect,
      );
    }

    // ─── 3) Health Connect Installations-Status (Android) ─────────
    bool hcInstalled = defaultTargetPlatform == TargetPlatform.iOS;
    if (defaultTargetPlatform == TargetPlatform.android) {
      hcInstalled = await _isHealthConnectInstalled();
      if (!hcInstalled) {
        return const HealthDiagnosis(
          isPluginAvailable: true,
          isHealthConnectInstalled: false,
          permissionStatus: HealthPermissionStatus.unknown,
          hasAnyDataSource: false,
          detectedDataSources: <String>[],
          latestSampleAt: null,
          summary:
              'Health Connect ist nicht installiert — bitte aus dem Play Store hinzufügen.',
          recommendedAction: HealthFixAction.installHealthConnect,
        );
      }
    }

    // ─── 4) Permission-Status prüfen ──────────────────────────────
    HealthPermissionStatus permState = HealthPermissionStatus.unknown;
    try {
      final p = await health.hasPermissions(_types, permissions: _permissions);
      if (p == true) {
        permState = HealthPermissionStatus.granted;
      } else if (p == false) {
        permState = HealthPermissionStatus.notGranted;
      } else {
        permState = HealthPermissionStatus.unknown;
      }
    } catch (e) {
      debugPrint('BiometricService.diagnose hasPermissions failed: $e');
      permState = HealthPermissionStatus.unknown;
    }

    if (permState != HealthPermissionStatus.granted) {
      return HealthDiagnosis(
        isPluginAvailable: true,
        isHealthConnectInstalled: hcInstalled,
        permissionStatus: permState,
        hasAnyDataSource: false,
        detectedDataSources: const <String>[],
        latestSampleAt: null,
        summary: permState == HealthPermissionStatus.notGranted
            ? 'Health-Berechtigung wurde verweigert — bitte in Health Connect erlauben.'
            : 'Health-Berechtigung wurde noch nicht erteilt.',
        recommendedAction: permState == HealthPermissionStatus.notGranted
            ? HealthFixAction.openHealthConnectSettings
            : HealthFixAction.grantPermission,
      );
    }

    // ─── 5) Daten-Quellen prüfen (HR letzte 7 Tage) ───────────────
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    List<HealthDataPoint> points = const [];
    try {
      points = await health.getHealthDataFromTypes(
        types: const [HealthDataType.HEART_RATE],
        startTime: weekAgo,
        endTime: now,
      );
    } catch (e) {
      debugPrint('BiometricService.diagnose getHealthDataFromTypes failed: $e');
    }

    final sources = <String>{};
    DateTime? latest;
    for (final p in points) {
      final name = _extractSourceName(p);
      if (name != null && name.isNotEmpty) sources.add(name);
      if (latest == null || p.dateTo.isAfter(latest)) latest = p.dateTo;
    }

    if (points.isEmpty) {
      return HealthDiagnosis(
        isPluginAvailable: true,
        isHealthConnectInstalled: hcInstalled,
        permissionStatus: HealthPermissionStatus.granted,
        hasAnyDataSource: false,
        detectedDataSources: const <String>[],
        latestSampleAt: null,
        summary:
            'Keine Herzfrequenz-Daten gefunden — bitte eine Smartwatch oder Fitness-App verbinden.',
        recommendedAction: HealthFixAction.connectDataSource,
      );
    }

    final sortedSources = sources.toList()..sort();
    return HealthDiagnosis(
      isPluginAvailable: true,
      isHealthConnectInstalled: hcInstalled,
      permissionStatus: HealthPermissionStatus.granted,
      hasAnyDataSource: true,
      detectedDataSources: List.unmodifiable(sortedSources),
      latestSampleAt: latest,
      summary: sortedSources.isEmpty
          ? 'Alles bereit — Herzfrequenz-Daten sind verfügbar.'
          : 'Alles bereit — Quelle: ${sortedSources.join(", ")}.',
      recommendedAction: HealthFixAction.allOk,
    );
  }

  /// Best-effort check: ist Health Connect (Android-Provider-App) installiert?
  ///
  /// Versucht in dieser Reihenfolge:
  ///  1. `health.getHealthConnectSdkStatus()` (API ≥ 13.x)
  ///  2. Fallback: leeren `hasPermissions`-Call — wirft auf nicht-installiertem
  ///     Health Connect i.d.R. eine PlatformException.
  Future<bool> _isHealthConnectInstalled() async {
    // 1) preferred API
    try {
      final status = await health.getHealthConnectSdkStatus();
      // Health Connect's enum surfaces a `sdkAvailable` variant; we compare
      // by string to stay resilient against minor enum renames between
      // health-package versions.
      final s = status.toString().toLowerCase();
      if (s.contains('sdkavailable') && !s.contains('updaterequired')) {
        return true;
      }
      // Provider exists but needs an update — still treat as installed so the
      // user is nudged via the permission flow (Play Store deeplink) rather
      // than the install dialog.
      if (s.contains('updaterequired')) return true;
      return false;
    } catch (_) {
      // fall through
    }
    // 2) heuristic fallback
    try {
      await health.hasPermissions(_types, permissions: _permissions);
      return true;
    } catch (e) {
      debugPrint('BiometricService._isHealthConnectInstalled fallback: $e');
      return false;
    }
  }

  String? _extractSourceName(HealthDataPoint point) {
    try {
      if (point.sourceName.isNotEmpty) return point.sourceName;
    } catch (_) {}
    try {
      if (point.sourceId.isNotEmpty) return point.sourceId;
    } catch (_) {}
    return null;
  }

  /// Versucht Health Connect via Play-Store-Deeplink zu installieren.
  ///
  /// - **Android:** öffnet den Play-Store-Eintrag der Provider-App.
  /// - **Sonst:** no-op, gibt `false` zurück.
  Future<bool> openInstallHealthConnect() async {
    if (kIsWeb) return false;
    if (defaultTargetPlatform != TargetPlatform.android) return false;

    // 1) preferred: das Plugin macht es selbst (Deeplink + Fallback)
    try {
      await health.installHealthConnect();
      return true;
    } catch (e) {
      debugPrint('BiometricService.openInstallHealthConnect plugin: $e');
    }

    // 2) Fallback: url_launcher
    const marketUri = 'market://details?id=com.google.android.apps.healthdata';
    const webUri =
        'https://play.google.com/store/apps/details?id=com.google.android.apps.healthdata';
    try {
      final m = Uri.parse(marketUri);
      if (await canLaunchUrl(m)) {
        return launchUrl(m, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('BiometricService.openInstallHealthConnect market: $e');
    }
    try {
      return launchUrl(Uri.parse(webUri), mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('BiometricService.openInstallHealthConnect web: $e');
      return false;
    }
  }

  /// Öffnet die Health-Connect-Einstellungen (Permissions + Datenquellen).
  ///
  /// Best-effort über Plugin-API → Custom-Intent-Deeplink → App-Detail-Page.
  Future<bool> openHealthConnectSettings() async {
    if (kIsWeb) return false;
    if (defaultTargetPlatform != TargetPlatform.android) return false;

    // Deeplink-Versuche.
    final uris = <String>[
      // Direkt in die Health-Connect-Einstellungen springen.
      // 'androidx.health.ACTION_HEALTH_CONNECT_SETTINGS' kann nur via
      // intent:// gestartet werden — wir nutzen den Play-Store-Eintrag als
      // robusten Universal-Fallback wenn Intent-Deeplinks blockiert sind.
      'package:com.google.android.apps.healthdata',
      'market://details?id=com.google.android.apps.healthdata',
      'https://play.google.com/store/apps/details?id=com.google.android.apps.healthdata',
    ];
    for (final u in uris) {
      try {
        final parsed = Uri.parse(u);
        if (await canLaunchUrl(parsed)) {
          return launchUrl(parsed, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        debugPrint('BiometricService.openHealthConnectSettings $u failed: $e');
      }
    }
    return false;
  }

  /// Reads the most recent resting heart-rate value within [since].
  ///
  /// Returns `null` if no data point is available or the user has not granted
  /// permission. Falls back to the latest HEART_RATE sample if no
  /// RESTING_HEART_RATE points exist in the window.
  Future<double?> getRestingHeartRate({
    Duration since = const Duration(hours: 24),
  }) async {
    try {
      await _ensureConfigured();
      final now = DateTime.now();
      final start = now.subtract(since);

      // Try RESTING_HEART_RATE first
      final resting = await health.getHealthDataFromTypes(
        types: const [HealthDataType.RESTING_HEART_RATE],
        startTime: start,
        endTime: now,
      );
      final latestResting = _latestNumeric(resting);
      if (latestResting != null) return latestResting;

      // Fallback to plain HEART_RATE
      final hr = await health.getHealthDataFromTypes(
        types: const [HealthDataType.HEART_RATE],
        startTime: start,
        endTime: now,
      );
      return _latestNumeric(hr);
    } catch (e, st) {
      debugPrint('BiometricService.getRestingHeartRate failed: $e\n$st');
      return null;
    }
  }

  /// Reads the most recent HRV (SDNN, in milliseconds) within [since].
  ///
  /// Returns `null` if no data point is available or the user has not granted
  /// permission.
  Future<double?> getHRV({
    Duration since = const Duration(hours: 24),
  }) async {
    try {
      await _ensureConfigured();
      final now = DateTime.now();
      final start = now.subtract(since);
      final hrv = await health.getHealthDataFromTypes(
        types: const [HealthDataType.HEART_RATE_VARIABILITY_SDNN],
        startTime: start,
        endTime: now,
      );
      return _latestNumeric(hrv);
    } catch (e, st) {
      debugPrint('BiometricService.getHRV failed: $e\n$st');
      return null;
    }
  }

  /// Reads the **mean** heart rate measured between [start] and [end].
  /// Used for the per-session "during"-window — typically a 2-minute pre/post
  /// measurement.
  Future<double?> _meanHeartRateBetween(DateTime start, DateTime end) async {
    try {
      await _ensureConfigured();
      final points = await health.getHealthDataFromTypes(
        types: const [HealthDataType.HEART_RATE],
        startTime: start,
        endTime: end,
      );
      return _meanNumeric(points);
    } catch (e) {
      debugPrint('BiometricService._meanHeartRateBetween failed: $e');
      return null;
    }
  }

  /// Reads the **mean** HRV (SDNN ms) measured between [start] and [end].
  Future<double?> _meanHrvBetween(DateTime start, DateTime end) async {
    try {
      await _ensureConfigured();
      final points = await health.getHealthDataFromTypes(
        types: const [HealthDataType.HEART_RATE_VARIABILITY_SDNN],
        startTime: start,
        endTime: end,
      );
      return _meanNumeric(points);
    } catch (e) {
      debugPrint('BiometricService._meanHrvBetween failed: $e');
      return null;
    }
  }

  /// High-level helper: measures the biometric delta around a session window.
  ///
  /// The function reads HR + HRV from a `windowMinutes` window BEFORE
  /// [sessionStart] and AFTER [sessionEnd] (default 2 minutes each), then
  /// computes the resulting [BiometricComparison].
  ///
  /// Both `sessionStart` and `sessionEnd` default to "now" pairs that produce
  /// a useful baseline when called directly without arguments — but for real
  /// sessions you should pass the actual timestamps.
  Future<BiometricComparison> measureSessionEffect({
    DateTime? sessionStart,
    DateTime? sessionEnd,
    Duration windowBefore = const Duration(minutes: 2),
    Duration windowAfter = const Duration(minutes: 2),
  }) async {
    final start = sessionStart ?? DateTime.now();
    final end = sessionEnd ?? DateTime.now();

    final hrBefore =
        await _meanHeartRateBetween(start.subtract(windowBefore), start);
    final hrAfter = await _meanHeartRateBetween(end, end.add(windowAfter));
    final hrvBefore =
        await _meanHrvBetween(start.subtract(windowBefore), start);
    final hrvAfter = await _meanHrvBetween(end, end.add(windowAfter));

    final cmp = BiometricComparison(
      hrvBefore: hrvBefore,
      hrvAfter: hrvAfter,
      heartRateBefore: hrBefore,
      heartRateAfter: hrAfter,
      effectivenessScore: 0,
      sessionStart: start,
      sessionEnd: end,
    );
    return cmp.copyWith(
      effectivenessScore: calculateEffectivenessScore(cmp),
    );
  }

  /// Computes the Wirkungs-Score:
  ///
  ///   `((hrvAfter - hrvBefore) / hrvBefore) * 100`
  ///
  /// Returns `0.0` if either value is `null`, zero, or non-finite. Positive
  /// values indicate HRV gain (parasympathetic recovery → effective session),
  /// negative values indicate HRV loss.
  double calculateEffectivenessScore(BiometricComparison data) {
    final before = data.hrvBefore;
    final after = data.hrvAfter;
    if (before == null || after == null) return 0.0;
    if (before <= 0) return 0.0;
    final score = ((after - before) / before) * 100.0;
    if (!score.isFinite) return 0.0;
    // Clamp to a sensible UI range
    return score.clamp(-100.0, 500.0).toDouble();
  }

  /// Persists a measurement into the `biometric_readings` table.
  /// Silently no-ops when the user is logged out (graceful degradation).
  Future<void> saveReading({
    required String sessionType,
    String? sessionWorld,
    required BiometricComparison data,
    int? durationMinutes,
    String? notes,
  }) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      await Supabase.instance.client.from('biometric_readings').insert({
        'user_id': user.id,
        'session_type': sessionType,
        'session_world': sessionWorld,
        'hrv_before': data.hrvBefore,
        'hrv_after': data.hrvAfter,
        'hr_before': data.heartRateBefore,
        'hr_after': data.heartRateAfter,
        'effectiveness_score': data.effectivenessScore,
        'duration_minutes': durationMinutes,
        'notes': notes,
      });
    } catch (e, st) {
      debugPrint('BiometricService.saveReading failed: $e\n$st');
    }
  }

  // ─── helpers ─────────────────────────────────────────────────

  double? _latestNumeric(List<HealthDataPoint> points) {
    if (points.isEmpty) return null;
    points.sort((a, b) => b.dateTo.compareTo(a.dateTo));
    final v = points.first.value;
    if (v is NumericHealthValue) return v.numericValue.toDouble();
    return null;
  }

  double? _meanNumeric(List<HealthDataPoint> points) {
    if (points.isEmpty) return null;
    final values = points
        .map((p) => p.value)
        .whereType<NumericHealthValue>()
        .map((v) => v.numericValue.toDouble())
        .toList();
    if (values.isEmpty) return null;
    final sum = values.reduce((a, b) => a + b);
    return sum / values.length;
  }
}

/// Immutable result of a before/after biometric comparison.
@immutable
class BiometricComparison {
  final double? hrvBefore;
  final double? hrvAfter;
  final double? heartRateBefore;
  final double? heartRateAfter;
  final double effectivenessScore;
  final DateTime sessionStart;
  final DateTime sessionEnd;

  const BiometricComparison({
    required this.hrvBefore,
    required this.hrvAfter,
    required this.heartRateBefore,
    required this.heartRateAfter,
    required this.effectivenessScore,
    required this.sessionStart,
    required this.sessionEnd,
  });

  /// Whether at least one HRV value is missing — UI should fall back to a
  /// "no biometric data" message.
  bool get hasHrvData => hrvBefore != null && hrvAfter != null;

  /// Whether at least one heart-rate value is missing.
  bool get hasHrData => heartRateBefore != null && heartRateAfter != null;

  /// Whether any biometric data was captured at all.
  bool get hasAnyData => hasHrvData || hasHrData;

  /// Heart rate delta as percentage (negative = HR dropped → calming).
  double? get heartRateDeltaPct {
    if (heartRateBefore == null ||
        heartRateAfter == null ||
        heartRateBefore == 0) {
      return null;
    }
    return ((heartRateAfter! - heartRateBefore!) / heartRateBefore!) * 100.0;
  }

  /// HRV delta as percentage (positive = HRV rose → parasympathetic gain).
  double? get hrvDeltaPct {
    if (hrvBefore == null || hrvAfter == null || hrvBefore == 0) return null;
    return ((hrvAfter! - hrvBefore!) / hrvBefore!) * 100.0;
  }

  BiometricComparison copyWith({
    double? hrvBefore,
    double? hrvAfter,
    double? heartRateBefore,
    double? heartRateAfter,
    double? effectivenessScore,
    DateTime? sessionStart,
    DateTime? sessionEnd,
  }) {
    return BiometricComparison(
      hrvBefore: hrvBefore ?? this.hrvBefore,
      hrvAfter: hrvAfter ?? this.hrvAfter,
      heartRateBefore: heartRateBefore ?? this.heartRateBefore,
      heartRateAfter: heartRateAfter ?? this.heartRateAfter,
      effectivenessScore: effectivenessScore ?? this.effectivenessScore,
      sessionStart: sessionStart ?? this.sessionStart,
      sessionEnd: sessionEnd ?? this.sessionEnd,
    );
  }

  Map<String, dynamic> toJson() => {
        'hrv_before': hrvBefore,
        'hrv_after': hrvAfter,
        'hr_before': heartRateBefore,
        'hr_after': heartRateAfter,
        'effectiveness_score': effectivenessScore,
        'session_start': sessionStart.toIso8601String(),
        'session_end': sessionEnd.toIso8601String(),
      };
}

/// Permission status for the Health platform.
enum HealthPermissionStatus { granted, notGranted, unknown }

/// Concrete remediation step a user can take to make Health-Reading work.
enum HealthFixAction {
  /// Everything is fine — reading works.
  allOk,

  /// Android Provider App (Health Connect) is missing → install from Play Store.
  installHealthConnect,

  /// Permissions never granted → show the system permission dialog.
  grantPermission,

  /// Permissions were explicitly denied → user must adjust them in Settings.
  openHealthConnectSettings,

  /// Permissions OK but no data source emits HR samples → connect a watch /
  /// fitness app.
  connectDataSource,

  /// iOS-only feature, but the current build is not an iOS build yet.
  iosBuildMissing,

  /// Running on Web / unsupported desktop → no Health platform exists.
  webNotSupported,
}

/// Structured diagnostic snapshot of the Health setup, produced by
/// [BiometricService.diagnose]. Designed to power user-friendly error dialogs.
@immutable
class HealthDiagnosis {
  /// Whether the underlying Health plugin could be initialised at all.
  final bool isPluginAvailable;

  /// Android: whether the Health Connect provider app is installed.
  /// iOS: always `true` (HealthKit is part of the OS).
  /// Web / unsupported: `false`.
  final bool isHealthConnectInstalled;

  /// Current permission state for the configured READ scopes.
  final HealthPermissionStatus permissionStatus;

  /// `true` when at least one HR data point was found in the last 7 days.
  final bool hasAnyDataSource;

  /// Unique source names (`Galaxy Watch 6`, `Samsung Health`, `Google Fit`,
  /// `Fitbit`, …) extracted from the HR samples.
  final List<String> detectedDataSources;

  /// Timestamp of the most recent HR sample (if any).
  final DateTime? latestSampleAt;

  /// Human-readable 1-sentence status — safe to surface as dialog body.
  final String summary;

  /// The action the user can take to resolve / advance the situation.
  final HealthFixAction recommendedAction;

  const HealthDiagnosis({
    required this.isPluginAvailable,
    required this.isHealthConnectInstalled,
    required this.permissionStatus,
    required this.hasAnyDataSource,
    required this.detectedDataSources,
    required this.latestSampleAt,
    required this.summary,
    required this.recommendedAction,
  });

  /// ISO 8601 helper for serialisation / debug overlays.
  String? get latestSampleTimestamp => latestSampleAt?.toIso8601String();

  bool get isReady =>
      recommendedAction == HealthFixAction.allOk &&
      permissionStatus == HealthPermissionStatus.granted &&
      hasAnyDataSource;

  @override
  String toString() =>
      'HealthDiagnosis(action: $recommendedAction, perm: $permissionStatus, '
      'sources: $detectedDataSources, latest: $latestSampleAt)';
}
