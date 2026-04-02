/// Realtime Updates Service
/// Provides live activity feed and real-time notifications
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'spirit_journal_service.dart';
import 'synchronicity_service.dart';
import 'streak_tracking_service.dart';

/// Activity Type enum
enum ActivityType {
  journalEntry,
  synchronicity,
  streakMilestone,
  achievementUnlock,
  dailyCheckIn,
}

/// Activity Item Model
class ActivityItem {
  final String id;
  final ActivityType type;
  final String title;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  ActivityItem({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    this.metadata = const {},
  });

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Gerade eben';
    } else if (difference.inMinutes < 60) {
      return 'vor ${difference.inMinutes} Min';
    } else if (difference.inHours < 24) {
      return 'vor ${difference.inHours} Std';
    } else if (difference.inDays < 7) {
      return 'vor ${difference.inDays} Tagen';
    } else {
      return 'vor ${(difference.inDays / 7).floor()} Wochen';
    }
  }

  String get icon {
    switch (type) {
      case ActivityType.journalEntry:
        return '📝';
      case ActivityType.synchronicity:
        return '✨';
      case ActivityType.streakMilestone:
        return '🔥';
      case ActivityType.achievementUnlock:
        return '🏆';
      case ActivityType.dailyCheckIn:
        return '✅';
    }
  }
}

/// Realtime Updates Service Singleton
class RealtimeUpdatesService {
  static final RealtimeUpdatesService _instance = RealtimeUpdatesService._internal();
  factory RealtimeUpdatesService() => _instance;
  RealtimeUpdatesService._internal();

  final SpiritJournalService _journalService = SpiritJournalService();
  final SynchronicityService _syncService = SynchronicityService();
  final StreakTrackingService _streakService = StreakTrackingService();
  // UNUSED FIELD: final AchievementService _achievementService = AchievementService();

  /// Activity Stream (broadcast to all listeners)
  final StreamController<List<ActivityItem>> _activityController =
      StreamController<List<ActivityItem>>.broadcast();
  Stream<List<ActivityItem>> get activityStream => _activityController.stream;

  /// New Activity Stream (individual events)
  final StreamController<ActivityItem> _newActivityController =
      StreamController<ActivityItem>.broadcast();
  Stream<ActivityItem> get newActivityStream => _newActivityController.stream;

  /// Activity cache (last 50 activities)
  final List<ActivityItem> _activities = [];
  List<ActivityItem> get activities => List.unmodifiable(_activities);

  /// Polling timer for live updates
  Timer? _pollingTimer;
  bool _isPolling = false;

  /// Last known counts (for detecting new items)
  int _lastJournalCount = 0;
  int _lastSyncCount = 0;
  int _lastStreakDays = 0;

  // ============================================
  // INITIALIZATION
  // ============================================

  /// Initialize realtime service
  Future<void> init() async {
    try {
      await _loadInitialActivities();
      _startPolling();

      if (kDebugMode) {
        debugPrint('⚡ RealtimeUpdatesService initialized');
        debugPrint('   Activities loaded: ${_activities.length}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ RealtimeUpdatesService init error: $e');
      }
    }
  }

  /// Load initial activities from services
  Future<void> _loadInitialActivities() async {
    await _journalService.init();
    await _syncService.init();
    await _streakService.init();
    // await _achievementService.init();

    _activities.clear();

    // Load Journal activities
    for (final entry in _journalService.entries.take(10)) {
      _activities.add(ActivityItem(
        id: 'journal_${entry.id}',
        type: ActivityType.journalEntry,
        title: 'Journal-Eintrag',
        description: '${SpiritJournalService.getCategoryEmoji(entry.category)} ${entry.content.substring(0, entry.content.length > 50 ? 50 : entry.content.length)}${entry.content.length > 50 ? '...' : ''}',
        timestamp: entry.timestamp,
        metadata: {'category': entry.category},
      ));
    }

    // Load Synchronicity activities
    for (final sync in _syncService.entries.take(10)) {
      _activities.add(ActivityItem(
        id: 'sync_${sync.id}',
        type: ActivityType.synchronicity,
        title: 'Synchronizität',
        description: sync.event,
        timestamp: sync.timestamp,
        metadata: {'significance': sync.significance},
      ));
    }

    // Load Streak milestones
    final currentStreak = _streakService.currentStreak;
    if (currentStreak > 0 && [7, 14, 30, 60, 90, 180, 365].contains(currentStreak)) {
      _activities.add(ActivityItem(
        id: 'streak_${currentStreak}_days',
        type: ActivityType.streakMilestone,
        title: 'Streak-Meilenstein',
        description: '$currentStreak Tage in Folge! 🎉',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        metadata: {'days': currentStreak},
      ));
    }

    // Load Achievement unlocks
    // Note: AchievementService doesn't expose unlocked list directly
    // We can show unlock count instead
    final unlockedCount = 0; // _achievementService.unlockedCount;
    if (unlockedCount > 0) {
      _activities.add(ActivityItem(
        id: 'achievements_unlocked',
        type: ActivityType.achievementUnlock,
        title: 'Achievements freigeschaltet',
        description: '🏆 $unlockedCount Achievements erreicht!',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        metadata: {'count': unlockedCount},
      ));
    }

    // Sort by timestamp (newest first)
    _activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Keep only last 50
    if (_activities.length > 50) {
      _activities.removeRange(50, _activities.length);
    }

    // Update initial counts
    _lastJournalCount = _journalService.entries.length;
    _lastSyncCount = _syncService.entries.length;
    _lastStreakDays = _streakService.currentStreak;

    _activityController.add(_activities);
  }

  // ============================================
  // POLLING FOR LIVE UPDATES
  // ============================================

  /// Start polling for new activities (every 30 seconds)
  void _startPolling() {
    if (_isPolling) return;
    _isPolling = true;

    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkForNewActivities();
    });

    if (kDebugMode) {
      debugPrint('🔄 Realtime polling started (every 30 seconds)');
    }
  }

  /// Stop polling
  void stopPolling() {
    _isPolling = false;
    _pollingTimer?.cancel();
    _pollingTimer = null;

    if (kDebugMode) {
      debugPrint('⏸️ Realtime polling stopped');
    }
  }

  /// Check for new activities
  Future<void> _checkForNewActivities() async {
    try {
      bool hasNewActivity = false;

      // Check for new journal entries
      if (_journalService.entries.length > _lastJournalCount) {
        final newEntry = _journalService.entries.first;
        final newActivity = ActivityItem(
          id: 'journal_${newEntry.id}',
          type: ActivityType.journalEntry,
          title: 'Neuer Journal-Eintrag',
          description: '${SpiritJournalService.getCategoryEmoji(newEntry.category)} ${newEntry.content.substring(0, newEntry.content.length > 50 ? 50 : newEntry.content.length)}${newEntry.content.length > 50 ? '...' : ''}',
          timestamp: newEntry.timestamp,
          metadata: {'category': newEntry.category},
        );
        
        _addActivity(newActivity);
        _lastJournalCount = _journalService.entries.length;
        hasNewActivity = true;
      }

      // Check for new synchronicities
      if (_syncService.entries.length > _lastSyncCount) {
        final newSync = _syncService.entries.first;
        final newActivity = ActivityItem(
          id: 'sync_${newSync.id}',
          type: ActivityType.synchronicity,
          title: 'Neue Synchronizität',
          description: newSync.event,
          timestamp: newSync.timestamp,
          metadata: {'significance': newSync.significance},
        );
        
        _addActivity(newActivity);
        _lastSyncCount = _syncService.entries.length;
        hasNewActivity = true;
      }

      // Check for streak milestones
      final currentStreak = _streakService.currentStreak;
      if (currentStreak > _lastStreakDays && [7, 14, 30, 60, 90, 180, 365].contains(currentStreak)) {
        final newActivity = ActivityItem(
          id: 'streak_${currentStreak}_days',
          type: ActivityType.streakMilestone,
          title: 'Streak-Meilenstein erreicht!',
          description: '$currentStreak Tage in Folge! 🎉',
          timestamp: DateTime.now(),
          metadata: {'days': currentStreak},
        );
        
        _addActivity(newActivity);
        _lastStreakDays = currentStreak;
        hasNewActivity = true;
      }

      if (hasNewActivity && kDebugMode) {
        debugPrint('⚡ New activities detected');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error checking for new activities: $e');
      }
    }
  }

  // ============================================
  // ACTIVITY MANAGEMENT
  // ============================================

  /// Add new activity to feed
  void _addActivity(ActivityItem activity) {
    _activities.insert(0, activity);
    
    // Keep only last 50
    if (_activities.length > 50) {
      _activities.removeLast();
    }

    // Broadcast to streams
    _activityController.add(_activities);
    _newActivityController.add(activity);

    if (kDebugMode) {
      debugPrint('➕ New activity: ${activity.title}');
    }
  }

  /// Manually add activity (for external triggers)
  void addActivity(ActivityItem activity) {
    _addActivity(activity);
  }

  /// Clear all activities
  void clearActivities() {
    _activities.clear();
    _activityController.add(_activities);
  }

  // ============================================
  // CLEANUP
  // ============================================

  void dispose() {
    stopPolling();
    _activityController.close();
    _newActivityController.close();
  }
}
