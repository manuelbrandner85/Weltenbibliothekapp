import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

// ═══════════════════════════════════════════════════════════════════════════
// NOTIFICATION CENTER — Echtzeit-Benachrichtigungen
// Supabase notifications-Tabelle + Realtime INSERT/UPDATE
// ═══════════════════════════════════════════════════════════════════════════

class NotificationCenterScreen extends StatefulWidget {
  final String world; // 'materie' | 'energie'

  const NotificationCenterScreen({super.key, required this.world});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _notifs = [];
  bool _loading = true;
  String? _error;
  RealtimeChannel? _channel;

  bool get _isEnergie => widget.world == 'energie';
  Color get _accent => _isEnergie ? const Color(0xFFAB47BC) : const Color(0xFFE53935);
  Color get _accentLight => _isEnergie ? const Color(0xFFCE93D8) : const Color(0xFFEF9A9A);
  Color get _bg => _isEnergie ? const Color(0xFF06040F) : const Color(0xFF04080F);
  Color get _card => _isEnergie ? const Color(0xFF100B1E) : const Color(0xFF0A1020);

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  // ── Data ─────────────────────────────────────────────────────────────────

  Future<void> _loadNotifications() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final uid = _supabase.auth.currentUser?.id;
      if (uid == null) {
        if (mounted) setState(() { _loading = false; _notifs = []; });
        return;
      }
      final result = await _supabase
          .from('notifications')
          .select('*')
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(100);

      if (mounted) {
        setState(() {
          _notifs = (result as List).cast<Map<String, dynamic>>();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Benachrichtigungen konnten nicht geladen werden.';
          _loading = false;
        });
      }
    }
  }

  void _subscribeRealtime() {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;

    _channel = _supabase
        .channel('notif_center_${widget.world}')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'notifications',
        filter: PostgresChangeFilter(
          type: FilterType.eq,
          column: 'user_id',
          value: uid,
        ),
        callback: (payload) {
          if (!mounted) return;
          final newRow = payload.newRecord;
          if (newRow.isNotEmpty) {
            setState(() => _notifs.insert(0, newRow));
          }
        },
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'notifications',
        filter: PostgresChangeFilter(
          type: FilterType.eq,
          column: 'user_id',
          value: uid,
        ),
        callback: (payload) {
          if (!mounted) return;
          final updated = payload.newRecord;
          if (updated.isEmpty) return;
          setState(() {
            final idx = _notifs.indexWhere((n) => n['id'] == updated['id']);
            if (idx >= 0) _notifs[idx] = updated;
          });
        },
      )
      ..subscribe();
  }

  Future<void> _markAsRead(String id) async {
    try {
      await _supabase
          .from('notifications')
          .update({'read_at': DateTime.now().toIso8601String()})
          .eq('id', id);
      // Realtime UPDATE event aktualisiert die Liste automatisch
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    final unreadIds = _notifs
        .where((n) => n['read_at'] == null)
        .map((n) => n['id'] as String)
        .toList();
    if (unreadIds.isEmpty) return;
    try {
      await _supabase
          .from('notifications')
          .update({'read_at': DateTime.now().toIso8601String()})
          .eq('user_id', uid)
          .isFilter('read_at', null);
      // Lokal sofort aktualisieren (Realtime-UPDATE folgt)
      if (mounted) {
        setState(() {
          final now = DateTime.now().toIso8601String();
          _notifs = _notifs.map((n) {
            if (n['read_at'] == null) {
              return {...n, 'read_at': now};
            }
            return n;
          }).toList();
        });
      }
    } catch (_) {}
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  bool _isRead(Map<String, dynamic> n) => n['read_at'] != null;

  int get _unreadCount => _notifs.where((n) => !_isRead(n)).length;

  IconData _typeIcon(String? type) {
    switch (type) {
      case 'message': return Icons.chat_bubble_outline;
      case 'like':    return Icons.favorite_outline;
      case 'follow':  return Icons.person_add_outlined;
      case 'achievement': return Icons.emoji_events_outlined;
      case 'system':  return Icons.info_outline;
      default:        return Icons.notifications_outlined;
    }
  }

  Color _typeColor(String? type) {
    switch (type) {
      case 'message': return const Color(0xFF42A5F5);
      case 'like':    return const Color(0xFFEF5350);
      case 'follow':  return const Color(0xFF66BB6A);
      case 'achievement': return const Color(0xFFFFD54F);
      case 'system':  return const Color(0xFF78909C);
      default:        return const Color(0xFF9E9E9E);
    }
  }

  String _typeLabelDe(String? type) {
    switch (type) {
      case 'message': return 'Nachricht';
      case 'like':    return 'Gefällt mir';
      case 'follow':  return 'Neuer Follower';
      case 'achievement': return 'Erfolg';
      case 'system':  return 'System';
      default:        return 'Info';
    }
  }

  String _relativeTime(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inSeconds < 60) return 'Gerade eben';
      if (diff.inMinutes < 60) return 'vor ${diff.inMinutes} Min.';
      if (diff.inHours < 24)   return 'vor ${diff.inHours} Std.';
      if (diff.inDays == 1)    return 'Gestern';
      if (diff.inDays < 7)     return 'vor ${diff.inDays} Tagen';
      return DateFormat('dd.MM.yyyy').format(dt);
    } catch (_) {
      return '';
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _card,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: Colors.white,
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Icon(Icons.notifications, color: _accentLight, size: 22),
            const SizedBox(width: 10),
            const Text(
              'Benachrichtigungen',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$_unreadCount',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllRead,
              icon: Icon(Icons.done_all, color: _accentLight, size: 18),
              label: Text(
                'Alle gelesen',
                style: TextStyle(color: _accentLight, fontSize: 13),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.white.withValues(alpha: 0.07)),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return _buildSkeleton();
    if (_error != null) return _buildError();
    if (_notifs.isEmpty) return _buildEmpty();

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: _accent,
      backgroundColor: _card,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _notifs.length,
        itemBuilder: (ctx, i) => _buildNotifTile(_notifs[i]),
      ),
    );
  }

  Widget _buildNotifTile(Map<String, dynamic> n) {
    final read = _isRead(n);
    final type = n['type'] as String?;
    final icon = _typeIcon(type);
    final color = _typeColor(type);
    final title = (n['title'] as String?) ?? _typeLabelDe(type);
    final body = (n['body'] as String?) ?? (n['message'] as String?) ?? '';
    final time = _relativeTime(n['created_at'] as String?);
    final id = n['id'] as String?;

    return Dismissible(
      key: ValueKey(id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.shade800,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) async => false, // Read-only dismiss animation, no actual delete
      child: GestureDetector(
        onTap: () {
          if (!read && id != null) _markAsRead(id);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: read
                ? _card
                : _card.withValues(alpha: 1.0),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: read
                  ? Colors.white.withValues(alpha: 0.06)
                  : color.withValues(alpha: 0.35),
              width: read ? 1.0 : 1.5,
            ),
            boxShadow: read
                ? []
                : [BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 10)],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type icon circle
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: read ? 0.08 : 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withValues(alpha: read ? 0.15 : 0.3),
                    ),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                color: read ? Colors.white60 : Colors.white,
                                fontSize: 14,
                                fontWeight: read ? FontWeight.w500 : FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            time,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.35),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      if (body.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          body,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: read ? 0.4 : 0.65),
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _typeLabelDe(type),
                              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const Spacer(),
                          if (!read)
                            Container(
                              width: 8, height: 8,
                              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 6,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Container(
          height: 86,
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(children: [
            const SizedBox(width: 14),
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 12, width: 160,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(6),
                      )),
                  const SizedBox(height: 8),
                  Container(height: 10, width: 220,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(6),
                      )),
                ],
              ),
            ),
            const SizedBox(width: 14),
          ]),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded,
              color: Colors.white.withValues(alpha: 0.2), size: 72),
          const SizedBox(height: 20),
          Text(
            'Keine Benachrichtigungen',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Du bist auf dem neuesten Stand.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off, color: Colors.white.withValues(alpha: 0.25), size: 60),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Fehler beim Laden',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 15),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadNotifications,
            icon: const Icon(Icons.refresh),
            label: const Text('Erneut versuchen'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
