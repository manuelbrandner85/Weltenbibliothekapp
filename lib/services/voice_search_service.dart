/// Voice Search Service
/// Echte Spracherkennung mit speech_to_text
library;

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_to_text.dart' show SpeechListenOptions;
import 'package:permission_handler/permission_handler.dart';

class VoiceSearchService {
  static final VoiceSearchService _instance = VoiceSearchService._internal();
  factory VoiceSearchService() => _instance;
  VoiceSearchService._internal();
  
  late stt.SpeechToText _speech;
  bool _isInitialized = false;
  bool _isListening = false;
  String _lastWords = '';
  
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  String get lastWords => _lastWords;
  
  /// Initialize speech recognition
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      _speech = stt.SpeechToText();
      _isInitialized = await _speech.initialize(
        onError: (error) {
          if (kDebugMode) {
            debugPrint('❌ [VoiceSearch] Error: $error');
          }
        },
        onStatus: (status) {
          if (kDebugMode) {
            debugPrint('🎤 [VoiceSearch] Status: $status');
          }
          _isListening = status == 'listening';
        },
      );
      
      if (_isInitialized && kDebugMode) {
        debugPrint('✅ [VoiceSearch] Initialized successfully');
      }
      
      return _isInitialized;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [VoiceSearch] Initialization failed: $e');
      }
      return false;
    }
  }
  
  /// Check and request microphone permission
  Future<bool> checkPermission() async {
    final status = await Permission.microphone.status;
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isDenied || status.isPermanentlyDenied) {
      final result = await Permission.microphone.request();
      return result.isGranted;
    }
    
    return false;
  }
  
  /// Start listening
  Future<String?> startListening({
    String locale = 'de_DE',
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        if (kDebugMode) {
          debugPrint('❌ [VoiceSearch] Not initialized');
        }
        return null;
      }
    }
    
    // Check permission
    final hasPermission = await checkPermission();
    if (!hasPermission) {
      if (kDebugMode) {
        debugPrint('❌ [VoiceSearch] No microphone permission');
      }
      return null;
    }
    
    // Check if available
    if (!await _speech.hasPermission) {
      if (kDebugMode) {
        debugPrint('❌ [VoiceSearch] No speech permission');
      }
      return null;
    }
    
    _lastWords = '';
    
    try {
      await _speech.listen(
        onResult: (result) {
          _lastWords = result.recognizedWords;
          if (kDebugMode) {
            debugPrint('🎤 [VoiceSearch] Recognized: $_lastWords');
          }
        },
        listenFor: timeout,
        pauseFor: const Duration(seconds: 3),
        localeId: locale,
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
        ),
      );
      
      // Wait for completion
      await Future.delayed(timeout);
      
      if (_isListening) {
        await stopListening();
      }
      
      return _lastWords.isNotEmpty ? _lastWords : null;
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [VoiceSearch] Listen failed: $e');
      }
      return null;
    }
  }
  
  /// Stop listening
  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
      
      if (kDebugMode) {
        debugPrint('🛑 [VoiceSearch] Stopped listening');
      }
    }
  }
  
  /// Get available locales
  Future<List<stt.LocaleName>> getLocales() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    return _speech.locales();
  }
  
  /// Cancel listening
  Future<void> cancel() async {
    if (_isListening) {
      await _speech.cancel();
      _isListening = false;
      
      if (kDebugMode) {
        debugPrint('❌ [VoiceSearch] Cancelled');
      }
    }
  }
}
