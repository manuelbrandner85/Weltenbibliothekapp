import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

/// Tutorial Overlay für ersten App-Start (v5.38 - VOLLSTÄNDIG)
class TutorialOverlay extends StatefulWidget {
  final VoidCallback onComplete;
  
  const TutorialOverlay({super.key, required this.onComplete});
  
  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  final List<TutorialStep> _steps = [
    TutorialStep(
      title: '🌀 Das Portal zwischen den Welten',
      description: 'Dieses mystische Portal verbindet zwei Realitäten.\n\n'
          'Es dreht sich kontinuierlich und zieht dich in seine Tiefen.\n\n'
          '💫 Tippe 10x auf das Portal für ein Geheimnis!',
      icon: Icons.auto_awesome,
      iconColor: Color(0xFFFFD700),
      backgroundColor: Color(0xFF1A237E),
    ),
    TutorialStep(
      title: '🔵 MATERIE - Die physische Welt',
      description: 'Forschung · Fakten · Geopolitik · Systeme\n\n'
          'Erforsche die materielle Realität mit wissenschaftlichen Methoden.\n\n'
          '🔬 Recherche-System mit 3 Modi\n'
          '📊 Kaninchenbau (6 Ebenen)\n'
          '🌍 Internationale Perspektiven',
      icon: Icons.public,
      iconColor: Color(0xFF2196F3),
      backgroundColor: Color(0xFF0D47A1),
    ),
    TutorialStep(
      title: '🟣 ENERGIE - Die spirituelle Dimension',
      description: 'Spirit · Bewusstsein · Archetypen · Symbolik\n\n'
          'Entdecke die energetische Ebene des Seins.\n\n'
          '✨ Archetypen-Rechner\n'
          '🎴 Tarot-System\n'
          '🔮 Mystische Symbole',
      icon: Icons.self_improvement,
      iconColor: Color(0xFF9C27B0),
      backgroundColor: Color(0xFF4A148C),
    ),
    TutorialStep(
      title: '✨ Interaktive Features!',
      description: 'Entdecke die versteckten Features:\n\n'
          '👆 Touch: Partikel weichen deinem Finger aus\n'
          '📱 Neige dein Handy: Portal folgt (Gyroscope)\n'
          '⭐ Sterne: 100 twinkelnde Sterne im Hintergrund\n'
          '⚡ Energie-Strahlen vom Portal zu den Buttons\n'
          '🎨 Adaptive Farben: Ändern sich mit der Tageszeit',
      icon: Icons.touch_app,
      iconColor: Color(0xFF00E5FF),
      backgroundColor: Color(0xFF006064),
    ),
  ];
  
  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutBack),
    );
    _fadeController.forward();
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }
  
  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      _fadeController.reverse().then((_) {
        if (mounted) {
          setState(() => _currentStep++);
          _fadeController.forward();
        }
      });
    } else {
      widget.onComplete();
    }
  }
  
  void _previousStep() {
    if (_currentStep > 0) {
      _fadeController.reverse().then((_) {
        if (mounted) {
          setState(() => _currentStep--);
          _fadeController.forward();
        }
      });
    }
  }
  
  void _skip() {
    widget.onComplete();
  }
  
  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];
    
    return Material(
      color: Colors.black.withValues(alpha: 0.92),
      child: SafeArea(
        child: Stack(
          children: [
            // Animated Background Gradient
            AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.0,
                  colors: [
                    step.backgroundColor.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
            
            // Skip Button
            Positioned(
              top: 20,
              right: 20,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _skip,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Überspringen',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.skip_next, color: Colors.white.withValues(alpha: 0.9), size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Content
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Animated Icon
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.elasticOut,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      step.iconColor.withValues(alpha: 0.4),
                                      step.backgroundColor.withValues(alpha: 0.2),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: step.iconColor.withValues(alpha: 0.5),
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: step.iconColor.withValues(alpha: 0.5),
                                      blurRadius: 30,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  step.icon,
                                  size: 60,
                                  color: step.iconColor,
                                ),
                              ),
                            );
                          },
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // Title with Gradient
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              step.iconColor,
                              step.iconColor.withValues(alpha: 0.7),
                            ],
                          ).createShader(bounds),
                          child: Text(
                            step.title,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Description
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            step.description,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.white,
                              height: 1.6,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        
                        const SizedBox(height: 60),
                        
                        // Navigation Section
                        Column(
                          children: [
                            // Progress Dots
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                _steps.length,
                                (index) {
                                  final isActive = index == _currentStep;
                                  final isCompleted = index < _currentStep;
                                  
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    width: isActive ? 32 : 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: isCompleted
                                          ? step.iconColor
                                          : isActive
                                              ? step.iconColor
                                              : Colors.white.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(5),
                                      boxShadow: isActive
                                          ? [
                                              BoxShadow(
                                                color: step.iconColor.withValues(alpha: 0.5),
                                                blurRadius: 10,
                                                spreadRadius: 2,
                                              ),
                                            ]
                                          : [],
                                    ),
                                  );
                                },
                              ),
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // Navigation Buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Back Button
                                if (_currentStep > 0)
                                  _buildNavButton(
                                    'Zurück',
                                    Icons.arrow_back,
                                    _previousStep,
                                    isPrimary: false,
                                  ),
                                
                                if (_currentStep > 0) const SizedBox(width: 16),
                                
                                // Next/Finish Button
                                _buildNavButton(
                                  _currentStep < _steps.length - 1 ? 'Weiter' : 'Los geht\'s!',
                                  _currentStep < _steps.length - 1 ? Icons.arrow_forward : Icons.check_circle,
                                  _nextStep,
                                  isPrimary: true,
                                  color: step.iconColor,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
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
  
  Widget _buildNavButton(String label, IconData icon, VoidCallback onPressed, {bool isPrimary = false, Color? color}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          decoration: BoxDecoration(
            gradient: isPrimary
                ? LinearGradient(
                    colors: [
                      color ?? const Color(0xFF64B5F6),
                      (color ?? const Color(0xFF64B5F6)).withValues(alpha: 0.7),
                    ],
                  )
                : null,
            color: isPrimary ? null : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isPrimary
                  ? Colors.transparent
                  : Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: (color ?? const Color(0xFF64B5F6)).withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isPrimary) Icon(icon, color: Colors.white, size: 20),
              if (!isPrimary) const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              if (isPrimary) const SizedBox(width: 8),
              if (isPrimary) Icon(icon, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class TutorialStep {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  
  TutorialStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
  });
}

/// Check if tutorial should be shown (first launch)
Future<bool> shouldShowTutorial() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final tutorialShown = prefs.getBool('tutorial_shown') ?? false;
    debugPrint('🎓 Tutorial bereits gezeigt: $tutorialShown');
    return !tutorialShown; // Zeige Tutorial nur beim ersten Start
  } catch (e) {
    debugPrint('❌ Fehler beim Tutorial-Check: $e');
    return false;
  }
}

/// Helper to mark tutorial as shown
Future<void> markTutorialAsShown() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_shown', true);
    debugPrint('✅ Tutorial als abgeschlossen markiert');
  } catch (e) {
    debugPrint('❌ Fehler beim Tutorial-Flag speichern: $e');
  }
}
