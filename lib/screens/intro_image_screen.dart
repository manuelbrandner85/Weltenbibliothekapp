import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'portal_home_screen.dart'; // ORIGINAL CINEMA-QUALITY PORTAL
import 'shared/onboarding_enhanced_screen.dart'; // ONBOARDING

/// Intro-Screen mit Bild und Überspringen-Button
class IntroImageScreen extends StatefulWidget {
  const IntroImageScreen({super.key});

  @override
  State<IntroImageScreen> createState() => _IntroImageScreenState();
}

class _IntroImageScreenState extends State<IntroImageScreen> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _imageLoaded = false;
  
  @override
  void initState() {
    super.initState();
    
    debugPrint('🎬 IntroImageScreen: initState gestartet');
    
    // ✅ PRELOAD IMAGE für smooth display
    _preloadImage();
    
    // Fade-in Animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    
    debugPrint('🎬 IntroImageScreen: Animation vorbereitet');
    
    // ✅ SOFORT ZUM PORTAL - Kein Auto-Navigation Delay mehr
    // Auto-Navigation wird entfernt - User navigiert durch Tippen
    // Future.delayed wurde entfernt für direkteren Zugang
  }
  
  /// ✅ PRELOAD IMAGE - startet Animation nur wenn Bild geladen
  Future<void> _preloadImage() async {
    try {
      final image = const AssetImage('assets/images/intro_weltenbibliothek.webp');
      await precacheImage(image, context);
      
      if (mounted) {
        setState(() {
          _imageLoaded = true;
        });
        _fadeController.forward();
        debugPrint('✅ IntroImageScreen: Bild geladen, Animation gestartet');
      }
    } catch (e) {
      debugPrint('⚠️ IntroImageScreen: Bild-Preload Fehler: $e');
      // Fallback: Animation trotzdem starten
      if (mounted) {
        setState(() {
          _imageLoaded = true;
        });
        _fadeController.forward();
      }
    }
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }
  
  void _navigateToApp() async {
    debugPrint('🎬 IntroImageScreen: _navigateToApp aufgerufen');
    try {
      // ✅ Prüfe ob Onboarding schon gesehen wurde
      final prefs = await SharedPreferences.getInstance();
      final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
      
      final nextScreen = hasSeenOnboarding
          ? const PortalHomeScreen() // Direkt zum Portal wenn schon gesehen
          : const OnboardingEnhancedScreen(); // Onboarding wenn noch nicht gesehen
      
      debugPrint('🎬 IntroImageScreen: Navigiere zu ${hasSeenOnboarding ? "Portal" : "Onboarding"}');
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) {
              return nextScreen;
            },
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
      debugPrint('🎬 IntroImageScreen: Navigation abgeschlossen');
    } catch (e) {
      debugPrint('❌ IntroImageScreen: Navigation error: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          debugPrint('🎬 IntroImageScreen: User tap detected, navigating immediately...');
          _navigateToApp();
        },
        child: Stack(
        children: [
          // ✅ SMOOTH LOADING: Zeige nur wenn Bild geladen
          if (_imageLoaded)
            // Hintergrundbild mit Fade-in (FULLSCREEN - ASSET-BASED)
            FadeTransition(
              opacity: _fadeAnimation,
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: Image.asset(
                  'assets/images/intro_weltenbibliothek.webp',
                  fit: BoxFit.cover,
                  // ✅ GAPLESS PLAYBACK für smooth display
                  gaplessPlayback: true,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback: Direkt zur App bei Fehler
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        _navigateToApp();
                      }
                    });
                    return Container(
                      color: Colors.black,
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_not_supported, color: Colors.white54, size: 64),
                            SizedBox(height: 16),
                            Text(
                              'Intro-Bild fehlt',
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          
          // ✅ LOADING INDICATOR während Bild lädt
          if (!_imageLoaded)
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white54,
                strokeWidth: 2,
              ),
            ),
          
          // Überspringen-Button (oben rechts)
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _navigateToApp,
                    borderRadius: BorderRadius.circular(25),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Überspringen',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}
