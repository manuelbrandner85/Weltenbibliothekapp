/// 🎙️ Voice Message Service - STUB for Non-Web Platforms
/// Provides empty implementations for Android/iOS builds
library;

import 'dart:async';
import 'package:flutter/foundation.dart';

class VoiceMessageService extends ChangeNotifier {
  static final VoiceMessageService _instance = VoiceMessageService._internal();
  factory VoiceMessageService() => _instance;
  VoiceMessageService._internal();

  bool _isRecording = false;
  bool _isPaused = false;
  Duration _recordingDuration = Duration.zero;
  String? _lastRecordedUrl;

  bool get isRecording => _isRecording;
  bool get isPaused => _isPaused;
  Duration get recordingDuration => _recordingDuration;
  String? get lastRecordedUrl => _lastRecordedUrl;

  /// Check if recording is supported (always false on non-web)
  bool get isSupported => false;

  /// Start recording (stub - does nothing on non-web)
  Future<bool> startRecording() async {
    if (kDebugMode) {
      debugPrint('⚠️ [VoiceMessage] Recording not supported on this platform');
    }
    return false;
  }

  /// Stop recording (stub - does nothing on non-web)
  Future<Uint8List?> stopRecording() async {
    return null;
  }

  /// Pause recording (stub - does nothing on non-web)
  void pauseRecording() {
    if (kDebugMode) {
      debugPrint('⚠️ [VoiceMessage] Pause not supported on this platform');
    }
  }

  /// Resume recording (stub - does nothing on non-web)
  void resumeRecording() {
    if (kDebugMode) {
      debugPrint('⚠️ [VoiceMessage] Resume not supported on this platform');
    }
  }

  /// Cancel recording (stub - does nothing on non-web)
  void cancelRecording() {
    _isRecording = false;
    _isPaused = false;
    _recordingDuration = Duration.zero;
    notifyListeners();
  }

  /// Upload voice message (stub - does nothing on non-web)
  Future<String?> uploadVoiceMessage(Uint8List audioData, String roomId, String username) async {
    if (kDebugMode) {
      debugPrint('⚠️ [VoiceMessage] Upload not supported on this platform');
    }
    return null;
  }

  /// Get voice message URL (stub - returns empty list on non-web)
  Future<List<Map<String, dynamic>>> getVoiceMessages(String roomId) async {
    return [];
  }
}
