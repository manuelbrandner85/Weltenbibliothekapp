// Notification-Center — Glocken-Icon in der AppBar mit Unread-Badge.
//
// Tap → Bottom-Sheet mit den letzten 30 Notifications. Funktioniert für
// Supabase-eingeloggte User (z.B. Admins über E-Mail-Login). Für reine
// InvisibleAuth-User (kein Supabase-Session) zeigt das Sheet leeren
// Zustand — das ist bekannt und wird mit dem Auth-Refactor behoben
// (CLAUDE.md TODO #1).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';

class NotificationCenterButton extends StatefulWidget {
  final Color accent;

  const NotificationCenterButton(
      {super.key, this.accent = const Color(0xFFC9A84C)});

  @override
  State<NotificationCenterButton> createState() =>
      _NotificationCenterButtonState();
}

class _NotificationCenterButtonState extends State<NotificationCenterButton> {
  int _unread = 0;
  RealtimeChannel? _channel;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _load();
    _subscribe();
    _poll = Timer.periodic(const Duration(minutes: 1), (_) => _load());
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final items = await SupabaseNotificationService.instance
          .getNotifications(unreadOnly: true, limit: 50);
      if (!mounted) return;
      setState(() => _unread = items.length);
    } catch (_) {
      // user nicht angemeldet → 0
      if (mounted) setState(() => _unread = 0);
    }
  }

  void _subscribe() {
    try {
      _channel = SupabaseNotificationService.instance.subscribeToNotifications(
          onNotification: (_) {
        if (mounted) _load();
      });
    } catch (_) {
      // Nicht eingeloggt → keine Subscription möglich.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: 'Benachrichtigungen',
          icon:
              const Icon(Icons.notifications_none_rounded, color: Colors.white),
          onPressed: () async {
            await _NotificationSheet.show(context, accent: widget.accent);
            _load();
          },
        ),
        if (_unread > 0)
          Positioned(
            top: 6,
            right: 6,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: const Color(0xFF050310), width: 1.5),
                ),
                child: Text(
                  _unread > 99 ? '99+' : '$_unread',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _NotificationSheet {
  static Future<void> show(BuildContext context, {required Color accent}) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D0D1A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _NotificationListView(accent: accent),
    );
  }
}

class _NotificationListView extends StatefulWidget {
  final Color accent;
  const _NotificationListView({required this.accent});

  @override
  State<_NotificationListView> createState() => _NotificationListViewState();
}

class _NotificationListViewState extends State<_NotificationListView> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await SupabaseNotificationService.instance
          .getNotifications(limit: 30);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markAllRead() async {
    try {
      await SupabaseNotificationService.instance.markAllAsRead();
      await _load();
    } catch (_) {}
  }

  String _relTime(String? iso) {
    if (iso == null) return '';
    try {
      final t = DateTime.parse(iso);
      final diff = DateTime.now().difference(t);
      if (diff.inMinutes < 1) return 'jetzt';
      if (diff.inMinutes < 60) return 'vor ${diff.inMinutes}m';
      if (diff.inHours < 24) return 'vor ${diff.inHours}h';
      if (diff.inDays < 7) return 'vor ${diff.inDays}d';
      return '${t.day}.${t.month}.';
    } catch (_) {
      return '';
    }
  }

  IconData _iconFor(String? type) {
    switch (type) {
      case 'mention':
        return Icons.alternate_email_rounded;
      case 'xp':
      case 'achievement':
        return Icons.emoji_events_rounded;
      case 'admin':
        return Icons.admin_panel_settings_rounded;
      case 'access':
      case 'approval':
        return Icons.verified_user_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Container(
      constraints: BoxConstraints(maxHeight: mq.size.height * 0.7),
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
            child: Row(
              children: [
                const Text(
                  'Benachrichtigungen',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (_items.any((i) => i['is_read'] == false))
                  TextButton.icon(
                    onPressed: _markAllRead,
                    icon: Icon(Icons.done_all_rounded,
                        color: widget.accent, size: 16),
                    label: Text('Alle gelesen',
                        style: TextStyle(color: widget.accent, fontSize: 12)),
                  ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          Expanded(
            child: _loading
                ? Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(widget.accent),
                      ),
                    ),
                  )
                : _items.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_off_rounded,
                                color: Colors.white24, size: 36),
                            const SizedBox(height: 12),
                            Text(
                              'Keine Benachrichtigungen',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.55),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) =>
                            const Divider(color: Colors.white10, height: 1),
                        itemBuilder: (ctx, i) {
                          final n = _items[i];
                          final unread = n['is_read'] == false;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  widget.accent.withValues(alpha: 0.15),
                              child: Icon(_iconFor(n['type'] as String?),
                                  color: widget.accent, size: 18),
                            ),
                            title: Text(
                              n['title']?.toString() ?? '',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight:
                                    unread ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              n['body']?.toString() ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontSize: 12,
                              ),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _relTime(n['created_at'] as String?),
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 10,
                                  ),
                                ),
                                if (unread) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: widget.accent,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            onTap: () async {
                              if (unread) {
                                final id = n['id']?.toString();
                                if (id != null) {
                                  await SupabaseNotificationService.instance
                                      .markAsRead(id);
                                }
                                _load();
                              }
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
