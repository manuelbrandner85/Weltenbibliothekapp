/// Achievement System Service
/// Version: 2.0.0 (SharedPreferences)
///
/// Features:
/// - Badge Collection System
/// - Unlock Logic & Progress Tracking
/// - XP & Level System
/// - Local Storage (SharedPreferences)
library;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Achievement Category Types
enum AchievementCategory {
  researcher,    // Research & Search related
  explorer,      // Content discovery
  community,     // Social interactions
  knowledge,     // Learning & Reading
  streak,        // Daily usage
  collector,     // Content saving
  creator,       // Content creation
  master,        // Special achievements
}

/// Achievement Rarity
enum AchievementRarity {
  common,        // Easy to get
  uncommon,      // Medium difficulty
  rare,          // Hard to get
  epic,          // Very hard
  legendary,     // Extremely rare
}

/// Single Achievement Definition
class Achievement {
  final String id;
  final String name;
  final String description;
  final String icon;
  final AchievementCategory category;
  final AchievementRarity rarity;
  final int xpReward;
  final int maxProgress;
  final String? secretHint;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.rarity,
    required this.xpReward,
    this.maxProgress = 1,
    this.secretHint,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'icon': icon,
    'category': category.name,
    'rarity': rarity.name,
    'xpReward': xpReward,
    'maxProgress': maxProgress,
    'secretHint': secretHint,
  };

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    icon: json['icon'] as String,
    category: AchievementCategory.values.firstWhere(
      (e) => e.name == json['category'],
    ),
    rarity: AchievementRarity.values.firstWhere(
      (e) => e.name == json['rarity'],
    ),
    xpReward: json['xpReward'] as int,
    maxProgress: json['maxProgress'] as int? ?? 1,
    secretHint: json['secretHint'] as String?,
  );
}

/// Achievement Progress
class AchievementProgress {
  final String achievementId;
  int currentProgress;
  bool isUnlocked;
  bool isViewed;
  DateTime? unlockedAt;

  AchievementProgress({
    required this.achievementId,
    this.currentProgress = 0,
    this.isUnlocked = false,
    this.isViewed = false,
    this.unlockedAt,
  });

  Map<String, dynamic> toJson() => {
    'achievementId': achievementId,
    'currentProgress': currentProgress,
    'isUnlocked': isUnlocked,
    'isViewed': isViewed,
    'unlockedAt': unlockedAt?.toIso8601String(),
  };

  factory AchievementProgress.fromJson(Map<String, dynamic> json) =>
      AchievementProgress(
        achievementId: json['achievementId'] as String,
        currentProgress: json['currentProgress'] as int? ?? 0,
        isUnlocked: json['isUnlocked'] as bool? ?? false,
        isViewed: json['isViewed'] as bool? ?? false,
        unlockedAt: json['unlockedAt'] != null
            ? DateTime.tryParse(json['unlockedAt'] as String)
            : null,
      );
}

/// User Level Model
class UserLevel {
  int level;
  int currentXP;
  int totalXP;

  UserLevel({
    this.level = 1,
    this.currentXP = 0,
    this.totalXP = 0,
  });

  int get xpForNextLevel => level * 100;

  Map<String, dynamic> toJson() => {
    'level': level,
    'currentXP': currentXP,
    'totalXP': totalXP,
  };

  factory UserLevel.fromJson(Map<String, dynamic> json) => UserLevel(
    level: json['level'] as int? ?? 1,
    currentXP: json['currentXP'] as int? ?? 0,
    totalXP: json['totalXP'] as int? ?? 0,
  );
}

/// Achievement Service - Singleton
class AchievementService {
  static final AchievementService _instance = AchievementService._internal();
  factory AchievementService() => _instance;
  AchievementService._internal();

  static const String _kProgress = 'ach_progress';
  static const String _kLevel    = 'ach_level';

  final Map<String, Achievement>       _achievements = {};
  final Map<String, AchievementProgress> _progress   = {};
  UserLevel _userLevel = UserLevel();

  final List<Function(Achievement, AchievementProgress)> _unlockListeners = [];
  final List<Function(UserLevel)> _levelUpListeners = [];

  /// Initialize Service
  Future<void> init() async {
    try {
      _defineAchievements();
      await _loadProgress();

      if (kDebugMode) {
        debugPrint('✅ AchievementService initialized');
        debugPrint('📊 Total Achievements: ${_achievements.length}');
        debugPrint('🏆 Unlocked: ${_progress.values.where((p) => p.isUnlocked).length}');
        debugPrint('⭐ User Level: ${_userLevel.level} (${_userLevel.currentXP}/${_userLevel.xpForNextLevel} XP)');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ AchievementService init error: $e');
    }
  }

  /// Define all achievements
  void _defineAchievements() {
    final achievements = [
      // 🔍 RESEARCHER ACHIEVEMENTS
      Achievement(
        id: 'first_search',
        name: 'Erster Schritt',
        description: 'Führe deine erste Recherche durch',
        icon: '🔍',
        category: AchievementCategory.researcher,
        rarity: AchievementRarity.common,
        xpReward: 10,
      ),
      Achievement(
        id: 'researcher_10',
        name: 'Wissensdurstig',
        description: 'Führe 10 Recherchen durch',
        icon: '📚',
        category: AchievementCategory.researcher,
        rarity: AchievementRarity.common,
        xpReward: 25,
        maxProgress: 10,
      ),
      Achievement(
        id: 'researcher_50',
        name: 'Recherche-Experte',
        description: 'Führe 50 Recherchen durch',
        icon: '🎓',
        category: AchievementCategory.researcher,
        rarity: AchievementRarity.uncommon,
        xpReward: 100,
        maxProgress: 50,
      ),
      Achievement(
        id: 'researcher_100',
        name: 'Meister-Rechercheur',
        description: 'Führe 100 Recherchen durch',
        icon: '🧠',
        category: AchievementCategory.researcher,
        rarity: AchievementRarity.rare,
        xpReward: 250,
        maxProgress: 100,
      ),
      // 📖 KNOWLEDGE ACHIEVEMENTS
      Achievement(
        id: 'first_read',
        name: 'Neugierig',
        description: 'Lese deinen ersten Artikel',
        icon: '📄',
        category: AchievementCategory.knowledge,
        rarity: AchievementRarity.common,
        xpReward: 10,
      ),
      Achievement(
        id: 'reader_25',
        name: 'Vielleser',
        description: 'Lese 25 Artikel',
        icon: '📰',
        category: AchievementCategory.knowledge,
        rarity: AchievementRarity.common,
        xpReward: 50,
        maxProgress: 25,
      ),
      Achievement(
        id: 'reader_100',
        name: 'Bibliophiler',
        description: 'Lese 100 Artikel',
        icon: '📚',
        category: AchievementCategory.knowledge,
        rarity: AchievementRarity.uncommon,
        xpReward: 150,
        maxProgress: 100,
      ),
      // 🔖 COLLECTOR ACHIEVEMENTS
      Achievement(
        id: 'first_bookmark',
        name: 'Merkzettel',
        description: 'Speichere deinen ersten Inhalt',
        icon: '🔖',
        category: AchievementCategory.collector,
        rarity: AchievementRarity.common,
        xpReward: 10,
      ),
      Achievement(
        id: 'curator',
        name: 'Kurator',
        description: 'Speichere 25 Inhalte',
        icon: '🗂️',
        category: AchievementCategory.collector,
        rarity: AchievementRarity.uncommon,
        xpReward: 75,
        maxProgress: 25,
      ),
      Achievement(
        id: 'knowledge_seeker',
        name: 'Wissenssammler',
        description: 'Speichere 50 Inhalte',
        icon: '💎',
        category: AchievementCategory.collector,
        rarity: AchievementRarity.rare,
        xpReward: 200,
        maxProgress: 50,
      ),
      // 🌐 COMMUNITY ACHIEVEMENTS
      Achievement(
        id: 'first_post',
        name: 'Stimme der Gemeinschaft',
        description: 'Erstelle deinen ersten Beitrag',
        icon: '✍️',
        category: AchievementCategory.community,
        rarity: AchievementRarity.common,
        xpReward: 20,
      ),
      Achievement(
        id: 'social_butterfly',
        name: 'Schmetterling',
        description: 'Like 50 Beiträge',
        icon: '🦋',
        category: AchievementCategory.community,
        rarity: AchievementRarity.common,
        xpReward: 50,
        maxProgress: 50,
      ),
      Achievement(
        id: 'commenter',
        name: 'Diskutant',
        description: 'Schreibe 20 Kommentare',
        icon: '💬',
        category: AchievementCategory.community,
        rarity: AchievementRarity.uncommon,
        xpReward: 75,
        maxProgress: 20,
      ),
      // 🔥 STREAK ACHIEVEMENTS
      Achievement(
        id: 'streak_7',
        name: 'Beständig',
        description: '7 Tage in Folge aktiv',
        icon: '🔥',
        category: AchievementCategory.streak,
        rarity: AchievementRarity.uncommon,
        xpReward: 100,
        maxProgress: 7,
      ),
      Achievement(
        id: 'streak_30',
        name: 'Unaufhaltsam',
        description: '30 Tage in Folge aktiv',
        icon: '⚡',
        category: AchievementCategory.streak,
        rarity: AchievementRarity.rare,
        xpReward: 300,
        maxProgress: 30,
      ),
      // 🗺️ EXPLORER ACHIEVEMENTS
      Achievement(
        id: 'world_explorer',
        name: 'Weltenwanderer',
        description: 'Besuche beide Welten',
        icon: '🌍',
        category: AchievementCategory.explorer,
        rarity: AchievementRarity.common,
        xpReward: 30,
        maxProgress: 2,
      ),
      Achievement(
        id: 'tool_master',
        name: 'Werkzeugmeister',
        description: 'Benutze 5 verschiedene Tools',
        icon: '🛠️',
        category: AchievementCategory.explorer,
        rarity: AchievementRarity.uncommon,
        xpReward: 100,
        maxProgress: 5,
      ),
      // ⭐ SPECIAL ACHIEVEMENTS
      Achievement(
        id: 'perfectionist',
        name: 'Perfektionist',
        description: 'Schalte fast alle Achievements frei',
        icon: '🏆',
        category: AchievementCategory.master,
        rarity: AchievementRarity.legendary,
        xpReward: 1000,
        secretHint: 'Sammle fast alle anderen Achievements',
      ),
    ];

    for (var achievement in achievements) {
      _achievements[achievement.id] = achievement;
    }
  }

  /// Load user progress from storage
  Future<void> _loadProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final progressData = prefs.getString(_kProgress);
      if (progressData != null) {
        final List<dynamic> progressList = jsonDecode(progressData);
        for (var json in progressList) {
          final progress = AchievementProgress.fromJson(json as Map<String, dynamic>);
          _progress[progress.achievementId] = progress;
        }
      }

      final levelData = prefs.getString(_kLevel);
      if (levelData != null) {
        _userLevel = UserLevel.fromJson(jsonDecode(levelData) as Map<String, dynamic>);
      }

      for (var achievementId in _achievements.keys) {
        if (!_progress.containsKey(achievementId)) {
          _progress[achievementId] = AchievementProgress(achievementId: achievementId);
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error loading progress: $e');
    }
  }

  /// Save progress to storage
  Future<void> _saveProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressList = _progress.values.map((p) => p.toJson()).toList();
      await prefs.setString(_kProgress, jsonEncode(progressList));
      await prefs.setString(_kLevel, jsonEncode(_userLevel.toJson()));
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error saving progress: $e');
    }
  }

  /// Increment achievement progress
  Future<bool> incrementProgress(String achievementId, {int amount = 1}) async {
    final achievement = _achievements[achievementId];
    if (achievement == null) return false;

    final progress = _progress[achievementId] ??
        AchievementProgress(achievementId: achievementId);

    if (progress.isUnlocked) return false;

    progress.currentProgress += amount;

    if (progress.currentProgress >= achievement.maxProgress) {
      return await _unlockAchievement(achievementId);
    } else {
      _progress[achievementId] = progress;
      await _saveProgress();
      return false;
    }
  }

  /// Unlock achievement
  Future<bool> _unlockAchievement(String achievementId) async {
    final achievement = _achievements[achievementId];
    if (achievement == null) return false;

    final progress = _progress[achievementId] ??
        AchievementProgress(achievementId: achievementId);

    if (progress.isUnlocked) return false;

    progress.isUnlocked = true;
    progress.currentProgress = achievement.maxProgress;
    progress.unlockedAt = DateTime.now();
    _progress[achievementId] = progress;

    await _addXP(achievement.xpReward);
    await _saveProgress();

    for (var listener in _unlockListeners) {
      listener(achievement, progress);
    }

    if (kDebugMode) {
      debugPrint('🏆 Achievement Unlocked: ${achievement.name} (+${achievement.xpReward} XP)');
    }

    _checkPerfectionist();

    return true;
  }

  /// Add XP and check for level up
  Future<void> _addXP(int xp) async {
    _userLevel.currentXP += xp;
    _userLevel.totalXP += xp;

    while (_userLevel.currentXP >= _userLevel.xpForNextLevel) {
      _userLevel.currentXP -= _userLevel.xpForNextLevel;
      _userLevel.level++;

      for (var listener in _levelUpListeners) {
        listener(_userLevel);
      }

      if (kDebugMode) {
        debugPrint('⬆️ LEVEL UP! Level ${_userLevel.level}');
      }
    }

    await _saveProgress();
  }

  void _checkPerfectionist() {
    final unlockedCount = _progress.values.where((p) => p.isUnlocked).length;
    final totalCount = _achievements.length;
    if (unlockedCount >= totalCount - 1) {
      incrementProgress('perfectionist');
    }
  }

  // =====================================================================
  // PUBLIC GETTERS
  // =====================================================================

  UserLevel get currentLevel => _userLevel;

  List<Achievement> get unlockedAchievements {
    return _achievements.values
        .where((achievement) {
          final progress = _progress[achievement.id];
          return progress != null && progress.isUnlocked;
        })
        .toList();
  }

  List<Achievement> get allAchievements => _achievements.values.toList();

  // =====================================================================
  // LISTENERS
  // =====================================================================

  void addUnlockListener(Function(Achievement, AchievementProgress) listener) {
    _unlockListeners.add(listener);
  }

  void addLevelUpListener(Function(UserLevel) listener) {
    _levelUpListeners.add(listener);
  }

  List<Achievement> getAllAchievements() => _achievements.values.toList();

  List<Achievement> getAchievementsByCategory(AchievementCategory category) {
    return _achievements.values.where((a) => a.category == category).toList();
  }

  AchievementProgress? getProgress(String achievementId) => _progress[achievementId];

  UserLevel getUserLevel() => _userLevel;

  int getUnlockedCount() => _progress.values.where((p) => p.isUnlocked).length;

  int getTotalCount() => _achievements.length;

  List<Achievement> getUnviewedAchievements() {
    return _achievements.values.where((achievement) {
      final progress = _progress[achievement.id];
      return progress != null && progress.isUnlocked && !progress.isViewed;
    }).toList();
  }

  Future<void> markAsViewed(String achievementId) async {
    final progress = _progress[achievementId];
    if (progress != null) {
      progress.isViewed = true;
      await _saveProgress();
    }
  }
}
