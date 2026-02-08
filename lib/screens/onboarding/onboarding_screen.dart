/// 🎓 WELTENBIBLIOTHEK - ONBOARDING SCREEN
/// Interactive 5-step tutorial for new users

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/onboarding_service.dart';
import '../../services/haptic_feedback_service.dart';
import 'dart:ui';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  
  const OnboardingScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateTransition() {
    _controller.reset();
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: OnboardingService(),
      child: Consumer<OnboardingService>(
        builder: (context, onboarding, child) {
          final step = onboarding.currentStepData;
          
          return Material(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF0A0A0A),
                    const Color(0xFF1A1A2E),
                    onboarding.currentStep.isEven 
                        ? const Color(0xFF2196F3).withValues(alpha: 0.2)
                        : const Color(0xFF9C27B0).withValues(alpha: 0.2),
                  ],
                ),
              ),
              child: SafeArea(
                child: Stack(
                  children: [
                    // Background particles
                    ...List.generate(20, (index) {
                      return Positioned(
                        left: (index * 50.0) % MediaQuery.of(context).size.width,
                        top: (index * 70.0) % MediaQuery.of(context).size.height,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      );
                    }),
                    
                    // Main content
                    Column(
                      children: [
                        // Header
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Progress indicator
                              Row(
                                children: List.generate(
                                  onboarding.steps.length,
                                  (index) => Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    width: 30,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: index <= onboarding.currentStep
                                          ? Colors.white
                                          : Colors.white.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ),
                              
                              // Skip button
                              TextButton(
                                onPressed: () async {
                                  await HapticFeedbackService().light();
                                  await onboarding.skip();
                                  widget.onComplete();
                                },
                                child: const Text(
                                  'Überspringen',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Content
                        Expanded(
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 32),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Icon
                                    Text(
                                      step.iconData ?? '🌟',
                                      style: const TextStyle(fontSize: 80),
                                    ),
                                    
                                    const SizedBox(height: 40),
                                    
                                    // Title
                                    Text(
                                      step.title,
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    
                                    const SizedBox(height: 20),
                                    
                                    // Description
                                    Text(
                                      step.description,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white.withValues(alpha: 0.8),
                                        height: 1.6,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    
                                    const SizedBox(height: 60),
                                    
                                    // Step counter
                                    Text(
                                      '${onboarding.currentStep + 1} von ${onboarding.steps.length}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white.withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        // Navigation buttons
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: Row(
                            children: [
                              // Back button
                              if (onboarding.currentStep > 0)
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () async {
                                      await HapticFeedbackService().light();
                                      await onboarding.previousStep();
                                      _animateTransition();
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      side: const BorderSide(color: Colors.white38),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      'Zurück',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              
                              if (onboarding.currentStep > 0)
                                const SizedBox(width: 16),
                              
                              // Next/Finish button
                              Expanded(
                                flex: onboarding.currentStep == 0 ? 1 : 1,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    await HapticFeedbackService().success();
                                    
                                    if (onboarding.currentStep == onboarding.steps.length - 1) {
                                      await onboarding.complete();
                                      widget.onComplete();
                                    } else {
                                      await onboarding.nextStep();
                                      _animateTransition();
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: onboarding.currentStep.isEven
                                        ? const Color(0xFF2196F3)
                                        : const Color(0xFF9C27B0),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    onboarding.currentStep == onboarding.steps.length - 1
                                        ? 'Los geht\'s!'
                                        : 'Weiter',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
