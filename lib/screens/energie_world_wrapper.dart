import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'energie_world_screen.dart';
import '../services/achievement_service.dart';  // 🏆 Achievement System
import '../services/storage_service.dart';  // 🔑 Storage for userId
import '../services/openclaw_dashboard_service.dart';  // 🚀 OpenClaw Admin Check
import 'shared/world_admin_dashboard.dart';  // 🛡️ Admin Dashboard

/// Energie-Welt-Wrapper - SIMPLIFIED VERSION
class EnergieWorldWrapper extends StatefulWidget {
  const EnergieWorldWrapper({super.key});

  @override
  State<EnergieWorldWrapper> createState() => _EnergieWorldWrapperState();
}

class _EnergieWorldWrapperState extends State<EnergieWorldWrapper> {
  // UNUSED FIELD: final _storage = StorageService();
  // UNUSED FIELD: EnergieProfile? _profile;
  bool _showOnboarding = false;
  bool _isLoading = true;
  bool _isAdmin = false; // 👑 Admin Status
  final OpenClawDashboardService _dashboardService = OpenClawDashboardService(); // 🚀

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
      // User-ID holen
      final userId = await StorageService().getUserId('energie');
      
      if (userId != null) {
        // Admin-Check via OpenClaw Dashboard Service
        _isAdmin = await _dashboardService.isAdmin(userId, 'energie');
        
        if (kDebugMode) {
          debugPrint('👑 ENERGIE ADMIN-CHECK: $_isAdmin (userId: $userId)');
        }
      }
      
      // Welt anzeigen (mit oder ohne Admin-Status)
      if (mounted) {
        setState(() {
          _isLoading = false;
          _showOnboarding = false; // DIREKT ZUR WELT!
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Admin-Check error: $e');
      }
      // Bei Fehler: Normal zur Welt
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

    // Onboarding State (nicht mehr verwendet - direkt zur Welt)
    // if (_showOnboarding) {
    //   return ProfileOnboardingScreen(
    //     worldType: 'energie',
    //     onProfileCreated: _onProfileCreated,
    //   );
    // }

    // Main World State - ADMIN DASHBOARD ODER NORMALER SCREEN
    if (_isAdmin) {
      // 🛡️ ADMIN: Zeige Admin-Dashboard
      if (kDebugMode) {
        debugPrint('👑 Navigiere zu ADMIN DASHBOARD (energie)');
      }
      return const WorldAdminDashboard(world: 'energie');
    }
    
    // 👤 NORMAL USER: Zeige normalen World Screen
    return const EnergieWorldScreen();
  }
}
