import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
import 'profile_settings_screen.dart';

/// 🌍 ENERGIE-WELT DASHBOARD (RIVERPOD VERSION)
///
/// Migration von StatefulWidget → ConsumerStatefulWidget
/// - Admin-Status kommt jetzt von Riverpod statt setState
/// - Offline-First mit Backend-Sync
/// - Automatische Refresh bei Profil-Änderungen
///
/// ARCHITEKTUR-VERBESSERUNGEN:
/// ✅ Single Source of Truth (AdminStateNotifier)
/// ✅ Kein Code-Duplikation mit Materie-Welt
/// ✅ Backend-safe (Timeouts blockieren nie die UI)
/// ✅ Automatische Refresh bei App-Resume

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
    // Observer für App-Lifecycle
    WidgetsBinding.instance.addObserver(this);

    // 🔥 KRITISCHER FIX: Admin-State SOFORT beim Screen-Load laden
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Force-Load Admin-State aus Hive
        ref.read(adminStateProvider('energie').notifier).load();
        
        if (kDebugMode) {
          debugPrint('✅ Energie Screen: Admin-State geladen');
        }
      }
    });

    // Haptic Feedback beim Betreten
    Future.delayed(const Duration(milliseconds: 1000), () {
      HapticService.selectionClick();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Refresh bei App-Resume
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Admin-Status neu laden
      ref.read(adminStateProvider('energie').notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 RIVERPOD: Admin-Status aus State lesen
    final adminState = ref.watch(adminStateProvider('energie'));

    // 🔥 CRITICAL: Tabs mit Key erstellen, damit sie neu gebaut werden wenn Admin-Status sich ändert
    final tabs = [
      EnergieHomeTabV5(key: ValueKey('home_${adminState.username}_${adminState.role}')),
      const SpiritTabModern(),
      const EnergieCommunityTabModern(),
      const EnergieKarteTabPro(),
      const UnifiedKnowledgeTab(world: 'energie'),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4A148C), // Lila
              Color(0xFF1A1A1A), // Dunkelgrau
              Color(0xFF000000), // Schwarz
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF7B1FA2).withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Zurück-Button
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),

                        // Titel
                        const Expanded(
                          child: Text(
                            'ENERGIE',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 4,
                            ),
                          ),
                        ),

                        // Portal-Wechsel Button
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFAB47BC).withValues(alpha: 0.5),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.swap_horiz, color: Color(0xFFAB47BC)),
                            iconSize: 28,
                            onPressed: () => Navigator.pop(context),
                            tooltip: 'Zur Portal-Auswahl',
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Stats Button
                        IconButton(
                          icon: const Icon(Icons.analytics_outlined, color: Color(0xFFAB47BC)),
                          iconSize: 24,
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
                        const SizedBox(width: 8),

                        // 🐛 DEBUG BUTTON (Optional - kann später entfernt werden)
                        if (kDebugMode)
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: adminState.isAdmin ? Colors.green : Colors.red,
                              boxShadow: [
                                BoxShadow(
                                  color: (adminState.isAdmin ? Colors.green : Colors.red)
                                      .withValues(alpha: 0.5),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(
                                adminState.isAdmin ? Icons.check_circle : Icons.cancel,
                                color: Colors.white,
                              ),
                              iconSize: 24,
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('🐛 ADMIN STATUS DEBUG'),
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
                                        onPressed: () {
                                          // Refresh Admin-Status
                                          ref.read(adminStateProvider('energie').notifier).refresh();
                                          Navigator.pop(context);
                                        },
                                        child: const Text('🔄 REFRESH'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              tooltip: 'Debug: Admin-Status',
                            ),
                          ),

                        // 🛡️ ADMIN BUTTON - NUR SICHTBAR FÜR ADMINS
                        if (adminState.isAdmin) ...[
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withValues(alpha: 0.5),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.admin_panel_settings,
                                color: Colors.orange,
                              ),
                              iconSize: 28,
                              onPressed: () async {
                                HapticService.mediumImpact();
                                
                                // 🔥 KRITISCHER FIX: STATE KOMPLETT NEU LADEN VOR NAVIGATION
                                if (kDebugMode) {
                                  debugPrint('🛡️ Admin-Button geklickt - State wird resettet...');
                                }
                                
                                // 1. State-Notifier holen
                                final notifier = ref.read(adminStateProvider('energie').notifier);
                                
                                // 2. FORCE REFRESH (lädt Profil komplett neu aus Hive)
                                await notifier.load();
                                
                                // 3. Kurz warten damit State garantiert aktualisiert ist
                                await Future.delayed(const Duration(milliseconds: 200));
                                
                                // 4. Finalen State prüfen (Debug)
                                if (kDebugMode) {
                                  final finalState = ref.read(adminStateProvider('energie'));
                                  debugPrint('✅ State vor Navigation:');
                                  debugPrint('   username: ${finalState.username}');
                                  debugPrint('   isAdmin: ${finalState.isAdmin}');
                                  debugPrint('   isRootAdmin: ${finalState.isRootAdmin}');
                                }
                                
                                // 5. JETZT ERST Dashboard öffnen (mit frischem State)
                                if (mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const WorldAdminDashboard(world: 'energie'),
                                    ),
                                  );
                                }
                              },
                              tooltip: 'Admin-Dashboard',
                            ),
                          ),
                        ],

                        // Profil-Einstellungen Button
                        IconButton(
                          icon: const Icon(Icons.settings, color: Colors.white),
                          onPressed: () async {
                            HapticService.selectionClick();
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProfileSettingsScreen(),
                              ),
                            );
                            // 🔥 WICHTIG: Admin-Status nach Profil-Änderungen neu laden
                            if (mounted) {
                              ref.read(adminStateProvider('energie').notifier).refresh();
                            }
                          },
                          tooltip: 'Profil-Einstellungen',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Tab Content
              Expanded(
                child: tabs[_currentIndex],
              ),

              // Bottom Navigation
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      const Color(0xFF7B1FA2).withValues(alpha: 0.2),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: BottomNavigationBar(
                  currentIndex: _currentIndex,
                  onTap: (index) {
                    HapticService.selectionClick();
                    setState(() => _currentIndex = index);
                  },
                  backgroundColor: Colors.transparent,
                  selectedItemColor: const Color(0xFFAB47BC),
                  unselectedItemColor: Colors.white54,
                  type: BottomNavigationBarType.fixed,
                  elevation: 0,
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home),
                      label: 'Home',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.psychology),
                      label: 'Spirit',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.people),
                      label: 'Community',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.map),
                      label: 'Karte',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.menu_book),
                      label: 'Wissen',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
