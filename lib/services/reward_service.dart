// =====================================================================
// REWARD SYSTEM SERVICE v1.0
// =====================================================================
// Verwaltet Belohnungen und Milestones
// Features:
// - Achievement Milestone Rewards
// - Streak Rewards
// - Level-Up Bonuses
// - Special Event Rewards
// =====================================================================

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// =====================================================================
// REWARD MODEL
// =====================================================================

enum RewardType {
  xpBonus,
  badge,
  title,
  special,
}

extension RewardTypeExtension on RewardType {
  String get label {
    switch (this) {
      case RewardType.xpBonus:
        return 'XP Bonus';
      case RewardType.badge:
        return 'Badge';
      case RewardType.title:
        return 'Titel';
      case RewardType.special:
        return 'Special';
    }
  }

  String get icon {
    switch (this) {
      case RewardType.xpBonus:
        return '⭐';
      case RewardType.badge:
        return '🏅';
      case RewardType.title:
        return '👑';
      case RewardType.special:
        return '🎁';
    }
  }
}

class Reward {
  final String id;
  final RewardType type;
  final String title;
  final String description;
  final int value; // XP Bonus amount or badge level
  final String icon;
  final DateTime unlockedAt;

  Reward({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.value,
    required this.icon,
    required this.unlockedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.toString(),
        'title': title,
        'description': description,
        'value': value,
        'icon': icon,
        'unlockedAt': unlockedAt.toIso8601String(),
      };

  factory Reward.fromJson(Map<String, dynamic> json) => Reward(
        id: json['id'] as String,
        type: RewardType.values.firstWhere(
          (e) => e.toString() == json['type'],
        ),
        title: json['title'] as String,
        description: json['description'] as String,
        value: json['value'] as int,
        icon: json['icon'] as String,
        unlockedAt: DateTime.parse(json['unlockedAt'] as String),
      );
}

// =====================================================================
// MILESTONE
// =====================================================================

class Milestone {
  final String id;
  final String title;
  final String description;
  final int targetValue;
  final String category; // 'achievements', 'level', 'streak', 'xp'
  final Reward reward;
  final bool isUnlocked;

  Milestone({
    required this.id,
    required this.title,
    required this.description,
    required this.targetValue,
    required this.category,
    required this.reward,
    this.isUnlocked = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'targetValue': targetValue,
        'category': category,
        'reward': reward.toJson(),
        'isUnlocked': isUnlocked,
      };

  factory Milestone.fromJson(Map<String, dynamic> json) => Milestone(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        targetValue: json['targetValue'] as int,
        category: json['category'] as String,
        reward: Reward.fromJson(json['reward'] as Map<String, dynamic>),
        isUnlocked: json['isUnlocked'] as bool? ?? false,
      );
}

// =====================================================================
// REWARD SERVICE
// =====================================================================

class RewardService {
  static final RewardService _instance = RewardService._internal();
  factory RewardService() => _instance;
  RewardService._internal();

  static const String _rewardsKey = 'unlocked_rewards';
  static const String _milestonesKey = 'milestones';

  SharedPreferences? _prefs;
  List<Reward> _unlockedRewards = [];
  List<Milestone> _milestones = [];

  // =====================================================================
  // INITIALIZATION
  // =====================================================================

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadRewards();
      await _loadMilestones();
      
      if (kDebugMode) {
        print('✅ RewardService initialized');
        print('   🎁 Unlocked rewards: ${_unlockedRewards.length}');
        print('   🎯 Milestones: ${_milestones.length}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ RewardService init error: $e');
      }
    }
  }

  // =====================================================================
  // DATA PERSISTENCE
  // =====================================================================

  Future<void> _loadRewards() async {
    try {
      final rewardsJson = _prefs?.getString(_rewardsKey);
      if (rewardsJson != null) {
        final List<dynamic> decoded = json.decode(rewardsJson);
        _unlockedRewards = decoded.map((json) => Reward.fromJson(json)).toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading rewards: $e');
      }
    }
  }

  Future<void> _saveRewards() async {
    try {
      final rewardsJson = json.encode(
        _unlockedRewards.map((r) => r.toJson()).toList(),
      );
      await _prefs?.setString(_rewardsKey, rewardsJson);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving rewards: $e');
      }
    }
  }

  Future<void> _loadMilestones() async {
    try {
      final milestonesJson = _prefs?.getString(_milestonesKey);
      if (milestonesJson != null) {
        final List<dynamic> decoded = json.decode(milestonesJson);
        _milestones = decoded.map((json) => Milestone.fromJson(json)).toList();
      } else {
        // Generate default milestones
        _milestones = _generateDefaultMilestones();
        await _saveMilestones();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading milestones: $e');
      }
      _milestones = _generateDefaultMilestones();
    }
  }

  Future<void> _saveMilestones() async {
    try {
      final milestonesJson = json.encode(
        _milestones.map((m) => m.toJson()).toList(),
      );
      await _prefs?.setString(_milestonesKey, milestonesJson);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving milestones: $e');
      }
    }
  }

  // =====================================================================
  // MILESTONE GENERATION
  // =====================================================================

  List<Milestone> _generateDefaultMilestones() {
    return [
      // ACHIEVEMENT MILESTONES
      Milestone(
        id: 'milestone_achievements_5',
        title: 'Erste Erfolge',
        description: 'Schalte 5 Achievements frei',
        targetValue: 5,
        category: 'achievements',
        reward: Reward(
          id: 'reward_achievements_5',
          type: RewardType.xpBonus,
          title: '100 XP Bonus',
          description: 'Bonus für 5 Achievements',
          value: 100,
          icon: '⭐',
          unlockedAt: DateTime.now(),
        ),
      ),
      Milestone(
        id: 'milestone_achievements_10',
        title: 'Erfolgssammler',
        description: 'Schalte 10 Achievements frei',
        targetValue: 10,
        category: 'achievements',
        reward: Reward(
          id: 'reward_achievements_10',
          type: RewardType.badge,
          title: 'Erfolgssammler Badge',
          description: 'Spezielles Badge für 10 Achievements',
          value: 1,
          icon: '🏅',
          unlockedAt: DateTime.now(),
        ),
      ),
      Milestone(
        id: 'milestone_achievements_20',
        title: 'Meister der Erfolge',
        description: 'Schalte alle 20 Achievements frei',
        targetValue: 20,
        category: 'achievements',
        reward: Reward(
          id: 'reward_achievements_20',
          type: RewardType.title,
          title: 'Titel: Meister',
          description: 'Exklusiver Titel für alle Achievements',
          value: 1,
          icon: '👑',
          unlockedAt: DateTime.now(),
        ),
      ),

      // LEVEL MILESTONES
      Milestone(
        id: 'milestone_level_5',
        title: 'Aufsteiger',
        description: 'Erreiche Level 5',
        targetValue: 5,
        category: 'level',
        reward: Reward(
          id: 'reward_level_5',
          type: RewardType.xpBonus,
          title: '200 XP Bonus',
          description: 'Bonus für Level 5',
          value: 200,
          icon: '⭐',
          unlockedAt: DateTime.now(),
        ),
      ),
      Milestone(
        id: 'milestone_level_10',
        title: 'Veteran',
        description: 'Erreiche Level 10',
        targetValue: 10,
        category: 'level',
        reward: Reward(
          id: 'reward_level_10',
          type: RewardType.special,
          title: 'Veteran Badge',
          description: 'Spezielles Badge für Level 10',
          value: 1,
          icon: '🎖️',
          unlockedAt: DateTime.now(),
        ),
      ),

      // STREAK MILESTONES
      Milestone(
        id: 'milestone_streak_7',
        title: 'Wochenkrieger',
        description: 'Halte eine 7-Tage Streak',
        targetValue: 7,
        category: 'streak',
        reward: Reward(
          id: 'reward_streak_7',
          type: RewardType.xpBonus,
          title: '150 XP Bonus',
          description: 'Bonus für 7-Tage Streak',
          value: 150,
          icon: '🔥',
          unlockedAt: DateTime.now(),
        ),
      ),
      Milestone(
        id: 'milestone_streak_30',
        title: 'Streak-Legende',
        description: 'Halte eine 30-Tage Streak',
        targetValue: 30,
        category: 'streak',
        reward: Reward(
          id: 'reward_streak_30',
          type: RewardType.title,
          title: 'Titel: Legende',
          description: 'Legendärer Titel für 30-Tage Streak',
          value: 1,
          icon: '👑',
          unlockedAt: DateTime.now(),
        ),
      ),

      // XP MILESTONES
      Milestone(
        id: 'milestone_xp_1000',
        title: 'Sammler',
        description: 'Sammle 1.000 XP',
        targetValue: 1000,
        category: 'xp',
        reward: Reward(
          id: 'reward_xp_1000',
          type: RewardType.xpBonus,
          title: '250 XP Bonus',
          description: 'Bonus für 1.000 XP',
          value: 250,
          icon: '💎',
          unlockedAt: DateTime.now(),
        ),
      ),
      Milestone(
        id: 'milestone_xp_5000',
        title: 'XP Meister',
        description: 'Sammle 5.000 XP',
        targetValue: 5000,
        category: 'xp',
        reward: Reward(
          id: 'reward_xp_5000',
          type: RewardType.special,
          title: 'Goldene Auszeichnung',
          description: 'Spezielle Auszeichnung für 5.000 XP',
          value: 1,
          icon: '🏆',
          unlockedAt: DateTime.now(),
        ),
      ),
    ];
  }

  // =====================================================================
  // MILESTONE CHECK
  // =====================================================================

  Future<List<Reward>> checkMilestones({
    int? achievementCount,
    int? level,
    int? streak,
    int? totalXp,
  }) async {
    final List<Reward> newRewards = [];

    for (int i = 0; i < _milestones.length; i++) {
      final milestone = _milestones[i];
      
      if (!milestone.isUnlocked) {
        bool shouldUnlock = false;

        switch (milestone.category) {
          case 'achievements':
            if (achievementCount != null && achievementCount >= milestone.targetValue) {
              shouldUnlock = true;
            }
            break;
          case 'level':
            if (level != null && level >= milestone.targetValue) {
              shouldUnlock = true;
            }
            break;
          case 'streak':
            if (streak != null && streak >= milestone.targetValue) {
              shouldUnlock = true;
            }
            break;
          case 'xp':
            if (totalXp != null && totalXp >= milestone.targetValue) {
              shouldUnlock = true;
            }
            break;
        }

        if (shouldUnlock) {
          // Unlock milestone
          _milestones[i] = Milestone(
            id: milestone.id,
            title: milestone.title,
            description: milestone.description,
            targetValue: milestone.targetValue,
            category: milestone.category,
            reward: milestone.reward,
            isUnlocked: true,
          );

          // Add reward
          _unlockedRewards.add(milestone.reward);
          newRewards.add(milestone.reward);

          if (kDebugMode) {
            print('🎁 Milestone unlocked: ${milestone.title}');
            print('   Reward: ${milestone.reward.title}');
          }
        }
      }
    }

    if (newRewards.isNotEmpty) {
      await _saveRewards();
      await _saveMilestones();
    }

    return newRewards;
  }

  // =====================================================================
  // GETTERS
  // =====================================================================

  List<Reward> get unlockedRewards => _unlockedRewards;
  List<Milestone> get milestones => _milestones;
  
  List<Milestone> get unlockedMilestones => 
      _milestones.where((m) => m.isUnlocked).toList();
  
  List<Milestone> get lockedMilestones => 
      _milestones.where((m) => !m.isUnlocked).toList();
  
  int get totalRewardValue => _unlockedRewards
      .where((r) => r.type == RewardType.xpBonus)
      .fold(0, (sum, r) => sum + r.value);
}
