// PropagandaBiasHistoryService — Trend-Daten pro Quelle (C3).
//
// Jeder Propaganda-Detector-Check schreibt einen Eintrag pro Domain.
// Liste-API gibt sortierte Reihe (älteste → neueste) für Line-Charts.

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';

class BiasHistoryPoint {
  final DateTime time;
  final double bias;
  final double? reliability;
  const BiasHistoryPoint({
    required this.time,
    required this.bias,
    this.reliability,
  });
}

class PropagandaBiasHistoryService {
  PropagandaBiasHistoryService._();
  static final instance = PropagandaBiasHistoryService._();

  SupabaseClient get _s => Supabase.instance.client;

  Future<void> record({
    required String domain,
    required double bias,
    double? reliability,
    String? userId,
    Map<String, dynamic>? details,
  }) async {
    try {
      await _s.from('propaganda_bias_history').insert({
        'source_domain': domain.toLowerCase(),
        'bias_score': bias.clamp(-1.0, 1.0),
        'reliability': reliability?.clamp(0.0, 1.0),
        'user_id': userId,
        'details': details ?? {},
      });
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ BiasHistory record: $e');
    }
  }

  Future<List<BiasHistoryPoint>> getHistory(String domain,
      {int limit = 100}) async {
    try {
      final res = await _s
          .from('propaganda_bias_history')
          .select('created_at,bias_score,reliability')
          .eq('source_domain', domain.toLowerCase())
          .order('created_at', ascending: true)
          .limit(limit);
      return (res as List).map((r) {
        final m = Map<String, dynamic>.from(r as Map);
        return BiasHistoryPoint(
          time: DateTime.parse(m['created_at'] as String),
          bias: (m['bias_score'] as num).toDouble(),
          reliability: (m['reliability'] as num?)?.toDouble(),
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ BiasHistory get: $e');
      return const [];
    }
  }
}
