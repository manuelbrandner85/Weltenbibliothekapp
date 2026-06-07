/// Vorhang-Welt Live-Chat Screen
///
/// Mystischer Gold-Design-Chat mit 5 Raeumen, Realtime-Subscription
/// und LiveKit-Sprachraeumen.
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

const _kAccent = Color(0xFFD4AF37);
const _kBg = Color(0xFF060408);
const _kSurface = Color(0xFF0D0A14);

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class VorhangLiveChatScreen extends StatefulWidget {
  final String? initialRoom;

  const VorhangLiveChatScreen({super.key, this.initialRoom});

  @override
  State<VorhangLiveChatScreen> createState() => _VorhangLiveChatScreenState();
}

class _VorhangLiveChatScreenState extends State<VorhangLiveChatScreen> {
  final CloudflareApiService _api = CloudflareApiService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();

  late String _selectedRoom;

  static const Map<String, String> _roomIdMap = {
    'orakel': 'vorhang-orakel',
    'rituale': 'vorhang-rituale',
    'symbole': 'vorhang-symbole',
    'prophezeiungen': 'vorhang-prophezeiungen',
    'spiegel': 'vorhang-spiegel',
  };

  final Map<String, Map<String, dynamic>> _rooms = {
    'orakel': {
      'name': '🔮 Orakel & Prophetie',
      'description':
          'Seherische Träume, Orakel-Praktiken und prophetische Visionen',
      'icon': '🔮',
    },
    'rituale': {
      'name': '🕯️ Rituale & Magie',
      'description': 'Magische Praktiken, Rituale und okkultes Wissen',
      'icon': '🕯️',
    },
    'symbole': {
      'name': '👁️ Symbole & Geheimcodes',
      'description': 'Versteckte Symbole, Geheimzeichen und kosmische Codes',
      'icon': '👁️',
    },
    'prophezeiungen': {
      'name': '📜 Prophezeiungen & Träume',
      'description': 'Alte Prophezeiungen, Traumdeutung und Visionaeres',
      'icon': '📜',
    },
    'spiegel': {
      'name': '🌀 Der Innere Spiegel',
      'description':
          'Bewusstseinserweiterung, innere Reisen und Schattenselbst',
      'icon': '🌀',
    },
  };

  String get _fullRoomId =>
      _roomIdMap[_selectedRoom] ?? 'vorhang-$_selectedRoom';

  // Profile
  String _username = '';
  String _userId = '';
  String _avatarEmoji = '🔮';
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
    _selectedRoom = widget.initialRoom ?? 'orakel';
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
    _inputFocusNode.dispose();
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
        _avatarEmoji = ep?.avatarEmoji ?? mp?.avatarEmoji ?? '🔮';
        _avatarUrl = ep?.avatarUrl ?? mp?.avatarUrl;
        _userId = supabase.auth.currentUser?.id ?? UserService.getCurrentUserId();
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
          .getChatMessages(_fullRoomId, realm: 'vorhang', limit: 50)
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
        realm: 'vorhang',
        userId: _userId,
        username: _username,
        message: text,
        avatarEmoji: _avatarEmoji,
        avatarUrl: _avatarUrl,
      );
      _messageController.clear();
      if (mounted) {
        setState(() {
          final exists =
              _messages.any((m) => m['id'] == serverMsg['id']);
          if (!exists) _messages.add(serverMsg);
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
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
          world: 'vorhang',
          displayName: _username,
          avatarUrl: _avatarUrl,
          // Single entry point: video available, toggle inside the call.
          audioOnly: false,
          initialMicEnabled: true,
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
        title: 'Vorhang Live-Chat',
        world: WBWorld.vorhang,
        actions: [
          // Single, clear live entry point for this world.
          IconButton(
            icon: const Icon(Icons.podcasts_rounded, color: _kAccent),
            tooltip: 'Live beitreten',
            onPressed: _joinVoiceRoom,
          ),
        ],
      ),
      body: Column(
        children: [
          // Live-Banner
          LiveRoomBanner(
            world: 'vorhang',
            currentRoomName: _fullRoomId,
            onJoin: (roomName) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LiveKitGroupCallScreen(
                    roomName: roomName,
                    world: 'vorhang',
                    displayName: _username,
                    avatarUrl: _avatarUrl,
                    audioOnly: false,
                    initialMicEnabled: true,
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _kAccent,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            room['description'] as String,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
            Text(
              'Fehler beim Laden',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '🔮',
                style: TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 16),
              const Text(
                'Hier ist es noch still',
                style: TextStyle(color: Colors.white54, fontSize: 15),
              ),
              const SizedBox(height: 8),
              Text(
                'Sei die erste mystische Stimme - schreibe etwas oder '
                'starte einen Live-Talk.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  _buildEmptyAction(
                    icon: Icons.edit_rounded,
                    label: 'Erste Nachricht senden',
                    filled: true,
                    onTap: () => _inputFocusNode.requestFocus(),
                  ),
                  _buildEmptyAction(
                    icon: Icons.podcasts_rounded,
                    label: 'Live starten',
                    filled: false,
                    onTap: _joinVoiceRoom,
                  ),
                ],
              ),
            ],
          ),
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

  // Small pill action used in the empty state (filled = primary CTA).
  Widget _buildEmptyAction({
    required IconData icon,
    required String label,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: filled
              ? _kAccent.withValues(alpha: 0.85)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: filled
                ? _kAccent
                : _kAccent.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: filled ? Colors.black : _kAccent,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: filled ? Colors.black : _kAccent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final msgUsername = msg['username']?.toString() ?? '';
    final isOwn = msgUsername.isNotEmpty && msgUsername == _username;
    final content =
        (msg['message'] ?? msg['content'] ?? '').toString();
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
    final avatarEmoji = emojiRaw.isNotEmpty ? emojiRaw : '🔮';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOwn
            ? _kAccent.withValues(alpha: 0.15)
            : const Color(0xFF120D1A),
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
            mainAxisAlignment: isOwn
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              if (!isOwn) ...[
                Text(avatarEmoji,
                    style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  msgUsername.isNotEmpty ? msgUsername : 'Unbekannt',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _kAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
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
                focusNode: _inputFocusNode,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Deine mystische Botschaft...',
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
