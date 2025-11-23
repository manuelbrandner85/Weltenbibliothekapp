import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/audio_content.dart';
import '../services/audio_player_service.dart';

/// 🎵 Player Provider - Verwaltet Audio-Wiedergabe-Status
class PlayerProvider with ChangeNotifier {
  final AudioPlayerService _audioService = AudioPlayerService();

  AudioContent? _currentContent;
  PlayerState? _playerState;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isLoading = false;

  // Getter
  AudioContent? get currentContent => _currentContent;
  PlayerState? get playerState => _playerState;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get isPlaying => _playerState?.playing ?? false;
  bool get isLoading => _isLoading;
  double get progress => _duration.inMilliseconds > 0
      ? _position.inMilliseconds / _duration.inMilliseconds
      : 0.0;

  PlayerProvider() {
    _initialize();
  }

  /// Initialisiere Player und Stream-Listener
  void _initialize() async {
    await _audioService.initialize();

    // Lausche auf Player-State-Änderungen
    _audioService.playerStateStream.listen((state) {
      _playerState = state;
      notifyListeners();
    });

    // Lausche auf Position-Änderungen
    _audioService.positionStream.listen((position) {
      _position = position;
      notifyListeners();
    });

    // Lausche auf Duration-Änderungen
    _audioService.durationStream.listen((duration) {
      if (duration != null) {
        _duration = duration;
        notifyListeners();
      }
    });
  }

  /// Spiele Audio-Content
  Future<void> playContent(AudioContent content) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _audioService.loadAndPlay(content);

      if (success) {
        _currentContent = content;
        if (kDebugMode) {
          debugPrint('🎵 Spiele jetzt: ${content.title}');
        }
      } else {
        if (kDebugMode) {
          debugPrint('❌ Fehler beim Laden von: ${content.title}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Wiedergabefehler: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle Play/Pause
  Future<void> togglePlayPause() async {
    await _audioService.togglePlayPause();
  }

  /// Pause
  Future<void> pause() async {
    await _audioService.pause();
  }

  /// Play
  Future<void> play() async {
    await _audioService.play();
  }

  /// Stop
  Future<void> stop() async {
    await _audioService.stop();
    _currentContent = null;
    _position = Duration.zero;
    _duration = Duration.zero;
    notifyListeners();
  }

  /// Seek zu Position
  Future<void> seek(Duration position) async {
    await _audioService.seek(position);
  }

  /// Setze Lautstärke
  Future<void> setVolume(double volume) async {
    await _audioService.setVolume(volume);
  }

  /// Format Duration
  String formatDuration(Duration duration) {
    return _audioService.formatDuration(duration);
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
}
