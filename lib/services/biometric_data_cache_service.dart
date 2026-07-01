// BiometricDataCacheService -- laedt, cached und aggregiert Biometrie-Daten
// (Herzfrequenz + Herzfrequenzvariabilitaet) aus der Supabase-Tabelle
// `biometric_readings` fuer die Biometrie-Analyse (Issue #442).
//
// Die Rohdaten werden pro Session vom Biofeedback-System geschrieben
// (health-Plugin: Apple HealthKit / Android Health Connect). Dieser Service
// liest sie mit dem Anon-Key unter RLS (auth.uid() = user_id), haelt sie im
// Speicher vor und berechnet daraus die Kennzahlen fuer die Diagramme.
//
// Die Aggregations-Logik ([BiometricSummary.fromReadings]) ist rein und ohne
// Netzwerk testbar -- siehe test/biometric_data_cache_service_test.dart.

import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Ein einzelner Biometrie-Datensatz (eine Session).
///
/// Plain Dart class mit `final`-Feldern statt Named Record (dart2js-Regel).
class BiometricReading {
  final String id;
  final String sessionType;
  final String? sessionWorld;
  final double? hrvBefore;
  final double? hrvAfter;
  final double? hrBefore;
  final double? hrAfter;
  final double? effectivenessScore;
  final int? durationMinutes;
  final String? notes;
  final DateTime createdAt;

  const BiometricReading({
    required this.id,
    required this.sessionType,
    required this.sessionWorld,
    required this.hrvBefore,
    required this.hrvAfter,
    required this.hrBefore,
    required this.hrAfter,
    required this.effectivenessScore,
    required this.durationMinutes,
    required this.notes,
    required this.createdAt,
  });

  factory BiometricReading.fromJson(Map<String, dynamic> j) => BiometricReading(
    id: j['id'] as String? ?? '',
    sessionType: j['session_type'] as String? ?? 'session',
    sessionWorld: j['session_world'] as String?,
    hrvBefore: _toDouble(j['hrv_before']),
    hrvAfter: _toDouble(j['hrv_after']),
    hrBefore: _toDouble(j['hr_before']),
    hrAfter: _toDouble(j['hr_after']),
    effectivenessScore: _toDouble(j['effectiveness_score']),
    durationMinutes: (j['duration_minutes'] as num?)?.toInt(),
    notes: j['notes'] as String?,
    createdAt:
        DateTime.tryParse(j['created_at'] as String? ?? '') ?? DateTime.now(),
  );

  /// Bevorzugt den Nachher-Wert (Ist-Zustand), faellt auf Vorher zurueck.
  double? get hrEffective => hrAfter ?? hrBefore;
  double? get hrvEffective => hrvAfter ?? hrvBefore;

  /// Delta der Herzfrequenz ueber die Session (negativ = beruhigend).
  double? get hrDelta =>
      (hrBefore != null && hrAfter != null) ? hrAfter! - hrBefore! : null;

  /// Delta der HRV ueber die Session (positiv = mehr Erholung/Kohaerenz).
  double? get hrvDelta =>
      (hrvBefore != null && hrvAfter != null) ? hrvAfter! - hrvBefore! : null;

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}

/// Aggregierte Kennzahlen ueber eine Liste von [BiometricReading]s.
///
/// Rein funktional aufgebaut ([fromReadings]) -- keine Netzwerk-Zugriffe,
/// damit die Analyse-Kernlogik isoliert testbar bleibt.
class BiometricSummary {
  final int count;
  final double? avgHr;
  final double? avgHrv;
  final double? minHr;
  final double? maxHr;
  final double? minHrv;
  final double? maxHrv;

  /// Trend = juengster Wert minus aeltester Wert (chronologisch).
  final double? hrTrend;
  final double? hrvTrend;
  final double? avgEffectiveness;

  const BiometricSummary({
    required this.count,
    required this.avgHr,
    required this.avgHrv,
    required this.minHr,
    required this.maxHr,
    required this.minHrv,
    required this.maxHrv,
    required this.hrTrend,
    required this.hrvTrend,
    required this.avgEffectiveness,
  });

  static const BiometricSummary empty = BiometricSummary(
    count: 0,
    avgHr: null,
    avgHrv: null,
    minHr: null,
    maxHr: null,
    minHrv: null,
    maxHrv: null,
    hrTrend: null,
    hrvTrend: null,
    avgEffectiveness: null,
  );

  bool get hasData => count > 0;

  /// Berechnet die Kennzahlen. [readings] darf in beliebiger Reihenfolge
  /// vorliegen -- Trends werden intern chronologisch (alt -> neu) bestimmt.
  factory BiometricSummary.fromReadings(List<BiometricReading> readings) {
    if (readings.isEmpty) return empty;

    final chrono = List<BiometricReading>.from(readings)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final hr = chrono
        .map((r) => r.hrEffective)
        .whereType<double>()
        .toList(growable: false);
    final hrv = chrono
        .map((r) => r.hrvEffective)
        .whereType<double>()
        .toList(growable: false);
    final eff = chrono
        .map((r) => r.effectivenessScore)
        .whereType<double>()
        .toList(growable: false);

    return BiometricSummary(
      count: chrono.length,
      avgHr: _avg(hr),
      avgHrv: _avg(hrv),
      minHr: _minOrNull(hr),
      maxHr: _maxOrNull(hr),
      minHrv: _minOrNull(hrv),
      maxHrv: _maxOrNull(hrv),
      hrTrend: _trend(hr),
      hrvTrend: _trend(hrv),
      avgEffectiveness: _avg(eff),
    );
  }

  static double? _avg(List<double> values) {
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  static double? _minOrNull(List<double> values) =>
      values.isEmpty ? null : values.reduce(math.min);

  static double? _maxOrNull(List<double> values) =>
      values.isEmpty ? null : values.reduce(math.max);

  static double? _trend(List<double> values) =>
      values.length < 2 ? null : values.last - values.first;
}

/// Laedt und cached Biometrie-Daten fuer die Analyse-Ansicht.
class BiometricDataCacheService {
  BiometricDataCacheService._();
  static final BiometricDataCacheService instance =
      BiometricDataCacheService._();

  SupabaseClient get _s => Supabase.instance.client;

  List<BiometricReading> _cache = const [];
  DateTime? _cachedAt;
  String? _cachedUserId;

  /// TTL fuer den In-Memory-Cache. Analyse-Screen liest oft mehrfach hinter-
  /// einander -- ein kurzer Cache spart Requests, ohne alt zu wirken.
  static const Duration _ttl = Duration(minutes: 2);

  /// Zuletzt geladene Daten (kann leer sein). Kein Netzwerk-Zugriff.
  List<BiometricReading> get cached => _cache;

  /// Laedt die letzten [limit] Biometrie-Datensaetze des Users.
  ///
  /// [forceRefresh] umgeht den TTL-Cache (z.B. Pull-to-Refresh).
  Future<List<BiometricReading>> loadReadings(
    String userId, {
    int limit = 90,
    bool forceRefresh = false,
  }) async {
    if (userId.isEmpty) return const [];

    final fresh =
        _cachedAt != null &&
        _cachedUserId == userId &&
        DateTime.now().difference(_cachedAt!) < _ttl;
    if (!forceRefresh && fresh) return _cache;

    try {
      final res = await _s
          .from('biometric_readings')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);
      final list = (res as List)
          .map(
            (r) =>
                BiometricReading.fromJson(Map<String, dynamic>.from(r as Map)),
          )
          .toList();
      _cache = list;
      _cachedAt = DateTime.now();
      _cachedUserId = userId;
      return list;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Biometrie laden: $e');
      // Bei Fehler den letzten Cache zurueckgeben statt hart zu scheitern.
      return _cache;
    }
  }

  /// Convenience: laedt + aggregiert in einem Schritt.
  Future<BiometricSummary> loadSummary(
    String userId, {
    int limit = 90,
    bool forceRefresh = false,
  }) async {
    final readings = await loadReadings(
      userId,
      limit: limit,
      forceRefresh: forceRefresh,
    );
    return BiometricSummary.fromReadings(readings);
  }

  /// Verwirft den Cache (z.B. nach Logout).
  void clear() {
    _cache = const [];
    _cachedAt = null;
    _cachedUserId = null;
  }
}
