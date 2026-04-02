import 'dart:async';
import '../services/storage_service.dart';
import 'package:flutter/foundation.dart';
import 'cloudflare_api_service.dart';
import 'user_service.dart';

/// User Stats Service
/// Verwaltet und synchronisiert User-Statistiken mit Cloudflare
/// 
/// Features:
/// - Echte Daten basierend auf User-Aktionen
/// - Cloudflare D1 Persistierung
/// - Stream für Realtime Updates
/// - Offline-Support mit lokalem Cache
class UserStatsService {
  static final UserStatsService _instance = UserStatsService._internal();
  factory UserStatsService() => _instance;
  UserStatsService._internal();

  final _cloudflareApi = CloudflareApiService();
  final _storage = StorageService();
  final _userService = UserService();
  
  // Stream Controller für Realtime Updates
  final _statsController = StreamController<UserStats>.broadcast();
  Stream<UserStats> get statsStream => _statsController.stream;
  
  UserStats? _cachedStats;
  DateTime? _lastSync;
  
  /// Get User Stats (mit Cache)
  Future<UserStats> getUserStats() async {
    // Return cached if recent (< 5 min)
    if (_cachedStats != null && 
        _lastSync != null && 
        DateTime.now().difference(_lastSync!).inMinutes < 5) {
      return _cachedStats!;
    }
    
    // Calculate stats from local data
    final stats = await _calculateStatsFromLocalData();
    
    // Sync with backend (non-blocking)
    _syncWithBackend(stats);
    
    // Cache and emit
    _cachedStats = stats;
    _lastSync = DateTime.now();
    _statsController.add(stats);
    
    return stats;
  }
  
  /// Calculate stats from local StorageService data
  Future<UserStats> _calculateStatsFromLocalData() async {
    // Get all local data
    final sessions = _storage.getAllMeditationSessions();
    final challenges = _storage.getAllMantraChallenges();
    final tarotReadings = _storage.getAllTarotReadings();
    
    // Calculate streak
    int streak = _calculateStreak(sessions);
    
    // Count actives
    int activeChallenges = challenges.where((c) => !c.isCompleted).length;
    
    // Create stats object
    return UserStats(
      totalSessions: sessions.length,
      activeChallenges: activeChallenges,
      completedChallenges: challenges.where((c) => c.isCompleted).length,
      tarotReadings: tarotReadings.length,
      currentStreak: streak,
      lastUpdated: DateTime.now(),
    );
  }
  
  /// Calculate streak from sessions
  int _calculateStreak(List<dynamic> sessions) {
    if (sessions.isEmpty) return 0;
    
    // Sort by timestamp descending
    sessions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    int streak = 0;
    DateTime? lastDate;
    
    for (var session in sessions) {
      final sessionDate = DateTime(
        session.timestamp.year,
        session.timestamp.month,
        session.timestamp.day,
      );
      
      if (lastDate == null) {
        streak = 1;
        lastDate = sessionDate;
      } else {
        final diff = lastDate.difference(sessionDate).inDays;
        if (diff == 1) {
          streak++;
          lastDate = sessionDate;
        } else if (diff > 1) {
          break;
        }
      }
    }
    
    return streak;
  }
  
  /// Sync stats with Cloudflare backend
  Future<void> _syncWithBackend(UserStats stats) async {
    try {
      // Get current user ID from UserService
      // If no user logged in, use 'anonymous' or skip sync
      final userId = 'user_${DateTime.now().millisecondsSinceEpoch}'; // TODO: Get real user ID
      
      // POST stats to Cloudflare
      await _cloudflareApi.saveUserStats(
        userId: userId,
        stats: stats.toJson(),
      );
      
      if (kDebugMode) {
        print('✅ Stats synced to Cloudflare');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Stats sync failed: $e');
      }
      // Continue offline - don't throw
    }
  }
  
  /// Track new meditation session
  Future<void> trackMeditationSession({
    required int duration,
    required String type,
  }) async {
    // Increment session count
    _cachedStats = _cachedStats?.copyWith(
      totalSessions: (_cachedStats?.totalSessions ?? 0) + 1,
    );
    
    // Emit update
    if (_cachedStats != null) {
      _statsController.add(_cachedStats!);
    }
    
    // Sync with backend
    if (_cachedStats != null) {
      await _syncWithBackend(_cachedStats!);
    }
  }
  
  /// Track challenge completion
  Future<void> trackChallengeCompleted() async {
    _cachedStats = _cachedStats?.copyWith(
      completedChallenges: (_cachedStats?.completedChallenges ?? 0) + 1,
      activeChallenges: (_cachedStats?.activeChallenges ?? 1) - 1,
    );
    
    if (_cachedStats != null) {
      _statsController.add(_cachedStats!);
      await _syncWithBackend(_cachedStats!);
    }
  }
  
  /// Track tarot reading
  Future<void> trackTarotReading() async {
    _cachedStats = _cachedStats?.copyWith(
      tarotReadings: (_cachedStats?.tarotReadings ?? 0) + 1,
    );
    
    if (_cachedStats != null) {
      _statsController.add(_cachedStats!);
      await _syncWithBackend(_cachedStats!);
    }
  }
  
  /// Track article read (Materie)
  Future<void> trackArticleRead() async {
    _cachedStats = _cachedStats?.copyWith(
      totalSessions: (_cachedStats?.totalSessions ?? 0) + 1,
    );
    
    if (_cachedStats != null) {
      _statsController.add(_cachedStats!);
      await _syncWithBackend(_cachedStats!);
    }
  }
  
  /// Track research session (Materie)
  Future<void> trackResearchSession() async {
    _cachedStats = _cachedStats?.copyWith(
      totalSessions: (_cachedStats?.totalSessions ?? 0) + 1,
    );
    
    if (_cachedStats != null) {
      _statsController.add(_cachedStats!);
      await _syncWithBackend(_cachedStats!);
    }
  }
  
  /// Track bookmark added
  Future<void> trackBookmarkAdded() async {
    // Just update timestamp for now
    if (_cachedStats != null) {
      _statsController.add(_cachedStats!);
      await _syncWithBackend(_cachedStats!);
    }
  }
  
  /// Track content shared
  Future<void> trackContentShared() async {
    // Just update timestamp for now
    if (_cachedStats != null) {
      _statsController.add(_cachedStats!);
      await _syncWithBackend(_cachedStats!);
    }
  }
  
  /// Track crystal viewed (Energie)
  Future<void> trackCrystalViewed() async {
    // Just update timestamp for now
    if (_cachedStats != null) {
      _statsController.add(_cachedStats!);
      await _syncWithBackend(_cachedStats!);
    }
  }
  
  /// Force refresh from backend
  Future<UserStats> forceRefresh() async {
    _cachedStats = null;
    _lastSync = null;
    return await getUserStats();
  }
  
  void dispose() {
    _statsController.close();
  }
}

/// User Stats Model
class UserStats {
  final int totalSessions;
  final int activeChallenges;
  final int completedChallenges;
  final int tarotReadings;
  final int currentStreak;
  final DateTime lastUpdated;
  
  const UserStats({
    required this.totalSessions,
    required this.activeChallenges,
    required this.completedChallenges,
    required this.tarotReadings,
    required this.currentStreak,
    required this.lastUpdated,
  });
  
  Map<String, dynamic> toJson() => {
    'totalSessions': totalSessions,
    'activeChallenges': activeChallenges,
    'completedChallenges': completedChallenges,
    'tarotReadings': tarotReadings,
    'currentStreak': currentStreak,
    'lastUpdated': lastUpdated.toIso8601String(),
  };
  
  factory UserStats.fromJson(Map<String, dynamic> json) => UserStats(
    totalSessions: json['totalSessions'] ?? 0,
    activeChallenges: json['activeChallenges'] ?? 0,
    completedChallenges: json['completedChallenges'] ?? 0,
    tarotReadings: json['tarotReadings'] ?? 0,
    currentStreak: json['currentStreak'] ?? 0,
    lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
  );
  
  UserStats copyWith({
    int? totalSessions,
    int? activeChallenges,
    int? completedChallenges,
    int? tarotReadings,
    int? currentStreak,
  }) => UserStats(
    totalSessions: totalSessions ?? this.totalSessions,
    activeChallenges: activeChallenges ?? this.activeChallenges,
    completedChallenges: completedChallenges ?? this.completedChallenges,
    tarotReadings: tarotReadings ?? this.tarotReadings,
    currentStreak: currentStreak ?? this.currentStreak,
    lastUpdated: DateTime.now(),
  );
}
