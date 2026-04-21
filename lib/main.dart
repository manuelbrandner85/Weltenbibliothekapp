import 'dart:async';
import 'package:flutter/material.dart';
// ✅ FÜR kDebugMode
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart' as provider; // ✅ Provider aliased
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 🆕 RIVERPOD für Admin-System
import 'services/sqlite_storage_service.dart'; // 🗄️ SQLITE LOCAL STORAGE
// 💾 SHARED PREFERENCES
// Firebase DEAKTIVIERT - Jetzt Cloudflare
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';
import 'screens/intro_image_screen.dart';
import 'screens/portal_home_screen.dart'; // 🌀 Portal (NACH Tutorial)
import 'screens/energie_world_screen.dart'; // ✅ FIXED: Correct path
import 'screens/energie/achievements_screen.dart';
import 'screens/daily_challenges_screen.dart';  // 🎯 Daily Challenges
import 'screens/leaderboard_screen.dart';  // 🏆 Leaderboard
import 'screens/enhanced_profile_screen.dart';  // 👤 Enhanced Profile
import 'screens/cloudflare_notification_settings_screen.dart'; // CLOUDFLARE PUSH
import 'screens/materie/search_history_screen.dart';
import 'screens/shared/update_history_screen.dart';
import 'screens/shared/backend_health_monitor_screen.dart'; // 🏥 HEALTH MONITOR // 🆕 SEARCH HISTORY
// REMOVED: Simple Voice Test Screen (deprecated)
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
import 'services/supabase_service.dart';  // 🟢 SUPABASE: Auth + Chat + Community
import 'services/profile_restore_service.dart'; // 🔄 PROFIL-WIEDERHERSTELLUNG
import 'services/push_notification_manager.dart'; // 🔔 PUSH NOTIFICATIONS (FCM + in-app)
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'widgets/update_gate.dart'; // 🔔 In-App Update-Meldungen (Release + OTA-Patch)

/// Global navigator key — needed by PushNotificationManager to deep-link into
/// routes from outside the widget tree (notification tap).
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔔 FIREBASE — vor allem anderen initialisieren (Background-Handler muss
  // VOR runApp() registriert werden, sonst verschluckt das Isolate die Nachricht).
  // Fail-safe: Wenn keine google-services.json vorhanden ist oder Play Services
  // fehlen, läuft die App auf den In-App-Polling-Kanal zurück (kein Crash).
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(fcmBackgroundHandler);
  } catch (e) {
    debugPrint('⚠️ Firebase init skipped (no config / no Play Services): $e');
  }

  // 🟢 SUPABASE - Muss als ERSTES initialisiert werden (vor allen anderen Services)
  await initSupabase();

  // 🗄️ SQLITE LOCAL STORAGE - Initialize SQLite database
  await SqliteStorageService.instance.init();

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

  // 🔔 PUSH NOTIFICATION MANAGER - Auto-Register + in-app polling
  // (fire-and-forget; init itself is awaitable but non-critical)
  unawaited(PushNotificationManager.instance.init(
    onDeepLink: (data) {
      final nav = appNavigatorKey.currentState;
      if (nav == null) return;
      final route = data['route']?.toString();
      final roomId = data['room_id']?.toString() ?? data['roomId']?.toString();
      if (route != null && route.isNotEmpty) {
        nav.pushNamed(route);
      } else if (roomId != null && roomId.startsWith('energie-')) {
        nav.pushNamed('/dashboard');
      }
    },
  ));
  
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

  // 🔄 PROFIL-WIEDERHERSTELLUNG - Im Hintergrund (nicht blockierend)
  // Stellt Profil aus Cloud wieder her falls Hive nach Neuinstallation leer ist
  ProfileRestoreService().checkAndRestoreProfiles().then((result) {
    if (result.anyRestored) {
      debugPrint('✅ Profile wiederhergestellt: ${result.toString()}');
    } else if (!result.anyProfilePresent) {
      debugPrint('ℹ️ Kein Profil vorhanden – normaler Onboarding-Flow');
    }
  }).catchError((e) {
    debugPrint('⚠️ Profile-Restore Fehler (ignoriert): $e');
  });
  
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
  @override
  void initState() {
    super.initState();
    
    // 🏆 Achievement Unlock Listener
    _setupAchievementListeners();
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
        return MaterialApp(
          title: 'Dual Realms - Deep Research',
          debugShowCheckedModeBanner: false,
          navigatorKey: appNavigatorKey,
          
          // 🌗 THEME: Dark/Light via ThemeService (Toggle in Profil-Settings)
          themeMode: themeService.themeMode,
          theme: EnhancedAppThemes.lightTheme,
          darkTheme: EnhancedAppThemes.darkTheme,
          
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
          // ✅ FIXED: DIREKT ZUM PORTAL - KEIN INTRO, KEINE CHECKS
          // UpdateGate zeigt beim ersten Frame + bei App-Resume Update-Meldungen
          // (Release-Update-Dialog / OTA-Patch-Bereit-Banner)
          home: const UpdateGate(child: PortalHomeScreen()), // 🌀 Portal + Update-Check
          routes: {
            '/home': (context) => const IntroImageScreen(),
            '/dashboard': (context) => const EnergieWorldScreen(), // ✅ FIXED
            '/achievements': (context) => const AchievementsScreen(),
            '/daily_challenges': (context) => const DailyChallengesScreen(),  // 🎯 Daily Challenges
            '/leaderboard': (context) => const LeaderboardScreen(),  // 🏆 Leaderboard
            '/enhanced_profile': (context) => const EnhancedProfileScreen(),  // 👤 Enhanced Profile
            '/notifications': (context) => const CloudflareNotificationSettingsScreen(), // CLOUDFLARE
            '/search_history': (context) => const SearchHistoryScreen(), // 🆕 SEARCH HISTORY
            '/health': (context) => const BackendHealthMonitorScreen(), // 🏥 HEALTH MONITOR
            UpdateHistoryScreen.routeName: (context) => const UpdateHistoryScreen(),
            // REMOVED: '/simple_voice_test' route (deprecated Simple Voice Test)
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
}
