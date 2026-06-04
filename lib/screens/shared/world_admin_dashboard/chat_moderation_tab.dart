// GENERATED SPLIT (TEIL 1B): part of world_admin_dashboard library.
// No logic changes -- structural extraction only.
part of '../world_admin_dashboard.dart';

// ═════════════════════════════════════════════════════════════════════════════
// TAB 3 – CHAT-MODERATION
// ═════════════════════════════════════════════════════════════════════════════
class _ChatModerationTab extends StatefulWidget {
  final String world;
  final AdminState admin;
  final Color accent, accentBright;
  const _ChatModerationTab(
      {required this.world,
      required this.admin,
      required this.accent,
      required this.accentBright});
  @override
  State<_ChatModerationTab> createState() => _ChatModerationTabState();
}

class _ChatModerationTabState extends State<_ChatModerationTab> {
  List<String> _rooms = [];
  String _selectedRoom = '';
  List<Map<String, dynamic>> _messages = [];
  bool _loadingMsgs = false;
  bool _loadingRooms = true;
  bool _autoRefresh = true;
  final _api = CloudflareApiService();
  Timer? _pollTimer;

  // Fallback-Raeume falls DB nicht erreichbar.
  static const List<String> _fallbackRooms = [
    'materie-politik',
    'materie-geschichte',
    'materie-ufo',
    'materie-verschwoerung',
    'materie-wissenschaft',
    'materie-tech',
    'materie-gesundheit',
    'materie-medien',
    'materie-finanzen',
    'energie-meditation',
    'energie-chakra',
    'energie-bewusstsein',
    'energie-heilung',
    'energie-kristalle',
    'energie-astrologie',
    'energie-traumdeutung',
    'vorhang-strategie',
    'vorhang-macht',
    'vorhang-medien',
    'vorhang-geopolitik',
    'ursprung-bewusstsein',
    'ursprung-quanten',
    'ursprung-realitaet',
  ];

  @override
  void initState() {
    super.initState();
    _loadRooms();
    _pollTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (_autoRefresh && _selectedRoom.isNotEmpty) _loadMessages();
    });
  }

  @override
  void didUpdateWidget(covariant _ChatModerationTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.world != widget.world) {
      _loadRooms();
    }
  }

  Future<void> _loadRooms() async {
    if (!mounted) return;
    setState(() => _loadingRooms = true);
    try {
      final res = await http
          .get(Uri.parse('${ApiConfig.workerUrl}/api/chat/rooms'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data is List)
            ? data
            : (data is Map ? (data['rooms'] ?? data['data'] ?? []) : []);
        final names = (list as List)
            .map((r) => (r['id'] ?? r['room_id'] ?? r['name'] ?? '').toString())
            .where((s) => s.isNotEmpty)
            .toList();
        if (names.isNotEmpty && mounted) {
          setState(() {
            _rooms = names;
            _selectedRoom = names.first;
            _loadingRooms = false;
          });
          _loadMessages();
          return;
        }
      }
    } catch (_) {}
    // Fallback to hardcoded list
    if (mounted) {
      setState(() {
        _rooms = _fallbackRooms;
        _selectedRoom = _fallbackRooms.first;
        _loadingRooms = false;
      });
      _loadMessages();
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    if (!mounted) return;
    if (mounted) setState(() => _loadingMsgs = true);
    try {
      final msgs = await _api.getChatMessages(_selectedRoom, limit: 50);
      if (mounted) setState(() => _messages = msgs);
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Chat laden: $e');
    } finally {
      if (mounted) setState(() => _loadingMsgs = false);
    }
  }

  void _snack(String msg, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color ?? const Color(0xFF1A1A2E),
      duration: const Duration(seconds: 3),
    ));
  }

  Future<void> _deleteMsg(Map<String, dynamic> msg) async {
    final id = (msg['id'] ?? msg['message_id'] ?? '').toString();
    final username = (msg['username'] ?? 'Unbekannt').toString();
    final content = (msg['content'] ?? msg['message'] ?? '').toString();

    if (id.isEmpty) {
      _snack('❌ Keine Nachrichten-ID vorhanden');
      return;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('🗑️ Nachricht löschen',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Von: @$username',
                      style: TextStyle(
                          color: widget.accent, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      content.length > 100
                          ? '${content.substring(0, 100)}…'
                          : content,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                      'Diese Aktion kann nicht rückgängig gemacht werden.',
                      style: TextStyle(color: Colors.white38, fontSize: 12)),
                ]),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Abbrechen',
                    style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.delete_rounded,
                    color: Colors.white, size: 16),
                label: const Text('Löschen',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    try {
      await _api.deleteChatMessage(
        messageId: id,
        roomId: _selectedRoom,
        userId: (msg['user_id'] ?? msg['userId'] ?? '').toString(),
        username: widget.admin.username ?? 'Weltenbibliothek',
        isAdmin: true,
      );
      _snack('🗑️ Nachricht von $username gelöscht',
          color: Colors.red.shade700);
      _loadMessages();
    } catch (e) {
      _snack('❌ Löschen fehlgeschlagen: $e', color: Colors.orange);
    }
  }

  Future<void> _banSender(Map<String, dynamic> msg) async {
    final userId = (msg['user_id'] ?? msg['userId'] ?? '').toString();
    final username = (msg['username'] ?? 'Unbekannt').toString();

    if (userId.isEmpty || userId.startsWith('user_')) {
      _snack('⚠️ Kein gültiger Account – Ban nicht möglich');
      return;
    }

    // AUDIT-FIX B12: Reason-Field statt hardcodedem 'Regelverstoß'
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('🚫 Sender sperren',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Soll @$username für Chat-Verstöße gesperrt werden?\n'
                  'Der Nutzer kann 24 Stunden lang nicht mehr chatten.',
                  style: const TextStyle(color: Colors.white70, height: 1.4),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonCtrl,
                  autofocus: true,
                  maxLength: 200,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Grund (Pflicht)',
                    labelStyle: TextStyle(color: Colors.white54),
                    counterStyle: TextStyle(color: Colors.white38),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Abbrechen',
                    style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  if (reasonCtrl.text.trim().length < 3) return;
                  Navigator.pop(context, true);
                },
                icon: const Icon(Icons.block_rounded,
                    color: Colors.white, size: 16),
                label: const Text('Sperren',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    final reason = reasonCtrl.text.trim().isEmpty
        ? 'Chat-Moderation'
        : 'Chat-Moderation: ${reasonCtrl.text.trim()}';
    final ok = await WorldAdminServiceV162.banUser(
        userId: userId, reason: reason, adminUserId: widget.admin.username);
    if (ok) {
      _snack('🚫 @$username gesperrt', color: Colors.red.shade700);
    } else {
      final errMsg = AdminApiClient.instance.diagLog.isNotEmpty
          ? AdminApiClient.instance.diagLog.last.message
          : 'Unbekannter Fehler';
      _snack('❌ Sperren fehlgeschlagen: $errMsg', color: Colors.orange);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // ── Header mit Auto-Refresh Toggle ───────────────────────────
      Container(
        color: const Color(0xFF0D0D1A),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        child: Row(children: [
          Icon(Icons.chat_bubble_rounded, color: widget.accent, size: 16),
          const SizedBox(width: 8),
          Text('${_messages.length} Nachrichten',
              style: TextStyle(
                  color: widget.accentBright,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const Spacer(),
          // Auto-refresh toggle
          Row(children: [
            const Text('Auto',
                style: TextStyle(color: Colors.white38, fontSize: 11)),
            const SizedBox(width: 4),
            Switch(
              value: _autoRefresh,
              onChanged: (v) => setState(() => _autoRefresh = v),
              activeColor: widget.accent,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ]),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: _loadMessages,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: widget.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  Icon(Icons.refresh_rounded, color: widget.accent, size: 16),
            ),
          ),
        ]),
      ),

      // ── Raum-Auswahl ─────────────────────────────────────────────
      Container(
        color: const Color(0xFF0D0D1A),
        height: 50,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          itemCount: _rooms.length,
          itemBuilder: (ctx, i) {
            final r = _rooms[i];
            final rawLabel = r.split('-').last;
            final cap = rawLabel[0].toUpperCase() + rawLabel.substring(1);
            final sel = r == _selectedRoom;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedRoom = r);
                _loadMessages();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                decoration: BoxDecoration(
                  color: sel
                      ? widget.accent.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: sel ? widget.accent : Colors.transparent,
                      width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(cap,
                    style: TextStyle(
                        color: sel ? widget.accentBright : Colors.white54,
                        fontSize: 12,
                        fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
              ),
            );
          },
        ),
      ),

      // ── Nachrichten ───────────────────────────────────────────────
      Expanded(
        child: _loadingMsgs && _messages.isEmpty
            ? Center(child: CircularProgressIndicator(color: widget.accent))
            : RefreshIndicator(
                onRefresh: _loadMessages,
                color: widget.accent,
                child: _messages.isEmpty
                    ? _EmptyHint(
                        'Keine Nachrichten in diesem Raum.\nZiehe nach unten zum Aktualisieren.')
                    : ListView.builder(
                        reverse: true,
                        itemCount: _messages.length,
                        itemBuilder: (ctx, i) {
                          final msg = _messages[_messages.length - 1 - i];
                          return _ChatMsgTile(
                            msg: msg,
                            accent: widget.accent,
                            accentBright: widget.accentBright,
                            onDelete: () => _deleteMsg(msg),
                            onBan: () => _banSender(msg),
                          );
                        },
                      ),
              ),
      ),
    ]);
  }
}
