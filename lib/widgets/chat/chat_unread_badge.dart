import 'package:flutter/material.dart';

import '../../services/chat/unread_tracker_service.dart';

/// Kleines Zahlen-Badge, das den Unread-Count eines Raums rendert.
/// Hört live auf [UnreadTrackerService] und aktualisiert sich automatisch.
class ChatUnreadBadge extends StatelessWidget {
  const ChatUnreadBadge({
    super.key,
    required this.roomId,
    this.background = const Color(0xFFE53935),
    this.foreground = Colors.white,
    this.size = 18,
  });

  final String roomId;
  final Color background;
  final Color foreground;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tracker = UnreadTrackerService.instance;
    return AnimatedBuilder(
      animation: tracker,
      builder: (_, __) {
        final count = tracker.countForSync(roomId);
        if (count <= 0) return const SizedBox.shrink();
        final label = count > 99 ? '99+' : '$count';
        return Container(
          constraints: BoxConstraints(minWidth: size, minHeight: size),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        );
      },
    );
  }
}
