import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UrsprungChatTab extends StatefulWidget {
  const UrsprungChatTab({super.key});

  @override
  State<UrsprungChatTab> createState() => _UrsprungChatTabState();
}

class _UrsprungChatTabState extends State<UrsprungChatTab> {
  static const _cyan = Color(0xFF00D4AA);
  static const _bg = Color(0xFF050510);
  static const _surface = Color(0xFF0A0A1A);
  static const _surfaceCard = Color(0xFF0F0F25);

  static const _rooms = [
    ('ursprung-allgemein', 'Allgemein'),
    ('ursprung-gateway', 'CIA Gateway'),
    ('ursprung-remote-viewing', 'Remote Viewing'),
    ('ursprung-manifestation', 'Manifestation'),
  ];

  String _roomId = 'ursprung-allgemein';
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final _client = Supabase.instance.client;

  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  RealtimeChannel? _channel;

  String get _username =>
      _client.auth.currentUser?.userMetadata?['username']?.toString() ?? 'Anonym';
  String? get _userId => _client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _loadRoom(_roomId);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadRoom(String roomId) async {
    await _channel?.unsubscribe();
    if (!mounted) return;
    setState(() {
      _loading = true;
      _messages = [];
    });

    final rows = await _client
        .from('chat_messages')
        .select('id,content,username,avatar_emoji,created_at')
        .eq('room_id', roomId)
        .order('created_at', ascending: true)
        .limit(50);

    if (!mounted) return;
    setState(() {
      _messages = List<Map<String, dynamic>>.from(rows);
      _loading = false;
    });
    _scrollToBottom();

    _channel = _client
        .channel('ursprung-chat-$roomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: roomId,
          ),
          callback: (payload) {
            if (!mounted) return;
            setState(() {
              _messages.add(Map<String, dynamic>.from(payload.newRecord));
            });
            _scrollToBottom();
          },
        )
        .subscribe();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _userId == null) return;
    _ctrl.clear();
    await _client.from('chat_messages').insert({
      'room_id': _roomId,
      'content': text,
      'message': text,
      'username': _username,
      'user_id': _userId,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: Column(
        children: [
          _buildRoomChips(),
          Expanded(child: _buildMessages()),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildRoomChips() {
    return Container(
      color: _surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _rooms.map((r) {
            final selected = _roomId == r.$1;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() => _roomId = r.$1);
                  _loadRoom(r.$1);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? _cyan : _cyan.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? _cyan : _cyan.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    r.$2,
                    style: TextStyle(
                      color: selected ? _bg : _cyan,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMessages() {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: _cyan));
    }
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 48, color: _cyan.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(
              'Noch keine Nachrichten.\nSei der Erste!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (_, i) => _buildBubble(_messages[i]),
    );
  }

  Widget _buildBubble(Map<String, dynamic> msg) {
    final isOwn = msg['username'] == _username;
    final name = msg['username']?.toString() ?? 'Anonym';
    final content = msg['content']?.toString() ?? '';
    final ts = msg['created_at'] != null
        ? DateTime.tryParse(msg['created_at'].toString())
        : null;
    final timeStr = ts != null
        ? '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}'
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isOwn) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: _cyan.withValues(alpha: 0.2),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(color: _cyan, fontSize: 11),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints:
                  BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isOwn ? _cyan : _surfaceCard,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isOwn ? 16 : 4),
                  bottomRight: Radius.circular(isOwn ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isOwn)
                    Text(
                      name,
                      style: const TextStyle(
                          color: _cyan, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  Text(
                    content,
                    style: TextStyle(
                      color: isOwn ? _bg : Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeStr,
                    style: TextStyle(
                      color: isOwn
                          ? _bg.withValues(alpha: 0.6)
                          : Colors.white.withValues(alpha: 0.4),
                      fontSize: 10,
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

  Widget _buildInput() {
    return Container(
      color: _surface,
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              style: const TextStyle(color: Colors.white),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Nachricht schreiben...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                filled: true,
                fillColor: _surfaceCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: _cyan,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: _bg, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
