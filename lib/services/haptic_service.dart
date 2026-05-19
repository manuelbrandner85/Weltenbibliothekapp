import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// v5.40 - Haptic Service for Easter Egg Improvements
/// Provides haptic feedback for tap interactions
class HapticService {
  /// Light haptic impact for normal taps (1.2)
  static void lightImpact() {
    HapticFeedback.lightImpact();
    if (kDebugMode) {
      debugPrint('📳 Light haptic feedback');
    }
  }

  /// Heavy haptic impact for unlock/achievement (1.2)
  static void heavyImpact() {
    HapticFeedback.heavyImpact();
    if (kDebugMode) {
      debugPrint('📳 Heavy haptic feedback');
    }
  }

  /// Medium haptic for button interactions
  static void mediumImpact() {
    HapticFeedback.mediumImpact();
    if (kDebugMode) {
      debugPrint('📳 Medium haptic feedback');
    }
  }

  /// Selection click for menu navigation
  static void selectionClick() {
    HapticFeedback.selectionClick();
    if (kDebugMode) {
      debugPrint('📳 Selection click feedback');
    }
  }
}
