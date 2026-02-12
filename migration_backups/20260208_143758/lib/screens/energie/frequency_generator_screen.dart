import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../models/frequency_preset.dart';
import '../../services/frequency_player_service.dart';
import '../../services/haptic_service.dart';
import 'package:audioplayers/audioplayers.dart';

/// 🎵 FREQUENCY GENERATOR - Heilende Klänge & Frequenzen
class FrequencyGeneratorScreen extends StatefulWidget {
  const FrequencyGeneratorScreen({super.key});

  @override
  State<FrequencyGeneratorScreen> createState() => _FrequencyGeneratorScreenState();
}

class _FrequencyGeneratorScreenState extends State<FrequencyGeneratorScreen> with SingleTickerProviderStateMixin {
  String _selectedCategory = 'solfeggio';
  FrequencyPreset? _activePreset;
  bool _isPlaying = false;
  late AnimationController _pulseController;
  final TextEditingController _searchController = TextEditingController();
  List<FrequencyPreset> _filteredPresets = [];
  
  // Real audio player for Solfeggio frequencies
  final AudioPlayer _audioPlayer = AudioPlayer();
  final double _volume = 0.7;

  @override
  void initState() {
    super.initState();
    _filteredPresets = FrequencyPreset.getByCategory(_selectedCategory);
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // Listen to play state changes
    FrequencyPlayerService.playStateStream.listen((isPlaying) {
      if (mounted) {
        setState(() {
          _isPlaying = isPlaying;
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _searchController.dispose();
    _audioPlayer.dispose();
    // Call stop without await (dispose must be synchronous)
    FrequencyPlayerService.stop().then((_) {
      if (kDebugMode) {
        debugPrint('🎵 Frequency player stopped in dispose');
      }
    });
    super.dispose();
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _searchController.clear();
      _filteredPresets = FrequencyPreset.getByCategory(category);
    });
    HapticService.selectionClick();
  }

  void _searchPresets(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPresets = FrequencyPreset.getByCategory(_selectedCategory);
      } else {
        _filteredPresets = FrequencyPreset.searchByKeyword(query);
      }
    });
  }

  Future<void> _playPreset(FrequencyPreset preset) async {
    // If same preset is playing, toggle pause/resume
    if (_activePreset?.id == preset.id && _isPlaying) {
      await _pausePlayback();
      return;
    }
    
    // If different preset, stop current and play new
    if (_activePreset != null) {
      await _stopPlayback();
    }
    
    setState(() {
      _activePreset = preset;
      _isPlaying = false;  // Will be set to true after successful load
    });
    
    // Check if we have real audio file for Solfeggio or Chakra or Planetary frequencies
    if ((preset.category == 'solfeggio' || preset.category == 'chakra' || preset.category == 'planetary') && _hasAudioFile(preset)) {
      await _playAudioFile(preset);
    } else if (preset.category == 'binaural') {
      // Binaural beats need base frequency
      await FrequencyPlayerService.playBinaural(200.0, preset.frequency);
      setState(() => _isPlaying = true);
    } else {
      await FrequencyPlayerService.play(preset.frequency);
      setState(() => _isPlaying = true);
    }
    
    HapticService.mediumImpact();
    
    if (mounted && _isPlaying) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${preset.icon} ${preset.name} spielt jetzt'),
          duration: const Duration(seconds: 2),
          backgroundColor: _getCategoryColor(_selectedCategory),
        ),
      );
    }
  }
  
  Future<void> _pausePlayback() async {
    await _audioPlayer.pause();
    await FrequencyPlayerService.stop();
    setState(() => _isPlaying = false);
    HapticService.lightImpact();
  }
  
  Future<void> _resumePlayback() async {
    await _audioPlayer.resume();
    setState(() => _isPlaying = true);
    HapticService.lightImpact();
  }
  
  bool _hasAudioFile(FrequencyPreset preset) {
    // Solfeggio & Chakra frequencies (use integer Hz)
    if (preset.category == 'solfeggio' || preset.category == 'chakra') {
      final freqInt = preset.frequency.round();
      return [174, 285, 396, 417, 432, 528, 639, 741, 852, 963].contains(freqInt);
    }
    
    // Planetary frequencies (use planet ID)
    if (preset.category == 'planetary') {
      return ['sun', 'moon', 'earth', 'mercury', 'venus', 'mars', 'jupiter', 'saturn']
          .any((planet) => preset.id.contains(planet));
    }
    
    return false;
  }
  
  Future<void> _playAudioFile(FrequencyPreset preset) async {
    try {
      String audioPath;
      
      // Determine audio file path based on category
      if (preset.category == 'planetary') {
        // Extract planet name from ID (e.g., 'planet_sun' -> 'sun')
        final planetName = preset.id.replaceAll('planet_', '');
        final freqCode = (preset.frequency * 100).round();
        audioPath = 'audio/frequency_${planetName}_$freqCode.mp3';
      } else {
        // Solfeggio & Chakra use integer Hz
        final freqInt = preset.frequency.round();
        audioPath = 'audio/frequency_${freqInt}hz.mp3';
      }
      
      // Stop any currently playing audio first
      await _audioPlayer.stop();
      
      await _audioPlayer.setVolume(_volume);
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource(audioPath));
      
      setState(() => _isPlaying = true);
      
      if (kDebugMode) {
        debugPrint('✅ Playing real audio: $audioPath');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Audio playback error: $e');
      }
      setState(() => _isPlaying = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Audio konnte nicht geladen werden: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopPlayback() async {
    await _audioPlayer.stop();
    await FrequencyPlayerService.stop();
    setState(() {
      _activePreset = null;
      _isPlaying = false;
    });
    HapticService.lightImpact();
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'solfeggio':
        return const Color(0xFF9C27B0);
      case 'chakra':
        return const Color(0xFFE91E63);
      case 'planetary':
        return const Color(0xFF3F51B5);
      case 'binaural':
        return const Color(0xFF00BCD4);
      default:
        return const Color(0xFF9C27B0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _getCategoryColor(_selectedCategory).withValues(alpha: 0.2),
              const Color(0xFF0A0A0A),
              const Color(0xFF000000),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),
              
              // Search Bar
              _buildSearchBar(),
              
              // Category Tabs
              _buildCategoryTabs(),
              
              const SizedBox(height: 16),
              
              // Active Preset Display
              if (_activePreset != null) _buildActivePreset(),
              
              // Preset List
              Expanded(
                child: _buildPresetList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FREQUENCY GENERATOR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Heilende Klänge & Frequenzen',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _getCategoryColor(_selectedCategory).withValues(alpha: 0.6 + _pulseController.value * 0.4),
                      _getCategoryColor(_selectedCategory).withValues(alpha: 0.0),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    _isPlaying ? Icons.music_note : Icons.music_off,
                    color: _isPlaying ? _getCategoryColor(_selectedCategory) : Colors.white54,
                    size: 24,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        onChanged: _searchPresets,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Suche nach Frequenz, Nutzen oder Keyword...',
          hintStyle: const TextStyle(color: Colors.white38),
          prefixIcon: const Icon(Icons.search, color: Colors.white54),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white54),
                  onPressed: () {
                    _searchController.clear();
                    _searchPresets('');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    final categories = [
      {'id': 'solfeggio', 'label': 'Solfeggio', 'icon': '🎵'},
      {'id': 'chakra', 'label': 'Chakren', 'icon': '🧘'},
      {'id': 'planetary', 'label': 'Planeten', 'icon': '🪐'},
      {'id': 'binaural', 'label': 'Binaural', 'icon': '🎧'},
    ];

    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isActive = _selectedCategory == category['id'];
          
          return GestureDetector(
            onTap: () => _selectCategory(category['id']!),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: isActive
                    ? LinearGradient(
                        colors: [
                          _getCategoryColor(category['id']!),
                          _getCategoryColor(category['id']!).withValues(alpha: 0.6),
                        ],
                      )
                    : null,
                color: isActive ? null : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive
                      ? _getCategoryColor(category['id']!)
                      : Colors.white.withValues(alpha: 0.1),
                  width: isActive ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    category['icon']!,
                    style: TextStyle(
                      fontSize: 20,
                      color: isActive ? Colors.white : Colors.white54,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    category['label']!,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.white54,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActivePreset() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getCategoryColor(_selectedCategory).withValues(alpha: 0.3),
            _getCategoryColor(_selectedCategory).withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getCategoryColor(_selectedCategory),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _getCategoryColor(_selectedCategory).withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getCategoryColor(_selectedCategory).withValues(alpha: 0.2),
                ),
                child: Center(
                  child: Text(
                    _activePreset!.icon,
                    style: const TextStyle(fontSize: 30),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _activePreset!.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_activePreset!.frequency.toStringAsFixed(2)} Hz',
                      style: TextStyle(
                        color: _getCategoryColor(_selectedCategory),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _isPlaying ? Icons.pause_circle : Icons.play_circle,
                      color: Colors.white,
                      size: 40,
                    ),
                    onPressed: () {
                      if (_isPlaying) {
                        _pausePlayback();
                      } else if (_activePreset != null) {
                        _resumePlayback();
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.stop_circle,
                      color: Colors.red,
                      size: 40,
                    ),
                    onPressed: _stopPlayback,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _activePreset!.benefit,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getCategoryColor(_selectedCategory).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Empfohlen: ${FrequencyPlayerService.getRecommendedDuration(_activePreset!.frequency)} Min',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetList() {
    if (_filteredPresets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Keine Frequenzen gefunden',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredPresets.length,
      itemBuilder: (context, index) {
        final preset = _filteredPresets[index];
        final isActive = _activePreset?.id == preset.id;

        return GestureDetector(
          onTap: () => _playPreset(preset),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: isActive
                  ? LinearGradient(
                      colors: [
                        _getCategoryColor(preset.category).withValues(alpha: 0.2),
                        _getCategoryColor(preset.category).withValues(alpha: 0.1),
                      ],
                    )
                  : null,
              color: isActive ? null : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive
                    ? _getCategoryColor(preset.category)
                    : Colors.white.withValues(alpha: 0.1),
                width: isActive ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getCategoryColor(preset.category).withValues(alpha: 0.2),
                  ),
                  child: Center(
                    child: Text(
                      preset.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        preset.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        preset.description,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        preset.benefit,
                        style: TextStyle(
                          color: _getCategoryColor(preset.category).withValues(alpha: 0.8),
                          fontSize: 11,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    Text(
                      '${preset.frequency.toStringAsFixed(preset.frequency < 100 ? 1 : 0)} Hz',
                      style: TextStyle(
                        color: _getCategoryColor(preset.category),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isActive && _isPlaying)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getCategoryColor(preset.category),
                          boxShadow: [
                            BoxShadow(
                              color: _getCategoryColor(preset.category),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
