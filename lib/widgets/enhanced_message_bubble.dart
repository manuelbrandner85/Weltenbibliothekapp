import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/cloudflare_api_service.dart';
import '../services/file_upload_service.dart';
// import '../services/voice_message_service.dart'; // ❌ Web-only - Disabled for Android
import 'voice_message_player.dart' show ChatVoicePlayer;  // 🎵 CHAT VOICE PLAYER
// 🎤 TELEGRAM VOICE PLAYER (Backup)
import 'read_receipts_indicator.dart'; // 📖 READ RECEIPTS

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
    final replyTo = message['reply_to'];
    final mediaType = message['media_type'];
    final mediaUrl = message['media_url'];
    
    return Align(
      alignment: widget.isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: InkWell(
        onLongPress: () {
          print('🔧 [Mobile Fix] Long press detected on message');
          _showMessageActions(context);
        },
        onTap: () {
          // Optional: tap to show actions on mobile
          if (defaultTargetPlatform == TargetPlatform.android || 
              defaultTargetPlatform == TargetPlatform.iOS) {
            print('🔧 [Mobile Fix] Tap detected - showing actions');
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
              // Reply preview
              if (replyTo != null)
                _buildReplyPreview(replyTo),
              
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
                            child: Image.network(
                              message['avatar_url'],
                              width: 24,
                              height: 24,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stack) {
                                return Text(
                                  message['avatar'] ?? '👤',
                                  style: const TextStyle(fontSize: 20),
                                );
                              },
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
                    
                    // Text message
                    if (message['message'] != null && 
                        (message['message'] as String).isNotEmpty)
                      Text(
                        message['message'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    
                    // Timestamp
                    const SizedBox(height: 4),
                    Text(
                      _formatTimestamp(message['timestamp'] ?? ''),
                      style: TextStyle(
                        fontSize: 10,
                        color: widget.isMyMessage 
                            ? Colors.white60 
                            : Colors.grey[500],
                      ),
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
    );
  }
  
  Widget _buildReplyPreview(String replyToId) {
    // TODO: Load reply message details
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: widget.worldColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.reply, size: 14, color: widget.worldColor),
          const SizedBox(width: 4),
          const Text(
            'Antwort auf...',
            style: TextStyle(fontSize: 12, color: Colors.white70),
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
            child: Image.network(
              mediaUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 200,
                  color: Colors.grey[850],
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
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
              errorBuilder: (context, error, stack) {
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
                            // Reload by forcing rebuild
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
      final fileUrl = mediaUrl;
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
