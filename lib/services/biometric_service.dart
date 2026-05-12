import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      final already = await health.hasPermissions(_types,
              permissions: _permissions) ??
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
