import 'package:flutter/material.dart';
import 'spirit_extended_models.dart';

/// ============================================
/// ACHIEVEMENT DEFINITIONS
/// 24 vordefinierte Achievements
/// ============================================

class AchievementsData {
  /// Alle 24 Achievements
  static List<Achievement> get allAchievements => [
    ..._streakAchievements,
    ..._checkInAchievements,
    ..._favoriteAchievements,
    ..._spiritToolsAchievements,
    ..._pointsAchievements,
    ..._specialAchievements,
  ];

  /// KATEGORIE 1: STREAK (5 Achievements)
  static List<Achievement> get _streakAchievements => [
    Achievement(
      id: 'streak_3',
      title: 'Erste Schritte',
      description: 'Erreiche einen 3-Tage-Streak',
      icon: Icons.local_fire_department,
      color: const Color(0xFFFF6B35),
      requiredCount: 3,
      category: AchievementCategory.streak,
    ),
    Achievement(
      id: 'streak_7',
      title: 'Wöchentlicher Krieger',
      description: 'Erreiche einen 7-Tage-Streak',
      icon: Icons.local_fire_department_outlined,
      color: const Color(0xFFFF8C42),
      requiredCount: 7,
      category: AchievementCategory.streak,
    ),
    Achievement(
      id: 'streak_30',
      title: 'Monatsmeister',
      description: 'Erreiche einen 30-Tage-Streak',
      icon: Icons.whatshot,
      color: const Color(0xFFFFAA00),
      requiredCount: 30,
      category: AchievementCategory.streak,
    ),
    Achievement(
      id: 'streak_100',
      title: 'Jahrhundertgenuss',
      description: 'Erreiche einen 100-Tage-Streak',
      icon: Icons.emoji_events,
      color: const Color(0xFFFFD700),
      requiredCount: 100,
      category: AchievementCategory.streak,
    ),
    Achievement(
      id: 'streak_365',
      title: 'Jahresheld',
      description: 'Erreiche einen 365-Tage-Streak',
      icon: Icons.star,
      color: const Color(0xFFFF1744),
      requiredCount: 365,
      category: AchievementCategory.streak,
    ),
  ];

  /// KATEGORIE 2: CHECK-IN (5 Achievements)
  static List<Achievement> get _checkInAchievements => [
    Achievement(
      id: 'checkin_3',
      title: 'Entdecker',
      description: 'Besuche 3 verschiedene Orte',
      icon: Icons.location_on,
      color: const Color(0xFF2196F3),
      requiredCount: 3,
      category: AchievementCategory.checkIn,
    ),
    Achievement(
      id: 'checkin_10',
      title: 'Weltenbummler',
      description: 'Besuche 10 verschiedene Orte',
      icon: Icons.map,
      color: const Color(0xFF00BCD4),
      requiredCount: 10,
      category: AchievementCategory.checkIn,
    ),
    Achievement(
      id: 'checkin_20',
      title: 'Reisender',
      description: 'Besuche 20 verschiedene Orte',
      icon: Icons.explore,
      color: const Color(0xFF009688),
      requiredCount: 20,
      category: AchievementCategory.checkIn,
    ),
    Achievement(
      id: 'checkin_materie_all',
      title: 'Materie-Meister',
      description: 'Besuche alle 8 Materie-Orte',
      icon: Icons.language,
      color: const Color(0xFF2196F3),
      requiredCount: 8,
      category: AchievementCategory.checkIn,
    ),
    Achievement(
      id: 'checkin_energie_all',
      title: 'Energie-Meister',
      description: 'Besuche alle 8 Energie-Orte',
      icon: Icons.auto_awesome,
      color: const Color(0xFF9C27B0),
      requiredCount: 8,
      category: AchievementCategory.checkIn,
    ),
  ];

  /// KATEGORIE 3: FAVORITEN (3 Achievements)
  static List<Achievement> get _favoriteAchievements => [
    Achievement(
      id: 'favorites_5',
      title: 'Sammler',
      description: 'Speichere 5 Favoriten',
      icon: Icons.star,
      color: const Color(0xFFFFC107),
      requiredCount: 5,
      category: AchievementCategory.favorites,
    ),
    Achievement(
      id: 'favorites_25',
      title: 'Kurator',
      description: 'Speichere 25 Favoriten',
      icon: Icons.stars,
      color: const Color(0xFFFFB300),
      requiredCount: 25,
      category: AchievementCategory.favorites,
    ),
    Achievement(
      id: 'favorites_100',
      title: 'Wissensschatz',
      description: 'Speichere 100 Favoriten',
      icon: Icons.auto_awesome,
      color: const Color(0xFFFF6F00),
      requiredCount: 100,
      category: AchievementCategory.favorites,
    ),
  ];

  /// KATEGORIE 4: SPIRIT-TOOLS (4 Achievements)
  static List<Achievement> get _spiritToolsAchievements => [
    Achievement(
      id: 'tools_3',
      title: 'Neugieriger',
      description: 'Nutze 3 verschiedene Spirit-Tools',
      icon: Icons.psychology,
      color: const Color(0xFF9C27B0),
      requiredCount: 3,
      category: AchievementCategory.spiritTools,
    ),
    Achievement(
      id: 'tools_10',
      title: 'Praktiker',
      description: 'Nutze 10 verschiedene Spirit-Tools',
      icon: Icons.auto_awesome,
      color: const Color(0xFF7B1FA2),
      requiredCount: 10,
      category: AchievementCategory.spiritTools,
    ),
    Achievement(
      id: 'tools_all',
      title: 'Meister der Tools',
      description: 'Nutze alle 16 Spirit-Tools',
      icon: Icons.emoji_events,
      color: const Color(0xFF6A1B9A),
      requiredCount: 16,
      category: AchievementCategory.spiritTools,
    ),
    Achievement(
      id: 'tools_numerology_10',
      title: 'Numerologie-Experte',
      description: 'Nutze den Numerologie-Rechner 10 Mal',
      icon: Icons.calculate,
      color: const Color(0xFFE1BEE7),
      requiredCount: 10,
      category: AchievementCategory.spiritTools,
    ),
  ];

  /// KATEGORIE 5: PUNKTE (3 Achievements)
  static List<Achievement> get _pointsAchievements => [
    Achievement(
      id: 'points_500',
      title: 'Aufsteigender',
      description: 'Erreiche 500 Spirit-Punkte',
      icon: Icons.trending_up,
      color: const Color(0xFF4CAF50),
      requiredCount: 500,
      category: AchievementCategory.points,
    ),
    Achievement(
      id: 'points_2000',
      title: 'Fortgeschrittener',
      description: 'Erreiche 2000 Spirit-Punkte',
      icon: Icons.military_tech,
      color: const Color(0xFF388E3C),
      requiredCount: 2000,
      category: AchievementCategory.points,
    ),
    Achievement(
      id: 'points_10000',
      title: 'Erleuchteter',
      description: 'Erreiche 10000 Spirit-Punkte',
      icon: Icons.stars,
      color: const Color(0xFF1B5E20),
      requiredCount: 10000,
      category: AchievementCategory.points,
    ),
  ];

  /// KATEGORIE 6: SPEZIAL (4 Achievements)
  static List<Achievement> get _specialAchievements => [
    Achievement(
      id: 'special_first_day',
      title: 'Willkommen',
      description: 'Melde dich das erste Mal an',
      icon: Icons.celebration,
      color: const Color(0xFFE91E63),
      requiredCount: 1,
      category: AchievementCategory.special,
    ),
    Achievement(
      id: 'special_both_worlds',
      title: 'Dualitätsmeister',
      description: 'Besuche beide Welten (Materie & Energie)',
      icon: Icons.brightness_6,
      color: const Color(0xFF673AB7),
      requiredCount: 1,
      category: AchievementCategory.special,
    ),
    Achievement(
      id: 'special_perfect_week',
      title: 'Perfekte Woche',
      description: 'Checke 7 Tage hintereinander ein',
      icon: Icons.check_circle,
      color: const Color(0xFF00E676),
      requiredCount: 7,
      category: AchievementCategory.special,
    ),
    Achievement(
      id: 'special_midnight_warrior',
      title: 'Mitternachtskrieger',
      description: 'Nutze die App um Mitternacht (00:00-01:00)',
      icon: Icons.nightlight_round,
      color: const Color(0xFF1A237E),
      requiredCount: 1,
      category: AchievementCategory.special,
    ),
  ];

  /// Hilfsfunktion: Achievement by ID
  static Achievement? getById(String id) {
    try {
      return allAchievements.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Hilfsfunktion: Achievements by Kategorie
  static List<Achievement> getByCategory(AchievementCategory category) {
    return allAchievements.where((a) => a.category == category).toList();
  }

  /// Statistik: Anzahl Achievements pro Kategorie
  static Map<AchievementCategory, int> get categoryCount {
    return {
      AchievementCategory.streak: _streakAchievements.length,
      AchievementCategory.checkIn: _checkInAchievements.length,
      AchievementCategory.favorites: _favoriteAchievements.length,
      AchievementCategory.spiritTools: _spiritToolsAchievements.length,
      AchievementCategory.points: _pointsAchievements.length,
      AchievementCategory.special: _specialAchievements.length,
    };
  }
}
