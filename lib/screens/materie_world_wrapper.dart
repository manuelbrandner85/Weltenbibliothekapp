import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'materie_world_screen.dart';
import '../services/achievement_service.dart';  // 🏆 Achievement System
import 'shared/world_admin_dashboard.dart';  // 🛡️ Admin Dashboard

/// Materie-Welt-Wrapper - SIMPLIFIED VERSION
class MaterieWorldWrapper extends StatefulWidget {
  const MaterieWorldWrapper({super.key});

  @override
  State<MaterieWorldWrapper> createState() => _MaterieWorldWrapperState();
}

class _MaterieWorldWrapperState extends State<MaterieWorldWrapper> {
  // UNUSED FIELD: final _storage = StorageService();
  // UNUSED FIELD: MaterieProfile? _profile;
  // ignore: unused_element
  bool _showOnboarding = false; // ignore: unused_field
  bool _isLoading = true;
  bool _isAdmin = false; // 👑 Admin Status

  @override
  void initState() {
    super.initState();
    // ✅ ADMIN-CHECK VOR WORLD-ANZEIGE
    _checkAdminStatusAndLoad();
    
    // 🏆 Achievement Trigger: World Visit
    _trackWorldVisit();
  }
  
  /// 👑 Admin-Status prüfen
  Future<void> _checkAdminStatusAndLoad() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final profile = await Supabase.instance.client
            .from('user_profiles')
            .select('is_admin')
            .eq('id', userId)
            .maybeSingle()
            .timeout(const Duration(seconds: 4));
        _isAdmin = profile?['is_admin'] == true;
        if (kDebugMode) {
          debugPrint('👑 MATERIE ADMIN-CHECK: $_isAdmin (userId: $userId)');
        }
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
          _showOnboarding = false;
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Admin-Check error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _showOnboarding = false;
          _isAdmin = false;
        });
      }
    }
  }
  
  /// Track world visit for achievements
  Future<void> _trackWorldVisit() async {
    try {
      await AchievementService().incrementProgress('world_traveler');
    } catch (e) {
      debugPrint('⚠️ Achievement tracking error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Loading State
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.blue),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('MATERIE', style: TextStyle(color: Colors.blue)),
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
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Initialisiere Materie-Welt...',
                  style: TextStyle(color: Colors.blue, fontSize: 16),
                ),
                const SizedBox(height: 16),
                // DEBUG-Button zum Skippen
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showOnboarding = true;
                      _isLoading = false;
                    });
                  },
                  child: const Text(
                    'FORCE ONBOARDING',
                    style: TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Onboarding State (nicht mehr verwendet - direkt zur Welt)
    // if (_showOnboarding) {
    //   return ProfileOnboardingScreen(
    //     worldType: 'materie',
    //     onProfileCreated: _onProfileCreated,
    //   );
    // }

    // Main World State - ADMIN DASHBOARD ODER NORMALER SCREEN
    if (_isAdmin) {
      // 🛡️ ADMIN: Zeige Admin-Dashboard
      if (kDebugMode) {
        debugPrint('👑 Navigiere zu ADMIN DASHBOARD (materie)');
      }
      return const WorldAdminDashboard(world: 'materie');
    }
    
    // 👤 NORMAL USER: Zeige normalen World Screen
    return const MaterieWorldScreen();
  }
}
