import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'energie/home_tab_v5.dart';
import 'energie/spirit_tab_modern.dart';
import 'energie/energie_community_tab_modern.dart';
import 'energie/energie_karte_tab_pro.dart';
import 'shared/unified_knowledge_tab.dart';
import 'shared/stats_dashboard_screen.dart';
import 'shared/world_admin_dashboard.dart';
import '../services/haptic_service.dart';
import '../features/admin/state/admin_state.dart';
import '../theme/wb_cinematic_tokens.dart';
import '../widgets/cinematic/wb_glass_app_bar.dart';
import '../widgets/cinematic/wb_floating_nav.dart';
import '../widgets/cinematic/wb_vignette.dart';
import '../widgets/cinematic/wb_ambient_particles.dart';
import 'profile_settings_screen.dart';

/// 🌍 ENERGIE-WELT DASHBOARD — Cinematic Chrome
///
/// Glassmorphic AppBar + Floating Bottom-Nav statt Material-Defaults.
/// Tabs (Home/Spirit/Community/Karte/Wissen) bleiben unverändert.
class EnergieWorldScreen extends ConsumerStatefulWidget {
  const EnergieWorldScreen({super.key});

  @override
  ConsumerState<EnergieWorldScreen> createState() => _EnergieWorldScreenState();
}

class _EnergieWorldScreenState extends ConsumerState<EnergieWorldScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(adminStateProvider('energie').notifier).load();
        if (kDebugMode) {
          debugPrint('✅ Energie Screen: Admin-State geladen');
        }
      }
    });

    Future.delayed(const Duration(milliseconds: 1000), () {
      HapticService.selectionClick();
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
      ref.read(adminStateProvider('energie').notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminStateProvider('energie'));

    final tabs = [
      EnergieHomeTabV5(
        key: ValueKey('home_${adminState.username}_${adminState.role}'),
        onSwitchTab: (idx) => setState(() => _currentIndex = idx),
      ),
      const SpiritTabModern(),
      const EnergieCommunityTabModern(),
      const EnergieKarteTabPro(),
      const UnifiedKnowledgeTab(world: 'energie'),
    ];

    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFF000004),
      appBar: WBGlassAppBar(
        world: WBWorld.energie,
        titleWidget: const Text(
          'ENERGIE',
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
          const Positioned.fill(child: _CosmicBackground(world: WBWorld.energie)),

          // Ambient particles (Phase 6)
          const Positioned.fill(
            child: WBAmbientParticles(world: WBWorld.energie, count: 35),
          ),

          // Tab-Content (Padding unten für Floating-Nav-Clearance)
          Padding(
            padding: const EdgeInsets.only(bottom: 80),
            child: tabs[_currentIndex],
          ),

          // Vignette als oberster atmosphärischer Layer
          const Positioned.fill(
            child: IgnorePointer(child: WBVignette()),
          ),

          // Floating Bottom-Nav
          Align(
            alignment: Alignment.bottomCenter,
            child: WBFloatingNav(
              world: WBWorld.energie,
              activeIndex: _currentIndex,
              items: const [
                WBFloatingNavItem(icon: Icons.home, label: 'Home'),
                WBFloatingNavItem(icon: Icons.self_improvement, label: 'Spirit'),
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
      IconButton(
        icon: const Icon(Icons.swap_horiz, color: Color(0xFFC79AFF)),
        iconSize: 22,
        onPressed: () => Navigator.pop(context),
        tooltip: 'Zur Portal-Auswahl',
      ),
      IconButton(
        icon: const Icon(Icons.analytics_outlined, color: Color(0xFFC79AFF)),
        iconSize: 22,
        onPressed: () {
          HapticService.selectionClick();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const StatsDashboardScreen(world: 'energie'),
            ),
          );
        },
        tooltip: 'Statistiken',
      ),
      if (kDebugMode) _DebugAdminBadge(adminState: adminState),
      if (adminState.isAdmin)
        IconButton(
          icon: const Icon(Icons.admin_panel_settings,
              color: Colors.orange),
          iconSize: 22,
          onPressed: () async {
            HapticService.mediumImpact();
            final notifier =
                ref.read(adminStateProvider('energie').notifier);
            await notifier.load();
            await Future.delayed(const Duration(milliseconds: 200));
            if (mounted) {
              Navigator.push(
                // ignore: use_build_context_synchronously
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const WorldAdminDashboard(world: 'energie'),
                ),
              );
            }
          },
          tooltip: 'Admin-Dashboard',
        ),
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
            ref.read(adminStateProvider('energie').notifier).refresh();
          }
        },
        tooltip: 'Profil-Einstellungen',
      ),
    ];
  }
}

/// Cosmic-Hintergrund mit subtiler Welt-Atmosphäre.
class _CosmicBackground extends StatelessWidget {
  final WBWorld world;
  const _CosmicBackground({required this.world});

  @override
  Widget build(BuildContext context) {
    final palette = context.wb.palette(world);
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0D0A1A),
                  Color(0xFF050310),
                  Color(0xFF000004),
                ],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.7),
                radius: 1.2,
                colors: [
                  palette.primary.withValues(alpha: 0.10),
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
