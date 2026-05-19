// BiometricSyncService — Cache für Health/Fit-Daten (L6).
//
// MVP — schreibt manuelle Werte in den DB-Cache (via `record`). Echte
// HealthKit/Google-Fit-Sync braucht `health` Plugin (folgt). Der Cache
// erlaubt schon jetzt, biometric_data_cache als Quelle für Wellness-Tools
// (Soundscape-Adaption, Atem-Pacing etc.) zu nutzen.

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';

class BiometricSample {
  final String id;
  final String userId;
  final String metric; // 'heart_rate' | 'hrv' | 'sleep_score' | 'steps'
  final double value;
  final String unit;
  final String? source;
  final DateTime measuredAt;
  const BiometricSample({
    required this.id,
    required this.userId,
    required this.metric,
    required this.value,
    required this.unit,
    required this.source,
    required this.measuredAt,
  });

  factory BiometricSample.fromJson(Map<String, dynamic> j) => BiometricSample(
        id: j['id'] as String,
        userId: j['user_id'] as String? ?? '',
        metric: j['metric'] as String? ?? '',
        value: (j['value'] as num).toDouble(),
        unit: j['unit'] as String? ?? '',
        source: j['source'] as String?,
        measuredAt: DateTime.parse(j['measured_at'] as String),
      );
}

class BiometricSyncService {
  BiometricSyncService._();
  static final instance = BiometricSyncService._();

  SupabaseClient get _s => Supabase.instance.client;

  Future<bool> record({
    required String userId,
    required String metric,
    required double value,
    required String unit,
    String? source,
    DateTime? measuredAt,
  }) async {
    try {
      await _s.from('biometric_data_cache').insert({
        'user_id': userId,
        'metric': metric,
        'value': value,
        'unit': unit,
        'source': source ?? 'manual',
        'measured_at': (measuredAt ?? DateTime.now()).toIso8601String(),
      });
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Bio record: $e');
      return false;
    }
  }

  Future<List<BiometricSample>> latest({
    required String userId,
    required String metric,
    int limit = 50,
  }) async {
    try {
      final res = await _s
          .from('biometric_data_cache')
          .select()
          .eq('user_id', userId)
          .eq('metric', metric)
          .order('measured_at', ascending: false)
          .limit(limit);
      return (res as List)
          .map((r) =>
              BiometricSample.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Bio latest: $e');
      return const [];
    }
  }
}
