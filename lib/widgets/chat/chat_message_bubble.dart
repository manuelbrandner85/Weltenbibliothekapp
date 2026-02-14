/// 💬 CHAT MESSAGE BUBBLE
/// 
/// Complete message bubble widget with:
/// - Text, image, voice, file message types
/// - Reactions display
/// - Reply preview
/// - Edit indicator
/// - Long-press context menu
/// - Read receipts
/// - Delivery status
library;

import 'package:flutter/material.dart';
import '../../models/chat_models.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isCurrentUser;
  final Function(String messageId, String emoji)? onAddReaction;
  final Function(String messageId, String emoji)? onRemoveReaction;
  final Function(ChatMessage message)? onReply;
  final Function(String messageId)? onEdit;
  final Function(String messageId)? onDelete;
  final Map<String, List<String>>? reactions;
  
  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.onAddReaction,
    this.onRemoveReaction,
    this.onReply,
    this.onEdit,
    this.onDelete,
    this.reactions,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: isCurrentUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar (for other users)
          if (!isCurrentUser) ...[
            _buildAvatar(context),
            const SizedBox(width: 8),
          ],
          
          // Message content
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showContextMenu(context),
              child: Column(
                crossAxisAlignment: isCurrentUser 
                    ? CrossAxisAlignment.end 
                    : CrossAxisAlignment.start,
                children: [
                  // Sender name (for other users)
                  if (!isCurrentUser)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4, left: 12),
                      child: Text(
                        message.senderName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  
                  // Message container
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    decoration: BoxDecoration(
                      color: isCurrentUser
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isCurrentUser ? 18 : 4),
                        bottomRight: Radius.circular(isCurrentUser ? 4 : 18),
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
                      children: [
                        // Reply preview (if replying to another message)
                        if (message.isReply) _buildReplyPreview(context),
                        
                        // Message content based on type
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: _buildMessageContent(context),
                        ),
                        
                        // Message footer (timestamp, status, edited)
                        _buildMessageFooter(context),
                      ],
                    ),
                  ),
                  
                  // Reactions
                  if (reactions != null && reactions!.isNotEmpty)
                    _buildReactionsBar(context),
                ],
              ),
            ),
          ),
          
          // Avatar (for current user)
          if (isCurrentUser) ...[
            const SizedBox(width: 8),
            _buildAvatar(context),
          ],
        ],
      ),
    );
  }
  
  // ==========================================================================
  // AVATAR
  // ==========================================================================
  
  Widget _buildAvatar(BuildContext context) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
      backgroundImage: message.senderAvatarUrl != null
          ? NetworkImage(message.senderAvatarUrl!)
          : null,
      child: message.senderAvatarUrl == null
          ? Text(
              message.senderName.isNotEmpty 
                  ? message.senderName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            )
          : null,
    );
  }
  
  // ==========================================================================
  // REPLY PREVIEW
  // ==========================================================================
  
  Widget _buildReplyPreview(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8, left: 12, right: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? Colors.white.withValues(alpha: 0.2)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: isCurrentUser ? Colors.white : Theme.of(context).primaryColor,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.replyToSenderName ?? 'Unknown',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isCurrentUser
                  ? Colors.white.withValues(alpha: 0.9)
                  : Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            message.replyToContent ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: isCurrentUser
                  ? Colors.white.withValues(alpha: 0.7)
                  : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  
  // ==========================================================================
  // MESSAGE CONTENT BY TYPE
  // ==========================================================================
  
  Widget _buildMessageContent(BuildContext context) {
    switch (message.type) {
      case MessageType.text:
        return _buildTextMessage(context);
      case MessageType.image:
        return _buildImageMessage(context);
      case MessageType.voice:
        return _buildVoiceMessage(context);
      case MessageType.file:
        return _buildFileMessage(context);
      case MessageType.system:
        return _buildSystemMessage(context);
      case MessageType.deleted:
        return _buildDeletedMessage(context);
    }
  }
  
  Widget _buildTextMessage(BuildContext context) {
    return SelectableText(
      message.content,
      style: TextStyle(
        fontSize: 15,
        height: 1.4,
        color: isCurrentUser ? Colors.white : Colors.black87,
      ),
    );
  }
  
  Widget _buildImageMessage(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.content.isNotEmpty) ...[
          Text(
            message.content,
            style: TextStyle(
              fontSize: 15,
              color: isCurrentUser ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            message.imageUrl!,
            fit: BoxFit.cover,
            width: double.infinity,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 200,
                alignment: Alignment.center,
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 200,
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image, size: 50),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildVoiceMessage(BuildContext context) {
    final duration = message.metadata['duration'] as int? ?? 0;
    
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isCurrentUser
                ? Colors.white.withValues(alpha: 0.2)
                : Theme.of(context).primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.play_arrow,
            color: isCurrentUser ? Colors.white : Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 30,
                decoration: BoxDecoration(
                  color: isCurrentUser
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: List.generate(
                    20,
                    (index) => Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: isCurrentUser
                              ? Colors.white.withValues(alpha: 0.5)
                              : Theme.of(context).primaryColor.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$duration sec',
                style: TextStyle(
                  fontSize: 12,
                  color: isCurrentUser
                      ? Colors.white.withValues(alpha: 0.7)
                      : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildFileMessage(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isCurrentUser
                ? Colors.white.withValues(alpha: 0.2)
                : Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.insert_drive_file,
            color: isCurrentUser ? Colors.white : Theme.of(context).primaryColor,
            size: 28,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.fileName ?? 'File',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isCurrentUser ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                message.formattedFileSize,
                style: TextStyle(
                  fontSize: 12,
                  color: isCurrentUser
                      ? Colors.white.withValues(alpha: 0.7)
                      : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.download,
          color: isCurrentUser ? Colors.white : Theme.of(context).primaryColor,
          size: 20,
        ),
      ],
    );
  }
  
  Widget _buildSystemMessage(BuildContext context) {
    return Text(
      message.content,
      style: TextStyle(
        fontSize: 13,
        fontStyle: FontStyle.italic,
        color: Colors.grey[600],
      ),
    );
  }
  
  Widget _buildDeletedMessage(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.block,
          size: 16,
          color: Colors.grey[400],
        ),
        const SizedBox(width: 8),
        Text(
          'This message was deleted',
          style: TextStyle(
            fontSize: 13,
            fontStyle: FontStyle.italic,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }
  
  // ==========================================================================
  // MESSAGE FOOTER
  // ==========================================================================
  
  Widget _buildMessageFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Edited indicator
          if (message.isEdited) ...[
            Text(
              'edited',
              style: TextStyle(
                fontSize: 10,
                color: isCurrentUser
                    ? Colors.white.withValues(alpha: 0.6)
                    : Colors.grey[500],
              ),
            ),
            const SizedBox(width: 4),
          ],
          
          // Timestamp
          Text(
            _formatTimestamp(message.timestamp),
            style: TextStyle(
              fontSize: 10,
              color: isCurrentUser
                  ? Colors.white.withValues(alpha: 0.7)
                  : Colors.grey[600],
            ),
          ),
          
          // Delivery status (for current user messages)
          if (isCurrentUser) ...[
            const SizedBox(width: 4),
            _buildStatusIcon(context),
          ],
        ],
      ),
    );
  }
  
  Widget _buildStatusIcon(BuildContext context) {
    IconData icon;
    Color color;
    
    switch (message.status) {
      case MessageStatus.sending:
        icon = Icons.access_time;
        color = Colors.white.withValues(alpha: 0.6);
        break;
      case MessageStatus.sent:
        icon = Icons.check;
        color = Colors.white.withValues(alpha: 0.7);
        break;
      case MessageStatus.delivered:
        icon = Icons.done_all;
        color = Colors.white.withValues(alpha: 0.7);
        break;
      case MessageStatus.read:
        icon = Icons.done_all;
        color = Colors.lightGreenAccent;
        break;
      case MessageStatus.failed:
        icon = Icons.error_outline;
        color = Colors.redAccent;
        break;
    }
    
    return Icon(icon, size: 14, color: color);
  }
  
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
  
  // ==========================================================================
  // REACTIONS BAR
  // ==========================================================================
  
  Widget _buildReactionsBar(BuildContext context) {
    if (reactions == null || reactions!.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        children: reactions!.entries.map((entry) {
          final emoji = entry.key;
          final users = entry.value;
          final currentUserId = 'current_user'; // TODO: Get from auth
          final hasReacted = users.contains(currentUserId);
          
          return GestureDetector(
            onTap: () {
              if (hasReacted) {
                onRemoveReaction?.call(message.id, emoji);
              } else {
                onAddReaction?.call(message.id, emoji);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: hasReacted
                    ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: hasReacted
                    ? Border.all(
                        color: Theme.of(context).primaryColor,
                        width: 1.5,
                      )
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 14)),
                  if (users.length > 1) ...[
                    const SizedBox(width: 4),
                    Text(
                      users.length.toString(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: hasReacted
                            ? Theme.of(context).primaryColor
                            : Colors.grey[600],
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
  
  // ==========================================================================
  // CONTEXT MENU
  // ==========================================================================
  
  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reply
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(context);
                onReply?.call(message);
              },
            ),
            
            // Edit (only for current user and text messages)
            if (isCurrentUser && message.type == MessageType.text)
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  onEdit?.call(message.id);
                },
              ),
            
            // Copy text
            if (message.type == MessageType.text)
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Copy to clipboard
                },
              ),
            
            // React
            ListTile(
              leading: const Icon(Icons.add_reaction),
              title: const Text('React'),
              onTap: () {
                Navigator.pop(context);
                _showReactionPicker(context);
              },
            ),
            
            // Delete (only for current user)
            if (isCurrentUser)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context);
                },
              ),
          ],
        ),
      ),
    );
  }
  
  void _showReactionPicker(BuildContext context) {
    // TODO: Show emoji picker
    final emojis = ['👍', '❤️', '😂', '😮', '😢', '🙏'];
    
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: emojis.map((emoji) {
              return GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  onAddReaction?.call(message.id, emoji);
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(emoji, style: const TextStyle(fontSize: 28)),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
  
  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete?.call(message.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
