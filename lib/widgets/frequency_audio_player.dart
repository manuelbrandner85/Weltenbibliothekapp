import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

/// 🎵 FREQUENCY AUDIO PLAYER WIDGET
/// Plays healing frequency audio files (432 Hz, 528 Hz, etc.)
class FrequencyAudioPlayer extends StatefulWidget {
  final String frequencyHz;
  final Color accentColor;
  final int durationMinutes;
  
  const FrequencyAudioPlayer({
    super.key,
    required this.frequencyHz,
    required this.accentColor,
    required this.durationMinutes,
  });

  @override
  State<FrequencyAudioPlayer> createState() => _FrequencyAudioPlayerState();
}

class _FrequencyAudioPlayerState extends State<FrequencyAudioPlayer> with SingleTickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  double _volume = 0.7;
  
  Timer? _sessionTimer;
  int _remainingSeconds = 0;
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Pulse animation for playing state
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // Audio player listeners
    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() => _totalDuration = duration);
      }
    });
    
    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() => _currentPosition = position);
      }
    });
    
    _audioPlayer.onPlayerComplete.listen((_) {
      // Loop the audio
      _audioPlayer.seek(Duration.zero);
      _audioPlayer.resume();
    });
    
    // Initialize session timer
    _remainingSeconds = widget.durationMinutes * 60;
  }
  
  @override
  void dispose() {
    _audioPlayer.dispose();
    _sessionTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }
  
  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
      _pulseController.stop();
      _sessionTimer?.cancel();
      setState(() => _isPlaying = false);
    } else {
      await _playFrequency();
    }
  }
  
  Future<void> _playFrequency() async {
    setState(() => _isLoading = true);
    
    try {
      // Map frequency to audio file (all Solfeggio frequencies)
      String audioPath;
      switch (widget.frequencyHz) {
        case '396':
          audioPath = 'assets/audio/frequency_396hz.mp3';
          break;
        case '417':
          audioPath = 'assets/audio/frequency_417hz.mp3';
          break;
        case '432':
          audioPath = 'assets/audio/frequency_432hz.mp3';
          break;
        case '528':
          audioPath = 'assets/audio/frequency_528hz.mp3';
          break;
        case '639':
          audioPath = 'assets/audio/frequency_639hz.mp3';
          break;
        case '741':
          audioPath = 'assets/audio/frequency_741hz.mp3';
          break;
        case '852':
          audioPath = 'assets/audio/frequency_852hz.mp3';
          break;
        case '963':
          audioPath = 'assets/audio/frequency_963hz.mp3';
          break;
        default:
          // Fallback to 432 Hz
          audioPath = 'assets/audio/frequency_432hz.mp3';
      }
      
      await _audioPlayer.setVolume(_volume);
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource(audioPath.replaceFirst('assets/', '')));
      
      _pulseController.repeat(reverse: true);
      
      // Start session timer
      _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _remainingSeconds--;
            if (_remainingSeconds <= 0) {
              _stopSession();
            }
          });
        }
      });
      
      setState(() {
        _isPlaying = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Fehler beim Abspielen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _stopSession() async {
    await _audioPlayer.stop();
    _sessionTimer?.cancel();
    _pulseController.stop();
    
    if (mounted) {
      setState(() {
        _isPlaying = false;
        _remainingSeconds = widget.durationMinutes * 60;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Frequenz-Session beendet (${widget.frequencyHz} Hz)'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
  
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.accentColor.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Frequency Visualization
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isPlaying ? _pulseAnimation.value : 1.0,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.accentColor.withValues(alpha: 0.2),
                    border: Border.all(color: widget.accentColor, width: 3),
                    boxShadow: _isPlaying
                        ? [
                            BoxShadow(
                              color: widget.accentColor.withValues(alpha: 0.5),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ]
                        : [],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.frequencyHz,
                          style: TextStyle(
                            color: widget.accentColor,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Hz',
                          style: TextStyle(
                            color: widget.accentColor.withValues(alpha: 0.8),
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          // Session Timer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer, color: widget.accentColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  _formatDuration(_remainingSeconds),
                  style: TextStyle(
                    color: widget.accentColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Play/Pause Button
          _isLoading
              ? CircularProgressIndicator(color: widget.accentColor)
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Play/Pause Button
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: widget.accentColor.withValues(alpha: 0.3),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: IconButton(
                        iconSize: 48,
                        icon: Icon(
                          _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                          color: widget.accentColor,
                        ),
                        onPressed: _togglePlayPause,
                      ),
                    ),
                    
                    const SizedBox(width: 24),
                    
                    // Stop Button
                    if (_isPlaying)
                      IconButton(
                        iconSize: 36,
                        icon: Icon(
                          Icons.stop_circle,
                          color: Colors.red.withValues(alpha: 0.8),
                        ),
                        onPressed: _stopSession,
                      ),
                  ],
                ),
          
          const SizedBox(height: 16),
          
          // Volume Slider
          Row(
            children: [
              Icon(Icons.volume_down, color: widget.accentColor.withValues(alpha: 0.7), size: 20),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: widget.accentColor,
                    inactiveTrackColor: widget.accentColor.withValues(alpha: 0.2),
                    thumbColor: widget.accentColor,
                    overlayColor: widget.accentColor.withValues(alpha: 0.2),
                  ),
                  child: Slider(
                    value: _volume,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (value) async {
                      setState(() => _volume = value);
                      await _audioPlayer.setVolume(value);
                    },
                  ),
                ),
              ),
              Icon(Icons.volume_up, color: widget.accentColor, size: 20),
            ],
          ),
        ],
      ),
    );
  }
}
