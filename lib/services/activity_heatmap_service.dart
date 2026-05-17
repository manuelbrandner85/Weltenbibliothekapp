// ActivityHeatmapService — Aktivitäts-Heatmap pro Welt × Stunde (M2).
//
// Aggregiert chat_messages der letzten 7 Tage, gruppiert nach Welt
// (via room_id-Prefix) und Stunde-of-Day. Liefert eine Matrix die im
// Admin-Dashboard als Heatmap angezeigt werden kann.

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';

class ActivityHeatmap {
  /// world → [24 Counter pro Stunde]
  final Map<String, List<int>> data;
  final int totalMessages;
  final DateTime fromTime;
  const ActivityHeatmap({
    required this.data,
    required this.totalMessages,
    required this.fromTime,
  });
}

class ActivityHeatmapService {
  ActivityHeatmapService._();
  static final instance = ActivityHeatmapService._();

  static const _worlds = ['materie', 'energie', 'vorhang', 'ursprung'];

  Future<ActivityHeatmap> compute({int days = 7}) async {
    final since = DateTime.now().subtract(Duration(days: days));
    try {
      final res = await Supabase.instance.client
          .from('chat_messages')
          .select('room_id,created_at')
          .gte('created_at', since.toUtc().toIso8601String())
          .limit(5000);

      final data = <String, List<int>>{
        for (final w in _worlds) w: List<int>.filled(24, 0),
      };
      int total = 0;
      for (final row in (res as List)) {
        final m = Map<String, dynamic>.from(row as Map);
        final roomId = (m['room_id'] as String? ?? '').toLowerCase();
        final world = _worlds.firstWhere(
          (w) => roomId.startsWith('$w-'),
          orElse: () => '',
        );
        if (world.isEmpty) continue;
        final t = DateTime.tryParse(m['created_at'] as String? ?? '');
        if (t == null) continue;
        final localH = t.toLocal().hour;
        if (localH >= 0 && localH < 24) {
          data[world]![localH] = data[world]![localH] + 1;
          total++;
        }
      }
      return ActivityHeatmap(data: data, totalMessages: total, fromTime: since);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Heatmap: $e');
      return ActivityHeatmap(
        data: {for (final w in _worlds) w: List<int>.filled(24, 0)},
        totalMessages: 0,
        fromTime: since,
      );
    }
  }
}
