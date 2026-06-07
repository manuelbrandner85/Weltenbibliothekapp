import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

import '../core/auth/admin_resolver.dart';
import 'energie_world_screen.dart';
import '../services/achievement_service.dart';
import '../theme/wb_cinematic_tokens.dart';
import '../widgets/cinematic/wb_glass_app_bar.dart';

/// Energie-Welt-Wrapper
/// Admin-Check direkt über Supabase profiles.role (nicht OpenClaw).
class EnergieWorldWrapper extends StatefulWidget {
  const EnergieWorldWrapper({super.key});

  @override
  State<EnergieWorldWrapper> createState() => _EnergieWorldWrapperState();
}

class _EnergieWorldWrapperState extends State<EnergieWorldWrapper> {
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
      // AdminResolver: Supabase Session + InvisibleAuth + Web SharedPref —
      // Root-Admin wird über alle 3 Pfade erkannt.
      _isAdmin = await AdminResolver.isCurrentUserAdmin();
      if (kDebugMode) debugPrint('👑 ENERGIE ADMIN-CHECK: $_isAdmin');
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Energie Admin-Check error: $e');
      _isAdmin = false;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _trackWorldVisit() async {
    try {
      await AchievementService().incrementProgress('world_traveler');
    } catch (e) { if (kDebugMode) debugPrint('energie_world_wrapper: silent catch -> $e'); }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF06040F),
        appBar: WBGlassAppBar(
          world: WBWorld.energie,
          title: 'ENERGIE',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.purple),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF4A148C).withValues(alpha: 0.3),
                Colors.black,
              ],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
            ),
          ),
        ),
      );
    }

    // Admin-Zugang läuft ausschließlich über das prominente Banner
    // (AdminDashboardButton) oben im World-Screen — kein FAB-Doppel.
    if (kDebugMode) debugPrint('👑 ENERGIE → admin=$_isAdmin');
    return const EnergieWorldScreen();
  }
}
