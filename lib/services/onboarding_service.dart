/// 🎓 WELTENBIBLIOTHEK - ONBOARDING SERVICE
/// Manages onboarding tutorial state and progress

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Onboarding Step
class OnboardingStep {
  final String id;
  final String title;
  final String description;
  final String? iconData;
  final String? targetWidget;
  
  OnboardingStep({
    required this.id,
    required this.title,
    required this.description,
    this.iconData,
    this.targetWidget,
  });
}

/// Onboarding Service
class OnboardingService extends ChangeNotifier {
  static final OnboardingService _instance = OnboardingService._internal();
  factory OnboardingService() => _instance;
  OnboardingService._internal();

  static const String _completedKey = 'onboarding_completed';
  static const String _currentStepKey = 'onboarding_current_step';
  static const String _skippedKey = 'onboarding_skipped';

  bool _isCompleted = false;
  bool _isSkipped = false;
  int _currentStep = 0;
  
  bool get isCompleted => _isCompleted;
  bool get isSkipped => _isSkipped;
  int get currentStep => _currentStep;
  bool get shouldShowOnboarding => !_isCompleted && !_isSkipped;

  /// Onboarding Steps
  final List<OnboardingStep> steps = [
    OnboardingStep(
      id: 'welcome',
      title: 'Willkommen zur Weltenbibliothek!',
      description: 'Entdecke Wissen aus zwei Welten: Materie (Fakten, Geschichte, Politik) und Energie (Spiritualität, Bewusstsein, Meditation).',
      iconData: '🌟',
    ),
    OnboardingStep(
      id: 'two_worlds',
      title: 'Zwei Welten erkunden',
      description: 'Wähle zwischen Materie-Welt (🔵 Blau) für wissenschaftliches Wissen oder Energie-Welt (🟣 Lila) für spirituelle Inhalte.',
      iconData: '🌍',
      targetWidget: 'world_buttons',
    ),
    OnboardingStep(
      id: 'chat',
      title: 'Live-Chat Community',
      description: 'Tausche dich mit anderen aus! Nutze die Chat-Räume, um Fragen zu stellen, zu diskutieren und neue Perspektiven zu entdecken.',
      iconData: '💬',
      targetWidget: 'chat_button',
    ),
    OnboardingStep(
      id: 'voice_chat',
      title: 'Voice Chat & Screen Sharing',
      description: 'Sprich direkt mit anderen Nutzern! Voice Chat für echte Gespräche und Screen Sharing für Präsentationen.',
      iconData: '🎙️',
      targetWidget: 'voice_chat',
    ),
    OnboardingStep(
      id: 'profile',
      title: 'Erstelle dein Profil',
      description: 'Erstelle Profile für beide Welten! Speichere deine Favoriten, tracke deinen Fortschritt und werde Teil der Community.',
      iconData: '👤',
      targetWidget: 'profile_button',
    ),
  ];

  /// Initialize service
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isCompleted = prefs.getBool(_completedKey) ?? false;
      _isSkipped = prefs.getBool(_skippedKey) ?? false;
      _currentStep = prefs.getInt(_currentStepKey) ?? 0;
      
      if (kDebugMode) {
        print('✅ Onboarding: Initialized');
        print('   Completed: $_isCompleted, Skipped: $_isSkipped, Step: $_currentStep');
      }
      
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Onboarding: Initialization failed - $e');
      }
    }
  }

  /// Move to next step
  Future<void> nextStep() async {
    if (_currentStep < steps.length - 1) {
      _currentStep++;
      await _saveCurrentStep();
      notifyListeners();
    } else {
      await complete();
    }
  }

  /// Move to previous step
  Future<void> previousStep() async {
    if (_currentStep > 0) {
      _currentStep--;
      await _saveCurrentStep();
      notifyListeners();
    }
  }

  /// Skip onboarding
  Future<void> skip() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_skippedKey, true);
      _isSkipped = true;
      
      if (kDebugMode) {
        print('⏭️ Onboarding: Skipped');
      }
      
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Onboarding: Skip failed - $e');
      }
    }
  }

  /// Complete onboarding
  Future<void> complete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_completedKey, true);
      _isCompleted = true;
      
      if (kDebugMode) {
        print('✅ Onboarding: Completed');
      }
      
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Onboarding: Complete failed - $e');
      }
    }
  }

  /// Reset onboarding (for testing)
  Future<void> reset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_completedKey);
      await prefs.remove(_skippedKey);
      await prefs.remove(_currentStepKey);
      
      _isCompleted = false;
      _isSkipped = false;
      _currentStep = 0;
      
      if (kDebugMode) {
        print('🔄 Onboarding: Reset');
      }
      
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Onboarding: Reset failed - $e');
      }
    }
  }

  /// Save current step
  Future<void> _saveCurrentStep() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_currentStepKey, _currentStep);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Onboarding: Save step failed - $e');
      }
    }
  }

  /// Get current step data
  OnboardingStep get currentStepData => steps[_currentStep];

  /// Get progress percentage
  double get progress => (_currentStep + 1) / steps.length;
}
