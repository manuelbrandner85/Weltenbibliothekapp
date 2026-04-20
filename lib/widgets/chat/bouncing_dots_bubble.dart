import 'package:flutter/material.dart';

/// iMessage-style animated typing bubble with 3 bouncing dots.
class BouncingDotsBubble extends StatefulWidget {
  final Color color;
  final Color bgColor;

  const BouncingDotsBubble({
    super.key,
    required this.color,
    this.bgColor = const Color(0xFF2A2A3E),
  });

  @override
  State<BouncingDotsBubble> createState() => _BouncingDotsBubbleState();
}

class _BouncingDotsBubbleState extends State<BouncingDotsBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: widget.bgColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
          bottomLeft: Radius.circular(4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (_, __) {
              final phase = (_controller.value * 3 - i).clamp(0.0, 3.0) % 1.0;
              final dy = phase < 0.5 ? -4.0 * phase * 2 : -4.0 * (1.0 - (phase - 0.5) * 2);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Transform.translate(
                  offset: Offset(0, dy.clamp(-4.0, 0.0)),
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
