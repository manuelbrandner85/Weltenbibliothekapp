// 🏆 ACHIEVEMENT SYSTEM - Weltenbibliothek V115+
// Gamification System: Achievements, Progress, Categories

enum AchievementCategory {
  meditation,
  tarot,
  chakra,
  numerology,
  astrology,
  crystal,
  moon,
  chat,
  research,
  streak,
  social,
  master,
}

enum AchievementRarity {
  common,
  rare,
  epic,
  legendary,
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final AchievementCategory category;
  final AchievementRarity rarity;
  final int xpReward;
  final int requiredProgress;
  final bool isSecret; // Hidden until unlocked

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    required this.rarity,
    required this.xpReward,
    required this.requiredProgress,
    this.isSecret = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'icon': icon,
        'category': category.name,
        'rarity': rarity.name,
        'xpReward': xpReward,
        'requiredProgress': requiredProgress,
        'isSecret': isSecret,
      };

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        icon: json['icon'] as String,
        category: AchievementCategory.values.firstWhere(
          (e) => e.name == json['category'],
        ),
        rarity: AchievementRarity.values.firstWhere(
          (e) => e.name == json['rarity'],
        ),
        xpReward: json['xpReward'] as int,
        requiredProgress: json['requiredProgress'] as int,
        isSecret: json['isSecret'] as bool? ?? false,
      );
}

class AchievementProgress {
  final String achievementId;
  final int currentProgress;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  AchievementProgress({
    required this.achievementId,
    required this.currentProgress,
    required this.isUnlocked,
    this.unlockedAt,
  });

  double get progressPercentage {
    final achievement = AchievementDefinitions.getAchievement(achievementId);
    if (achievement == null) return 0.0;
    return (currentProgress / achievement.requiredProgress).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() => {
        'achievementId': achievementId,
        'currentProgress': currentProgress,
        'isUnlocked': isUnlocked,
        'unlockedAt': unlockedAt?.toIso8601String(),
      };

  factory AchievementProgress.fromJson(Map<String, dynamic> json) =>
      AchievementProgress(
        achievementId: json['achievementId'] as String,
        currentProgress: json['currentProgress'] as int,
        isUnlocked: json['isUnlocked'] as bool,
        unlockedAt: json['unlockedAt'] != null
            ? DateTime.parse(json['unlockedAt'] as String)
            : null,
      );

  AchievementProgress copyWith({
    int? currentProgress,
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) =>
      AchievementProgress(
        achievementId: achievementId,
        currentProgress: currentProgress ?? this.currentProgress,
        isUnlocked: isUnlocked ?? this.isUnlocked,
        unlockedAt: unlockedAt ?? this.unlockedAt,
      );
}

// 🎯 ACHIEVEMENT DEFINITIONS (30+ Achievements)
class AchievementDefinitions {
  static final Map<String, Achievement> _achievements = {
    // 🧘 MEDITATION ACHIEVEMENTS
    'med_first': Achievement(
      id: 'med_first',
      title: 'Erste Schritte',
      description: 'Deine erste Meditation abgeschlossen',
      icon: '🧘',
      category: AchievementCategory.meditation,
      rarity: AchievementRarity.common,
      xpReward: 10,
      requiredProgress: 1,
    ),
    'med_10': Achievement(
      id: 'med_10',
      title: 'Meditations-Novize',
      description: '10 Meditationen abgeschlossen',
      icon: '🧘‍♂️',
      category: AchievementCategory.meditation,
      rarity: AchievementRarity.common,
      xpReward: 50,
      requiredProgress: 10,
    ),
    'med_50': Achievement(
      id: 'med_50',
      title: 'Meditations-Adept',
      description: '50 Meditationen abgeschlossen',
      icon: '🕉️',
      category: AchievementCategory.meditation,
      rarity: AchievementRarity.rare,
      xpReward: 200,
      requiredProgress: 50,
    ),
    'med_100': Achievement(
      id: 'med_100',
      title: 'Meditations-Meister',
      description: '100 Meditationen abgeschlossen',
      icon: '☸️',
      category: AchievementCategory.meditation,
      rarity: AchievementRarity.epic,
      xpReward: 500,
      requiredProgress: 100,
    ),
    'med_1hour': Achievement(
      id: 'med_1hour',
      title: 'Geduldiger Geist',
      description: '60 Minuten meditiert',
      icon: '⏰',
      category: AchievementCategory.meditation,
      rarity: AchievementRarity.rare,
      xpReward: 100,
      requiredProgress: 60,
    ),

    // 🔮 TAROT ACHIEVEMENTS
    'tarot_first': Achievement(
      id: 'tarot_first',
      title: 'Kartenleger',
      description: 'Deine erste Tarot-Legung',
      icon: '🔮',
      category: AchievementCategory.tarot,
      rarity: AchievementRarity.common,
      xpReward: 10,
      requiredProgress: 1,
    ),
    'tarot_daily_7': Achievement(
      id: 'tarot_daily_7',
      title: 'Tägliche Einsicht',
      description: '7 Tage in Folge Tageskarte gezogen',
      icon: '🎴',
      category: AchievementCategory.tarot,
      rarity: AchievementRarity.rare,
      xpReward: 100,
      requiredProgress: 7,
    ),
    'tarot_50': Achievement(
      id: 'tarot_50',
      title: 'Tarot-Experte',
      description: '50 Tarot-Legungen durchgeführt',
      icon: '🃏',
      category: AchievementCategory.tarot,
      rarity: AchievementRarity.epic,
      xpReward: 250,
      requiredProgress: 50,
    ),

    // 💠 CHAKRA ACHIEVEMENTS
    'chakra_balanced': Achievement(
      id: 'chakra_balanced',
      title: 'Balance gefunden',
      description: 'Alle 7 Chakren ausgeglichen',
      icon: '💠',
      category: AchievementCategory.chakra,
      rarity: AchievementRarity.epic,
      xpReward: 200,
      requiredProgress: 1,
    ),
    'chakra_journal_7': Achievement(
      id: 'chakra_journal_7',
      title: 'Chakra-Chronist',
      description: '7 Tage Chakra-Tagebuch geführt',
      icon: '📔',
      category: AchievementCategory.chakra,
      rarity: AchievementRarity.rare,
      xpReward: 100,
      requiredProgress: 7,
    ),

    // 🔢 NUMEROLOGY ACHIEVEMENTS
    'num_first': Achievement(
      id: 'num_first',
      title: 'Zahlen-Suchender',
      description: 'Erste Numerologie-Berechnung',
      icon: '🔢',
      category: AchievementCategory.numerology,
      rarity: AchievementRarity.common,
      xpReward: 10,
      requiredProgress: 1,
    ),
    'num_compatibility': Achievement(
      id: 'num_compatibility',
      title: 'Seelenpartner',
      description: 'Partner-Kompatibilität berechnet',
      icon: '💑',
      category: AchievementCategory.numerology,
      rarity: AchievementRarity.rare,
      xpReward: 50,
      requiredProgress: 1,
    ),

    // ⭐ ASTROLOGY ACHIEVEMENTS
    'astro_first': Achievement(
      id: 'astro_first',
      title: 'Sternkundler',
      description: 'Erstes Geburtshoroskop erstellt',
      icon: '⭐',
      category: AchievementCategory.astrology,
      rarity: AchievementRarity.common,
      xpReward: 10,
      requiredProgress: 1,
    ),
    'astro_daily_30': Achievement(
      id: 'astro_daily_30',
      title: 'Kosmischer Beobachter',
      description: '30 Tage Tageshoroskop gelesen',
      icon: '🌟',
      category: AchievementCategory.astrology,
      rarity: AchievementRarity.epic,
      xpReward: 150,
      requiredProgress: 30,
    ),

    // 💎 CRYSTAL ACHIEVEMENTS
    'crystal_first': Achievement(
      id: 'crystal_first',
      title: 'Kristall-Sammler',
      description: 'Ersten Kristall zur Sammlung hinzugefügt',
      icon: '💎',
      category: AchievementCategory.crystal,
      rarity: AchievementRarity.common,
      xpReward: 10,
      requiredProgress: 1,
    ),
    'crystal_10': Achievement(
      id: 'crystal_10',
      title: 'Kristall-Kenner',
      description: '10 Kristalle in Sammlung',
      icon: '💠',
      category: AchievementCategory.crystal,
      rarity: AchievementRarity.rare,
      xpReward: 100,
      requiredProgress: 10,
    ),
    'crystal_all': Achievement(
      id: 'crystal_all',
      title: 'Kristall-Meister',
      description: 'Alle Kristalle erforscht',
      icon: '🔮',
      category: AchievementCategory.crystal,
      rarity: AchievementRarity.legendary,
      xpReward: 500,
      requiredProgress: 100,
    ),

    // 🌙 MOON ACHIEVEMENTS
    'moon_ritual': Achievement(
      id: 'moon_ritual',
      title: 'Mondkind',
      description: 'Erstes Vollmond-Ritual durchgeführt',
      icon: '🌕',
      category: AchievementCategory.moon,
      rarity: AchievementRarity.rare,
      xpReward: 50,
      requiredProgress: 1,
    ),
    'moon_journal_30': Achievement(
      id: 'moon_journal_30',
      title: 'Lunarer Chronist',
      description: '30 Tage Mond-Tagebuch geführt',
      icon: '🌙',
      category: AchievementCategory.moon,
      rarity: AchievementRarity.epic,
      xpReward: 200,
      requiredProgress: 30,
    ),

    // 💬 CHAT ACHIEVEMENTS
    'chat_first': Achievement(
      id: 'chat_first',
      title: 'Erste Worte',
      description: 'Erste Nachricht im Live-Chat gesendet',
      icon: '💬',
      category: AchievementCategory.chat,
      rarity: AchievementRarity.common,
      xpReward: 5,
      requiredProgress: 1,
    ),
    'chat_100': Achievement(
      id: 'chat_100',
      title: 'Gesprächig',
      description: '100 Nachrichten gesendet',
      icon: '💭',
      category: AchievementCategory.chat,
      rarity: AchievementRarity.rare,
      xpReward: 100,
      requiredProgress: 100,
    ),
    'chat_500': Achievement(
      id: 'chat_500',
      title: 'Community-Botschafter',
      description: '500 Nachrichten gesendet',
      icon: '📣',
      category: AchievementCategory.chat,
      rarity: AchievementRarity.epic,
      xpReward: 300,
      requiredProgress: 500,
    ),

    // 📚 RESEARCH ACHIEVEMENTS
    'research_first': Achievement(
      id: 'research_first',
      title: 'Wissensdurstig',
      description: 'Ersten Artikel gelesen',
      icon: '📚',
      category: AchievementCategory.research,
      rarity: AchievementRarity.common,
      xpReward: 5,
      requiredProgress: 1,
    ),
    'research_50': Achievement(
      id: 'research_50',
      title: 'Gelehrter',
      description: '50 Artikel gelesen',
      icon: '📖',
      category: AchievementCategory.research,
      rarity: AchievementRarity.epic,
      xpReward: 250,
      requiredProgress: 50,
    ),

    // 🔥 STREAK ACHIEVEMENTS
    'streak_3': Achievement(
      id: 'streak_3',
      title: 'Gewohnheit bilden',
      description: '3 Tage Streak',
      icon: '🔥',
      category: AchievementCategory.streak,
      rarity: AchievementRarity.common,
      xpReward: 20,
      requiredProgress: 3,
    ),
    'streak_7': Achievement(
      id: 'streak_7',
      title: 'Wöchentliche Hingabe',
      description: '7 Tage Streak',
      icon: '🔥',
      category: AchievementCategory.streak,
      rarity: AchievementRarity.rare,
      xpReward: 50,
      requiredProgress: 7,
    ),
    'streak_30': Achievement(
      id: 'streak_30',
      title: 'Unerschütterlich',
      description: '30 Tage Streak',
      icon: '🔥',
      category: AchievementCategory.streak,
      rarity: AchievementRarity.epic,
      xpReward: 200,
      requiredProgress: 30,
    ),
    'streak_100': Achievement(
      id: 'streak_100',
      title: 'Legende der Hingabe',
      description: '100 Tage Streak',
      icon: '🔥',
      category: AchievementCategory.streak,
      rarity: AchievementRarity.legendary,
      xpReward: 1000,
      requiredProgress: 100,
    ),

    // 🏆 MASTER ACHIEVEMENTS (Secret)
    'master_spirit': Achievement(
      id: 'master_spirit',
      title: 'Spirit-Meister',
      description: 'Alle Spirit-Tools gemeistert',
      icon: '👁️',
      category: AchievementCategory.master,
      rarity: AchievementRarity.legendary,
      xpReward: 1000,
      requiredProgress: 1,
      isSecret: true,
    ),
    'master_all': Achievement(
      id: 'master_all',
      title: 'Weltenbibliothek-Meister',
      description: 'Alle anderen Achievements freigeschaltet',
      icon: '🌌',
      category: AchievementCategory.master,
      rarity: AchievementRarity.legendary,
      xpReward: 5000,
      requiredProgress: 1,
      isSecret: true,
    ),
  };

  static List<Achievement> getAllAchievements() =>
      _achievements.values.toList();

  static Achievement? getAchievement(String id) => _achievements[id];

  static List<Achievement> getByCategory(AchievementCategory category) =>
      _achievements.values.where((a) => a.category == category).toList();

  static List<Achievement> getByRarity(AchievementRarity rarity) =>
      _achievements.values.where((a) => a.rarity == rarity).toList();
}
