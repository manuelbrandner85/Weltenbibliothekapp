import 'package:flutter/material.dart';

import '../../services/chat/presence_service.dart';

/// Kompakter Live-Online-Counter: grüner Dot + "N".
/// Hört auf [PresenceService] und rendert nichts, wenn 0 online.
class ChatOnlineIndicator extends StatelessWidget {
  const ChatOnlineIndicator({
    super.key,
    this.color = const Color(0xFF4ADE80),
    this.textColor = Colors.white70,
  });

  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: PresenceService.instance,
      builder: (_, __) {
        final count = PresenceService.instance.onlineCount;
        if (count <= 0) return const SizedBox.shrink();
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      },
    );
  }
}
