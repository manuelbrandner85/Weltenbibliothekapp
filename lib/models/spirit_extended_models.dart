import 'package:flutter/material.dart';

/// ============================================
/// SPIRIT EXTENDED MODELS
/// Neue Datenmodelle für erweiterte Spirit-Features
/// ============================================

/// VORSCHLAG 1: TÄGLICHE SPIRIT-ÜBUNG
class DailySpiritPractice {
  final String id;
  final String title;
  final String description;
  final String category; // meditation, breathing, chakra, journal
  final int durationMinutes;
  final String basedOn; // cycle, archetype, chakra
  final DateTime recommendedDate;
  final bool completed;
  final DateTime? completedAt;

  DailySpiritPractice({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.durationMinutes,
    required this.basedOn,
    required this.recommendedDate,
    this.completed = false,
    this.completedAt,
  });

  // Für Hive Storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'durationMinutes': durationMinutes,
      'basedOn': basedOn,
      'recommendedDate': recommendedDate.toIso8601String(),
      'completed': completed,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory DailySpiritPractice.fromJson(Map<String, dynamic> json) {
    return DailySpiritPractice(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      durationMinutes: json['durationMinutes'] as int,
      basedOn: json['basedOn'] as String,
      recommendedDate: DateTime.parse(json['recommendedDate'] as String),
      completed: json['completed'] as bool? ?? false,
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt'] as String) 
          : null,
    );
  }

  // Copy with Methode für Updates
  DailySpiritPractice copyWith({
    bool? completed,
    DateTime? completedAt,
  }) {
    return DailySpiritPractice(
      id: id,
      title: title,
      description: description,
      category: category,
      durationMinutes: durationMinutes,
      basedOn: basedOn,
      recommendedDate: recommendedDate,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

/// VORSCHLAG 2: SYNCHRONIZITÄTS-EINTRAG (erweitert)
class SynchronicityEntry {
  final String id;
  final DateTime timestamp;
  final String event;
  final String meaning;
  final List<String> tags;
  final List<int> numbers; // Wiederkehrende Zahlen (z.B. 11:11)
  final int significance; // 1-5 Skala

  SynchronicityEntry({
    required this.id,
    required this.timestamp,
    required this.event,
    required this.meaning,
    required this.tags,
    required this.numbers,
    required this.significance,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'event': event,
      'meaning': meaning,
      'tags': tags,
      'numbers': numbers,
      'significance': significance,
    };
  }

  factory SynchronicityEntry.fromJson(Map<String, dynamic> json) {
    return SynchronicityEntry(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      event: json['event'] as String,
      meaning: json['meaning'] as String,
      tags: List<String>.from(json['tags'] as List),
      numbers: List<int>.from(json['numbers'] as List),
      significance: json['significance'] as int,
    );
  }
}

/// VORSCHLAG 4: ASTRO-TRANSIT-EVENT
class AstroTransitEvent {
  final DateTime date;
  final String eventType; // fullmoon, newmoon, mercury_retrograde, etc.
  final String title;
  final String description;
  final String influence; // positive, neutral, challenging
  final List<String> recommendations;

  AstroTransitEvent({
    required this.date,
    required this.eventType,
    required this.title,
    required this.description,
    required this.influence,
    required this.recommendations,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'eventType': eventType,
      'title': title,
      'description': description,
      'influence': influence,
      'recommendations': recommendations,
    };
  }

  factory AstroTransitEvent.fromJson(Map<String, dynamic> json) {
    return AstroTransitEvent(
      date: DateTime.parse(json['date'] as String),
      eventType: json['eventType'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      influence: json['influence'] as String,
      recommendations: List<String>.from(json['recommendations'] as List),
    );
  }
}

/// VORSCHLAG 5: SPIRIT-JOURNAL-EINTRAG (erweitert)
class SpiritJournalEntry {
  final String id;
  final DateTime timestamp;
  final String category; // dream, meditation, synchronicity, insight
  final String content;
  final String mood; // joy, peace, sadness, fear, anger, love, neutral
  final List<String> tags;
  final int? rating; // 1-5 optional

  SpiritJournalEntry({
    required this.id,
    required this.timestamp,
    required this.category,
    required this.content,
    required this.mood,
    required this.tags,
    this.rating,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'category': category,
      'content': content,
      'mood': mood,
      'tags': tags,
      'rating': rating,
    };
  }

  factory SpiritJournalEntry.fromJson(Map<String, dynamic> json) {
    return SpiritJournalEntry(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      category: json['category'] as String,
      content: json['content'] as String,
      mood: json['mood'] as String,
      tags: List<String>.from(json['tags'] as List),
      rating: json['rating'] as int?,
    );
  }
}

/// VORSCHLAG 6: PARTNER-PROFIL FÜR KOMPATIBILITÄT
class PartnerProfile {
  final String id;
  final String name;
  final DateTime birthDate;
  final int lifePathNumber;
  final Map<String, dynamic> archetype;
  final DateTime createdAt;

  PartnerProfile({
    required this.id,
    required this.name,
    required this.birthDate,
    required this.lifePathNumber,
    required this.archetype,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'birthDate': birthDate.toIso8601String(),
      'lifePathNumber': lifePathNumber,
      'archetype': archetype,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PartnerProfile.fromJson(Map<String, dynamic> json) {
    return PartnerProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      birthDate: DateTime.parse(json['birthDate'] as String),
      lifePathNumber: json['lifePathNumber'] as int,
      archetype: Map<String, dynamic>.from(json['archetype'] as Map),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// VORSCHLAG 6: KOMPATIBILITÄTS-ANALYSE
class CompatibilityAnalysis {
  final String userId;
  final String partnerId;
  final int compatibilityScore; // 0-100
  final List<String> strengths;
  final List<String> challenges;
  final List<String> communicationTips;
  final DateTime analyzedAt;

  CompatibilityAnalysis({
    required this.userId,
    required this.partnerId,
    required this.compatibilityScore,
    required this.strengths,
    required this.challenges,
    required this.communicationTips,
    required this.analyzedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'partnerId': partnerId,
      'compatibilityScore': compatibilityScore,
      'strengths': strengths,
      'challenges': challenges,
      'communicationTips': communicationTips,
      'analyzedAt': analyzedAt.toIso8601String(),
    };
  }

  factory CompatibilityAnalysis.fromJson(Map<String, dynamic> json) {
    return CompatibilityAnalysis(
      userId: json['userId'] as String,
      partnerId: json['partnerId'] as String,
      compatibilityScore: json['compatibilityScore'] as int,
      strengths: List<String>.from(json['strengths'] as List),
      challenges: List<String>.from(json['challenges'] as List),
      communicationTips: List<String>.from(json['communicationTips'] as List),
      analyzedAt: DateTime.parse(json['analyzedAt'] as String),
    );
  }
}

/// VORSCHLAG 7: WOCHENHOROSKOP
class WeeklyHoroscope {
  final DateTime weekStart;
  final DateTime weekEnd;
  final String overallTheme;
  final Map<String, String> categories; // love, career, health, spirituality
  final List<String> luckyDays;
  final List<String> challengingDays;
  final String specialAdvice;

  WeeklyHoroscope({
    required this.weekStart,
    required this.weekEnd,
    required this.overallTheme,
    required this.categories,
    required this.luckyDays,
    required this.challengingDays,
    required this.specialAdvice,
  });

  Map<String, dynamic> toJson() {
    return {
      'weekStart': weekStart.toIso8601String(),
      'weekEnd': weekEnd.toIso8601String(),
      'overallTheme': overallTheme,
      'categories': categories,
      'luckyDays': luckyDays,
      'challengingDays': challengingDays,
      'specialAdvice': specialAdvice,
    };
  }

  factory WeeklyHoroscope.fromJson(Map<String, dynamic> json) {
    return WeeklyHoroscope(
      weekStart: DateTime.parse(json['weekStart'] as String),
      weekEnd: DateTime.parse(json['weekEnd'] as String),
      overallTheme: json['overallTheme'] as String,
      categories: Map<String, String>.from(json['categories'] as Map),
      luckyDays: List<String>.from(json['luckyDays'] as List),
      challengingDays: List<String>.from(json['challengingDays'] as List),
      specialAdvice: json['specialAdvice'] as String,
    );
  }
}

/// VORSCHLAG 8: GAMIFICATION - USER PROGRESS
class SpiritProgress {
  final int totalPoints;
  final int currentLevel;
  final int pointsToNextLevel;
  final List<String> unlockedAchievements;
  final Map<String, int> activityCounts; // meditation: 10, journal: 5, etc.
  final int currentStreak;
  final int longestStreak;
  final DateTime lastActivityDate;

  SpiritProgress({
    required this.totalPoints,
    required this.currentLevel,
    required this.pointsToNextLevel,
    required this.unlockedAchievements,
    required this.activityCounts,
    required this.currentStreak,
    required this.longestStreak,
    required this.lastActivityDate,
  });

  // Level-Name basierend auf Level-Nummer
  String get levelName {
    if (currentLevel < 5) return 'Suchender';
    if (currentLevel < 10) return 'Erwachter';
    if (currentLevel < 20) return 'Schüler';
    if (currentLevel < 30) return 'Praktizierender';
    if (currentLevel < 40) return 'Meister';
    if (currentLevel < 50) return 'Weiser';
    return 'Erleuchteter';
  }

  Map<String, dynamic> toJson() {
    return {
      'totalPoints': totalPoints,
      'currentLevel': currentLevel,
      'pointsToNextLevel': pointsToNextLevel,
      'unlockedAchievements': unlockedAchievements,
      'activityCounts': activityCounts,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastActivityDate': lastActivityDate.toIso8601String(),
    };
  }

  factory SpiritProgress.fromJson(Map<String, dynamic> json) {
    return SpiritProgress(
      totalPoints: json['totalPoints'] as int,
      currentLevel: json['currentLevel'] as int,
      pointsToNextLevel: json['pointsToNextLevel'] as int,
      unlockedAchievements: List<String>.from(json['unlockedAchievements'] as List),
      activityCounts: Map<String, int>.from(json['activityCounts'] as Map),
      currentStreak: json['currentStreak'] as int,
      longestStreak: json['longestStreak'] as int,
      lastActivityDate: DateTime.parse(json['lastActivityDate'] as String),
    );
  }

  // Leeres Progress-Objekt für neue User
  factory SpiritProgress.empty() {
    return SpiritProgress(
      totalPoints: 0,
      currentLevel: 1,
      pointsToNextLevel: 100,
      unlockedAchievements: [],
      activityCounts: {},
      currentStreak: 0,
      longestStreak: 0,
      lastActivityDate: DateTime.now(),
    );
  }
}

/// ============================================
/// ACHIEVEMENT SYSTEM
/// ============================================

/// Achievement-Kategorien
enum AchievementCategory {
  streak,      // Streak-bezogen
  checkIn,     // Check-In-bezogen
  favorites,   // Favoriten-bezogen
  spiritTools, // Spirit-Tools-bezogen
  points,      // Punkte-bezogen
  special,     // Spezielle Achievements
}

/// VORSCHLAG 8: ACHIEVEMENT DEFINITION
class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int requiredCount;
  final AchievementCategory category;
  final DateTime? unlockedAt; // Zeitpunkt des Freischaltens

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.requiredCount,
    required this.category,
    this.unlockedAt,
  });

  // JSON-Serialisierung
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'requiredCount': requiredCount,
      'category': category.name,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      icon: Icons.stars, // Default Icon
      color: Colors.amber,
      requiredCount: json['requiredCount'] as int,
      category: AchievementCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => AchievementCategory.special,
      ),
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
    );
  }

  // Copy-with für Unlock-Timestamp
  Achievement copyWith({DateTime? unlockedAt}) {
    return Achievement(
      id: id,
      title: title,
      description: description,
      icon: icon,
      color: color,
      requiredCount: requiredCount,
      category: category,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  // Prüfen ob freigeschaltet
  bool get isUnlocked => unlockedAt != null;
}
