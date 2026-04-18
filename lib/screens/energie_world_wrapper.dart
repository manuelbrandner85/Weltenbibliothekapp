import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'energie_world_screen.dart';
import '../services/achievement_service.dart';  // 🏆 Achievement System
import 'shared/world_admin_dashboard.dart';  // 🛡️ Admin Dashboard

/// Energie-Welt-Wrapper - SIMPLIFIED VERSION
class EnergieWorldWrapper extends StatefulWidget {
  const EnergieWorldWrapper({super.key});

  @override
  State<EnergieWorldWrapper> createState() => _EnergieWorldWrapperState();
}

class _EnergieWorldWrapperState extends State<EnergieWorldWrapper> {
  bool _showOnboarding = false; // ignore: unused_field
  bool _isLoading = true;
  bool _isAdmin = false; // 👑 Admin Status

  @override
  void initState() {
    super.initState();
    _checkAdminStatusAndLoad();
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
          debugPrint('👑 ENERGIE ADMIN-CHECK: $_isAdmin (userId: $userId)');
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
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.purple),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('ENERGIE', style: TextStyle(color: Colors.purple)),
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
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Initialisiere Energie-Welt...',
                  style: TextStyle(color: Colors.purple, fontSize: 16),
                ),
                const SizedBox(height: 16),
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

    // Main World State - ADMIN DASHBOARD ODER NORMALER SCREEN
    if (_isAdmin) {
      if (kDebugMode) debugPrint('👑 Navigiere zu ADMIN DASHBOARD (energie)');
      return const WorldAdminDashboard(world: 'energie');
    }

    return const EnergieWorldScreen();
  }
}
