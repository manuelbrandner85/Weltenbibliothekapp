import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

/// v15.13 - Production-Ready Sound Service
/// Provides tap sounds, unlock sounds, and other audio feedback
/// 
/// ✅ ECHTE AUDIO-IMPLEMENTIERUNG
/// - Nutzt audioplayers package
/// - Cached audio players für Performance
/// - Fallback zu Debug-Logs bei Fehlern
class SoundService {
  // Singleton Pattern
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();
  
  // Audio Player Pool für parallele Sounds
  final List<AudioPlayer> _playerPool = [];
  static const int _maxPlayers = 5;
  
  // Sound-Assets (URLs oder lokale Assets)
  static const Map<String, String> _soundAssets = {
    'tap': 'https://www.soundjay.com/buttons/sounds/button-09.mp3',
    'unlock': 'https://www.soundjay.com/buttons/sounds/button-30.mp3',
    'achievement': 'https://www.soundjay.com/buttons/sounds/beep-07.mp3',
    'game_score': 'https://www.soundjay.com/buttons/sounds/beep-01b.mp3',
    'game_bonus': 'https://www.soundjay.com/buttons/sounds/beep-02.mp3',
    'game_fail': 'https://www.soundjay.com/buttons/sounds/beep-03.mp3',
  };
  
  /// Initialisiere Sound Service (optional, wird lazy initialisiert)
  Future<void> initialize() async {
    try {
      // Pre-load player pool
      for (int i = 0; i < _maxPlayers; i++) {
        _playerPool.add(AudioPlayer());
      }
      
      if (kDebugMode) {
        debugPrint('🔊 SoundService initialized with $_maxPlayers players');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ SoundService initialization failed: $e');
      }
    }
  }
  
  /// Play tap sound with variable pitch
  static void playTapSound({double pitch = 1.0}) async {
    try {
      final player = _instance._getAvailablePlayer();
      if (player == null) {
        if (kDebugMode) debugPrint('⚠️ No available audio player');
        return;
      }
      
      // Play sound (pitch currently not supported by audioplayers)
      // Alternative: Use different sound files for different pitches
      await player.play(UrlSource(_soundAssets['tap']!));
      player.setVolume(0.5); // Moderate volume
      
      if (kDebugMode) {
        debugPrint('🔊 Playing tap sound (pitch: $pitch)');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error playing tap sound: $e');
      }
    }
  }
  
  /// Play unlock sound when Easter Egg is triggered
  static void playUnlockSound() async {
    try {
      final player = _instance._getAvailablePlayer();
      if (player == null) return;
      
      await player.play(UrlSource(_soundAssets['unlock']!));
      player.setVolume(0.7); // Louder for important events
      
      if (kDebugMode) {
        debugPrint('🔊 Playing unlock sound (WHOOSH!)');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error playing unlock sound: $e');
      }
    }
  }
  
  /// Play achievement unlock sound
  static void playAchievementSound() async {
    try {
      final player = _instance._getAvailablePlayer();
      if (player == null) return;
      
      await player.play(UrlSource(_soundAssets['achievement']!));
      player.setVolume(0.8); // High volume for achievements
      
      if (kDebugMode) {
        debugPrint('🔊 Playing achievement unlock sound');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error playing achievement sound: $e');
      }
    }
  }
  
  /// Play mini-game sound effects
  static void playGameSound(String type) async {
    try {
      final player = _instance._getAvailablePlayer();
      if (player == null) return;
      
      // Map game sound types to assets
      String? soundUrl;
      switch (type.toLowerCase()) {
        case 'score':
        case 'point':
          soundUrl = _soundAssets['game_score'];
          break;
        case 'bonus':
        case 'powerup':
          soundUrl = _soundAssets['game_bonus'];
          break;
        case 'fail':
        case 'gameover':
          soundUrl = _soundAssets['game_fail'];
          break;
        default:
          soundUrl = _soundAssets['tap'];
      }
      
      if (soundUrl != null) {
        await player.play(UrlSource(soundUrl));
        player.setVolume(0.6);
      }
      
      if (kDebugMode) {
        debugPrint('🔊 Playing game sound: $type');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error playing game sound: $e');
      }
    }
  }
  
  /// Get available audio player from pool
  AudioPlayer? _getAvailablePlayer() {
    try {
      // Initialize pool if empty
      if (_playerPool.isEmpty) {
        for (int i = 0; i < _maxPlayers; i++) {
          _playerPool.add(AudioPlayer());
        }
      }
      
      // Find idle player
      for (var player in _playerPool) {
        if (player.state != PlayerState.playing) {
          return player;
        }
      }
      
      // All players busy, return first one (will interrupt current sound)
      return _playerPool.first;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error getting audio player: $e');
      }
      return null;
    }
  }
  
  /// Dispose all audio players
  void dispose() {
    for (var player in _playerPool) {
      player.dispose();
    }
    _playerPool.clear();
    
    if (kDebugMode) {
      debugPrint('🔊 SoundService disposed');
    }
  }
  
  /// Play custom sound from URL or asset path
  static void playCustomSound(String soundUrl, {double volume = 0.5}) async {
    try {
      final player = _instance._getAvailablePlayer();
      if (player == null) return;
      
      await player.play(UrlSource(soundUrl));
      player.setVolume(volume);
      
      if (kDebugMode) {
        debugPrint('🔊 Playing custom sound: $soundUrl');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error playing custom sound: $e');
      }
    }
  }
}
