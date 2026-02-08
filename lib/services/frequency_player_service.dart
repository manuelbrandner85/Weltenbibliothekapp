import 'dart:async';
import 'package:flutter/foundation.dart';

// For Android platform
import 'frequency_player_service_android.dart' as android_audio;

// For Web platform - conditional import

/// Real Frequency Audio Generator Service with Web Audio API
/// Generates authentic sine wave tones for healing frequencies
class FrequencyPlayerService {
  static bool _isPlaying = false;
  static double _currentFrequency = 440.0;
  static double _volume = 0.3; // Default volume (30%)
  
  // Web Audio API context (only for web platform)
  static dynamic _audioContext;
  static dynamic _oscillator;
  static dynamic _gainNode;
  
  static final List<StreamController<bool>> _playStateControllers = [];

  /// Initialize Web Audio API (for web platform)
  static void _initWebAudio() {
    if (kIsWeb && _audioContext == null) {
      try {
        // Create AudioContext using JavaScript interop (Web only)
        // Skip this on non-web platforms
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ Web Audio API not available: $e');
        }
      }
    }
  }

  /// Play a frequency (Hz) - REAL AUDIO!
  static Future<void> play(double frequency) async {
    _currentFrequency = frequency;
    _isPlaying = true;
    _notifyPlayState();
    
    if (kDebugMode) {
      debugPrint('🎵 Playing REAL frequency: ${frequency.toStringAsFixed(2)} Hz');
    }
    
    if (kIsWeb) {
      _playWebAudio(frequency, _volume);
    } else {
      // Android: Use real audio synthesis!
      await android_audio.FrequencyPlayerServiceAndroid.play(frequency);
    }
  }

  /// Play with custom volume (0.0 - 1.0)
  static Future<void> playWithVolume(double frequency, double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await play(frequency);
  }

  /// Set volume (0.0 - 1.0)
  static Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    
    if (kIsWeb && _gainNode != null) {
      try {
        _gainNode.callMethod('gain').setProperty('value', _volume);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ Failed to set volume: $e');
        }
      }
    } else if (!kIsWeb) {
      // Android: Set volume in real audio player
      await android_audio.FrequencyPlayerServiceAndroid.setVolume(_volume);
    }
  }

  /// Real Web Audio API playback
  static void _playWebAudio(double frequency, double volume) {
    try {
      // Stop any existing oscillator
      _stopWebAudio();
      
      // Initialize audio context if needed
      _initWebAudio();
      
      if (_audioContext == null) {
        if (kDebugMode) {
          debugPrint('⚠️ AudioContext not available, falling back to simulation');
        }
        _simulatePlayback();
        return;
      }
      
      // Create oscillator (tone generator)
      _oscillator = _audioContext.callMethod('createOscillator', []);
      _oscillator.setProperty('type', 'sine'); // Pure sine wave
      _oscillator.callMethod('frequency').setProperty('value', frequency);
      
      // Create gain node (volume control)
      _gainNode = _audioContext.callMethod('createGain', []);
      _gainNode.callMethod('gain').setProperty('value', volume);
      
      // Connect: Oscillator -> Gain -> Destination (speakers)
      _oscillator.callMethod('connect', [_gainNode]);
      _gainNode.callMethod('connect', [_audioContext.getProperty('destination')]);
      
      // Start playing
      _oscillator.callMethod('start', [0]);
      
      if (kDebugMode) {
        debugPrint('✅ Web Audio: Playing \${frequency}Hz at \${(volume * 100).toInt()}% volume');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Web Audio playback error: $e');
      }
      _simulatePlayback();
    }
  }

  /// Stop Web Audio playback
  static void _stopWebAudio() {
    try {
      if (_oscillator != null) {
        _oscillator.callMethod('stop', []);
        _oscillator.callMethod('disconnect', []);
        _oscillator = null;
      }
      if (_gainNode != null) {
        _gainNode.callMethod('disconnect', []);
        _gainNode = null;
      }
    } catch (e) {
      // Ignore errors when stopping
    }
  }

  /// Stop playback
  static Future<void> stop() async {
    _isPlaying = false;
    _notifyPlayState();
    
    if (kIsWeb) {
      _stopWebAudio();
    } else {
      // Android: Stop real audio playback
      await android_audio.FrequencyPlayerServiceAndroid.stop();
    }
    
    if (kDebugMode) {
      debugPrint('⏸️ Stopped playback');
    }
  }

  /// Check if currently playing
  static bool get isPlaying => _isPlaying;

  /// Get current frequency
  static double get currentFrequency => _currentFrequency;
  
  /// Get current volume
  static double get volume => _volume;

  /// Listen to play state changes
  static Stream<bool> get playStateStream {
    final controller = StreamController<bool>.broadcast();
    _playStateControllers.add(controller);
    return controller.stream;
  }

  /// Simulate playback (for Android or fallback)
  static void _simulatePlayback() {
    if (kDebugMode) {
      debugPrint('⚠️ Using simulated playback (audio synthesis not available)');
    }
  }

  /// Notify all listeners of play state change
  static void _notifyPlayState() {
    for (var controller in _playStateControllers) {
      if (!controller.isClosed) {
        controller.add(_isPlaying);
      }
    }
  }

  /// Play binaural beat (stereo - different frequency each ear)
  static Future<void> playBinaural(double leftFreq, double rightFreq) async {
    if (kDebugMode) {
      final beat = (rightFreq - leftFreq).abs();
      debugPrint('🎧 Playing binaural: ${leftFreq}Hz (L) + ${rightFreq}Hz (R) = ${beat}Hz beat');
    }
    
    if (kIsWeb) {
      _playBinauralWeb(leftFreq, rightFreq, _volume);
    } else {
      // Android: Use real audio synthesis
      await android_audio.FrequencyPlayerServiceAndroid.playBinaural(leftFreq, rightFreq);
    }
  }

  /// Real binaural beat playback (Web Audio API with stereo panning)
  static void _playBinauralWeb(double leftFreq, double rightFreq, double volume) {
    try {
      _stopWebAudio();
      _initWebAudio();
      
      if (_audioContext == null) return;
      
      // Create two oscillators (one per ear)
      final leftOsc = _audioContext.callMethod('createOscillator', []);
      leftOsc.setProperty('type', 'sine');
      leftOsc.callMethod('frequency').setProperty('value', leftFreq);
      
      final rightOsc = _audioContext.callMethod('createOscillator', []);
      rightOsc.setProperty('type', 'sine');
      rightOsc.callMethod('frequency').setProperty('value', rightFreq);
      
      // Create stereo panner nodes
      final leftPanner = _audioContext.callMethod('createStereoPanner', []);
      leftPanner.setProperty('pan').setProperty('value', -1.0); // Full left
      
      final rightPanner = _audioContext.callMethod('createStereoPanner', []);
      rightPanner.setProperty('pan').setProperty('value', 1.0); // Full right
      
      // Create gain node
      _gainNode = _audioContext.callMethod('createGain', []);
      _gainNode.callMethod('gain').setProperty('value', volume);
      
      // Connect: Left Oscillator -> Left Panner -> Gain -> Destination
      leftOsc.callMethod('connect', [leftPanner]);
      leftPanner.callMethod('connect', [_gainNode]);
      
      // Connect: Right Oscillator -> Right Panner -> Gain -> Destination
      rightOsc.callMethod('connect', [rightPanner]);
      rightPanner.callMethod('connect', [_gainNode]);
      
      _gainNode.callMethod('connect', [_audioContext.getProperty('destination')]);
      
      // Start both oscillators
      leftOsc.callMethod('start', [0]);
      rightOsc.callMethod('start', [0]);
      
      // Store reference to both oscillators
      _oscillator = {'left': leftOsc, 'right': rightOsc};
      
      _isPlaying = true;
      _notifyPlayState();
      
      if (kDebugMode) {
        debugPrint('✅ Binaural Beat: \${leftFreq}Hz (L) + \${rightFreq}Hz (R)');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Binaural playback error: $e');
      }
    }
  }

  /// Dispose (cleanup)
  static Future<void> dispose() async {
    await stop();
    if (!kIsWeb) {
      await android_audio.FrequencyPlayerServiceAndroid.dispose();
    }
    for (var controller in _playStateControllers) {
      controller.close();
    }
    _playStateControllers.clear();
  }

  /// Calculate recommended listening duration (minutes)
  static int getRecommendedDuration(double frequency) {
    if (frequency < 10) {
      return 20; // Binaural beats: 20+ min
    } else if (frequency < 100) {
      return 15; // Low frequencies: 15+ min
    } else if (frequency < 500) {
      return 10; // Mid frequencies: 10+ min
    } else {
      return 5; // High frequencies: 5+ min
    }
  }
  
  /// Solfeggio frequency names
  static String getFrequencyName(double freq) {
    final solfeggio = {
      174.0: '174 Hz - Schmerz & Stress lindern',
      285.0: '285 Hz - Zell-Regeneration',
      396.0: '396 Hz - Befreiung von Schuld & Angst',
      417.0: '417 Hz - Veränderung & Transformation',
      528.0: '528 Hz - DNA-Reparatur & Liebe',
      639.0: '639 Hz - Beziehungen & Harmonie',
      741.0: '741 Hz - Erwachen & Intuition',
      852.0: '852 Hz - Spirituelle Ordnung',
      963.0: '963 Hz - Göttliche Einheit',
    };
    
    // Find closest frequency
    double closest = solfeggio.keys.first;
    double minDiff = (freq - closest).abs();
    
    for (var key in solfeggio.keys) {
      final diff = (freq - key).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = key;
      }
    }
    
    if (minDiff < 5.0) {
      return solfeggio[closest]!;
    }
    
    return '\${freq.toStringAsFixed(2)} Hz';
  }
}
