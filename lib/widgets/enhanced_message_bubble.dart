import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/cloudflare_api_service.dart';
import '../services/file_upload_service.dart';
// import '../services/voice_message_service.dart'; // ❌ Web-only - Disabled for Android
import 'voice_message_player.dart' show ChatVoicePlayer;  // 🎵 CHAT VOICE PLAYER
// 🎤 TELEGRAM VOICE PLAYER (Backup)
import 'read_receipts_indicator.dart'; // 📖 READ RECEIPTS
import 'chat/chat_markdown_text.dart'; // ✨ Markdown-Light

/// 💬 ENHANCED MESSAGE BUBBLE
/// Mit Reactions, Reply, Media, Read Receipts
class EnhancedMessageBubble extends StatefulWidget {
  final Map<String, dynamic> message;
  final String currentUserId;
  final String currentUsername;
  final bool isMyMessage;
  final VoidCallback? onReply;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final Color worldColor; // ENERGIE: purple, MATERIE: red
  
  const EnhancedMessageBubble({
    super.key,
    required this.message,
    required this.currentUserId,
    required this.currentUsername,
    required this.isMyMessage,
    this.onReply,
    this.onEdit,
    this.onDelete,
    this.worldColor = Colors.purple,
  });

  @override
  State<EnhancedMessageBubble> createState() => _EnhancedMessageBubbleState();
}

class _EnhancedMessageBubbleState extends State<EnhancedMessageBubble> {
  List<Map<String, dynamic>> _reactions = [];
  bool _showReactionPicker = false;
  bool _isLoadingReactions = false;
  
  final List<String> _availableEmojis = [
    '👍', '❤️', '😂', '🔥', '✨', '🙏', '💯', '🎉',
    '👁️', '🤔', '💫', '🌟', '🔮', '🧘', '⚡', '🌈'
  ];

  @override
  void initState() {
    super.initState();
    _loadReactions();
  }

  Future<void> _loadReactions() async {
    if (_isLoadingReactions) return;
    
    setState(() => _isLoadingReactions = true);
    
    try {
      final messageId = widget.message['id'];
      if (messageId == null) {
        if (kDebugMode) debugPrint('⚠️ Message missing ID field');
        setState(() => _isLoadingReactions = false);
        return;
      }
      final response = await http.get(
        Uri.parse('${CloudflareApiService.chatFeaturesApiUrl}/messages/$messageId/reactions'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200 && mounted) {
        final Map<String, dynamic> data = json.decode(response.body);
        final Map<String, dynamic> reactions = data['reactions'] ?? {};
        
        // Convert { emoji: [users] } to List<Map> format
        final List<Map<String, dynamic>> reactionsList = [];
        reactions.forEach((emoji, users) {
          if (users is List && users.isNotEmpty) {
            reactionsList.add({
              'emoji': emoji,
              'users': users,
              'count': users.length,
            });
          }
        });
        
        setState(() {
          _reactions = reactionsList;
          _isLoadingReactions = false;
        });
        
        if (kDebugMode) {
          debugPrint('👍 Loaded ${reactionsList.length} reactions for message $messageId');
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Load reactions error: $e');
      if (mounted) setState(() => _isLoadingReactions = false);
    }
  }

  Future<void> _addReaction(String emoji) async {
    try {
      final messageId = widget.message['id'];
      if (messageId == null) {
        if (kDebugMode) debugPrint('⚠️ Cannot add reaction: Message missing ID');
        return;
      }
      
      // 🆕 Direct call to Chat Features Worker
      final response = await http.post(
        Uri.parse('${CloudflareApiService.chatFeaturesApiUrl}/messages/$messageId/react'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': widget.currentUserId,
          'username': widget.currentUsername,
          'emoji': emoji,
        }),
      );
      
      if (response.statusCode == 200) {
        setState(() => _showReactionPicker = false);
        await _loadReactions();
      } else {
        if (kDebugMode) debugPrint('❌ Add reaction failed: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Add reaction error: $e');
    }
  }

  Future<void> _removeReaction(String emoji) async {
    try {
      final messageId = widget.message['id'];
      if (messageId == null) {
        if (kDebugMode) debugPrint('⚠️ Cannot remove reaction: Message missing ID');
        return;
      }
      
      // 🆕 Toggle reaction (same endpoint - Worker handles toggle)
      final response = await http.post(
        Uri.parse('${CloudflareApiService.chatFeaturesApiUrl}/messages/$messageId/react'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': widget.currentUserId,
          'username': widget.currentUsername,
          'emoji': emoji,
        }),
      );
      
      if (response.statusCode == 200) {
        await _loadReactions();
      } else {
        if (kDebugMode) debugPrint('❌ Remove reaction failed: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Remove reaction error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    // Telegram-Style Reply (v36): Snapshot-Spalten aus chat_messages.
    final replyToId = message['reply_to_id']?.toString();
    final replyToContent = message['reply_to_content']?.toString();
    final replyToSender = message['reply_to_sender_name']?.toString();
    final hasReply = replyToId != null && replyToId.isNotEmpty;
    final mediaType = message['media_type'];
    final mediaUrl = message['media_url'];

    return Align(
      alignment: widget.isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: _SwipeToReply(
        enabled: widget.onReply != null,
        isMyMessage: widget.isMyMessage,
        onTriggered: () => widget.onReply?.call(),
        child: InkWell(
          onLongPress: () {
            debugPrint('🔧 [Mobile Fix] Long press detected on message');
            _showMessageActions(context);
          },
          onTap: () {
            // Optional: tap to show actions on mobile
            if (defaultTargetPlatform == TargetPlatform.android ||
                defaultTargetPlatform == TargetPlatform.iOS) {
              debugPrint('🔧 [Mobile Fix] Tap detected - showing actions');
              _showMessageActions(context);
            }
          },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Column(
            crossAxisAlignment: widget.isMyMessage
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              // Telegram-Style Reply-Preview (Quote-Snapshot).
              if (hasReply)
                _buildReplyPreview(
                  senderName: replyToSender,
                  content: replyToContent,
                ),
              
              // Main message bubble
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.isMyMessage 
                      ? widget.worldColor.withValues(alpha: 0.3)
                      : const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.worldColor.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User info
                    Row(
                      children: [
                        // Avatar
                        if (message['avatar_url'] != null && 
                            (message['avatar_url'] as String).startsWith('http'))
                          ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: message['avatar_url'],
                              width: 24,
                              height: 24,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => Text(
                                message['avatar'] ?? '👤',
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                          )
                        else if (message['avatar'] != null) 
                          Text(
                            message['avatar'],
                            style: const TextStyle(fontSize: 20),
                          )
                        else if (!widget.isMyMessage) 
                          const Text('👤', style: TextStyle(fontSize: 20)),
                        
                        const SizedBox(width: 8),
                        
                        // Username
                        Text(
                          message['username'] ?? 'Unknown',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: widget.isMyMessage 
                                ? Colors.white70 
                                : widget.worldColor,
                          ),
                        ),
                        
                        // Edited indicator
                        if (message['edited'] == 1 || message['edited'] == true) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(bearbeitet)',
                            style: TextStyle(
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                              color: widget.isMyMessage 
                                  ? Colors.white60 
                                  : Colors.grey[500],
                            ),
                          ),
                        ],
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Media (Image/Voice)
                    if (mediaType != null && mediaUrl != null)
                      _buildMediaContent(mediaType, mediaUrl),
                    
                    // Text message (mit Markdown-Light + klickbaren Links)
                    if (message['message'] != null &&
                        (message['message'] as String).isNotEmpty)
                      ChatMarkdownText(
                        message['message'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.35,
                        ),
                      ),
                    
                    // Timestamp + Pending-Indicator
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTimestamp(message['timestamp'] ?? ''),
                          style: TextStyle(
                            fontSize: 10,
                            color: widget.isMyMessage
                                ? Colors.white60
                                : Colors.grey[500],
                          ),
                        ),
                        if (message['is_pending'] == true) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.schedule,
                            size: 12,
                            color: widget.isMyMessage
                                ? Colors.white60
                                : Colors.grey[500],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // Reactions
              if (_reactions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Wrap(
                    spacing: 4,
                    children: _reactions.map((reaction) {
                      return InkWell(
                        onTap: () => _removeReaction(reaction['emoji']),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: widget.worldColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: widget.worldColor.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                reaction['emoji'],
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${reaction['count']}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              
              // Reaction Picker
              if (_showReactionPicker)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Wrap(
                    spacing: 4,
                    children: _availableEmojis.map((emoji) {
                      return InkWell(
                        onTap: () => _addReaction(emoji),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          child: Text(emoji, style: const TextStyle(fontSize: 24)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              
              // 📖 READ RECEIPTS (nur für eigene Nachrichten)
              if (widget.isMyMessage && widget.message['id'] != null)
                ReadReceiptsIndicator(
                  messageId: widget.message['id'],
                  currentUserId: widget.currentUserId,
                  worldColor: widget.worldColor,
                ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  /// Telegram-Style Reply-Preview: linker farbiger Balken + Sendername (bold)
  /// + gekürzter Zitatinhalt. Snapshot-Felder aus der DB, daher bleibt die
  /// Quote auch sichtbar wenn die Original-Nachricht gelöscht wurde.
  Widget _buildReplyPreview({String? senderName, String? content}) {
    final name = (senderName ?? '').trim().isEmpty
        ? 'Nachricht'
        : senderName!.trim();
    final snippet = (content ?? '').trim();
    final displayContent = snippet.isEmpty ? '[gelöscht]' : snippet;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(color: widget.worldColor, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: widget.worldColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            displayContent,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.75),
              fontStyle: snippet.isEmpty ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMediaContent(String mediaType, String mediaUrl) {
    if (mediaType == 'image') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: 120,
              maxHeight: 300,
              minWidth: 200,
            ),
            child: CachedNetworkImage(
              imageUrl: mediaUrl,
              fit: BoxFit.cover,
              progressIndicatorBuilder: (context, url, progress) {
                return Container(
                  height: 200,
                  color: Colors.grey[850],
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: progress.progress,
                          color: widget.worldColor,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Bild lädt...',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              errorWidget: (context, url, error) {
                return Container(
                  height: 120,
                  width: 200,
                  color: Colors.grey[800],
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.broken_image, color: Colors.white54, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          'Bild konnte nicht geladen werden',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        TextButton.icon(
                          onPressed: () {
                            (context as Element).markNeedsBuild();
                          },
                          icon: const Icon(Icons.refresh, size: 16, color: Colors.white70),
                          label: const Text(
                            'Erneut versuchen',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    } else if (mediaType == 'voice') {
      // 🎵 VOICE MESSAGE PLAYER (REAL)
      final audioUrl = widget.message['media_url'] as String?;
      final durationSeconds = widget.message['duration'] as int?;
      
      if (audioUrl != null) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: ChatVoicePlayer(
            audioUrl: audioUrl,
            duration: durationSeconds != null 
                ? Duration(seconds: durationSeconds)
                : Duration.zero,
            accentColor: widget.worldColor,
          ),
        );
      }
      
      // Fallback wenn keine URL
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_arrow, color: widget.worldColor),
            const SizedBox(width: 8),
            const Text('Sprachnachricht', style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    } else if (mediaType == 'file') {
      // 📁 FILE ATTACHMENT
      final fileUrl = mediaUrl; // ignore: unused_local_variable
      final filename = widget.message['filename'] as String? ?? 'Datei';
      final fileSize = widget.message['file_size'] as int? ?? 0;
      
      final isImage = FileUploadService.isImageFile(filename);
      final isDocument = FileUploadService.isDocumentFile(filename);
      final isVideo = FileUploadService.isVideoFile(filename);

      IconData icon;
      Color iconColor;

      if (isImage) {
        icon = Icons.image;
        iconColor = Colors.blue;
      } else if (isDocument) {
        icon = Icons.description;
        iconColor = Colors.red;
      } else if (isVideo) {
        icon = Icons.video_library;
        iconColor = Colors.purple;
      } else {
        icon = Icons.insert_drive_file;
        iconColor = Colors.grey;
      }

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: iconColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 32),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    filename,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    FileUploadService.formatFileSize(fileSize),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.download, color: iconColor, size: 20),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
  
  void _showMessageActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.add_reaction, color: widget.worldColor),
                title: const Text('Reagieren', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _showReactionPicker = !_showReactionPicker);
                },
              ),
              ListTile(
                leading: const Icon(Icons.reply, color: Colors.blue),
                title: const Text('Antworten', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onReply?.call();
                },
              ),
              if (widget.isMyMessage) ...[
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.orange),
                  title: const Text('Bearbeiten', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(ctx);
                    widget.onEdit?.call();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Löschen', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(ctx);
                    widget.onDelete?.call();
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }
  
  String _formatTimestamp(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(dt);
      
      if (diff.inMinutes < 1) return 'Gerade eben';
      if (diff.inHours < 1) return '${diff.inMinutes}m';
      if (diff.inDays < 1) return '${diff.inHours}h';
      if (diff.inDays < 7) return '${diff.inDays}d';
      
      return '${dt.day}.${dt.month}.${dt.year}';
    } catch (e) {
      return '';
    }
  }
}

/// Telegram-Style Swipe-to-Reply wrapper.
/// Swipes the child horizontally (left for own messages, right for others) and
/// triggers [onTriggered] once the drag exceeds [_kTriggerDistance].
class _SwipeToReply extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final bool isMyMessage;
  final VoidCallback onTriggered;

  const _SwipeToReply({
    required this.child,
    required this.enabled,
    required this.isMyMessage,
    required this.onTriggered,
  });

  @override
  State<_SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<_SwipeToReply>
    with SingleTickerProviderStateMixin {
  static const double _kTriggerDistance = 60.0;
  static const double _kMaxDistance = 90.0;

  double _dragOffset = 0.0;
  bool _triggered = false;
  late final AnimationController _reset;

  @override
  void initState() {
    super.initState();
    _reset = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    )..addListener(() {
        setState(() {
          _dragOffset = _dragOffset * (1 - _reset.value);
        });
      });
  }

  @override
  void dispose() {
    _reset.dispose();
    super.dispose();
  }

  void _onUpdate(DragUpdateDetails d) {
    if (!widget.enabled) return;
    final dx = d.delta.dx;
    // Own messages: swipe left (negative dx). Others: swipe right.
    if (widget.isMyMessage && dx > 0 && _dragOffset == 0) return;
    if (!widget.isMyMessage && dx < 0 && _dragOffset == 0) return;

    setState(() {
      _dragOffset = (_dragOffset + dx).clamp(-_kMaxDistance, _kMaxDistance);
    });

    if (!_triggered && _dragOffset.abs() >= _kTriggerDistance) {
      _triggered = true;
      HapticFeedback.mediumImpact();
      widget.onTriggered();
    }
  }

  void _onEnd(DragEndDetails _) {
    _triggered = false;
    _reset.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final iconOpacity =
        (_dragOffset.abs() / _kTriggerDistance).clamp(0.0, 1.0);
    final showOnRight = widget.isMyMessage; // own swipe left → icon on right
    return GestureDetector(
      onHorizontalDragUpdate: _onUpdate,
      onHorizontalDragEnd: _onEnd,
      behavior: HitTestBehavior.translucent,
      child: Stack(
        alignment: showOnRight
            ? Alignment.centerRight
            : Alignment.centerLeft,
        children: [
          Opacity(
            opacity: iconOpacity,
            child: Padding(
              padding: EdgeInsets.only(
                left: showOnRight ? 0 : 8,
                right: showOnRight ? 8 : 0,
              ),
              child: const Icon(
                Icons.reply,
                color: Colors.white70,
                size: 20,
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(_dragOffset, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
