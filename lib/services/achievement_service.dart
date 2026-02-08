/// Achievement System Service
/// Version: 1.0.0
/// 
/// Features:
/// - Badge Collection System
/// - Unlock Logic & Progress Tracking
/// - XP & Level System
/// - Local Storage (Hive)
library;

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
  final String? secretHint; // For hidden achievements

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

/// User Achievement Progress
class AchievementProgress {
  final String achievementId;
  int currentProgress;
  bool isUnlocked;
  DateTime? unlockedAt;
  bool isViewed; // User hat Unlock-Notification gesehen

  AchievementProgress({
    required this.achievementId,
    this.currentProgress = 0,
    this.isUnlocked = false,
    this.unlockedAt,
    this.isViewed = false,
  });

  Map<String, dynamic> toJson() => {
    'achievementId': achievementId,
    'currentProgress': currentProgress,
    'isUnlocked': isUnlocked,
    'unlockedAt': unlockedAt?.toIso8601String(),
    'isViewed': isViewed,
  };

  factory AchievementProgress.fromJson(Map<String, dynamic> json) => AchievementProgress(
    achievementId: json['achievementId'] as String,
    currentProgress: json['currentProgress'] as int? ?? 0,
    isUnlocked: json['isUnlocked'] as bool? ?? false,
    unlockedAt: json['unlockedAt'] != null 
      ? DateTime.parse(json['unlockedAt'] as String)
      : null,
    isViewed: json['isViewed'] as bool? ?? false,
  );
}

/// User Level & XP
class UserLevel {
  int level;
  int currentXP;
  int totalXP;

  UserLevel({
    this.level = 1,
    this.currentXP = 0,
    this.totalXP = 0,
  });

  int get xpForNextLevel => _calculateXPForLevel(level + 1);
  double get progressToNextLevel => currentXP / xpForNextLevel;

  static int _calculateXPForLevel(int level) {
    // Exponential XP curve: 100 * (level ^ 1.5)
    return (100 * (level * level * level).toDouble().clamp(1, 1000000)).round();
  }

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

  static const String _boxName = 'achievements_box';
  static const String _progressKey = 'achievement_progress';
  static const String _levelKey = 'user_level';

  Box? _box;
  final Map<String, Achievement> _achievements = {};
  final Map<String, AchievementProgress> _progress = {};
  UserLevel _userLevel = UserLevel();

  // Callbacks für UI Updates
  final List<Function(Achievement, AchievementProgress)> _unlockListeners = [];
  final List<Function(UserLevel)> _levelUpListeners = [];

  /// Initialize Service
  Future<void> init() async {
    try {
      if (!Hive.isBoxOpen(_boxName)) {
        _box = await Hive.openBox(_boxName);
      } else {
        _box = Hive.box(_boxName);
      }
      
      _defineAchievements();
      await _loadProgress();
      
      if (kDebugMode) {
        print('✅ AchievementService initialized');
        print('📊 Total Achievements: ${_achievements.length}');
        print('🏆 Unlocked: ${_progress.values.where((p) => p.isUnlocked).length}');
        print('⭐ User Level: ${_userLevel.level} (${_userLevel.currentXP}/${_userLevel.xpForNextLevel} XP)');
      }
    } catch (e) {
      if (kDebugMode) print('❌ AchievementService init error: $e');
    }
  }

  /// Define all achievements
  void _defineAchievements() {
    final achievements = [
      // 🔍 RESEARCHER ACHIEVEMENTS
      Achievement(
        id: 'first_search',
        name: 'Erste Suche',
        description: 'Führe deine erste Suche durch',
        icon: '🔍',
        category: AchievementCategory.researcher,
        rarity: AchievementRarity.common,
        xpReward: 10,
      ),
      Achievement(
        id: 'search_veteran',
        name: 'Such-Veteran',
        description: 'Führe 100 Suchen durch',
        icon: '🔬',
        category: AchievementCategory.researcher,
        rarity: AchievementRarity.uncommon,
        xpReward: 50,
        maxProgress: 100,
      ),
      Achievement(
        id: 'search_master',
        name: 'Such-Meister',
        description: 'Führe 1000 Suchen durch',
        icon: '🎓',
        category: AchievementCategory.researcher,
        rarity: AchievementRarity.rare,
        xpReward: 200,
        maxProgress: 1000,
      ),

      // 🌍 EXPLORER ACHIEVEMENTS
      Achievement(
        id: 'first_narrative',
        name: 'Erste Entdeckung',
        description: 'Öffne dein erstes Narrativ',
        icon: '📖',
        category: AchievementCategory.explorer,
        rarity: AchievementRarity.common,
        xpReward: 10,
      ),
      Achievement(
        id: 'narrative_explorer',
        name: 'Narrativ-Entdecker',
        description: 'Lies 50 verschiedene Narrative',
        icon: '🗺️',
        category: AchievementCategory.explorer,
        rarity: AchievementRarity.uncommon,
        xpReward: 75,
        maxProgress: 50,
      ),
      Achievement(
        id: 'world_traveler',
        name: 'Welten-Reisender',
        description: 'Besuche beide Welten 10x',
        icon: '🌌',
        category: AchievementCategory.explorer,
        rarity: AchievementRarity.rare,
        xpReward: 150,
        maxProgress: 20,
      ),

      // 👥 COMMUNITY ACHIEVEMENTS
      Achievement(
        id: 'first_like',
        name: 'Erste Reaktion',
        description: 'Like deinen ersten Post',
        icon: '❤️',
        category: AchievementCategory.community,
        rarity: AchievementRarity.common,
        xpReward: 10,
      ),
      Achievement(
        id: 'first_comment',
        name: 'Erste Interaktion',
        description: 'Schreibe deinen ersten Kommentar',
        icon: '💬',
        category: AchievementCategory.community,
        rarity: AchievementRarity.common,
        xpReward: 15,
      ),
      Achievement(
        id: 'community_champion',
        name: 'Community-Champion',
        description: 'Sammle 100 Likes auf deinen Posts',
        icon: '🏆',
        category: AchievementCategory.community,
        rarity: AchievementRarity.epic,
        xpReward: 250,
        maxProgress: 100,
      ),

      // 📚 KNOWLEDGE ACHIEVEMENTS
      Achievement(
        id: 'quick_learner',
        name: 'Schnell-Lerner',
        description: 'Lies 3 Narrative an einem Tag',
        icon: '⚡',
        category: AchievementCategory.knowledge,
        rarity: AchievementRarity.uncommon,
        xpReward: 50,
        maxProgress: 3,
      ),
      Achievement(
        id: 'knowledge_seeker',
        name: 'Wissens-Sucher',
        description: 'Sammle 50 Lesezeichen',
        icon: '📚',
        category: AchievementCategory.knowledge,
        rarity: AchievementRarity.rare,
        xpReward: 100,
        maxProgress: 50,
      ),
      Achievement(
        id: 'encyclopedia',
        name: 'Enzyklopädie',
        description: 'Lies Narrative aus allen Kategorien',
        icon: '📖',
        category: AchievementCategory.knowledge,
        rarity: AchievementRarity.epic,
        xpReward: 300,
        maxProgress: 10, // 10 verschiedene Kategorien
      ),

      // 🔥 STREAK ACHIEVEMENTS
      Achievement(
        id: 'streak_beginner',
        name: 'Tägliche Routine',
        description: 'Erreiche einen 3-Tage-Streak',
        icon: '🔥',
        category: AchievementCategory.streak,
        rarity: AchievementRarity.common,
        xpReward: 25,
        maxProgress: 3,
      ),
      Achievement(
        id: 'streak_keeper',
        name: 'Streak-Bewahrer',
        description: 'Erreiche einen 7-Tage-Streak',
        icon: '⚡',
        category: AchievementCategory.streak,
        rarity: AchievementRarity.uncommon,
        xpReward: 75,
        maxProgress: 7,
      ),
      Achievement(
        id: 'streak_legend',
        name: 'Streak-Legende',
        description: 'Erreiche einen 30-Tage-Streak',
        icon: '🌟',
        category: AchievementCategory.streak,
        rarity: AchievementRarity.legendary,
        xpReward: 500,
        maxProgress: 30,
      ),

      // 💾 COLLECTOR ACHIEVEMENTS
      Achievement(
        id: 'first_bookmark',
        name: 'Erste Sammlung',
        description: 'Speichere dein erstes Lesezeichen',
        icon: '🔖',
        category: AchievementCategory.collector,
        rarity: AchievementRarity.common,
        xpReward: 10,
      ),
      Achievement(
        id: 'curator',
        name: 'Kurator',
        description: 'Sammle 25 Lesezeichen',
        icon: '📌',
        category: AchievementCategory.collector,
        rarity: AchievementRarity.uncommon,
        xpReward: 50,
        maxProgress: 25,
      ),

      // ⭐ SPECIAL/MASTER ACHIEVEMENTS
      Achievement(
        id: 'early_bird',
        name: 'Frühaufsteher',
        description: 'Nutze die App vor 6:00 Uhr',
        icon: '🌅',
        category: AchievementCategory.master,
        rarity: AchievementRarity.rare,
        xpReward: 100,
        secretHint: 'Besuche die App zu ungewöhnlichen Zeiten...',
      ),
      Achievement(
        id: 'night_owl',
        name: 'Nachteule',
        description: 'Nutze die App nach 23:00 Uhr',
        icon: '🦉',
        category: AchievementCategory.master,
        rarity: AchievementRarity.rare,
        xpReward: 100,
        secretHint: 'Die Nacht ist voller Geheimnisse...',
      ),
      Achievement(
        id: 'perfectionist',
        name: 'Perfektionist',
        description: 'Schalte alle anderen Achievements frei',
        icon: '💎',
        category: AchievementCategory.master,
        rarity: AchievementRarity.legendary,
        xpReward: 1000,
        secretHint: 'Meistere alles...',
      ),
    ];

    for (var achievement in achievements) {
      _achievements[achievement.id] = achievement;
    }
  }

  /// Load user progress from storage
  Future<void> _loadProgress() async {
    try {
      // Load achievement progress
      final progressData = _box?.get(_progressKey);
      if (progressData != null) {
        final List<dynamic> progressList = jsonDecode(progressData as String);
        for (var json in progressList) {
          final progress = AchievementProgress.fromJson(json);
          _progress[progress.achievementId] = progress;
        }
      }

      // Load user level
      final levelData = _box?.get(_levelKey);
      if (levelData != null) {
        _userLevel = UserLevel.fromJson(jsonDecode(levelData as String));
      }

      // Initialize missing progress entries
      for (var achievementId in _achievements.keys) {
        if (!_progress.containsKey(achievementId)) {
          _progress[achievementId] = AchievementProgress(achievementId: achievementId);
        }
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error loading progress: $e');
    }
  }

  /// Save progress to storage
  Future<void> _saveProgress() async {
    try {
      final progressList = _progress.values.map((p) => p.toJson()).toList();
      await _box?.put(_progressKey, jsonEncode(progressList));
      await _box?.put(_levelKey, jsonEncode(_userLevel.toJson()));
    } catch (e) {
      if (kDebugMode) print('❌ Error saving progress: $e');
    }
  }

  /// Increment achievement progress
  Future<bool> incrementProgress(String achievementId, {int amount = 1}) async {
    final achievement = _achievements[achievementId];
    if (achievement == null) return false;

    final progress = _progress[achievementId]!;
    if (progress.isUnlocked) return false; // Already unlocked

    progress.currentProgress += amount;

    // Check if unlocked
    if (progress.currentProgress >= achievement.maxProgress) {
      return await _unlockAchievement(achievementId);
    }

    await _saveProgress();
    return false;
  }

  /// Unlock achievement
  Future<bool> _unlockAchievement(String achievementId) async {
    final achievement = _achievements[achievementId];
    final progress = _progress[achievementId];
    
    if (achievement == null || progress == null || progress.isUnlocked) {
      return false;
    }

    progress.isUnlocked = true;
    progress.unlockedAt = DateTime.now();
    progress.currentProgress = achievement.maxProgress;

    // Award XP
    await _addXP(achievement.xpReward);

    await _saveProgress();

    // Notify listeners
    for (var listener in _unlockListeners) {
      listener(achievement, progress);
    }

    if (kDebugMode) {
      print('🏆 Achievement Unlocked: ${achievement.name} (+${achievement.xpReward} XP)');
    }

    // Check for perfectionist achievement
    _checkPerfectionist();

    return true;
  }

  /// Add XP and check for level up
  Future<void> _addXP(int xp) async {
    _userLevel.currentXP += xp;
    _userLevel.totalXP += xp;

    // Check for level up
    while (_userLevel.currentXP >= _userLevel.xpForNextLevel) {
      _userLevel.currentXP -= _userLevel.xpForNextLevel;
      _userLevel.level++;

      // Notify listeners
      for (var listener in _levelUpListeners) {
        listener(_userLevel);
      }

      if (kDebugMode) {
        print('⬆️ LEVEL UP! Level ${_userLevel.level}');
      }
    }

    await _saveProgress();
  }

  /// Check if perfectionist achievement should be unlocked
  void _checkPerfectionist() {
    final unlockedCount = _progress.values.where((p) => p.isUnlocked).length;
    final totalCount = _achievements.length;
    
    if (unlockedCount >= totalCount - 1) { // -1 because perfectionist itself
      incrementProgress('perfectionist');
    }
  }

  // =====================================================================
  // PUBLIC GETTERS
  // =====================================================================

  /// Get current user level
  UserLevel get currentLevel => _userLevel;

  /// Get all unlocked achievements
  List<Achievement> get unlockedAchievements {
    return _achievements.values
        .where((achievement) {
          final progress = _progress[achievement.id];
          return progress != null && progress.isUnlocked;
        })
        .toList();
  }

  /// Get all achievements
  List<Achievement> get allAchievements => _achievements.values.toList();

  // =====================================================================
  // LISTENERS
  // =====================================================================

  /// Add unlock listener
  void addUnlockListener(Function(Achievement, AchievementProgress) listener) {
    _unlockListeners.add(listener);
  }

  /// Add level up listener
  void addLevelUpListener(Function(UserLevel) listener) {
    _levelUpListeners.add(listener);
  }

  /// Get all achievements
  List<Achievement> getAllAchievements() => _achievements.values.toList();

  /// Get achievements by category
  List<Achievement> getAchievementsByCategory(AchievementCategory category) {
    return _achievements.values.where((a) => a.category == category).toList();
  }

  /// Get achievement progress
  AchievementProgress? getProgress(String achievementId) => _progress[achievementId];

  /// Get user level
  UserLevel getUserLevel() => _userLevel;

  /// Get unlocked achievements count
  int getUnlockedCount() => _progress.values.where((p) => p.isUnlocked).length;

  /// Get total achievements count
  int getTotalCount() => _achievements.length;

  /// Get unviewed unlocked achievements
  List<Achievement> getUnviewedAchievements() {
    return _achievements.values.where((achievement) {
      final progress = _progress[achievement.id];
      return progress != null && progress.isUnlocked && !progress.isViewed;
    }).toList();
  }

  /// Mark achievement as viewed
  Future<void> markAsViewed(String achievementId) async {
    final progress = _progress[achievementId];
    if (progress != null) {
      progress.isViewed = true;
      await _saveProgress();
    }
  }
}
