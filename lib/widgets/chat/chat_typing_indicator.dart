/// 💬 CHAT TYPING INDICATOR
/// 
/// Animated typing indicator showing who is currently typing
/// 
/// Features:
/// - Animated dots
/// - Multiple users support
/// - User names display
/// - Smooth animations
library;

import 'package:flutter/material.dart';

class ChatTypingIndicator extends StatefulWidget {
  final Set<String> typingUsers;
  
  const ChatTypingIndicator({
    super.key,
    required this.typingUsers,
  });

  @override
  State<ChatTypingIndicator> createState() => _ChatTypingIndicatorState();
}

class _ChatTypingIndicatorState extends State<ChatTypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.typingUsers.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            child: Icon(
              Icons.edit,
              size: 16,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          
          // Typing container
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                  bottomLeft: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // User names
                  Text(
                    _buildTypingText(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // Animated dots
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildAnimatedDot(0),
                      const SizedBox(width: 4),
                      _buildAnimatedDot(1),
                      const SizedBox(width: 4),
                      _buildAnimatedDot(2),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _buildTypingText() {
    final users = widget.typingUsers.toList();
    
    if (users.length == 1) {
      return '${users[0]} is typing...';
    } else if (users.length == 2) {
      return '${users[0]} and ${users[1]} are typing...';
    } else if (users.length == 3) {
      return '${users[0]}, ${users[1]} and ${users[2]} are typing...';
    } else {
      return '${users[0]}, ${users[1]} and ${users.length - 2} others are typing...';
    }
  }
  
  Widget _buildAnimatedDot(int index) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final delay = index * 0.15;
        final value = _animationController.value - delay;
        final normalizedValue = (value % 1.0).clamp(0.0, 1.0);
        
        // Create bounce effect
        double scale;
        if (normalizedValue < 0.5) {
          scale = 1.0 + (normalizedValue * 2 * 0.5);
        } else {
          scale = 1.5 - ((normalizedValue - 0.5) * 2 * 0.5);
        }
        
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
