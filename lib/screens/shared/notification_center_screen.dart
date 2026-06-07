import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/wb_cinematic_tokens.dart';
import '../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../widgets/cinematic/wb_vignette.dart';
import '../../services/account_service.dart';
import '../../services/unified_profile_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// NOTIFICATION CENTER — Echtzeit-Benachrichtigungen
// Supabase notifications-Tabelle + Realtime INSERT/UPDATE
// ═══════════════════════════════════════════════════════════════════════════

class NotificationCenterScreen extends StatefulWidget {
  final String world; // 'materie' | 'energie'

  const NotificationCenterScreen({super.key, required this.world});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _notifs = [];
  bool _loading = true;
  String? _error;
  RealtimeChannel? _channel;

  bool get _isEnergie => widget.world == 'energie';
  Color get _accent =>
      _isEnergie ? const Color(0xFFAB47BC) : const Color(0xFFE53935);
  Color get _accentLight =>
      _isEnergie ? const Color(0xFFCE93D8) : const Color(0xFFEF9A9A);
  Color get _bg =>
      _isEnergie ? const Color(0xFF06040F) : const Color(0xFF04080F);
  Color get _card =>
      _isEnergie ? const Color(0xFF100B1E) : const Color(0xFF0A1020);

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

  /// Loest die wirksame Identitaet auf. InvisibleAuth-User haben KEINE
  /// Supabase-UUID (auth.currentUser == null), nutzen aber eine
  /// legacy_user_id ('user_<ts>_<rand>') aus dem UnifiedProfileService.
  /// Returnt (spaltenname, wert) -- entweder ('user_id', uuid) oder
  /// ('legacy_user_id', legacyId). Returnt null wenn keine Identitaet da ist.
  (String, String)? _identity() {
    final authUid = _supabase.auth.currentUser?.id;
    if (authUid != null && authUid.isNotEmpty) return ('user_id', authUid);
    final unified = UnifiedProfileService.instance.userId;
    if (unified == null || unified.isEmpty) return null;
    // InvisibleAuth-IDs beginnen mit 'user_'. Eine UUID nicht.
    if (unified.startsWith('user_')) return ('legacy_user_id', unified);
    return ('user_id', unified);
  }

  bool get _isLegacy => _identity()?.$1 == 'legacy_user_id';

  Future<void> _loadNotifications() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final id = _identity();
      if (id == null) {
        if (mounted) {
          setState(() {
            _loading = false;
            _notifs = [];
          });
        }
        return;
      }
      List<Map<String, dynamic>> result;
      if (id.$1 == 'legacy_user_id') {
        // InvisibleAuth: RLS blockiert Direktzugriff -> ueber Worker laden.
        result = await AccountService.instance.getNotifications(userId: id.$2);
      } else {
        final raw = await _supabase
            .from('notifications')
            .select('*')
            .eq(id.$1, id.$2)
            .order('created_at', ascending: false)
            .limit(100);
        result = (raw as List).cast<Map<String, dynamic>>();
      }

      if (mounted) {
        setState(() {
          _notifs = result;
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
    if (!mounted) return;
    final id = _identity();
    if (id == null) return;
    // InvisibleAuth: Supabase-Realtime ist durch RLS (auth.uid()=user_id)
    // blockiert -> keine Live-Subscription moeglich. Die 30s-Polling-Schicht
    // im PushNotificationManager + Reload beim Oeffnen decken das ab.
    if (id.$1 == 'legacy_user_id') return;
    // Prevent duplicate channels if called more than once
    _channel?.unsubscribe();

    _channel = _supabase.channel('notif_center_${widget.world}')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'notifications',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: id.$1,
          value: id.$2,
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
          type: PostgresChangeFilterType.eq,
          column: id.$1,
          value: id.$2,
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
      if (_isLegacy) {
        final me = _identity();
        if (me == null) return;
        await AccountService.instance
            .markNotificationsRead(userId: me.$2, id: id);
        // Lokal aktualisieren (kein Realtime fuer Legacy).
        if (mounted) {
          setState(() {
            final idx = _notifs.indexWhere((n) => n['id'] == id);
            if (idx >= 0) {
              _notifs[idx] = {..._notifs[idx], 'is_read': true};
            }
          });
        }
        return;
      }
      // Beide Spalten setzen -- die App nutzt an verschiedenen Stellen
      // read_at (dieser Screen) UND is_read (Badge-Button). Sonst springt
      // der Gelesen-Status.
      await _supabase.from('notifications').update({
        'read_at': DateTime.now().toIso8601String(),
        'is_read': true,
      }).eq('id', id);
      // Realtime UPDATE event aktualisiert die Liste automatisch
    } catch (e) {
      if (kDebugMode)
        debugPrint('notification_center_screen: silent catch -> $e');
    }
  }

  /// Loescht eine Notification ueber den Worker (InvisibleAuth-tauglich).
  /// Gibt true zurueck wenn die Kachel weggewischt werden darf.
  Future<bool> _deleteNotification(String id) async {
    final uid =
        _supabase.auth.currentUser?.id ?? UnifiedProfileService.instance.userId;
    if (uid == null) return false;
    final ok =
        await AccountService.instance.deleteNotification(id: id, userId: uid);
    if (ok && mounted) {
      setState(() => _notifs.removeWhere((n) => n['id'] == id));
    } else if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loeschen fehlgeschlagen.')),
      );
    }
    return ok;
  }

  /// Loescht ALLE Notifications des Users.
  Future<void> _deleteAll() async {
    final uid =
        _supabase.auth.currentUser?.id ?? UnifiedProfileService.instance.userId;
    if (uid == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _card,
        title:
            const Text('Alle loeschen?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Alle Benachrichtigungen werden unwiderruflich entfernt.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Loeschen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok =
        await AccountService.instance.deleteAllNotifications(userId: uid);
    if (ok && mounted) {
      setState(() => _notifs = []);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loeschen fehlgeschlagen.')),
      );
    }
  }

  Future<void> _markAllRead() async {
    final id = _identity();
    if (id == null) return;
    if (_notifs.where((n) => !_isRead(n)).isEmpty) return;
    try {
      if (id.$1 == 'legacy_user_id') {
        await AccountService.instance.markNotificationsRead(userId: id.$2);
      } else {
        await _supabase
            .from('notifications')
            .update({
              'read_at': DateTime.now().toIso8601String(),
              'is_read': true,
            })
            .eq(id.$1, id.$2)
            .isFilter('read_at', null);
      }
      // Lokal sofort aktualisieren (Realtime-UPDATE folgt bei UUID)
      if (mounted) {
        setState(() {
          final now = DateTime.now().toIso8601String();
          _notifs = _notifs.map((n) {
            if (!_isRead(n)) {
              return {...n, 'read_at': now, 'is_read': true};
            }
            return n;
          }).toList();
        });
      }
    } catch (e) {
      if (kDebugMode)
        debugPrint('notification_center_screen: silent catch -> $e');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  // Liest BEIDE moeglichen Gelesen-Spalten (read_at-Timestamp ODER
  // is_read-Boolean), damit der Status konsistent ist egal welche der
  // Worker/Client-Pfade die Notification als gelesen markiert hat.
  bool _isRead(Map<String, dynamic> n) =>
      n['read_at'] != null || n['is_read'] == true;

  int get _unreadCount => _notifs.where((n) => !_isRead(n)).length;

  IconData _typeIcon(String? type) {
    switch (type) {
      case 'message':
        return Icons.chat_bubble_outline;
      case 'like':
        return Icons.favorite_outline;
      case 'follow':
        return Icons.person_add_outlined;
      case 'achievement':
        return Icons.emoji_events_outlined;
      case 'system':
        return Icons.info_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _typeColor(String? type) {
    switch (type) {
      case 'message':
        return const Color(0xFF42A5F5);
      case 'like':
        return const Color(0xFFEF5350);
      case 'follow':
        return const Color(0xFF66BB6A);
      case 'achievement':
        return const Color(0xFFFFD54F);
      case 'system':
        return const Color(0xFF78909C);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  String _typeLabelDe(String? type) {
    switch (type) {
      case 'message':
        return 'Nachricht';
      case 'like':
        return 'Gefällt mir';
      case 'follow':
        return 'Neuer Follower';
      case 'achievement':
        return 'Erfolg';
      case 'system':
        return 'System';
      default:
        return 'Info';
    }
  }

  String _relativeTime(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inSeconds < 60) return 'Gerade eben';
      if (diff.inMinutes < 60) return 'vor ${diff.inMinutes} Min.';
      if (diff.inHours < 24) return 'vor ${diff.inHours} Std.';
      if (diff.inDays == 1) return 'Gestern';
      if (diff.inDays < 7) return 'vor ${diff.inDays} Tagen';
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
      backgroundColor: const Color(0xFF000004),
      appBar: WBGlassAppBar(
        world: WBWorld.neutral,
        titleWidget: Row(
          children: [
            Icon(Icons.notifications, color: _accentLight, size: 20),
            const SizedBox(width: 10),
            Text(
              'Benachrichtigungen',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.4,
              ),
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
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
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
          if (_notifs.isNotEmpty)
            IconButton(
              tooltip: 'Alle loeschen',
              onPressed: _deleteAll,
              icon: Icon(Icons.delete_sweep_outlined,
                  color: _accentLight, size: 20),
            ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0D0A1A),
                    Color(0xFF050310),
                    Color(0xFF000004)
                  ],
                ),
              ),
            ),
          ),
          const Positioned.fill(child: IgnorePointer(child: WBVignette())),
          _buildBody(),
        ],
      ),
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
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
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
      confirmDismiss: (_) async {
        if (id == null) return false;
        return _deleteNotification(id);
      },
      child: GestureDetector(
        onTap: () {
          if (!read && id != null) _markAsRead(id);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: read ? _card : _card.withValues(alpha: 1.0),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: read
                  ? Colors.white.withValues(alpha: 0.06)
                  : color.withValues(alpha: 0.35),
              width: read ? 1.0 : 1.5,
            ),
            boxShadow: read
                ? []
                : [
                    BoxShadow(
                        color: color.withValues(alpha: 0.12), blurRadius: 10)
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type icon circle
                Container(
                  width: 44,
                  height: 44,
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
                                fontWeight:
                                    read ? FontWeight.w500 : FontWeight.bold,
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
                            color: Colors.white
                                .withValues(alpha: read ? 0.4 : 0.65),
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _typeLabelDe(type),
                              style: TextStyle(
                                  color: color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          const Spacer(),
                          if (!read)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                  color: color, shape: BoxShape.circle),
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
              width: 44,
              height: 44,
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
                  Container(
                      height: 12,
                      width: 160,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(6),
                      )),
                  const SizedBox(height: 8),
                  Container(
                      height: 10,
                      width: 220,
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
          Icon(Icons.notifications_none,
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
          Icon(Icons.cloud_off,
              color: Colors.white.withValues(alpha: 0.25), size: 60),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Fehler beim Laden',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5), fontSize: 15),
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
