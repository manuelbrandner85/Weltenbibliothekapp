import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Generic 3-slide onboarding screen for new worlds.
///
/// Shown **once** per world on first entry. Stores a flag in
/// SharedPreferences keyed by `onboarding_completed_<world>` so the user
/// only sees it once.
///
/// Used for Vorhang and Ursprung (the two new worlds in v6.0).
class WorldOnboardingScreen extends StatefulWidget {
  final String world; // 'vorhang' | 'ursprung'
  final List<_OnboardingSlide> slides;
  final Color accent;
  final Color accentLight;
  final Color background;
  final VoidCallback onComplete;

  const WorldOnboardingScreen._({
    required this.world,
    required this.slides,
    required this.accent,
    required this.accentLight,
    required this.background,
    required this.onComplete,
  });

  /// Vorhang-Welt — Machtpsychologie / Manipulation / Strategie / Schatten
  factory WorldOnboardingScreen.vorhang({required VoidCallback onComplete}) {
    return WorldOnboardingScreen._(
      world: 'vorhang',
      onComplete: onComplete,
      accent: const Color(0xFFC9A84C),
      accentLight: const Color(0xFFE0C872),
      background: const Color(0xFF0F0A02),
      slides: const [
        _OnboardingSlide(
          icon: Icons.theater_comedy_outlined,
          title: 'Willkommen hinter dem Vorhang',
          body: 'Hier lernst du die Psychologie der Macht — '
              'nicht um zu manipulieren, sondern um dich zu schützen.',
        ),
        _OnboardingSlide(
          icon: Icons.account_tree_outlined,
          title: '30 Module in 6 Branches',
          body: 'Von Robert Greene bis C.G. Jung — das vollständige '
              'Studium der menschlichen Natur.',
        ),
        _OnboardingSlide(
          icon: Icons.psychology_outlined,
          title: 'Dein Mentor: Der Stratege',
          body: 'Ein eiskalt-analytischer Berater steht dir zur Seite.',
        ),
      ],
    );
  }

  /// Ursprung-Welt — Gateway / Quantum / Remote Viewing
  factory WorldOnboardingScreen.ursprung({required VoidCallback onComplete}) {
    return WorldOnboardingScreen._(
      world: 'ursprung',
      onComplete: onComplete,
      accent: const Color(0xFF00D4AA),
      accentLight: const Color(0xFF40E8C0),
      background: const Color(0xFF050510),
      slides: const [
        _OnboardingSlide(
          icon: Icons.auto_awesome,
          title: 'Willkommen am Ursprung',
          body: 'Basierend auf deklassifizierten CIA-Dokumenten: Lerne die '
              'Techniken, die das US-Militär über 20 Jahre erforscht hat.',
        ),
        _OnboardingSlide(
          icon: Icons.science_outlined,
          title: '25 Module + 5 interaktive Tools',
          body: 'Gateway Process, Focus Levels, Remote Viewing, Manifestation '
              '— von der Theorie direkt in die Praxis.',
        ),
        _OnboardingSlide(
          icon: Icons.all_inclusive,
          title: 'Dein Mentor: Der Alchemist',
          body: 'Ein mystischer Bewusstseinsexperte verbindet altes Wissen '
              'mit moderner Wissenschaft.',
        ),
      ],
    );
  }

  static String _prefsKey(String world) => 'onboarding_completed_$world';

  /// Returns true if the onboarding for the given world has already been completed.
  static Future<bool> isCompleted(String world) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKey(world)) ?? false;
  }

  /// Marks onboarding as completed for the given world.
  static Future<void> markCompleted(String world) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey(world), true);
  }

  @override
  State<WorldOnboardingScreen> createState() => _WorldOnboardingScreenState();
}

class _OnboardingSlide {
  final IconData icon;
  final String title;
  final String body;

  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.body,
  });
}

class _WorldOnboardingScreenState extends State<WorldOnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _controller = PageController();
  int _page = 0;
  late final AnimationController _glow;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _glow.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < widget.slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await WorldOnboardingScreen.markCompleted(widget.world);
    if (!mounted) return;
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Background glow
            AnimatedBuilder(
              animation: _glow,
              builder: (_, __) => Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topCenter,
                      radius: 1.5,
                      colors: [
                        widget.accent.withValues(
                          alpha: 0.15 + _glow.value * 0.08,
                        ),
                        widget.background,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Column(
              children: [
                // Skip button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextButton(
                      onPressed: _finish,
                      child: Text(
                        'Überspringen',
                        style: TextStyle(
                          color: widget.accentLight.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                ),
                // Slides
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: widget.slides.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (_, i) => _buildSlide(widget.slides[i]),
                  ),
                ),
                // Page indicator
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(widget.slides.length, (i) {
                      final active = i == _page;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active
                              ? widget.accent
                              : widget.accent.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ),
                // Next/Start button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.accent,
                        foregroundColor: Colors.black,
                        elevation: 8,
                        shadowColor: widget.accent.withValues(alpha: 0.6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      child: Text(
                        _page < widget.slides.length - 1
                            ? 'Weiter'
                            : "Los geht's",
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(_OnboardingSlide slide) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with glow
          AnimatedBuilder(
            animation: _glow,
            builder: (_, __) => Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    widget.accent.withValues(alpha: 0.4 + _glow.value * 0.2),
                    widget.accent.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Center(
                child: Icon(
                  slide.icon,
                  size: 64,
                  color: widget.accentLight,
                ),
              ),
            ),
          ),
          const SizedBox(height: 48),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: widget.accentLight,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            slide.body,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 16,
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
