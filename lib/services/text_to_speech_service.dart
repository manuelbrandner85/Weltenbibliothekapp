import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Text-to-Speech Service - Artikel vorlesen lassen
class TextToSpeechService {
  static final TextToSpeechService _instance = TextToSpeechService._internal();
  factory TextToSpeechService() => _instance;
  TextToSpeechService._internal();

  final FlutterTts _tts = FlutterTts();
  
  bool _isInitialized = false;
  bool _isPlaying = false;
  double _speechRate = 1.0;
  double _pitch = 1.0;
  double _volume = 1.0;
  String _language = 'de-DE';

  /// Getter
  bool get isPlaying => _isPlaying;
  double get speechRate => _speechRate;
  double get pitch => _pitch;
  double get volume => _volume;

  /// Initialisierung
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Einstellungen laden
      await _loadSettings();

      // TTS konfigurieren
      await _tts.setLanguage(_language);
      await _tts.setSpeechRate(_speechRate);
      await _tts.setPitch(_pitch);
      await _tts.setVolume(_volume);

      // Callbacks
      _tts.setStartHandler(() {
        _isPlaying = true;
        debugPrint('🔊 TTS gestartet');
      });

      _tts.setCompletionHandler(() {
        _isPlaying = false;
        debugPrint('✅ TTS beendet');
      });

      _tts.setCancelHandler(() {
        _isPlaying = false;
        debugPrint('⏹️ TTS abgebrochen');
      });

      _tts.setErrorHandler((msg) {
        _isPlaying = false;
        debugPrint('❌ TTS Fehler: $msg');
      });

      _isInitialized = true;
      debugPrint('✅ Text-to-Speech Service initialisiert');
    } catch (e) {
      debugPrint('❌ Fehler bei TTS Initialisierung: $e');
    }
  }

  /// Text vorlesen
  Future<void> speak(String text) async {
    if (!_isInitialized) await initialize();
    
    try {
      await _tts.speak(text);
    } catch (e) {
      debugPrint('❌ Fehler beim Vorlesen: $e');
    }
  }

  /// Pause
  Future<void> pause() async {
    try {
      await _tts.pause();
      _isPlaying = false;
    } catch (e) {
      debugPrint('❌ Fehler beim Pausieren: $e');
    }
  }

  /// Fortsetzen
  Future<void> resume() async {
    try {
      // Flutter TTS hat kein direktes resume, verwende speak
      _isPlaying = true;
    } catch (e) {
      debugPrint('❌ Fehler beim Fortsetzen: $e');
    }
  }

  /// Stoppen
  Future<void> stop() async {
    try {
      await _tts.stop();
      _isPlaying = false;
    } catch (e) {
      debugPrint('❌ Fehler beim Stoppen: $e');
    }
  }

  /// Geschwindigkeit ändern
  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.5, 2.0);
    await _tts.setSpeechRate(_speechRate);
    await _saveSettings();
  }

  /// Tonhöhe ändern
  Future<void> setPitch(double pitch) async {
    _pitch = pitch.clamp(0.5, 2.0);
    await _tts.setPitch(_pitch);
    await _saveSettings();
  }

  /// Lautstärke ändern
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _tts.setVolume(_volume);
    await _saveSettings();
  }

  /// Sprache ändern
  Future<void> setLanguage(String language) async {
    _language = language;
    await _tts.setLanguage(_language);
    await _saveSettings();
  }

  /// Verfügbare Sprachen
  Future<List<String>> getAvailableLanguages() async {
    try {
      final languages = await _tts.getLanguages;
      return List<String>.from(languages);
    } catch (e) {
      debugPrint('❌ Fehler beim Abrufen der Sprachen: $e');
      return ['de-DE', 'en-US'];
    }
  }

  /// Artikel vorlesen (mit Titel)
  Future<void> readArticle({
    required String title,
    required String content,
    bool includeTitle = true,
  }) async {
    String text = '';
    
    if (includeTitle) {
      text = 'Titel: $title. \n\n$content';
    } else {
      text = content;
    }

    // Bereinige Text (HTML-Tags entfernen, etc.)
    text = _cleanText(text);

    await speak(text);
  }

  /// Text bereinigen
  String _cleanText(String text) {
    // HTML-Tags entfernen
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');
    
    // Mehrfache Leerzeichen entfernen
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    
    // Spezielle Zeichen
    text = text.replaceAll('&nbsp;', ' ');
    text = text.replaceAll('&amp;', 'und');
    text = text.replaceAll('&lt;', 'kleiner als');
    text = text.replaceAll('&gt;', 'größer als');
    
    return text.trim();
  }

  /// Einstellungen laden
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _speechRate = prefs.getDouble('tts_speech_rate') ?? 1.0;
      _pitch = prefs.getDouble('tts_pitch') ?? 1.0;
      _volume = prefs.getDouble('tts_volume') ?? 1.0;
      _language = prefs.getString('tts_language') ?? 'de-DE';
    } catch (e) {
      debugPrint('❌ Fehler beim Laden der Einstellungen: $e');
    }
  }

  /// Einstellungen speichern
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('tts_speech_rate', _speechRate);
      await prefs.setDouble('tts_pitch', _pitch);
      await prefs.setDouble('tts_volume', _volume);
      await prefs.setString('tts_language', _language);
    } catch (e) {
      debugPrint('❌ Fehler beim Speichern der Einstellungen: $e');
    }
  }

  /// Geschätzte Lesedauer
  Duration estimateReadingTime(String text, {double wordsPerMinute = 150}) {
    final wordCount = text.split(' ').length;
    final minutes = (wordCount / wordsPerMinute) * (1 / _speechRate);
    return Duration(minutes: minutes.ceil());
  }
}
