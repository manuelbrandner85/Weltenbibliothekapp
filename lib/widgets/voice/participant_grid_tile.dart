/// 🎤 PARTICIPANT GRID TILE - MODERN WEBRTC UI
/// Single participant tile for 2×5 grid layout
/// Features:
/// - Active speaker highlight
/// - Speaking animation
/// - Admin menu (long-press)
/// - Mute indicator
/// - Current user badge
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/webrtc_participant.dart';
import '../../providers/webrtc_call_provider.dart';

class ParticipantGridTile extends ConsumerWidget {
  final WebRTCParticipant participant;
  final bool isCurrentUser;
  final bool isAdmin;
  final VoidCallback? onLongPress;
  final Color accentColor;

  const ParticipantGridTile({
    super.key,
    required this.participant,
    required this.isCurrentUser,
    required this.isAdmin,
    this.onLongPress,
    this.accentColor = Colors.blue,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch active speaker
    final activeSpeaker = ref.watch(activeSpeakerProvider);
    final isActiveSpeaker = activeSpeaker?.userId == participant.userId;

    return GestureDetector(
      onLongPress: isAdmin && !isCurrentUser ? onLongPress : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActiveSpeaker
                ? Colors.green
                : participant.isSpeaking
                    ? Colors.green.withValues(alpha: 0.5)
                    : Colors.transparent,
            width: isActiveSpeaker ? 3 : 2,
          ),
          boxShadow: isActiveSpeaker
              ? [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Avatar with speaking animation
            Stack(
              alignment: Alignment.center,
              children: [
                // Speaking animation ring
                if (participant.isSpeaking)
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    builder: (context, value, child) {
                      return Container(
                        width: 60 + (value * 10),
                        height: 60 + (value * 10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.green.withValues(alpha: 1.0 - value),
                            width: 2,
                          ),
                        ),
                      );
                    },
                    onEnd: () {
                      // Speaking animation - widget will rebuild when state changes
                    },
                  ),

                // Avatar
                CircleAvatar(
                  radius: 30,
                  backgroundColor: accentColor.withValues(alpha: 0.2),
                  child: Text(
                    participant.avatarEmoji ?? '👤',
                    style: const TextStyle(fontSize: 32),
                  ),
                ),

                // Mute indicator
                if (participant.isMuted)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mic_off,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // Username
            Text(
              participant.username,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),

            // Status badge
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isCurrentUser) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'You',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ] else if (isActiveSpeaker) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.graphic_eq,
                          color: Colors.green,
                          size: 10,
                        ),
                        SizedBox(width: 2),
                        Text(
                          'Speaking',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (participant.isSpeaking) ...[
                  const Icon(
                    Icons.graphic_eq,
                    color: Colors.green,
                    size: 12,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
