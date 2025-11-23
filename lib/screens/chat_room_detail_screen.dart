import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/chat_room_model.dart';
import '../models/message.dart';
import '../services/cloudflare_chat_service.dart';
import '../services/auth_service.dart';
import '../services/live_room_service.dart';
import '../providers/webrtc_provider.dart';
import '../widgets/telegram_voice_chat_widget.dart';
import '../widgets/telegram_live_banner.dart';
import '../widgets/music/music_mini_player.dart';
import '../widgets/enhanced_radio_player.dart';
import '../widgets/chat_background_carousel.dart';
import '../utils/optimized_page_route.dart';
import 'live_stream_host_screen.dart';
import 'live_stream_viewer_screen.dart';
import 'package:flutter/foundation.dart';

class ChatRoomDetailScreen extends StatefulWidget {
  final ChatRoom chatRoom;

  const ChatRoomDetailScreen({super.key, required this.chatRoom});

  @override
  State<ChatRoomDetailScreen> createState() => _ChatRoomDetailScreenState();
}

class _ChatRoomDetailScreenState extends State<ChatRoomDetailScreen> {
  final CloudflareChatService _chatService = CloudflareChatService();
  final AuthService _authService = AuthService();
  final LiveRoomService _liveRoomService = LiveRoomService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Message> _messages = [];
  bool _isLoading = true;
  Timer? _pollingTimer;
  String? _currentUsername;
  LiveRoom? _activeLiveRoom;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadMessages();
    _checkActiveLiveRoom();
    // Poll für neue Nachrichten alle 3 Sekunden
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _loadMessages();
      _checkActiveLiveRoom();
    });
  }

  /// Load current authenticated user
  Future<void> _loadCurrentUser() async {
    try {
      final user = await _authService.getCurrentUser();
      if (mounted && user != null) {
        setState(() {
          _currentUsername = user['username'] as String?;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading current user: $e');
      }
    }
  }

  /// Check if there's an active live room for this chat room
  Future<void> _checkActiveLiveRoom() async {
    try {
      // Get all active live rooms
      final liveRooms = await _liveRoomService.getActiveLiveRooms();

      // CRITICAL FIX: Filter by chatRoomId (not roomId/liveRoomId)
      final activeLiveRoom = liveRooms.cast<LiveRoom?>().firstWhere(
        (room) =>
            room?.chatRoomId == widget.chatRoom.id && room?.isLive == true,
        orElse: () => null,
      );

      if (mounted) {
        setState(() {
          _activeLiveRoom = activeLiveRoom;
        });
      }
    } catch (e) {
      // Silent failure - just means no active live room
      if (kDebugMode) {
        debugPrint('Error checking active live room: $e');
      }
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _chatService.dispose();
    super.dispose();
  }

  /// Konvertiert Raum-Theme zu Chat-Type für Bildauswahl
  String _getChatType(String theme) {
    // Mapping von Theme zu unseren Bildsätzen
    if (theme == 'music') return 'musik';
    if (theme == 'mystery') return 'verschwoerung';
    return 'weltenbibliothek'; // Standard für library, wisdom, etc.
  }

  Future<void> _loadMessages() async {
    try {
      print('📨 [UI] Lade Nachrichten für Raum: ${widget.chatRoom.id}');

      final messages = await _chatService.getMessages(widget.chatRoom.id);

      print('📨 [UI] ${messages.length} Nachrichten geladen');
      for (final msg in messages) {
        print('  - ${msg.senderName}: ${msg.content}');
      }

      if (mounted) {
        setState(() {
          _messages = messages.reversed.toList(); // Neueste zuletzt
          _isLoading = false;
        });

        print('✅ [UI] UI aktualisiert mit ${_messages.length} Nachrichten');
      }
    } catch (e) {
      print('❌ [UI] Fehler beim Laden der Nachrichten: $e');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: widget.chatRoom.isFixed
                    ? const Color(0xFF9B59B6).withValues(alpha: 0.2)
                    : const Color(0xFF3498DB).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  widget.chatRoom.emoji,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.chatRoom.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${widget.chatRoom.memberCount} Mitglieder',
                    style: const TextStyle(fontSize: 12, color: Colors.white60),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // 🎥 Video-Button (VOLLBILD WebRTC Livestream)
          Consumer<WebRTCProvider>(
            builder: (context, webrtcProvider, child) {
              final hasActiveLiveRoom =
                  _activeLiveRoom != null && _activeLiveRoom!.isLive;
              final isHost =
                  hasActiveLiveRoom &&
                  _activeLiveRoom!.hostUsername == _currentUsername;

              return IconButton(
                icon: Icon(
                  hasActiveLiveRoom ? Icons.videocam : Icons.videocam_off,
                  color: hasActiveLiveRoom ? Colors.red : Colors.white,
                ),
                onPressed: () => _toggleRoomStream(context, webrtcProvider),
                tooltip: hasActiveLiveRoom
                    ? (isHost
                          ? 'Zum Livestream (Host)'
                          : 'Livestream beitreten')
                    : 'Livestream starten',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMessages,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showChatInfo(),
          ),
        ],
      ),
      body: ChatBackgroundCarousel(
        chatType: _getChatType(widget.chatRoom.backgroundTheme),
        child: Stack(
          children: [
            // Haupt-Chat-Bereich (Nachrichten)
            Column(
              children: [
                // 🔴 LIVE-Leiste für User die NICHT streamen (wie Telegram)
                TelegramLiveBanner(
                  roomId: widget.chatRoom.id,
                  roomName: widget.chatRoom.name,
                ),

                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF9B59B6),
                          ),
                        )
                      : _messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 64,
                                color: Colors.white30,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Noch keine Nachrichten',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Sei der Erste, der schreibt!',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            final isCurrentUser =
                                message.senderId == 'current_user_id';
                            return _buildMessageBubble(message, isCurrentUser);
                          },
                        ),
                ),

                // 🎵 Mini-Player Integration (conditional)
                if (widget.chatRoom.backgroundTheme == 'music')
                  EnhancedRadioPlayer(
                    activeUserCount: widget.chatRoom.memberCount,
                    isAdmin: _currentUsername == 'admin', // TODO: Replace with actual admin check
                  )
                else
                  const MusicMiniPlayer(),

                // Nachrichteneingabe
                _buildMessageInput(),
              ],
            ),

            // 🎥 Telegram-Style Video Overlay (schwebt ÜBER Nachrichten)
            TelegramVoiceChatWidget(
              roomId: widget.chatRoom.id,
              roomName: widget.chatRoom.name,
            ),
          ],
        ),
      ),
    );
  }

  /// 🎥 Livestream starten oder beitreten (VOLLBILD WebRTC)
  void _toggleRoomStream(
    BuildContext context,
    WebRTCProvider webrtcProvider,
  ) async {
    if (_currentUsername == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Bitte zuerst einloggen'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check permissions first
    try {
      final cameraStatus = await Permission.camera.status;
      final micStatus = await Permission.microphone.status;

      if (!cameraStatus.isGranted || !micStatus.isGranted) {
        final results = await [
          Permission.camera,
          Permission.microphone,
        ].request();

        if (!results[Permission.camera]!.isGranted ||
            !results[Permission.microphone]!.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ Kamera- und Mikrofon-Zugriff erforderlich'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Permission error: $e');
      }
    }

    final roomId = widget.chatRoom.id;

    // Check if there's already an active live room
    if (_activeLiveRoom != null && _activeLiveRoom!.isLive) {
      // Determine if current user is the host
      final isHost = _activeLiveRoom!.hostUsername == _currentUsername;

      if (isHost) {
        // HOST: Navigate to fullscreen host screen
        if (mounted) {
          NavigationHelper.pushFade(
            context,
            LiveStreamHostScreen(
              roomId: roomId,
              chatRoomId: widget.chatRoom.id,
              roomTitle: widget.chatRoom.name,
            ),
          ).then((_) {
            // Refresh when returning from stream
            _checkActiveLiveRoom();
          });
        }
      } else {
        // VIEWER: Navigate to fullscreen viewer screen
        if (mounted) {
          NavigationHelper.pushFade(
            context,
            LiveStreamViewerScreen(
              roomId: roomId,
              chatRoomId: widget.chatRoom.id,
              roomTitle: widget.chatRoom.name,
              hostUsername: _activeLiveRoom!.hostUsername,
            ),
          ).then((_) {
            // Refresh when returning from stream
            _checkActiveLiveRoom();
          });
        }
      }
    } else {
      // No active live room - create one and become HOST
      if (mounted) {
        // Show loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎥 Erstelle Live-Stream...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      try {
        final result = await _liveRoomService.createLiveRoom(
          chatRoomId: widget.chatRoom.id,
          title: 'Live: ${widget.chatRoom.name}',
          description: 'Live-Stream in ${widget.chatRoom.name}',
          category: 'chat',
        );

        if (result['success'] == true) {
          // 🚀 TELEGRAM-STYLE v3.8.0: Check if joining existing stream
          final isExistingStream = result['existing_stream'] == true;
          final room = result['room'] as LiveRoom?;
          final streamRoomId = room?.roomId ?? roomId;

          if (isExistingStream && room != null) {
            // ✅ Joining existing stream
            final isHost = room.hostUsername == _currentUsername;

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '📺 ${result['message'] ?? 'Trete Stream bei'}',
                  ),
                  backgroundColor: const Color(0xFF8B5CF6),
                  duration: const Duration(seconds: 2),
                ),
              );

              // Navigate to appropriate screen
              if (isHost) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LiveStreamHostScreen(
                      roomId: streamRoomId,
                      chatRoomId: widget.chatRoom.id,
                      roomTitle: widget.chatRoom.name,
                    ),
                  ),
                ).then((_) => _checkActiveLiveRoom());
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LiveStreamViewerScreen(
                      roomId: streamRoomId,
                      chatRoomId: widget.chatRoom.id,
                      roomTitle: widget.chatRoom.name,
                      hostUsername: room.hostUsername,
                    ),
                  ),
                ).then((_) => _checkActiveLiveRoom());
              }
            }
          } else {
            // ✅ New stream created - navigate to host screen
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LiveStreamHostScreen(
                    roomId: streamRoomId,
                    chatRoomId: widget.chatRoom.id,
                    roomTitle: widget.chatRoom.name,
                  ),
                ),
              ).then((_) => _checkActiveLiveRoom());
            }
          }
        } else {
          // Generic error
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '❌ ${result['error'] ?? 'Fehler beim Erstellen des Live-Streams'}',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Fehler: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildMessageBubble(Message message, bool isCurrentUser) {
    // ✅ Admins können ALLE Nachrichten bearbeiten/löschen, User nur eigene
    final canEditDelete = isCurrentUser || _currentUsername == 'admin';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onLongPress: () => canEditDelete ? _showMessageOptions(message) : null,
        child: Row(
          mainAxisAlignment: isCurrentUser
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isCurrentUser) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF9B59B6).withValues(alpha: 0.3),
                child: Text(
                  message.senderName[0].toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF9B59B6),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isCurrentUser
                      ? const Color(0xFF9B59B6)
                      : const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isCurrentUser ? 16 : 4),
                    bottomRight: Radius.circular(isCurrentUser ? 4 : 16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isCurrentUser)
                      Text(
                        message.senderName,
                        style: const TextStyle(
                          color: Color(0xFF9B59B6),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    if (!isCurrentUser) const SizedBox(height: 4),
                    Text(
                      message.content,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.4,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (message.isEdited) ...[
                          Icon(
                            Icons.edit,
                            size: 11,
                            color: isCurrentUser
                                ? Colors.white.withValues(alpha: 0.5)
                                : Colors.white24,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          _formatMessageTime(message.timestamp),
                          style: TextStyle(
                            color: isCurrentUser
                                ? Colors.white.withValues(alpha: 0.7)
                                : Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (isCurrentUser) ...[
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF9B59B6).withValues(alpha: 0.3),
                child: Text(
                  message.senderName[0].toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF9B59B6),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 🛠️ Zeigt Optionen für eine Nachricht (Bearbeiten/Löschen)
  void _showMessageOptions(Message message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Bearbeiten-Option
            ListTile(
              leading: const Icon(Icons.edit, color: Color(0xFF3498DB)),
              title: const Text(
                'Nachricht bearbeiten',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _editMessage(message);
              },
            ),
            // Löschen-Option
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Nachricht löschen',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteMessage(message);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// 🗑️ Bestätigt das Löschen einer Nachricht
  void _confirmDeleteMessage(Message message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Nachricht löschen?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Diese Nachricht wird dauerhaft gelöscht und aus der Cloudflare-Datenbank entfernt. Diese Aktion kann nicht rückgängig gemacht werden.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Abbrechen',
              style: TextStyle(color: Colors.white60),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteMessage(message);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 4,
            ),
            child: const Text(
              'Löschen',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🗑️ Löscht eine Nachricht aus Cloudflare D1
  Future<void> _deleteMessage(Message message) async {
    try {
      print('🗑️ [UI] Lösche Nachricht: ${message.id}');

      // Cloudflare API aufrufen
      await _chatService.deleteMessage(
        chatRoomId: widget.chatRoom.id,
        messageId: message.id,
      );

      print('✅ [UI] Nachricht erfolgreich gelöscht!');

      // UI aktualisieren
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Nachricht wurde gelöscht'),
            backgroundColor: Color(0xFF9B59B6),
            duration: Duration(seconds: 2),
          ),
        );

        // Nachrichten neu laden
        _loadMessages();
      }
    } catch (e) {
      print('❌ [UI] Fehler beim Löschen: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Fehler beim Löschen: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// ✏️ Bearbeitet eine Nachricht
  void _editMessage(Message message) {
    final editController = TextEditingController(text: message.content);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Nachricht bearbeiten',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: editController,
          style: const TextStyle(color: Colors.white),
          maxLines: null,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Nachricht eingeben...',
            hintStyle: const TextStyle(color: Colors.white38),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF9B59B6)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Abbrechen',
              style: TextStyle(color: Colors.white60),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final newContent = editController.text.trim();
              if (newContent.isEmpty || newContent == message.content) {
                Navigator.pop(context);
                return;
              }

              Navigator.pop(context);
              await _updateMessage(message, newContent);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9B59B6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 4,
            ),
            child: const Text(
              'Speichern',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 📝 Aktualisiert eine Nachricht in Cloudflare D1
  Future<void> _updateMessage(Message message, String newContent) async {
    try {
      print('📝 [UI] Bearbeite Nachricht: ${message.id}');

      // Cloudflare API aufrufen
      await _chatService.updateMessage(
        chatRoomId: widget.chatRoom.id,
        messageId: message.id,
        newContent: newContent,
      );

      print('✅ [UI] Nachricht erfolgreich bearbeitet!');

      // UI aktualisieren
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Nachricht wurde bearbeitet'),
            backgroundColor: Color(0xFF9B59B6),
            duration: Duration(seconds: 2),
          ),
        );

        // Nachrichten neu laden
        _loadMessages();
      }
    } catch (e) {
      print('❌ [UI] Fehler beim Bearbeiten: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Fehler beim Bearbeiten: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Nachricht eingeben...',
                    hintStyle: const TextStyle(
                      color: Colors.white38,
                      fontSize: 15,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF0F0F1E).withValues(alpha: 0.8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: const BorderSide(
                        color: Color(0xFF9B59B6),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF9B59B6),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF9B59B6).withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: _sendMessage,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    try {
      // JWT Auth - Username wird automatisch aus Token extrahiert
      await _chatService.sendMessage(
        chatRoomId: widget.chatRoom.id,
        content: content,
        type: 'text',
      );

      _messageController.clear();
      _loadMessages(); // Reload messages

      // Scroll nach unten
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Senden: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );

    if (messageDate == today) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.day}.${timestamp.month}.${timestamp.year} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  void _showChatInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: widget.chatRoom.isFixed
                        ? const Color(0xFF9B59B6).withValues(alpha: 0.2)
                        : const Color(0xFF3498DB).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      widget.chatRoom.emoji,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.chatRoom.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.chatRoom.memberCount} Mitglieder',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Beschreibung:',
              style: TextStyle(
                color: Color(0xFF9B59B6),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.chatRoom.description,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 24),
            if (widget.chatRoom.isFixed)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF9B59B6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF9B59B6).withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock, color: Color(0xFF9B59B6), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Dies ist ein fixer Chat-Raum und kann nicht gelöscht werden.',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
