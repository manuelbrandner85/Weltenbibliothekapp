// SpiritReadingService — Unified History / Vergleich für alle Spirit-Tools.
//
// G1 Tool-Vergleich: getHistory(tool) → 2 Snapshots ('heute', 'vor X Tagen').
// G4 Reading-Tagebuch: full timeline pro Tool.

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';

class SpiritReading {
  final String id;
  final String userId;
  final String? username;
  final String tool;
  final String? summary;
  final Map<String, dynamic> result;
  final String? audioUrl;
  final DateTime createdAt;
  const SpiritReading({
    required this.id,
    required this.userId,
    required this.username,
    required this.tool,
    required this.summary,
    required this.result,
    required this.audioUrl,
    required this.createdAt,
  });

  factory SpiritReading.fromJson(Map<String, dynamic> j) => SpiritReading(
        id: j['id'] as String,
        userId: j['user_id'] as String? ?? '',
        username: j['username'] as String?,
        tool: j['tool'] as String? ?? '',
        summary: j['summary'] as String?,
        result: Map<String, dynamic>.from(j['result'] as Map? ?? {}),
        audioUrl: j['audio_url'] as String?,
        createdAt: DateTime.tryParse(j['created_at'] as String? ?? '') ?? DateTime.now(),
      );
}

// Result-Klasse statt Named-Record (dart2js-Bug mit nullable named records).
class SpiritReadingComparison {
  final SpiritReading? current;
  final SpiritReading? past;
  const SpiritReadingComparison(this.current, this.past);
}

class SpiritReadingService {
  SpiritReadingService._();
  static final instance = SpiritReadingService._();

  SupabaseClient get _s => Supabase.instance.client;

  Future<SpiritReading?> save({
    required String userId,
    String? username,
    required String tool,
    String? summary,
    required Map<String, dynamic> result,
  }) async {
    try {
      final res = await _s.from('spirit_readings').insert({
        'user_id': userId,
        'username': username,
        'tool': tool,
        'summary': summary,
        'result': result,
      }).select().single();
      return SpiritReading.fromJson(Map<String, dynamic>.from(res as Map));
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Reading save: $e');
      return null;
    }
  }

  Future<List<SpiritReading>> getHistory(
    String userId,
    String tool, {
    int limit = 50,
  }) async {
    try {
      final res = await _s
          .from('spirit_readings')
          .select()
          .eq('user_id', userId)
          .eq('tool', tool)
          .order('created_at', ascending: false)
          .limit(limit);
      return (res as List)
          .map((r) => SpiritReading.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Reading history: $e');
      return const [];
    }
  }

  /// G1 Tool-Vergleich: gibt aktuelles + ca-30-Tage-altes Reading zurück.
  Future<SpiritReadingComparison> compareVsPast(
    String userId,
    String tool, {
    int daysAgo = 30,
  }) async {
    final history = await getHistory(userId, tool, limit: 100);
    if (history.isEmpty) return const SpiritReadingComparison(null, null);
    final current = history.first;
    final target = DateTime.now().subtract(Duration(days: daysAgo));
    SpiritReading? past;
    double bestDelta = double.infinity;
    for (final r in history) {
      final d = (r.createdAt.difference(target)).inSeconds.abs().toDouble();
      if (d < bestDelta && r.id != current.id) {
        bestDelta = d;
        past = r;
      }
    }
    return SpiritReadingComparison(current, past);
  }

  Future<bool> attachAudio(String readingId, String url) async {
    try {
      await _s.from('spirit_readings').update({
        'audio_url': url,
      }).eq('id', readingId);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Reading audio attach: $e');
      return false;
    }
  }

  /// G2 Combo-Insight: nimmt die letzten N Readings über alle Tools eines
  /// Users und schickt sie an den Worker zur AI-Synthese.
  Future<List<SpiritReading>> recentAllTools(
    String userId, {
    int limit = 5,
  }) async {
    try {
      final res = await _s
          .from('spirit_readings')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);
      return (res as List)
          .map((r) => SpiritReading.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Reading recentAll: $e');
      return const [];
    }
  }
}
