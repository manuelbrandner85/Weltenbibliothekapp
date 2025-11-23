import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import '../models/audio_content.dart';
import 'ytdlp_api_service.dart';

/// 🎵 Audio Player Service mit just_audio
class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  final YtdlpApiService _ytdlpService = YtdlpApiService();

  AudioContent? _currentContent;
  bool _isInitialized = false;

  // Getter
  AudioPlayer get player => _player;
  AudioContent? get currentContent => _currentContent;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  bool get isPlaying => _player.playing;

  /// Initialisiere Audio Player
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Setze Audio-Session (für Background-Playback vorbereitet)
      if (kDebugMode) {
        debugPrint('🎵 Audio Player initialisiert');
      }
      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler bei Player-Initialisierung: $e');
      }
    }
  }

  /// Lade und spiele Audio-Content
  Future<bool> loadAndPlay(AudioContent content) async {
    try {
      if (kDebugMode) {
        debugPrint('🎵 Lade Audio: ${content.title}');
      }

      _currentContent = content;

      // Hole Audio-Stream-URL von yt-dlp API
      final audioUrl = await _ytdlpService.getBestAudioUrl(content.id);

      if (audioUrl == null) {
        if (kDebugMode) {
          debugPrint('❌ Keine Audio-URL gefunden');
        }
        return false;
      }

      // Lade Audio-URL in Player
      await _player.setUrl(audioUrl);

      if (kDebugMode) {
        debugPrint('✅ Audio geladen, starte Wiedergabe...');
      }

      // Starte Wiedergabe
      await _player.play();

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Laden/Abspielen: $e');
      }
      return false;
    }
  }

  /// Play/Pause Toggle
  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  /// Pause
  Future<void> pause() async {
    await _player.pause();
  }

  /// Play
  Future<void> play() async {
    await _player.play();
  }

  /// Stop
  Future<void> stop() async {
    await _player.stop();
    _currentContent = null;
  }

  /// Seek zu Position
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  /// Setze Lautstärke (0.0 - 1.0)
  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
  }

  /// Dispose
  void dispose() {
    _player.dispose();
  }

  /// Format Duration zu String
  String formatDuration(Duration? duration) {
    if (duration == null) return '00:00';

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
