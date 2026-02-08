/// 🎙️ VOICE CHAT RECORDING SERVICE
/// Records voice chat sessions with participant consent
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

enum RecordingState {
  idle,
  requestingPermission,
  recording,
  stopping,
  failed,
}

class VoiceChatRecordingService {
  static final VoiceChatRecordingService _instance = VoiceChatRecordingService._internal();
  factory VoiceChatRecordingService() => _instance;
  VoiceChatRecordingService._internal();

  RecordingState _state = RecordingState.idle;
  DateTime? _recordingStartTime;
  MediaRecorder? _mediaRecorder;
  final List<Uint8List> _recordedChunks = [];
  
  // Consent tracking
  final Map<String, bool> _participantConsent = {};
  String? _moderatorId;

  RecordingState get state => _state;
  bool get isRecording => _state == RecordingState.recording;
  Duration? get recordingDuration {
    if (_recordingStartTime == null) return null;
    return DateTime.now().difference(_recordingStartTime!);
  }

  /// Request recording permission from all participants
  Future<bool> requestRecordingPermission({
    required String moderatorId,
    required List<String> participantIds,
    required Future<bool> Function(String userId) askConsent,
  }) async {
    _state = RecordingState.requestingPermission;
    _moderatorId = moderatorId;
    _participantConsent.clear();

    if (kDebugMode) {
      debugPrint('🎙️ [Recording] Requesting permission from ${participantIds.length} participants');
    }

    // Ask each participant for consent
    for (final userId in participantIds) {
      final consent = await askConsent(userId);
      _participantConsent[userId] = consent;
      
      if (kDebugMode) {
        debugPrint('🎙️ [Recording] $userId consent: $consent');
      }
    }

    // All must consent
    final allConsent = _participantConsent.values.every((c) => c);
    
    if (!allConsent) {
      if (kDebugMode) {
        debugPrint('❌ [Recording] Not all participants consented');
      }
      _state = RecordingState.failed;
      return false;
    }

    if (kDebugMode) {
      debugPrint('✅ [Recording] All participants consented');
    }
    
    return true;
  }

  /// Start recording
  Future<bool> startRecording(MediaStream stream) async {
    try {
      if (kDebugMode) {
        debugPrint('🎙️ [Recording] Starting recording...');
      }

      _recordedChunks.clear();
      _recordingStartTime = DateTime.now();

      // Create MediaRecorder (Web only for now)
      if (kIsWeb) {
        // Note: MediaRecorder API needs proper implementation
        // This is a placeholder for now
        _state = RecordingState.recording;
        
        if (kDebugMode) {
          debugPrint('✅ [Recording] Recording started (placeholder)');
        }
        
        return true;
      } else {
        if (kDebugMode) {
          debugPrint('❌ [Recording] Recording not supported on this platform');
        }
        _state = RecordingState.failed;
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Recording] Failed to start: $e');
      }
      _state = RecordingState.failed;
      return false;
    }
  }

  /// Stop recording and return audio data
  Future<Uint8List?> stopRecording() async {
    try {
      if (_mediaRecorder == null || _state != RecordingState.recording) {
        return null;
      }

      _state = RecordingState.stopping;

      if (kDebugMode) {
        debugPrint('🎙️ [Recording] Stopping recording...');
      }

      await _mediaRecorder!.stop();
      _mediaRecorder = null;

      // Combine all chunks
      final totalLength = _recordedChunks.fold<int>(0, (sum, chunk) => sum + chunk.length);
      final combined = Uint8List(totalLength);
      
      int offset = 0;
      for (final chunk in _recordedChunks) {
        combined.setRange(offset, offset + chunk.length, chunk);
        offset += chunk.length;
      }

      _state = RecordingState.idle;
      _recordingStartTime = null;

      if (kDebugMode) {
        debugPrint('✅ [Recording] Recording stopped: ${combined.length} bytes');
      }

      return combined;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Recording] Failed to stop: $e');
      }
      _state = RecordingState.failed;
      return null;
    }
  }

  /// Cancel recording
  void cancelRecording() {
    _mediaRecorder?.stop();
    _mediaRecorder = null;
    _recordedChunks.clear();
    _recordingStartTime = null;
    _participantConsent.clear();
    _state = RecordingState.idle;
  }

  /// Get participant consent status
  bool hasConsent(String userId) {
    return _participantConsent[userId] ?? false;
  }
}
