// SpiritReadingService — Unified History / Vergleich für alle Spirit-Tools.
//
// G1 Tool-Vergleich: getHistory(tool) → 2 Snapshots ('heute', 'vor X Tagen').
// G4 Reading-Tagebuch: full timeline pro Tool.

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'achievement_service.dart';

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
        createdAt: DateTime.tryParse(j['created_at'] as String? ?? '') ??
            DateTime.now(),
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
      final res = await _s
          .from('spirit_readings')
          .insert({
            'user_id': userId,
            'username': username,
            'tool': tool,
            'summary': summary,
            'result': result,
          })
          .select()
          .single();
      // Fire-and-forget XP-Award (10 XP pro Reading). Schoent das Konto
      // gegenueber Spam (1 Reading/Tool/Tag waere ideal, aber Idempotenz
      // braucht Datenbank-Logik. Hier nur einfacher Award.)
      _awardXp(userId, tool);
      // v5.44.4: Achievement-Tracking fire-and-forget
      _trackAchievements(tool);
      return SpiritReading.fromJson(Map<String, dynamic>.from(res as Map));
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Reading save: $e');
      return null;
    }
  }

  /// Vergibt 10 XP pro gespeichertem Reading. Nutzt die add_user_xp RPC
  /// wenn verfuegbar, sonst direkter profiles.xp-Increment (nur wenn RLS
  /// das zulaesst - sonst no-op). Niemals throw - Reading-Save bleibt
  /// auch ohne XP-Award erfolgreich.
  Future<void> _awardXp(String userId, String tool) async {
    try {
      await _s.rpc('add_user_xp', params: {
        'p_user_id': userId,
        'p_amount': 10,
        'p_reason': 'spirit:$tool',
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            'XP-Award via RPC fehlgeschlagen ($e), versuche Direct-Update');
      }
      try {
        // Fallback: SELECT current XP, dann UPDATE +10
        final profile = await _s
            .from('profiles')
            .select('xp')
            .eq('id', userId)
            .maybeSingle();
        if (profile == null) return;
        final current = (profile['xp'] as num?)?.toInt() ?? 0;
        await _s.from('profiles').update({'xp': current + 10}).eq('id', userId);
      } catch (e2) {
        if (kDebugMode) {
          debugPrint('XP-Award Fallback auch fehlgeschlagen: $e2');
        }
      }
    }
  }

  /// v5.44.4: Spirit-Achievement-Tracking. Fire-and-forget, throws nie.
  /// Loggt + erhoeht Achievement-Progress fuer:
  /// - spirit_first: Erstes Reading
  /// - spirit_10/50/100: total Readings
  /// - spirit_seven_tools: 7 unterschiedliche Tools
  /// - spirit_master_diviner: alle 14 Tools genutzt
  /// - spirit_streak_7: Spirit-Nutzung an 7 aufeinanderfolgenden Tagen
  static const _kSpiritUsedToolsKey = 'spirit_tools_used_v1';
  static const _kSpiritLastDayKey = 'spirit_last_day_v1';
  static const _kSpiritStreakKey = 'spirit_streak_v1';

  Future<void> _trackAchievements(String tool) async {
    try {
      final svc = AchievementService();
      final prefs = await SharedPreferences.getInstance();

      // Erstes Reading
      await svc.incrementProgress('spirit_first');

      // Total-Counter (incrementProgress macht intern den Vergleich gegen
      // maxProgress und lockt frei wenn erreicht)
      await svc.incrementProgress('spirit_10');
      await svc.incrementProgress('spirit_50');
      await svc.incrementProgress('spirit_100');

      // Unterschiedliche Tools tracking
      final usedToolsRaw =
          prefs.getStringList(_kSpiritUsedToolsKey) ?? const [];
      final usedTools = usedToolsRaw.toSet();
      if (!usedTools.contains(tool)) {
        usedTools.add(tool);
        await prefs.setStringList(_kSpiritUsedToolsKey, usedTools.toList());
        await svc.incrementProgress('spirit_seven_tools');
        await svc.incrementProgress('spirit_master_diviner');
      }

      // Streak tracking
      final today = DateTime.now();
      final todayKey = '${today.year}-${today.month}-${today.day}';
      final lastDay = prefs.getString(_kSpiritLastDayKey);
      if (lastDay != todayKey) {
        // Neuer Tag - pruefe ob gestern war (= Streak weiter)
        int streak = prefs.getInt(_kSpiritStreakKey) ?? 0;
        final yesterday = today.subtract(const Duration(days: 1));
        final yesterdayKey =
            '${yesterday.year}-${yesterday.month}-${yesterday.day}';
        if (lastDay == yesterdayKey) {
          streak += 1;
        } else {
          streak = 1; // Lücke - reset
        }
        await prefs.setString(_kSpiritLastDayKey, todayKey);
        await prefs.setInt(_kSpiritStreakKey, streak);
        // increment Achievement für jeden Tag (1..7)
        if (streak <= 7) {
          await svc.incrementProgress('spirit_streak_7');
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Spirit-Achievement-Tracking: $e');
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
          .map((r) =>
              SpiritReading.fromJson(Map<String, dynamic>.from(r as Map)))
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
          .map((r) =>
              SpiritReading.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Reading recentAll: $e');
      return const [];
    }
  }
}
