import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/music_genre.dart';
import '../models/music_track.dart';
import '../services/music_sync_service.dart';

/// Simple Music Provider
///
/// Verwaltet den lokalen Musik-Player-State mit just_audio.
/// Kommuniziert mit dem Cloudflare Worker für Genre-Auswahl und Playlist-Management.
///
/// Features:
/// - Genre-basierte Playlist-Auswahl
/// - just_audio Integration für lokale Wiedergabe
/// - Dynamische Lautstärke-Limitierung (1 User=100%, 2 User=50%, 3+ User=10%)
/// - Play/Pause/Next Controls
/// - Progress-Tracking
class SimpleMusicProvider extends ChangeNotifier {
  // Services
  final MusicSyncService _syncService = MusicSyncService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  // State
  MusicTrack? _currentTrack;
  MusicGenre? _currentGenre;
  List<String> _playlist = []; // Video-IDs
  int _playlistIndex = 0;
  bool _isPlaying = false;
  bool _isLoadingGenre = false;
  int _volume = 100;
  int _maxVolume = 100;
  int _participantCount = 1;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  String? _errorMessage;

  // Getters
  MusicTrack? get currentTrack => _currentTrack;
  MusicGenre? get currentGenre => _currentGenre;
  List<String> get playlist => _playlist;
  int get playlistIndex => _playlistIndex;
  bool get isPlaying => _isPlaying;
  bool get isLoadingGenre => _isLoadingGenre;
  int get volume => _volume;
  int get maxVolume => _maxVolume;
  int get participantCount => _participantCount;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  String? get errorMessage => _errorMessage;
  bool get hasTrack => _currentTrack != null;

  // Progress als Prozentsatz (0.0 - 1.0)
  double get progress {
    if (_totalDuration.inMilliseconds == 0) return 0.0;
    return _currentPosition.inMilliseconds / _totalDuration.inMilliseconds;
  }

  // Constructor
  SimpleMusicProvider() {
    _initializePlayer();
  }

  /// Initialisiert den Audio-Player und Listener
  void _initializePlayer() {
    // Position Stream
    _audioPlayer.positionStream.listen((position) {
      _currentPosition = position;
      notifyListeners();
    });

    // Duration Stream
    _audioPlayer.durationStream.listen((duration) {
      if (duration != null) {
        _totalDuration = duration;
        notifyListeners();
      }
    });

    // Player State Stream
    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;

      // Auto-Next bei Song-Ende
      if (state.processingState == ProcessingState.completed) {
        _handleSongCompleted();
      }

      notifyListeners();
    });

    if (kDebugMode) {
      debugPrint('🎵 SimpleMusicProvider: AudioPlayer initialisiert');
    }
  }

  /// Wählt ein Genre und lädt die Playlist
  Future<void> selectGenre(String roomId, MusicGenre genre) async {
    try {
      _isLoadingGenre = true;
      _currentGenre = genre;
      _errorMessage = null;
      notifyListeners();

      if (kDebugMode) {
        debugPrint('🎵 Genre-Auswahl: ${genre.displayName}');
      }

      // Genre-Auswahl an Cloudflare Worker senden
      final firstTrack = await _syncService.setGenre(genre);

      if (firstTrack != null) {
        // Playlist initialisieren mit Video-ID
        _playlist = [firstTrack.videoId];
        _playlistIndex = 0;
        _updateMaxVolume();

        // Ersten Song laden und abspielen
        await _loadAndPlayTrack(firstTrack);
      } else {
        throw Exception('Keine Songs für Genre ${genre.displayName} gefunden');
      }
    } catch (e) {
      _errorMessage = 'Fehler beim Laden des Genres: $e';
      if (kDebugMode) {
        debugPrint('❌ Fehler bei Genre-Auswahl: $e');
      }
    } finally {
      _isLoadingGenre = false;
      notifyListeners();
    }
  }

  /// Lädt und spielt einen Track ab
  Future<void> _loadAndPlayTrack(MusicTrack track) async {
    try {
      _currentTrack = track;
      _errorMessage = null;
      notifyListeners();

      if (kDebugMode) {
        debugPrint('🎵 Lade Track: ${track.title}');
      }

      // Audio-URL laden
      await _audioPlayer.setUrl(track.audioUrl);

      // Lautstärke setzen (respektiert maxVolume)
      final actualVolume = (_volume / 100).clamp(0.0, _maxVolume / 100);
      await _audioPlayer.setVolume(actualVolume);

      // Abspielen
      await _audioPlayer.play();

      if (kDebugMode) {
        debugPrint('✅ Track wird abgespielt: ${track.title}');
      }
    } catch (e) {
      _errorMessage = 'Fehler beim Abspielen: $e';
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Track-Laden: $e');
      }
      notifyListeners();
    }
  }

  /// Play/Pause Toggle
  Future<void> togglePlayPause() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        if (kDebugMode) {
          debugPrint('⏸️ Musik pausiert');
        }
      } else {
        await _audioPlayer.play();
        if (kDebugMode) {
          debugPrint('▶️ Musik fortgesetzt');
        }
      }
    } catch (e) {
      _errorMessage = 'Fehler bei Play/Pause: $e';
      if (kDebugMode) {
        debugPrint('❌ Fehler bei Play/Pause: $e');
      }
      notifyListeners();
    }
  }

  /// Nächster Song
  Future<void> nextSong(String roomId) async {
    try {
      if (kDebugMode) {
        debugPrint('⏭️ Nächster Song angefordert');
      }

      // Nächsten Song vom Worker abrufen
      final nextTrack = await _syncService.nextSong();

      if (nextTrack != null) {
        _playlistIndex++;
        await _loadAndPlayTrack(nextTrack);
      } else {
        _errorMessage = 'Keine weiteren Songs in der Playlist';
        if (kDebugMode) {
          debugPrint('⚠️ Ende der Playlist erreicht');
        }
      }
    } catch (e) {
      _errorMessage = 'Fehler beim Laden des nächsten Songs: $e';
      if (kDebugMode) {
        debugPrint('❌ Fehler beim nächsten Song: $e');
      }
      notifyListeners();
    }
  }

  /// Lautstärke setzen (respektiert maxVolume)
  Future<void> setVolume(int newVolume) async {
    try {
      _volume = newVolume.clamp(0, 100);

      // Tatsächliche Lautstärke respektiert maxVolume
      final actualVolume = (_volume / 100).clamp(0.0, _maxVolume / 100);
      await _audioPlayer.setVolume(actualVolume);

      if (kDebugMode) {
        debugPrint(
          '🔊 Lautstärke: $_volume% (Max: $_maxVolume%, Actual: ${(actualVolume * 100).toInt()}%)',
        );
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Setzen der Lautstärke: $e');
      }
    }
  }

  /// Seek zu bestimmter Position
  Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Seek: $e');
      }
    }
  }

  /// Song-Abschluss behandeln (Auto-Next)
  Future<void> _handleSongCompleted() async {
    if (kDebugMode) {
      debugPrint('✅ Song beendet - Auto-Next');
    }

    // Hinweis: roomId muss von außen übergeben werden
    // Für Simplified Version: einfach stoppen
    await _audioPlayer.stop();
    _isPlaying = false;
    notifyListeners();

    // TODO: In vollständiger Version automatisch nextSong() aufrufen
  }

  /// Aktualisiert maxVolume basierend auf Teilnehmer-Anzahl
  void _updateMaxVolume() {
    if (_participantCount <= 1) {
      _maxVolume = 100;
    } else if (_participantCount == 2) {
      _maxVolume = 50;
    } else {
      _maxVolume = 10; // 3+ Teilnehmer
    }

    if (kDebugMode) {
      debugPrint(
        '👥 Teilnehmer: $_participantCount → Max-Lautstärke: $_maxVolume%',
      );
    }
  }

  /// Teilnehmer-Anzahl aktualisieren (von außen aufrufbar)
  void updateParticipantCount(int count) {
    _participantCount = count;
    _updateMaxVolume();

    // Lautstärke neu anwenden mit aktualisiertem Maximum
    setVolume(_volume);
  }

  /// Musik global pausieren (z.B. für Livestream-Priorität)
  Future<void> pauseForLivestream() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
      if (kDebugMode) {
        debugPrint('⏸️ Musik pausiert für Livestream');
      }
    }
  }

  /// Musik nach Livestream wieder fortsetzen
  Future<void> resumeAfterLivestream() async {
    if (!_isPlaying && _currentTrack != null) {
      await _audioPlayer.play();
      if (kDebugMode) {
        debugPrint('▶️ Musik fortgesetzt nach Livestream');
      }
    }
  }

  /// Cleanup
  @override
  void dispose() {
    _audioPlayer.dispose();
    if (kDebugMode) {
      debugPrint('🗑️ SimpleMusicProvider disposed');
    }
    super.dispose();
  }
}
