/// 📳 HAPTIC FEEDBACK SERVICE
/// Production-ready taktiles Feedback-System
library;

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Haptic Feedback Service für taktiles Feedback
/// 
/// Features:
/// - Light, Medium, Heavy Feedback Intensitäten
/// - Erfolgs/Fehler/Warnung Feedback-Patterns
/// - Settings Toggle (An/Aus in Einstellungen)
/// - Button, Swipe, Notification Feedback
class HapticFeedbackService {
  static final HapticFeedbackService _instance = HapticFeedbackService._internal();
  factory HapticFeedbackService() => _instance;
  HapticFeedbackService._internal();

  static const String _enabledKey = 'haptic_feedback_enabled';
  bool _isEnabled = true;

  /// Initialize service und lade Settings
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isEnabled = prefs.getBool(_enabledKey) ?? true;
      print('🔄 HapticFeedbackService initialized: enabled=$_isEnabled');
    } catch (e) {
      print('❌ HapticFeedbackService initialization failed: $e');
      _isEnabled = true; // Default: enabled
    }
  }

  /// Haptic Feedback aktivieren/deaktivieren
  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledKey, enabled);
      print('✅ Haptic Feedback: ${enabled ? "aktiviert" : "deaktiviert"}');
    } catch (e) {
      print('❌ Failed to save haptic setting: $e');
    }
  }

  /// Check if haptic feedback is enabled
  bool get isEnabled => _isEnabled;

  // ==========================================
  // BASIC FEEDBACK TYPES
  // ==========================================

  /// Light Impact - für subtile Interaktionen
  /// Verwendung: Hover, kleine Buttons, Toggles
  Future<void> light() async {
    if (!_isEnabled) return;
    try {
      await HapticFeedback.lightImpact();
    } catch (e) {
      print('❌ Haptic light failed: $e');
    }
  }

  /// Medium Impact - für Standard-Interaktionen
  /// Verwendung: Standard Buttons, Swipes, Selections
  Future<void> medium() async {
    if (!_isEnabled) return;
    try {
      await HapticFeedback.mediumImpact();
    } catch (e) {
      print('❌ Haptic medium failed: $e');
    }
  }

  /// Heavy Impact - für wichtige Aktionen
  /// Verwendung: Delete, Submit, Wichtige Bestätigungen
  Future<void> heavy() async {
    if (!_isEnabled) return;
    try {
      await HapticFeedback.heavyImpact();
    } catch (e) {
      print('❌ Haptic heavy failed: $e');
    }
  }

  /// Selection Changed - für Picker/Slider
  /// Verwendung: Scrollbare Listen, Picker, Slider
  Future<void> selection() async {
    if (!_isEnabled) return;
    try {
      await HapticFeedback.selectionClick();
    } catch (e) {
      print('❌ Haptic selection failed: $e');
    }
  }

  /// Vibrate Pattern - für Custom Vibration
  /// Verwendung: Notifications, Alarms, Custom Patterns
  Future<void> vibrate() async {
    if (!_isEnabled) return;
    try {
      await HapticFeedback.vibrate();
    } catch (e) {
      print('❌ Haptic vibrate failed: $e');
    }
  }

  // ==========================================
  // CONTEXT-SPECIFIC FEEDBACK
  // ==========================================

  /// Button Tap Feedback
  /// Verwendung: Bei Button-Taps
  Future<void> buttonTap() async {
    await light();
  }

  /// Important Button Feedback (z.B. Submit, Delete)
  Future<void> importantButtonTap() async {
    await medium();
  }

  /// Critical Action Feedback (z.B. Delete Account)
  Future<void> criticalAction() async {
    await heavy();
  }

  /// Swipe Gesture Feedback
  /// Verwendung: PageView Swipes, Dismissible
  Future<void> swipe() async {
    await light();
  }

  /// Toggle Switch Feedback
  Future<void> toggle() async {
    await light();
  }

  /// Success Feedback Pattern
  /// Verwendung: Erfolgreiche Aktionen (Save, Upload, Login)
  Future<void> success() async {
    if (!_isEnabled) return;
    await medium();
    await Future.delayed(const Duration(milliseconds: 100));
    await light();
  }

  /// Error Feedback Pattern
  /// Verwendung: Fehler, Validation Errors
  Future<void> error() async {
    if (!_isEnabled) return;
    await heavy();
    await Future.delayed(const Duration(milliseconds: 80));
    await heavy();
  }

  /// Warning Feedback Pattern
  /// Verwendung: Warnungen, Wichtige Hinweise
  Future<void> warning() async {
    if (!_isEnabled) return;
    await medium();
    await Future.delayed(const Duration(milliseconds: 100));
    await medium();
  }

  /// Notification Received Feedback
  /// Verwendung: Push Notifications, Chat Messages
  Future<void> notification() async {
    if (!_isEnabled) return;
    await vibrate();
  }

  /// Long Press Start Feedback
  /// Verwendung: Long Press Interaktionen
  Future<void> longPressStart() async {
    await medium();
  }

  /// Long Press End Feedback
  Future<void> longPressEnd() async {
    await light();
  }

  /// Pull-to-Refresh Feedback
  /// Verwendung: Refresh Trigger
  Future<void> refresh() async {
    await medium();
  }

  /// Page Transition Feedback
  /// Verwendung: Navigation zwischen Screens
  Future<void> pageTransition() async {
    await light();
  }

  /// Modal Open Feedback
  Future<void> modalOpen() async {
    await light();
  }

  /// Modal Close Feedback
  Future<void> modalClose() async {
    await light();
  }

  /// Achievement Unlocked Feedback
  /// Verwendung: Gamification, Erfolge
  Future<void> achievementUnlocked() async {
    if (!_isEnabled) return;
    await medium();
    await Future.delayed(const Duration(milliseconds: 150));
    await light();
    await Future.delayed(const Duration(milliseconds: 150));
    await light();
  }

  /// Voice Chat Join Feedback
  Future<void> voiceChatJoin() async {
    await success();
  }

  /// Voice Chat Leave Feedback
  Future<void> voiceChatLeave() async {
    await medium();
  }

  /// Message Sent Feedback
  Future<void> messageSent() async {
    await light();
  }

  /// Message Received Feedback
  Future<void> messageReceived() async {
    await light();
  }
}
