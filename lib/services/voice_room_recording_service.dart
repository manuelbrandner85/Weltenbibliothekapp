/// 📹 VOICE ROOM RECORDING SERVICE
/// Record entire voice chat sessions using flutter_sound
library;

import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_sound/flutter_sound.dart';

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

  FlutterSoundRecorder? _recorder;

  final _stateController = StreamController<RecordingState>.broadcast();
  final _durationController = StreamController<Duration>.broadcast();

  Stream<RecordingState> get stateStream => _stateController.stream;
  Stream<Duration> get durationStream => _durationController.stream;

  RecordingState get state => _state;
  Duration get recordedDuration => _recordedDuration;
  String? get recordingPath => _recordingPath;
  bool get isRecording => _state == RecordingState.recording;

  Future<void> _initRecorder() async {
    if (_recorder != null) return;
    _recorder = FlutterSoundRecorder();
    await _recorder!.openRecorder();
  }

  /// 🔴 Start Recording
  Future<bool> startRecording(String roomId) async {
    try {
      if (_state != RecordingState.idle) {
        if (kDebugMode) debugPrint('⚠️ [Recording] Already recording or stopped');
        return false;
      }

      if (kDebugMode) debugPrint('🔴 [Recording] Starting for room: $roomId');

      await _initRecorder();

      // Get temporary directory for recording
      final dir = kIsWeb
          ? null
          : await getTemporaryDirectory();
      final filename = 'voice_recording_${roomId}_${DateTime.now().millisecondsSinceEpoch}.aac';
      _recordingPath = dir != null ? '${dir.path}/$filename' : filename;

      // Start recording
      await _recorder!.startRecorder(
        toFile: kIsWeb ? null : _recordingPath,
        codec: Codec.aacADTS,
      );

      _state = RecordingState.recording;
      _startTime = DateTime.now();
      _recordedDuration = Duration.zero;

      // Start duration tracking
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _recordedDuration = Duration(seconds: _recordedDuration.inSeconds + 1);
        _durationController.add(_recordedDuration);
      });

      _stateController.add(_state);
      if (kDebugMode) debugPrint('✅ [Recording] Started: $_recordingPath');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [Recording] Failed to start: $e');
      return false;
    }
  }

  /// ⏸️ Pause Recording
  Future<void> pauseRecording() async {
    try {
      if (_state != RecordingState.recording) return;
      if (kDebugMode) debugPrint('⏸️ [Recording] Paused');

      _state = RecordingState.paused;
      _durationTimer?.cancel();

      await _recorder?.pauseRecorder();
      _stateController.add(_state);
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [Recording] Failed to pause: $e');
    }
  }

  /// ▶️ Resume Recording
  Future<void> resumeRecording() async {
    try {
      if (_state != RecordingState.paused) return;
      if (kDebugMode) debugPrint('▶️ [Recording] Resumed');

      _state = RecordingState.recording;

      await _recorder?.resumeRecorder();

      // Resume duration tracking
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _recordedDuration = Duration(seconds: _recordedDuration.inSeconds + 1);
        _durationController.add(_recordedDuration);
      });

      _stateController.add(_state);
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [Recording] Failed to resume: $e');
    }
  }

  /// ⏹️ Stop Recording
  Future<String?> stopRecording() async {
    try {
      if (_state == RecordingState.idle || _state == RecordingState.stopped) {
        return null;
      }

      if (kDebugMode) debugPrint('⏹️ [Recording] Stopping...');

      _durationTimer?.cancel();
      _state = RecordingState.stopped;

      final path = await _recorder?.stopRecorder() ?? _recordingPath;

      _stateController.add(_state);

      // Reset state
      _recordingPath = null;
      _startTime = null;
      _recordedDuration = Duration.zero;
      _state = RecordingState.idle;

      // Close recorder for cleanup
      await _recorder?.closeRecorder();
      _recorder = null;

      if (kDebugMode) debugPrint('✅ [Recording] Stopped. File: $path');
      return path;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [Recording] Failed to stop: $e');
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
    _recorder?.closeRecorder();
    _recorder = null;
    _stateController.close();
    _durationController.close();
  }
}
