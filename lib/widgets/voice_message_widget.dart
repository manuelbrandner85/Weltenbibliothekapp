import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import '../utils/responsive_utils.dart';
import '../utils/responsive_text_styles.dart';

/// Voice Message Player Widget
/// Displays and plays audio messages in chat
class VoiceMessageWidget extends StatefulWidget {
  final String audioUrl;
  final Duration? duration;
  final Color? waveformColor;
  final bool isMyMessage;
  
  const VoiceMessageWidget({
    super.key,
    required this.audioUrl,
    this.duration,
    this.waveformColor,
    this.isMyMessage = false,
  });

  @override
  State<VoiceMessageWidget> createState() => _VoiceMessageWidgetState();
}

class _VoiceMessageWidgetState extends State<VoiceMessageWidget> {
  final _audioPlayer = AudioPlayer();
  
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  double _playbackSpeed = 1.0;
  
  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
  }
  
  void _initAudioPlayer() {
    // Listen to player state
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
    
    // Listen to duration
    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _totalDuration = duration;
        });
      }
    });
    
    // Listen to position
    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    });
    
    // Auto-reset when completed
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _currentPosition = Duration.zero;
        });
      }
    });
    
    // Set initial duration if provided
    if (widget.duration != null) {
      _totalDuration = widget.duration!;
    }
  }
  
  Future<void> _playPause() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        if (_currentPosition >= _totalDuration && _totalDuration > Duration.zero) {
          // Restart from beginning
          await _audioPlayer.seek(Duration.zero);
        }
        await _audioPlayer.play(UrlSource(widget.audioUrl));
        await _audioPlayer.setPlaybackRate(_playbackSpeed);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Audio playback error: $e');
      }
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
  
  void _changeSpeed() {
    setState(() {
      if (_playbackSpeed == 1.0) {
        _playbackSpeed = 1.5;
      } else if (_playbackSpeed == 1.5) {
        _playbackSpeed = 2.0;
      } else {
        _playbackSpeed = 1.0;
      }
    });
    
    if (_isPlaying) {
      _audioPlayer.setPlaybackRate(_playbackSpeed);
    }
  }
  
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
  
  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final utils = ResponsiveUtils.of(context);
    final textStyles = ResponsiveTextStyles.of(context);
    
    final waveColor = widget.waveformColor ?? 
        (widget.isMyMessage ? Colors.white70 : Colors.blue[300]);
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: utils.spacingXs, 
        vertical: utils.spacingXs / 2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause Button
          IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: waveColor,
            ),
            onPressed: _playPause,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          
          SizedBox(width: utils.spacingXs),
          
          // Waveform visualization (simplified)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Waveform bars
                SizedBox(
                  height: utils.iconSizeMd,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: List.generate(30, (index) {
                      // Calculate bar height based on index
                      final progress = _totalDuration > Duration.zero
                          ? _currentPosition.inMilliseconds / _totalDuration.inMilliseconds
                          : 0.0;
                      final barProgress = index / 30;
                      final isPlayed = barProgress <= progress;
                      
                      final height = 4.0 + (index % 7) * 2.0;
                      
                      return Container(
                        width: 2,
                        height: height,
                        decoration: BoxDecoration(
                          color: isPlayed 
                              ? waveColor 
                              : waveColor!.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      );
                    }),
                  ),
                ),
                
                SizedBox(height: utils.spacingXs / 2),
                
                // Progress indicator
                LinearProgressIndicator(
                  value: _totalDuration > Duration.zero
                      ? _currentPosition.inMilliseconds / _totalDuration.inMilliseconds
                      : 0.0,
                  backgroundColor: waveColor!.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(waveColor),
                  minHeight: 2,
                ),
              ],
            ),
          ),
          
          SizedBox(width: utils.spacingXs),
          
          // Duration & Speed
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatDuration(_totalDuration - _currentPosition),
                style: textStyles.labelSmall.copyWith(
                  color: waveColor,
                ),
              ),
              InkWell(
                onTap: _changeSpeed,
                child: Text(
                  '${_playbackSpeed}x',
                  style: textStyles.labelSmall.copyWith(
                    fontSize: textStyles.labelSmall.fontSize! * 0.9,
                    color: waveColor.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
