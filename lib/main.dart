import 'package:flutter/material.dart';
// ✅ FÜR kDebugMode
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart' as provider; // ✅ Provider aliased
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 🆕 RIVERPOD für Admin-System
// Firebase DEAKTIVIERT - Jetzt Cloudflare
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';
import 'screens/intro_image_screen.dart';
import 'screens/portal_home_screen.dart'; // 🌀 Portal (NACH Tutorial)
import 'screens/shared/onboarding_enhanced_screen.dart'; // 🎓 ENHANCED ONBOARDING v8.0
import 'screens/energie/dashboard_screen.dart';
import 'screens/energie/achievements_screen.dart';
import 'screens/daily_challenges_screen.dart';  // 🎯 Daily Challenges
import 'screens/leaderboard_screen.dart';  // 🏆 Leaderboard
import 'screens/enhanced_profile_screen.dart';  // 👤 Enhanced Profile
import 'screens/cloudflare_notification_settings_screen.dart'; // CLOUDFLARE PUSH
import 'screens/materie/search_history_screen.dart';
import 'screens/shared/backend_health_monitor_screen.dart'; // 🏥 HEALTH MONITOR // 🆕 SEARCH HISTORY
import 'screens/test/simple_voice_test_screen.dart'; // 🧪 SIMPLE VOICE TEST
// KI-ANALYSE-TOOLS (für Recherche-Tab)
import 'screens/materie/propaganda_detector_screen.dart';
import 'screens/materie/image_forensics_screen.dart';
import 'screens/materie/power_network_mapper_screen.dart';
import 'screens/materie/event_predictor_screen.dart';
// 🔐 ADMIN-DASHBOARD (World-Based Admin System)
import 'screens/shared/world_admin_dashboard.dart';
// import 'screens/energie/notification_settings_screen.dart'; // FIREBASE - deaktiviert
// import 'screens/notification_settings_screen.dart' as new_notif; // FIREBASE - deaktiviert
import 'services/service_manager.dart'; // ✅ NEW: Centralized service initialization
import 'services/theme_service.dart';
import 'services/privacy_analytics_service.dart'; // 📊 PRIVACY ANALYTICS
import 'services/analytics_service.dart'; // 📊 CLOUDFLARE ANALYTICS (NEW)
import 'services/error_reporting_service.dart'; // 🚨 ERROR REPORTING (NEW)
import 'services/image_cache_service.dart'; // 🖼️ IMAGE CACHE (NEW)
import 'services/haptic_feedback_service.dart'; // 📳 HAPTIC FEEDBACK (NEW Phase 3)
import 'services/offline_sync_service.dart'; // 📡 OFFLINE SYNC (NEW Phase 3)
import 'config/enhanced_app_themes.dart'; // 🎨 ENHANCED UI/UX THEMES
import 'services/achievement_service.dart';  // 🏆 Achievement System
import 'widgets/achievement_unlock_dialog.dart';  // 🏆 Achievement UI
import 'utils/error_boundary.dart';  // 🛡️ Error Boundary
// import 'widgets/offline_indicator.dart';  // 📡 OFFLINE INDICATOR (DISABLED - BUILD ISSUE)
// import 'services/push_notification_service.dart'; // Firebase -> Cloudflare

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 🛡️ ERROR BOUNDARY - Verhindert App-Crashes
  ErrorBoundary.initialize();
  
  // 📊 ANALYTICS - Track app start
  final analytics = PrivacyAnalyticsService();
  await analytics.trackEvent(PrivacyAnalyticsService.eventAppOpen);
  
  // 📊 CLOUDFLARE ANALYTICS - Initialize (NEW)
  final cloudflareAnalytics = CloudflareAnalyticsService();
  cloudflareAnalytics.initialize(); // Anonymous zuerst, userId wird nach Login gesetzt
  
  // 🚨 ERROR REPORTING - Initialize (NEW Phase 2)
  await ErrorReportingService().initialize();
  
  // 🖼️ IMAGE CACHE - Initialize (NEW Phase 2)
  ImageCacheService().initialize();
  await ImageCacheService().cleanupOnStart();
  
  // 📳 HAPTIC FEEDBACK - Initialize (NEW Phase 3)
  await HapticFeedbackService().initialize();
  
  // 📡 OFFLINE SYNC - Initialize (NEW Phase 3)
  await OfflineSyncService().initialize();
  
  // ═══════════════════════════════════════════════════════════
  // MOBILE SYSTEM UI OPTIMIERUNGEN (SYNC - SCHNELL)
  // ═══════════════════════════════════════════════════════════
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFF0D47A1),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  
  // ═══════════════════════════════════════════════════════════
  // KRITISCHE SERVICES (SYNC - NUR DIESE BLOCKIEREN START)
  // ═══════════════════════════════════════════════════════════
  
  // ═══════════════════════════════════════════════════════════
  // KRITISCHE SERVICES (SYNC - BLOCKING)
  // Managed by ServiceManager - NO arbitrary delays!
  // ═══════════════════════════════════════════════════════════
  
  try {
    await ServiceManager().initializeCriticalServices();
    debugPrint('✅ Critical services ready (Storage + Theme)');
  } catch (e) {
    debugPrint('⚠️ Critical service init error: $e');
    // App cannot start without critical services
    rethrow;
  }
  
  // ═══════════════════════════════════════════════════════════
  // APP STARTEN (NICHT BLOCKIEREND)
  // ═══════════════════════════════════════════════════════════
  
  runApp(
    // 🆕 RIVERPOD: ProviderScope für Admin-System
    ProviderScope(
      child: provider.ChangeNotifierProvider(
        create: (_) => ThemeService(),
        child: const WeltenbibliothekApp(),
      ),
    ),
  );
  
  // ═══════════════════════════════════════════════════════════
  // NICHT-KRITISCHE SERVICES (ASYNC - IM HINTERGRUND)
  // Managed by ServiceManager - Priority-based loading
  // ═══════════════════════════════════════════════════════════
  
  ServiceManager().initializeBackgroundServices();
}

class WeltenbibliothekApp extends StatefulWidget {
  const WeltenbibliothekApp({super.key});

  @override
  State<WeltenbibliothekApp> createState() => _WeltenbibliothekAppState();
}

class _WeltenbibliothekAppState extends State<WeltenbibliothekApp> {
  bool _showOnboarding = false;
  bool _isCheckingOnboarding = true;

  @override
  void initState() {
    super.initState();
    _checkNewOnboarding();
    
    // 🏆 Achievement Unlock Listener
    _setupAchievementListeners();
  }
  
  /// Check if new onboarding should be shown
  Future<void> _checkNewOnboarding() async {
    // ❌ TUTORIAL KOMPLETT DEAKTIVIERT - Direkt zum Portal
    if (mounted) {
      setState(() {
        _showOnboarding = false; // Kein Tutorial, direkt zum Portal
        _isCheckingOnboarding = false;
      });
    }
  }
  
  /// 🏆 Setup Achievement Listeners
  void _setupAchievementListeners() {
    final achievementService = AchievementService();
    
    // Listen for achievement unlocks
    achievementService.addUnlockListener((achievement, progress) {
      Future.delayed(Duration.zero, () {
        if (mounted) {
          // Show animated unlock dialog
          AchievementUnlockDialog.show(
            context,
            achievement,
            progress,
          );
        }
      });
    });
    
    // Listen for level ups
    achievementService.addLevelUpListener((userLevel) {
      Future.delayed(Duration.zero, () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.emoji_events, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '⬆️ LEVEL UP! Du bist jetzt Level ${userLevel.level}!',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.amber,
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      });
    });
  }
  
  /// Höre auf Achievement-Unlocks (DISABLED - Toast notifications used instead)
  // void _listenToAchievementUnlocks() {
  //   AchievementService().unlockStream.listen((achievement) {
  //     Future.delayed(const Duration(milliseconds: 500), () {
  //       if (mounted) {
  //         showDialog(
  //           context: context,
  //           barrierDismissible: true,
  //           builder: (context) => AchievementUnlockPopup(
  //             achievement: achievement,
  //             onDismiss: () => Navigator.of(context).pop(),
  //           ),
  //         );
  //       }
  //     });
  //   });
  // }
  
  @override
  Widget build(BuildContext context) {
    return provider.Consumer<ThemeService>(
      builder: (context, themeService, child) {
        // DISABLED: OfflineIndicator (build issue)
        return MaterialApp(
          title: 'Dual Realms - Deep Research',
          debugShowCheckedModeBanner: false,
          
          // 🌙 PERMANENT DARK MODE (unabhängig von System-Einstellungen)
          themeMode: ThemeMode.dark,
          theme: EnhancedAppThemes.darkTheme, // Dark als Standard
          darkTheme: EnhancedAppThemes.darkTheme, // Immer Dark
          
          // ═══════════════════════════════════════════════════════════
          // MOBILE SCROLL PERFORMANCE
          // ═══════════════════════════════════════════════════════════
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            physics: const BouncingScrollPhysics(),
            scrollbars: false, // Keine Scrollbars auf Mobile
          ),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('de', 'DE'), // Deutsch
            Locale('en', 'US'), // Englisch als Fallback
          ],
          locale: const Locale('de', 'DE'),
          // ✅ FIXED: Kein Onboarding mehr, direkt zum Intro
          home: _isCheckingOnboarding
              ? const Scaffold(
                  backgroundColor: Colors.black,
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.blue),
                        SizedBox(height: 20),
                        Text(
                          'Dual Realms wird geladen...',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                )
              : _showOnboarding
                  ? const OnboardingEnhancedScreen() // 📖 Tutorial-Seiten (ENERGIE, MATERIE, etc.)
                  : const PortalHomeScreen(), // 🌀 Direkt zum Portal
          routes: {
            '/home': (context) => const IntroImageScreen(),
            '/dashboard': (context) => const DashboardScreen(),
            '/achievements': (context) => const AchievementsScreen(),
            '/daily_challenges': (context) => const DailyChallengesScreen(),  // 🎯 Daily Challenges
            '/leaderboard': (context) => const LeaderboardScreen(),  // 🏆 Leaderboard
            '/enhanced_profile': (context) => const EnhancedProfileScreen(),  // 👤 Enhanced Profile
            '/notifications': (context) => const CloudflareNotificationSettingsScreen(), // CLOUDFLARE
            '/search_history': (context) => const SearchHistoryScreen(), // 🆕 SEARCH HISTORY
            '/health': (context) => const BackendHealthMonitorScreen(), // 🏥 HEALTH MONITOR
            '/simple_voice_test': (context) => const SimpleVoiceTestScreen(), // 🧪 SIMPLE VOICE TEST
            // 🔐 ADMIN-DASHBOARDS (World-specific)
            '/admin/materie': (context) => const WorldAdminDashboard(world: 'materie'),
            '/admin/energie': (context) => const WorldAdminDashboard(world: 'energie'),
            // KI-ANALYSE-TOOLS (für Recherche-Tab)
            '/propaganda-detector': (context) => const PropagandaDetectorScreen(),
            '/image-forensics': (context) => const ImageForensicsScreen(),
            '/power-network-mapper': (context) => const PowerNetworkMapperScreen(),
            '/event-predictor': (context) => const EventPredictorScreen(),
          },
        );
      },
    );
  }

  // TODO: Review unused method: _checkOnboardingCompleted
  // Future<bool> _checkOnboardingCompleted() async {
    // final prefs = await SharedPreferences.getInstance();
    // return prefs.getBool('onboarding_completed') ?? false;
  // }
}
