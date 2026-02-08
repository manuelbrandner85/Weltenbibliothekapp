/// 🎵 VOICE AUDIO EFFECTS SERVICE
/// Provides smooth audio transitions (Fade In/Out, Volume Control)
library;

import 'package:flutter/foundation.dart';
import 'dart:async';

class VoiceAudioEffectsService {
  // Singleton
  static final VoiceAudioEffectsService _instance = VoiceAudioEffectsService._internal();
  factory VoiceAudioEffectsService() => _instance;
  VoiceAudioEffectsService._internal();

  Timer? _fadeTimer;
  double _currentVolume = 1.0;

  /// 🎚️ Current Volume
  double get currentVolume => _currentVolume;

  /// 📈 Fade In Audio
  Future<void> fadeIn({
    required Function(double volume) onVolumeChange,
    Duration duration = const Duration(milliseconds: 300),
    double targetVolume = 1.0,
  }) async {
    try {
      _fadeTimer?.cancel();

      final steps = 30; // 30 steps for smooth fade
      final stepDuration = duration.inMilliseconds ~/ steps;
      final volumeStep = (targetVolume - _currentVolume) / steps;

      int currentStep = 0;

      _fadeTimer = Timer.periodic(
        Duration(milliseconds: stepDuration),
        (timer) {
          currentStep++;
          _currentVolume += volumeStep;

          // Clamp volume
          _currentVolume = _currentVolume.clamp(0.0, targetVolume);

          onVolumeChange(_currentVolume);

          if (currentStep >= steps) {
            timer.cancel();
            _currentVolume = targetVolume;
            onVolumeChange(_currentVolume);
            
            if (kDebugMode) {
              debugPrint('📈 [AudioEffects] Fade In complete: $_currentVolume');
            }
          }
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [AudioEffects] Fade In error: $e');
      }
    }
  }

  /// 📉 Fade Out Audio
  Future<void> fadeOut({
    required Function(double volume) onVolumeChange,
    Duration duration = const Duration(milliseconds: 300),
    double targetVolume = 0.0,
  }) async {
    try {
      _fadeTimer?.cancel();

      final steps = 30;
      final stepDuration = duration.inMilliseconds ~/ steps;
      final volumeStep = (_currentVolume - targetVolume) / steps;

      int currentStep = 0;

      _fadeTimer = Timer.periodic(
        Duration(milliseconds: stepDuration),
        (timer) {
          currentStep++;
          _currentVolume -= volumeStep;

          // Clamp volume
          _currentVolume = _currentVolume.clamp(targetVolume, 1.0);

          onVolumeChange(_currentVolume);

          if (currentStep >= steps) {
            timer.cancel();
            _currentVolume = targetVolume;
            onVolumeChange(_currentVolume);
            
            if (kDebugMode) {
              debugPrint('📉 [AudioEffects] Fade Out complete: $_currentVolume');
            }
          }
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [AudioEffects] Fade Out error: $e');
      }
    }
  }

  /// 🔀 Crossfade between two audio sources
  Future<void> crossfade({
    required Function(double volumeA, double volumeB) onVolumeChange,
    Duration duration = const Duration(milliseconds: 500),
  }) async {
    try {
      _fadeTimer?.cancel();

      final steps = 40;
      final stepDuration = duration.inMilliseconds ~/ steps;

      double volumeA = 1.0;
      double volumeB = 0.0;
      int currentStep = 0;

      _fadeTimer = Timer.periodic(
        Duration(milliseconds: stepDuration),
        (timer) {
          currentStep++;
          volumeA = 1.0 - (currentStep / steps);
          volumeB = currentStep / steps;

          onVolumeChange(volumeA, volumeB);

          if (currentStep >= steps) {
            timer.cancel();
            onVolumeChange(0.0, 1.0);
            
            if (kDebugMode) {
              debugPrint('🔀 [AudioEffects] Crossfade complete');
            }
          }
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [AudioEffects] Crossfade error: $e');
      }
    }
  }

  /// 🎚️ Set Volume Immediately
  void setVolume(double volume) {
    _currentVolume = volume.clamp(0.0, 1.0);
    if (kDebugMode) {
      debugPrint('🎚️ [AudioEffects] Volume set: $_currentVolume');
    }
  }

  /// 🛑 Stop all effects
  void stopEffects() {
    _fadeTimer?.cancel();
    _fadeTimer = null;
  }

  /// 🗑️ Dispose
  void dispose() {
    stopEffects();
  }
}
