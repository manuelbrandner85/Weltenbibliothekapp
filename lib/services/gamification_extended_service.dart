// GamificationExtendedService — Cluster K Services (K1-K3, K5, K6).
//
// Aggregiert die Logik für Achievement-Tiers, Daily-Challenges,
// Weekly-Leaderboard, Guild-Quests und Destiny-Weekly-Draw in einem
// Service. K4 (Skill-Tree-Prerequisites) ist rein UI-seitig — Daten
// liegen im skill_tree-Modul.

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';

enum AchievementTier { bronze, silver, gold, platinum }

class GamificationExtendedService {
  GamificationExtendedService._();
  static final instance = GamificationExtendedService._();

  SupabaseClient get _s => Supabase.instance.client;

  // K1: Tier-Promotion ──────────────────────────────────────────
  // Promoviert ein erreichtes Achievement zur nächsten Tier wenn die
  // Bedingung erfüllt ist (z.B. 'completed 10x' für gold).
  Future<bool> setTier({
    required String userId,
    required String achievementKey,
    required AchievementTier tier,
  }) async {
    try {
      await _s.from('user_achievements').upsert({
        'user_id': userId,
        'achievement_key': achievementKey,
        'tier': tier.name,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,achievement_key');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Tier set: $e');
      return false;
    }
  }

  // K2: Daily-Challenges für heute ──────────────────────────────
  Future<List<Map<String, dynamic>>> todayChallenges({String? world}) async {
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      var q = _s
          .from('daily_challenges_active')
          .select()
          .eq('active_date', today);
      if (world != null) q = q.eq('world', world);
      final res = await q;
      return (res as List).cast<Map<String, dynamic>>();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Daily challenges: $e');
      return const [];
    }
  }

  // K3: Weekly Leaderboard ──────────────────────────────────────
  String _weekStart() {
    final n = DateTime.now();
    // Montag dieser Woche.
    final monday = n.subtract(Duration(days: (n.weekday + 6) % 7));
    return DateTime(monday.year, monday.month, monday.day)
        .toIso8601String()
        .substring(0, 10);
  }

  Future<List<Map<String, dynamic>>> weeklyTop(String world, {int limit = 20}) async {
    try {
      final week = _weekStart();
      final res = await _s
          .from('leaderboard_weekly')
          .select()
          .eq('week_start', week)
          .eq('world', world)
          .order('weekly_xp', ascending: false)
          .limit(limit);
      return (res as List).cast<Map<String, dynamic>>();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Weekly top: $e');
      return const [];
    }
  }

  Future<List<Map<String, dynamic>>> hallOfFame(String world, {int limit = 30}) async {
    try {
      final res = await _s
          .from('leaderboard_weekly')
          .select()
          .eq('is_hall_of_fame', true)
          .eq('world', world)
          .order('week_start', ascending: false)
          .limit(limit);
      return (res as List).cast<Map<String, dynamic>>();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ HoF: $e');
      return const [];
    }
  }

  Future<bool> reportWeeklyXp({
    required String userId,
    String? username,
    required String world,
    required int xp,
  }) async {
    try {
      final week = _weekStart();
      await _s.from('leaderboard_weekly').upsert({
        'week_start': week,
        'user_id': userId,
        'username': username,
        'world': world,
        'weekly_xp': xp,
        'weekly_rank': 0, // wird beim Reset normalisiert
      }, onConflict: 'week_start,world,user_id');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Weekly XP report: $e');
      return false;
    }
  }

  // K5: Guild-Quest dieser Woche ────────────────────────────────
  Future<Map<String, dynamic>?> currentGuildQuest(String guildId) async {
    try {
      final week = _weekStart();
      final res = await _s
          .from('guild_quests')
          .select()
          .eq('guild_id', guildId)
          .eq('week_start', week)
          .maybeSingle();
      return res == null ? null : Map<String, dynamic>.from(res as Map);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ GuildQuest: $e');
      return null;
    }
  }

  Future<bool> contributeToGuildQuest({
    required String guildId,
    required int xpDelta,
  }) async {
    try {
      final current = await currentGuildQuest(guildId);
      if (current == null) return false;
      final newXp = (current['current_xp'] as int? ?? 0) + xpDelta;
      final target = current['target_xp'] as int? ?? 500;
      final completed = newXp >= target && current['completed_at'] == null;
      await _s.from('guild_quests').update({
        'current_xp': newXp,
        if (completed) 'completed_at': DateTime.now().toIso8601String(),
      }).eq('id', current['id']);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Guild contribute: $e');
      return false;
    }
  }

  // K6: Destiny-Wöchentlich-Ziehung ─────────────────────────────
  Future<Map<String, dynamic>?> currentWeeklyDraw(String userId) async {
    try {
      final week = _weekStart();
      final res = await _s
          .from('destiny_weekly_draws')
          .select()
          .eq('user_id', userId)
          .eq('week_start', week)
          .maybeSingle();
      return res == null ? null : Map<String, dynamic>.from(res as Map);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Destiny draw: $e');
      return null;
    }
  }

  Future<bool> setWeeklyDraw({
    required String userId,
    required String cardId,
  }) async {
    try {
      final week = _weekStart();
      await _s.from('destiny_weekly_draws').upsert({
        'user_id': userId,
        'week_start': week,
        'card_id': cardId,
      }, onConflict: 'user_id,week_start');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Destiny set: $e');
      return false;
    }
  }
}
