// Profile-Chat-Preview — Live-Vorschau wie das Profil im Chat aussieht.
//
// Wird im Profile-Editor unter dem Avatar gerendert. Zeigt eine
// nachgebaute Chat-Bubble mit aktuellem Avatar/Username/Beispieltext.
// Aktualisiert sich automatisch wenn der User die Felder ändert.

import 'package:flutter/material.dart';

class ProfileChatPreview extends StatelessWidget {
  final String? avatarUrl;
  final String? avatarEmoji;
  final String username;
  final String displayName;
  final Color accent;

  const ProfileChatPreview({
    super.key,
    required this.avatarUrl,
    required this.avatarEmoji,
    required this.username,
    required this.displayName,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final name = displayName.trim().isNotEmpty
        ? displayName.trim()
        : (username.trim().isNotEmpty ? username.trim() : 'Du');
    final hasNetwork = (avatarUrl ?? '').startsWith('http');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFF0D0D1A),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.visibility_outlined,
                  color: accent.withValues(alpha: 0.7), size: 14),
              const SizedBox(width: 6),
              Text(
                'SO SIEHT DEIN PROFIL IM CHAT AUS',
                style: TextStyle(
                  color: accent.withValues(alpha: 0.7),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Avatar (gleich wie in Materie/Energie-Chat: radius 18)
              CircleAvatar(
                radius: 18,
                backgroundColor: accent.withValues(alpha: 0.2),
                backgroundImage: hasNetwork ? NetworkImage(avatarUrl!) : null,
                child: !hasNetwork
                    ? Text(
                        (avatarEmoji?.isNotEmpty ?? false)
                            ? avatarEmoji!
                            : (name.isNotEmpty ? name[0].toUpperCase() : '?'),
                        style: TextStyle(
                          fontSize:
                              (avatarEmoji?.isNotEmpty ?? false) ? 16 : 14,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              // Bubble
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(14),
                      bottomLeft: Radius.circular(14),
                      bottomRight: Radius.circular(14),
                    ),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Hallo Weltenbibliothek 👋',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
