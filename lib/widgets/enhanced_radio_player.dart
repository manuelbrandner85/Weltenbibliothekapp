import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/radio_favorites.dart';
import '../services/radio_cache_service.dart';

/// 📻 Enhanced Radio Browser Player - Professional Edition
/// Features: Favorites, History, Crossfade, Live Status, Search, Visualizer
class EnhancedRadioPlayer extends StatefulWidget {
  final int activeUserCount;
  final bool isAdmin;

  const EnhancedRadioPlayer({
    super.key,
    this.activeUserCount = 1,
    this.isAdmin = false,
  });

  @override
  State<EnhancedRadioPlayer> createState() => _EnhancedRadioPlayerState();
}

class _EnhancedRadioPlayerState extends State<EnhancedRadioPlayer>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // Audio Players
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _preloadPlayer = AudioPlayer();
  
  // Animation Controllers
  late AnimationController _pulseController;
  late AnimationController _visualizerController;
  late AnimationController _crossfadeController;
  
  // 🎵 KURATIERTE MUSIK-GENRES + SOUNDCLOUD
  static const List<Map<String, String>> _musicGenres = [
    {'name': 'soundcloud', 'display': '☁️ SoundCloud', 'color': 'FF5500'}, // SoundCloud Orange
    {'name': 'pop', 'display': '🎤 Pop', 'color': 'FF6B9D'},
    {'name': 'rock', 'display': '🎸 Rock', 'color': 'E74C3C'},
    {'name': 'classic rock', 'display': '🎸 Classic Rock', 'color': 'C0392B'},
    {'name': 'metal', 'display': '🤘 Metal', 'color': '2C3E50'},
    {'name': 'jazz', 'display': '🎷 Jazz', 'color': 'F39C12'},
    {'name': 'blues', 'display': '🎺 Blues', 'color': '3498DB'},
    {'name': 'classical', 'display': '🎻 Classical', 'color': '8E44AD'},
    {'name': 'electronic', 'display': '🎧 Electronic', 'color': '00D2FF'},
    {'name': 'dance', 'display': '💃 Dance', 'color': 'E91E63'},
    {'name': 'house', 'display': '🏠 House', 'color': '9C27B0'},
    {'name': 'techno', 'display': '⚡ Techno', 'color': 'FF5722'},
    {'name': 'trance', 'display': '🌀 Trance', 'color': '00BCD4'},
    {'name': 'hip hop', 'display': '🎤 Hip Hop', 'color': 'FF9800'},
    {'name': 'rap', 'display': '🎤 Rap', 'color': 'FFC107'},
    {'name': 'r&b', 'display': '🎵 R&B', 'color': 'FF4081'},
    {'name': 'soul', 'display': '💙 Soul', 'color': '2196F3'},
    {'name': 'funk', 'display': '🕺 Funk', 'color': 'FFEB3B'},
    {'name': 'reggae', 'display': '🌴 Reggae', 'color': '4CAF50'},
    {'name': 'country', 'display': '🤠 Country', 'color': 'A1887F'},
    {'name': 'folk', 'display': '🎻 Folk', 'color': '8D6E63'},
    {'name': 'indie', 'display': '🎨 Indie', 'color': '607D8B'},
    {'name': 'alternative', 'display': '🎸 Alternative', 'color': '9E9E9E'},
    {'name': 'ambient', 'display': '🌌 Ambient', 'color': '673AB7'},
    {'name': 'chillout', 'display': '😌 Chillout', 'color': '03A9F4'},
    {'name': 'lounge', 'display': '🍸 Lounge', 'color': 'FF5252'},
    {'name': '80s', 'display': '📻 80s', 'color': 'FF6F00'},
    {'name': '90s', 'display': '📼 90s', 'color': 'E040FB'},
    {'name': 'disco', 'display': '🪩 Disco', 'color': 'FFD740'},
    {'name': 'latin', 'display': '💃 Latin', 'color': 'FF6E40'},
    {'name': 'world', 'display': '🌍 World', 'color': '69F0AE'},
  ];
  
  // ❌ Removed unused language/country filters (gelockerte Filter-Logik)
  
  // State
  String? _selectedGenre;
  String? _currentStationName;
  String? _currentStationUrl;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _showVolumeSlider = false;
  // ❌ Removed _showGenreGrid (unused)
  bool _isExpanded = false;
  double _volume = 1.0;
  bool _isLiveStatusOnline = true;

  // Station Management
  List<Map<String, dynamic>> _currentGenreStations = [];
  Set<String> _playedStationUrls = {};
  int _currentStationIndex = 0;
  int _failedAttemptsCount = 0; // Zähler für fehlgeschlagene Versuche
  static const int _maxFailedAttempts = 5; // Max. 5 Versuche
  
  // Favorites & History
  List<String> _favoriteGenres = [];
  List<String> _recentlyPlayedGenres = [];
  
  // Voice/Ad Detection
  Timer? _voiceDetectionTimer;
  int _silentCheckCounter = 0;
  bool _isMusicPlaying = true;
  
  // Preloading
  bool _isPreloadReady = false;
  String? _preloadedStationUrl;
  
  // Crossfade
  bool _isCrossfading = false;
  
  // Search
  String _searchQuery = '';
  List<Map<String, String>> _filteredGenres = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // ✅ App Lifecycle Observer
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _visualizerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..repeat(reverse: true);
    
    _crossfadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _filteredGenres = _musicGenres;
    _setupAudioListeners();
    _loadFavoritesAndHistory();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // ✅ App Lifecycle Management - DEAKTIVIERT
    // Das Lifecycle-Handling verursachte Splash-Screen Freeze
    // Audio Player läuft im Hintergrund weiter (Android-Standard)
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    
    // ✅ Controllers zuerst disposen
    _pulseController.dispose();
    _visualizerController.dispose();
    _crossfadeController.dispose();
    _voiceDetectionTimer?.cancel();
    
    // ✅ Audio Player ASYNCHRON stoppen und disposen (verhindert Freeze)
    _audioPlayer.stop().then((_) => _audioPlayer.dispose()).catchError((e) {
      if (kDebugMode) debugPrint('Audio Player dispose error: $e');
    });
    _preloadPlayer.stop().then((_) => _preloadPlayer.dispose()).catchError((e) {
      if (kDebugMode) debugPrint('Preload Player dispose error: $e');
    });
    
    super.dispose();
  }

  Future<void> _loadFavoritesAndHistory() async {
    final favorites = await RadioFavorites.getFavorites();
    final history = await RadioFavorites.getHistory();
    
    if (mounted) {
      setState(() {
        _favoriteGenres = favorites;
        _recentlyPlayedGenres = history;
      });
    }
    
    // Auto-load letztes Genre
    final lastPlayed = await RadioFavorites.getLastPlayed();
    if (lastPlayed != null && mounted) {
      _loadGenreStations(lastPlayed['genre']!);
    }
  }

  void _setupAudioListeners() {
    _audioPlayer.playingStream.listen((playing) {
      if (mounted) {
        setState(() {
          _isPlaying = playing;
        });
        
        if (playing) {
          _startVoiceDetection();
          _preloadNextStation();
          if (!_visualizerController.isAnimating) {
            _visualizerController.repeat(reverse: true);
          }
        } else {
          _stopVoiceDetection();
          _visualizerController.stop();
        }
      }
    });

    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _playNextStationInGenre();
      }
      
      // Live Status Update
      if (mounted) {
        setState(() {
          _isLiveStatusOnline = state.processingState != ProcessingState.idle;
        });
      }
    });

    _audioPlayer.playbackEventStream.listen(
      (event) {
        if (_isPlaying && event.duration != null) {
          _checkAudioContent(event);
        }
      },
      onError: (Object e, StackTrace st) {
        if (kDebugMode) {
          debugPrint('❌ Stream-Fehler: $e');
        }
        setState(() => _isLiveStatusOnline = false);
        _playNextStationInGenre();
      },
    );
  }

  void _startVoiceDetection() {
    _voiceDetectionTimer?.cancel();
    _voiceDetectionTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!_isMusicPlaying && _silentCheckCounter > 2) {
        if (kDebugMode) {
          debugPrint('🎙️ Werbung/Sprache erkannt → Skip');
        }
        _playNextStationInGenre();
        _silentCheckCounter = 0;
      }
    });
  }

  void _stopVoiceDetection() {
    _voiceDetectionTimer?.cancel();
  }

  void _checkAudioContent(PlaybackEvent event) {
    if (event.bufferedPosition == event.duration) {
      _silentCheckCounter++;
    } else {
      _silentCheckCounter = 0;
      _isMusicPlaying = true;
    }
  }

  Future<void> _loadGenreStations(String genre) async {
    setState(() {
      _isLoading = true;
      _selectedGenre = genre;
      _currentGenreStations.clear();
      _playedStationUrls.clear();
      _currentStationIndex = 0;
      _failedAttemptsCount = 0; // Counter beim Genre-Wechsel zurücksetzen
      _isPreloadReady = false;
    });

    // Speichere in History
    await RadioFavorites.addToHistory(genre);
    _recentlyPlayedGenres = await RadioFavorites.getHistory();

    // Prüfe Cache
    final cachedStations = await RadioCacheService.getCachedStations(genre);
    if (cachedStations != null && cachedStations.isNotEmpty) {
      if (kDebugMode) {
        debugPrint('📦 Cache Hit für Genre: $genre');
      }
      setState(() {
        _currentGenreStations = cachedStations;
      });
      await _playCurrentStation();
      return;
    }

    try {
      final encodedGenre = Uri.encodeComponent(genre);
      final response = await http.get(
        Uri.parse(
          'https://de1.api.radio-browser.info/json/stations/bytag/$encodedGenre?limit=100&order=votes&hidebroken=true',
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> stations = json.decode(response.body);
        
        if (stations.isNotEmpty) {
          final uniqueStations = <String, Map<String, dynamic>>{};
          
          for (final station in stations) {
            final url = station['url_resolved'] ?? station['url'];
            if (url == null || url.toString().isEmpty) continue;
            
            final language = (station['language'] ?? '').toString().toLowerCase();
            final country = (station['country'] ?? '').toString().toLowerCase();
            final tags = (station['tags'] ?? '').toString().toLowerCase();
            final name = (station['name'] ?? '').toString().toLowerCase();
            
            final isTalkStation = tags.contains('talk') || tags.contains('news') || 
                                  tags.contains('sports') || name.contains('talk') || name.contains('news');
            
            // ✅ GELOCKERTE Filter: Musik-Genre UND kein Talk = OK (unabhängig von Land/Sprache)
            final isValidStation = !isTalkStation;
            
            if (isValidStation) {
              uniqueStations[url] = {
                'url': url,
                'name': station['name'] ?? 'Unbekannter Sender',
                'votes': station['votes'] ?? 0,
                'language': language,
                'country': country,
                'bitrate': station['bitrate'] ?? 128,
              };
            }
          }

          final sortedStations = uniqueStations.values.toList();
          sortedStations.sort((a, b) => (b['bitrate'] as int).compareTo(a['bitrate'] as int));

          setState(() {
            _currentGenreStations = sortedStations;
          });
          
          // Cache speichern
          await RadioCacheService.cacheStations(genre, sortedStations);

          if (_currentGenreStations.isNotEmpty) {
            await _playCurrentStation();
          } else {
            setState(() => _isLoading = false);
          }
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Laden: $e');
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _playCurrentStation() async {
    if (_currentGenreStations.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    // Crossfade aktivieren wenn bereits Musik läuft
    if (_isPlaying) {
      _isCrossfading = true;
      await _crossfadeController.forward();
    }

    // Preload nutzen wenn verfügbar
    if (_isPreloadReady && _preloadedStationUrl != null) {
      final preloadedStation = _currentGenreStations.firstWhere(
        (s) => s['url'] == _preloadedStationUrl,
        orElse: () => _currentGenreStations[_currentStationIndex],
      );
      
      if (_isCrossfading) {
        await _audioPlayer.setVolume(0);
      }
      
      await _audioPlayer.stop();
      await _audioPlayer.setAudioSource(_preloadPlayer.audioSource!);
      await _audioPlayer.play();
      
      if (_isCrossfading) {
        await _crossfadeController.reverse();
        await _audioPlayer.setVolume(_volume);
        _isCrossfading = false;
      }
      
      _updateVolume();
      
      setState(() {
        _currentStationName = preloadedStation['name'];
        _currentStationUrl = preloadedStation['url'];
        _isLoading = false;
        _isMusicPlaying = true;
        _silentCheckCounter = 0;
        _isPreloadReady = false;
        _isLiveStatusOnline = true;
        _failedAttemptsCount = 0; // Erfolg: Counter zurücksetzen
      });
      
      await RadioFavorites.saveLastPlayed(_selectedGenre!, preloadedStation['name']);
      _currentStationIndex++;
      _preloadNextStation();
      return;
    }

    while (_currentStationIndex < _currentGenreStations.length) {
      final station = _currentGenreStations[_currentStationIndex];
      final streamUrl = station['url'] as String;

      if (_playedStationUrls.contains(streamUrl)) {
        _currentStationIndex++;
        continue;
      }

      try {
        setState(() => _isLoading = true);
        _playedStationUrls.add(streamUrl);

        if (_isCrossfading) {
          await _audioPlayer.setVolume(0);
        }

        await _audioPlayer.setUrl(streamUrl).timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw TimeoutException('Timeout'),
        );

        await _audioPlayer.play();
        
        if (_isCrossfading) {
          await _crossfadeController.reverse();
          _isCrossfading = false;
        }
        
        _updateVolume();

        setState(() {
          _currentStationName = station['name'];
          _currentStationUrl = streamUrl;
          _isLoading = false;
          _isMusicPlaying = true;
          _silentCheckCounter = 0;
          _isLiveStatusOnline = true;
          _failedAttemptsCount = 0; // Erfolg: Counter zurücksetzen
        });
        
        await RadioFavorites.saveLastPlayed(_selectedGenre!, station['name']);
        return;

      } catch (e) {
        _currentStationIndex++;
      }
    }

    if (_currentStationIndex >= _currentGenreStations.length) {
      _failedAttemptsCount++;
      
      if (_failedAttemptsCount >= _maxFailedAttempts) {
        // Nach 5 erfolglosen Durchläufen: Abbruch
        if (kDebugMode) {
          debugPrint('⚠️ Alle Sender fehlgeschlagen nach $_maxFailedAttempts Versuchen');
        }
        setState(() {
          _isLoading = false;
          _currentStationName = 'Keine Sender verfügbar';
          _isLiveStatusOnline = false;
        });
        return;
      }
      
      // Neuer Durchlauf mit zurückgesetztem Index
      _currentStationIndex = 0;
      _playedStationUrls.clear();
      await _playCurrentStation();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _preloadNextStation() async {
    if (_currentGenreStations.isEmpty) return;
    
    final nextIndex = (_currentStationIndex + 1) % _currentGenreStations.length;
    final nextStation = _currentGenreStations[nextIndex];
    final nextUrl = nextStation['url'] as String;
    
    try {
      await _preloadPlayer.setUrl(nextUrl).timeout(const Duration(seconds: 5));
      setState(() {
        _isPreloadReady = true;
        _preloadedStationUrl = nextUrl;
      });
    } catch (e) {
      setState(() {
        _isPreloadReady = false;
        _preloadedStationUrl = null;
      });
    }
  }

  Future<void> _playNextStationInGenre() async {
    if (_currentGenreStations.isEmpty) return;
    _currentStationIndex++;
    if (_currentStationIndex >= _currentGenreStations.length) {
      _currentStationIndex = 0;
      _playedStationUrls.clear();
    }
    await _playCurrentStation();
  }

  void _updateVolume() {
    // ✅ NEUE LOGIK: Livestream → 5%, User kann selbst regeln
    if (widget.isAdmin) {
      // Admin kann immer volle Kontrolle
      _audioPlayer.setVolume(_volume);
      return;
    }

    double targetVolume;
    if (widget.activeUserCount == 1) {
      // Kein Livestream → Volle Lautstärke
      targetVolume = 1.0;
    } else if (widget.activeUserCount >= 2) {
      // Livestream aktiv → 5% (User kann im UI anpassen)
      targetVolume = 0.05;
    } else {
      targetVolume = 1.0;
    }

    setState(() => _volume = targetVolume);
    _audioPlayer.setVolume(targetVolume);
  }

  void _filterGenres(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredGenres = _musicGenres;
      } else {
        _filteredGenres = _musicGenres
            .where((g) => g['display']!.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _toggleFavorite(String genre) async {
    await RadioFavorites.toggleFavorite(genre);
    _favoriteGenres = await RadioFavorites.getFavorites();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _isExpanded ? 350 : 70,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF9B59B6).withValues(alpha: 0.95),
            const Color(0xFF8E44AD).withValues(alpha: 0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: _isExpanded ? _buildExpandedView() : _buildCompactView(),
      ),
    );
  }

  Widget _buildCompactView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _buildGenreButton(),
          const SizedBox(width: 8),
          Expanded(child: _buildStationInfo()),
          _buildExpandButton(),
          const SizedBox(width: 4),
          _buildPlayPauseButton(),
          const SizedBox(width: 4),
          _buildVolumeControl(),
        ],
      ),
    );
  }

  Widget _buildExpandedView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header mit Collapse Button
          Row(
            children: [
              Expanded(child: _buildStationInfo()),
              _buildExpandButton(),
            ],
          ),
          const SizedBox(height: 12),
          
          // Suchfeld
          TextField(
            onChanged: _filterGenres,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: '🔍 Genre suchen...',
              hintStyle: const TextStyle(color: Colors.white60),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.search, color: Colors.white70),
            ),
          ),
          const SizedBox(height: 12),
          
          // Favoriten Section
          if (_favoriteGenres.isNotEmpty) ...[
            const Text(
              '⭐ Favoriten',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildFavoriteGenres(),
            const SizedBox(height: 12),
          ],
          
          // Zuletzt gespielt
          if (_recentlyPlayedGenres.isNotEmpty) ...[
            const Text(
              '📜 Zuletzt gespielt',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildRecentGenres(),
            const SizedBox(height: 12),
          ],
          
          // Genre Grid
          const Text(
            '🎵 Alle Genres',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildGenreGrid(),
        ],
      ),
    );
  }

  Widget _buildGenreButton() {
    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.library_music, color: Colors.white, size: 18),
            if (_selectedGenre != null) ...[
              const SizedBox(width: 6),
              Text(
                _musicGenres.firstWhere((g) => g['name'] == _selectedGenre)['display']!,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStationInfo() {
    if (_isLoading) {
      return const Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
          ),
          const SizedBox(width: 8),
          Text('Lädt...', style: TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      );
    }

    if (_currentStationName == null) {
      return const Text(
        '🎵 Wähle ein Genre',
        style: TextStyle(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic),
      );
    }

    return Row(
      children: [
        // Live Status
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _isLiveStatusOnline ? Colors.green : Colors.red,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        
        // Pulse Indikator
        if (_isPlaying)
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withValues(
                    alpha: 0.5 + (_pulseController.value * 0.5),
                  ),
                  shape: BoxShape.circle,
                ),
              );
            },
          ),
        if (_isPlaying) const SizedBox(width: 8),
        
        // Station Name
        Expanded(
          child: Text(
            _currentStationName!,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildExpandButton() {
    return IconButton(
      icon: Icon(
        _isExpanded ? Icons.expand_more : Icons.expand_less,
        color: Colors.white,
        size: 20,
      ),
      onPressed: () => setState(() => _isExpanded = !_isExpanded),
    );
  }

  Widget _buildPlayPauseButton() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 22),
        onPressed: () async {
          if (_isPlaying) {
            await _audioPlayer.pause();
          } else {
            if (_selectedGenre != null && _currentGenreStations.isNotEmpty) {
              await _audioPlayer.play();
            } else if (_musicGenres.isNotEmpty) {
              await _loadGenreStations(_musicGenres.first['name']!);
            }
          }
        },
      ),
    );
  }

  Widget _buildVolumeControl() {
    return GestureDetector(
      onTap: () => setState(() => _showVolumeSlider = !_showVolumeSlider),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _volume > 0.5 ? Icons.volume_up : _volume > 0 ? Icons.volume_down : Icons.volume_off,
              color: Colors.white,
              size: 20,
            ),
          ),
          if (_showVolumeSlider) _buildVolumeSliderPopup(),
        ],
      ),
    );
  }

  Widget _buildVolumeSliderPopup() {
    String tooltip = widget.isAdmin
        ? 'Admin: Volle Kontrolle'
        : widget.activeUserCount == 1
            ? 'Keine Livestream'
            : widget.activeUserCount >= 2
                ? 'Livestream: 0-100%'
                : 'Normal';

    return Positioned(
      right: 0,
      bottom: 50,
      child: Container(
        width: 50,
        height: 180,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Tooltip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                tooltip,
                style: const TextStyle(color: Colors.white70, fontSize: 8),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            
            Text(
              '${(_volume * 100).toInt()}%',
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: RotatedBox(
                  quarterTurns: 3,
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    ),
                    child: Slider(
                      value: _volume,
                      min: 0,
                      max: 1,
                      activeColor: const Color(0xFFFFD700),
                      inactiveColor: Colors.white30,
                      // ✅ ALLE User können Lautstärke regeln (0-100%)
                      onChanged: (value) {
                        setState(() => _volume = value);
                        _audioPlayer.setVolume(value);
                      },
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Icon(
              widget.isAdmin ? Icons.admin_panel_settings : Icons.people,
              color: widget.isAdmin ? const Color(0xFFFFD700) : Colors.white54,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteGenres() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _favoriteGenres.length,
        itemBuilder: (context, index) {
          final genreName = _favoriteGenres[index];
          final genre = _musicGenres.firstWhere((g) => g['name'] == genreName);
          return _buildGenreChip(genre, isFavorite: true);
        },
      ),
    );
  }

  Widget _buildRecentGenres() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _recentlyPlayedGenres.take(5).length,
        itemBuilder: (context, index) {
          final genreName = _recentlyPlayedGenres[index];
          final genre = _musicGenres.firstWhere((g) => g['name'] == genreName);
          return _buildGenreChip(genre);
        },
      ),
    );
  }

  Widget _buildGenreGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _filteredGenres.length,
      itemBuilder: (context, index) {
        return _buildGenreChip(_filteredGenres[index]);
      },
    );
  }

  Widget _buildGenreChip(Map<String, String> genre, {bool isFavorite = false}) {
    final isSelected = _selectedGenre == genre['name'];
    final isFav = _favoriteGenres.contains(genre['name']);
    final genreName = genre['name']!;
    final genreDisplay = genre['display']!;
    
    return GestureDetector(
      onTap: () {
        _loadGenreStations(genreName);
        setState(() => _isExpanded = false);
      },
      onLongPress: () => _toggleFavorite(genreName),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isFav)
              const Icon(Icons.star, color: Color(0xFFFFD700), size: 12),
            if (isFav) const SizedBox(width: 4),
            Text(
              genre['display']!,
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(EnhancedRadioPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeUserCount != widget.activeUserCount ||
        oldWidget.isAdmin != widget.isAdmin) {
      _updateVolume();
    }
  }
}
