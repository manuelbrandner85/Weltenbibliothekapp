import 'package:flutter/material.dart';

import '../../services/chat/presence_service.dart';

/// BottomSheet mit Kontext-Info zu einem Chat-Raum:
/// - Name + Icon
/// - Beschreibung
/// - Online-Zähler (live via [PresenceService])
/// - Slot für weitere Detail-Blöcke (z.B. Pinned-Preview)
class ChatRoomInfoSheet extends StatelessWidget {
  const ChatRoomInfoSheet({
    super.key,
    required this.roomName,
    required this.roomIcon,
    required this.description,
    required this.worldColor,
    this.extra,
  });

  final String roomName;
  final String roomIcon;
  final String description;
  final Color worldColor;
  final Widget? extra;

  static Future<void> show(
    BuildContext context, {
    required String roomName,
    required String roomIcon,
    required String description,
    required Color worldColor,
    Widget? extra,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => ChatRoomInfoSheet(
        roomName: roomName,
        roomIcon: roomIcon,
        description: description,
        worldColor: worldColor,
        extra: extra,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(roomIcon, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    roomName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _OnlineDot(color: worldColor),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.35,
              ),
            ),
            if (extra != null) ...[
              const SizedBox(height: 16),
              Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
              const SizedBox(height: 12),
              extra!,
            ],
          ],
        ),
      ),
    );
  }
}

class _OnlineDot extends StatelessWidget {
  const _OnlineDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: PresenceService.instance,
      builder: (_, __) {
        final count = PresenceService.instance.onlineCount;
        if (count <= 0) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.6)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$count online',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
