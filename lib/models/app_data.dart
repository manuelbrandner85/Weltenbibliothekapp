/// ═══════════════════════════════════════════════════════════
/// WELTENBIBLIOTHEK - APP DATA MODELS
/// Zentrale Datenmodelle für Storage & State Management
/// v57 - TOP 10 VERBESSERUNGEN
/// ═══════════════════════════════════════════════════════════
library;

// ═══════════════════════════════════════════════════════════
// 1. TAROT JOURNAL - Tarot-Ziehungen Historie
// ═══════════════════════════════════════════════════════════

class TarotReading {
  final String id;
  final DateTime timestamp;
  final String cardName;
  final String cardSymbol;
  final String cardMeaning;
  final String? personalNote;
  final String spreadType; // 'single', '3-card', 'celtic'

  TarotReading({
    required this.id,
    required this.timestamp,
    required this.cardName,
    required this.cardSymbol,
    required this.cardMeaning,
    this.personalNote,
    this.spreadType = 'single',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'cardName': cardName,
        'cardSymbol': cardSymbol,
        'cardMeaning': cardMeaning,
        'personalNote': personalNote,
        'spreadType': spreadType,
      };

  factory TarotReading.fromJson(Map<String, dynamic> json) => TarotReading(
        id: json['id'] ?? '',
        timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
        cardName: json['cardName'] ?? '',
        cardSymbol: json['cardSymbol'] ?? '',
        cardMeaning: json['cardMeaning'] ?? '',
        personalNote: json['personalNote'],
        spreadType: json['spreadType'] ?? 'single',
      );
}

// ═══════════════════════════════════════════════════════════
// 2. MONDTAGEBUCH - Mondphasen Notizen
// ═══════════════════════════════════════════════════════════

class MoonJournalEntry {
  final String id;
  final DateTime timestamp;
  final String moonPhase; // 'neumond', 'zunehmend', 'vollmond', 'abnehmend'
  final String note;
  final List<String> emotions; // ['Freude', 'Ruhe', 'Energie']
  final int energyLevel; // 1-10

  MoonJournalEntry({
    required this.id,
    required this.timestamp,
    required this.moonPhase,
    required this.note,
    this.emotions = const [],
    this.energyLevel = 5,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'moonPhase': moonPhase,
        'note': note,
        'emotions': emotions,
        'energyLevel': energyLevel,
      };

  factory MoonJournalEntry.fromJson(Map<String, dynamic> json) => MoonJournalEntry(
        id: json['id'] ?? '',
        timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
        moonPhase: json['moonPhase'] ?? '',
        note: json['note'] ?? '',
        emotions: List<String>.from(json['emotions'] ?? []),
        energyLevel: json['energyLevel'] ?? 5,
      );
}

// ═══════════════════════════════════════════════════════════
// 3. KRISTALL-SAMMLUNG - Persönliche Kristalle
// ═══════════════════════════════════════════════════════════

class CrystalCollection {
  final String crystalName;
  final DateTime addedDate;
  final String? note;
  final String? purchaseLocation;
  final List<String> experiencedEffects;

  CrystalCollection({
    required this.crystalName,
    required this.addedDate,
    this.note,
    this.purchaseLocation,
    this.experiencedEffects = const [],
  });

  Map<String, dynamic> toJson() => {
        'crystalName': crystalName,
        'addedDate': addedDate.toIso8601String(),
        'note': note,
        'purchaseLocation': purchaseLocation,
        'experiencedEffects': experiencedEffects,
      };

  factory CrystalCollection.fromJson(Map<String, dynamic> json) => CrystalCollection(
        crystalName: json['crystalName'] ?? '',
        addedDate: DateTime.parse(json['addedDate'] ?? DateTime.now().toIso8601String()),
        note: json['note'],
        purchaseLocation: json['purchaseLocation'],
        experiencedEffects: List<String>.from(json['experiencedEffects'] ?? []),
      );
}

// ═══════════════════════════════════════════════════════════
// 4. MANTRA-CHALLENGE - 21-Tage-Tracking
// ═══════════════════════════════════════════════════════════

class MantraChallenge {
  final String id;
  final String mantraText;
  final DateTime startDate;
  final List<DateTime> completedDays;
  final bool isCompleted;
  final String? completionNote;

  MantraChallenge({
    required this.id,
    required this.mantraText,
    required this.startDate,
    this.completedDays = const [],
    this.isCompleted = false,
    this.completionNote,
  });

  int get currentStreak => completedDays.length;
  int get remainingDays => 21 - completedDays.length;
  double get progress => (completedDays.length / 21.0).clamp(0.0, 1.0);

  Map<String, dynamic> toJson() => {
        'id': id,
        'mantraText': mantraText,
        'startDate': startDate.toIso8601String(),
        'completedDays': completedDays.map((d) => d.toIso8601String()).toList(),
        'isCompleted': isCompleted,
        'completionNote': completionNote,
      };

  factory MantraChallenge.fromJson(Map<String, dynamic> json) => MantraChallenge(
        id: json['id'] ?? '',
        mantraText: json['mantraText'] ?? '',
        startDate: DateTime.parse(json['startDate'] ?? DateTime.now().toIso8601String()),
        completedDays: (json['completedDays'] as List<dynamic>?)
                ?.map((d) => DateTime.parse(d as String))
                .toList() ??
            [],
        isCompleted: json['isCompleted'] ?? false,
        completionNote: json['completionNote'],
      );
}

// ═══════════════════════════════════════════════════════════
// 5. MEDITATION STATISTIK - Tracking
// ═══════════════════════════════════════════════════════════

class MeditationSession {
  final String id;
  final DateTime timestamp;
  final int durationMinutes;
  final String meditationType; // 'breath', 'body_scan', 'mantra', 'visualization', 'chakra'

  MeditationSession({
    required this.id,
    required this.timestamp,
    required this.durationMinutes,
    this.meditationType = 'breath',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'durationMinutes': durationMinutes,
        'meditationType': meditationType,
      };

  factory MeditationSession.fromJson(Map<String, dynamic> json) => MeditationSession(
        id: json['id'] ?? '',
        timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
        durationMinutes: json['durationMinutes'] ?? 0,
        meditationType: json['meditationType'] ?? 'breath',
      );
}

// ═══════════════════════════════════════════════════════════
// 6. APP ACHIEVEMENTS - Badge-System (v57)
// ═══════════════════════════════════════════════════════════

class AppAchievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final DateTime? unlockedAt;
  final bool isUnlocked;
  final int requiredCount;
  final int currentCount;

  AppAchievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.unlockedAt,
    this.isUnlocked = false,
    this.requiredCount = 1,
    this.currentCount = 0,
  });

  double get progress => (currentCount / requiredCount).clamp(0.0, 1.0);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'icon': icon,
        'unlockedAt': unlockedAt?.toIso8601String(),
        'isUnlocked': isUnlocked,
        'requiredCount': requiredCount,
        'currentCount': currentCount,
      };

  factory AppAchievement.fromJson(Map<String, dynamic> json) => AppAchievement(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        icon: json['icon'] ?? '🏆',
        unlockedAt: json['unlockedAt'] != null ? DateTime.parse(json['unlockedAt']) : null,
        isUnlocked: json['isUnlocked'] ?? false,
        requiredCount: json['requiredCount'] ?? 1,
        currentCount: json['currentCount'] ?? 0,
      );
}

// ═══════════════════════════════════════════════════════════
// 7. STREAK-SYSTEM - Tägliche Aktivität
// ═══════════════════════════════════════════════════════════

class ToolStreak {
  final String toolId; // 'tarot', 'meditation', 'mantra', etc.
  final int currentStreak;
  final int longestStreak;
  final DateTime lastActiveDate;
  final List<DateTime> activityDates;

  ToolStreak({
    required this.toolId,
    this.currentStreak = 0,
    this.longestStreak = 0,
    required this.lastActiveDate,
    this.activityDates = const [],
  });

  Map<String, dynamic> toJson() => {
        'toolId': toolId,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'lastActiveDate': lastActiveDate.toIso8601String(),
        'activityDates': activityDates.map((d) => d.toIso8601String()).toList(),
      };

  factory ToolStreak.fromJson(Map<String, dynamic> json) => ToolStreak(
        toolId: json['toolId'] ?? '',
        currentStreak: json['currentStreak'] ?? 0,
        longestStreak: json['longestStreak'] ?? 0,
        lastActiveDate: DateTime.parse(json['lastActiveDate'] ?? DateTime.now().toIso8601String()),
        activityDates: (json['activityDates'] as List<dynamic>?)
                ?.map((d) => DateTime.parse(d as String))
                .toList() ??
            [],
      );
}
