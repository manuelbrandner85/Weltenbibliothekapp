import 'package:flutter/material.dart';

import '../../services/chat/read_receipt_service.dart';

/// Kleiner „Gelesen von N"-Haken, der nur auf EIGENEN Nachrichten
/// gerendert wird. Rechnet live mit [ReadReceiptService].
///
/// - 0 Leser  → grauer Einzelhaken
/// - ≥1 Leser → farbiger Doppelhaken + Zahl
class ChatReadReceiptIndicator extends StatelessWidget {
  const ChatReadReceiptIndicator({
    super.key,
    required this.messageCreatedAt,
    required this.ownUserId,
    this.readColor = const Color(0xFF4ADE80),
    this.pendingColor = Colors.white38,
  });

  final DateTime messageCreatedAt;
  final String ownUserId;
  final Color readColor;
  final Color pendingColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ReadReceiptService.instance,
      builder: (_, __) {
        final readers = ReadReceiptService.instance.readersCountAtOrAfter(
          messageCreatedAt: messageCreatedAt,
          ownUserId: ownUserId,
        );
        final hasReaders = readers > 0;
        final color = hasReaders ? readColor : pendingColor;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasReaders ? Icons.done_all : Icons.done,
              size: 14,
              color: color,
            ),
            if (hasReaders) ...[
              const SizedBox(width: 3),
              Text(
                '$readers',
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
