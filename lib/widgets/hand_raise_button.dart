/// ✋ HAND RAISE BUTTON
/// Button for raising/lowering hand in voice chat
library;

import 'package:flutter/material.dart';
import '../services/webrtc_voice_service.dart'; // ✅ UNIFIED WebRTC Service
import '../services/voice_feedback_service.dart';
import '../services/simple_voice_controller.dart'; // ✅ Import SimpleVoiceController

class HandRaiseButton extends StatefulWidget {
  final SimpleVoiceController voiceController;
  final String userId;

  const HandRaiseButton({
    super.key,
    required this.voiceController,
    required this.userId,
  });

  @override
  State<HandRaiseButton> createState() => _HandRaiseButtonState();
}

class _HandRaiseButtonState extends State<HandRaiseButton>
    with SingleTickerProviderStateMixin {
  final VoiceFeedbackService _feedback = VoiceFeedbackService();
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  bool _isHandRaised = false;

  @override
  void initState() {
    super.initState();

    // Shake Animation
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(
        parent: _shakeController,
        curve: Curves.elasticIn,
      ),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _toggleHandRaise() async {
    setState(() {
      _isHandRaised = !_isHandRaised;
    });

    if (_isHandRaised) {
      _shakeController.repeat(reverse: true);
      await _feedback.handRaised();
      // TODO: Call actual WebRTC service
      // await widget.voiceController.raiseHand(widget.userId);
    } else {
      _shakeController.stop();
      _shakeController.reset();
      await _feedback.success();
      // TODO: Call actual WebRTC service
      // await widget.voiceController.lowerHand(widget.userId);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isHandRaised
                ? '✋ Hand gehoben! Warte auf Moderator...'
                : '👋 Hand gesenkt',
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: _isHandRaised
              ? Offset(_shakeAnimation.value, 0)
              : Offset.zero,
          child: FloatingActionButton(
            onPressed: _toggleHandRaise,
            backgroundColor:
                _isHandRaised ? Colors.orange : Colors.white.withValues(alpha: 0.2),
            child: Icon(
              _isHandRaised ? Icons.back_hand : Icons.back_hand_outlined,
              color: _isHandRaised ? Colors.white : Colors.white70,
            ),
          ),
        );
      },
    );
  }
}

/// 📋 Hand Raise Indicator (for participant tiles)
class HandRaiseIndicator extends StatelessWidget {
  final bool isHandRaised;
  final double size;

  const HandRaiseIndicator({
    super.key,
    required this.isHandRaised,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    if (!isHandRaised) return const SizedBox.shrink();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.2),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              Icons.back_hand,
              color: Colors.white,
              size: size * 0.6,
            ),
          ),
        );
      },
      onEnd: () {},
    );
  }
}
