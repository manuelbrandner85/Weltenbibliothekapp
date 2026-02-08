/// 🎨 EMOJI REACTION PICKER
/// Bottom sheet for selecting emoji reactions
library;

import 'package:flutter/material.dart';

class EmojiReactionPicker extends StatelessWidget {
  final Function(String emoji) onEmojiSelected;
  final Color color;

  const EmojiReactionPicker({
    super.key,
    required this.onEmojiSelected,
    this.color = Colors.purple,
  });

  static final List<String> _emojis = [
    '👍', '❤️', '😂', '😮', '😢', '🙏',
    '🔥', '⭐', '✅', '❌', '💯', '🎉',
    '👀', '💪', '🤔', '😱', '🚀', '💡',
    '🎯', '💎', '⚡', '🌟', '🏆', '🎊',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle Bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          
          // Title
          Text(
            'Reaktion hinzufügen',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Emoji Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: _emojis.length,
            itemBuilder: (context, index) {
              final emoji = _emojis[index];
              return InkWell(
                onTap: () {
                  onEmojiSelected(emoji);
                  Navigator.pop(context);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white12,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  static Future<String?> show(BuildContext context, {Color? color}) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => EmojiReactionPicker(
        onEmojiSelected: (emoji) => Navigator.pop(context, emoji),
        color: color ?? Colors.purple,
      ),
    );
  }
}

/// Emoji Reaction Bar (shows reactions under message)
class EmojiReactionBar extends StatelessWidget {
  final Map<String, List<Map<String, dynamic>>> reactions;
  final String currentUserId;
  final Function(String emoji) onReactionTap;
  final VoidCallback onAddReaction;
  final Color color;

  const EmojiReactionBar({
    super.key,
    required this.reactions,
    required this.currentUserId,
    required this.onReactionTap,
    required this.onAddReaction,
    this.color = Colors.purple,
  });

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        // Existing Reactions
        ...reactions.entries.map((entry) {
          final emoji = entry.key;
          final users = entry.value;
          final hasReacted = users.any((u) => u['userId'] == currentUserId);

          return InkWell(
            onTap: () => onReactionTap(emoji),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: hasReacted ? color.withValues(alpha: 0.2) : Colors.white10,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: hasReacted ? color : Colors.white24,
                  width: hasReacted ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    emoji,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${users.length}',
                    style: TextStyle(
                      color: hasReacted ? color : Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        
        // Add Reaction Button
        InkWell(
          onTap: onAddReaction,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white24,
                width: 1,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_reaction_outlined,
                  size: 18,
                  color: Colors.white70,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
