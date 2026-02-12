import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🎓 ENHANCED ONBOARDING FLOW v8.0
/// 
/// 6-Screen Tutorial mit Features:
/// - Swipe-Gestures (PageView)
/// - Skip-Button
/// - "Nicht mehr zeigen" Checkbox
/// - Animierte Illustrationen mit Feature-Highlights
/// - Interactive Elements
/// - Zeigt nur beim ersten App-Start
class OnboardingEnhancedScreen extends StatefulWidget {
  const OnboardingEnhancedScreen({super.key});

  @override
  State<OnboardingEnhancedScreen> createState() => _OnboardingEnhancedScreenState();
}

class _OnboardingEnhancedScreenState extends State<OnboardingEnhancedScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _dontShowAgain = false;
  late List<AnimationController> _animationControllers;

  final List<OnboardingPageData> _pages = [
    // ✅ INTRO-TUTORIAL: 4 Seiten (ENERGIE, MATERIE, Features, Portal)
    OnboardingPageData(
      title: '🟣 ENERGIE - Die spirituelle Dimension',
      description: 'Spirit · Bewusstsein · Archetypen · Symbolik\n\n'
          'Entdecke die energetische Ebene des Seins.',
      icon: Icons.self_improvement,
      features: [
        '✨ Archetypen-Rechner',
        '🎴 Tarot-System',
        '🔮 Mystische Symbole',
      ],
      gradient: [const Color(0xFF9B51E0), const Color(0xFF4A148C)],
    ),
    OnboardingPageData(
      title: '🔵 MATERIE - Die physische Welt',
      description: 'Forschung · Fakten · Geopolitik · Systeme\n\n'
          'Erforsche die materielle Realität mit wissenschaftlichen Methoden.',
      icon: Icons.public,
      features: [
        '🔬 Recherche-System mit 3 Modi',
        '📊 Kaninchenbau (6 Ebenen)',
        '🌍 Internationale Perspektiven',
      ],
      gradient: [const Color(0xFF2196F3), const Color(0xFF0D47A1)],
    ),
    OnboardingPageData(
      title: '✨ Interaktive Features!',
      description: 'Entdecke die versteckten Features:',
      icon: Icons.touch_app,
      features: [
        '👆 Touch: Partikel weichen deinem Finger aus',
        '📱 Neige dein Handy: Portal folgt (Gyroscope)',
        '⭐ Sterne: 100 twinkelnde Sterne im Hintergrund',
        '⚡ Energie-Strahlen vom Portal zu den Buttons',
        '🎨 Adaptive Farben: Ändern sich mit der Tageszeit',
      ],
      gradient: [const Color(0xFF00E5FF), const Color(0xFF006064)],
    ),
    OnboardingPageData(
      title: '🌀 Das Portal zwischen den Welten',
      description: 'Dieses mystische Portal verbindet zwei Realitäten.\n\n'
          'Es dreht sich kontinuierlich und zieht dich in seine Tiefen.',
      icon: Icons.auto_awesome,
      features: [
        '💫 Tippe 10x auf das Portal für ein Geheimnis!',
      ],
      gradient: [const Color(0xFFFFD700), const Color(0xFF1A237E)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationControllers = List.generate(
      _pages.length,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200),
      ),
    );
    
    // Start first animation
    _animationControllers[0].forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    
    // Trigger animation for new page
    if (index < _animationControllers.length) {
      _animationControllers[index].forward();
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Mark ALL onboarding types as completed (to prevent any confusion)
    await prefs.setBool('enhanced_onboarding_completed', true);
    await prefs.setBool('new_onboarding_completed', true);
    await prefs.setBool('onboarding_completed', true);
    
    if (mounted) {
      // Navigate to main app (IntroImageScreen)
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // PageView
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              return _buildPage(_pages[index], _animationControllers[index]);
            },
          ),

          // Skip button (top right)
          if (_currentPage < _pages.length - 1)
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton(
                    onPressed: () {
                      _pageController.animateToPage(
                        _pages.length - 1,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      );
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.3),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Überspringen',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Bottom controls
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Page indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pages.length, (index) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: _currentPage == index ? 32 : 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 24),

                    // "Nicht mehr zeigen" checkbox (nur auf letzter Page)
                    if (_currentPage == _pages.length - 1)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: CheckboxListTile(
                          value: _dontShowAgain,
                          onChanged: (value) {
                            setState(() => _dontShowAgain = value ?? false);
                          },
                          title: const Text(
                            'Nicht mehr zeigen',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: Colors.white,
                          checkColor: _pages[_currentPage].gradient[0],
                          dense: true,
                        ),
                      ),

                    // Next/Start button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_currentPage == _pages.length - 1) {
                            _completeOnboarding();
                          } else {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _pages[_currentPage].gradient[0],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentPage == _pages.length - 1
                                  ? 'Los geht\'s!'
                                  : 'Weiter',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _currentPage == _pages.length - 1
                                  ? Icons.rocket_launch
                                  : Icons.arrow_forward,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingPageData page, AnimationController controller) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: page.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 1),
              
              // Animated Icon
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: controller,
                  curve: Curves.easeIn,
                ),
                child: ScaleTransition(
                  scale: CurvedAnimation(
                    parent: controller,
                    curve: Curves.elasticOut,
                  ),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      page.icon,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Title
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: controller,
                  curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
                )),
                child: FadeTransition(
                  opacity: CurvedAnimation(
                    parent: controller,
                    curve: const Interval(0.2, 0.8),
                  ),
                  child: Text(
                    page.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Description
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: controller,
                  curve: const Interval(0.3, 0.9, curve: Curves.easeOut),
                )),
                child: FadeTransition(
                  opacity: CurvedAnimation(
                    parent: controller,
                    curve: const Interval(0.3, 0.9),
                  ),
                  child: Text(
                    page.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Feature List
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: controller,
                  curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
                )),
                child: FadeTransition(
                  opacity: CurvedAnimation(
                    parent: controller,
                    curve: const Interval(0.4, 1.0),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: page.features.map((feature) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  feature,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingPageData {
  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradient;
  final List<String> features;

  OnboardingPageData({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.features,
  });
}
