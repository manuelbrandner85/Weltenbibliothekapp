import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'achievement_service.dart';  // 🏆 Achievement System

/// Daily Knowledge Drop Service
/// Manages daily featured narratives and user engagement streaks
class DailyKnowledgeService {
  // Backend URL
  static const String _backendUrl = 'https://api-backend.brandy13062.workers.dev';
  
  // SharedPreferences Keys
  static const String _lastVisitKey = 'daily_knowledge_last_visit';
  static const String _currentStreakKey = 'daily_knowledge_streak';
  static const String _longestStreakKey = 'daily_knowledge_longest_streak';
  static const String _totalVisitsKey = 'daily_knowledge_total_visits';
  static const String _lastFeaturedIdKey = 'daily_knowledge_last_featured_id';
  
  // Singleton
  static final DailyKnowledgeService _instance = DailyKnowledgeService._internal();
  factory DailyKnowledgeService() => _instance;
  DailyKnowledgeService._internal();
  
  SharedPreferences? _prefs;
  
  /// Initialize service
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _checkAndUpdateStreak();
  }
  
  // ============================================
  // DAILY FEATURED NARRATIVE
  // ============================================
  
  /// Get today's featured narrative
  Future<Map<String, dynamic>?> getTodaysFeaturedNarrative() async {
    try {
      final response = await http.get(
        Uri.parse('$_backendUrl/api/daily-featured'),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Cache featured ID
        if (data['id'] != null) {
          await _prefs?.setString(_lastFeaturedIdKey, data['id']);
        }
        
        if (kDebugMode) {
          debugPrint('✅ Featured narrative loaded: ${data['title']}');
        }
        
        return data;
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ Failed to load featured: ${response.statusCode}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Featured narrative error: $e');
      }
      return null;
    }
  }
  
  /// Get time until next featured narrative (midnight)
  Duration getTimeUntilNext() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    return tomorrow.difference(now);
  }
  
  /// Format countdown string
  String getCountdownString() {
    final duration = getTimeUntilNext();
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '$hours Std ${minutes}min';
    } else {
      return '$minutes Minuten';
    }
  }
  
  // ============================================
  // STREAK SYSTEM
  // ============================================
  
  /// Check and update streak based on last visit
  Future<void> _checkAndUpdateStreak() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final lastVisitString = _prefs?.getString(_lastVisitKey);
    
    if (lastVisitString == null) {
      // First visit ever
      await _resetStreak(firstVisit: true);
      return;
    }
    
    final lastVisit = DateTime.parse(lastVisitString);
    final lastVisitDay = DateTime(lastVisit.year, lastVisit.month, lastVisit.day);
    
    final daysDifference = today.difference(lastVisitDay).inDays;
    
    if (daysDifference == 0) {
      // Same day - no change
      if (kDebugMode) {
        debugPrint('✅ Same day visit - streak maintained');
      }
    } else if (daysDifference == 1) {
      // Next day - increment streak
      await _incrementStreak();
      if (kDebugMode) {
        debugPrint('🔥 Streak incremented!');
      }
    } else {
      // Missed days - reset streak
      await _resetStreak();
      if (kDebugMode) {
        debugPrint('💔 Streak broken - reset to 1');
      }
    }
    
    // Update last visit
    await _prefs?.setString(_lastVisitKey, now.toIso8601String());
  }
  
  /// Increment streak
  Future<void> _incrementStreak() async {
    final currentStreak = _prefs?.getInt(_currentStreakKey) ?? 0;
    final newStreak = currentStreak + 1;
    
    await _prefs?.setInt(_currentStreakKey, newStreak);
    
    // Update longest streak if needed
    final longestStreak = _prefs?.getInt(_longestStreakKey) ?? 0;
    if (newStreak > longestStreak) {
      await _prefs?.setInt(_longestStreakKey, newStreak);
    }
    
    // Increment total visits
    final totalVisits = _prefs?.getInt(_totalVisitsKey) ?? 0;
    await _prefs?.setInt(_totalVisitsKey, totalVisits + 1);
    
    // 🏆 Achievement Trigger: Streak
    _trackStreakAchievements(newStreak);
  }
  
  /// Reset streak
  Future<void> _resetStreak({bool firstVisit = false}) async {
    await _prefs?.setInt(_currentStreakKey, 1);
    
    if (firstVisit) {
      await _prefs?.setInt(_longestStreakKey, 1);
      await _prefs?.setInt(_totalVisitsKey, 1);
    } else {
      final totalVisits = _prefs?.getInt(_totalVisitsKey) ?? 0;
      await _prefs?.setInt(_totalVisitsKey, totalVisits + 1);
    }
    
    await _prefs?.setString(_lastVisitKey, DateTime.now().toIso8601String());
  }
  
  /// Get current streak
  int getCurrentStreak() {
    return _prefs?.getInt(_currentStreakKey) ?? 0;
  }
  
  /// Get longest streak
  int getLongestStreak() {
    return _prefs?.getInt(_longestStreakKey) ?? 0;
  }
  
  /// Get total visits
  int getTotalVisits() {
    return _prefs?.getInt(_totalVisitsKey) ?? 0;
  }
  
  /// Get last visit date
  DateTime? getLastVisit() {
    final lastVisitString = _prefs?.getString(_lastVisitKey);
    if (lastVisitString == null) return null;
    return DateTime.parse(lastVisitString);
  }
  
  /// Check if user visited today
  bool hasVisitedToday() {
    final lastVisit = getLastVisit();
    if (lastVisit == null) return false;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastVisitDay = DateTime(lastVisit.year, lastVisit.month, lastVisit.day);
    
    return today == lastVisitDay;
  }
  
  /// Get streak emoji based on count
  String getStreakEmoji(int streak) {
    if (streak >= 365) return '🏆'; // 1 year
    if (streak >= 100) return '💎'; // 100 days
    if (streak >= 30) return '⭐'; // 1 month
    if (streak >= 7) return '🔥'; // 1 week
    return '✨'; // Starting
  }
  
  /// Get streak achievement message
  String getStreakAchievementMessage(int streak) {
    if (streak >= 365) return 'Unglaublich! 1 Jahr Streak! 🎉';
    if (streak >= 100) return 'Wow! 100 Tage Streak! 💪';
    if (streak >= 30) return 'Fantastisch! 30 Tage Streak! 🌟';
    if (streak >= 7) return 'Super! 7 Tage Streak! 🔥';
    if (streak >= 3) return 'Gut gemacht! 3 Tage Streak! ✨';
    return 'Streak gestartet! 🚀';
  }
  
  // ============================================
  // STATISTICS
  // ============================================
  
  /// Get user engagement stats
  Map<String, dynamic> getEngagementStats() {
    return {
      'current_streak': getCurrentStreak(),
      'longest_streak': getLongestStreak(),
      'total_visits': getTotalVisits(),
      'last_visit': getLastVisit()?.toIso8601String(),
      'visited_today': hasVisitedToday(),
    };
  }
  
  /// Reset all data (for testing)
  Future<void> resetAllData() async {
    await _prefs?.remove(_lastVisitKey);
    await _prefs?.remove(_currentStreakKey);
    await _prefs?.remove(_longestStreakKey);
    await _prefs?.remove(_totalVisitsKey);
    await _prefs?.remove(_lastFeaturedIdKey);
    
    if (kDebugMode) {
      debugPrint('✅ Daily Knowledge data reset');
    }
  }
  
  /// 🏆 Achievement Tracking Helper
  void _trackStreakAchievements(int streak) {
    try {
      if (streak >= 3) {
        AchievementService().incrementProgress('streak_beginner', amount: streak);
      }
      if (streak >= 7) {
        AchievementService().incrementProgress('streak_keeper', amount: streak);
      }
      if (streak >= 30) {
        AchievementService().incrementProgress('streak_legend', amount: streak);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Achievement tracking error: $e');
    }
  }
}
