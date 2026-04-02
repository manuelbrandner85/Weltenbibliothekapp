import 'package:flutter/foundation.dart';
import 'dart:async';

/// 🎤 VOICE NOTES SERVICE - Audio Recording
class VoiceNotesService {
  static const int maxDurationSeconds = 60;
  static const int maxSizeKB = 1024; // 1 MB
  
  bool _isRecording = false;
  Timer? _recordingTimer;
  int _recordingSeconds = 0;
  
  bool get isRecording => _isRecording;
  int get recordingSeconds => _recordingSeconds;
  
  /// Start Audio Recording
  Future<bool> startRecording() async {
    try {
      _isRecording = true;
      _recordingSeconds = 0;
      
      // Start timer
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _recordingSeconds++;
        if (_recordingSeconds >= maxDurationSeconds) {
          stopRecording();
        }
      });
      
      if (kDebugMode) {
        print('🎤 Recording started');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Recording start error: $e');
      }
      return false;
    }
  }
  
  /// Stop Recording
  Future<Map<String, dynamic>?> stopRecording() async {
    try {
      _isRecording = false;
      _recordingTimer?.cancel();
      
      if (kDebugMode) {
        print('🎤 Recording stopped: ${_recordingSeconds}s');
      }
      
      // Return audio data (simulated)
      return {
        'duration': _recordingSeconds,
        'path': 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a',
        'size': _recordingSeconds * 50, // Simulate ~50KB per second
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Recording stop error: $e');
      }
      return null;
    }
  }
  
  /// Cancel Recording
  void cancelRecording() {
    _isRecording = false;
    _recordingSeconds = 0;
    _recordingTimer?.cancel();
    
    if (kDebugMode) {
      print('🎤 Recording cancelled');
    }
  }
  
  /// Format duration (MM:SS)
  static String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  
  /// Get recording progress (0.0 - 1.0)
  double getProgress() {
    return _recordingSeconds / maxDurationSeconds;
  }
}
