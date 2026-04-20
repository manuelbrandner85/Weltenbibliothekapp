// lib/services/voice_assistant_service.dart
// WELTENBIBLIOTHEK v9.0 - SPRINT 2: AI RESEARCH ASSISTANT
// Feature 14.2: Voice Assistant Integration
// Voice-to-Text + Text-to-Speech + Natural Language Processing

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

/// Voice Assistant Service - Singleton
/// Handles Speech-to-Text, Text-to-Speech, and Voice Command Processing
class VoiceAssistantService {
  static final VoiceAssistantService _instance = VoiceAssistantService._internal();
  factory VoiceAssistantService() => _instance;
  VoiceAssistantService._internal();

  // Speech-to-Text Engine
  late stt.SpeechToText _speechToText;
  bool _isInitialized = false;
  bool _isListening = false;
  String _lastTranscript = '';
  double _confidenceLevel = 0.0;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  String get lastTranscript => _lastTranscript;
  double get confidenceLevel => _confidenceLevel;

  // Callbacks
  Function(String)? onTranscriptUpdate;
  Function(String)? onFinalTranscript;
  Function(String)? onError;

  /// Initialize Voice Assistant (call once at app startup)
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _speechToText = stt.SpeechToText();
      
      // Check microphone permission
      final permissionStatus = await Permission.microphone.status;
      if (permissionStatus.isDenied) {
        final result = await Permission.microphone.request();
        if (result.isDenied) {
          if (kDebugMode) {
            debugPrint('🎤 VoiceAssistant: Microphone permission denied');
          }
          return false;
        }
      }

      // Initialize speech recognition
      _isInitialized = await _speechToText.initialize(
        onError: (error) {
          if (kDebugMode) {
            debugPrint('🎤 VoiceAssistant Error: ${error.errorMsg}');
          }
          onError?.call(error.errorMsg);
          _isListening = false;
        },
        onStatus: (status) {
          if (kDebugMode) {
            debugPrint('🎤 VoiceAssistant Status: $status');
          }
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
          }
        },
      );

      if (_isInitialized) {
        if (kDebugMode) {
          debugPrint('✅ VoiceAssistant initialized successfully');
        }
      }

      return _isInitialized;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ VoiceAssistant initialization failed: $e');
      }
      return false;
    }
  }

  /// Start listening for voice input
  Future<bool> startListening({
    String localeId = 'de_DE', // German by default
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return false;
    }

    if (_isListening) {
      if (kDebugMode) {
        debugPrint('⚠️ VoiceAssistant: Already listening');
      }
      return false;
    }

    try {
      // Check if speech recognition is available
      final available = await _speechToText.initialize();
      if (!available) {
        onError?.call('Spracherkennung nicht verfügbar');
        return false;
      }

      _lastTranscript = '';
      _confidenceLevel = 0.0;
      _isListening = true;

      await _speechToText.listen(
        localeId: localeId,
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.confirmation,
          cancelOnError: true,
          partialResults: true,
        ),
        onResult: (result) {
          _lastTranscript = result.recognizedWords;
          _confidenceLevel = result.confidence;

          if (kDebugMode) {
            debugPrint('🎤 Transcript: $_lastTranscript (confidence: ${(_confidenceLevel * 100).toStringAsFixed(0)}%)');
          }

          // Update UI with partial results
          onTranscriptUpdate?.call(_lastTranscript);

          // Final result
          if (result.finalResult) {
            if (kDebugMode) {
              debugPrint('✅ Final transcript: $_lastTranscript');
            }
            onFinalTranscript?.call(_lastTranscript);
            _isListening = false;
          }
        },
      );

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ VoiceAssistant: Failed to start listening: $e');
      }
      _isListening = false;
      onError?.call('Fehler beim Starten der Spracherkennung');
      return false;
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _speechToText.stop();
      _isListening = false;
      
      if (kDebugMode) {
        debugPrint('🛑 VoiceAssistant: Stopped listening');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ VoiceAssistant: Error stopping: $e');
      }
    }
  }

  /// Cancel listening without processing result
  Future<void> cancelListening() async {
    if (!_isListening) return;

    try {
      await _speechToText.cancel();
      _isListening = false;
      _lastTranscript = '';
      _confidenceLevel = 0.0;
      
      if (kDebugMode) {
        debugPrint('🚫 VoiceAssistant: Cancelled listening');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ VoiceAssistant: Error cancelling: $e');
      }
    }
  }

  /// Process voice command with Natural Language Processing
  /// Returns a structured command object
  VoiceCommand processCommand(String transcript) {
    final lowerTranscript = transcript.toLowerCase().trim();

    // Search commands
    if (lowerTranscript.contains('suche') || 
        lowerTranscript.contains('finde') ||
        lowerTranscript.contains('zeige')) {
      return VoiceCommand(
        type: VoiceCommandType.search,
        query: _extractSearchQuery(lowerTranscript),
        confidence: _confidenceLevel,
      );
    }

    // Navigation commands
    if (lowerTranscript.contains('öffne') || 
        lowerTranscript.contains('gehe zu') ||
        lowerTranscript.contains('navigiere')) {
      return VoiceCommand(
        type: VoiceCommandType.navigate,
        target: _extractNavigationTarget(lowerTranscript),
        confidence: _confidenceLevel,
      );
    }

    // Filter commands
    if (lowerTranscript.contains('filter') || 
        lowerTranscript.contains('sortiere') ||
        lowerTranscript.contains('zeige nur')) {
      return VoiceCommand(
        type: VoiceCommandType.filter,
        filterType: _extractFilterType(lowerTranscript),
        confidence: _confidenceLevel,
      );
    }

    // Reading commands
    if (lowerTranscript.contains('lies vor') || 
        lowerTranscript.contains('vorlesen')) {
      return VoiceCommand(
        type: VoiceCommandType.read,
        confidence: _confidenceLevel,
      );
    }

    // Default: treat as search query
    return VoiceCommand(
      type: VoiceCommandType.search,
      query: lowerTranscript,
      confidence: _confidenceLevel,
    );
  }

  /// Extract search query from natural language
  String _extractSearchQuery(String transcript) {
    // Remove common search prefixes
    final prefixes = ['suche nach', 'suche', 'finde', 'zeige mir', 'zeige'];
    String query = transcript.toLowerCase();
    
    for (final prefix in prefixes) {
      if (query.startsWith(prefix)) {
        query = query.substring(prefix.length).trim();
        break;
      }
    }
    
    return query;
  }

  /// Extract navigation target
  String _extractNavigationTarget(String transcript) {
    if (transcript.contains('dashboard')) return 'dashboard';
    if (transcript.contains('materie')) return 'materie';
    if (transcript.contains('energie')) return 'energie';
    if (transcript.contains('spirit')) return 'spirit';
    if (transcript.contains('community')) return 'community';
    if (transcript.contains('favoriten')) return 'favorites';
    return 'home';
  }

  /// Extract filter type
  String _extractFilterType(String transcript) {
    if (transcript.contains('narrative')) return 'narrative';
    if (transcript.contains('theorie')) return 'theory';
    if (transcript.contains('verschwörung')) return 'conspiracy';
    if (transcript.contains('wissenschaft')) return 'science';
    if (transcript.contains('mystik')) return 'mystic';
    return 'all';
  }

  /// Check if microphone is available
  Future<bool> checkMicrophoneAvailability() async {
    try {
      final status = await Permission.microphone.status;
      return status.isGranted;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Microphone check failed: $e');
      }
      return false;
    }
  }

  /// Get available locales for speech recognition
  Future<List<String>> getAvailableLocales() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      final locales = await _speechToText.locales();
      return locales.map((locale) => locale.localeId).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to get locales: $e');
      }
      return ['de_DE', 'en_US']; // Fallback
    }
  }

  /// Dispose resources
  void dispose() {
    if (_isListening) {
      _speechToText.stop();
    }
    _isListening = false;
    _isInitialized = false;
  }
}

/// Voice Command Data Class
class VoiceCommand {
  final VoiceCommandType type;
  final String? query;
  final String? target;
  final String? filterType;
  final double confidence;

  VoiceCommand({
    required this.type,
    this.query,
    this.target,
    this.filterType,
    required this.confidence,
  });

  @override
  String toString() {
    return 'VoiceCommand(type: $type, query: $query, target: $target, filter: $filterType, confidence: ${(confidence * 100).toStringAsFixed(0)}%)';
  }
}

/// Voice Command Types
enum VoiceCommandType {
  search,      // Search for content
  navigate,    // Navigate to screen
  filter,      // Apply filters
  read,        // Read aloud content
  unknown,     // Unrecognized command
}
