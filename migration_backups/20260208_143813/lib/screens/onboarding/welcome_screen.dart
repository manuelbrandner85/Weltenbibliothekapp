/// Welcome & Onboarding Screens
/// First-time user experience for Weltenbibliothek
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/app_animations.dart';
import '../../config/enhanced_app_themes.dart';
import '../../utils/responsive_helper.dart';
import 'feature_tour_screen.dart';

/// Welcome Screen - First screen for new users
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startTour() async {
    Navigator.pushReplacement(
      context,
      AppPageTransitions.slideFromRight(const FeatureTourScreen()),
    );
  }

  Future<void> _skipOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    if (mounted) {
      // Navigate to main app (will be handled by main.dart)
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              EnhancedAppThemes.darkBackground,
              const Color(0xFF0F0F1E),
              EnhancedAppThemes.energiePrimary.withValues(alpha: 0.3),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton(
                    onPressed: _skipOnboarding,
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
              ),

              const Spacer(),

              // Main content
              FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo/Icon
                      Container(
                        width: context.responsive(mobile: 120, tablet: 150, desktop: 180),
                        height: context.responsive(mobile: 120, tablet: 150, desktop: 180),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              EnhancedAppThemes.energiePrimary,
                              EnhancedAppThemes.energieSecondary,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: EnhancedAppThemes.energiePrimary.withValues(alpha: 0.5),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.auto_stories,
                          size: context.responsive(mobile: 60, tablet: 75, desktop: 90),
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // App name
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            EnhancedAppThemes.energiePrimary,
                            EnhancedAppThemes.energieSecondary,
                          ],
                        ).createShader(bounds),
                        child: Text(
                          'Weltenbibliothek',
                          style: TextStyle(
                            fontSize: context.responsive(mobile: 36, tablet: 44, desktop: 52),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Tagline
                      const Text(
                        '10.000 Jahre Wissen',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.5,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Sub-tagline
                      Text(
                        '58 Events • 16 Energie-Orte • 348 Quellen',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.6),
                          letterSpacing: 0.5,
                        ),
                      ),

                      const SizedBox(height: 60),

                      // Features preview
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          children: [
                            _buildGlassFeatureCard(
                              icon: Icons.public,
                              iconColor: const Color(0xFF1976D2),
                              text: '58 historische Events',
                              subtitle: 'Materie-Karte: 9600 v.Chr. – 2024',
                            ),
                            const SizedBox(height: 12),
                            _buildGlassFeatureCard(
                              icon: Icons.bolt,
                              iconColor: const Color(0xFF7B1FA2),
                              text: '16 Energie-Orte',
                              subtitle: 'Spirituelle Dimensionen',
                            ),
                            const SizedBox(height: 12),
                            _buildGlassFeatureCard(
                              icon: Icons.timeline,
                              iconColor: const Color(0xFFFF6F00),
                              text: 'Timeline & Filter',
                              subtitle: '±50 Jahre, 25 Kategorien',
                            ),
                            const SizedBox(height: 12),
                            _buildGlassFeatureCard(
                              icon: Icons.stars,
                              iconColor: const Color(0xFF00897B),
                              text: 'Intelligente Features',
                              subtitle: 'Favoriten, Journal, Synchronizitäten',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // CTA Button
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.responsive(mobile: 40, tablet: 80, desktop: 120),
                      vertical: context.responsive(mobile: 40, tablet: 50, desktop: 60),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: context.responsive(mobile: 56, tablet: 64, desktop: 72),
                      child: ElevatedButton(
                        onPressed: _startTour,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: EnhancedAppThemes.energiePrimary,
                          foregroundColor: Colors.white,
                          elevation: 8,
                          shadowColor: EnhancedAppThemes.energiePrimary.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'JETZT STARTEN',
                              style: TextStyle(
                                fontSize: context.responsive(mobile: 18, tablet: 20, desktop: 22),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.arrow_forward, size: context.responsive(mobile: 24, tablet: 28, desktop: 32)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassFeatureCard({
    required IconData icon,
    required Color iconColor,
    required String text,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        // Glassmorphism effect
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon with gradient background
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  iconColor.withValues(alpha: 0.8),
                  iconColor.withValues(alpha: 0.5),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Arrow indicator
          Icon(
            Icons.arrow_forward_ios,
            color: Colors.white.withValues(alpha: 0.5),
            size: 18,
          ),
        ],
      ),
    );
  }
}
