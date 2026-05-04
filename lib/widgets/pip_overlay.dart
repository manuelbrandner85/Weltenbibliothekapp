/// 📺 B10.3 — PiP-Overlay
///
/// Wird im PiP-Modus anstelle des vollen Call-Screens gezeigt.
/// Zeigt nur: Avatar des aktiven Sprechers + Name + Welt-Akzent.
/// Kein ControlBar, keine TopBar — PiP-Fenster ist sehr klein.
library;

import 'package:flutter/material.dart';

import '../config/wb_design.dart';
import '../services/livekit_call_service.dart';

class PipOverlay extends StatelessWidget {
  final String world;
  final String localName;
  final String? localAvatarUrl;
  final LiveKitCallService service;

  const PipOverlay({
    super.key,
    required this.world,
    required this.localName,
    required this.localAvatarUrl,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    final accent = WbDesign.accent(world);
    final bg = WbDesign.background(world);

    // Aktiver Sprecher → dessen Name/Avatar zeigen, sonst lokal
    final speakerIdentities = service.speakersNotifier.value;
    final activeSpeakerName = speakerIdentities.isNotEmpty
        ? service.remoteParticipantNames.firstWhere(
            (n) => speakerIdentities.any((id) => id.contains(n.toLowerCase())),
            orElse: () => localName,
          )
        : localName;

    return Container(
      color: bg,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar-Kreis mit Welt-Gradient
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: WbDesign.hero(world),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.5),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: localAvatarUrl != null && localAvatarUrl!.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        localAvatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _initials(activeSpeakerName),
                      ),
                    )
                  : _initials(activeSpeakerName),
            ),
            const SizedBox(height: 8),
            Text(
              activeSpeakerName,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Mic-Status
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  service.micEnabled ? Icons.mic_rounded : Icons.mic_off_rounded,
                  color: service.micEnabled ? accent : Colors.grey,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  world == 'materie' ? 'Materie' : 'Energie',
                  style: TextStyle(
                    color: accent.withValues(alpha: 0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final initials = parts.length == 1
        ? parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '?'
        : '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
