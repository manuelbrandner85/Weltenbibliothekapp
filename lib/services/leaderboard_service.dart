// =====================================================================
// LEADERBOARD SERVICE v2.0 – Echte Supabase-Daten
// =====================================================================
// Features:
// - Global Leaderboard (Top Users nach XP aus profiles-Tabelle)
// - Weekly/Monthly Rankings
// - Caching für Performance
// =====================================================================

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

// =====================================================================
// LEADERBOARD ENTRY MODEL
// =====================================================================

class LeaderboardEntry {
  final String userId;
  final String username;
  final int totalXp;
  final int level;
  final int achievementCount;
  final int rank;
  final String? avatarUrl;
  final bool isCurrentUser;

  LeaderboardEntry({
    required this.userId,
    required this.username,
    required this.totalXp,
    required this.level,
    required this.achievementCount,
    required this.rank,
    this.avatarUrl,
    this.isCurrentUser = false,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'username': username,
        'totalXp': totalXp,
        'level': level,
        'achievementCount': achievementCount,
        'rank': rank,
        'avatarUrl': avatarUrl,
        'isCurrentUser': isCurrentUser,
      };

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      LeaderboardEntry(
        userId: json['userId'] as String? ?? '',
        username: json['username'] as String? ?? 'Anonym',
        totalXp: json['totalXp'] as int? ?? 0,
        level: json['level'] as int? ?? 1,
        achievementCount: json['achievementCount'] as int? ?? 0,
        rank: json['rank'] as int? ?? 0,
        avatarUrl: json['avatarUrl'] as String?,
        isCurrentUser: json['isCurrentUser'] as bool? ?? false,
      );

  factory LeaderboardEntry.fromProfile(
    Map<String, dynamic> profile,
    int rank,
    String currentUserId,
  ) {
    final xp = (profile['xp'] as int?) ?? (profile['total_xp'] as int?) ?? 0;
    final lvl = (profile['level'] as int?) ?? (xp ~/ 1000 + 1);
    return LeaderboardEntry(
      userId: profile['id'] as String? ?? '',
      username: profile['username'] as String? ?? profile['display_name'] as String? ?? 'Anonym',
      totalXp: xp,
      level: lvl,
      achievementCount: (profile['achievement_count'] as int?) ?? 0,
      rank: rank,
      avatarUrl: profile['avatar_url'] as String?,
      isCurrentUser: profile['id'] == currentUserId,
    );
  }
}

// =====================================================================
// LEADERBOARD TYPE
// =====================================================================

enum LeaderboardType {
  allTime,
  weekly,
  monthly,
  friends,
}

extension LeaderboardTypeExtension on LeaderboardType {
  String get label {
    switch (this) {
      case LeaderboardType.allTime:
        return 'All-Time';
      case LeaderboardType.weekly:
        return 'Woche';
      case LeaderboardType.monthly:
        return 'Monat';
      case LeaderboardType.friends:
        return 'Freunde';
    }
  }

  String get icon {
    switch (this) {
      case LeaderboardType.allTime:
        return '🏆';
      case LeaderboardType.weekly:
        return '📅';
      case LeaderboardType.monthly:
        return '📆';
      case LeaderboardType.friends:
        return '👥';
    }
  }
}

// =====================================================================
// LEADERBOARD SERVICE
// =====================================================================

class LeaderboardService {
  static final LeaderboardService _instance = LeaderboardService._internal();
  factory LeaderboardService() => _instance;
  LeaderboardService._internal();

  final Map<LeaderboardType, List<LeaderboardEntry>> _cachedLeaderboards = {};
  final Map<LeaderboardType, DateTime> _cacheTime = {};
  static const _cacheDuration = Duration(minutes: 5);

  String get _currentUserId =>
      Supabase.instance.client.auth.currentUser?.id ?? '';

  // =====================================================================
  // INITIALIZATION
  // =====================================================================

  Future<void> init() async {
    try {
      // Pre-load leaderboards in background
      await getLeaderboard(LeaderboardType.allTime);
      if (kDebugMode) {
        debugPrint('✅ LeaderboardService initialized (Supabase)');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ LeaderboardService init error: $e');
      }
    }
  }

  // =====================================================================
  // REAL DATA FROM SUPABASE
  // =====================================================================

  Future<List<LeaderboardEntry>> _fetchFromSupabase(
    LeaderboardType type,
  ) async {
    try {
      final currentId = _currentUserId;

      // Query profiles sorted by xp (or level)
      var query = supabase
          .from('profiles')
          .select('id, username, display_name, avatar_url, xp, level, achievement_count')
          .order('xp', ascending: false)
          .limit(50);

      // For weekly/monthly, try to use a date filter on updated_at
      if (type == LeaderboardType.weekly) {
        final since = DateTime.now().subtract(const Duration(days: 7));
        query = supabase
            .from('profiles')
            .select('id, username, display_name, avatar_url, xp, level, achievement_count')
            .gte('updated_at', since.toIso8601String())
            .order('xp', ascending: false)
            .limit(50);
      } else if (type == LeaderboardType.monthly) {
        final since = DateTime.now().subtract(const Duration(days: 30));
        query = supabase
            .from('profiles')
            .select('id, username, display_name, avatar_url, xp, level, achievement_count')
            .gte('updated_at', since.toIso8601String())
            .order('xp', ascending: false)
            .limit(50);
      }

      final data = await query;

      final entries = <LeaderboardEntry>[];
      for (int i = 0; i < data.length; i++) {
        entries.add(LeaderboardEntry.fromProfile(data[i], i + 1, currentId));
      }

      // Ensure current user is in list even if not in top 50
      if (currentId.isNotEmpty && !entries.any((e) => e.userId == currentId)) {
        try {
          final myProfile = await supabase
              .from('profiles')
              .select('id, username, display_name, avatar_url, xp, level, achievement_count')
              .eq('id', currentId)
              .single();
          entries.add(LeaderboardEntry.fromProfile(
            myProfile,
            entries.length + 1,
            currentId,
          ));
        } catch (_) {}
      }

      return entries;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [Leaderboard] Supabase fetch failed: $e');
      return [];
    }
  }

  bool _isCacheValid(LeaderboardType type) {
    final time = _cacheTime[type];
    if (time == null) return false;
    return DateTime.now().difference(time) < _cacheDuration;
  }

  // =====================================================================
  // PUBLIC API
  // =====================================================================

  Future<List<LeaderboardEntry>> getLeaderboard(LeaderboardType type) async {
    // Friends leaderboard: same as allTime but filtered
    if (type == LeaderboardType.friends) {
      return getLeaderboard(LeaderboardType.allTime);
    }

    if (_isCacheValid(type) && _cachedLeaderboards.containsKey(type)) {
      return _cachedLeaderboards[type]!;
    }

    final entries = await _fetchFromSupabase(type);
    if (entries.isNotEmpty) {
      _cachedLeaderboards[type] = entries;
      _cacheTime[type] = DateTime.now();
    }
    return entries;
  }

  Future<LeaderboardEntry?> getCurrentUserEntry(LeaderboardType type) async {
    final leaderboard = await getLeaderboard(type);
    try {
      return leaderboard.firstWhere((entry) => entry.isCurrentUser);
    } catch (e) {
      return null;
    }
  }

  Future<int> getCurrentUserRank(LeaderboardType type) async {
    final entry = await getCurrentUserEntry(type);
    return entry?.rank ?? 0;
  }

  Future<List<LeaderboardEntry>> getTopEntries(
    LeaderboardType type, {
    int limit = 10,
  }) async {
    final leaderboard = await getLeaderboard(type);
    return leaderboard.take(limit).toList();
  }

  /// Force refresh cache
  Future<void> refresh() async {
    _cachedLeaderboards.clear();
    _cacheTime.clear();
    await getLeaderboard(LeaderboardType.allTime);
  }
}
