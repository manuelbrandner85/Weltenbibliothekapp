/// 🎙️ PUSH-TO-TALK BUTTON
/// Hold to speak button for voice chat
library;

import 'package:flutter/material.dart';
import '../services/webrtc_voice_service.dart'; // ✅ UNIFIED WebRTC Service
import '../services/audio_settings_service.dart';

class PushToTalkButton extends StatefulWidget {
  final SimpleVoiceController voiceController;

  const PushToTalkButton({
    super.key,
    required this.voiceController,
  });

  @override
  State<PushToTalkButton> createState() => _PushToTalkButtonState();
}

class _PushToTalkButtonState extends State<PushToTalkButton>
    with SingleTickerProviderStateMixin {
  final AudioSettingsService _settings = AudioSettingsService();
  bool _isPressing = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handlePressStart() {
    setState(() => _isPressing = true);
    _pulseController.repeat(reverse: true);
    widget.voiceController.startPushToTalk();
  }

  void _handlePressEnd() {
    setState(() => _isPressing = false);
    _pulseController.stop();
    _pulseController.reset();
    widget.voiceController.stopPushToTalk();
  }

  @override
  Widget build(BuildContext context) {
    if (!_settings.pushToTalk) {
      return const SizedBox.shrink();
    }

    return Center(
      child: GestureDetector(
        onTapDown: (_) => _handlePressStart(),
        onTapUp: (_) => _handlePressEnd(),
        onTapCancel: _handlePressEnd,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _isPressing ? _pulseAnimation.value : 1.0,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isPressing ? Colors.green : Colors.grey,
                  boxShadow: _isPressing
                      ? [
                          BoxShadow(
                            color: Colors.green.withValues(alpha: 0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isPressing ? Icons.mic : Icons.mic_off,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isPressing ? 'Sprechen...' : 'Halten zum\nSprechen',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
