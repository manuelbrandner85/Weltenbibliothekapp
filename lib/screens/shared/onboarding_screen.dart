import 'package:flutter/material.dart';
import '../../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import 'package:shared_preferences/shared_preferences.dart';

/// 🎓 ONBOARDING FLOW
/// 
/// 4-Screen Tutorial mit Features:
/// - Swipe-Gestures (PageView)
/// - Skip-Button
/// - "Nicht mehr zeigen" Checkbox
/// - Animierte Illustrationen
/// - Zeigt nur beim ersten App-Start
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _dontShowAgain = false;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Willkommen in der\nWeltenbibliothek',
      description: 'Entdecke verborgenes Wissen aus zwei Welten:\nMaterie & Energie',
      icon: Icons.auto_stories,
      gradient: const [Color(0xFF1E88E5), Color(0xFF7E57C2)],
    ),
    OnboardingPage(
      title: '100 Wissensdatenbank-\nEinträge',
      description: '50 Materie-Themen (Verschwörungen, Forschung)\n50 Energie-Themen (Meditation, Astrologie)',
      icon: Icons.library_books,
      gradient: const [Color(0xFF1E88E5), Color(0xFF0D47A1)],
    ),
    OnboardingPage(
      title: 'Favoriten & Notizen',
      description: 'Speichere Lieblingsartikel, schreibe persönliche Notizen\nund verfolge deinen Lesefortschritt',
      icon: Icons.favorite,
      gradient: const [Color(0xFFE53935), Color(0xFFC62828)],
    ),
    OnboardingPage(
      title: 'Statistiken & Insights',
      description: 'Visualisiere deinen Fortschritt mit Charts,\nStreaks und detaillierten Statistiken',
      icon: Icons.analytics,
      gradient: const [Color(0xFF7E57C2), Color(0xFF4A148C)],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Always mark as completed (respect "don't show again" is implicit)
    await prefs.setBool('new_onboarding_completed', true);
    
    if (mounted) {
      // Navigate to main app (pop to previous route or restart)
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
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
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              return _buildPage(_pages[index]);
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
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: const Text(
                      'Überspringen',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
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
                          width: _currentPage == index ? 24 : 8,
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
                      CheckboxListTile(
                        value: _dontShowAgain,
                        onChanged: (value) {
                          setState(() => _dontShowAgain = value ?? false);
                        },
                        title: const Text(
                          'Nicht mehr zeigen',
                          style: TextStyle(color: Colors.white),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: Colors.white,
                        checkColor: _pages[_currentPage].gradient[0],
                      ),

                    const SizedBox(height: 16),

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
                              duration: const Duration(milliseconds: 300),
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
                        child: Text(
                          _currentPage == _pages.length - 1
                              ? 'Los geht\'s!'
                              : 'Weiter',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
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

  Widget _buildPage(OnboardingPage page) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: page.gradient,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Icon
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        page.icon,
                        size: 64,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 48),

              // Title
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
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
                  );
                },
              ),

              const SizedBox(height: 24),

              // Description
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
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
                  );
                },
              ),

              const SizedBox(height: 100), // Space for bottom controls
            ],
          ),
        ),
      ),
    );
  }

  /// Check if onboarding should be shown
  // TODO: Review unused method: shouldShowOnboarding
  // static Future<bool> shouldShowOnboarding() async {
    // final prefs = await SharedPreferences.getInstance();
    // final completed = prefs.getBool('new_onboarding_completed') ?? false;
    // return !completed;
  // }

  /// Reset onboarding (for testing)
  // TODO: Review unused method: resetOnboarding
  // static Future<void> resetOnboarding() async {
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.remove('new_onboarding_completed');
  // }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradient;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
  });
}
