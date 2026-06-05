/// Ursprung-Welt Live-Chat Screen
///
/// Cyan-Design-Chat fuer die Ursprung-Welt mit 5 Raeumen:
/// Natur, Kosmos, Urvolk, Heilpflanzen, Tiergeister.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show RealtimeChannel;

import '../../services/cloudflare_api_service.dart';
import '../../services/storage_service.dart';
import '../../services/supabase_service.dart';
import '../../services/user_service.dart';
import '../../theme/wb_cinematic_tokens.dart';
import '../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../widgets/live_room_banner.dart';
import '../shared/livekit_group_call_screen.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const _kAccent = Color(0xFF00D4AA);
const _kBg = Color(0xFF050510);
const _kSurface = Color(0xFF080818);

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class UrsprungLiveChatScreen extends StatefulWidget {
  final String? initialRoom;

  const UrsprungLiveChatScreen({super.key, this.initialRoom});

  @override
  State<UrsprungLiveChatScreen> createState() =>
      _UrsprungLiveChatScreenState();
}

class _UrsprungLiveChatScreenState extends State<UrsprungLiveChatScreen> {
  final CloudflareApiService _api = CloudflareApiService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late String _selectedRoom;

  static const Map<String, String> _roomIdMap = {
    'natur': 'ursprung-natur',
    'kosmos': 'ursprung-kosmos',
    'urvolk': 'ursprung-urvolk',
    'heilpflanzen': 'ursprung-heilpflanzen',
    'tiergeister': 'ursprung-tiergeister',
  };

  final Map<String, Map<String, dynamic>> _rooms = {
    'natur': {
      'name': '🌿 Natur & Naturgeister',
      'description':
          'Naturkraefte, Geister der Natur und Leben auf der Erde',
      'icon': '🌿',
    },
    'kosmos': {
      'name': '🌌 Kosmos & Sternenhimmel',
      'description':
          'Kosmische Verbindungen, Sterne und universelle Wahrheiten',
      'icon': '🌌',
    },
    'urvolk': {
      'name': '🏛️ Ur-Kulturen & Ahnen',
      'description':
          'Uraltes Wissen der Naturvoelker, Ahnenverbindung und Traditionen',
      'icon': '🏛️',
    },
    'heilpflanzen': {
      'name': '🌱 Heilpflanzen & Natur-Medizin',
      'description':
          'Pflanzenwissen, Kraeuterheilkunde und natuerliche Heilmethoden',
      'icon': '🌱',
    },
    'tiergeister': {
      'name': '🦅 Tiergeister & Animismus',
      'description':
          'Tier-Totem, animistische Weltsicht und Naturverbindung',
      'icon': '🦅',
    },
  };

  String get _fullRoomId =>
      _roomIdMap[_selectedRoom] ?? 'ursprung-$_selectedRoom';

  // Profile
  String _username = '';
  String _userId = '';
  String _avatarEmoji = '🌿';
  String? _avatarUrl;

  // State
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _errorMessage;

  RealtimeChannel? _realtimeChannel;
  Timer? _realtimeRetryTimer;
  int _realtimeRetryCount = 0;

  @override
  void initState() {
    super.initState();
    _selectedRoom = widget.initialRoom ?? 'natur';
    _userId = supabase.auth.currentUser?.id ?? UserService.getCurrentUserId();
    _loadProfile();
    _subscribeToRoom(_fullRoomId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadMessages();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = null;
    _realtimeRetryTimer?.cancel();
    _realtimeRetryTimer = null;
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Profile
  // ---------------------------------------------------------------------------

  void _loadProfile() {
    final storage = StorageService();
    final ep = storage.getEnergieProfile();
    final mp = storage.getMaterieProfile();
    final profile = ep ?? mp;
    if (profile != null) {
      setState(() {
        _username = ep?.username ?? mp?.username ?? '';
        _avatarEmoji = ep?.avatarEmoji ?? mp?.avatarEmoji ?? '🌿';
        _avatarUrl = ep?.avatarUrl ?? mp?.avatarUrl;
        _userId =
            supabase.auth.currentUser?.id ?? UserService.getCurrentUserId();
      });
    } else {
      _userId = UserService.getCurrentUserId();
    }
  }

  // ---------------------------------------------------------------------------
  // Realtime
  // ---------------------------------------------------------------------------

  void _subscribeToRoom(String roomId) {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = SupabaseChatService.instance.subscribeToRoom(
      roomId,
      onMessage: (newMsg) {
        if (!mounted) return;
        final msgRoom = newMsg['room_id']?.toString();
        if (msgRoom != null && msgRoom != _fullRoomId) return;
        final newId = newMsg['id']?.toString();
        final exists = _messages.any((m) => m['id']?.toString() == newId);
        if (!exists) {
          setState(() => _messages.add(newMsg));
          _scrollToBottom();
        }
      },
      onUpdate: (updated) {
        if (!mounted) return;
        final id = updated['id']?.toString();
        if (id == null) return;
        if (updated['is_deleted'] == true) {
          setState(
              () => _messages.removeWhere((m) => m['id']?.toString() == id));
          return;
        }
        final idx = _messages.indexWhere((m) => m['id']?.toString() == id);
        if (idx >= 0) {
          setState(() => _messages[idx] = {..._messages[idx], ...updated});
        }
      },
      onDelete: (messageId) {
        if (!mounted) return;
        setState(
            () => _messages.removeWhere((m) => m['id']?.toString() == messageId));
      },
      onSubscribed: () {
        _realtimeRetryCount = 0;
        _realtimeRetryTimer?.cancel();
      },
      onError: (e) {
        _scheduleRealtimeReconnect(roomId);
      },
    );
  }

  void _scheduleRealtimeReconnect(String roomId) {
    if (!mounted || roomId != _fullRoomId) return;
    if (_realtimeRetryCount >= 6) return;
    _realtimeRetryTimer?.cancel();
    final delays = [2, 5, 10, 20, 40, 60];
    final delaySec = delays[_realtimeRetryCount.clamp(0, delays.length - 1)];
    _realtimeRetryCount++;
    _realtimeRetryTimer = Timer(Duration(seconds: delaySec), () {
      if (!mounted || roomId != _fullRoomId) return;
      _subscribeToRoom(roomId);
    });
  }

  // ---------------------------------------------------------------------------
  // Load Messages
  // ---------------------------------------------------------------------------

  Future<void> _loadMessages({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      final messages = await _api
          .getChatMessages(_fullRoomId, realm: 'ursprung', limit: 50)
          .timeout(const Duration(seconds: 15));
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
          _errorMessage = null;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Send Message
  // ---------------------------------------------------------------------------

  Future<void> _sendMessage() async {
    if (_isSending) return;
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    if (_username.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bitte zuerst ein Profil anlegen.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    _isSending = true;
    try {
      final serverMsg = await _api.sendChatMessage(
        roomId: _fullRoomId,
        realm: 'ursprung',
        userId: _userId,
        username: _username,
        message: text,
        avatarEmoji: _avatarEmoji,
        avatarUrl: _avatarUrl,
      );
      _messageController.clear();
      if (mounted) {
        setState(() {
          final exists = _messages.any((m) => m['id'] == serverMsg['id']);
          if (!exists) _messages.add(serverMsg);
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Senden fehlgeschlagen. Bitte erneut versuchen.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _isSending = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Room Switch
  // ---------------------------------------------------------------------------

  void _switchRoom(String roomKey) {
    if (roomKey == _selectedRoom) return;
    setState(() {
      _selectedRoom = roomKey;
      _messages = [];
      _errorMessage = null;
    });
    _subscribeToRoom(_fullRoomId);
    _loadMessages();
  }

  // ---------------------------------------------------------------------------
  // Scroll
  // ---------------------------------------------------------------------------

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  // ---------------------------------------------------------------------------
  // LiveKit
  // ---------------------------------------------------------------------------

  void _joinVoiceRoom() {
    if (_username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte zuerst ein Profil anlegen.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LiveKitGroupCallScreen(
          roomName: _fullRoomId,
          world: 'ursprung',
          displayName: _username,
          avatarUrl: _avatarUrl,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: WBGlassAppBar(
        title: 'Ursprung Live-Chat',
        world: WBWorld.ursprung,
        actions: [
          IconButton(
            icon: const Icon(Icons.mic_rounded, color: _kAccent),
            tooltip: 'Sprachraum beitreten',
            onPressed: _joinVoiceRoom,
          ),
        ],
      ),
      body: Column(
        children: [
          // Live-Banner
          LiveRoomBanner(
            world: 'ursprung',
            currentRoomName: _fullRoomId,
            onJoin: (roomName) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LiveKitGroupCallScreen(
                    roomName: roomName,
                    world: 'ursprung',
                    displayName: _username,
                    avatarUrl: _avatarUrl,
                  ),
                ),
              );
            },
          ),

          // Room Selector
          _buildRoomSelector(),

          // Current Room Info
          _buildRoomInfo(),

          // Messages
          Expanded(
            child: _buildMessageList(),
          ),

          // Input
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildRoomSelector() {
    return Container(
      height: 44,
      color: _kSurface,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: _rooms.length,
        itemBuilder: (context, index) {
          final key = _rooms.keys.elementAt(index);
          final room = _rooms[key]!;
          final isSelected = key == _selectedRoom;
          return GestureDetector(
            onTap: () => _switchRoom(key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? _kAccent.withValues(alpha: 0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? _kAccent.withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.12),
                ),
              ),
              child: Text(
                room['icon'] as String,
                style: TextStyle(
                  fontSize: 16,
                  color: isSelected ? _kAccent : Colors.white54,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoomInfo() {
    final room = _rooms[_selectedRoom];
    if (room == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: _kSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            room['name'] as String,
            style: const TextStyle(
              color: _kAccent,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            room['description'] as String,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _kAccent),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.orange, size: 40),
            const SizedBox(height: 12),
            const Text(
              'Fehler beim Laden',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadMessages,
              child: const Text(
                'Erneut versuchen',
                style: TextStyle(color: _kAccent),
              ),
            ),
          ],
        ),
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🌿',
              style: TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              'Noch keine Nachrichten',
              style: TextStyle(color: Colors.white54, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(
              'Verbinde dich mit der Natur und beginne das Gespraech.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _kAccent,
      backgroundColor: _kSurface,
      onRefresh: _loadMessages,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          return _buildMessageBubble(_messages[index]);
        },
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final msgUsername = msg['username']?.toString() ?? '';
    final isOwn = msgUsername.isNotEmpty && msgUsername == _username;
    final content = (msg['message'] ?? msg['content'] ?? '').toString();
    final createdAt = msg['created_at']?.toString() ?? '';

    String? timeLabel;
    if (createdAt.isNotEmpty) {
      final dt = DateTime.tryParse(createdAt)?.toLocal();
      if (dt != null) {
        final h = dt.hour.toString().padLeft(2, '0');
        final m = dt.minute.toString().padLeft(2, '0');
        timeLabel = '$h:$m';
      }
    }

    final emojiRaw = msg['avatar_emoji']?.toString() ?? '';
    final avatarEmoji = emojiRaw.isNotEmpty ? emojiRaw : '🌿';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOwn
            ? _kAccent.withValues(alpha: 0.15)
            : const Color(0xFF0A0F1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOwn
              ? _kAccent.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isOwn) ...[
                Text(avatarEmoji,
                    style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
              ],
              Text(
                msgUsername.isNotEmpty ? msgUsername : 'Unbekannt',
                style: const TextStyle(
                  color: _kAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (timeLabel != null) ...[
                const SizedBox(width: 8),
                Text(
                  timeLabel,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        8 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: _kSurface,
        border: Border(
          top: BorderSide(
            color: _kAccent.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _kBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _kAccent.withValues(alpha: 0.2),
                ),
              ),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Deine Botschaft an die Natur...',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 14,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isSending ? null : _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _isSending
                    ? _kAccent.withValues(alpha: 0.3)
                    : _kAccent.withValues(alpha: 0.8),
                shape: BoxShape.circle,
              ),
              child: _isSending
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
