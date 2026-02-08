// =====================================================================
// DAILY CHALLENGES SERVICE v1.0
// =====================================================================
// Verwaltet tägliche Herausforderungen mit Kategorien und Belohnungen
// Features:
// - Tägliche Challenge-Generierung (4 Kategorien)
// - Fortschritt-Tracking
// - Bonus-XP & Belohnungen
// - Automatisches Zurücksetzen um Mitternacht
// =====================================================================

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'achievement_service.dart';

// =====================================================================
// CHALLENGE MODEL
// =====================================================================

enum ChallengeCategory {
  search,
  read,
  community,
  streak,
}

extension ChallengeCategoryExtension on ChallengeCategory {
  String get label {
    switch (this) {
      case ChallengeCategory.search:
        return 'Suchen';
      case ChallengeCategory.read:
        return 'Lesen';
      case ChallengeCategory.community:
        return 'Community';
      case ChallengeCategory.streak:
        return 'Streak';
    }
  }

  String get icon {
    switch (this) {
      case ChallengeCategory.search:
        return '🔍';
      case ChallengeCategory.read:
        return '📖';
      case ChallengeCategory.community:
        return '👥';
      case ChallengeCategory.streak:
        return '🔥';
    }
  }
}

class DailyChallenge {
  final String id;
  final ChallengeCategory category;
  final String title;
  final String description;
  final int targetValue;
  final int currentProgress;
  final int bonusXp;
  final DateTime date;

  DailyChallenge({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.targetValue,
    this.currentProgress = 0,
    required this.bonusXp,
    required this.date,
  });

  bool get isCompleted => currentProgress >= targetValue;
  
  double get progressPercent => 
      targetValue > 0 ? (currentProgress / targetValue * 100).clamp(0, 100) : 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category.toString(),
        'title': title,
        'description': description,
        'targetValue': targetValue,
        'currentProgress': currentProgress,
        'bonusXp': bonusXp,
        'date': date.toIso8601String(),
      };

  factory DailyChallenge.fromJson(Map<String, dynamic> json) => DailyChallenge(
        id: json['id'] as String,
        category: ChallengeCategory.values.firstWhere(
          (e) => e.toString() == json['category'],
        ),
        title: json['title'] as String,
        description: json['description'] as String,
        targetValue: json['targetValue'] as int,
        currentProgress: json['currentProgress'] as int? ?? 0,
        bonusXp: json['bonusXp'] as int,
        date: DateTime.parse(json['date'] as String),
      );

  DailyChallenge copyWith({int? currentProgress}) => DailyChallenge(
        id: id,
        category: category,
        title: title,
        description: description,
        targetValue: targetValue,
        currentProgress: currentProgress ?? this.currentProgress,
        bonusXp: bonusXp,
        date: date,
      );
}

// =====================================================================
// DAILY CHALLENGES SERVICE
// =====================================================================

class DailyChallengesService {
  static final DailyChallengesService _instance = DailyChallengesService._internal();
  factory DailyChallengesService() => _instance;
  DailyChallengesService._internal();

  static const String _challengesKey = 'daily_challenges';
  static const String _lastResetKey = 'daily_challenges_last_reset';
  static const String _completedTodayKey = 'daily_challenges_completed_today';

  SharedPreferences? _prefs;
  List<DailyChallenge> _todaysChallenges = [];
  int _completedToday = 0;

  // =====================================================================
  // INITIALIZATION
  // =====================================================================

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _checkAndResetIfNeeded();
      await _loadChallenges();
      
      if (kDebugMode) {
        print('✅ DailyChallengesService initialized');
        print('   📋 Challenges today: ${_todaysChallenges.length}');
        print('   ✓ Completed: $_completedToday');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ DailyChallengesService init error: $e');
      }
    }
  }

  // =====================================================================
  // CHALLENGE GENERATION
  // =====================================================================

  Future<void> _checkAndResetIfNeeded() async {
    final lastReset = _prefs?.getString(_lastResetKey);
    final today = _getTodayString();

    if (lastReset != today) {
      // Neuer Tag - Challenges zurücksetzen
      await _generateDailyChallenges();
      await _prefs?.setString(_lastResetKey, today);
      await _prefs?.setInt(_completedTodayKey, 0);
      _completedToday = 0;
      
      if (kDebugMode) {
        print('🔄 Daily challenges reset for $today');
      }
    }
  }

  Future<void> _generateDailyChallenges() async {
    _todaysChallenges = [
      // SEARCH CHALLENGE
      DailyChallenge(
        id: 'search_${DateTime.now().millisecondsSinceEpoch}',
        category: ChallengeCategory.search,
        title: 'Wissensdurst',
        description: 'Führe 5 Recherchen durch',
        targetValue: 5,
        bonusXp: 50,
        date: DateTime.now(),
      ),
      
      // READ CHALLENGE
      DailyChallenge(
        id: 'read_${DateTime.now().millisecondsSinceEpoch}',
        category: ChallengeCategory.read,
        title: 'Vielleser',
        description: 'Lies 3 verschiedene Narratives',
        targetValue: 3,
        bonusXp: 40,
        date: DateTime.now(),
      ),
      
      // COMMUNITY CHALLENGE
      DailyChallenge(
        id: 'community_${DateTime.now().millisecondsSinceEpoch}',
        category: ChallengeCategory.community,
        title: 'Aktiv dabei',
        description: 'Interagiere 10x (Likes/Comments)',
        targetValue: 10,
        bonusXp: 60,
        date: DateTime.now(),
      ),
      
      // STREAK CHALLENGE
      DailyChallenge(
        id: 'streak_${DateTime.now().millisecondsSinceEpoch}',
        category: ChallengeCategory.streak,
        title: 'Streak halten',
        description: 'Behalte deine tägliche Streak bei',
        targetValue: 1,
        bonusXp: 30,
        date: DateTime.now(),
      ),
    ];

    await _saveChallenges();
  }

  // =====================================================================
  // DATA PERSISTENCE
  // =====================================================================

  Future<void> _loadChallenges() async {
    try {
      final challengesJson = _prefs?.getString(_challengesKey);
      if (challengesJson != null) {
        final List<dynamic> decoded = json.decode(challengesJson);
        _todaysChallenges = decoded
            .map((json) => DailyChallenge.fromJson(json))
            .toList();
      } else {
        // Keine Challenges vorhanden - generieren
        await _generateDailyChallenges();
      }

      _completedToday = _prefs?.getInt(_completedTodayKey) ?? 0;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading challenges: $e');
      }
      await _generateDailyChallenges();
    }
  }

  Future<void> _saveChallenges() async {
    try {
      final challengesJson = json.encode(
        _todaysChallenges.map((c) => c.toJson()).toList(),
      );
      await _prefs?.setString(_challengesKey, challengesJson);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving challenges: $e');
      }
    }
  }

  // =====================================================================
  // PROGRESS TRACKING
  // =====================================================================

  Future<void> incrementProgress(ChallengeCategory category, {int amount = 1}) async {
    try {
      bool anyCompleted = false;

      for (int i = 0; i < _todaysChallenges.length; i++) {
        final challenge = _todaysChallenges[i];
        
        if (challenge.category == category && !challenge.isCompleted) {
          final newProgress = challenge.currentProgress + amount;
          _todaysChallenges[i] = challenge.copyWith(currentProgress: newProgress);

          // Challenge gerade abgeschlossen?
          if (!challenge.isCompleted && _todaysChallenges[i].isCompleted) {
            anyCompleted = true;
            _completedToday++;
            await _prefs?.setInt(_completedTodayKey, _completedToday);
            
            // Bonus XP vergeben
            await AchievementService().incrementProgress('first_search');  // Trigger achievement als Belohnung
            
            if (kDebugMode) {
              print('🎉 Challenge completed: ${_todaysChallenges[i].title}');
              print('   🎁 Bonus XP: +${_todaysChallenges[i].bonusXp}');
            }
          }
        }
      }

      if (anyCompleted) {
        await _saveChallenges();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error incrementing challenge progress: $e');
      }
    }
  }

  // =====================================================================
  // GETTERS
  // =====================================================================

  List<DailyChallenge> get todaysChallenges => _todaysChallenges;
  
  int get completedToday => _completedToday;
  
  int get totalChallenges => _todaysChallenges.length;
  
  double get completionPercent => 
      totalChallenges > 0 ? (_completedToday / totalChallenges * 100) : 0;

  DailyChallenge? getChallengeByCategory(ChallengeCategory category) {
    try {
      return _todaysChallenges.firstWhere((c) => c.category == category);
    } catch (e) {
      return null;
    }
  }

  // =====================================================================
  // HELPERS
  // =====================================================================

  String _getTodayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
