import 'package:flutter/material.dart';
import 'dart:async';
import '../services/websocket_service.dart';
import '../services/auth_service.dart';
import '../services/live_room_service.dart';
import 'package:intl/intl.dart';

/// ═══════════════════════════════════════════════════════════════
/// LIVE CHAT SCREEN - Weltenbibliothek
/// ═══════════════════════════════════════════════════════════════
/// Real-Time WebSocket Chat für Live-Stream Rooms
/// Features:
/// - WebSocket-Verbindung zu Cloudflare Durable Objects
/// - Live Chat-Nachrichten
/// - Typing-Indicators
/// - Online-Status
/// - Auto-Scroll
/// ═══════════════════════════════════════════════════════════════

class LiveChatScreen extends StatefulWidget {
  final String roomId;
  final String roomTitle;
  final String hostUsername;
  final bool isHost;

  const LiveChatScreen({
    super.key,
    required this.roomId,
    required this.roomTitle,
    required this.hostUsername,
    required this.isHost,
  });

  @override
  State<LiveChatScreen> createState() => _LiveChatScreenState();
}

class _LiveChatScreenState extends State<LiveChatScreen> {
  final WebSocketService _websocketService = WebSocketService();
  final LiveRoomService _liveRoomService = LiveRoomService();
  final AuthService _authService = AuthService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  List<String> _onlineUsers = [];
  Map<String, bool> _typingUsers = {};
  String? _currentUsername;
  bool _isConnecting = true;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _websocketService.disconnect();
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  Future<void> _initialize() async {
    // Get current user
    final user = await _authService.getCurrentUser();
    if (user != null) {
      setState(() {
        _currentUsername = user['username'] as String?;
      });
    }

    // Connect to WebSocket
    await _websocketService.connectToRoom(widget.roomId);

    // Listen to streams
    _websocketService.messageStream.listen((message) {
      setState(() {
        _messages.add(message);
      });
      _scrollToBottom();
    });

    _websocketService.stateStream.listen((state) {
      setState(() {
        _isConnecting =
            state == WebSocketConnectionState.connecting ||
            state == WebSocketConnectionState.reconnecting;
      });
    });

    _websocketService.typingStream.listen((data) {
      final username = data['username'] as String;
      final isTyping = data['is_typing'] as bool;

      setState(() {
        _typingUsers[username] = isTyping;
      });

      // Auto-hide typing indicator after 3 seconds
      if (isTyping) {
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _typingUsers[username] = false;
            });
          }
        });
      }
    });

    _websocketService.onlineUsersStream.listen((users) {
      setState(() {
        _onlineUsers = users;
      });
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    try {
      _websocketService.sendChatMessage(message);
      _messageController.clear();
      _websocketService.sendTypingIndicator(false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Senden: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onTyping() {
    _websocketService.sendTypingIndicator(true);

    // Cancel previous timer
    _typingTimer?.cancel();

    // Set new timer to stop typing indicator
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _websocketService.sendTypingIndicator(false);
    });
  }

  Future<void> _leaveRoom() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Stream verlassen?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Möchtest du den Live-Stream wirklich verlassen?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Abbrechen',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
            ),
            child: const Text('Verlassen'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _liveRoomService.leaveLiveRoom(widget.roomId);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _endStream() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Stream beenden?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Möchtest du den Live-Stream beenden? Alle Teilnehmer werden entfernt.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Abbrechen',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Beenden'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await _liveRoomService.endLiveRoom(widget.roomId);

      if (mounted) {
        if (result['success'] == true) {
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Fehler beim Beenden'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.roomTitle, style: const TextStyle(fontSize: 16)),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _isConnecting ? Colors.orange : Colors.green,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _isConnecting
                            ? Colors.orange.withValues(alpha: 0.5)
                            : Colors.green.withValues(alpha: 0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _isConnecting
                      ? 'Verbinde...'
                      : '${_onlineUsers.length} Online',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1A1A2E),
        actions: [
          if (widget.isHost)
            IconButton(
              icon: const Icon(Icons.stop_circle, color: Colors.red),
              onPressed: _endStream,
              tooltip: 'Stream beenden',
            )
          else
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: _leaveRoom,
              tooltip: 'Verlassen',
            ),
        ],
      ),
      body: Column(
        children: [
          // Online Users Indicator
          if (_onlineUsers.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.people, size: 16, color: Color(0xFF8B5CF6)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _onlineUsers.join(', '),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          // Messages List
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Noch keine Nachrichten',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sei der Erste, der etwas schreibt!',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
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
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
          ),

          // Typing Indicator
          if (_typingUsers.values.any((isTyping) => isTyping))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF8B5CF6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_typingUsers.entries.where((e) => e.value).map((e) => e.key).join(', ')} tippt...',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

          // Message Input
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      onChanged: (_) => _onTyping(),
                      onSubmitted: (_) => _sendMessage(),
                      enabled: _websocketService.isConnected,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: _websocketService.isConnected
                            ? 'Nachricht schreiben...'
                            : 'Verbinde...',
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: const Color(0xFF334155),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _websocketService.isConnected
                          ? _sendMessage
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isSentByMe = message.username == _currentUsername;

    return Align(
      alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Column(
          crossAxisAlignment: isSentByMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            // Username
            if (!isSentByMe)
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message.username,
                      style: const TextStyle(
                        color: Color(0xFF8B5CF6),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (message.username == widget.hostUsername) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'HOST',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            // Message Bubble
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: isSentByMe
                    ? const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                      )
                    : null,
                color: isSentByMe ? null : const Color(0xFF1E293B),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isSentByMe ? 16 : 4),
                  bottomRight: Radius.circular(isSentByMe ? 4 : 16),
                ),
                border: isSentByMe
                    ? null
                    : Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(message.dateTime),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 10,
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
}
