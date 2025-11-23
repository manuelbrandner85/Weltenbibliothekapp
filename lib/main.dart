import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'screens/map_screen.dart';
import 'screens/home_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/telegram_screen.dart';
import 'screens/dm_screen.dart';
import 'screens/timeline_screen.dart';
import 'screens/more_screen.dart';
import 'screens/auth_wrapper.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
// Music screen removed for optimized UX
import 'providers/event_provider.dart';
import 'providers/music_library_provider.dart';
import 'providers/player_provider.dart';
import 'providers/simple_music_provider.dart';
import 'providers/music_player_provider.dart';
import 'providers/user_provider.dart'; // NEW: User System
import 'providers/favorites_provider.dart'; // PHASE 2: Favorites System
import 'services/local_storage_service.dart';
import 'providers/webrtc_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ GLOBAL ERROR BOUNDARY (Best Practice 2024)
  // Catches ALL Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    _logError('Flutter Error', details.exception, details.stack);
  };

  // Catches ALL async errors outside Flutter framework
  await runZonedGuarded(() async {
    final localStorage = LocalStorageService();
    await localStorage.initialize();

    // CRITICAL FIX: Initialize AuthService to restore JWT token
    final authService = AuthService();
    await authService.initialize();

    // NEW: Initialize UserProvider for user system
    final userProvider = UserProvider();
    if (authService.isAuthenticated) {
      await userProvider.initialize();
    }

    runApp(
      WeltenbibliothekApp(localStorage: localStorage, userProvider: userProvider),
    );
  }, (error, stack) {
    _logError('Async Error', error, stack);
  });
}

/// ✅ Centralized Error Logging
/// In Production: Send to Crashlytics/Sentry
void _logError(String context, Object error, StackTrace? stack) {
  if (kDebugMode) {
    debugPrint('❌ [$context] $error');
    if (stack != null) {
      debugPrint('Stack trace:\n$stack');
    }
  } else {
    // TODO: In Production, send to Firebase Crashlytics or Sentry
    // FirebaseCrashlytics.instance.recordError(error, stack, reason: context);
  }
}

class WeltenbibliothekApp extends StatelessWidget {
  final LocalStorageService localStorage;
  final UserProvider userProvider;

  const WeltenbibliothekApp({
    super.key,
    required this.localStorage,
    required this.userProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => EventProvider(localStorage: localStorage),
        ),
        // 👤 NEW: User System Provider (Phase 3)
        ChangeNotifierProvider<UserProvider>.value(value: userProvider),
        // 🎥 WebRTC Video Service Provider (for Chat video calls)
        ChangeNotifierProvider(create: (context) => WebRTCProvider()),
        // 🎵 Musik-Providers
        ChangeNotifierProvider(
          create: (context) => MusicLibraryProvider()..initialize(),
        ),
        ChangeNotifierProvider(create: (context) => PlayerProvider()),
        // 🎵 Simple Music Provider (YouTube Music Integration)
        ChangeNotifierProvider(create: (context) => SimpleMusicProvider()),
        // 🎵 Music Sync Player Provider (Cloudflare Worker Integration)
        ChangeNotifierProvider(create: (context) => MusicPlayerProvider()),
        // ⭐ PHASE 2: Favorites System Provider
        ChangeNotifierProvider(
          create: (context) => FavoritesProvider()..initialize(),
        ),
      ],
      child: MaterialApp(
        title: 'Weltenbibliothek',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: const ColorScheme.dark(
            // Hauptfarben - Mystisches Violett & Gold
            primary: Color(0xFF8B5CF6), // Violett
            primaryContainer: Color(0xFF6D28D9),
            secondary: Color(0xFFFBBF24), // Gold
            secondaryContainer: Color(0xFFF59E0B),
            tertiary: Color(0xFF34D399), // Smaragdgrün
            // Hintergrund - Tiefes Nacht-Blau
            surface: Color(0xFF0F172A),
            surfaceContainer: Color(0xFF1E293B),
            surfaceContainerHighest: Color(0xFF334155),

            // Akzentfarben
            error: Color(0xFFEF4444),
            onPrimary: Color(0xFFFFFFFF),
            onSecondary: Color(0xFF1E293B),
            onSurface: Color(0xFFE2E8F0),
            onSurfaceVariant: Color(0xFF94A3B8),
          ),
          scaffoldBackgroundColor: const Color(0xFF0F172A),

          // App Bar Theme - Glassmorphismus
          appBarTheme: const AppBarTheme(
            elevation: 0,
            centerTitle: true,
            backgroundColor: Color(0xFF1E293B),
            foregroundColor: Color(0xFFE2E8F0),
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Color(0xFFE2E8F0),
            ),
          ),

          // Card Theme - Moderne Karten
          cardTheme: CardThemeData(
            elevation: 4,
            color: const Color(0xFF1E293B),
            shadowColor: Colors.black.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),

          // Button Themes
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          // Input Decoration
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF334155),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
            ),
          ),

          // Icon Theme
          iconTheme: const IconThemeData(color: Color(0xFF94A3B8)),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthWrapper(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const MainScreen(),
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with AutomaticKeepAliveClientMixin {
  int _selectedIndex = 1; // Start with Map
  
  // ✅ PERFORMANCE OPTIMIZATION: Lazy-loaded screen cache
  // Nur aktive Screens werden instanziiert und bleiben im Speicher
  final Map<int, Widget> _screenCache = {};
  
  // Screen-Builder Functions (Lazy Loading)
  Widget _buildScreen(int index) {
    // Cache-Check: Wenn Screen bereits existiert, wiederverwenden
    if (_screenCache.containsKey(index)) {
      return _screenCache[index]!;
    }
    
    // Screen erstellen und cachen
    Widget screen;
    switch (index) {
      case 0:
        screen = const HomeScreen();
        break;
      case 1:
        screen = const MapScreen();
        break;
      case 2:
        screen = const ChatScreen();
        break;
      case 3:
        screen = const TelegramScreen();
        break;
      case 4:
        screen = const DMScreen();
        break;
      case 5:
        screen = const TimelineScreen();
        break;
      case 6:
        screen = const MoreScreen();
        break;
      default:
        screen = const MapScreen();
    }
    
    _screenCache[index] = screen;
    return screen;
  }
  
  @override
  bool get wantKeepAlive => true; // Preserve state across rebuilds

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: List.generate(7, (index) {
          // Nur aktiven und benachbarte Screens bauen
          if (index == _selectedIndex || 
              index == _selectedIndex - 1 || 
              index == _selectedIndex + 1) {
            return _buildScreen(index);
          }
          // Placeholder für nicht geladene Screens
          return const SizedBox.shrink();
        }),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          border: Border(
            top: BorderSide(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(child: _buildNavItem(Icons.home, 'Home', 0)),
                Expanded(child: _buildNavItem(Icons.map, 'Karte', 1)),
                Expanded(child: _buildNavItem(Icons.chat, 'Chats', 2)),
                Expanded(child: _buildNavItem(Icons.telegram, 'Tele', 3)),
                Expanded(child: _buildNavItem(Icons.message, 'DM', 4)),
                Expanded(child: _buildNavItem(Icons.timeline, 'Zeit', 5)),
                Expanded(child: _buildNavItem(Icons.more_horiz, 'Mehr', 6)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                    const Color(0xFF6D28D9).withValues(alpha: 0.2),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                  width: 1,
                )
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: isSelected
                  ? BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    )
                  : null,
              child: Icon(
                icon,
                color: isSelected
                    ? const Color(0xFF8B5CF6)
                    : const Color(0xFF64748B),
                size: 20,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 8,
                color: isSelected
                    ? const Color(0xFFE2E8F0)
                    : const Color(0xFF64748B),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
