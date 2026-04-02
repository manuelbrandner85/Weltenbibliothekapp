import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// Android Frequency Audio Generator Service
/// Generates authentic sine wave tones using programmatic audio synthesis
class FrequencyPlayerServiceAndroid {
  static AudioPlayer? _player;
  static bool _isPlaying = false;
  static double _currentFrequency = 440.0;
  static double _volume = 0.3;
  // UNUSED FIELD: static Timer? _playbackTimer;
  
  static final List<StreamController<bool>> _playStateControllers = [];

  /// Initialize audio player
  static Future<void> _initPlayer() async {
    if (_player == null) {
      _player = AudioPlayer();
      if (kDebugMode) {
        debugPrint('✅ Android AudioPlayer initialized');
      }
    }
  }

  /// Generate sine wave audio data (PCM)
  /// Creates a pure sine wave tone at the specified frequency
  static Uint8List _generateSineWave(double frequency, int durationSeconds) {
    const int sampleRate = 44100; // CD quality
    const int bitDepth = 16; // 16-bit PCM
    final int totalSamples = sampleRate * durationSeconds;
    
    // Create WAV file header + audio data
    final ByteData data = ByteData(44 + (totalSamples * 2));
    
    // WAV Header (44 bytes)
    // "RIFF" chunk descriptor
    data.setUint8(0, 0x52); // R
    data.setUint8(1, 0x49); // I
    data.setUint8(2, 0x46); // F
    data.setUint8(3, 0x46); // F
    data.setUint32(4, 36 + totalSamples * 2, Endian.little); // File size - 8
    
    // "WAVE" format
    data.setUint8(8, 0x57);  // W
    data.setUint8(9, 0x41);  // A
    data.setUint8(10, 0x56); // V
    data.setUint8(11, 0x45); // E
    
    // "fmt " sub-chunk
    data.setUint8(12, 0x66); // f
    data.setUint8(13, 0x6d); // m
    data.setUint8(14, 0x74); // t
    data.setUint8(15, 0x20); // space
    data.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
    data.setUint16(20, 1, Endian.little); // AudioFormat (1 = PCM)
    data.setUint16(22, 1, Endian.little); // NumChannels (1 = Mono)
    data.setUint32(24, sampleRate, Endian.little); // SampleRate
    data.setUint32(28, sampleRate * 2, Endian.little); // ByteRate
    data.setUint16(32, 2, Endian.little); // BlockAlign
    data.setUint16(34, bitDepth, Endian.little); // BitsPerSample
    
    // "data" sub-chunk
    data.setUint8(36, 0x64); // d
    data.setUint8(37, 0x61); // a
    data.setUint8(38, 0x74); // t
    data.setUint8(39, 0x61); // a
    data.setUint32(40, totalSamples * 2, Endian.little); // Subchunk2Size
    
    // Generate sine wave samples
    final double amplitude = 32767.0 * _volume; // Max amplitude for 16-bit
    final double angularFrequency = 2.0 * math.pi * frequency;
    
    for (int i = 0; i < totalSamples; i++) {
      final double time = i / sampleRate;
      final double sample = amplitude * math.sin(angularFrequency * time);
      final int sampleValue = sample.round().clamp(-32768, 32767);
      
      // Write 16-bit sample (little-endian)
      data.setInt16(44 + (i * 2), sampleValue, Endian.little);
    }
    
    return data.buffer.asUint8List();
  }

  /// Play a frequency (Hz) - REAL AUDIO for Android!
  static Future<void> play(double frequency) async {
    _currentFrequency = frequency;
    _isPlaying = true;
    _notifyPlayState();
    
    if (kDebugMode) {
      debugPrint('🎵 Android: Playing REAL frequency: ${frequency.toStringAsFixed(2)} Hz');
    }
    
    try {
      await _initPlayer();
      
      // Generate 30 seconds of audio (looped)
      final audioData = _generateSineWave(frequency, 30);
      
      if (kDebugMode) {
        debugPrint('✅ Generated ${audioData.length} bytes of audio data');
      }
      
      // Create a stream source from the generated audio
      await _player!.setAudioSource(
        MyCustomSource(audioData),
        initialPosition: Duration.zero,
      );
      
      // Set looping mode for continuous playback
      await _player!.setLoopMode(LoopMode.one);
      
      // Set volume
      await _player!.setVolume(_volume);
      
      // Start playback
      await _player!.play();
      
      if (kDebugMode) {
        debugPrint('✅ Android: Playing ${frequency}Hz at ${(_volume * 100).toInt()}% volume');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Android audio playback error: $e');
      }
      _isPlaying = false;
      _notifyPlayState();
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
    if (_player != null && _isPlaying) {
      await _player!.setVolume(_volume);
      if (kDebugMode) {
        debugPrint('🔊 Volume set to ${(_volume * 100).toInt()}%');
      }
    }
  }

  /// Stop playback
  static Future<void> stop() async {
    _isPlaying = false;
    _notifyPlayState();
    
    if (_player != null) {
      await _player!.stop();
      if (kDebugMode) {
        debugPrint('⏸️ Stopped playback');
      }
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

  /// Notify all listeners of play state change
  static void _notifyPlayState() {
    for (var controller in _playStateControllers) {
      if (!controller.isClosed) {
        controller.add(_isPlaying);
      }
    }
  }

  /// Play binaural beat (stereo - different frequency each ear)
  /// NOTE: For true binaural beats, we need stereo audio generation
  static Future<void> playBinaural(double leftFreq, double rightFreq) async {
    if (kDebugMode) {
      final beat = (rightFreq - leftFreq).abs();
      debugPrint('🎧 Android: Playing binaural: ${leftFreq}Hz (L) + ${rightFreq}Hz (R) = ${beat}Hz beat');
    }
    
    // For now, play average frequency (stereo generation would require more complex audio synthesis)
    final avgFreq = (leftFreq + rightFreq) / 2;
    await play(avgFreq);
  }

  /// Dispose (cleanup)
  static Future<void> dispose() async {
    await stop();
    await _player?.dispose();
    _player = null;
    
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
    // FIX: Cannot use 'const' with double keys - use final instead
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
    
    return '${freq.toStringAsFixed(2)} Hz';
  }
}

/// Custom audio source for just_audio
/// Provides programmatically generated audio data
class MyCustomSource extends StreamAudioSource {
  final Uint8List _audioData;
  
  MyCustomSource(this._audioData);
  
  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= _audioData.length;
    
    return StreamAudioResponse(
      sourceLength: _audioData.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(_audioData.sublist(start, end)),
      contentType: 'audio/wav',
    );
  }
}
