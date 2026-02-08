import 'package:flutter/material.dart';
import '../models/enhanced_chat_message.dart';
import '../utils/responsive_utils.dart';
import '../utils/responsive_text_styles.dart';
import '../utils/responsive_spacing.dart';

/// Enhanced Chat Message Bubble mit Reactions & Mentions
/// ✅ RESPONSIVE: Automatische Anpassung an Bildschirmgröße
class EnhancedChatBubble extends StatefulWidget {
  final EnhancedChatMessage message;
  final String currentUsername;
  final Function(String emoji) onAddReaction;
  final Function(String emoji) onRemoveReaction;
  final VoidCallback? onEdit; // 🆕 Bearbeiten-Callback
  final VoidCallback? onDelete; // 🆕 Löschen-Callback
  final Color accentColor;
  
  const EnhancedChatBubble({
    super.key,
    required this.message,
    required this.currentUsername,
    required this.onAddReaction,
    required this.onRemoveReaction,
    this.onEdit, // 🆕 Optional
    this.onDelete, // 🆕 Optional
    required this.accentColor,
  });

  @override
  State<EnhancedChatBubble> createState() => _EnhancedChatBubbleState();
}

class _EnhancedChatBubbleState extends State<EnhancedChatBubble> {
  bool _showReactionPicker = false;
  
  // Quick Reactions
  final List<String> _quickReactions = ['❤️', '👍', '😂', '🎉', '🔥', '👀', '💯', '🤔'];

  @override
  Widget build(BuildContext context) {
    // ✅ RESPONSIVE UTILITIES
    final responsive = context.responsive;
    final textStyles = context.textStyles;
    
    final isOwnMessage = widget.message.username == widget.currentUsername;
    final hasMentions = widget.message.mentions.contains(widget.currentUsername);
    
    return GestureDetector(
      onLongPress: () {
        if (isOwnMessage) {
          // Eigene Nachricht: Zeige Bearbeiten/Löschen-Menü
          _showActionMenu(context);
        } else {
          // Fremde Nachricht: Zeige Reaction Picker
          setState(() => _showReactionPicker = !_showReactionPicker);
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: responsive.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Message Bubble
            Container(
              padding: context.paddingMd,
              decoration: BoxDecoration(
                gradient: isOwnMessage
                    ? LinearGradient(
                        colors: [
                          widget.accentColor.withValues(alpha: 0.3),
                          widget.accentColor.withValues(alpha: 0.1),
                        ],
                      )
                    : hasMentions
                        ? LinearGradient(
                            colors: [
                              Colors.amber.withValues(alpha: 0.3),
                              Colors.amber.withValues(alpha: 0.1),
                            ],
                          )
                        : null,
                color: isOwnMessage || hasMentions 
                    ? null 
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(responsive.borderRadiusMd),
                border: Border.all(
                  color: hasMentions 
                      ? Colors.amber.withValues(alpha: 0.5) 
                      : isOwnMessage
                          ? widget.accentColor.withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.1),
                  width: hasMentions ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      // Avatar
                      Text(
                        widget.message.avatarEmoji ?? '👤',
                        style: TextStyle(fontSize: responsive.iconSizeMd),
                      ),
                      SizedBox(width: responsive.spacingSm),
                      
                      // Username
                      Expanded(
                        child: Text(
                          widget.message.username,
                          style: textStyles.chatUsername.copyWith(
                            color: widget.accentColor,
                          ),
                        ),
                      ),
                      
                      // Mention Badge
                      if (hasMentions)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: responsive.spacingSm,
                            vertical: responsive.spacingXs,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(responsive.borderRadiusSm),
                          ),
                          child: Text(
                            '@',
                            style: textStyles.labelSmall.copyWith(
                              color: Colors.black,
                            ),
                          ),
                        ),
                      
                      SizedBox(width: responsive.spacingSm),
                      
                      // Timestamp
                      Text(
                        _formatTime(widget.message.timestamp),
                        style: textStyles.chatTimestamp,
                      ),
                    ],
                  ),
                  
                  SizedBox(height: responsive.spacingSm),
                  
                  // Message Text mit Mentions Highlighting
                  _buildMessageText(),
                ],
              ),
            ),
            
            // Reactions
            if (widget.message.reactions.isNotEmpty)
              _buildReactionsRow(),
            
            // Reaction Picker
            if (_showReactionPicker)
              _buildReactionPicker(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMessageText() {
    // ✅ RESPONSIVE TEXT
    final textStyles = ResponsiveTextStyles.of(context);
    
    final text = widget.message.message;
    final mentions = widget.message.mentions;
    
    if (mentions.isEmpty) {
      return Text(
        text,
        style: textStyles.chatMessage,
      );
    }
    
    // Highlight Mentions
    final spans = <TextSpan>[];
    final words = text.split(' ');
    
    for (var word in words) {
      if (word.startsWith('@')) {
        final username = word.substring(1);
        spans.add(TextSpan(
          text: word,
          style: TextStyle(
            color: username == widget.currentUsername 
                ? Colors.amber 
                : widget.accentColor,
            fontWeight: FontWeight.bold,
            backgroundColor: username == widget.currentUsername
                ? Colors.amber.withValues(alpha: 0.2)
                : null,
          ),
        ));
      } else {
        spans.add(TextSpan(
          text: word,
          style: const TextStyle(color: Colors.white),
        ));
      }
      
      // Leerzeichen nach jedem Wort
      if (word != words.last) {
        spans.add(const TextSpan(text: ' '));
      }
    }
    
    return RichText(
      text: TextSpan(
        children: spans,
        style: textStyles.chatMessage,
      ),
    );
  }
  
  Widget _buildReactionsRow() {
    // ✅ RESPONSIVE SPACING
    final responsive = ResponsiveUtils.of(context);
    final textStyles = ResponsiveTextStyles.of(context);
    
    return Padding(
      padding: EdgeInsets.only(
        top: responsive.spacingSm,
        left: responsive.spacingXs,
      ),
      child: Wrap(
        spacing: responsive.spacingXs,
        runSpacing: responsive.spacingXs,
        children: widget.message.reactions.entries.map((entry) {
          final emoji = entry.key;
          final users = entry.value;
          final hasReacted = users.contains(widget.currentUsername);
          
          return GestureDetector(
            onTap: () {
              if (hasReacted) {
                widget.onRemoveReaction(emoji);
              } else {
                widget.onAddReaction(emoji);
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.spacingSm,
                vertical: responsive.spacingXs,
              ),
              decoration: BoxDecoration(
                color: hasReacted
                    ? widget.accentColor.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(responsive.borderRadiusSm),
                border: Border.all(
                  color: hasReacted
                      ? widget.accentColor
                      : Colors.white.withValues(alpha: 0.2),
                  width: hasReacted ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    emoji,
                    style: TextStyle(fontSize: responsive.iconSizeSm),
                  ),
                  SizedBox(width: responsive.spacingXs),
                  Text(
                    '${users.length}',
                    style: textStyles.labelSmall.copyWith(
                      color: hasReacted ? widget.accentColor : Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildReactionPicker() {
    // ✅ RESPONSIVE SIZES
    final responsive = ResponsiveUtils.of(context);
    
    return Container(
      margin: EdgeInsets.only(
        top: responsive.spacingSm,
        left: responsive.spacingXs,
      ),
      padding: context.paddingSm,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(responsive.borderRadiusLg),
        border: Border.all(
          color: widget.accentColor.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.accentColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Wrap(
        spacing: responsive.spacingSm,
        runSpacing: responsive.spacingSm,
        children: _quickReactions.map((emoji) {
          return GestureDetector(
            onTap: () {
              widget.onAddReaction(emoji);
              setState(() => _showReactionPicker = false);
            },
            child: Container(
              width: responsive.iconSizeXl,
              height: responsive.iconSizeXl,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(responsive.borderRadiusSm),
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: TextStyle(fontSize: responsive.iconSizeLg),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inMinutes < 1) return 'Jetzt';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
  
  // 🆕 Zeige Aktions-Menü für eigene Nachrichten
  void _showActionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black.withValues(alpha: 0.95),
              widget.accentColor.withValues(alpha: 0.2),
            ],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(
            color: widget.accentColor.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Bearbeiten-Button
              if (widget.onEdit != null)
                ListTile(
                  leading: Icon(
                    Icons.edit_outlined,
                    color: widget.accentColor,
                  ),
                  title: const Text(
                    'Nachricht bearbeiten',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onEdit?.call();
                  },
                ),
              
              // Löschen-Button
              if (widget.onDelete != null)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                  title: const Text(
                    'Nachricht löschen',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDelete(context);
                  },
                ),
              
              // Abbrechen-Button
              ListTile(
                leading: Icon(
                  Icons.close,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                title: Text(
                  'Abbrechen',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                onTap: () => Navigator.pop(context),
              ),
              
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
  
  // 🆕 Lösch-Bestätigung
  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.red.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 12),
            Text(
              'Nachricht löschen?',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: const Text(
          'Diese Aktion kann nicht rückgängig gemacht werden.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Abbrechen',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }
}
