import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
// ✅ FÜR kDebugMode
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart' as provider; // ✅ Provider aliased
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 🆕 RIVERPOD für Admin-System
import 'services/sqlite_storage_service.dart'; // 🗄️ SQLITE LOCAL STORAGE (Mobile)
// 💾 SHARED PREFERENCES
// Firebase DEAKTIVIERT - Jetzt Cloudflare
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';
import 'screens/intro_image_screen.dart';
import 'screens/portal_home_screen.dart'; // 🌀 Portal (NACH Tutorial)
import 'screens/web/web_auth_gate.dart'; // 🌐 Web Auth Gate
import 'screens/web/web_admin_panel.dart'; // 👑 Web Admin Panel
import 'widgets/livekit_mini_bar.dart'; // 📞 Mini-Bar für aktiven LiveKit-Call
import 'screens/energie_world_screen.dart'; // ✅ FIXED: Correct path
import 'screens/energie/achievements_screen.dart';
import 'screens/daily_challenges_screen.dart';  // 🎯 Daily Challenges
import 'screens/leaderboard_screen.dart';  // 🏆 Leaderboard
import 'screens/enhanced_profile_screen.dart';  // 👤 Enhanced Profile
import 'screens/cloudflare_notification_settings_screen.dart'; // CLOUDFLARE PUSH
import 'screens/materie/search_history_screen.dart';
import 'screens/shared/update_history_screen.dart';
import 'screens/shared/backend_health_monitor_screen.dart'; // 🏥 HEALTH MONITOR // 🆕 SEARCH HISTORY
import 'screens/vorhang/vorhang_world_wrapper.dart'; // 🎭 VORHANG WORLD
import 'screens/ursprung/ursprung_world_wrapper.dart'; // 🌀 URSPRUNG WORLD
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
import 'services/user_presence_service.dart'; // 🟢 Online-Status
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
import 'services/pip_service.dart'; // 📺 B10.3 PiP

/// Global navigator key — needed by PushNotificationManager to deep-link into
/// routes from outside the widget tree (notification tap).
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔔 FIREBASE — nur auf Mobile initialisieren (nicht auf Web)
  // Fail-safe: Wenn keine google-services.json vorhanden ist oder Play Services
  // fehlen, läuft die App auf den In-App-Polling-Kanal zurück (kein Crash).
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(fcmBackgroundHandler);
    } catch (e) {
      debugPrint('⚠️ Firebase init skipped (no config / no Play Services): $e');
    }
  }

  // 🟢 SUPABASE - Muss als ERSTES initialisiert werden (vor allen anderen Services)
  await initSupabase();

  // 🗄️ SQLITE LOCAL STORAGE - Initialize SQLite database (nur auf Mobile)
  if (!kIsWeb) {
    await SqliteStorageService.instance.init();
  } else {
    // Web: SharedPreferences-basierter Storage
    // Wird lazy initialisiert wenn benötigt (kein sqflite auf Web)
  }

  // 🛡️ ERROR BOUNDARY - Verhindert App-Crashes
  ErrorBoundary.initialize();

  if (!kIsWeb) {
    // 📊 ANALYTICS - Track app start (Mobile only)
    final analytics = PrivacyAnalyticsService();
    await analytics.trackEvent(PrivacyAnalyticsService.eventAppOpen);

    // 📊 CLOUDFLARE ANALYTICS - Initialize (Mobile only)
    final cloudflareAnalytics = CloudflareAnalyticsService();
    cloudflareAnalytics.initialize();

    // 🚨 ERROR REPORTING - Initialize (Mobile only)
    await ErrorReportingService().initialize();

    // 🖼️ IMAGE CACHE - Initialize (Mobile only)
    ImageCacheService().initialize();
    await ImageCacheService().cleanupOnStart();

    // 📳 HAPTIC FEEDBACK - Initialize (Mobile only)
    await HapticFeedbackService().initialize();

    // 📡 OFFLINE SYNC - Initialize (Mobile only — sqflite nicht auf Web)
    await OfflineSyncService().initialize();
  }

  // 📺 PiP-SERVICE - MethodChannel-Handler registrieren (nur auf Mobile)
  if (!kIsWeb) {
    await PipService.instance.init();
  }

  // 🔔 PUSH NOTIFICATION MANAGER - Auto-Register + in-app polling (nur Mobile)
  // (fire-and-forget; init itself is awaitable but non-critical)
  if (!kIsWeb) unawaited(PushNotificationManager.instance.init(
    onDeepLink: (data) {
      final nav = appNavigatorKey.currentState;
      if (nav == null) return;
      final type = data['type']?.toString() ?? '';
      final route = data['route']?.toString();
      final roomId = data['room_id']?.toString() ?? data['roomId']?.toString();

      // Explizite Route hat höchste Priorität
      if (route != null && route.isNotEmpty) {
        nav.pushNamed(route);
        return;
      }

      switch (type) {
        case 'chat_message':
        case 'mention':
        case 'reply':
          // Chat-Räume: Energie-Prefix → Energie-Dashboard, sonst Home
          if (roomId != null && roomId.startsWith('energie-')) {
            nav.pushNamed('/dashboard');
          }
          // Materie-Räume landen auf PortalHome (kein eigener Materie-Route)
          break;
        case 'achievement':
          nav.pushNamed('/achievements');
          break;
        case 'like':
        case 'comment':
        case 'follow':
        case 'new_article':
          // Benachrichtigungszentrum öffnen
          nav.pushNamed('/notifications');
          break;
        default:
          // Kein Route-Mapping → ignorieren (App bleibt auf aktuellem Screen)
          break;
      }
    },
  ));
  
  // ═══════════════════════════════════════════════════════════
  // MOBILE SYSTEM UI OPTIMIERUNGEN (SYNC - SCHNELL) — nur auf Mobile
  // ═══════════════════════════════════════════════════════════

  if (!kIsWeb) {
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
  }
  
  // ═══════════════════════════════════════════════════════════
  // KRITISCHE SERVICES (SYNC - NUR DIESE BLOCKIEREN START)
  // ═══════════════════════════════════════════════════════════
  
  // ═══════════════════════════════════════════════════════════
  // KRITISCHE SERVICES (SYNC - BLOCKING)
  // Managed by ServiceManager - NO arbitrary delays!
  // ═══════════════════════════════════════════════════════════
  
  // 🌐 Web + Mobile: Critical Services laufen jetzt auf BEIDEN Plattformen.
  // Hard-Timeout 10s: wenn auf Web ein Service hängt (z.B. SharedPreferences
  // bei IndexedDB-Block, Supabase-Lookup ohne Antwort), läuft die App
  // trotzdem an statt im Ladezustand zu erfrieren.
  try {
    await ServiceManager()
        .initializeCriticalServices()
        .timeout(const Duration(seconds: 10));
    debugPrint('✅ Critical services ready (Storage + Theme + Auth)');
  } catch (e) {
    debugPrint('⚠️ Critical service init error / timeout: $e');
    // App-Start auf Mobile NICHT möglich ohne critical services.
    // Web: critical-services-failure ist non-fatal (Stubs greifen meist).
    if (!kIsWeb) rethrow;
  }

  // 🔄 PROFIL-WIEDERHERSTELLUNG (Mobile only — Cloud-Sync schreibt in Hive)
  // Web nutzt SharedPreferences (web_user_name), kein Profile-Restore nötig.
  if (!kIsWeb) {
    ProfileRestoreService().checkAndRestoreProfiles().then((result) {
      if (result.anyRestored) {
        debugPrint('✅ Profile wiederhergestellt: ${result.toString()}');
      } else if (!result.anyProfilePresent) {
        debugPrint('ℹ️ Kein Profil vorhanden – normaler Onboarding-Flow');
      }
    }).catchError((e) {
      debugPrint('⚠️ Profile-Restore Fehler (ignoriert): $e');
    });
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
  
  if (!kIsWeb) {
    ServiceManager().initializeBackgroundServices();
  }
}

/// ScrollBehavior für Web: ermöglicht Touch- und Maus-Drag zum Scrollen.
class _WebScrollBehavior extends MaterialScrollBehavior {
  const _WebScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

class WeltenbibliothekApp extends StatefulWidget {
  const WeltenbibliothekApp({super.key});

  @override
  State<WeltenbibliothekApp> createState() => _WeltenbibliothekAppState();
}

class _WeltenbibliothekAppState extends State<WeltenbibliothekApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 🏆 Achievement Unlock Listener
    _setupAchievementListeners();

    // 🟢 Online-Status: Heartbeat alle 90s während App im Foreground.
    UserPresenceService.instance.start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    UserPresenceService.instance.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      UserPresenceService.instance.start();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      UserPresenceService.instance.stop();
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
        return MaterialApp(
          title: 'Dual Realms - Deep Research',
          debugShowCheckedModeBanner: false,
          navigatorKey: appNavigatorKey,
          
          // 🌗 THEME: Dark/Light via ThemeService (Toggle in Profil-Settings)
          themeMode: themeService.themeMode,
          theme: EnhancedAppThemes.lightTheme,
          darkTheme: EnhancedAppThemes.darkTheme,
          
          // ═══════════════════════════════════════════════════════════
          // SCROLL PERFORMANCE (angepasst für Web und Mobile)
          // ═══════════════════════════════════════════════════════════
          scrollBehavior: kIsWeb
              ? const _WebScrollBehavior()
              : const MaterialScrollBehavior().copyWith(
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
          // Mini-Bar für aktiven Sprach-Anruf wird ÜBER allen Screens injiziert
          // Auf Web: keine LiveKit Mini-Bar (WebRTC nicht unterstützt)
          builder: (context, child) {
            if (kIsWeb) return child ?? const SizedBox.shrink();
            return Stack(
              children: [
                child ?? const SizedBox.shrink(),
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LiveKitMiniBar(),
                ),
              ],
            );
          },
          // Web: Login-Gate vor dem Portal
          // Mobile: direkt zum Portal + UpdateGate für OTA-Patch-Dialog
          home: kIsWeb
              ? const WebAuthGate()
              : const UpdateGate(child: PortalHomeScreen()),
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
            '/admin/vorhang': (context) => const WorldAdminDashboard(world: 'vorhang'),
            '/admin/ursprung': (context) => const WorldAdminDashboard(world: 'ursprung'),
            // 🌍 NEUE WELTEN
            '/vorhang': (context) => const VorhangWorldWrapper(),
            '/ursprung': (context) => const UrsprungWorldWrapper(),
            // KI-ANALYSE-TOOLS (für Recherche-Tab)
            '/propaganda-detector': (context) => const PropagandaDetectorScreen(),
            '/image-forensics': (context) => const ImageForensicsScreen(),
            '/power-network-mapper': (context) => const PowerNetworkMapperScreen(),
            '/event-predictor': (context) => const EventPredictorScreen(),
            // 🌐 WEB-ADMIN (Web-Zugänge verwalten)
            '/admin/web-users': (context) => const WebAdminPanel(),
          },
        );
      },
    );
  }
}
