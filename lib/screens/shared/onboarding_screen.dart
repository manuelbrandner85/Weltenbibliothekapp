import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// OpenClaw v2.0
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/wb_cinematic_tokens.dart';
import '../../widgets/cinematic/wb_vignette.dart';
import '../../widgets/cinematic/wb_glow_button.dart';

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
      description:
          'Entdecke verborgenes Wissen aus vier Welten:\nMaterie, Energie, Vorhang & Ursprung',
      icon: Icons.auto_stories,
      gradient: const [Color(0xFF050310), Color(0xFF0D0A1A)],
      world: WBWorld.neutral,
      backdrop: 'assets/backdrops/onboarding_hero.webp',
    ),
    OnboardingPage(
      title: 'Materie — Fakten\n& Recherche',
      description:
          '50 Materie-Themen: Geopolitik, Verschwörungen,\nOSINT-Tools und investigative Recherche',
      icon: Icons.search,
      gradient: const [Color(0xFF050310), Color(0xFF0A2452)],
      world: WBWorld.materie,
      backdrop: 'assets/backdrops/world_materie.webp',
    ),
    OnboardingPage(
      title: 'Energie — Spirit\n& Bewusstsein',
      description:
          '50 Energie-Themen: Meditation, Astrologie,\nChakren, Numerologie und Healing',
      icon: Icons.self_improvement,
      gradient: const [Color(0xFF050310), Color(0xFF3B0D6E)],
      world: WBWorld.energie,
      backdrop: 'assets/backdrops/world_energie.webp',
    ),
    OnboardingPage(
      title: 'Community &\nLive-Features',
      description:
          'Echtzeit-Chat, Lesezeichen, Statistiken\nund gemeinsames Erforschen',
      icon: Icons.people,
      gradient: const [Color(0xFF050310), Color(0xFF1A1A2E)],
      world: WBWorld.neutral,
      backdrop: 'assets/backdrops/onboarding_hero.webp',
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
      backgroundColor: const Color(0xFF050310),
      body: Stack(
        children: [
          // Vignette background
          const Positioned.fill(child: WBVignette()),

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

                    // Next/Start button — Cinema WBGlowButton
                    WBGlowButton(
                      label: _currentPage == _pages.length - 1
                          ? 'LOS GEHTS'
                          : 'WEITER',
                      icon: _currentPage == _pages.length - 1
                          ? Icons.rocket_launch
                          : Icons.arrow_forward,
                      world: _pages[_currentPage].world,
                      fullWidth: true,
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        if (_currentPage == _pages.length - 1) {
                          _completeOnboarding();
                        } else {
                          _pageController.nextPage(
                            duration: WBMotion.page,
                            curve: WBMotion.enterCurve,
                          );
                        }
                      },
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
    final palette = context.wb.palette(page.world);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: page.gradient,
        ),
        image: page.backdrop != null
            ? DecorationImage(
                image: AssetImage(page.backdrop!),
                fit: BoxFit.cover,
                opacity: 0.45,
              )
            : null,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(WBSpace.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Icon with world-glow
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: WBMotion.hero,
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: palette.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: palette.primary.withValues(alpha: 0.3),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Icon(
                        page.icon,
                        size: 56,
                        color: palette.label,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: WBSpace.huge),

              // Title — cinema typography
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: WBMotion.card,
                curve: WBMotion.enterCurve,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: Text(
                        page.title,
                        textAlign: TextAlign.center,
                        style: WBType.hero.copyWith(
                          fontSize: 28,
                          letterSpacing: 3.0,
                          height: 1.3,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: WBSpace.xxl),

              // Description
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: WBMotion.enterCurve,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: Text(
                        page.description,
                        textAlign: TextAlign.center,
                        style: WBType.body.copyWith(
                          fontSize: 15,
                          height: 1.6,
                          color: Colors.white.withValues(alpha: 0.75),
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
  // final prefs = await SharedPreferences.getInstance();
  // final completed = prefs.getBool('new_onboarding_completed') ?? false;
  // return !completed;
  // }

  /// Reset onboarding (for testing)
  // final prefs = await SharedPreferences.getInstance();
  // await prefs.remove('new_onboarding_completed');
  // }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradient;
  final WBWorld world;
  final String? backdrop;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
    this.world = WBWorld.neutral,
    this.backdrop,
  });
}
