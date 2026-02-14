/// 💬 CHAT INPUT BAR
/// 
/// Message composition widget with:
/// - Text input with multi-line support
/// - Image/file attachment
/// - Voice message recording
/// - Reply preview
/// - Edit mode
/// - Emoji picker
/// - Send button
library;

import 'package:flutter/material.dart';
import '../../models/chat_models.dart';

class ChatInputBar extends StatefulWidget {
  final Function(String content) onSendMessage;
  final Function(String content)? onEditMessage;
  final VoidCallback? onTyping;
  final VoidCallback? onCancelReply;
  final VoidCallback? onCancelEdit;
  final ChatMessage? replyToMessage;
  final String? editingMessageId;
  final String? editingMessageContent;
  
  const ChatInputBar({
    super.key,
    required this.onSendMessage,
    this.onEditMessage,
    this.onTyping,
    this.onCancelReply,
    this.onCancelEdit,
    this.replyToMessage,
    this.editingMessageId,
    this.editingMessageContent,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isComposing = false;
  bool _isRecordingVoice = false;
  
  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleTextChanged);
    
    // Pre-fill with editing content
    if (widget.editingMessageContent != null) {
      _controller.text = widget.editingMessageContent!;
      _isComposing = true;
    }
  }
  
  @override
  void didUpdateWidget(ChatInputBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update text when editing message changes
    if (widget.editingMessageId != oldWidget.editingMessageId) {
      if (widget.editingMessageContent != null) {
        _controller.text = widget.editingMessageContent!;
        _isComposing = true;
        _focusNode.requestFocus();
      } else {
        _controller.clear();
        _isComposing = false;
      }
    }
  }
  
  @override
  void dispose() {
    _controller.removeListener(_handleTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
  
  void _handleTextChanged() {
    final isComposing = _controller.text.trim().isNotEmpty;
    if (isComposing != _isComposing) {
      setState(() {
        _isComposing = isComposing;
      });
    }
    
    // Notify typing
    if (isComposing) {
      widget.onTyping?.call();
    }
  }
  
  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    
    if (widget.editingMessageId != null) {
      // Edit mode
      widget.onEditMessage?.call(text);
    } else {
      // Send mode
      widget.onSendMessage(text);
    }
    
    _controller.clear();
    setState(() {
      _isComposing = false;
    });
    
    _focusNode.requestFocus();
  }
  
  void _handleImagePicker() {
    // TODO: Implement image picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image picker coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  void _handleFilePicker() {
    // TODO: Implement file picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('File picker coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  void _handleVoiceRecording() {
    setState(() {
      _isRecordingVoice = !_isRecordingVoice;
    });
    
    if (_isRecordingVoice) {
      // TODO: Start voice recording
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voice recording started...'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      // TODO: Stop voice recording and send
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voice recording stopped'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
  
  void _handleEmojiPicker() {
    // TODO: Show emoji picker
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 300,
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 8,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: 64,
          itemBuilder: (context, index) {
            final emojis = [
              '😀', '😃', '😄', '😁', '😆', '😅', '🤣', '😂',
              '🙂', '🙃', '😉', '😊', '😇', '🥰', '😍', '🤩',
              '😘', '😗', '😚', '😙', '😋', '😛', '😜', '🤪',
              '😝', '🤑', '🤗', '🤭', '🤫', '🤔', '🤐', '🤨',
              '😐', '😑', '😶', '😏', '😒', '🙄', '😬', '🤥',
              '😌', '😔', '😪', '🤤', '😴', '😷', '🤒', '🤕',
              '🤢', '🤮', '🤧', '🥵', '🥶', '🥴', '😵', '🤯',
              '🤠', '🥳', '😎', '🤓', '🧐', '😕', '😟', '🙁',
            ];
            
            if (index >= emojis.length) return const SizedBox.shrink();
            
            return GestureDetector(
              onTap: () {
                _controller.text += emojis[index];
                Navigator.pop(context);
              },
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  emojis[index],
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reply preview
            if (widget.replyToMessage != null) _buildReplyPreview(),
            
            // Edit mode indicator
            if (widget.editingMessageId != null) _buildEditModeBar(),
            
            // Input bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Attachment buttons
                  if (!_isRecordingVoice) ...[
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      color: Theme.of(context).primaryColor,
                      onPressed: _showAttachmentMenu,
                      tooltip: 'Attachments',
                    ),
                  ],
                  
                  // Text input field
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Emoji button
                          IconButton(
                            icon: const Icon(Icons.emoji_emotions_outlined),
                            color: Colors.grey[600],
                            onPressed: _handleEmojiPicker,
                            padding: const EdgeInsets.only(left: 8),
                          ),
                          
                          // Text field
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              decoration: const InputDecoration(
                                hintText: 'Type a message...',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 10,
                                ),
                              ),
                              maxLines: null,
                              keyboardType: TextInputType.multiline,
                              textInputAction: TextInputAction.newline,
                              textCapitalization: TextCapitalization.sentences,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Send / Voice button
                  Container(
                    decoration: BoxDecoration(
                      color: _isComposing || _isRecordingVoice
                          ? Theme.of(context).primaryColor
                          : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isRecordingVoice
                            ? Icons.stop
                            : _isComposing
                                ? Icons.send
                                : Icons.mic,
                      ),
                      color: _isComposing || _isRecordingVoice
                          ? Colors.white
                          : Colors.grey[600],
                      onPressed: _isComposing
                          ? _handleSend
                          : _handleVoiceRecording,
                      tooltip: _isComposing ? 'Send' : 'Voice message',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // ==========================================================================
  // REPLY PREVIEW
  // ==========================================================================
  
  Widget _buildReplyPreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to ${widget.replyToMessage!.senderName}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.replyToMessage!.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            color: Colors.grey[600],
            onPressed: widget.onCancelReply,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
  
  // ==========================================================================
  // EDIT MODE BAR
  // ==========================================================================
  
  Widget _buildEditModeBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        border: Border(
          top: BorderSide(
            color: Colors.orange.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.edit,
            size: 18,
            color: Colors.orange,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Edit message',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.orange[700],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            color: Colors.orange[700],
            onPressed: widget.onCancelEdit,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
  
  // ==========================================================================
  // ATTACHMENT MENU
  // ==========================================================================
  
  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              
              // Title
              Text(
                'Send Attachment',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              
              // Attachment options
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttachmentOption(
                    context,
                    icon: Icons.image,
                    label: 'Image',
                    color: Colors.purple,
                    onTap: () {
                      Navigator.pop(context);
                      _handleImagePicker();
                    },
                  ),
                  _buildAttachmentOption(
                    context,
                    icon: Icons.insert_drive_file,
                    label: 'File',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      _handleFilePicker();
                    },
                  ),
                  _buildAttachmentOption(
                    context,
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    color: Colors.red,
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Camera
                    },
                  ),
                  _buildAttachmentOption(
                    context,
                    icon: Icons.location_on,
                    label: 'Location',
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Location
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildAttachmentOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
