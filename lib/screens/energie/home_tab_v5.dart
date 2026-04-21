import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/openclaw_dashboard_service.dart';
import '../../services/storage_service.dart';
import '../../models/energie_profile.dart';
import 'package:url_launcher/url_launcher.dart';
import '../materie/recherche_tab_mobile.dart';
import 'energie_live_chat_screen.dart';
import '../../services/chat/recent_rooms_service.dart';
import '../shared/bookmarks_screen.dart';
import '../shared/stats_dashboard_screen.dart';
import '../shared/notification_center_screen.dart';
import 'spirit_tab_modern.dart';
import 'calculators/chakra_calculator_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════
// ENERGIE HOME DASHBOARD V7 – REDESIGN 2026
// "Mystical Cosmos" · Amethyst-Purple · Aura FX · Spiritual Panels
// ═══════════════════════════════════════════════════════════════════════════

class EnergieHomeTabV5 extends StatefulWidget {
  /// Callback zum Umschalten der Bottom-Tab-Navigation des Parents.
  /// Wenn gesetzt: Home-Buttons wie "Spirit" schalten den Tab um,
  /// statt einen neuen Screen zu pushen → identische Darstellung
  /// wie beim direkten Tab-Klick.
  final ValueChanged<int>? onSwitchTab;

  const EnergieHomeTabV5({super.key, this.onSwitchTab});

  @override
  State<EnergieHomeTabV5> createState() => _EnergieHomeTabV5State();
}

class _EnergieHomeTabV5State extends State<EnergieHomeTabV5>
    with TickerProviderStateMixin {

  // ── Animations ─────────────────────────────────────────────────────────
  late AnimationController _auraCtrl;
  late AnimationController _entryCtrl;
  late AnimationController _orbitCtrl;
  late Animation<double> _entryAnim;

  // ── Services ───────────────────────────────────────────────────────────
  final _dash = OpenClawDashboardService();

  // ── State ──────────────────────────────────────────────────────────────
  EnergieProfile? _profile;
  bool _loading = true;
  int _articles = 0, _sessions = 0, _bookmarks = 0, _shares = 0;
  List<Map<String, dynamic>> _latestArticles = [];
  List<Map<String, dynamic>> _trending = [];
  int _notifs = 0;
  final _scrollCtrl = ScrollController();
  double _scrollOffset = 0;
  Timer? _liveTimer;
  RealtimeChannel? _channel;
  RealtimeChannel? _notifChannel;
  RealtimeChannel? _statsChannel;

  // ── Colors ─────────────────────────────────────────────────────────────
  static const _bg      = Color(0xFF06040F);
  static const _card    = Color(0xFF100B1E);
  static const _cardB   = Color(0xFF150E25);
  static const _purple  = Color(0xFFAB47BC);
  static const _purpleD = Color(0xFF4A148C);
  static const _purpleL = Color(0xFFCE93D8);
  static const _gold    = Color(0xFFFFD54F);
  static const _teal    = Color(0xFF26C6DA);
  static const _pink    = Color(0xFFEC407A);
  static const _green   = Color(0xFF66BB6A);
  static const _indigo  = Color(0xFF5C6BC0);

  @override
  void initState() {
    super.initState();
    _auraCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 3))..repeat(reverse: true);
    _entryCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1000));
    _orbitCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 12))..repeat();
    _entryAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic);
    _entryCtrl.forward();
    _scrollCtrl.addListener(() {
      setState(() => _scrollOffset = _scrollCtrl.offset);
    });
    _loadAll();
    _startLive();
  }

  @override
  void dispose() {
    _auraCtrl.dispose();
    _entryCtrl.dispose();
    _orbitCtrl.dispose();
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
    _profile = StorageService().getEnergieProfile();
  }

  Future<void> _loadStats() async {
    try {
      final s = await _dash.getStatistics(realm: 'energie');
      if (mounted) {
        setState(() {
          _articles  = s['totalArticles']    ?? s['total_articles']    ?? 0;
          _sessions  = s['researchSessions'] ?? s['research_sessions'] ?? 0;
          _bookmarks = s['bookmarkedTopics'] ?? s['bookmarked_topics'] ?? 0;
          _shares    = s['sharedFindings']   ?? s['shared_findings']   ?? 0;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadContent() async {
    try {
      _latestArticles = await _dash.getRecentArticles(realm: 'energie', limit: 6);
      _trending       = await _dash.getTrendingTopics(realm: 'energie', limit: 8);
      final uid  = Supabase.instance.client.auth.currentUser?.id ??
                   await StorageService().getUserId('energie');
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

    // Realtime: Artikel → Content + Stats neu laden
    _channel = client
        .channel('energie_home_content')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public', table: 'articles',
        callback: (_) { if (mounted) { _loadContent(); _loadStats(); } },
      )
      ..subscribe();

    // Realtime: chat_messages + bookmarks + likes → Stats neu laden
    _statsChannel = client
        .channel('energie_home_stats')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public', table: 'chat_messages',
        callback: (_) { if (mounted) _loadStats(); },
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public', table: 'bookmarks',
        callback: (_) { if (mounted) _loadStats(); },
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public', table: 'likes',
        callback: (_) { if (mounted) _loadStats(); },
      )
      ..subscribe();

    // Realtime: notifications → Glocken-Badge sofort aktualisieren
    final uid = client.auth.currentUser?.id;
    if (uid != null) {
      _notifChannel = client
          .channel('energie_home_notifs')
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
          callback: (_) { if (mounted) _refreshNotifCount(); },
        )
        ..subscribe();
    }

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

  // ── Navigation ─────────────────────────────────────────────────────────
  Future<void> _go(Widget screen) => Navigator.push<void>(
      context, MaterialPageRoute(builder: (_) => screen));

  /// Zum Spirit-Tab wechseln: bevorzugt via Parent-Tab-Switch
  /// (identisches Look & State wie Bottom-Nav-Klick); fällt auf
  /// Navigator.push zurück, wenn kein Callback vorhanden ist.
  void _openSpiritTab() {
    final cb = widget.onSwitchTab;
    if (cb != null) {
      cb(1); // Spirit = Tab-Index 1 in EnergieWorldScreen
    } else {
      _go(const SpiritTabModern());
    }
  }

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
    if (h < 5)  return '🌙 Stille Stunden';
    if (h < 12) return '☀️ Guten Morgen';
    if (h < 17) return '🌤 Guten Tag';
    if (h < 21) return '🌅 Guten Abend';
    return '🌙 Gute Nacht';
  }

  String get _moonPhase {
    final now = DateTime.now();
    final daysSinceNew = now.difference(DateTime(2000, 1, 6)).inDays % 29;
    if (daysSinceNew < 4)  return '🌑 Neumond';
    if (daysSinceNew < 8)  return '🌒 Zunehmend';
    if (daysSinceNew < 11) return '🌓 Halbmond';
    if (daysSinceNew < 15) return '🌔 Fast Voll';
    if (daysSinceNew < 19) return '🌕 Vollmond';
    if (daysSinceNew < 22) return '🌖 Abnehmend';
    if (daysSinceNew < 26) return '🌗 Halbmond';
    return '🌘 Alt';
  }

  String get _moonEmoji => _moonPhase.split(' ').first;
  String get _moonName {
    final parts = _moonPhase.split(' ');
    return parts.length > 1 ? parts.skip(1).join(' ') : _moonPhase;
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
          color: _purple,
          backgroundColor: _cardB,
          displacement: 60,
          child: CustomScrollView(
            controller: _scrollCtrl,
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              _buildHeroHeader(),
              _buildMysticBanner(),
              _buildLiveStatBanner(),
              _buildActionGrid(),
              _buildRecentRooms(),
              _buildSectionTitle('✨ Spirituelle Themen', subtitle: 'Im Fokus'),
              _buildTrendingChips(),
              _buildSectionTitle('📿 Neueste Artikel', subtitle: 'Wissen & Weisheit'),
              _buildArticleCards(),
              _buildExploreSection(),
              const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
            ],
          ),
        ),
      ),
    );
  }

  // ── HERO HEADER ────────────────────────────────────────────────────────
  Widget _buildHeroHeader() {
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _entryAnim,
        child: SizedBox(
          height: 220,
          child: Stack(
            children: [
              // Aura background
              AnimatedBuilder(
                animation: _orbitCtrl,
                builder: (_, __) => CustomPaint(
                  painter: _AuraPainter(
                    orbitProgress: _orbitCtrl.value,
                    auraProgress: _auraCtrl.value,
                    scrollOffset: _scrollOffset,
                    color: _purple,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
              // Fade to bg
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, _bg],
                    stops: const [0.45, 1.0],
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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildAuraOrb(),
                          const SizedBox(width: 14),
                          Expanded(child: _buildGreetingText()),
                          _buildNotifBell(),
                        ],
                      ),
                      const SizedBox(height: 16),
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

  Widget _buildAuraOrb() {
    return AnimatedBuilder(
      animation: _auraCtrl,
      builder: (_, __) => GestureDetector(
        onTap: () => _go(const StatsDashboardScreen(world: 'energie')),
        child: Container(
          width: 54, height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                _purple.withValues(alpha: 0.45 + _auraCtrl.value * 0.2),
                _purpleD.withValues(alpha: 0.1),
              ],
            ),
            border: Border.all(
                color: _purpleL.withValues(alpha: 0.4 + _auraCtrl.value * 0.3),
                width: 1.5),
            boxShadow: [
              BoxShadow(
                color: _purple.withValues(alpha: 0.25 + _auraCtrl.value * 0.2),
                blurRadius: 18,
                spreadRadius: 3,
              ),
            ],
          ),
          child: Center(
            child: Text(
              _profile?.avatarEmoji ?? '✨',
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingText() {
    final name = (_profile?.firstName.isNotEmpty == true)
        ? _profile!.firstName
        : _profile?.username ?? 'Suchende/r';
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
              name,
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
        Row(children: [
          AnimatedBuilder(
            animation: _auraCtrl,
            builder: (_, __) => Container(
              width: 6, height: 6,
              decoration: BoxDecoration(
                color: _purple.withValues(alpha: 0.5 + _auraCtrl.value * 0.5),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: _purple.withValues(alpha: 0.5), blurRadius: 4)],
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Text('Welt der ENERGIE',
              style: TextStyle(color: Colors.white38, fontSize: 11)),
        ]),
      ],
    );
  }

  Widget _buildNotifBell() {
    return GestureDetector(
      onTap: () async {
        await _go(const NotificationCenterScreen(world: 'energie'));
        _refreshNotifCount();
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Icon(
              _notifs > 0 ? Icons.notifications : Icons.notifications_outlined,
              color: _notifs > 0 ? _gold : Colors.white60,
              size: 22,
            ),
          ),
          if (_notifs > 0)
            Positioned(
              right: -4, top: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: _pink, shape: BoxShape.circle),
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
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
          boxShadow: [
            BoxShadow(color: _purple.withValues(alpha: 0.08), blurRadius: 12),
          ],
        ),
        child: Row(children: [
          Icon(Icons.search_rounded, color: _purpleL.withValues(alpha: 0.7), size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Spirituelle Themen suchen…',
                style: TextStyle(color: Colors.white30, fontSize: 14)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _purple.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _purple.withValues(alpha: 0.3)),
            ),
            child: const Text('Suche',
                style: TextStyle(color: _purpleL, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    );
  }

  // ── MYSTIC BANNER (Moon / Spirit Portal) ───────────────────────────────
  Widget _buildMysticBanner() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: GestureDetector(
          onTap: _openSpiritTab,
          child: AnimatedBuilder(
            animation: _auraCtrl,
            builder: (_, __) => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _purpleD.withValues(alpha: 0.8),
                    _purple.withValues(alpha: 0.3 + _auraCtrl.value * 0.1),
                    _gold.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: _purpleL.withValues(alpha: 0.2 + _auraCtrl.value * 0.1)),
                boxShadow: [
                  BoxShadow(
                    color: _purple.withValues(alpha: 0.12 + _auraCtrl.value * 0.08),
                    blurRadius: 20, offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(children: [
                // Animated moon
                AnimatedBuilder(
                  animation: _orbitCtrl,
                  builder: (_, __) => Transform.rotate(
                    angle: _orbitCtrl.value * math.pi * 2 * 0.1,
                    child: Text(
                      _moonEmoji,
                      style: TextStyle(
                          fontSize: 36 + _auraCtrl.value * 4),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Spirituelles Zentrum',
                          style: TextStyle(color: Colors.white, fontSize: 15,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 3),
                      Row(children: [
                        Text(_moonName,
                            style: TextStyle(color: _purpleL.withValues(alpha: 0.8),
                                fontSize: 12, fontWeight: FontWeight.w500)),
                        const Text('  ·  ',
                            style: TextStyle(color: Colors.white24, fontSize: 12)),
                        const Text('Chakras · Spirit',
                            style: TextStyle(color: Colors.white38, fontSize: 11)),
                      ]),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF6A1B9A), Color(0xFFAB47BC)]),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: _purple.withValues(alpha: 0.3), blurRadius: 10),
                    ],
                  ),
                  child: const Text('Öffnen',
                      style: TextStyle(color: Colors.white, fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  // ── LIVE STAT BANNER ───────────────────────────────────────────────────
  Widget _buildLiveStatBanner() {
    final stats = [
      _StatDef(icon: Icons.auto_stories,      label: 'Artikel',   value: _articles,  color: _purple),
      _StatDef(icon: Icons.self_improvement,  label: 'Sessions',  value: _sessions,  color: _teal),
      _StatDef(icon: Icons.bookmark_border,   label: 'Gespeich.', value: _bookmarks, color: _gold),
      _StatDef(icon: Icons.share_outlined,    label: 'Geteilt',   value: _shares,    color: _green),
    ];

    return SliverToBoxAdapter(
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
            .animate(_entryAnim),
        child: FadeTransition(
          opacity: _entryAnim,
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: _cardB,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: stats.asMap().entries.map((e) {
                final i = e.key;
                final s = e.value;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (s.label == 'Gespeich.') {
                        _go(const BookmarksScreen());
                      } else {
                        _go(const StatsDashboardScreen(world: 'energie'));
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: i < stats.length - 1
                          ? BoxDecoration(
                              border: Border(
                                right: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
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
                                  style: TextStyle(color: s.color, fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                          const SizedBox(height: 1),
                          Text(s.label,
                              style: const TextStyle(color: Colors.white38, fontSize: 9,
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

  // ── ACTION GRID ─────────────────────────────────────────────────────────
  Widget _buildActionGrid() {
    final tiles = [
      _TileDef(
        icon: Icons.self_improvement_rounded,
        label: 'Spirit',
        sub: 'Seele & Bewusstsein',
        gradient: [const Color(0xFF3E0D6B), const Color(0xFF6A1B9A), const Color(0xFFAB47BC)],
        badge: 0,
        onTap: _openSpiritTab,
      ),
      _TileDef(
        icon: Icons.forum_rounded,
        label: 'Live Chat',
        sub: 'Spiritueller Austausch',
        gradient: [const Color(0xFF004D40), const Color(0xFF00796B), const Color(0xFF26C6DA)],
        badge: _notifs,
        onTap: () => _go(const EnergieLiveChatScreen()),
      ),
      _TileDef(
        icon: Icons.spa_rounded,
        label: 'Chakras',
        sub: 'Energie & Balance',
        gradient: [const Color(0xFF880E4F), const Color(0xFFC2185B), const Color(0xFFEC407A)],
        badge: 0,
        onTap: () => _go(const ChakraCalculatorScreen()),
      ),
      _TileDef(
        icon: Icons.collections_bookmark_rounded,
        label: 'Gespeichert',
        sub: 'Deine Weisheiten',
        gradient: [const Color(0xFF4A3B00), const Color(0xFF827717), const Color(0xFFFFD54F)],
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
                  color: t.gradient.last.withValues(alpha: 0.25),
                  blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                // Decorative circles
                Positioned(
                  right: -16, bottom: -16,
                  child: Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.06),
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
                          style: const TextStyle(color: Colors.white, fontSize: 13,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 1),
                      Text(t.sub,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7),
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
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold,
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
                  style: const TextStyle(color: Colors.white, fontSize: 17,
                      fontWeight: FontWeight.bold)),
              if (subtitle.isNotEmpty)
                Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ]),
          ),
          GestureDetector(
            onTap: () => _go(const MobileOptimierterRechercheTab()),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _purple.withValues(alpha: 0.3)),
              ),
              child: const Text('Alle →',
                  style: TextStyle(color: _purpleL, fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }

  // ── RECENT ROOMS ───────────────────────────────────────────────────────
  static const Map<String, (String, String)> _recentRoomMeta = {
    'meditation': ('🧘', 'Meditation'),
    'astralreisen': ('🌌', 'Astralreisen'),
    'chakren': ('🔥', 'Chakren'),
    'spiritualitaet': ('🔮', 'Spiritualität'),
    'heilung': ('💫', 'Heilung'),
    'tarot': ('🃏', 'Tarot'),
    'astrologie': ('🌠', 'Astrologie'),
  };

  Widget _buildRecentRooms() {
    return SliverToBoxAdapter(
      child: FutureBuilder<List<String>>(
        future: RecentRoomsService.instance.get('energie'),
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
                                EnergieLiveChatScreen(initialRoom: id),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: _purple.withValues(alpha: 0.4),
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
        : ['Meditation', 'Chakra', 'Mondkraft', 'Astrologie', 'Traumdeutung', 'Heilung', 'Bewusstsein'];
    final chipColors = [_purple, _teal, _pink, _gold, _green, _indigo, _purpleL];

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
              onTap: _openSpiritTab,
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
          onTap: _openSpiritTab,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _purple.withValues(alpha: 0.15)),
            ),
            child: Column(children: [
              Icon(Icons.auto_stories, color: _purpleL.withValues(alpha: 0.4), size: 44),
              const SizedBox(height: 14),
              const Text('Spirit-Inhalte entdecken',
                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 6),
              const Text('Zum Spirit-Bereich →',
                  style: TextStyle(color: _purpleL, fontSize: 13, fontWeight: FontWeight.w500)),
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
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: _FeaturedArticleCard(
                article: a,
                onTap: () => _goArticle(a),
                accent: _purple,
              ),
            );
          }
          return Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16,
                i == _latestArticles.length - 1 ? 0 : 10),
            child: _ArticleCard(article: a, onTap: () => _goArticle(a), accent: _purple),
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
          onTap: () => _go(const StatsDashboardScreen(world: 'energie')),
          child: AnimatedBuilder(
            animation: _auraCtrl,
            builder: (_, __) => Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _purpleD.withValues(alpha: 0.7),
                    _purple.withValues(alpha: 0.3 + _auraCtrl.value * 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                    color: _purple.withValues(alpha: 0.25 + _auraCtrl.value * 0.1)),
                boxShadow: [
                  BoxShadow(
                      color: _purple.withValues(alpha: 0.15 + _auraCtrl.value * 0.08),
                      blurRadius: 24, offset: const Offset(0, 8)),
                ],
              ),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Statistiken & Insights',
                        style: TextStyle(color: Colors.white, fontSize: 15,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Deine spirituelle Reise',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
                  ]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
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
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// AURA PAINTER
// ═══════════════════════════════════════════════════════════════════════════
class _AuraPainter extends CustomPainter {
  final double orbitProgress;
  final double auraProgress;
  final double scrollOffset;
  final Color color;

  _AuraPainter({
    required this.orbitProgress,
    required this.auraProgress,
    required this.scrollOffset,
    required this.color,
  });

  static final List<Offset> _stars = List.generate(35, (i) {
    final rng = math.Random(i * 11 + 7);
    return Offset(rng.nextDouble(), rng.nextDouble());
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: const [Color(0xFF08040F), Color(0xFF0D061A), Color(0xFF080410)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Aura glow
    final glow1 = Paint()
      ..color = color.withValues(alpha: 0.06 + math.sin(auraProgress * math.pi) * 0.04)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 70);
    canvas.drawCircle(Offset(size.width * 0.4, size.height * 0.3), size.width * 0.55, glow1);

    final glow2 = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.03 + auraProgress * 0.02)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);
    canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.6), size.width * 0.3, glow2);

    // Orbiting particles
    final particlePaint = Paint()..color = color.withValues(alpha: 0.25);
    for (int p = 0; p < 3; p++) {
      final angle = orbitProgress * math.pi * 2 + p * (math.pi * 2 / 3);
      final radius = 30.0 + p * 15;
      final cx = size.width * 0.75 + math.cos(angle) * radius;
      final cy = size.height * 0.25 + math.sin(angle) * radius * 0.6;
      canvas.drawCircle(Offset(cx, cy - scrollOffset * 0.1), 2.0 + p * 0.5, particlePaint);
    }

    // Stars
    final starPaint = Paint();
    for (var i = 0; i < _stars.length; i++) {
      final s = _stars[i];
      final twinkle = math.sin(auraProgress * math.pi * 2 + i * 0.9);
      final alpha = (0.15 + twinkle * 0.12).clamp(0.03, 0.35);
      starPaint.color = Colors.white.withValues(alpha: alpha);
      canvas.drawCircle(
        Offset(s.dx * size.width, s.dy * size.height - scrollOffset * 0.12),
        1.0 + (i % 3) * 0.4, starPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_AuraPainter old) =>
      old.orbitProgress != orbitProgress ||
      old.auraProgress != auraProgress ||
      old.scrollOffset != scrollOffset;
}

// ═══════════════════════════════════════════════════════════════════════════
// SHARED WIDGETS
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
          : [const Color(0xFF9C27B0), const Color(0xFF6A1B9A)]),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      isRoot ? '👑 ROOT' : '✨ ADM',
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

// Featured card (large)
class _FeaturedArticleCard extends StatelessWidget {
  final Map<String, dynamic> article;
  final VoidCallback onTap;
  final Color accent;
  const _FeaturedArticleCard({required this.article, required this.onTap, required this.accent});

  @override
  Widget build(BuildContext context) {
    final title  = (article['title']  ?? 'Artikel').toString();
    final source = (article['source'] ?? article['realm'] ?? 'Energie').toString();
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
            colors: [const Color(0xFF1A0830), accent.withValues(alpha: 0.12)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(color: accent.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 6)),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accent.withValues(alpha: 0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 6, height: 6,
                    decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Text('TOP ARTIKEL',
                    style: TextStyle(color: accent, fontSize: 9,
                        fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ]),
            ),
            const Spacer(),
            if (date.isNotEmpty)
              Text(_fmtDate(date),
                  style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ]),
          const SizedBox(height: 12),
          Text(title,
              style: const TextStyle(color: Colors.white, fontSize: 16,
                  fontWeight: FontWeight.bold, height: 1.35),
              maxLines: 3, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          Row(children: [
            Icon(Icons.source_outlined, color: accent.withValues(alpha: 0.7), size: 13),
            const SizedBox(width: 4),
            Text(source, style: TextStyle(color: accent.withValues(alpha: 0.8), fontSize: 12)),
            const Spacer(),
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
        ]),
      ),
    );
  }

  String _fmtDate(String raw) {
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

// Normal article card
class _ArticleCard extends StatelessWidget {
  final Map<String, dynamic> article;
  final VoidCallback onTap;
  final Color accent;
  const _ArticleCard({required this.article, required this.onTap, required this.accent});

  @override
  Widget build(BuildContext context) {
    final title  = (article['title']  ?? 'Artikel').toString();
    final source = (article['source'] ?? article['realm'] ?? 'Energie').toString();
    final date   = (article['created_at'] ?? article['publishedAt'] ?? '').toString();
    final type   = (article['type'] ?? 'article').toString();
    final icon   = type == 'video' ? Icons.play_circle_outline
                 : type == 'meditation' ? Icons.self_improvement
                 : Icons.auto_stories;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: const Color(0xFF0E0A1A),
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
                  style: const TextStyle(color: Colors.white, fontSize: 13,
                      fontWeight: FontWeight.w600, height: 1.3),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(children: [
                Text(source,
                    style: TextStyle(color: accent.withValues(alpha: 0.7), fontSize: 11)),
                if (date.isNotEmpty) ...[
                  const Text(' · ', style: TextStyle(color: Colors.white24, fontSize: 11)),
                  Text(_fmtDate(date),
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

  String _fmtDate(String raw) {
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
