/// 🎙️ SPEAKING INDICATOR WIDGET
///
/// Zeigt animierte Audio-Level-Balken für jeden Sprecher im Voice-Raum.
/// Wird von audioLevelStream des WebRTCVoiceService getrieben.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/webrtc_voice_service.dart';

// ── SPEAKING INDICATOR (kleine Version für Teilnehmerliste) ────────────────

class SpeakingIndicator extends StatefulWidget {
  final bool isSpeaking;
  final Color color;
  final double size;

  const SpeakingIndicator({
    super.key,
    required this.isSpeaking,
    this.color = Colors.greenAccent,
    this.size = 16,
  });

  @override
  State<SpeakingIndicator> createState() => _SpeakingIndicatorState();
}

class _SpeakingIndicatorState extends State<SpeakingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _barAnimations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    // 3 Balken mit versetzten Phasen
    _barAnimations = [
      Tween<double>(begin: 0.2, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
        ),
      ),
      Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.2, 0.8, curve: Curves.easeInOut),
        ),
      ),
      Tween<double>(begin: 0.2, end: 0.8).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
        ),
      ),
    ];
  }

  @override
  void didUpdateWidget(SpeakingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpeaking && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isSpeaking && _controller.isAnimating) {
      _controller.stop();
      _controller.animateTo(0.1);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isSpeaking) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: Center(
          child: Icon(
            Icons.mic_none,
            size: widget.size * 0.75,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(3, (i) {
              final height = widget.size * _barAnimations[i].value;
              return Container(
                width: (widget.size - 4) / 3,
                height: height,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

// ── AUDIO LEVEL BAR (für Vollansicht) ──────────────────────────────────────

class AudioLevelBar extends StatelessWidget {
  final double level; // 0.0 – 1.0
  final Color color;
  final double width;
  final double height;

  const AudioLevelBar({
    super.key,
    required this.level,
    this.color = Colors.greenAccent,
    this.width = 200,
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: FractionallySizedBox(
        widthFactor: level.clamp(0.0, 1.0),
        alignment: Alignment.centerLeft,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.greenAccent,
                level > 0.6 ? Colors.orangeAccent : Colors.greenAccent,
                level > 0.85 ? Colors.redAccent : (level > 0.6 ? Colors.orangeAccent : Colors.greenAccent),
              ],
            ),
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
      ),
    );
  }
}

// ── STREAM-BASIERTER SPEAKING INDICATOR ────────────────────────────────────

class StreamSpeakingIndicator extends StatefulWidget {
  /// Benutzter userId für den dieser Indikator angezeigt wird.
  final String userId;
  final WebRTCVoiceService voiceService;
  final double size;
  final Color color;

  const StreamSpeakingIndicator({
    super.key,
    required this.userId,
    required this.voiceService,
    this.size = 16,
    this.color = Colors.greenAccent,
  });

  @override
  State<StreamSpeakingIndicator> createState() => _StreamSpeakingIndicatorState();
}

class _StreamSpeakingIndicatorState extends State<StreamSpeakingIndicator> {
  double _audioLevel = 0.0;
  StreamSubscription<Map<String, double>>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.voiceService.audioLevelStream.listen((levels) {
      final level = levels[widget.userId] ?? 0.0;
      if (mounted && (level - _audioLevel).abs() > 0.01) {
        setState(() => _audioLevel = level);
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSpeaking = _audioLevel > 0.05;
    return SpeakingIndicator(
      isSpeaking: isSpeaking,
      color: widget.color,
      size: widget.size,
    );
  }
}

// ── PARTICIPANT ROW MIT SPEAKING INDICATOR ─────────────────────────────────

class ParticipantSpeakingRow extends StatefulWidget {
  final VoiceParticipant participant;
  final WebRTCVoiceService voiceService;
  final Color worldColor;

  const ParticipantSpeakingRow({
    super.key,
    required this.participant,
    required this.voiceService,
    required this.worldColor,
  });

  @override
  State<ParticipantSpeakingRow> createState() => _ParticipantSpeakingRowState();
}

class _ParticipantSpeakingRowState extends State<ParticipantSpeakingRow> {
  double _audioLevel = 0.0;
  StreamSubscription<Map<String, double>>? _levelSubscription;
  StreamSubscription<Map<String, bool>>? _speakingSubscription;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _isSpeaking = widget.participant.isSpeaking;

    _levelSubscription = widget.voiceService.audioLevelStream.listen((levels) {
      final level = levels[widget.participant.userId] ?? 0.0;
      if (mounted && (level - _audioLevel).abs() > 0.01) {
        setState(() {
          _audioLevel = level;
          _isSpeaking = level > 0.05;
        });
      }
    });

    _speakingSubscription = widget.voiceService.speakingStream.listen((speaking) {
      final isSpeaking = speaking[widget.participant.userId] ?? false;
      if (mounted && isSpeaking != _isSpeaking) {
        setState(() => _isSpeaking = isSpeaking);
      }
    });
  }

  @override
  void dispose() {
    _levelSubscription?.cancel();
    _speakingSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _isSpeaking
            ? widget.worldColor.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: _isSpeaking
            ? Border.all(color: widget.worldColor.withValues(alpha: 0.4), width: 1.5)
            : null,
      ),
      child: Row(
        children: [
          // Avatar mit Speaking-Glow
          Stack(
            alignment: Alignment.center,
            children: [
              if (_isSpeaking)
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.worldColor.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              CircleAvatar(
                radius: 18,
                backgroundColor: widget.worldColor.withValues(alpha: 0.2),
                child: Text(
                  widget.participant.username.isNotEmpty
                      ? widget.participant.username[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: widget.worldColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Name + Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.participant.username,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: _isSpeaking ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (_isSpeaking)
                  AudioLevelBar(
                    level: _audioLevel,
                    color: widget.worldColor,
                    width: 100,
                    height: 4,
                  ),
              ],
            ),
          ),

          // Speaking Indicator / Mute Icon
          if (widget.participant.isMuted)
            Icon(Icons.mic_off, size: 18, color: Colors.red.shade300)
          else
            SpeakingIndicator(
              isSpeaking: _isSpeaking,
              color: widget.worldColor,
              size: 18,
            ),
        ],
      ),
    );
  }
}
