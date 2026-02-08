import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../services/storage_service.dart';

/// Automatisches Streak-Tracking Service
/// Trackt tägliche Logins und Tool-Nutzung
class StreakTrackingService {
  static final StreakTrackingService _instance = StreakTrackingService._internal();
  factory StreakTrackingService() => _instance;
  StreakTrackingService._internal();

  static const String _keyLastLoginDate = 'last_login_date';
  static const String _keyLoginDates = 'login_dates_history';
  static const String _keyCurrentStreak = 'current_streak';
  static const String _keyLongestStreak = 'longest_streak';
  
  /// Streak-Status Stream (für Live-Updates)
  final StreamController<int> _streakController = StreamController<int>.broadcast();
  Stream<int> get streakStream => _streakController.stream;
  
  /// Current Streak (cached)
  int _currentStreak = 0;
  int get currentStreak => _currentStreak;
  
  /// Longest Streak
  int _longestStreak = 0;
  int get longestStreak => _longestStreak;
  
  /// Login History (last 365 days)
  List<DateTime> _loginHistory = [];
  List<DateTime> get loginHistory => List.unmodifiable(_loginHistory);
  
  /// Initialize service and load streak data
  Future<void> init() async {
    await _loadStreakData();
    
    if (kDebugMode) {
      debugPrint('🔥 StreakTrackingService initialized');
      debugPrint('   Current Streak: $_currentStreak days');
      debugPrint('   Longest Streak: $_longestStreak days');
      debugPrint('   Login History: ${_loginHistory.length} entries');
    }
  }
  
  /// Load streak data from storage
  Future<void> _loadStreakData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load current and longest streak
      _currentStreak = prefs.getInt(_keyCurrentStreak) ?? 0;
      _longestStreak = prefs.getInt(_keyLongestStreak) ?? 0;
      
      // Load login history
      final historyStrings = prefs.getStringList(_keyLoginDates) ?? [];
      _loginHistory = historyStrings
          .map((s) => DateTime.parse(s))
          .toList()
        ..sort((a, b) => b.compareTo(a)); // Newest first
      
      // Recalculate streak based on history
      await _recalculateStreak();
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error loading streak data: $e');
      }
    }
  }
  
  /// Recalculate current streak from login history
  Future<void> _recalculateStreak() async {
    if (_loginHistory.isEmpty) {
      _currentStreak = 0;
      return;
    }
    
    final today = _normalizeDate(DateTime.now());
    final lastLogin = _normalizeDate(_loginHistory.first);
    
    // Check if streak is broken
    final daysSinceLastLogin = today.difference(lastLogin).inDays;
    
    if (daysSinceLastLogin > 1) {
      // Streak broken
      _currentStreak = 0;
      await _saveStreakData();
      return;
    }
    
    // Count consecutive days
    int streak = 0;
    DateTime checkDate = today;
    
    for (final loginDate in _loginHistory) {
      final normalizedLogin = _normalizeDate(loginDate);
      final diff = checkDate.difference(normalizedLogin).inDays;
      
      if (diff == 0) {
        // Same day
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else if (diff == 1) {
        // Previous day found
        streak++;
        checkDate = normalizedLogin.subtract(const Duration(days: 1));
      } else {
        // Gap found, streak ends
        break;
      }
    }
    
    _currentStreak = streak;
    await _saveStreakData();
  }
  
  /// Save streak data to storage
  Future<void> _saveStreakData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyCurrentStreak, _currentStreak);
      await prefs.setInt(_keyLongestStreak, _longestStreak);
      
      // Save login history (last 365 days only)
      final historyStrings = _loginHistory
          .take(365)
          .map((d) => d.toIso8601String())
          .toList();
      await prefs.setStringList(_keyLoginDates, historyStrings);
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error saving streak data: $e');
      }
    }
  }
  
  /// Normalize date to midnight (ignore time)
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
  
  /// Täglichen Login tracken
  Future<void> trackDailyLogin() async {
    final today = _normalizeDate(DateTime.now());
    final todayKey = '${today.year}-${today.month}-${today.day}';
    
    // Prüfen ob heute schon eingeloggt
    final lastLoginKey = await _getLastLoginKey();
    
    if (lastLoginKey == todayKey) {
      if (kDebugMode) {
        debugPrint('🔥 Streak: Heute bereits eingeloggt');
      }
      return;
    }
    
    // Login tracken
    await _saveLastLoginKey(todayKey);
    
    // Add to login history
    if (!_loginHistory.any((d) => _normalizeDate(d).isAtSameMomentAs(today))) {
      _loginHistory.insert(0, today);
    }
    
    // Recalculate streak
    final oldStreak = _currentStreak;
    await _recalculateStreak();
    
    // Update longest streak if needed
    if (_currentStreak > _longestStreak) {
      _longestStreak = _currentStreak;
      await _saveStreakData();
    }
    
    // Broadcast streak update
    _streakController.add(_currentStreak);
    
    // Punkte hinzufügen (täglicher Login = 10 Punkte)
    await StorageService().addPoints(10, 'daily_login');
    
    // Bonus points for streak milestones
    if ([7, 14, 30, 60, 90, 180, 365].contains(_currentStreak)) {
      await StorageService().addPoints(_currentStreak, 'streak_milestone');
      if (kDebugMode) {
        debugPrint('🎉 Streak Milestone! $_currentStreak days (+$_currentStreak Bonus-Punkte)');
      }
    }
    
    // Achievement-Check
    // await AchievementService().checkAchievements();
    
    if (kDebugMode) {
      debugPrint('🔥 Streak: Täglicher Login getrackt (+10 Punkte)');
      debugPrint('   Current Streak: $_currentStreak days (was: $oldStreak)');
    }
  }

  /// Tool-Nutzung tracken
  Future<void> trackToolUsage(String toolName) async {
    // Tool-Nutzung = 5 Punkte
    await StorageService().addPoints(5, 'tool_$toolName');
    
    if (kDebugMode) {
      debugPrint('🔥 Streak: Tool-Nutzung getrackt: $toolName (+5 Punkte)');
    }
  }

  /// Check-In tracken
  Future<void> trackCheckIn(String locationName) async {
    // Check-In = 15 Punkte
    await StorageService().addPoints(15, 'checkin_$locationName');
    
    if (kDebugMode) {
      debugPrint('🔥 Streak: Check-In getrackt: $locationName (+15 Punkte)');
    }
  }

  /// Artikel gelesen
  Future<void> trackArticleRead(String articleId) async {
    // Artikel lesen = 3 Punkte
    await StorageService().addPoints(3, 'article_read');
    
    if (kDebugMode) {
      debugPrint('🔥 Streak: Artikel gelesen (+3 Punkte)');
    }
  }

  /// Favorit hinzugefügt
  Future<void> trackFavoriteAdded() async {
    // Favorit = 2 Punkte
    await StorageService().addPoints(2, 'favorite_added');
    
    if (kDebugMode) {
      debugPrint('🔥 Streak: Favorit hinzugefügt (+2 Punkte)');
    }
  }

  // Private Helpers
  Future<String?> _getLastLoginKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyLastLoginDate);
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveLastLoginKey(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLastLoginDate, key);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Fehler beim Speichern des Login-Keys: $e');
      }
    }
  }
}
