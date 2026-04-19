import 'package:flutter/material.dart';

import '../../services/offline_sync_service.dart';

/// Schmaler Status-Banner über dem Chat-List.
///
/// Zeigt drei Zustände an:
///  1. Offline → rotes Banner „Offline – Nachrichten werden gepuffert"
///  2. Reconnecting → oranges Banner „Verbindung wird wiederhergestellt…"
///  3. Pending-Queue > 0 → gelbes Banner „N Nachrichten warten auf Verbindung"
///
/// Ist keiner der Zustände aktiv, rendert das Widget 0 Höhe (SizedBox.shrink).
class ChatStatusBanner extends StatelessWidget {
  const ChatStatusBanner({
    super.key,
    required this.reconnecting,
    this.worldColor,
  });

  /// Setzt der Screen, wenn der Realtime-Channel im Reconnect-Zustand ist.
  final bool reconnecting;
  final Color? worldColor;

  @override
  Widget build(BuildContext context) {
    final offline = OfflineSyncService();
    return AnimatedBuilder(
      animation: offline,
      builder: (_, __) {
        final isOffline = offline.isOffline;
        final pending = offline.pendingActionsCount;

        if (!isOffline && !reconnecting && pending == 0) {
          return const SizedBox.shrink();
        }

        late final Color bg;
        late final IconData icon;
        late final String text;

        if (isOffline) {
          bg = const Color(0xFFE53935);
          icon = Icons.cloud_off;
          text = pending > 0
              ? 'Offline · $pending Nachricht${pending == 1 ? '' : 'en'} in Warteschlange'
              : 'Offline · Nachrichten werden zwischengespeichert';
        } else if (reconnecting) {
          bg = const Color(0xFFFB8C00);
          icon = Icons.sync;
          text = 'Verbindung wird wiederhergestellt…';
        } else {
          bg = const Color(0xFFFBC02D);
          icon = Icons.schedule_send;
          text =
              '$pending Nachricht${pending == 1 ? '' : 'en'} werden gesendet…';
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: bg.withValues(alpha: 0.92),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (!isOffline && pending > 0)
                InkWell(
                  onTap: () => offline.syncPendingActions(),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    child: Text(
                      'Jetzt senden',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
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
