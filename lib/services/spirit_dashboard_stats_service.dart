// SpiritDashboardStatsService — Aggregat persönlicher Spirit-Tool-Nutzung (F2).
//
// Liest aus den lokalen SQLite/Hive-Boxen (Tool-Cache + spirit-tool-history)
// und liefert einen kompakten Stats-Block. Kein Server-Sync — pure
// On-Device-Aggregat.

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

import 'sqlite_storage_service.dart';

class SpiritDashboardStats {
  final int toolsUsed;
  final int totalReadings;
  final String? mostUsedTool;
  final String? topChakra;
  final DateTime? lastReading;
  const SpiritDashboardStats({
    required this.toolsUsed,
    required this.totalReadings,
    required this.mostUsedTool,
    required this.topChakra,
    required this.lastReading,
  });

  factory SpiritDashboardStats.empty() => const SpiritDashboardStats(
        toolsUsed: 0,
        totalReadings: 0,
        mostUsedTool: null,
        topChakra: null,
        lastReading: null,
      );
}

class SpiritDashboardStatsService {
  SpiritDashboardStatsService._();
  static final instance = SpiritDashboardStatsService._();

  // SQLite-Boxen, in denen Tool-Results landen. Naming aus
  // spirit_calculations / energie-Tools — bekannte Keys:
  static const _toolBoxes = [
    'chakra_results',
    'numerology_results',
    'hermetic_results',
    'kabbalah_results',
    'gematria_results',
    'archetype_results',
    'human_design_results',
    'natal_chart_results',
    'moon_calendar_results',
    'dream_interpretation_results',
    'body_scan_results',
    'shamanic_journey_results',
    'soul_contract_results',
    'ancestral_work_results',
  ];

  Future<SpiritDashboardStats> compute() async {
    try {
      final db = SqliteStorageService.instance;
      final perTool = <String, int>{};
      int total = 0;
      DateTime? last;
      String? topChakra;
      final chakraCount = <String, int>{};

      for (final box in _toolBoxes) {
        try {
          final entries = await db.getAll(box);
          if (entries.isEmpty) continue;
          perTool[box] = entries.length;
          total += entries.length;
          for (final e in entries) {
            try {
              final m = (e is Map)
                  ? Map<String, dynamic>.from(e)
                  : <String, dynamic>{};
              final tsRaw = m['timestamp'] ?? m['created_at'] ?? m['date'];
              final t = tsRaw is String ? DateTime.tryParse(tsRaw) : null;
              if (t != null && (last == null || t.isAfter(last))) last = t;
              // Chakra-specific: häufigster Punkt
              if (box == 'chakra_results') {
                final dom =
                    (m['dominant_chakra'] ?? m['top_chakra']) as String?;
                if (dom != null) {
                  chakraCount[dom] = (chakraCount[dom] ?? 0) + 1;
                }
              }
            } catch (e) { if (kDebugMode) debugPrint('spirit_dashboard_stats_service: silent catch -> $e'); }
          }
        } catch (e) { if (kDebugMode) debugPrint('spirit_dashboard_stats_service: silent catch -> $e'); }
      }

      if (chakraCount.isNotEmpty) {
        final sorted = chakraCount.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        topChakra = sorted.first.key;
      }

      String? mostUsed;
      if (perTool.isNotEmpty) {
        final sorted = perTool.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        mostUsed = sorted.first.key.replaceAll('_results', '');
      }

      return SpiritDashboardStats(
        toolsUsed: perTool.length,
        totalReadings: total,
        mostUsedTool: mostUsed,
        topChakra: topChakra,
        lastReading: last,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ SpiritDashboardStats: $e');
      return SpiritDashboardStats.empty();
    }
  }
}
