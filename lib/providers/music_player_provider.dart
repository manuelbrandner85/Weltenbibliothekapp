import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/music_track.dart';
import '../models/music_genre.dart';
import '../services/music_sync_service.dart';

/// 🎵 Music Player Provider
/// Verwaltet Musik-Wiedergabe mit just_audio + Cloudflare Worker Sync
class MusicPlayerProvider with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final MusicSyncService _syncService = MusicSyncService();

  // Player State
  MusicTrack? _currentTrack;
  bool _isPlaying = false;
  bool _isLoading = false;
  double _volume = 1.0; // 0.0 - 1.0
  double _maxVolume = 1.0; // Dynamisch basierend auf Teilnehmer-Anzahl
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  MusicGenre? _currentGenre;
  int _participantCount = 1;

  // Getters
  MusicTrack? get currentTrack => _currentTrack;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  double get volume => _volume;
  double get maxVolume => _maxVolume;
  Duration get position => _position;
  Duration get duration => _duration;
  MusicGenre? get currentGenre => _currentGenre;
  int get participantCount => _participantCount;
  bool get isConnected => _syncService.isConnected;

  MusicPlayerProvider() {
    _initializePlayer();
  }

  /// Initialisiere Audio Player
  void _initializePlayer() {
    // Position Updates
    _audioPlayer.positionStream.listen((position) {
      _position = position;
      notifyListeners();

      // Sende Position an Sync-Service (alle 5 Sekunden)
      if (position.inSeconds % 5 == 0) {
        _syncService.sendPlaybackPosition(position.inSeconds.toDouble());
      }
    });

    // Duration Updates
    _audioPlayer.durationStream.listen((duration) {
      if (duration != null) {
        _duration = duration;
        notifyListeners();
      }
    });

    // Player State Changes
    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      _isLoading =
          state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering;
      notifyListeners();

      // Auto-Next-Song bei Ende
      if (state.processingState == ProcessingState.completed) {
        nextSong();
      }
    });

    // Höre auf Sync-Service Updates
    _syncService.stateUpdates.listen((update) {
      _handleSyncUpdate(update);
    });
  }

  /// Verbinde zu Musik-Raum
  Future<bool> connectToRoom(String roomId) async {
    final success = await _syncService.connectToRoom(roomId);
    if (success) {
      notifyListeners();
    }
    return success;
  }

  /// Trenne von Raum
  Future<void> disconnect() async {
    await _syncService.disconnect();
    await _audioPlayer.stop();
    _currentTrack = null;
    _isPlaying = false;
    notifyListeners();
  }

  /// Handle Sync Updates vom Worker
  void _handleSyncUpdate(Map<String, dynamic> update) {
    final type = update['type'] as String?;

    if (type == 'initial_state' || type == 'state_update') {
      final state = update['state'] as Map<String, dynamic>?;
      if (state != null) {
        _updateFromSyncState(state);
      }
    }

    if (type == 'participant_update') {
      _participantCount = update['participantCount'] as int? ?? 1;
      _maxVolume = (update['maxVolume'] as int? ?? 100) / 100.0;

      // Passe Lautstärke an Max-Lautstärke an
      if (_volume > _maxVolume) {
        setVolume(_maxVolume);
      }

      notifyListeners();
    }
  }

  /// Update State von Sync-Worker
  void _updateFromSyncState(Map<String, dynamic> state) {
    // Hier könnten wir den State synchronisieren
    // Für jetzt: Nur lokale Wiedergabe
    notifyListeners();
  }

  /// Genre auswählen
  Future<void> selectGenre(MusicGenre genre) async {
    _isLoading = true;
    _currentGenre = genre;
    notifyListeners();

    try {
      // Setze Genre im Sync-Worker und erhalte ersten Song
      final track = await _syncService.setGenre(genre);

      if (track != null) {
        await playTrack(track);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Genre-Auswahl fehlgeschlagen: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Spiele Track ab
  Future<void> playTrack(MusicTrack track) async {
    try {
      _isLoading = true;
      _currentTrack = track;
      notifyListeners();

      // Lade Audio-Stream-URL
      await _audioPlayer.setUrl(track.audioUrl);

      // Starte Wiedergabe
      await _audioPlayer.play();

      _isPlaying = true;
      _isLoading = false;
      notifyListeners();

      if (kDebugMode) {
        debugPrint('▶️ Spiele: ${track.title} - ${track.artist}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Wiedergabe fehlgeschlagen: $e');
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Play/Pause Toggle
  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
      await _syncService.togglePlayPause(false);
      _isPlaying = false;
    } else {
      await _audioPlayer.play();
      await _syncService.togglePlayPause(true);
      _isPlaying = true;
    }
    notifyListeners();
  }

  /// Nächster Song
  Future<void> nextSong() async {
    _isLoading = true;
    notifyListeners();

    try {
      final track = await _syncService.nextSong();

      if (track != null) {
        await playTrack(track);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Nächster Song fehlgeschlagen: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Setze Lautstärke (respektiert maxVolume)
  Future<void> setVolume(double newVolume) async {
    // Begrenze auf maxVolume
    final clampedVolume = newVolume.clamp(0.0, _maxVolume);

    _volume = clampedVolume;
    await _audioPlayer.setVolume(clampedVolume);
    await _syncService.setVolume(clampedVolume);

    notifyListeners();
  }

  /// Seek zu Position
  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  /// Musik global aktivieren/deaktivieren (z.B. für Livestream)
  Future<void> setMusicEnabled(bool enabled) async {
    if (!enabled && _isPlaying) {
      await _audioPlayer.pause();
      _isPlaying = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _syncService.dispose();
    super.dispose();
  }
}
