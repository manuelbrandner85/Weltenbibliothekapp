/// 🎵 VOICE FEEDBACK SERVICE
/// Provides haptic and audio feedback for voice interactions
library;

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class VoiceFeedbackService {
  // Singleton
  static final VoiceFeedbackService _instance = VoiceFeedbackService._internal();
  factory VoiceFeedbackService() => _instance;
  VoiceFeedbackService._internal();

  /// 🎤 Mic On Feedback
  Future<void> micOn() async {
    try {
      await HapticFeedback.mediumImpact();
      if (kDebugMode) {
        debugPrint('🎤 [VoiceFeedback] Mic ON');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [VoiceFeedback] Error: $e');
      }
    }
  }

  /// 🔇 Mic Off Feedback
  Future<void> micOff() async {
    try {
      await HapticFeedback.lightImpact();
      if (kDebugMode) {
        debugPrint('🔇 [VoiceFeedback] Mic OFF');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [VoiceFeedback] Error: $e');
      }
    }
  }

  /// 👤 User Joined Feedback
  Future<void> userJoined() async {
    try {
      await HapticFeedback.selectionClick();
      if (kDebugMode) {
        debugPrint('👤 [VoiceFeedback] User joined');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [VoiceFeedback] Error: $e');
      }
    }
  }

  /// 🚪 User Left Feedback
  Future<void> userLeft() async {
    try {
      await HapticFeedback.selectionClick();
      if (kDebugMode) {
        debugPrint('🚪 [VoiceFeedback] User left');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [VoiceFeedback] Error: $e');
      }
    }
  }

  /// 🗣️ Speaking Started Feedback
  Future<void> speakingStarted() async {
    try {
      await HapticFeedback.lightImpact();
      if (kDebugMode) {
        debugPrint('🗣️ [VoiceFeedback] Speaking started');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [VoiceFeedback] Error: $e');
      }
    }
  }

  /// 🤐 Speaking Stopped Feedback
  Future<void> speakingStopped() async {
    try {
      await HapticFeedback.lightImpact();
      if (kDebugMode) {
        debugPrint('🤐 [VoiceFeedback] Speaking stopped');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [VoiceFeedback] Error: $e');
      }
    }
  }

  /// ✋ Hand Raised Feedback
  Future<void> handRaised() async {
    try {
      await HapticFeedback.mediumImpact();
      if (kDebugMode) {
        debugPrint('✋ [VoiceFeedback] Hand raised');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [VoiceFeedback] Error: $e');
      }
    }
  }

  /// ❌ Error Feedback
  Future<void> error() async {
    try {
      await HapticFeedback.heavyImpact();
      if (kDebugMode) {
        debugPrint('❌ [VoiceFeedback] Error feedback');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [VoiceFeedback] Error: $e');
      }
    }
  }

  /// ✅ Success Feedback
  Future<void> success() async {
    try {
      await HapticFeedback.mediumImpact();
      if (kDebugMode) {
        debugPrint('✅ [VoiceFeedback] Success feedback');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [VoiceFeedback] Error: $e');
      }
    }
  }
}
