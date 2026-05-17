import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'vorhang_home_tab.dart';
import 'vorhang_research_tab.dart';
import 'vorhang_community_tab.dart';
import 'vorhang_map_tab.dart';
import '../shared/unified_knowledge_tab.dart';
import '../shared/stats_dashboard_screen.dart';
import '../shared/world_admin_dashboard.dart';
import '../../widgets/admin_dashboard_button.dart';
import '../../services/haptic_service.dart';
import '../../features/admin/state/admin_state.dart';
import '../../theme/wb_cinematic_tokens.dart';
import '../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../widgets/cinematic/wb_floating_nav.dart';
import '../../widgets/cinematic/wb_vignette.dart';
import '../../widgets/cinematic/wb_ambient_particles.dart';
import '../profile_settings_screen.dart';
import '../../widgets/notification_center_button.dart';

/// 🎭 VORHANG-WELT DASHBOARD — Cinematic Chrome
///
/// Glassmorphic AppBar + Floating Bottom-Nav.
/// Tabs: Home / Recherche / Community / Karte / Wissen
class VorhangWorldScreen extends ConsumerStatefulWidget {
  const VorhangWorldScreen({super.key});

  @override
  ConsumerState<VorhangWorldScreen> createState() => _VorhangWorldScreenState();
}

class _VorhangWorldScreenState extends ConsumerState<VorhangWorldScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(adminStateProvider('vorhang').notifier).load();
        if (kDebugMode) {
          debugPrint('✅ Vorhang Screen: Admin-State geladen');
        }
      }
    });

    Future.delayed(const Duration(milliseconds: 1000), () {
      HapticService.lightImpact();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(adminStateProvider('vorhang').notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminStateProvider('vorhang'));

    final tabs = [
      VorhangHomeTab(
        key: ValueKey('home_${adminState.username}_${adminState.role}'),
        onSwitchTab: (idx) => setState(() => _currentIndex = idx),
      ),
      const VorhangResearchTab(),
      const VorhangCommunityTab(),
      const VorhangMapTab(),
      const UnifiedKnowledgeTab(world: 'vorhang'),
    ];

    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFF000000),
      appBar: WBGlassAppBar(
        world: WBWorld.vorhang,
        showWorldSwitcher: true,
        titleWidget: const Text(
          'VORHANG',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w300,
            fontSize: 18,
            letterSpacing: 4.0,
            color: Colors.white,
          ),
        ),
        actions: _buildAppBarActions(context, adminState),
      ),
      body: Stack(
        children: [
          // Cosmic-Hintergrund + Welt-Ambient
          const Positioned.fill(child: _CosmicBackground()),

          // Ambient particles
          const Positioned.fill(
            child: WBAmbientParticles(world: WBWorld.vorhang, count: 35),
          ),

          // Tab-Content + Admin-Button (über Tabs, nur wenn isAdmin)
          Padding(
            padding: const EdgeInsets.only(bottom: 80),
            child: Column(
              children: [
                AdminDashboardButton(adminState: adminState, world: 'vorhang'),
                Expanded(child: tabs[_currentIndex]),
              ],
            ),
          ),

          // Vignette als oberster atmosphärischer Layer
          const Positioned.fill(
            child: IgnorePointer(child: WBVignette()),
          ),

          // Floating Bottom-Nav
          Align(
            alignment: Alignment.bottomCenter,
            child: WBFloatingNav(
              world: WBWorld.vorhang,
              activeIndex: _currentIndex,
              items: const [
                WBFloatingNavItem(icon: Icons.home, label: 'Home'),
                WBFloatingNavItem(icon: Icons.search, label: 'Recherche'),
                WBFloatingNavItem(icon: Icons.people, label: 'Community'),
                WBFloatingNavItem(icon: Icons.map, label: 'Karte'),
                WBFloatingNavItem(icon: Icons.menu_book, label: 'Wissen'),
              ],
              onChanged: (i) => setState(() => _currentIndex = i),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAppBarActions(BuildContext context, AdminState adminState) {
    return [
      const NotificationCenterButton(accent: Color(0xFFC9A84C)),
      // Portal-Wechsel
      IconButton(
        icon: const Icon(Icons.swap_horiz, color: Color(0xFFC9A84C)),
        iconSize: 22,
        onPressed: () => Navigator.pop(context),
        tooltip: 'Zur Portal-Auswahl',
      ),
      // Stats
      IconButton(
        icon: const Icon(Icons.analytics_outlined, color: Color(0xFFC9A84C)),
        iconSize: 22,
        onPressed: () {
          HapticService.selectionClick();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const StatsDashboardScreen(world: 'vorhang'),
            ),
          );
        },
        tooltip: 'Statistiken',
      ),
      // Debug-Indikator (nur Debug-Build)
      if (kDebugMode) _DebugAdminBadge(adminState: adminState),
      // (Admin-Dashboard-Zugang ist jetzt prominenter Banner unter AppBar.)
      // Profil-Einstellungen
      IconButton(
        icon: const Icon(Icons.settings_outlined, color: Colors.white),
        iconSize: 22,
        onPressed: () async {
          HapticService.selectionClick();
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProfileSettingsScreen(),
            ),
          );
          if (mounted) {
            ref.read(adminStateProvider('vorhang').notifier).refresh();
          }
        },
        tooltip: 'Profil-Einstellungen',
      ),
    ];
  }
}

/// Cosmic-Hintergrund mit Gold-Atmosphäre für Vorhang-Welt.
class _CosmicBackground extends StatelessWidget {
  const _CosmicBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Tief-dunkler Gradient (Gold/Schwarz)
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0D0A00),
                  Color(0xFF050300),
                  Color(0xFF000000),
                ],
              ),
            ),
          ),
          // Gold-Ambient (radial vom oberen Drittel)
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.7),
                radius: 1.2,
                colors: [
                  const Color(0xFFC9A84C).withValues(alpha: 0.08),
                  Colors.transparent,
                ],
                stops: const [0.0, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Debug-Badge (nur in Debug-Builds).
class _DebugAdminBadge extends StatelessWidget {
  final AdminState adminState;
  const _DebugAdminBadge({required this.adminState});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        adminState.isAdmin ? Icons.check_circle : Icons.cancel,
        color: adminState.isAdmin ? Colors.green : Colors.redAccent,
      ),
      iconSize: 20,
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('🐛 ADMIN STATUS'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('isAdmin: ${adminState.isAdmin}'),
                Text('isRootAdmin: ${adminState.isRootAdmin}'),
                Text('World: ${adminState.world}'),
                Text('Backend Verified: ${adminState.backendVerified}'),
                Text('Username: ${adminState.username ?? "null"}'),
                Text('Role: ${adminState.role ?? "null"}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      },
      tooltip: 'Debug: Admin-Status',
    );
  }
}
