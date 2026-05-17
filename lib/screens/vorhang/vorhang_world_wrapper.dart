import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

import '../../core/auth/admin_resolver.dart';
import 'vorhang_world_screen.dart';
import '../../services/achievement_service.dart';
import '../../theme/wb_cinematic_tokens.dart';
import '../../widgets/cinematic/wb_glass_app_bar.dart';

import '../onboarding/world_onboarding_screen.dart';

/// 🎭 Vorhang-Welt-Wrapper
/// Admin-Check direkt über Supabase profiles.role (nicht OpenClaw).
class VorhangWorldWrapper extends StatefulWidget {
  const VorhangWorldWrapper({super.key});

  @override
  State<VorhangWorldWrapper> createState() => _VorhangWorldWrapperState();
}

class _VorhangWorldWrapperState extends State<VorhangWorldWrapper> {
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
    final done = await WorldOnboardingScreen.isCompleted('vorhang');
    if (done || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorldOnboardingScreen.vorhang(
          onComplete: () => Navigator.of(context).pop(),
        ),
        fullscreenDialog: true,
      ),
    );
  }

  Future<void> _checkAdminAndLoad() async {
    try {
      _isAdmin = await AdminResolver.isCurrentUserAdmin();
      if (kDebugMode) debugPrint('👑 VORHANG ADMIN-CHECK: $_isAdmin');
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Vorhang Admin-Check error: $e');
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
        backgroundColor: const Color(0xFF000000),
        appBar: WBGlassAppBar(
        world: WBWorld.vorhang,
        title: 'VORHANG',
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFFC9A84C)),
            onPressed: () => Navigator.of(context).pop(),
          ),
      ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFC9A84C).withValues(alpha: 0.15),
                Colors.black,
              ],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC9A84C)),
            ),
          ),
        ),
      );
    }

    // Admin-Zugang läuft ausschließlich über das prominente Banner
    // (AdminDashboardButton) oben im World-Screen — kein FAB-Doppel.
    if (kDebugMode) debugPrint('👑 VORHANG → admin=$_isAdmin');
    return const VorhangWorldScreen();
  }
}
