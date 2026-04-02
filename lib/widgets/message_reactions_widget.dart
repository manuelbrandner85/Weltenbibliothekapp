import 'package:flutter/material.dart';

/// Message Reactions Widget
/// Zeigt Emoji-Reaktionen unter Nachrichten an
class MessageReactionsWidget extends StatelessWidget {
  final Map<String, dynamic> message;
  final Function(String emoji) onReact;
  final String currentUsername;
  
  const MessageReactionsWidget({
    super.key,
    required this.message,
    required this.onReact,
    required this.currentUsername,
  });
  
  @override
  Widget build(BuildContext context) {
    final reactions = message['reactions'] as Map<String, dynamic>? ?? {};
    
    if (reactions.isEmpty) return const SizedBox.shrink();
    
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: reactions.entries.map((entry) {
        final emoji = entry.key;
        final users = (entry.value as List<dynamic>).cast<String>();
        final hasReacted = users.contains(currentUsername);
        
        return GestureDetector(
          onTap: () => onReact(emoji),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: hasReacted
                  ? const Color(0xFF9B51E0).withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasReacted
                    ? const Color(0xFF9B51E0)
                    : Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  '${users.length}',
                  style: TextStyle(
                    color: hasReacted ? Colors.white : Colors.white70,
                    fontSize: 12,
                    fontWeight: hasReacted ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Reaction Picker Bottom Sheet
class ReactionPickerSheet extends StatelessWidget {
  final Function(String emoji) onSelectEmoji;
  
  const ReactionPickerSheet({super.key, required this.onSelectEmoji});
  
  static final List<String> _emojis = [
    '👍', '❤️', '😂', '😮', '😢', '😡',
    '🔥', '✨', '💯', '🎉', '🙏', '👏',
    '💪', '🌟', '⚡', '💎', '🌈', '🎯',
  ];
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle Bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Title
          const Text(
            'Reaktion wählen',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          // Emoji Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: _emojis.length,
            itemBuilder: (context, index) {
              final emoji = _emojis[index];
              return GestureDetector(
                onTap: () {
                  onSelectEmoji(emoji);
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
