import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';
import 'dart:async';

// Service imports (static imports required in Dart)
import 'theme_service.dart';
import 'local_chat_storage_service.dart'; // 💬 Local Chat Storage
import 'invisible_auth_service.dart'; // 🔐 PHASE 1: AUTHENTICATION
import 'sound_service.dart'; // ✅ PRODUCTION-READY: Real audio system
import 'unified_knowledge_service.dart';
import 'cloudflare_api_service.dart';
import 'cloudflare_push_service.dart';
import '../services/offline_storage_service.dart';
import 'checkin_service.dart';
import 'favorites_service.dart';
import 'search_history_service.dart'; // 🆕 Search History Service
import 'community_interaction_service.dart'; // 🆕 Community Interaction Service
import 'daily_knowledge_service.dart'; // 🆕 Daily Knowledge Service
import 'ai_search_suggestion_service.dart'; // 🆕 AI Search Suggestion Service
import 'daily_spirit_practice_service.dart';
import 'synchronicity_service.dart';
import 'streak_tracking_service.dart';
import 'anonymous_cloud_sync_service.dart';
import 'realtime_updates_service.dart';
// import 'notification_service.dart'; // ❌ Web-only - Disabled for Android
import 'achievement_service.dart'; // 🏆 Achievement System
import 'unified_profile_service.dart'; // 🪪 v95 Unified Profile
import 'realtime_notification_service.dart'; // 🔔 v95 Realtime Notifications
import 'daily_challenges_service.dart'; // 🎯 Daily Challenges
import 'leaderboard_service.dart'; // 🏆 Leaderboard
import 'reward_service.dart'; // 🎁 Reward System
import 'social_sharing_service.dart'; // 📤 Social Sharing
import 'user_content_service.dart'; // ✍️ User Content
// 📊 Analytics

/// Service Initialization Manager
///
/// Manages app-wide service initialization with:
/// - Priority-based loading (Critical → High → Medium → Low)
/// - Dependency tracking
/// - Proper error handling & timeouts
/// - Initialization state monitoring
/// - No arbitrary delays - event-driven initialization
///
/// Usage:
/// ```dart
/// // In main.dart, BEFORE runApp():
/// await ServiceManager().initializeCriticalServices();
///
/// // After runApp() (non-blocking):
/// ServiceManager().initializeBackgroundServices();
/// ```
class ServiceManager {
  static final ServiceManager _instance = ServiceManager._internal();
  factory ServiceManager() => _instance;
  ServiceManager._internal();

  // Service initialization state
  bool _criticalServicesInitialized = false;
  bool _backgroundServicesInitializing = false;
  final Map<String, ServiceInitState> _serviceStates = {};
  final StreamController<ServiceInitEvent> _eventController =
      StreamController<ServiceInitEvent>.broadcast();

  /// Get service initialization state
  bool get criticalServicesReady => _criticalServicesInitialized;
  bool get backgroundServicesInitializing => _backgroundServicesInitializing;

  /// Stream of service initialization events (for UI feedback)
  Stream<ServiceInitEvent> get events => _eventController.stream;

  /// Get state of specific service
  ServiceInitState getServiceState(String serviceName) {
    return _serviceStates[serviceName] ?? ServiceInitState.notStarted;
  }

  /// ════════════════════════════════════════════════════════════
  /// PHASE 1: CRITICAL SERVICES (BLOCKING - App startup depends on these)
  /// Target: <500ms initialization time
  /// 🔐 ENHANCED: Now includes InvisibleAuthService (Phase 1)
  /// ════════════════════════════════════════════════════════════
  Future<void> initializeCriticalServices() async {
    if (_criticalServicesInitialized) {
      debugPrint('⚠️ Critical services already initialized');
      return;
    }

    debugPrint('🚀 Starting CRITICAL service initialization...');
    final startTime = DateTime.now();

    try {
      // StorageService - Required for all data persistence
      // ✅ ANDROID FIX: Reduzierter Timeout für schnelleren Start
      await _initializeService(
        'StorageService',
        () async {
          await StorageService().init();
        },
        critical: true,
        timeout:
            const Duration(seconds: 5), // ✅ Erhöht von 2s auf 5s für Android
      );

      // ThemeService - Required for app theming
      await _initializeService(
        'ThemeService',
        () async {
          await ThemeService().init();
        },
        critical: true,
        timeout: const Duration(seconds: 1),
      );

      // 💬 LocalChatStorageService - Offline-First Chat (NEW)
      await _initializeService(
        'LocalChatStorageService',
        () async {
          await LocalChatStorageService().initialize();
        },
        critical: true,
        timeout: const Duration(seconds: 2),
      );

      // 🪪 UnifiedProfileService - One profile fuer alle Welten (v95)
      await _initializeService(
        'UnifiedProfileService',
        () async {
          await UnifiedProfileService.instance.init();
        },
        critical: false,
        timeout: const Duration(seconds: 2),
      );

      // 🔔 RealtimeNotificationService - in-app Banner + Supabase Realtime
      await _initializeService(
        'RealtimeNotificationService',
        () async {
          await RealtimeNotificationService.instance.init();
        },
        critical: false,
        timeout: const Duration(seconds: 2),
      );

      // 🔐 CRITICAL FIX: InvisibleAuthService OPTIONAL (kann offline funktionieren)
      // ✅ WICHTIG: Auth-Init läuft NICHT mehr blockierend!
      // Auth wird im Hintergrund nachgeladen, App startet sofort
      try {
        // Fire-and-forget: Auth im Hintergrund initialisieren
        InvisibleAuthService().initialize().catchError((e) {
          debugPrint('⚠️ InvisibleAuthService: Background init failed: $e');
        });
        debugPrint('✅ InvisibleAuthService: Starting in background...');
      } catch (e) {
        debugPrint('⚠️ InvisibleAuthService: Init skipped (non-critical): $e');
        // ✅ App kann OHNE Auth-Service starten!
      }

      // ✅ SoundService - Audio feedback system (non-blocking)
      // Note: SoundService has its own initialization in constructor
      // Just instantiate to trigger lazy loading
      try {
        SoundService(); // Trigger singleton initialization
        if (kDebugMode) {
          debugPrint('✅ SoundService: Ready');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ SoundService: Init failed (non-critical): $e');
        }
      }

      _criticalServicesInitialized = true;
      final duration = DateTime.now().difference(startTime);
      debugPrint(
          '✅ Critical services initialized in ${duration.inMilliseconds}ms');
    } catch (e, stackTrace) {
      debugPrint('❌ CRITICAL FAILURE: Critical services initialization failed');
      debugPrint('Error: $e');
      if (kDebugMode) {
        debugPrint('StackTrace: $stackTrace');
      }
      rethrow; // Critical services MUST succeed or app cannot start
    }
  }

  /// ════════════════════════════════════════════════════════════
  /// PHASE 2: BACKGROUND SERVICES (NON-BLOCKING - Load after UI ready)
  /// Target: <5s total initialization time
  /// ════════════════════════════════════════════════════════════
  void initializeBackgroundServices() {
    if (_backgroundServicesInitializing) {
      debugPrint('⚠️ Background services already initializing');
      return;
    }

    _backgroundServicesInitializing = true;
    debugPrint('🔄 Starting BACKGROUND service initialization...');

    // Run in background (don't await - non-blocking)
    _initializeBackgroundServicesAsync();
  }

  Future<void> _initializeBackgroundServicesAsync() async {
    final startTime = DateTime.now();

    try {
      // ════════════════════════════════════════════════════════════
      // TIER 1: HIGH PRIORITY (Portal/Knowledge System - User sees immediately)
      // Load sequentially to respect dependencies
      // ════════════════════════════════════════════════════════════

      // Cloudflare API Service (Singleton - instant)
      // ⚡ CRITICAL FIX: Make optional to prevent app hang if Worker offline
      try {
        await _initializeService(
          'CloudflareApiService',
          () async {
            // Just instantiate singleton
            CloudflareApiService();
          },
          timeout: const Duration(milliseconds: 100),
        );
      } catch (e) {
        debugPrint('⚠️ CloudflareApiService init failed (non-critical): $e');
        // Continue app startup without Cloudflare API
      }

      // ════════════════════════════════════════════════════════════
      // TIER 2: MEDIUM PRIORITY (Load in parallel - all independent)
      // ⚡ OPTIMIZATION: Knowledge Service moved to parallel loading
      //    to prevent blocking app start (was 10s timeout!)
      // 💡 CRITICAL: All services are OPTIONAL - app will work without them!
      // ════════════════════════════════════════════════════════════
      await Future.wait([
        // Knowledge Service (Portal depends on this - but load in parallel)
        _initializeService(
          'UnifiedKnowledgeService',
          () async {
            await UnifiedKnowledgeService().init();
          },
          timeout: const Duration(seconds: 2), // Aggressive timeout: 3s → 2s
        ).catchError((e) {
          debugPrint('⚠️ UnifiedKnowledgeService init failed: $e');
          return null; // Continue without knowledge data (will load on-demand)
        }),
        _initializeService(
          'CloudflarePushService',
          () async => await CloudflarePushService().initialize(),
          timeout: const Duration(seconds: 1), // Fast fail if Worker offline
        ).catchError((e) {
          debugPrint('⚠️ CloudflarePushService init failed (non-critical): $e');
          return null; // Continue without push notifications
        }),
        _initializeService(
          'OfflineStorageService',
          () async => await OfflineStorageService().initialize(),
          timeout: const Duration(seconds: 1),
        ).catchError((e) {
          debugPrint('⚠️ UnifiedStorageService init failed: $e');
          return null;
        }),
        _initializeService(
          'CheckInService',
          () async => await CheckInService().init(),
          timeout: const Duration(seconds: 1),
        ).catchError((e) {
          debugPrint('⚠️ CheckInService init failed: $e');
          return null;
        }),
        _initializeService(
          'FavoritesService',
          () async => await FavoritesService.init(),
          timeout: const Duration(seconds: 1),
        ).catchError((e) {
          debugPrint('⚠️ FavoritesService init failed: $e');
          return null;
        }),
        _initializeService(
          'SearchHistoryService',
          () async => await SearchHistoryService.init(),
          timeout: const Duration(seconds: 1),
        ).catchError((e) {
          debugPrint('⚠️ SearchHistoryService init failed: $e');
          return null;
        }),
        // ❌ NotificationService disabled for Android (Web-only)
        // _initializeService(
        //   'NotificationService',
        //   () async => await NotificationService().initialize(),
        //   timeout: const Duration(seconds: 1),
        // ).catchError((e) {
        //   debugPrint('⚠️ NotificationService init failed: $e');
        //   return null;
        // }),
        _initializeService(
          'CommunityInteractionService',
          () async => await CommunityInteractionService().init(),
          timeout: const Duration(seconds: 1),
        ).catchError((e) {
          debugPrint('⚠️ CommunityInteractionService init failed: $e');
          return null;
        }),
        _initializeService(
          'DailyKnowledgeService',
          () async => await DailyKnowledgeService().init(),
          timeout: const Duration(seconds: 1),
        ).catchError((e) {
          debugPrint('⚠️ DailyKnowledgeService init failed: $e');
          return null;
        }),
        _initializeService(
          'AISearchSuggestionService',
          () async => await AISearchSuggestionService().init(),
          timeout: const Duration(seconds: 1),
        ).catchError((e) {
          debugPrint('⚠️ AISearchSuggestionService init failed: $e');
          return null;
        }),
        _initializeService(
          'AchievementService',
          () async => await AchievementService().init(),
          timeout: const Duration(seconds: 1),
        ).catchError((e) {
          debugPrint('⚠️ AchievementService init failed: $e');
          return null;
        }),
        _initializeService(
          'DailyChallengesService',
          () async => await DailyChallengesService().init(),
          timeout: const Duration(seconds: 1),
        ).catchError((e) {
          debugPrint('⚠️ DailyChallengesService init failed: $e');
          return null;
        }),
        _initializeService(
          'LeaderboardService',
          () async => await LeaderboardService().init(),
          timeout: const Duration(seconds: 1),
        ).catchError((e) {
          debugPrint('⚠️ LeaderboardService init failed: $e');
          return null;
        }),
        _initializeService(
          'RewardService',
          () async => await RewardService().init(),
          timeout: const Duration(seconds: 1),
        ).catchError((e) {
          debugPrint('⚠️ RewardService init failed: $e');
          return null;
        }),
        _initializeService(
          'SocialSharingService',
          () async => await SocialSharingService().init(),
          timeout: const Duration(seconds: 1),
        ).catchError((e) {
          debugPrint('⚠️ SocialSharingService init failed: $e');
          return null;
        }),
        _initializeService(
          'UserContentService',
          () async => await UserContentService().init(),
          timeout: const Duration(seconds: 1),
        ).catchError((e) {
          debugPrint('⚠️ UserContentService init failed: $e');
          return null;
        }),
        // 📊 AnalyticsService - No init needed (singleton ready)
        Future.value(null),
      ]);

      // ════════════════════════════════════════════════════════════
      // TIER 3: LOW PRIORITY (Nice-to-have features - load last)
      // ════════════════════════════════════════════════════════════
      await Future.wait([
        _initializeService(
          'DailySpiritPracticeService',
          () async => await DailySpiritPracticeService().init(),
        ),
        _initializeService(
          'SynchronicityService',
          () async => await SynchronicityService().init(),
        ),
        _initializeService(
          'StreakTrackingService',
          () async => await StreakTrackingService().init(),
        ),
        _initializeService(
          'AnonymousCloudSyncService',
          () async => await AnonymousCloudSyncService().init(),
        ),
        _initializeService(
          'RealtimeUpdatesService',
          () async => await RealtimeUpdatesService().init(),
        ),
      ]);

      // ════════════════════════════════════════════════════════════
      // TIER 4: ANALYTICS (After everything else - lowest priority)
      // ════════════════════════════════════════════════════════════
      await _initializeService(
        'StreakTracking_DailyLogin',
        () async => await StreakTrackingService().trackDailyLogin(),
        timeout: const Duration(seconds: 10),
      );

      // 🏆 Time-based Achievement Check
      _checkTimeBasedAchievements();

      final duration = DateTime.now().difference(startTime);
      debugPrint('✅ Background services initialized in ${duration.inSeconds}s');
      _printServiceSummary();
    } catch (e, stackTrace) {
      debugPrint('⚠️ Background service initialization had errors (non-fatal)');
      debugPrint('Error: $e');
      if (kDebugMode) {
        debugPrint('StackTrace: $stackTrace');
      }
      // Don't rethrow - background services failing is non-fatal
    } finally {
      _backgroundServicesInitializing = false;
    }
  }

  /// ════════════════════════════════════════════════════════════
  /// HELPER: Initialize single service with proper error handling
  /// ════════════════════════════════════════════════════════════
  Future<void> _initializeService(
    String serviceName,
    Future<void> Function() initializer, {
    Duration timeout = const Duration(seconds: 5),
    bool critical = false,
  }) async {
    _serviceStates[serviceName] = ServiceInitState.initializing;
    _eventController
        .add(ServiceInitEvent(serviceName, ServiceInitState.initializing));

    try {
      await initializer().timeout(
        timeout,
        onTimeout: () {
          throw TimeoutException(
              '$serviceName timed out after ${timeout.inSeconds}s');
        },
      );

      _serviceStates[serviceName] = ServiceInitState.ready;
      _eventController
          .add(ServiceInitEvent(serviceName, ServiceInitState.ready));

      if (kDebugMode) {
        debugPrint('  ✅ $serviceName');
      }
    } catch (e) {
      _serviceStates[serviceName] = ServiceInitState.failed;
      _eventController.add(
          ServiceInitEvent(serviceName, ServiceInitState.failed, error: e));

      if (critical) {
        debugPrint('  ❌ CRITICAL: $serviceName failed - $e');
        rethrow; // Critical services must succeed
      } else {
        debugPrint('  ⚠️ $serviceName failed (non-fatal) - $e');
        // Non-critical services can fail without breaking the app
      }
    }
  }

  /// Print service initialization summary
  void _printServiceSummary() {
    final ready =
        _serviceStates.values.where((s) => s == ServiceInitState.ready).length;
    final failed =
        _serviceStates.values.where((s) => s == ServiceInitState.failed).length;
    final total = _serviceStates.length;

    debugPrint('📊 Service Summary: $ready/$total ready');

    if (failed > 0) {
      debugPrint('  ⚠️ $failed services failed:');
      _serviceStates.forEach((name, state) {
        if (state == ServiceInitState.failed) {
          debugPrint('    ❌ $name');
        }
      });
    }
  }

  /// Dispose resources
  void dispose() {
    _eventController.close();
  }

  /// 🏆 Check Time-based Achievements (Early Bird, Night Owl)
  void _checkTimeBasedAchievements() {
    try {
      final hour = DateTime.now().hour;

      // Early Bird: Before 6 AM
      if (hour < 6) {
        AchievementService().incrementProgress('early_bird');
        if (kDebugMode) debugPrint('🌅 Early Bird achievement triggered!');
      }

      // Night Owl: After 11 PM
      if (hour >= 23) {
        AchievementService().incrementProgress('night_owl');
        if (kDebugMode) debugPrint('🦉 Night Owl achievement triggered!');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Time-based achievement check error: $e');
    }
  }
}

/// Service initialization state
enum ServiceInitState {
  notStarted,
  initializing,
  ready,
  failed,
}

/// Service initialization event (for UI feedback)
class ServiceInitEvent {
  final String serviceName;
  final ServiceInitState state;
  final dynamic error;

  ServiceInitEvent(this.serviceName, this.state, {this.error});
}

/// Timeout exception with descriptive message
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => 'TimeoutException: $message';
}
