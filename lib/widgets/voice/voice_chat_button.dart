/// 🎤 VOICE CHAT BUTTON WIDGET
/// Modern voice chat button for AppBar with pulsing animation and participant count

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

class VoiceChatButton extends StatefulWidget {
  final bool isInVoiceRoom;
  final int participantCount;
  final VoidCallback onPressed;
  final Color accentColor;

  const VoiceChatButton({
    Key? key,
    required this.isInVoiceRoom,
    required this.participantCount,
    required this.onPressed,
    this.accentColor = Colors.purple,
  }) : super(key: key);

  @override
  State<VoiceChatButton> createState() => _VoiceChatButtonState();
}

class _VoiceChatButtonState extends State<VoiceChatButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Pulsing animation when in voice room
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
    
    if (widget.isInVoiceRoom) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(VoiceChatButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Start/stop pulsing animation based on voice room state
    if (widget.isInVoiceRoom && !oldWidget.isInVoiceRoom) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isInVoiceRoom && oldWidget.isInVoiceRoom) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isInVoiceRoom ? _pulseAnimation.value : 1.0,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Main Button
              IconButton(
                icon: Icon(
                  widget.isInVoiceRoom ? Icons.call : Icons.call_outlined,
                  color: widget.isInVoiceRoom 
                      ? widget.accentColor 
                      : Colors.white,
                ),
                onPressed: () {
                  if (kDebugMode) {
                    debugPrint('🎤 [VoiceChatButton] Button pressed!');
                    debugPrint('🎤 [VoiceChatButton] isInVoiceRoom: ${widget.isInVoiceRoom}');
                    debugPrint('🎤 [VoiceChatButton] participants: ${widget.participantCount}');
                  }
                  widget.onPressed();
                },
                tooltip: widget.isInVoiceRoom 
                    ? 'Voice Chat aktiv' 
                    : 'Voice Chat beitreten',
              ),
              
              // Participant Count Badge
              if (widget.participantCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: widget.accentColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.accentColor.withValues(alpha: 0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      widget.participantCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              
              // Active indicator ring
              if (widget.isInVoiceRoom)
                Positioned.fill(
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.accentColor.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
