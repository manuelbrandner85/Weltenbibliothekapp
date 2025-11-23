import 'package:flutter/material.dart';
import '../models/message_model.dart';

/// ═══════════════════════════════════════════════════════════════
/// MESSAGE REACTIONS WIDGET - Telegram-Style Emoji Reactions
/// ═══════════════════════════════════════════════════════════════
///
/// Features:
/// - Quick emoji reactions (❤️ 🔥 👍 😂 😮 🙏 ✨)
/// - Show reaction count below message
/// - Tap to add/remove your reaction
/// - Long-press message to show reaction picker
/// - Mystical theme with gold accents
/// ═══════════════════════════════════════════════════════════════

class MessageReactionsWidget extends StatelessWidget {
  final MessageModel message;
  final String currentUserId;
  final Function(String emoji) onReactionTap;
  final bool showPicker;

  const MessageReactionsWidget({
    super.key,
    required this.message,
    required this.currentUserId,
    required this.onReactionTap,
    this.showPicker = false,
  });

  /// Available mystical emoji reactions
  static const List<String> availableReactions = [
    '❤️', // Love
    '🔥', // Fire
    '👍', // Thumbs up
    '😂', // Laughing
    '😮', // Surprised
    '🙏', // Praying hands
    '✨', // Sparkles (mystical)
  ];

  @override
  Widget build(BuildContext context) {
    if (message.reactions.isEmpty && !showPicker) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Existing reactions
        if (message.reactions.isNotEmpty) _buildExistingReactions(context),

        // Reaction picker (shown on long-press)
        if (showPicker) _buildReactionPicker(context),
      ],
    );
  }

  /// Display existing reactions with counts
  Widget _buildExistingReactions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 8),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: message.reactions.entries.map((entry) {
          final emoji = entry.key;
          final users = entry.value;
          final count = users.length;
          final hasUserReacted = users.contains(currentUserId);

          return GestureDetector(
            onTap: () => onReactionTap(emoji),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: hasUserReacted
                    ? const Color(0xFFFFD700).withValues(
                        alpha: 0.2,
                      ) // Gold for user's reaction
                    : Colors.white.withValues(alpha: 0.1),
                border: Border.all(
                  color: hasUserReacted
                      ? const Color(0xFFFFD700) // Gold border
                      : Colors.white.withValues(alpha: 0.3),
                  width: hasUserReacted ? 1.5 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 14)),
                  if (count > 1) ...[
                    const SizedBox(width: 4),
                    Text(
                      count.toString(),
                      style: TextStyle(
                        color: hasUserReacted
                            ? const Color(0xFFFFD700)
                            : Colors.white70,
                        fontSize: 12,
                        fontWeight: hasUserReacted
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Reaction picker overlay (shown on long-press)
  Widget _buildReactionPicker(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8, left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.2),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: availableReactions.map((emoji) {
          final hasReacted = message.hasUserReaction(currentUserId, emoji);

          return GestureDetector(
            onTap: () => onReactionTap(emoji),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: hasReacted
                    ? const Color(0xFFFFD700).withValues(alpha: 0.2)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 20)),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// QUICK REACTION BUTTON - Add to message bubble
/// ═══════════════════════════════════════════════════════════════
class QuickReactionButton extends StatelessWidget {
  final VoidCallback onPressed;

  const QuickReactionButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E).withValues(alpha: 0.9),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFFFFD700).withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.add_reaction_outlined,
          size: 16,
          color: Color(0xFFFFD700),
        ),
      ),
    );
  }
}
