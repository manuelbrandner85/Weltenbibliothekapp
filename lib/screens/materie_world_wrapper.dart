import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

import '../core/auth/admin_resolver.dart';
import 'materie_world_screen.dart';
import '../services/achievement_service.dart';
import 'shared/world_admin_dashboard.dart';
import '../theme/wb_cinematic_tokens.dart';
import '../widgets/cinematic/wb_glass_app_bar.dart';
import '../widgets/cinematic/wb_vignette.dart';

/// Materie-Welt-Wrapper
/// Admin-Check direkt über Supabase profiles.role (nicht OpenClaw).
class MaterieWorldWrapper extends StatefulWidget {
  const MaterieWorldWrapper({super.key});

  @override
  State<MaterieWorldWrapper> createState() => _MaterieWorldWrapperState();
}

class _MaterieWorldWrapperState extends State<MaterieWorldWrapper> {
  bool _isLoading = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminAndLoad();
    _trackWorldVisit();
  }

  Future<void> _checkAdminAndLoad() async {
    try {
      // AdminResolver kennt 3 Auth-Pfade: Supabase Session, lokales
      // InvisibleAuth-Profile, Web-SharedPref. Root-Admin ('Weltenbibliothek')
      // wird in JEDEM Pfad erkannt → Dashboard erscheint in allen 4 Welten.
      _isAdmin = await AdminResolver.isCurrentUserAdmin();
      if (kDebugMode) debugPrint('👑 MATERIE ADMIN-CHECK: $_isAdmin');
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Materie Admin-Check error: $e');
      _isAdmin = false;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _trackWorldVisit() async {
    try {
      await AchievementService().incrementProgress('world_traveler');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF04080F),
        appBar: WBGlassAppBar(
        world: WBWorld.materie,
        title: 'MATERIE',
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.blue),
            onPressed: () => Navigator.of(context).pop(),
          ),
      ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF0D47A1).withValues(alpha: 0.3),
                Colors.black,
              ],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
        ),
      );
    }

    if (_isAdmin) {
      if (kDebugMode) debugPrint('👑 MATERIE → Admin FAB aktiv');
      return Stack(
        children: [
          const MaterieWorldScreen(),
          Positioned(
            bottom: 80,
            right: 16,
            child: FloatingActionButton.extended(
              heroTag: 'admin_fab_materie',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const WorldAdminDashboard(world: 'materie'),
                ),
              ),
              backgroundColor: const Color(0xFFC9A84C),
              foregroundColor: Colors.black,
              icon: const Icon(Icons.admin_panel_settings_rounded),
              label: const Text('Admin', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      );
    }

    return const MaterieWorldScreen();
  }
}
