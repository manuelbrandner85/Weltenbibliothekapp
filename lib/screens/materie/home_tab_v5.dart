import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/openclaw_dashboard_service.dart';
import '../../services/storage_service.dart';
import '../../models/materie_profile.dart';
import 'package:url_launcher/url_launcher.dart';
import 'recherche_tab_mobile.dart';
import 'materie_live_chat_screen.dart';
import 'history_timeline_screen.dart';
import '../../services/chat/recent_rooms_service.dart';
import '../shared/bookmarks_screen.dart';
import '../shared/stats_dashboard_screen.dart';
import '../shared/notification_center_screen.dart';
import '../../services/world_subscription_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// MATERIE HOME DASHBOARD V7 – REDESIGN 2026
// "Cosmos Explorer" · Deep-Blue · Glassmorphism · Parallax · Live-Data
// ═══════════════════════════════════════════════════════════════════════════

class MaterieHomeTabV5 extends StatefulWidget {
  const MaterieHomeTabV5({super.key});
  @override
  State<MaterieHomeTabV5> createState() => _MaterieHomeTabV5State();
}

class _MaterieHomeTabV5State extends State<MaterieHomeTabV5>
    with TickerProviderStateMixin {

  // ── Animations ─────────────────────────────────────────────────────────
  late AnimationController _pulseCtrl;
  late AnimationController _entryCtrl;
  late AnimationController _particleCtrl;
  late Animation<double> _entryAnim;

  // ── Services ───────────────────────────────────────────────────────────
  final _dash = OpenClawDashboardService();

  // ── State ──────────────────────────────────────────────────────────────
  MaterieProfile? _profile;
  bool _loading = true;
  int _articles = 0, _sessions = 0, _bookmarks = 0, _shares = 0;
  List<Map<String, dynamic>> _latestArticles = [];
  List<Map<String, dynamic>> _trending = [];
  int _notifs = 0;
  bool _worldSubscribed = false;
  final _worldSubSvc = WorldSubscriptionService();
  final _scrollCtrl = ScrollController();
  double _scrollOffset = 0;
  Timer? _liveTimer;
  RealtimeChannel? _channel;
  RealtimeChannel? _notifChannel;
  RealtimeChannel? _statsChannel;

  // ── Design Colors ──────────────────────────────────────────────────────
  static const _bg      = Color(0xFF04080F);
  static const _card    = Color(0xFF0A1020);
  static const _cardB   = Color(0xFF0D1528);
  static const _blue    = Color(0xFF2979FF);
  static const _blueL   = Color(0xFF82B1FF);
  static const _blueD   = Color(0xFF1A237E);
  static const _cyan    = Color(0xFF00E5FF);
  static const _green   = Color(0xFF00E676);
  static const _amber   = Color(0xFFFFAB00);
  static const _red     = Color(0xFFFF1744);
  static const _purple  = Color(0xFF7C4DFF);

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 2))..repeat(reverse: true);
    _entryCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1000));
    _particleCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 8))..repeat();
    _entryAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic);
    _entryCtrl.forward();
    _scrollCtrl.addListener(() {
      setState(() => _scrollOffset = _scrollCtrl.offset);
    });
    _loadAll();
    _loadWorldSubscription();
    _startLive();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _entryCtrl.dispose();
    _particleCtrl.dispose();
    _scrollCtrl.dispose();
    _liveTimer?.cancel();
    _channel?.unsubscribe();
    _notifChannel?.unsubscribe();
    _statsChannel?.unsubscribe();
    super.dispose();
  }

  // ── Data ───────────────────────────────────────────────────────────────
  Future<void> _loadAll() async {
    if (mounted) setState(() => _loading = true);
    await Future.wait([_loadProfile(), _loadStats(), _loadContent()]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadProfile() async {
    _profile = StorageService().getMaterieProfile();
  }

  Future<void> _loadStats() async {
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return;

      final results = await Future.wait([
        // Eigene Community-Beiträge (Materie-Welt)
        Supabase.instance.client
            .from('community_posts')
            .select('id, likes_count')
            .eq('user_id', uid)
            .eq('world', 'materie'),
        // Eigene Chat-Nachrichten (alle Materie-Räume)
        Supabase.instance.client
            .from('chat_messages')
            .select('id, created_at')
            .eq('user_id', uid)
            .like('room_id', 'materie%')
            .order('created_at', ascending: false)
            .limit(500),
      ]);

      final posts   = (results[0] as List?) ?? [];
      final msgs    = (results[1] as List?) ?? [];
      final likes   = posts.fold<int>(0, (s, p) => s + ((p['likes_count'] as num?)?.toInt() ?? 0));
      final streak  = _calcStreak(msgs
          .map((m) => DateTime.tryParse(m['created_at'] as String? ?? ''))
          .whereType<DateTime>()
          .toList());

      if (mounted) {
        setState(() {
          _articles  = posts.length;
          _sessions  = msgs.length;
          _bookmarks = likes;
          _shares    = streak;
        });
      }
    } catch (_) {}
  }

  int _calcStreak(List<DateTime> dates) {
    if (dates.isEmpty) return 0;
    final daySet = dates.map((d) => DateTime(d.year, d.month, d.day)).toSet();
    int streak = 0;
    var cursor = DateTime.now();
    cursor = DateTime(cursor.year, cursor.month, cursor.day);
    if (!daySet.contains(cursor)) cursor = cursor.subtract(const Duration(days: 1));
    while (daySet.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Future<void> _loadContent() async {
    try {
      _latestArticles = await _dash.getRecentArticles(realm: 'materie', limit: 6);
      _trending       = await _dash.getTrendingTopics(realm: 'materie', limit: 8);
      final uid  = Supabase.instance.client.auth.currentUser?.id ??
                   await StorageService().getUserId('materie');
      // Unread-Count direkt aus DB (kein Umweg über getNotifications-Normalisierung)
      final unreadResult = await Supabase.instance.client
          .from('notifications')
          .select('id')
          .eq('user_id', uid!)
          .isFilter('read_at', null);
      if (mounted) {
        setState(() {
          _notifs = (unreadResult as List).length;
        });
      }
    } catch (_) {}
  }

  void _startLive() {
    final client = Supabase.instance.client;

    // Realtime: community_posts → Content + Stats neu laden
    _channel = client
        .channel('materie_home_content')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public', table: 'community_posts',
        callback: (_) { if (mounted) { _loadContent(); _loadStats(); } },
      )
      ..subscribe();

    // Realtime: chat_messages + community_posts → Stats neu laden
    _statsChannel = client
        .channel('materie_home_stats')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public', table: 'chat_messages',
        callback: (_) { if (mounted) _loadStats(); },
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public', table: 'community_posts',
        callback: (_) { if (mounted) _loadStats(); },
      )
      ..subscribe();

    // Realtime: notifications → Glocken-Badge sofort aktualisieren
    final uid = client.auth.currentUser?.id;
    if (uid != null) {
      _notifChannel = client
          .channel('materie_home_notifs')
        ..onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: uid,
          ),
          callback: (_) { if (mounted) setState(() => _notifs++); },
        )
        ..onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: uid,
          ),
          // Wenn mark-as-read → Badge neu berechnen (lade Unread-Count frisch)
          callback: (_) { if (mounted) _refreshNotifCount(); },
        )
        ..subscribe();
    }

    // Fallback-Timer: alle 5 Min vollen Reload (deckt Supabase-Realtime-Ausfälle ab)
    _liveTimer = Timer.periodic(const Duration(minutes: 5),
        (_) { if (mounted) _loadAll(); });
  }

  Future<void> _refreshNotifCount() async {
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return;
      final result = await Supabase.instance.client
          .from('notifications')
          .select('id')
          .eq('user_id', uid)
          .isFilter('read_at', null);
      if (mounted) setState(() => _notifs = (result as List).length);
    } catch (_) {}
  }

  Future<void> _loadWorldSubscription() async {
    final subscribed = await _worldSubSvc.isSubscribed('materie');
    if (mounted) setState(() => _worldSubscribed = subscribed);
  }

  Future<void> _toggleWorldSubscription() async {
    final newState = await _worldSubSvc.toggle('materie');
    if (mounted) {
      setState(() => _worldSubscribed = newState);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(newState
            ? '🔔 Artikel-Benachrichtigungen aktiviert'
            : '🔕 Artikel-Benachrichtigungen deaktiviert'),
        duration: const Duration(seconds: 2),
        backgroundColor: newState ? const Color(0xFF2979FF) : Colors.grey[800],
      ));
    }
  }

  // ── Navigation ─────────────────────────────────────────────────────────
  Future<void> _go(Widget screen) => Navigator.push<void>(
      context, MaterialPageRoute(builder: (_) => screen));

  void _goArticle(Map<String, dynamic> a) {
    final url = a['url'] as String?;
    if (url != null && url.isNotEmpty) {
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      _go(const MobileOptimierterRechercheTab());
    }
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 5)  return 'Gute Nacht';
    if (h < 12) return 'Guten Morgen';
    if (h < 17) return 'Guten Tag';
    if (h < 21) return 'Guten Abend';
    return 'Gute Nacht';
  }

  // ══════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: const TextStyle(
        decoration: TextDecoration.none,
        decorationColor: Colors.transparent,
        fontFamily: 'Roboto',
        letterSpacing: 0.1,
        height: 1.25,
      ),
      child: Scaffold(
        backgroundColor: _bg,
        body: RefreshIndicator(
          onRefresh: _loadAll,
          color: _blue,
          backgroundColor: _cardB,
          displacement: 60,
          child: CustomScrollView(
            controller: _scrollCtrl,
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              _buildHeroHeader(),
              _buildLiveStatBanner(),
              _buildActionGrid(),
              _buildRecentRooms(),
              _buildSectionTitle('🔥 Trending', subtitle: 'Heiß diskutiert'),
              _buildTrendingChips(),
              _buildSectionTitle('📰 Neueste Artikel', subtitle: 'Frisch aus der Welt'),
              _buildArticleCards(),
              _buildExploreSection(),
              const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
            ],
          ),
        ),
      ),
    );
  }

  // ── HERO HEADER (Parallax) ─────────────────────────────────────────────
  Widget _buildHeroHeader() {
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _entryAnim,
        child: SizedBox(
          height: 220,
          child: Stack(
            children: [
              // Animated background
              AnimatedBuilder(
                animation: _particleCtrl,
                builder: (_, __) => CustomPaint(
                  painter: _CosmosBackgroundPainter(
                    progress: _particleCtrl.value,
                    scrollOffset: _scrollOffset,
                    color: _blue,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
              // Gradient overlay
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, _bg],
                    stops: [0.5, 1.0],
                  ),
                ),
              ),
              // Content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: avatar + greeting + notifications
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildAvatarOrb(),
                          const SizedBox(width: 14),
                          Expanded(child: _buildGreetingText()),
                          _buildArticleAlertToggle(),
                          const SizedBox(width: 8),
                          _buildNotifBell(),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Search bar
                      _buildInlineSearch(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarOrb() {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) => GestureDetector(
        onTap: () => _go(const StatsDashboardScreen(world: 'materie')),
        child: Container(
          width: 54, height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                _blue.withValues(alpha: 0.35 + _pulseCtrl.value * 0.15),
                _blueD.withValues(alpha: 0.1),
              ],
            ),
            border: Border.all(
                color: _blue.withValues(alpha: 0.5 + _pulseCtrl.value * 0.25),
                width: 1.5),
            boxShadow: [
              BoxShadow(
                color: _blue.withValues(alpha: 0.2 + _pulseCtrl.value * 0.2),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Text(
              _profile?.avatarEmoji ?? '🌍',
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_greeting,
            style: const TextStyle(
                color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Row(children: [
          Flexible(
            child: Text(
              _profile?.username ?? 'Explorer',
              style: const TextStyle(
                  color: Colors.white, fontSize: 20,
                  fontWeight: FontWeight.bold, letterSpacing: -0.3),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_profile?.isAdmin() == true) ...[
            const SizedBox(width: 8),
            _AdminBadge(isRoot: _profile!.isRootAdmin()),
          ],
        ]),
        const SizedBox(height: 3),
        // Live dot + status
        Row(children: [
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => Container(
              width: 6, height: 6,
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.6 + _pulseCtrl.value * 0.4),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: _green.withValues(alpha: 0.5), blurRadius: 4)],
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Text('Welt der MATERIE',
              style: TextStyle(color: Colors.white38, fontSize: 11)),
        ]),
      ],
    );
  }

  Widget _buildArticleAlertToggle() {
    return Tooltip(
      message: _worldSubscribed
          ? 'Artikel-Alerts deaktivieren'
          : 'Artikel-Alerts aktivieren',
      child: GestureDetector(
        onTap: _toggleWorldSubscription,
        child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: _worldSubscribed
                ? _blue.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _worldSubscribed
                  ? _blue.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.12),
            ),
          ),
          child: Icon(
            _worldSubscribed
                ? Icons.newspaper
                : Icons.newspaper_outlined,
            color: _worldSubscribed ? _blue : Colors.white60,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildNotifBell() {
    return GestureDetector(
      onTap: () async {
        await _go(const NotificationCenterScreen(world: 'materie'));
        // Nach Rückkehr Badge neu laden (User könnte Notifs gelesen haben)
        _refreshNotifCount();
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Icon(
              _notifs > 0 ? Icons.notifications : Icons.notifications_outlined,
              color: _notifs > 0 ? _amber : Colors.white60,
              size: 22,
            ),
          ),
          if (_notifs > 0)
            Positioned(
              right: -4, top: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: _red, shape: BoxShape.circle),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  _notifs > 9 ? '9+' : '$_notifs',
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInlineSearch() {
    return GestureDetector(
      onTap: () => _go(const MobileOptimierterRechercheTab()),
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(color: _blue.withValues(alpha: 0.08), blurRadius: 12),
          ],
        ),
        child: Row(children: [
          Icon(Icons.search_rounded, color: _blueL.withValues(alpha: 0.7), size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Artikel, Themen, Fakten suchen…',
                style: TextStyle(color: Colors.white30, fontSize: 14)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _blue.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _blue.withValues(alpha: 0.35)),
            ),
            child: const Text('KI-Suche',
                style: TextStyle(color: _blueL, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    );
  }

  // ── LIVE STAT BANNER ───────────────────────────────────────────────────
  Widget _buildLiveStatBanner() {
    final stats = [
      _StatDef(icon: Icons.edit_note,             label: 'Beiträge',    value: _articles,  color: _blue),
      _StatDef(icon: Icons.chat_bubble_outline,   label: 'Nachrichten', value: _sessions,  color: _cyan),
      _StatDef(icon: Icons.favorite_border,       label: 'Likes',       value: _bookmarks, color: _red),
      _StatDef(icon: Icons.local_fire_department, label: 'Streak',      value: _shares,    color: _amber),
    ];

    return SliverToBoxAdapter(
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
            .animate(_entryAnim),
        child: FadeTransition(
          opacity: _entryAnim,
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: _cardB,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              children: stats.asMap().entries.map((e) {
                final i = e.key;
                final s = e.value;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _go(const StatsDashboardScreen(world: 'materie')),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: i < stats.length - 1
                          ? BoxDecoration(
                              border: Border(
                                right: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                              ),
                            )
                          : null,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(s.icon, color: s.color, size: 18),
                          const SizedBox(height: 5),
                          _loading
                              ? _Shimmer(w: 26, h: 16, r: 4)
                              : Text('${s.value}',
                                  style: TextStyle(
                                      color: s.color, fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                          const SizedBox(height: 1),
                          Text(s.label,
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 9,
                                  fontWeight: FontWeight.w500),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  // ── ACTION GRID (2×2 tiles) ─────────────────────────────────────────────
  Widget _buildActionGrid() {
    final tiles = [
      _TileDef(
        icon: Icons.auto_stories_rounded,
        label: 'Recherche',
        sub: 'Artikel & Fakten',
        gradient: [const Color(0xFF0D47A1), const Color(0xFF1565C0), const Color(0xFF2979FF)],
        badge: 0,
        onTap: () => _go(const MobileOptimierterRechercheTab()),
      ),
      _TileDef(
        icon: Icons.forum_rounded,
        label: 'Live Chat',
        sub: 'Jetzt diskutieren',
        gradient: [const Color(0xFF006064), const Color(0xFF00838F), const Color(0xFF00E5FF)],
        badge: _notifs,
        onTap: () => _go(const MaterieLiveChatScreen()),
      ),
      _TileDef(
        icon: Icons.timeline_rounded,
        label: 'Zeitlinie',
        sub: 'Geschichte & Ereignisse',
        gradient: [const Color(0xFF1B5E20), const Color(0xFF2E7D32), const Color(0xFF43A047)],
        badge: 0,
        onTap: () => _go(const HistoryTimelineScreen()),
      ),
      _TileDef(
        icon: Icons.collections_bookmark_rounded,
        label: 'Gespeichert',
        sub: 'Deine Sammlung',
        gradient: [const Color(0xFFE65100), const Color(0xFFF57C00), const Color(0xFFFFAB00)],
        badge: _bookmarks > 0 ? _bookmarks : 0,
        onTap: () => _go(const BookmarksScreen()),
      ),
    ];

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
              .animate(_entryAnim),
          child: FadeTransition(
            opacity: _entryAnim,
            child: Column(children: [
              Row(children: [
                _buildActionTile(tiles[0]),
                const SizedBox(width: 10),
                _buildActionTile(tiles[1]),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                _buildActionTile(tiles[2]),
                const SizedBox(width: 10),
                _buildActionTile(tiles[3]),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile(_TileDef t) {
    return Expanded(
      child: GestureDetector(
        onTap: t.onTap,
        child: Container(
          height: 108,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: t.gradient,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                  color: t.gradient.last.withValues(alpha: 0.3),
                  blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                // Decorative background circles
                Positioned(
                  right: -16, bottom: -16,
                  child: Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.07),
                    ),
                  ),
                ),
                Positioned(
                  right: -4, top: -20,
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.04),
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(t.icon, color: Colors.white, size: 20),
                      ),
                      const Spacer(),
                      Text(t.label,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 1),
                      Text(t.sub,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 10)),
                    ],
                  ),
                ),
                // Badge
                if (t.badge > 0)
                  Positioned(
                    right: 10, top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        t.badge > 9 ? '9+' : '${t.badge}',
                        style: TextStyle(
                            fontSize: 9, fontWeight: FontWeight.bold,
                            color: t.gradient.last),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── SECTION TITLE ──────────────────────────────────────────────────────
  Widget _buildSectionTitle(String title, {String subtitle = ''}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 17,
                      fontWeight: FontWeight.bold)),
              if (subtitle.isNotEmpty)
                Text(subtitle,
                    style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ]),
          ),
          GestureDetector(
            onTap: () => _go(const MobileOptimierterRechercheTab()),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _blue.withValues(alpha: 0.3)),
              ),
              child: const Text('Alle →',
                  style: TextStyle(color: _blueL, fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }

  // ── RECENT ROOMS ───────────────────────────────────────────────────────
  static const Map<String, (String, String)> _recentRoomMeta = {
    'politik': ('🎭', 'Politik'),
    'geschichte': ('🏛️', 'Geschichte'),
    'ufo': ('🛸', 'UFOs'),
    'verschwoerungen': ('👁️', 'Verschwörungen'),
    'wissenschaft': ('🔬', 'Wissenschaft'),
    'heilung': ('🌿', 'Heilung'),
    'forschung': ('🧪', 'Forschung'),
  };

  Widget _buildRecentRooms() {
    return SliverToBoxAdapter(
      child: FutureBuilder<List<String>>(
        future: RecentRoomsService.instance.get('materie'),
        builder: (ctx, snap) {
          final rooms = snap.data ?? const <String>[];
          if (rooms.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history, size: 16, color: Colors.white70),
                    const SizedBox(width: 6),
                    Text(
                      'Zuletzt besucht',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: rooms.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (c, i) {
                      final id = rooms[i];
                      final meta = _recentRoomMeta[id] ?? ('💬', id);
                      return InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                MaterieLiveChatScreen(initialRoom: id),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: _red.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(meta.$1, style: const TextStyle(fontSize: 14)),
                              const SizedBox(width: 6),
                              Text(
                                meta.$2,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── TRENDING CHIPS ─────────────────────────────────────────────────────
  Widget _buildTrendingChips() {
    final topics = _trending.isNotEmpty
        ? _trending.map((t) => t['topic'] ?? t['title'] ?? '').whereType<String>().toList()
        : ['UFO', 'Geopolitik', 'Technologie', 'Medien', 'Wissenschaft', 'Geschichte', 'Deep State'];

    final chipColors = [_blue, _cyan, _red, _amber, _green, _purple, _blueL];

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 44,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _loading ? 6 : topics.length,
          itemBuilder: (ctx, i) {
            if (_loading) {
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _Shimmer(w: 85, h: 36, r: 20),
              );
            }
            final topic = topics[i];
            final c = chipColors[i % chipColors.length];
            return GestureDetector(
              onTap: () => _go(const MobileOptimierterRechercheTab()),
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: c.withValues(alpha: 0.3)),
                ),
                child: Text(topic,
                    style: TextStyle(color: c, fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── ARTICLE CARDS ──────────────────────────────────────────────────────
  Widget _buildArticleCards() {
    if (_loading) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: List.generate(3, (_) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _Shimmer(w: double.infinity, h: 88, r: 16),
            )),
          ),
        ),
      );
    }

    if (_latestArticles.isEmpty) {
      return SliverToBoxAdapter(
        child: GestureDetector(
          onTap: () => _go(const MobileOptimierterRechercheTab()),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _blue.withValues(alpha: 0.15)),
            ),
            child: Column(children: [
              Icon(Icons.article_outlined, color: _blueL.withValues(alpha: 0.4), size: 44),
              const SizedBox(height: 14),
              const Text('Artikel entdecken',
                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 6),
              const Text('Zur Recherche →',
                  style: TextStyle(color: _blueL, fontSize: 13, fontWeight: FontWeight.w500)),
            ]),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (ctx, i) {
          if (i >= _latestArticles.length) return null;
          final a = _latestArticles[i];
          // First article is featured (larger)
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: _FeaturedArticleCard(
                article: a,
                onTap: () => _goArticle(a),
                accent: _blue,
              ),
            );
          }
          return Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16,
                i == _latestArticles.length - 1 ? 0 : 10),
            child: _ArticleCard(article: a, onTap: () => _goArticle(a), accent: _blue),
          );
        },
        childCount: _latestArticles.length,
      ),
    );
  }

  // ── EXPLORE SECTION ────────────────────────────────────────────────────
  Widget _buildExploreSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
        child: GestureDetector(
          onTap: () => _go(const StatsDashboardScreen(world: 'materie')),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _blueD.withValues(alpha: 0.8),
                  _blue.withValues(alpha: 0.4),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _blue.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(color: _blue.withValues(alpha: 0.15), blurRadius: 24, offset: const Offset(0, 8)),
              ],
            ),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Statistiken & Analyse',
                      style: TextStyle(color: Colors.white, fontSize: 15,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Deine persönlichen Insights',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 12)),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.analytics_outlined, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text('Öffnen',
                      style: TextStyle(color: Colors.white, fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// COSMOS BACKGROUND PAINTER
// ═══════════════════════════════════════════════════════════════════════════
class _CosmosBackgroundPainter extends CustomPainter {
  final double progress;
  final double scrollOffset;
  final Color color;

  _CosmosBackgroundPainter({
    required this.progress,
    required this.scrollOffset,
    required this.color,
  });

  static final List<Offset> _stars = List.generate(40, (i) {
    final rng = math.Random(i * 7 + 13);
    return Offset(rng.nextDouble(), rng.nextDouble());
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Deep background
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF040A18),
          const Color(0xFF060D20),
          const Color(0xFF08101A),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Animated nebula glow
    final nebulaPaint = Paint()
      ..color = color.withValues(alpha: 0.06 + math.sin(progress * math.pi * 2) * 0.03)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
    canvas.drawCircle(
      Offset(size.width * 0.3, size.height * 0.4),
      size.width * 0.5,
      nebulaPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.2),
      size.width * 0.3,
      nebulaPaint..color = const Color(0xFF7C4DFF).withValues(alpha: 0.04),
    );

    // Stars
    final starPaint = Paint()..color = Colors.white;
    for (var i = 0; i < _stars.length; i++) {
      final s = _stars[i];
      final twinkle = math.sin(progress * math.pi * 2 + i * 0.7);
      final alpha = (0.2 + twinkle * 0.15).clamp(0.05, 0.4);
      final radius = 1.0 + (i % 3) * 0.5;
      starPaint.color = Colors.white.withValues(alpha: alpha);
      canvas.drawCircle(
        Offset(s.dx * size.width, s.dy * size.height - scrollOffset * 0.15),
        radius, starPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_CosmosBackgroundPainter old) =>
      old.progress != progress || old.scrollOffset != scrollOffset;
}

// ═══════════════════════════════════════════════════════════════════════════
// WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _AdminBadge extends StatelessWidget {
  final bool isRoot;
  const _AdminBadge({required this.isRoot});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: isRoot
          ? [Colors.amber.shade700, Colors.orange.shade500]
          : [const Color(0xFFE53935), const Color(0xFFC62828)]),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      isRoot ? '👑 ROOT' : '🛡️ ADM',
      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
    ),
  );
}

class _StatDef {
  final IconData icon;
  final String label;
  final int value;
  final Color color;
  const _StatDef({required this.icon, required this.label, required this.value, required this.color});
}

class _TileDef {
  final IconData icon;
  final String label, sub;
  final List<Color> gradient;
  final int badge;
  final VoidCallback onTap;
  const _TileDef({required this.icon, required this.label, required this.sub,
    required this.gradient, required this.badge, required this.onTap});
}

class _Shimmer extends StatelessWidget {
  final double w, h, r;
  const _Shimmer({required this.w, required this.h, required this.r});
  @override
  Widget build(BuildContext context) => Container(
    width: w, height: h,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(r),
    ),
  );
}

// Featured article (large hero card)
class _FeaturedArticleCard extends StatelessWidget {
  final Map<String, dynamic> article;
  final VoidCallback onTap;
  final Color accent;
  const _FeaturedArticleCard({required this.article, required this.onTap, required this.accent});

  @override
  Widget build(BuildContext context) {
    final title  = (article['title']  ?? 'Artikel').toString();
    final source = (article['source'] ?? article['realm'] ?? 'Materie').toString();
    final date   = (article['created_at'] ?? article['publishedAt'] ?? '').toString();
    final tags   = (article['tags'] as List?)?.take(2).toList() ?? [];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0A1828),
              accent.withValues(alpha: 0.12),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(color: accent.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accent.withValues(alpha: 0.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 5),
                  Text('TOP ARTIKEL',
                      style: TextStyle(color: accent, fontSize: 9,
                          fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ]),
              ),
              const Spacer(),
              if (date.isNotEmpty)
                Text(_formatDate(date),
                    style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ]),
            const SizedBox(height: 12),
            // Title
            Text(title,
                style: const TextStyle(
                    color: Colors.white, fontSize: 16,
                    fontWeight: FontWeight.bold, height: 1.35),
                maxLines: 3, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 10),
            // Footer
            Row(children: [
              Icon(Icons.source_outlined, color: accent.withValues(alpha: 0.7), size: 13),
              const SizedBox(width: 4),
              Text(source,
                  style: TextStyle(color: accent.withValues(alpha: 0.8), fontSize: 12)),
              const Spacer(),
              // Tags
              ...tags.take(2).map((t) => Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(t.toString(),
                    style: const TextStyle(color: Colors.white38, fontSize: 10)),
              )),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.arrow_forward_rounded, color: accent, size: 14),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final d = DateTime.parse(raw);
      final diff = DateTime.now().difference(d);
      if (diff.inDays > 7)  return '${d.day}.${d.month}.${d.year}';
      if (diff.inDays > 0)  return 'vor ${diff.inDays}T';
      if (diff.inHours > 0) return 'vor ${diff.inHours}h';
      return 'jetzt';
    } catch (_) { return ''; }
  }
}

// Normal article card (compact)
class _ArticleCard extends StatelessWidget {
  final Map<String, dynamic> article;
  final VoidCallback onTap;
  final Color accent;
  const _ArticleCard({required this.article, required this.onTap, required this.accent});

  @override
  Widget build(BuildContext context) {
    final title  = (article['title']  ?? 'Artikel').toString();
    final source = (article['source'] ?? article['realm'] ?? 'Materie').toString();
    final date   = (article['created_at'] ?? article['publishedAt'] ?? '').toString();
    final type   = (article['type'] ?? 'article').toString();
    final icon   = type == 'video' ? Icons.play_circle_outline
                 : type == 'podcast' ? Icons.mic_outlined
                 : Icons.article_outlined;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: const Color(0xFF0A1020),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withValues(alpha: 0.18)),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 13,
                      fontWeight: FontWeight.w600, height: 1.3),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(children: [
                Text(source,
                    style: TextStyle(color: accent.withValues(alpha: 0.7), fontSize: 11)),
                if (date.isNotEmpty) ...[
                  const Text(' · ', style: TextStyle(color: Colors.white24, fontSize: 11)),
                  Text(_formatDate(date),
                      style: const TextStyle(color: Colors.white38, fontSize: 11)),
                ],
              ]),
            ]),
          ),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 13),
        ]),
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final d = DateTime.parse(raw);
      final diff = DateTime.now().difference(d);
      if (diff.inDays > 7)  return '${d.day}.${d.month}.${d.year}';
      if (diff.inDays > 0)  return 'vor ${diff.inDays}T';
      if (diff.inHours > 0) return 'vor ${diff.inHours}h';
      return 'jetzt';
    } catch (_) { return ''; }
  }
}
