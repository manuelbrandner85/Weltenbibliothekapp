/// 📹 VOICE ROOM RECORDING SERVICE
/// Record entire voice chat sessions
library;

import 'package:flutter/foundation.dart';
import 'dart:async';

enum RecordingState {
  idle,
  recording,
  paused,
  stopped,
}

class VoiceRoomRecordingService {
  // Singleton
  static final VoiceRoomRecordingService _instance =
      VoiceRoomRecordingService._internal();
  factory VoiceRoomRecordingService() => _instance;
  VoiceRoomRecordingService._internal();

  RecordingState _state = RecordingState.idle;
  String? _recordingPath;
  DateTime? _startTime;
  Duration _recordedDuration = Duration.zero;
  Timer? _durationTimer;

  final _stateController = StreamController<RecordingState>.broadcast();
  final _durationController = StreamController<Duration>.broadcast();

  Stream<RecordingState> get stateStream => _stateController.stream;
  Stream<Duration> get durationStream => _durationController.stream;

  RecordingState get state => _state;
  Duration get recordedDuration => _recordedDuration;
  String? get recordingPath => _recordingPath;
  bool get isRecording => _state == RecordingState.recording;

  /// 🔴 Start Recording
  Future<bool> startRecording(String roomId) async {
    try {
      if (_state != RecordingState.idle) {
        if (kDebugMode) {
          debugPrint('⚠️ [Recording] Already recording or stopped');
        }
        return false;
      }

      if (kDebugMode) {
        debugPrint('🔴 [Recording] Starting for room: $roomId');
      }

      _state = RecordingState.recording;
      _startTime = DateTime.now();
      _recordedDuration = Duration.zero;

      // TODO: Implement actual audio recording
      // 1. Get all audio streams from participants
      // 2. Mix them together
      // 3. Save to file (mp3/wav/m4a)
      //
      // Libraries to consider:
      // - flutter_sound
      // - record
      // - audio_session

      _recordingPath = '/storage/emulated/0/Download/voice_recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

      // Start duration tracking
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _recordedDuration = Duration(seconds: _recordedDuration.inSeconds + 1);
        _durationController.add(_recordedDuration);
      });

      _stateController.add(_state);

      if (kDebugMode) {
        debugPrint('✅ [Recording] Started successfully');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Recording] Failed to start: $e');
      }
      return false;
    }
  }

  /// ⏸️ Pause Recording
  Future<void> pauseRecording() async {
    try {
      if (_state != RecordingState.recording) return;

      if (kDebugMode) {
        debugPrint('⏸️ [Recording] Paused');
      }

      _state = RecordingState.paused;
      _durationTimer?.cancel();

      // TODO: Pause actual recording

      _stateController.add(_state);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Recording] Failed to pause: $e');
      }
    }
  }

  /// ▶️ Resume Recording
  Future<void> resumeRecording() async {
    try {
      if (_state != RecordingState.paused) return;

      if (kDebugMode) {
        debugPrint('▶️ [Recording] Resumed');
      }

      _state = RecordingState.recording;

      // Resume duration tracking
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _recordedDuration = Duration(seconds: _recordedDuration.inSeconds + 1);
        _durationController.add(_recordedDuration);
      });

      // TODO: Resume actual recording

      _stateController.add(_state);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Recording] Failed to resume: $e');
      }
    }
  }

  /// ⏹️ Stop Recording
  Future<String?> stopRecording() async {
    try {
      if (_state == RecordingState.idle || _state == RecordingState.stopped) {
        return null;
      }

      if (kDebugMode) {
        debugPrint('⏹️ [Recording] Stopping...');
      }

      _durationTimer?.cancel();
      _state = RecordingState.stopped;

      // TODO: Finalize recording file

      _stateController.add(_state);

      final path = _recordingPath;

      // Reset state
      _recordingPath = null;
      _startTime = null;
      _recordedDuration = Duration.zero;
      _state = RecordingState.idle;

      if (kDebugMode) {
        debugPrint('✅ [Recording] Stopped. File: $path');
      }

      return path;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Recording] Failed to stop: $e');
      }
      return null;
    }
  }

  /// 📊 Get Recording Info
  Map<String, dynamic> getRecordingInfo() {
    return {
      'state': _state.toString(),
      'duration': _recordedDuration.toString(),
      'path': _recordingPath,
      'startTime': _startTime?.toIso8601String(),
    };
  }

  /// 🗑️ Dispose
  void dispose() {
    _durationTimer?.cancel();
    _stateController.close();
    _durationController.close();
  }
}
