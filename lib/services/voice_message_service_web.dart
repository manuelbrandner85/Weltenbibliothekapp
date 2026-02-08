/// 🎙️ Voice Message Service
/// Handles audio recording and playback for voice messages
library;

import 'dart:async';
import 'dart:typed_data';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'cloudflare_api_service.dart';

class VoiceMessageService extends ChangeNotifier {
  static final VoiceMessageService _instance = VoiceMessageService._internal();
  factory VoiceMessageService() => _instance;
  VoiceMessageService._internal();

  final String _baseUrl = CloudflareApiService.chatFeaturesApiUrl;

  html.MediaRecorder? _mediaRecorder;
  html.MediaStream? _mediaStream;
  final List<html.Blob> _audioChunks = [];
  Timer? _recordingTimer;
  
  bool _isRecording = false;
  bool _isPaused = false;
  Duration _recordingDuration = Duration.zero;
  String? _lastRecordedUrl;

  bool get isRecording => _isRecording;
  bool get isPaused => _isPaused;
  Duration get recordingDuration => _recordingDuration;
  String? get lastRecordedUrl => _lastRecordedUrl;

  /// Check if recording is supported
  bool get isSupported {
    if (!kIsWeb) return false;
    return html.window.navigator.mediaDevices != null;
  }

  /// Start recording
  Future<bool> startRecording() async {
    try {
      if (!isSupported) {
        if (kDebugMode) {
          debugPrint('❌ [VoiceMessage] Recording not supported');
        }
        return false;
      }

      // Request microphone permission
      _mediaStream = await html.window.navigator.mediaDevices!.getUserMedia({
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
      });

      // Create MediaRecorder
      _mediaRecorder = html.MediaRecorder(_mediaStream!, {
        'mimeType': 'audio/webm',
      });

      _audioChunks.clear();

      // Listen to data
      _mediaRecorder!.addEventListener('dataavailable', (event) {
        final blobEvent = event as html.BlobEvent;
        if (blobEvent.data != null && blobEvent.data!.size > 0) {
          _audioChunks.add(blobEvent.data!);
        }
      });

      // Start recording
      _mediaRecorder!.start();
      _isRecording = true;
      _recordingDuration = Duration.zero;

      // Start timer
      _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        _recordingDuration += const Duration(milliseconds: 100);
        notifyListeners();
      });

      if (kDebugMode) {
        debugPrint('🎙️ [VoiceMessage] Recording started');
      }

      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [VoiceMessage] Start recording error: $e');
      }
      return false;
    }
  }

  /// Stop recording
  Future<Uint8List?> stopRecording() async {
    try {
      if (_mediaRecorder == null || !_isRecording) return null;

      final completer = Completer<Uint8List?>();

      // Listen to stop event
      _mediaRecorder!.addEventListener('stop', (event) async {
        if (_audioChunks.isEmpty) {
          completer.complete(null);
          return;
        }

        // Create blob from chunks
        final blob = html.Blob(_audioChunks, 'audio/webm');
        
        // Convert to Uint8List
        final reader = html.FileReader();
        reader.readAsArrayBuffer(blob);
        
        reader.onLoadEnd.listen((event) {
          final arrayBuffer = reader.result as ByteBuffer;
          completer.complete(Uint8List.view(arrayBuffer));
        });
      });

      // Stop recording
      _mediaRecorder!.stop();
      _mediaStream?.getTracks().forEach((track) => track.stop());
      
      _recordingTimer?.cancel();
      _isRecording = false;
      _isPaused = false;

      if (kDebugMode) {
        debugPrint('🎙️ [VoiceMessage] Recording stopped (${_recordingDuration.inSeconds}s)');
      }

      notifyListeners();
      return await completer.future;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [VoiceMessage] Stop recording error: $e');
      }
      return null;
    }
  }

  /// Pause recording
  void pauseRecording() {
    if (_mediaRecorder != null && _isRecording && !_isPaused) {
      _mediaRecorder!.pause();
      _recordingTimer?.cancel();
      _isPaused = true;
      notifyListeners();
    }
  }

  /// Resume recording
  void resumeRecording() {
    if (_mediaRecorder != null && _isRecording && _isPaused) {
      _mediaRecorder!.resume();
      _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        _recordingDuration += const Duration(milliseconds: 100);
        notifyListeners();
      });
      _isPaused = false;
      notifyListeners();
    }
  }

  /// Upload voice message
  Future<String?> uploadVoiceMessage(Uint8List audioData) async {
    try {
      final uri = Uri.parse('$_baseUrl/upload/voice');
      final request = http.MultipartRequest('POST', uri);
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'audio',
          audioData,
          filename: 'voice_${DateTime.now().millisecondsSinceEpoch}.webm',
        ),
      );

      request.fields['duration'] = _recordingDuration.inSeconds.toString();

      if (kDebugMode) {
        debugPrint('📤 [VoiceMessage] Uploading: ${audioData.length} bytes');
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _lastRecordedUrl = data['url'];

        if (kDebugMode) {
          debugPrint('✅ [VoiceMessage] Uploaded: $_lastRecordedUrl');
        }

        return _lastRecordedUrl;
      } else {
        throw Exception('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [VoiceMessage] Upload error: $e');
      }
      return null;
    }
  }

  /// Format duration
  static String formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Cleanup
  @override
  void dispose() {
    _recordingTimer?.cancel();
    _mediaStream?.getTracks().forEach((track) => track.stop());
    super.dispose();
  }
}
