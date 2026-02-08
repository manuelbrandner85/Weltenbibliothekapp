/// Feature Tour Screen - WELTENBIBLIOTHEK v42
/// Intelligente, visuelle App-Tour mit Kategorie-Auswahl
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'setup_wizard_screen.dart';

/// Feature Tour mit intelligenter Kategorie-Auswahl
class FeatureTourScreen extends StatefulWidget {
  const FeatureTourScreen({super.key});

  @override
  State<FeatureTourScreen> createState() => _FeatureTourScreenState();
}

class _FeatureTourScreenState extends State<FeatureTourScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Animation Controllers
  late AnimationController _iconAnimationController;
  late AnimationController _textAnimationController;
  late Animation<double> _iconScaleAnimation;
  late Animation<double> _iconRotationAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;

  final List<FeaturePage> _pages = [
    // PAGE 1: MATERIE-KARTE mit 58 EVENTS
    FeaturePage(
      icon: Icons.public,
      title: '58 Historische Events',
      subtitle: '10.000 Jahre Geschichte',
      description:
          'Von Göbekli Tepe (9600 v.Chr.) bis zur COVID-19 Pandemie (2024) – entdecke die wichtigsten Ereignisse der Menschheitsgeschichte mit offiziellen & alternativen Perspektiven.',
      features: [
        'Timeline-Slider: ±50 Jahre Navigation',
        '25 Kategorien: UFO, Deep State, Wissenschaft...',
        '174 hochauflösende Bilder',
        '58 deutsche Dokumentationen',
        '348 wissenschaftliche Quellen',
      ],
      color: Color(0xFF1976D2),
      gradient: [Color(0xFF0D47A1), Color(0xFF1976D2), Color(0xFF42A5F5)],
      backgroundIcon: Icons.language,
    ),

    // PAGE 2: ENERGIE-KARTE mit 16 EVENTS
    FeaturePage(
      icon: Icons.bolt,
      title: '16 Energie-Orte',
      subtitle: 'Spirituelle Dimensionen',
      description:
          'Dieselben historischen Ereignisse aus energie-spiritueller Perspektive: Bewusstseins-Shifts, Frequenz-Verschiebungen & kollektive Seelen-Lektionen.',
      features: [
        'Energie-Level: 1-10 Skala',
        '11 spirituelle Kategorien',
        'Kosmische Verbindungen',
        'Bewusstseins-Analysen',
        'Dimensionale Portale',
      ],
      color: Color(0xFF7B1FA2),
      gradient: [Color(0xFF4A148C), Color(0xFF7B1FA2), Color(0xFF9C27B0)],
      backgroundIcon: Icons.energy_savings_leaf,
    ),

    // PAGE 3: FEATURES & TOOLS
    FeaturePage(
      icon: Icons.auto_awesome,
      title: 'Intelligente Features',
      subtitle: 'Personalisierte Erfahrung',
      description:
          'Die Weltenbibliothek bietet dir mächtige Tools für deine persönliche Wissens- und Bewusstseins-Reise.',
      features: [
        'Favoriten & Bookmarks',
        'Tägliche Spirit-Übungen',
        'Synchronizitäten tracken',
        'Spirit-Journal mit Mood-Tracking',
        'Layer-Switcher: 4 Kartenansichten',
      ],
      color: Color(0xFFFF6F00),
      gradient: [Color(0xFFE65100), Color(0xFFFF6F00), Color(0xFFFFA726)],
      backgroundIcon: Icons.stars,
    ),

    // PAGE 4: KATEGORIE-AUSWAHL (Intelligente Personalisierung)
    FeaturePage(
      icon: Icons.explore,
      title: 'Was interessiert dich?',
      subtitle: 'Wähle deine Startseite',
      description:
          'Starte mit dem Bereich, der dich am meisten fasziniert. Du kannst später jederzeit zwischen den Kategorien wechseln.',
      features: [], // Wird durch Kategorie-Auswahl ersetzt
      color: Color(0xFF00897B),
      gradient: [Color(0xFF00695C), Color(0xFF00897B), Color(0xFF26A69A)],
      backgroundIcon: Icons.category,
      isSelectionPage: true,
    ),
  ];

  @override
  void initState() {
    super.initState();

    // Icon-Animation
    _iconAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _iconScaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(
        parent: _iconAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _iconRotationAnimation = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(
        parent: _iconAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Text-Animation
    _textAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textAnimationController,
        curve: Curves.easeOut,
      ),
    );

    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _textAnimationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _iconAnimationController.dispose();
    _textAnimationController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
      _textAnimationController.reset();
      _textAnimationController.forward();
    } else {
      // Letzte Seite: Warten auf Kategorie-Auswahl
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
      _textAnimationController.reset();
      _textAnimationController.forward();
    }
  }

  Future<void> _skipTour() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Future<void> _finishTourWithCategory(String category) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    await prefs.setString('preferred_start_category', category);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        FadePageRoute(
          page: const SetupWizardScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated Background Gradient
          AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              double page = 0.0;
              if (_pageController.hasClients) {
                page = _pageController.page ?? 0.0;
              }

              return Container(
                decoration: BoxDecoration(
                  gradient: _getInterpolatedGradient(page),
                ),
              );
            },
          ),

          // PageView
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
              _textAnimationController.reset();
              _textAnimationController.forward();
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return _buildPage(_pages[index], index);
            },
          ),

          // Skip button (nur auf ersten 3 Seiten)
          if (_currentPage < _pages.length - 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: TextButton(
                onPressed: _skipTour,
                child: const Text(
                  'ÜBERSPRINGEN',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          // Bottom controls (nur auf ersten 3 Seiten)
          if (_currentPage < _pages.length - 1)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  // Page indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => _buildPageIndicator(index),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Navigation buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Row(
                      children: [
                        // Back button
                        if (_currentPage > 0)
                          IconButton(
                            onPressed: _previousPage,
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white70,
                              size: 28,
                            ),
                          )
                        else
                          const SizedBox(width: 48),

                        const Spacer(),

                        // Next button
                        ElevatedButton(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: _pages[_currentPage].color,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            elevation: 8,
                            shadowColor:
                                Colors.black.withValues(alpha: 0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _currentPage == _pages.length - 2
                                    ? 'STARTEN'
                                    : 'WEITER',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                _currentPage == _pages.length - 2
                                    ? Icons.rocket_launch
                                    : Icons.arrow_forward,
                                size: 24,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPage(FeaturePage page, int index) {
    // Spezialbehandlung für Auswahl-Seite
    if (page.isSelectionPage) {
      return _buildSelectionPage(page);
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          children: [
            const SizedBox(height: 80),

            // Animiertes Icon mit Hintergrund
            AnimatedBuilder(
              animation: _iconAnimationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _iconScaleAnimation.value,
                  child: Transform.rotate(
                    angle: _iconRotationAnimation.value,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background Icon (semi-transparent, größer)
                        Icon(
                          page.backgroundIcon,
                          size: 200,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),

                        // Main Icon Container
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: page.color.withValues(alpha: 0.4),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: Icon(
                            page.icon,
                            size: 70,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 40),

            // Title mit Fade & Slide Animation
            FadeTransition(
              opacity: _textFadeAnimation,
              child: SlideTransition(
                position: _textSlideAnimation,
                child: Column(
                  children: [
                    Text(
                      page.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      page.subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.8),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Description
            FadeTransition(
              opacity: _textFadeAnimation,
              child: Text(
                page.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.9),
                  height: 1.6,
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Feature Liste mit Icons
            Expanded(
              child: SingleChildScrollView(
                child: FadeTransition(
                  opacity: _textFadeAnimation,
                  child: Column(
                    children: page.features.asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildFeatureItem(
                          entry.value,
                          _getFeatureIcon(entry.key),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionPage(FeaturePage page) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const SizedBox(height: 40),

            // Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                page.icon,
                size: 50,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 32),

            // Title
            Text(
              page.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.3,
              ),
            ),

            const SizedBox(height: 12),

            // Subtitle
            Text(
              page.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),

            const SizedBox(height: 16),

            // Description
            Text(
              page.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),

            const SizedBox(height: 40),

            // Kategorie-Auswahl Buttons
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  _buildCategoryCard(
                    icon: Icons.public,
                    title: 'Materie-Karte',
                    subtitle: '58 Events',
                    color: const Color(0xFF1976D2),
                    onTap: () => _finishTourWithCategory('materie'),
                  ),
                  _buildCategoryCard(
                    icon: Icons.bolt,
                    title: 'Energie-Karte',
                    subtitle: '16 Orte',
                    color: const Color(0xFF7B1FA2),
                    onTap: () => _finishTourWithCategory('energie'),
                  ),
                  _buildCategoryCard(
                    icon: Icons.self_improvement,
                    title: 'Spirit-Dashboard',
                    subtitle: 'Übungen & Journal',
                    color: const Color(0xFFFF6F00),
                    onTap: () => _finishTourWithCategory('spirit'),
                  ),
                  _buildCategoryCard(
                    icon: Icons.explore,
                    title: 'Alles erkunden',
                    subtitle: 'Freie Wahl',
                    color: const Color(0xFF00897B),
                    onTap: () => _finishTourWithCategory('all'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color,
              color.withValues(alpha: 0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFeatureIcon(int index) {
    const icons = [
      Icons.timeline,
      Icons.category,
      Icons.image,
      Icons.video_library,
      Icons.library_books,
    ];
    return icons[index % icons.length];
  }

  Widget _buildPageIndicator(int index) {
    final isActive = index == _currentPage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 32 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(4),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.5),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
    );
  }

  LinearGradient _getInterpolatedGradient(double page) {
    final int currentIndex = page.floor();
    final int nextIndex = (currentIndex + 1).clamp(0, _pages.length - 1);
    final double progress = page - currentIndex;

    final currentGradient = _pages[currentIndex].gradient;
    final nextGradient = _pages[nextIndex].gradient;

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.lerp(currentGradient[0], nextGradient[0], progress)!,
        Color.lerp(currentGradient[1], nextGradient[1], progress)!,
        Color.lerp(currentGradient[2], nextGradient[2], progress)!,
      ],
    );
  }
}

/// Feature page data model
class FeaturePage {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final List<String> features;
  final Color color;
  final List<Color> gradient;
  final IconData backgroundIcon;
  final bool isSelectionPage;

  FeaturePage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.features,
    required this.color,
    required this.gradient,
    required this.backgroundIcon,
    this.isSelectionPage = false,
  });
}

/// Custom Fade Page Route
class FadePageRoute extends PageRouteBuilder {
  final Widget page;

  FadePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 600),
        );
}
