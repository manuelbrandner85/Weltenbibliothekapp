import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math' as math;

/// 🎵 TELEGRAM-STYLE VOICE PLAYER
/// Waveform, playback speed, seeking - exactly like Telegram
class TelegramVoicePlayer extends StatefulWidget {
  final String audioUrl;
  final Duration duration;
  final Color accentColor;
  final bool isOwn;

  const TelegramVoicePlayer({
    super.key,
    required this.audioUrl,
    required this.duration,
    this.accentColor = Colors.blue,
    this.isOwn = false,
  });

  @override
  State<TelegramVoicePlayer> createState() => _TelegramVoicePlayerState();
}

class _TelegramVoicePlayerState extends State<TelegramVoicePlayer> {
  final AudioPlayer _player = AudioPlayer();
  
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _playbackSpeed = 1.0;
  
  // Waveform data (simulated for now - can be real audio analysis)
  final List<double> _waveformData = List.generate(40, (index) {
    return 0.3 + (math.sin(index * 0.3) * 0.4).abs() + (math.Random().nextDouble() * 0.3);
  });

  @override
  void initState() {
    super.initState();
    _duration = widget.duration;
    
    // Player state listener
    _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
    
    // Position listener
    _player.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });
    
    // Duration listener
    _player.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration;
        });
      }
    });
    
    // Completion listener
    _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    try {
      if (_isPlaying) {
        await _player.pause();
      } else {
        if (_position == Duration.zero || _position >= _duration) {
          await _player.setPlaybackRate(_playbackSpeed);
          await _player.play(UrlSource(widget.audioUrl));
        } else {
          await _player.resume();
        }
      }
    } catch (e) {
      debugPrint('❌ Playback error: $e');
    }
  }

  Future<void> _cyclePlaybackSpeed() async {
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
      await _player.setPlaybackRate(_playbackSpeed);
    }
  }

  Future<void> _seekTo(double value) async {
    final position = Duration(milliseconds: (value * _duration.inMilliseconds).toInt());
    await _player.seek(position);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString();
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;
    
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isOwn
            ? widget.accentColor.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause Button
          GestureDetector(
            onTap: _togglePlayPause,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: widget.accentColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Waveform + Progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Waveform with progress
                GestureDetector(
                  onTapDown: (details) {
                    final box = context.findRenderObject() as RenderBox;
                    final localPosition = box.globalToLocal(details.globalPosition);
                    final width = box.size.width - 100; // Account for button + spacing
                    final progress = ((localPosition.dx - 44) / width).clamp(0.0, 1.0);
                    _seekTo(progress);
                  },
                  child: SizedBox(
                    height: 32,
                    child: CustomPaint(
                      painter: WaveformPainter(
                        waveformData: _waveformData,
                        progress: progress,
                        accentColor: widget.accentColor,
                        backgroundColor: Colors.grey.withValues(alpha: 0.3),
                      ),
                      size: Size.infinite,
                    ),
                  ),
                ),
                
                const SizedBox(height: 4),
                
                // Duration + Speed
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_isPlaying ? _position : _duration),
                      style: TextStyle(
                        color: widget.isOwn ? Colors.white70 : Colors.grey[700],
                        fontSize: 12,
                      ),
                    ),
                    
                    GestureDetector(
                      onTap: _cyclePlaybackSpeed,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: widget.accentColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_playbackSpeed}x',
                          style: TextStyle(
                            color: widget.accentColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom Painter for Telegram-style waveform
class WaveformPainter extends CustomPainter {
  final List<double> waveformData;
  final double progress;
  final Color accentColor;
  final Color backgroundColor;

  WaveformPainter({
    required this.waveformData,
    required this.progress,
    required this.accentColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = size.width / waveformData.length;
    final barSpacing = barWidth * 0.3;
    final actualBarWidth = barWidth - barSpacing;
    
    for (int i = 0; i < waveformData.length; i++) {
      final x = i * barWidth;
      final barHeight = waveformData[i] * size.height;
      final y = (size.height - barHeight) / 2;
      
      // Determine color based on progress
      final barProgress = (i * barWidth) / size.width;
      final color = barProgress <= progress ? accentColor : backgroundColor;
      
      final paint = Paint()
        ..color = color
        ..strokeCap = StrokeCap.round
        ..strokeWidth = actualBarWidth;
      
      canvas.drawLine(
        Offset(x + actualBarWidth / 2, y),
        Offset(x + actualBarWidth / 2, y + barHeight),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.accentColor != accentColor;
  }
}
