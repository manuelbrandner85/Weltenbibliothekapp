// =====================================================================
// LEADERBOARD SERVICE v1.0
// =====================================================================
// Verwaltet Rankings und Bestenlisten
// Features:
// - Global Leaderboard (Top Users nach XP)
// - Weekly/Monthly Rankings
// - Friends Leaderboard
// - User Stats Vergleich
// =====================================================================

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'achievement_service.dart';

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
        userId: json['userId'] as String,
        username: json['username'] as String,
        totalXp: json['totalXp'] as int,
        level: json['level'] as int,
        achievementCount: json['achievementCount'] as int,
        rank: json['rank'] as int,
        avatarUrl: json['avatarUrl'] as String?,
        isCurrentUser: json['isCurrentUser'] as bool? ?? false,
      );
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

  // 🌐 Backend API Configuration
  static const String _baseUrl = 'https://api-backend.brandy13062.workers.dev';
  static const Duration _timeout = Duration(seconds: 10);

  static const String _leaderboardKey = 'global_leaderboard';
  static const String _weeklyKey = 'weekly_leaderboard';
  static const String _monthlyKey = 'monthly_leaderboard';
  static const String _friendsKey = 'friends_leaderboard';
  static const String _currentUserIdKey = 'current_user_id';

  SharedPreferences? _prefs;
  final Map<LeaderboardType, List<LeaderboardEntry>> _cachedLeaderboards = {};
  String _currentUserId = 'user_manuel'; // Default user

  // =====================================================================
  // INITIALIZATION
  // =====================================================================

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _currentUserId = _prefs?.getString(_currentUserIdKey) ?? 'user_manuel';
      
      // Generate mock data for demo
      await _generateMockLeaderboards();
      
      if (kDebugMode) {
        print('✅ LeaderboardService initialized');
        print('   👤 Current user: $_currentUserId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ LeaderboardService init error: $e');
      }
    }
  }

  // =====================================================================
  // MOCK DATA GENERATION (für Demo)
  // =====================================================================

  Future<void> _generateMockLeaderboards() async {
    // Get current user stats
    final achievementService = AchievementService();
    final currentUserLevel = achievementService.currentLevel;
    final currentUserXp = currentUserLevel.totalXP;
    final currentAchievementCount = achievementService.unlockedAchievements.length;

    // Generate All-Time Leaderboard
    final allTimeEntries = _generateMockEntries(
      LeaderboardType.allTime,
      currentUserXp,
      currentUserLevel.level,
      currentAchievementCount,
    );
    _cachedLeaderboards[LeaderboardType.allTime] = allTimeEntries;

    // Generate Weekly Leaderboard
    final weeklyEntries = _generateMockEntries(
      LeaderboardType.weekly,
      (currentUserXp * 0.3).toInt(),
      currentUserLevel.level,
      currentAchievementCount,
    );
    _cachedLeaderboards[LeaderboardType.weekly] = weeklyEntries;

    // Generate Monthly Leaderboard
    final monthlyEntries = _generateMockEntries(
      LeaderboardType.monthly,
      (currentUserXp * 0.6).toInt(),
      currentUserLevel.level,
      currentAchievementCount,
    );
    _cachedLeaderboards[LeaderboardType.monthly] = monthlyEntries;

    // Generate Friends Leaderboard (smaller)
    final friendsEntries = _generateFriendsEntries(
      currentUserXp,
      currentUserLevel.level,
      currentAchievementCount,
    );
    _cachedLeaderboards[LeaderboardType.friends] = friendsEntries;
  }

  List<LeaderboardEntry> _generateMockEntries(
    LeaderboardType type,
    int userXp,
    int userLevel,
    int userAchievements,
  ) {
    final List<LeaderboardEntry> entries = [];
    final random = DateTime.now().millisecondsSinceEpoch;

    // Generate 50 mock users
    final mockUsers = [
      'Alex_Scholar', 'Sophia_Sage', 'Max_Explorer', 'Luna_Mystic',
      'Felix_Seeker', 'Nina_Wise', 'Leo_Hunter', 'Maya_Oracle',
      'Tom_Voyager', 'Emma_Legend', 'Paul_Master', 'Lisa_Keeper',
      'Ben_Champion', 'Sara_Wizard', 'Jan_Guru', 'Kim_Prodigy',
      'Tim_Expert', 'Eva_Scholar', 'Dan_Mentor', 'Amy_Maven',
      'Sam_Adept', 'Mia_Curator', 'Joe_Artisan', 'Zoe_Savant',
      'Rob_Luminary', 'Ivy_Virtuoso', 'Kai_Doyen', 'Lia_Pundit',
    ];

    // Add current user
    entries.add(LeaderboardEntry(
      userId: _currentUserId,
      username: 'Manuel',
      totalXp: userXp,
      level: userLevel,
      achievementCount: userAchievements,
      rank: 0, // Will be calculated
      isCurrentUser: true,
    ));

    // Add mock users with varying XP
    for (int i = 0; i < mockUsers.length; i++) {
      final xpVariation = (random % 10000) + (i * 100);
      final mockXp = userXp + xpVariation - 5000;
      
      entries.add(LeaderboardEntry(
        userId: 'user_$i',
        username: mockUsers[i % mockUsers.length],
        totalXp: mockXp > 0 ? mockXp : 100,
        level: (mockXp / 1000).toInt() + 1,
        achievementCount: (mockXp / 100).toInt(),
        rank: 0, // Will be calculated
      ));
    }

    // Sort by XP and assign ranks
    entries.sort((a, b) => b.totalXp.compareTo(a.totalXp));
    
    return entries.asMap().entries.map((entry) {
      final index = entry.key;
      final user = entry.value;
      return LeaderboardEntry(
        userId: user.userId,
        username: user.username,
        totalXp: user.totalXp,
        level: user.level,
        achievementCount: user.achievementCount,
        rank: index + 1,
        isCurrentUser: user.isCurrentUser,
      );
    }).toList();
  }

  List<LeaderboardEntry> _generateFriendsEntries(
    int userXp,
    int userLevel,
    int userAchievements,
  ) {
    final List<LeaderboardEntry> entries = [];
    
    // Add current user
    entries.add(LeaderboardEntry(
      userId: _currentUserId,
      username: 'Manuel',
      totalXp: userXp,
      level: userLevel,
      achievementCount: userAchievements,
      rank: 0,
      isCurrentUser: true,
    ));

    // Add 5 friends
    final friends = [
      {'name': 'Alex', 'xpOffset': 200},
      {'name': 'Sophia', 'xpOffset': -150},
      {'name': 'Max', 'xpOffset': 300},
      {'name': 'Luna', 'xpOffset': -50},
      {'name': 'Felix', 'xpOffset': 100},
    ];

    for (int i = 0; i < friends.length; i++) {
      final friend = friends[i];
      final friendXp = userXp + (friend['xpOffset'] as int);
      
      entries.add(LeaderboardEntry(
        userId: 'friend_$i',
        username: friend['name'] as String,
        totalXp: friendXp > 0 ? friendXp : 100,
        level: (friendXp / 1000).toInt() + 1,
        achievementCount: (friendXp / 100).toInt(),
        rank: 0,
      ));
    }

    // Sort and rank
    entries.sort((a, b) => b.totalXp.compareTo(a.totalXp));
    
    return entries.asMap().entries.map((entry) {
      final index = entry.key;
      final user = entry.value;
      return LeaderboardEntry(
        userId: user.userId,
        username: user.username,
        totalXp: user.totalXp,
        level: user.level,
        achievementCount: user.achievementCount,
        rank: index + 1,
        isCurrentUser: user.isCurrentUser,
      );
    }).toList();
  }

  // =====================================================================
  // PUBLIC API
  // =====================================================================

  Future<List<LeaderboardEntry>> getLeaderboard(LeaderboardType type) async {
    // Refresh current user stats
    await _generateMockLeaderboards();
    return _cachedLeaderboards[type] ?? [];
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
}
