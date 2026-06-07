import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

import '../../core/auth/admin_resolver.dart';
import 'ursprung_world_screen.dart';
import '../../services/achievement_service.dart';
import '../../theme/wb_cinematic_tokens.dart';
import '../../widgets/cinematic/wb_glass_app_bar.dart';

import '../onboarding/world_onboarding_screen.dart';

/// 🌀 Ursprung-Welt-Wrapper
/// Admin-Check direkt über Supabase profiles.role (nicht OpenClaw).
class UrsprungWorldWrapper extends StatefulWidget {
  const UrsprungWorldWrapper({super.key});

  @override
  State<UrsprungWorldWrapper> createState() => _UrsprungWorldWrapperState();
}

class _UrsprungWorldWrapperState extends State<UrsprungWorldWrapper> {
  bool _isLoading = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminAndLoad();
    _trackWorldVisit();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowOnboarding());
  }

  Future<void> _maybeShowOnboarding() async {
    final done = await WorldOnboardingScreen.isCompleted('ursprung');
    if (done || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorldOnboardingScreen.ursprung(
          onComplete: () => Navigator.of(context).pop(),
        ),
        fullscreenDialog: true,
      ),
    );
  }

  Future<void> _checkAdminAndLoad() async {
    try {
      _isAdmin = await AdminResolver.isCurrentUserAdmin();
      if (kDebugMode) debugPrint('👑 URSPRUNG ADMIN-CHECK: $_isAdmin');
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Ursprung Admin-Check error: $e');
      _isAdmin = false;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _trackWorldVisit() async {
    try {
      await AchievementService().incrementProgress('world_traveler');
    } catch (e) { if (kDebugMode) debugPrint('ursprung_world_wrapper: silent catch -> $e'); }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF050510),
        appBar: WBGlassAppBar(
          world: WBWorld.ursprung,
          title: 'URSPRUNG',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF00D4AA)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF00D4AA).withValues(alpha: 0.15),
                const Color(0xFF050510),
              ],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D4AA)),
            ),
          ),
        ),
      );
    }

    // Admin-Zugang läuft ausschließlich über das prominente Banner
    // (AdminDashboardButton) oben im World-Screen — kein FAB-Doppel.
    if (kDebugMode) debugPrint('👑 URSPRUNG → admin=$_isAdmin');
    return const UrsprungWorldScreen();
  }
}
