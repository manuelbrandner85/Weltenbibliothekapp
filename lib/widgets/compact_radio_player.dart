import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// 📻 Kompakter Radio Browser Player für Musik-Chat
/// Design: Schmale, attraktive Top-Leiste die den Chat nicht stört
class CompactRadioPlayer extends StatefulWidget {
  final int activeUserCount;
  final bool isAdmin;

  const CompactRadioPlayer({
    super.key,
    this.activeUserCount = 1,
    this.isAdmin = false,
  });

  @override
  State<CompactRadioPlayer> createState() => _CompactRadioPlayerState();
}

class _CompactRadioPlayerState extends State<CompactRadioPlayer>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _preloadPlayer = AudioPlayer(); // 🚀 Preload nächster Sender
  
  // 🎵 KURATIERTE MUSIK-GENRES (basierend auf radio-browser.info)
  static const List<Map<String, String>> _musicGenres = [
    {'name': 'pop', 'display': '🎤 Pop'},
    {'name': 'rock', 'display': '🎸 Rock'},
    {'name': 'classic rock', 'display': '🎸 Classic Rock'},
    {'name': 'metal', 'display': '🤘 Metal'},
    {'name': 'jazz', 'display': '🎷 Jazz'},
    {'name': 'blues', 'display': '🎺 Blues'},
    {'name': 'classical', 'display': '🎻 Classical'},
    {'name': 'electronic', 'display': '🎧 Electronic'},
    {'name': 'dance', 'display': '💃 Dance'},
    {'name': 'house', 'display': '🏠 House'},
    {'name': 'techno', 'display': '⚡ Techno'},
    {'name': 'trance', 'display': '🌀 Trance'},
    {'name': 'hip hop', 'display': '🎤 Hip Hop'},
    {'name': 'rap', 'display': '🎤 Rap'},
    {'name': 'r&b', 'display': '🎵 R&B'},
    {'name': 'soul', 'display': '💙 Soul'},
    {'name': 'funk', 'display': '🕺 Funk'},
    {'name': 'reggae', 'display': '🌴 Reggae'},
    {'name': 'country', 'display': '🤠 Country'},
    {'name': 'folk', 'display': '🎻 Folk'},
    {'name': 'indie', 'display': '🎨 Indie'},
    {'name': 'alternative', 'display': '🎸 Alternative'},
    {'name': 'ambient', 'display': '🌌 Ambient'},
    {'name': 'chillout', 'display': '😌 Chillout'},
    {'name': 'lounge', 'display': '🍸 Lounge'},
    {'name': '80s', 'display': '📻 80s'},
    {'name': '90s', 'display': '📼 90s'},
    {'name': 'disco', 'display': '🪩 Disco'},
    {'name': 'latin', 'display': '💃 Latin'},
    {'name': 'world', 'display': '🌍 World'},
  ];
  
  // 🌍 Erlaubte Sprachen: Deutsch, Englisch, US
  static const List<String> _allowedLanguages = [
    'german', 'deutsch', 'de',
    'english', 'en', 
    'american', 'us', 'usa'
  ];
  
  // 🌍 Erlaubte Länder
  static const List<String> _allowedCountries = [
    'germany', 'deutschland', 'de',
    'united kingdom', 'uk', 'gb', 'england',
    'united states', 'usa', 'us', 'america'
  ];
  
  String? _selectedGenre;
  String? _currentStationName;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _showVolumeSlider = false;
  double _volume = 1.0;
  late AnimationController _pulseController;

  // 🔄 Station Management für aktuelles Genre
  List<Map<String, dynamic>> _currentGenreStations = [];
  Set<String> _playedStationUrls = {};
  int _currentStationIndex = 0;
  
  // 🎙️ Voice/Ad Detection
  Timer? _voiceDetectionTimer;
  int _silentCheckCounter = 0;
  bool _isMusicPlaying = true;
  
  // 🚀 Preloading
  bool _isPreloadReady = false;
  String? _preloadedStationUrl;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _setupAudioListeners();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _voiceDetectionTimer?.cancel();
    _audioPlayer.dispose();
    _preloadPlayer.dispose();
    super.dispose();
  }

  void _setupAudioListeners() {
    _audioPlayer.playingStream.listen((playing) {
      if (mounted) {
        setState(() {
          _isPlaying = playing;
        });
        
        if (playing) {
          _startVoiceDetection();
          // 🚀 Preload nächsten Sender während aktueller läuft
          _preloadNextStation();
        } else {
          _stopVoiceDetection();
        }
      }
    });

    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _playNextStationInGenre();
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
          debugPrint('❌ Stream-Fehler erkannt: $e');
          debugPrint('🔄 Überspringe zum nächsten Sender...');
        }
        _playNextStationInGenre();
      },
    );
  }

  void _startVoiceDetection() {
    _voiceDetectionTimer?.cancel();
    _voiceDetectionTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!_isMusicPlaying && _silentCheckCounter > 2) {
        if (kDebugMode) {
          debugPrint('🎙️ Mögliche Werbung/Sprache erkannt → Skip');
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

  /// 🎵 Lade alle Sender für gewähltes Genre
  Future<void> _loadGenreStations(String genre) async {
    setState(() {
      _isLoading = true;
      _selectedGenre = genre;
      _currentGenreStations.clear();
      _playedStationUrls.clear();
      _currentStationIndex = 0;
      _isPreloadReady = false;
    });

    try {
      final encodedGenre = Uri.encodeComponent(genre);
      
      // 🌍 KRITISCH: Lade nur deutsche, englische und US-Sender
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
            
            // 🌍 Sprach- und Länder-Filter
            final language = (station['language'] ?? '').toString().toLowerCase();
            final country = (station['country'] ?? '').toString().toLowerCase();
            final tags = (station['tags'] ?? '').toString().toLowerCase();
            final name = (station['name'] ?? '').toString().toLowerCase();
            
            // Prüfe Sprache
            final hasAllowedLanguage = _allowedLanguages.any(
              (lang) => language.contains(lang)
            );
            
            // Prüfe Land
            final hasAllowedCountry = _allowedCountries.any(
              (countryCode) => country.contains(countryCode)
            );
            
            // Filtere Talk/News/Sports aus
            final isTalkStation = tags.contains('talk') || 
                                  tags.contains('news') || 
                                  tags.contains('sports') ||
                                  name.contains('talk') ||
                                  name.contains('news');
            
            // Nur Sender mit erlaubter Sprache ODER erlaubtem Land
            if ((hasAllowedLanguage || hasAllowedCountry) && !isTalkStation) {
              uniqueStations[url] = {
                'url': url,
                'name': station['name'] ?? 'Unbekannter Sender',
                'votes': station['votes'] ?? 0,
                'language': language,
                'country': country,
                'bitrate': station['bitrate'] ?? 128, // Für Qualitäts-Sortierung
              };
            }
          }

          // Sortiere nach Bitrate (höher = besser) für schnelleres Buffering
          final sortedStations = uniqueStations.values.toList();
          sortedStations.sort((a, b) => (b['bitrate'] as int).compareTo(a['bitrate'] as int));

          setState(() {
            _currentGenreStations = sortedStations;
          });

          if (_currentGenreStations.isNotEmpty) {
            await _playCurrentStation();
          } else {
            if (kDebugMode) {
              debugPrint('⚠️ Keine DE/EN/US Musik-Sender für Genre "$genre" gefunden');
            }
            setState(() => _isLoading = false);
          }
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Laden der Sender: $e');
      }
      setState(() => _isLoading = false);
    }
  }

  /// 🎵 Spiele aktuellen Sender ab
  Future<void> _playCurrentStation() async {
    if (_currentGenreStations.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    // 🚀 OPTIMIERUNG: Nutze preloaded Station wenn verfügbar
    if (_isPreloadReady && _preloadedStationUrl != null) {
      final preloadedStation = _currentGenreStations.firstWhere(
        (s) => s['url'] == _preloadedStationUrl,
        orElse: () => _currentGenreStations[_currentStationIndex],
      );
      
      if (kDebugMode) {
        debugPrint('⚡ Nutze preloaded Station: ${preloadedStation['name']}');
      }
      
      // Tausche Player (nahtloser Übergang)
      await _audioPlayer.stop();
      await _audioPlayer.setAudioSource(_preloadPlayer.audioSource!);
      await _audioPlayer.play();
      
      _updateVolume();
      
      setState(() {
        _currentStationName = preloadedStation['name'];
        _isLoading = false;
        _isMusicPlaying = true;
        _silentCheckCounter = 0;
        _isPreloadReady = false;
      });
      
      _currentStationIndex++;
      _preloadNextStation();
      return;
    }

    // Standard-Playback (kein Preload)
    while (_currentStationIndex < _currentGenreStations.length) {
      final station = _currentGenreStations[_currentStationIndex];
      final streamUrl = station['url'] as String;

      if (_playedStationUrls.contains(streamUrl)) {
        _currentStationIndex++;
        continue;
      }

      try {
        if (kDebugMode) {
          debugPrint('🎵 Starte: ${station['name']} (${station['language']}, ${station['country']})');
        }

        setState(() => _isLoading = true);
        _playedStationUrls.add(streamUrl);

        // Schnelleres Timeout (5 Sekunden statt 10)
        await _audioPlayer.setUrl(streamUrl).timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw TimeoutException('Stream timeout'),
        );

        await _audioPlayer.play();
        _updateVolume();

        setState(() {
          _currentStationName = station['name'];
          _isLoading = false;
          _isMusicPlaying = true;
          _silentCheckCounter = 0;
        });

        if (kDebugMode) {
          debugPrint('✅ Sender gestartet: ${station['name']}');
        }

        return;

      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Fehler: ${station['name']}: $e');
        }
        _currentStationIndex++;
      }
    }

    if (_currentStationIndex >= _currentGenreStations.length) {
      _currentStationIndex = 0;
      _playedStationUrls.clear();
      await _playCurrentStation();
    } else {
      setState(() => _isLoading = false);
    }
  }

  /// 🚀 Preload nächsten Sender im Hintergrund
  Future<void> _preloadNextStation() async {
    if (_currentGenreStations.isEmpty) return;
    
    final nextIndex = (_currentStationIndex + 1) % _currentGenreStations.length;
    final nextStation = _currentGenreStations[nextIndex];
    final nextUrl = nextStation['url'] as String;
    
    try {
      if (kDebugMode) {
        debugPrint('🔄 Preloading: ${nextStation['name']}');
      }
      
      await _preloadPlayer.setUrl(nextUrl).timeout(
        const Duration(seconds: 5),
      );
      
      setState(() {
        _isPreloadReady = true;
        _preloadedStationUrl = nextUrl;
      });
      
      if (kDebugMode) {
        debugPrint('✅ Preload bereit: ${nextStation['name']}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Preload fehlgeschlagen: $e');
      }
      setState(() {
        _isPreloadReady = false;
        _preloadedStationUrl = null;
      });
    }
  }

  /// 🎵 Nächster Sender im aktuellen Genre
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
    if (widget.isAdmin) {
      _audioPlayer.setVolume(_volume);
      return;
    }

    double targetVolume;
    if (widget.activeUserCount == 1) {
      targetVolume = 1.0;
    } else if (widget.activeUserCount == 2) {
      targetVolume = 0.5;
    } else {
      targetVolume = 0.1;
    }

    setState(() {
      _volume = targetVolume;
    });
    _audioPlayer.setVolume(targetVolume);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              _buildCompactGenreSelector(),
              const SizedBox(width: 8),
              Expanded(child: _buildStationInfo()),
              _buildPlayPauseButton(),
              const SizedBox(width: 4),
              _buildVolumeControl(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactGenreSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: _selectedGenre,
        hint: const Icon(Icons.library_music, color: Colors.white, size: 20),
        dropdownColor: const Color(0xFF1A1A2E),
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 20),
        items: _musicGenres.map((genre) {
          return DropdownMenuItem<String>(
            value: genre['name'],
            child: Text(
              genre['display']!,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            _loadGenreStations(value);
          }
        },
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
          SizedBox(width: 8),
          Text('Lädt...', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
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
        if (_isPlaying)
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.5 + (_pulseController.value * 0.5)),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                      blurRadius: 4 + (_pulseController.value * 4),
                      spreadRadius: _pulseController.value * 2,
                    ),
                  ],
                ),
              );
            },
          ),
        if (_isPlaying) const SizedBox(width: 8),
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
          if (_showVolumeSlider)
            Positioned(
              right: 0,
              bottom: 50,
              child: Container(
                width: 50,
                height: 150,
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
                    Text('${(_volume * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
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
                            onChanged: widget.isAdmin ? (value) {
                              setState(() => _volume = value);
                              _audioPlayer.setVolume(value);
                            } : null,
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
            ),
        ],
      ),
    );
  }

  @override
  void didUpdateWidget(CompactRadioPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeUserCount != widget.activeUserCount ||
        oldWidget.isAdmin != widget.isAdmin) {
      _updateVolume();
    }
  }
}
