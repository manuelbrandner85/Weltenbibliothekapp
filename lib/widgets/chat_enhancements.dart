/// 💬 LIVE CHAT UPGRADES - V115+
/// User Profiles, Typing Indicators, Reactions, Reply System
library;

import 'package:flutter/material.dart';

// ========================================
// 👤 USER PROFILE MODEL
// ========================================
class UserProfile {
  final String userId;
  final String username;
  final String avatar;
  final String status;
  final bool isOnline;
  final int level;
  final DateTime? lastSeen;

  UserProfile({
    required this.userId,
    required this.username,
    required this.avatar,
    this.status = '',
    this.isOnline = false,
    this.level = 1,
    this.lastSeen,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'username': username,
        'avatar': avatar,
        'status': status,
        'isOnline': isOnline,
        'level': level,
        'lastSeen': lastSeen?.toIso8601String(),
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        userId: json['userId'] as String,
        username: json['username'] as String,
        avatar: json['avatar'] as String,
        status: json['status'] as String? ?? '',
        isOnline: json['isOnline'] as bool? ?? false,
        level: json['level'] as int? ?? 1,
        lastSeen: json['lastSeen'] != null ? DateTime.parse(json['lastSeen'] as String) : null,
      );
}

// ========================================
// 💬 ENHANCED MESSAGE MODEL
// ========================================
class EnhancedChatMessage {
  final String id;
  final String userId;
  final String username;
  final String content;
  final DateTime timestamp;
  final String? replyToId;
  final Map<String, int> reactions; // emoji -> count

  EnhancedChatMessage({
    required this.id,
    required this.userId,
    required this.username,
    required this.content,
    required this.timestamp,
    this.replyToId,
    this.reactions = const {},
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'username': username,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'replyToId': replyToId,
        'reactions': reactions,
      };

  factory EnhancedChatMessage.fromJson(Map<String, dynamic> json) => EnhancedChatMessage(
        id: json['id'] as String,
        userId: json['userId'] as String,
        username: json['username'] as String,
        content: json['content'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        replyToId: json['replyToId'] as String?,
        reactions: Map<String, int>.from(json['reactions'] as Map? ?? {}),
      );
}

// ========================================
// 👤 USER INFO DIALOG
// ========================================
class UserInfoDialog extends StatelessWidget {
  final UserProfile user;

  const UserInfoDialog({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: user.isOnline ? Colors.green : Colors.grey,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(user.avatar, style: const TextStyle(fontSize: 40)),
              ),
            ),
            const SizedBox(height: 16),
            
            // Username & Level
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  user.username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Lvl ${user.level}',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Online Status
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: user.isOnline ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  user.isOnline ? 'Online' : 'Zuletzt gesehen: ${_formatLastSeen(user.lastSeen)}',
                  style: TextStyle(
                    color: user.isOnline ? Colors.green : Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Status
            if (user.status.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.info_outline, color: Colors.white70, size: 16),
                    const SizedBox(width: 8),
                    Text(user.status, style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () {
                    // Send message
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.message, color: Colors.blue),
                  label: const Text('Nachricht', style: TextStyle(color: Colors.blue)),
                ),
                TextButton.icon(
                  onPressed: () {
                    // Add friend
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.person_add, color: Colors.green),
                  label: const Text('Freund', style: TextStyle(color: Colors.green)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatLastSeen(DateTime? lastSeen) {
    if (lastSeen == null) return 'unbekannt';
    
    final now = DateTime.now();
    final diff = now.difference(lastSeen);
    
    if (diff.inMinutes < 1) return 'gerade eben';
    if (diff.inMinutes < 60) return 'vor ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'vor ${diff.inHours}h';
    return 'vor ${diff.inDays}d';
  }
}

// ========================================
// ⌨️ TYPING INDICATOR
// ========================================
class TypingIndicator extends StatefulWidget {
  final List<String> typingUsers;

  const TypingIndicator({super.key, required this.typingUsers});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.typingUsers.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (index) {
                  final delay = index * 0.2;
                  final opacity = ((_controller.value + delay) % 1.0) > 0.5 ? 1.0 : 0.3;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: opacity),
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(width: 8),
          Text(
            widget.typingUsers.length == 1
                ? '${widget.typingUsers.first} schreibt...'
                : '${widget.typingUsers.length} Personen schreiben...',
            style: const TextStyle(color: Colors.white60, fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}

// ========================================
// 😄 REACTION PICKER
// ========================================
class ReactionPicker extends StatelessWidget {
  final Function(String) onReactionSelected;

  const ReactionPicker({super.key, required this.onReactionSelected});

  static const reactions = ['👍', '❤️', '😄', '🤔', '😮', '😢', '🎉', '🔥'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: reactions.map((emoji) {
          return GestureDetector(
            onTap: () => onReactionSelected(emoji),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ========================================
// 💬 REPLY PREVIEW WIDGET
// ========================================
class ReplyPreview extends StatelessWidget {
  final EnhancedChatMessage replyToMessage;
  final VoidCallback onCancel;

  const ReplyPreview({
    super.key,
    required this.replyToMessage,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        border: Border(
          left: BorderSide(color: Colors.blue, width: 4),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Antwort an ${replyToMessage.username}',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  replyToMessage.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70, size: 20),
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }
}

// ========================================
// 📱 ENHANCED MESSAGE BUBBLE
// ========================================
class EnhancedMessageBubble extends StatelessWidget {
  final EnhancedChatMessage message;
  final bool isMyMessage;
  final VoidCallback onReply;
  final Function(String) onReaction;
  final VoidCallback onUserTap;
  final EnhancedChatMessage? replyToMessage;

  const EnhancedMessageBubble({
    super.key,
    required this.message,
    required this.isMyMessage,
    required this.onReply,
    required this.onReaction,
    required this.onUserTap,
    this.replyToMessage,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        _showMessageOptions(context);
      },
      child: Align(
        alignment: isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isMyMessage ? const Color(0xFF1976D2) : const Color(0xFF2A2A3E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Username (for others' messages)
              if (!isMyMessage)
                GestureDetector(
                  onTap: onUserTap,
                  child: Text(
                    message.username,
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              
              // Reply indicator
              if (replyToMessage != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        replyToMessage!.username,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        replyToMessage!.content,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white60, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
              ],
              
              // Message content
              Text(
                message.content,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              
              // Reactions
              if (message.reactions.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  children: message.reactions.entries.map((entry) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${entry.key} ${entry.value}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.reply, color: Colors.blue),
            title: const Text('Antworten', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              onReply();
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_reaction, color: Colors.amber),
            title: const Text('Reaktion hinzufügen', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _showReactionPicker(context);
            },
          ),
        ],
      ),
    );
  }

  void _showReactionPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ReactionPicker(
          onReactionSelected: (emoji) {
            onReaction(emoji);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
