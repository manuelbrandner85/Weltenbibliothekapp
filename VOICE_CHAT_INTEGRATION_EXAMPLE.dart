/// 🚀 MATERIE LIVE CHAT SCREEN - VOICE CHAT INTEGRATION EXAMPLE
/// 
/// Dieses File zeigt die konkrete Integration in den Materie Live Chat Screen

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 📦 NEUE IMPORTS HINZUFÜGEN
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
import '../../widgets/voice_chat_button.dart';         // ← NEU
import '../../widgets/minimized_voice_overlay.dart';   // ← NEU
*/

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 🔧 SCHRITT 1: build() Method - Wrap mit VoiceOverlayBuilder
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
@override
Widget build(BuildContext context) {
  // ✅ WRAP HIER!
  return VoiceOverlayBuilder(
    child: Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            _buildAppBar(),
            
            // ✅ NEU: Voice Chat Banner
            VoiceChatBanner(
              roomId: _selectedRoom,
              roomName: _materieRooms[_selectedRoom]!['name'],
              userId: _userId,
              username: _username,
              color: _materieRooms[_selectedRoom]!['color'],
            ),
            
            // Room Selector
            _buildRoomSelector(),
            
            // Messages
            Expanded(child: _buildMessageList()),
            
            // Input Bar
            _buildInputBar(),
          ],
        ),
      ),
    ),
  );
}
*/

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 🎯 ALTERNATIVE: Voice Chat Button in AppBar
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
Widget _buildAppBar() {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.red.shade900, Colors.red.shade700],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Row(
      children: [
        const Icon(Icons.public, color: Colors.white, size: 28),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MATERIE-WELT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Live Chat',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        
        // ✅ NEU: Voice Chat Button in AppBar
        VoiceChatButton(
          roomId: _selectedRoom,
          roomName: _materieRooms[_selectedRoom]!['name'],
          userId: _userId,
          username: _username,
          color: Colors.red,
        ),
        
        const SizedBox(width: 12),
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          onPressed: () => _showProfileDialog(),
        ),
      ],
    ),
  );
}
*/

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 📋 VOLLSTÄNDIGE INTEGRATION - KOMPLETTES BEISPIEL
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
import 'package:flutter/material.dart';
import '../../widgets/voice_chat_button.dart';
import '../../widgets/minimized_voice_overlay.dart';
import '../../services/cloudflare_api_service.dart';
import '../../services/hybrid_chat_service.dart';

class MaterieLiveChatScreen extends StatefulWidget {
  const MaterieLiveChatScreen({super.key});

  @override
  State<MaterieLiveChatScreen> createState() => _MaterieLiveChatScreenState();
}

class _MaterieLiveChatScreenState extends State<MaterieLiveChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final CloudflareApiService _api = CloudflareApiService();
  late final HybridChatService _hybridChat;
  
  String _selectedRoom = 'politik';
  String _username = 'User${DateTime.now().millisecondsSinceEpoch % 10000}';
  String _userId = 'user_anonymous';
  String _avatar = '👤';
  String? _avatarEmoji;
  String? _avatarUrl;
  
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  final Map<String, Map<String, dynamic>> _materieRooms = {
    'politik': {
      'name': '🎭 Geopolitik & Weltordnung',
      'description': 'Weltpolitik, geheime Agenden, Neue Weltordnung',
      'color': Colors.red,
      'icon': '🎭',
    },
    'geschichte': {
      'name': '🏛️ Geschichte & Fakten',
      'description': 'Echte Geschichte vs. offizielle Narrative',
      'color': Colors.orange,
      'icon': '🏛️',
    },
    'ufo': {
      'name': '🛸 UFO & Außerirdische',
      'description': 'Sichtungen, Entführungen, Area 51',
      'color': Colors.purple,
      'icon': '🛸',
    },
  };

  @override
  void initState() {
    super.initState();
    _hybridChat = HybridChatService(realm: 'materie');
    _loadProfile();
    _loadMessages();
  }

  Future<void> _loadProfile() async {
    // Load user profile...
  }

  Future<void> _loadMessages() async {
    // Load chat messages...
  }

  @override
  Widget build(BuildContext context) {
    // ✅ WRAP MIT VoiceOverlayBuilder
    return VoiceOverlayBuilder(
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        body: SafeArea(
          child: Column(
            children: [
              // App Bar mit Voice Button
              _buildAppBar(),
              
              // ✅ Voice Chat Banner
              VoiceChatBanner(
                roomId: _selectedRoom,
                roomName: _materieRooms[_selectedRoom]!['name'],
                userId: _userId,
                username: _username,
                color: _materieRooms[_selectedRoom]!['color'] as Color,
              ),
              
              // Room Selector
              _buildRoomSelector(),
              
              // Messages
              Expanded(child: _buildMessageList()),
              
              // Input Bar
              _buildInputBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade900, Colors.red.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.public, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MATERIE-WELT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Live Chat',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildRoomSelector() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _materieRooms.length,
        itemBuilder: (context, index) {
          final roomId = _materieRooms.keys.elementAt(index);
          final room = _materieRooms[roomId]!;
          final isSelected = _selectedRoom == roomId;
          
          return GestureDetector(
            onTap: () => setState(() => _selectedRoom = roomId),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? (room['color'] as Color).withOpacity(0.3)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? (room['color'] as Color)
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    room['icon'] as String,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (room['name'] as String).split(' ').last,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isOwnMessage = message['user_id'] == _userId;
    
    return Align(
      alignment: isOwnMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isOwnMessage
              ? Colors.red.shade800
              : Colors.grey.shade800,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message['username'] ?? 'Unknown',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message['message'] ?? '',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        border: Border(
          top: BorderSide(color: Colors.grey.shade800, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Message...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.grey.shade800,
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
          CircleAvatar(
            backgroundColor: Colors.red,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    
    try {
      await _api.sendChatMessage(
        roomId: _selectedRoom,
        realm: 'materie',
        userId: _userId,
        username: _username,
        message: _messageController.text.trim(),
        avatarEmoji: _avatarEmoji,
        avatarUrl: _avatarUrl,
      );
      
      _messageController.clear();
      await _loadMessages();
    } catch (e) {
      print('Error sending message: $e');
    }
  }
}
*/

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ✅ FERTIG! Das war's!
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 
// Mit diesen 2 einfachen Schritten ist der Voice Chat vollständig integriert:
// 1. VoiceOverlayBuilder als Wrapper
// 2. VoiceChatBanner oder VoiceChatButton hinzufügen
//
// Der Rest wird automatisch vom System übernommen! 🎉
