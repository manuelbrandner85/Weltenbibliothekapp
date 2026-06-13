import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

import '../core/auth/admin_resolver.dart';
import 'materie_world_screen.dart';
import '../services/achievement_service.dart';
import '../theme/wb_cinematic_tokens.dart';
import '../widgets/cinematic/wb_glass_app_bar.dart';
import '../widgets/cinematic/wb_adaptive_backdrop.dart';

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
    } catch (e) { if (kDebugMode) debugPrint('materie_world_wrapper: silent catch -> $e'); }
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
        // Phase-1 backdrop: world still as the empty/loading state.
        body: WbAdaptiveBackdrop(
          fallbackImage: 'assets/images/world_materie.webp',
          overlayColor: Colors.black.withValues(alpha: 0.35),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
        ),
      );
    }

    // Admin-Zugang läuft ausschließlich über das prominente Banner
    // (AdminDashboardButton) oben im World-Screen — kein FAB-Doppel.
    if (kDebugMode) debugPrint('👑 MATERIE → admin=$_isAdmin');
    return const MaterieWorldScreen();
  }
}
