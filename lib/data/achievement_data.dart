import 'package:flutter/material.dart';

/// v5.40 - Achievement System Data (2.3)
/// Defines all unlockable achievements in the app
class AchievementData {
  static final Map<String, Map<String, dynamic>> achievements = {
    'portal_entdecker': {
      'id': 'portal_entdecker',
      'title': '🌀 Portal-Entdecker',
      'description': 'Easter Egg freigeschaltet (10x Portal getappt)',
      'icon': '🌀',
      'points': 10,
      'rarity': 'common',
    },
    'farb_meister': {
      'id': 'farb_meister',
      'title': '🎨 Farb-Meister',
      'description': 'Alle 5 Portal-Farbschemata ausprobiert',
      'icon': '🎨',
      'points': 25,
      'rarity': 'rare',
    },
    'welten_reisender': {
      'id': 'welten_reisender',
      'title': '🌍 Welten-Reisender',
      'description': '10x zwischen Materie und Energie gewechselt',
      'icon': '🌍',
      'points': 15,
      'rarity': 'common',
    },
    'golden_portal': {
      'id': 'golden_portal',
      'title': '👑 Goldenes Portal',
      'description': '50x Portal getappt - Goldenes Portal freigeschaltet!',
      'icon': '👑',
      'points': 50,
      'rarity': 'legendary',
    },
    'mini_game_champion': {
      'id': 'mini_game_champion',
      'title': '🎮 Mini-Game Champion',
      'description': 'Portal Defense mit 100+ Punkten abgeschlossen',
      'icon': '🎮',
      'points': 30,
      'rarity': 'epic',
    },
    'cheat_code_master': {
      'id': 'cheat_code_master',
      'title': '🔐 Cheat Code Meister',
      'description': 'Alle Cheat Codes entdeckt',
      'icon': '🔐',
      'points': 40,
      'rarity': 'epic',
    },
    'hidden_facts_scholar': {
      'id': 'hidden_facts_scholar',
      'title': '📚 Fakten-Gelehrter',
      'description': 'Alle 12 Hidden Facts gelesen',
      'icon': '📚',
      'points': 20,
      'rarity': 'rare',
    },
  };

  /// Get achievement by ID
  static Map<String, dynamic>? getAchievement(String id) {
    return achievements[id];
  }

  /// Get all achievements
  static List<Map<String, dynamic>> getAllAchievements() {
    return achievements.values.toList();
  }

  /// Get total possible points
  static int getTotalPoints() {
    return achievements.values
        .fold(0, (sum, achievement) => sum + (achievement['points'] as int));
  }

  /// Get rarity color
  static Color getRarityColor(String rarity) {
    switch (rarity) {
      case 'common':
        return const Color(0xFF9E9E9E); // Gray
      case 'rare':
        return const Color(0xFF2196F3); // Blue
      case 'epic':
        return const Color(0xFF9C27B0); // Purple
      case 'legendary':
        return const Color(0xFFFFD700); // Gold
      default:
        return const Color(0xFFFFFFFF); // White
    }
  }
}
