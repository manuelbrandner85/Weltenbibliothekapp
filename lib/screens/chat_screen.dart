import 'package:flutter/material.dart';
import '../models/chat_room_model.dart';
import '../services/cloudflare_chat_service.dart';
import 'chat_room_detail_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final CloudflareChatService _chatService = CloudflareChatService();
  List<ChatRoom> _chatRooms = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadChatRooms();
    _chatService.initializeFixedChatRooms();
  }

  @override
  void dispose() {
    _chatService.dispose();
    super.dispose();
  }

  Future<void> _loadChatRooms() async {
    try {
      print('📋 [UI] Starte Laden der Chat-Räume...');

      setState(() {
        _isLoading = true;
        _error = null;
      });

      final rooms = await _chatService.getChatRooms();

      print('📋 [UI] Chat-Räume geladen: ${rooms.length} Räume');
      for (final room in rooms) {
        print('   - ${room.emoji} ${room.name} (isFixed: ${room.isFixed})');
      }

      setState(() {
        _chatRooms = rooms;
        _isLoading = false;
      });

      print('✅ [UI] UI aktualisiert mit ${_chatRooms.length} Chat-Räumen');
    } catch (e, stackTrace) {
      print('❌ [UI] Fehler beim Laden der Chat-Räume: $e');
      print('❌ [UI] Stack Trace: $stackTrace');

      setState(() {
        _error = e.toString();
        _isLoading = false;
        _chatRooms = ChatRoom.getFixedChatRooms(); // Fallback
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        title: const Text(
          'Chat-Räume',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 2,
        shadowColor: Colors.purple.withValues(alpha: 0.3),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 24),
            onPressed: _loadChatRooms,
            tooltip: 'Aktualisieren',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF9B59B6)),
            )
          : _chatRooms.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.white30,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Keine Chat-Räume vorhanden',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateChatDialog(),
                    icon: const Icon(Icons.add_rounded, size: 22),
                    label: const Text(
                      'Chat erstellen',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9B59B6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 6,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadChatRooms,
              color: const Color(0xFF9B59B6),
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _chatRooms.length,
                itemBuilder: (context, index) {
                  final chatRoom = _chatRooms[index];
                  return _buildChatRoomCard(chatRoom);
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateChatDialog(),
        backgroundColor: const Color(0xFF9B59B6),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded, size: 24),
        label: const Text(
          'Neuer Chat',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        elevation: 6,
      ),
    );
  }

  Widget _buildChatRoomCard(ChatRoom chatRoom) {
    // Nur für benutzerdefinierte Räume: Swipe-to-Delete
    if (!chatRoom.isFixed) {
      return Dismissible(
        key: Key(chatRoom.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          // Bestätigungsdialog
          return await _confirmDeleteChatRoom(chatRoom);
        },
        onDismissed: (direction) async {
          // Nach Bestätigung löschen
          await _deleteChatRoom(chatRoom);
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.delete, color: Colors.white, size: 32),
              SizedBox(height: 4),
              Text(
                'Löschen',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        child: _buildChatRoomCardContent(chatRoom),
      );
    }

    // Für fixe Räume: Normale Card
    return _buildChatRoomCardContent(chatRoom);
  }

  Widget _buildChatRoomCardContent(ChatRoom chatRoom) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        // Neumorphism Multi-Layer Schatten
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: chatRoom.isFixed
                ? const Color(0xFF9B59B6).withValues(alpha: 0.15)
                : const Color(0xFF3498DB).withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Card(
        color: const Color(0xFF1A1A2E),
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: chatRoom.isFixed
                ? const Color(0xFF9B59B6).withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.05),
            width: 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            splashColor: chatRoom.isFixed
                ? const Color(0xFF9B59B6).withValues(alpha: 0.2)
                : const Color(0xFF3498DB).withValues(alpha: 0.15),
            highlightColor: chatRoom.isFixed
                ? const Color(0xFF9B59B6).withValues(alpha: 0.1)
                : const Color(0xFF3498DB).withValues(alpha: 0.08),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ChatRoomDetailScreen(chatRoom: chatRoom),
                ),
              ).then((_) => _loadChatRooms());
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Ultra-Modern Avatar mit Glassmorphism
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: chatRoom.isFixed
                                ? [
                                    const Color(
                                      0xFF9B59B6,
                                    ).withValues(alpha: 0.4),
                                    const Color(
                                      0xFF8E44AD,
                                    ).withValues(alpha: 0.25),
                                    const Color(
                                      0xFF9B59B6,
                                    ).withValues(alpha: 0.15),
                                  ]
                                : [
                                    const Color(
                                      0xFF3498DB,
                                    ).withValues(alpha: 0.35),
                                    const Color(
                                      0xFF2ECC71,
                                    ).withValues(alpha: 0.25),
                                    const Color(
                                      0xFF1ABC9C,
                                    ).withValues(alpha: 0.15),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: chatRoom.isFixed
                                  ? const Color(
                                      0xFF9B59B6,
                                    ).withValues(alpha: 0.25)
                                  : const Color(
                                      0xFF3498DB,
                                    ).withValues(alpha: 0.2),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            chatRoom.emoji,
                            style: const TextStyle(fontSize: 36),
                          ),
                        ),
                      ),
                      // Status Indicator (Activity Dot)
                      if (chatRoom.lastMessageTime != null &&
                          DateTime.now()
                                  .difference(chatRoom.lastMessageTime!)
                                  .inHours <
                              1)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2ECC71),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF1A1A2E),
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF2ECC71,
                                  ).withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 18),
                  // Content mit verbessertem Spacing
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title Row mit Premium Badge
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                chatRoom.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                  letterSpacing: 0.2,
                                  height: 1.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (chatRoom.isFixed)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF9B59B6),
                                      Color(0xFF8E44AD),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF9B59B6,
                                      ).withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.verified,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'OFFIZIELL',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Description mit besserer Lesbarkeit
                        Text(
                          chatRoom.description,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 14,
                            height: 1.5,
                            letterSpacing: 0.15,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        // Premium Meta-Info Chips
                        Row(
                          children: [
                            // Members Chip mit Glassmorphism
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(
                                      0xFF9B59B6,
                                    ).withValues(alpha: 0.2),
                                    const Color(
                                      0xFF9B59B6,
                                    ).withValues(alpha: 0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(
                                    0xFF9B59B6,
                                  ).withValues(alpha: 0.25),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.people_rounded,
                                    size: 15,
                                    color: Color(0xFF9B59B6),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    '${chatRoom.memberCount}',
                                    style: const TextStyle(
                                      color: Color(0xFF9B59B6),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Time Chip mit Gradient
                            if (chatRoom.lastMessageTime != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(
                                        0xFF3498DB,
                                      ).withValues(alpha: 0.2),
                                      const Color(
                                        0xFF2ECC71,
                                      ).withValues(alpha: 0.15),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF3498DB,
                                    ).withValues(alpha: 0.25),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.access_time_rounded,
                                      size: 15,
                                      color: Color(0xFF3498DB),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      _formatTimestamp(
                                        chatRoom.lastMessageTime!,
                                      ),
                                      style: const TextStyle(
                                        color: Color(0xFF3498DB),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const Spacer(),
                            // Modern Arrow Indicator
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    chatRoom.isFixed
                                        ? const Color(
                                            0xFF9B59B6,
                                          ).withValues(alpha: 0.25)
                                        : const Color(
                                            0xFF3498DB,
                                          ).withValues(alpha: 0.2),
                                    chatRoom.isFixed
                                        ? const Color(
                                            0xFF9B59B6,
                                          ).withValues(alpha: 0.15)
                                        : const Color(
                                            0xFF3498DB,
                                          ).withValues(alpha: 0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: chatRoom.isFixed
                                    ? const Color(0xFF9B59B6)
                                    : const Color(0xFF3498DB),
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Jetzt';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${timestamp.day}.${timestamp.month}.${timestamp.year}';
    }
  }

  void _showCreateChatDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedEmoji = '💬';

    // 🎨 Moderne Emoji-Auswahl (erweitert und kategorisiert)
    final emojis = [
      // Kommunikation
      '💬', '💭', '🗨️', '💌', '📮',
      // Kreativ & Kunst
      '🎨', '🎭', '🎬', '🎤', '🎧',
      // Musik
      '🎵', '🎶', '🎸', '🎹', '🎺',
      // Wissen & Bildung
      '📚', '📖', '📕', '📗', '📘',
      // Mystisch & Spirituell
      '🔮', '🎴', '🃏', '🧿', '💎',
      // Gaming
      '🎮', '🕹️', '👾', '🎯', '🎲',
      // Energie & Power
      '⚡', '🔥', '💥', '✨', '🌟',
      // Natur & Welt
      '🌍', '🌎', '🌏', '🌐', '🗺️',
      // Farben & Vibes
      '🌈', '🦄', '🌺', '🌸', '🌼',
      // Tech & Innovation
      '💻', '📱', '🔧', '⚙️', '🛠️',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text(
            'Neuen Chat erstellen',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true, // ✅ Tastatur automatisch öffnen
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Chat-Name',
                    labelStyle: const TextStyle(color: Colors.white60),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
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
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Beschreibung',
                    labelStyle: const TextStyle(color: Colors.white60),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
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
                const SizedBox(height: 16),
                const Text(
                  'Emoji auswählen:',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: emojis.map((emoji) {
                    final isSelected = emoji == selectedEmoji;
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          selectedEmoji = emoji;
                        });
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF9B59B6).withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF9B59B6)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
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
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bitte gib einen Chat-Namen ein'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  print(
                    '📝 [UI] Erstelle neuen Chat: ${nameController.text.trim()}',
                  );

                  final chatId = await _chatService.createChatRoom(
                    name: nameController.text.trim(),
                    description: descriptionController.text.trim().isEmpty
                        ? 'Ein benutzerdefinierter Chat'
                        : descriptionController.text.trim(),
                    createdBy: 'current_user_id', // TODO: Echte User ID
                    emoji: selectedEmoji,
                  );

                  print('✅ [UI] Chat erfolgreich erstellt! ID: $chatId');

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Chat erfolgreich erstellt!'),
                        backgroundColor: Color(0xFF9B59B6),
                      ),
                    );

                    print('🔄 [UI] Lade Chat-Liste neu...');
                    await _loadChatRooms(); // Reload list
                    print('✅ [UI] Chat-Liste neu geladen!');
                  }
                } catch (e, stackTrace) {
                  print('❌ [UI] Fehler beim Erstellen des Chats: $e');
                  print('❌ [UI] Stack Trace: $stackTrace');

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Fehler: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9B59B6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 4,
              ),
              child: const Text(
                'Erstellen',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🗑️ Bestätigt das Löschen eines Chat-Raums
  Future<bool> _confirmDeleteChatRoom(ChatRoom chatRoom) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Chat-Raum löschen?',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Möchtest du den Chat-Raum "${chatRoom.name}" wirklich löschen?',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.red, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Alle Nachrichten in diesem Raum werden ebenfalls dauerhaft aus der Cloudflare-Datenbank gelöscht.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Abbrechen',
              style: TextStyle(color: Colors.white60),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
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

    return result ?? false;
  }

  /// 🗑️ Löscht einen Chat-Raum aus Cloudflare D1
  Future<void> _deleteChatRoom(ChatRoom chatRoom) async {
    try {
      print('🗑️ [UI] Lösche Chat-Raum: ${chatRoom.id}');

      // Cloudflare API aufrufen
      await _chatService.deleteChatRoom(chatRoom.id);

      print('✅ [UI] Chat-Raum erfolgreich gelöscht!');

      // UI aktualisieren
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Chat-Raum "${chatRoom.name}" wurde gelöscht'),
            backgroundColor: const Color(0xFF9B59B6),
            duration: const Duration(seconds: 2),
          ),
        );

        // Liste neu laden
        _loadChatRooms();
      }
    } catch (e) {
      print('❌ [UI] Fehler beim Löschen: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Fehler: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );

        // Liste neu laden (auch bei Fehler, um UI zu synchronisieren)
        _loadChatRooms();
      }
    }
  }
}
