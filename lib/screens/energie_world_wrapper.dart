import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'energie_world_screen.dart';
import '../services/achievement_service.dart';  // 🏆 Achievement System

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

    // Main World State - IMMER ANZEIGEN
    return const EnergieWorldScreen();
  }
}
