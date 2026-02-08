import 'package:shared_preferences/shared_preferences.dart';

/// User Statistics
class UserStats {
  int totalSearches;
  int bookmarksCount;
  int categoriesExplored;
  int narrativesViewed;
  DateTime? lastSearchDate;
  Map<String, int> searchesByCategory;

  UserStats({
    this.totalSearches = 0,
    this.bookmarksCount = 0,
    this.categoriesExplored = 0,
    this.narrativesViewed = 0,
    this.lastSearchDate,
    Map<String, int>? searchesByCategory,
  }) : searchesByCategory = searchesByCategory ?? {};

  Map<String, dynamic> toJson() {
    return {
      'totalSearches': totalSearches,
      'bookmarksCount': bookmarksCount,
      'categoriesExplored': categoriesExplored,
      'narrativesViewed': narrativesViewed,
      'lastSearchDate': lastSearchDate?.toIso8601String(),
      'searchesByCategory': searchesByCategory,
    };
  }

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalSearches: json['totalSearches'] as int? ?? 0,
      bookmarksCount: json['bookmarksCount'] as int? ?? 0,
      categoriesExplored: json['categoriesExplored'] as int? ?? 0,
      narrativesViewed: json['narrativesViewed'] as int? ?? 0,
      lastSearchDate: json['lastSearchDate'] != null
          ? DateTime.parse(json['lastSearchDate'] as String)
          : null,
      searchesByCategory: Map<String, int>.from(
        json['searchesByCategory'] as Map? ?? {},
      ),
    );
  }
}

/// Achievement
class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int requiredCount;
  final String category;
  bool isUnlocked;
  DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.requiredCount,
    required this.category,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  static List<Achievement> getAll() {
    return [
      Achievement(
        id: 'first_search',
        title: 'Erste Recherche',
        description: 'Führe deine erste Recherche durch',
        icon: '🔍',
        requiredCount: 1,
        category: 'searches',
      ),
      Achievement(
        id: 'researcher',
        title: 'Forscher',
        description: 'Führe 10 Recherchen durch',
        icon: '📚',
        requiredCount: 10,
        category: 'searches',
      ),
      Achievement(
        id: 'expert',
        title: 'Experte',
        description: 'Führe 50 Recherchen durch',
        icon: '🎓',
        requiredCount: 50,
        category: 'searches',
      ),
      Achievement(
        id: 'master',
        title: 'Meister',
        description: 'Führe 100 Recherchen durch',
        icon: '👑',
        requiredCount: 100,
        category: 'searches',
      ),
      Achievement(
        id: 'bookworm',
        title: 'Sammler',
        description: 'Speichere 25 Lesezeichen',
        icon: '📑',
        requiredCount: 25,
        category: 'bookmarks',
      ),
      Achievement(
        id: 'explorer',
        title: 'Entdecker',
        description: 'Erkunde alle 7 Kategorien',
        icon: '🗺️',
        requiredCount: 7,
        category: 'categories',
      ),
      Achievement(
        id: 'narrative_hunter',
        title: 'Narrative Jäger',
        description: 'Öffne 30 verschiedene Narrative',
        icon: '🎯',
        requiredCount: 30,
        category: 'narratives',
      ),
    ];
  }
}

/// Stats & Achievements Service
class StatsService {
  static const String _statsKey = 'user_stats';
  static const String _achievementsKey = 'achievements';
  late SharedPreferences _prefs;
  UserStats? _stats;
  List<Achievement>? _achievements;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadStats();
    await _loadAchievements();
  }

  Future<void> _loadStats() async {
    final jsonStr = _prefs.getString(_statsKey);
    if (jsonStr != null) {
      _stats = UserStats.fromJson(
        Map<String, dynamic>.from(
          // Parse JSON string
          {},
        ),
      );
    } else {
      _stats = UserStats();
    }
  }

  Future<void> _loadAchievements() async {
    _achievements = Achievement.getAll();
    // Load unlocked status from prefs
    for (var achievement in _achievements!) {
      final isUnlocked = _prefs.getBool('achievement_${achievement.id}') ?? false;
      achievement.isUnlocked = isUnlocked;
    }
  }

  Future<void> _saveStats() async {
    // Save stats as JSON string
    await _prefs.setString(_statsKey, ''); // Placeholder
  }

  // Track Actions
  Future<void> trackSearch(String category) async {
    _stats!.totalSearches++;
    _stats!.lastSearchDate = DateTime.now();
    
    if (!_stats!.searchesByCategory.containsKey(category)) {
      _stats!.searchesByCategory[category] = 0;
      _stats!.categoriesExplored++;
    }
    _stats!.searchesByCategory[category] = 
        (_stats!.searchesByCategory[category] ?? 0) + 1;
    
    await _saveStats();
    await _checkAchievements();
  }

  Future<void> trackNarrativeView(String narrativeId) async {
    _stats!.narrativesViewed++;
    await _saveStats();
    await _checkAchievements();
  }

  Future<void> trackBookmark() async {
    _stats!.bookmarksCount++;
    await _saveStats();
    await _checkAchievements();
  }

  Future<void> _checkAchievements() async {
    for (var achievement in _achievements!) {
      if (achievement.isUnlocked) continue;

      bool shouldUnlock = false;
      switch (achievement.category) {
        case 'searches':
          shouldUnlock = _stats!.totalSearches >= achievement.requiredCount;
          break;
        case 'bookmarks':
          shouldUnlock = _stats!.bookmarksCount >= achievement.requiredCount;
          break;
        case 'categories':
          shouldUnlock = _stats!.categoriesExplored >= achievement.requiredCount;
          break;
        case 'narratives':
          shouldUnlock = _stats!.narrativesViewed >= achievement.requiredCount;
          break;
      }

      if (shouldUnlock) {
        achievement.isUnlocked = true;
        achievement.unlockedAt = DateTime.now();
        await _prefs.setBool('achievement_${achievement.id}', true);
      }
    }
  }

  UserStats get stats => _stats ?? UserStats();
  List<Achievement> get achievements => _achievements ?? [];
  
  int get level {
    final searches = _stats?.totalSearches ?? 0;
    if (searches >= 100) return 5; // Meister
    if (searches >= 50) return 4;  // Experte
    if (searches >= 25) return 3;  // Fortgeschritten
    if (searches >= 10) return 2;  // Forscher
    return 1; // Novize
  }

  String get levelName {
    switch (level) {
      case 5: return '👑 Meister';
      case 4: return '🎓 Experte';
      case 3: return '📚 Fortgeschritten';
      case 2: return '🔍 Forscher';
      default: return '🌱 Novize';
    }
  }

  int get xp => _stats?.totalSearches ?? 0;
  int get nextLevelXp {
    if (level >= 5) return 100;
    return [10, 25, 50, 100][level - 1];
  }
}
