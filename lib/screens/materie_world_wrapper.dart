import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'materie_world_screen.dart';
import '../services/achievement_service.dart';  // 🏆 Achievement System

/// Materie-Welt-Wrapper - SIMPLIFIED VERSION
class MaterieWorldWrapper extends StatefulWidget {
  const MaterieWorldWrapper({super.key});

  @override
  State<MaterieWorldWrapper> createState() => _MaterieWorldWrapperState();
}

class _MaterieWorldWrapperState extends State<MaterieWorldWrapper> {
  // UNUSED FIELD: final _storage = StorageService();
  // UNUSED FIELD: MaterieProfile? _profile;
  bool _showOnboarding = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // BYPASS FIX: Direkt zur Welt ohne Profil-Check
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _showOnboarding = false; // DIREKT ZUR WELT!
        });
      }
    });
    
    // 🏆 Achievement Trigger: World Visit
    _trackWorldVisit();
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

    // Main World State - IMMER ANZEIGEN
    return const MaterieWorldScreen();
  }
}
