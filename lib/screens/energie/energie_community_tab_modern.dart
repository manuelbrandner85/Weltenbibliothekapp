import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/storage_service.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import '../../models/community_post.dart';
import '../../services/community_service.dart'; // ✅ Cloudflare API
// 🔐 PROFIL-DATEN
import '../../widgets/create_post_dialog_v2.dart'; // ✅ Post-Dialog
import '../../widgets/post_actions_row.dart'; // ✅ POST ACTIONS
import '../../widgets/loading_skeletons.dart'; // 💀 LOADING SKELETONS
import 'energie_live_chat_screen.dart'; // 💬 LIVE-CHAT INTEGRATION
import '../../services/chat_notification_service.dart'; // 🔔 NOTIFICATION SERVICE

/// Moderner Energie-Community-Tab - Spiritueller Feed-Style
class EnergieCommunityTabModern extends StatefulWidget {
  const EnergieCommunityTabModern({super.key});

  @override
  State<EnergieCommunityTabModern> createState() => _EnergieCommunityTabModernState();
}

// ── Design palette (mirrors Energie Home Dashboard V7) ───────────────────
const _kBg      = Color(0xFF06040F);
const _kCard    = Color(0xFF100B1E);
const _kCardB   = Color(0xFF150E25);
const _kPurple  = Color(0xFFAB47BC);
const _kPurpleD = Color(0xFF4A148C);
const _kPurpleL = Color(0xFFCE93D8);
const _kGold    = Color(0xFFFFD54F);
const _kTeal    = Color(0xFF26C6DA);
const _kPink    = Color(0xFFEC407A);
const _kGreen   = Color(0xFF66BB6A);

class _EnergieCommunityTabModernState extends State<EnergieCommunityTabModern> with TickerProviderStateMixin {
  bool _isLoading = true;
  String _selectedView = 'alle'; // 'alle', 'trending', 'fotos', 'diskussion', 'gespeichert'

  // Bookmarks (Feature 9) — persisted in SharedPreferences
  Set<String> _bookmarkedIds = {};
  // Reactions (Feature 2) — emoji → set of reaction-usernames (in-memory)
  final Map<String, Map<String, int>> _reactions = {};

  // 💬 TAB CONTROLLER für Posts vs Chat
  late TabController _tabController;
  final ChatNotificationService _notificationService = ChatNotificationService();
  final CommunityService _communityService = CommunityService();

  // ── Hero-header animations (mirror home dashboard) ────────────────────
  late AnimationController _auraCtrl;
  late AnimationController _entryCtrl;
  late AnimationController _orbitCtrl;
  late Animation<double> _entryAnim;
  final ScrollController _scrollCtrl = ScrollController();
  double _scrollOffset = 0;

  // ✅ Echte Posts von Cloudflare API
  List<CommunityPost> _posts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _auraCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 3))..repeat(reverse: true);
    _entryCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 900));
    _orbitCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 12))..repeat();
    _entryAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic);
    _entryCtrl.forward();
    _scrollCtrl.addListener(() {
      if (mounted) setState(() => _scrollOffset = _scrollCtrl.offset);
    });
    _loadBookmarks();
    _loadData();
  }

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('energie_bookmarks') ?? [];
    if (mounted) setState(() => _bookmarkedIds = saved.toSet());
  }

  Future<void> _toggleBookmark(String postId) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_bookmarkedIds.contains(postId)) {
        _bookmarkedIds.remove(postId);
      } else {
        _bookmarkedIds.add(postId);
        HapticFeedback.lightImpact();
      }
    });
    await prefs.setStringList('energie_bookmarks', _bookmarkedIds.toList());
  }

  void _toggleReaction(String postId, String emoji) {
    HapticFeedback.selectionClick();
    setState(() {
      _reactions[postId] ??= {};
      _reactions[postId]![emoji] = (_reactions[postId]![emoji] ?? 0) + 1;
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final posts = await _communityService.fetchPosts(
        worldType: WorldType.energie,
      );
      if (kDebugMode) {
        debugPrint('🟣 ENERGIE: Geladene Posts: ${posts.length}');
      }
      if (mounted) {
        setState(() {
          _posts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🟣 ENERGIE: Fehler beim Laden: $e');
      }
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_friendlyErrorMessage(e))),
        );
      }
    }
  }

  /// Mappt technische Exceptions auf nutzerfreundliche deutsche Texte.
  String _friendlyErrorMessage(Object e) {
    final s = e.toString();
    if (s.contains('SocketException') ||
        s.contains('Failed host lookup') ||
        s.contains('Network is unreachable')) {
      return '📡 Keine Internet-Verbindung — bitte WLAN/Mobilfunk prüfen.';
    }
    if (s.contains('TimeoutException') || s.contains('timed out')) {
      return '⏱️ Server reagiert nicht — bitte später erneut versuchen.';
    }
    if (s.contains('401') || s.contains('Unauthorized')) {
      return '🔒 Nicht angemeldet — bitte App neu starten und einloggen.';
    }
    if (s.contains('403') || s.contains('Forbidden')) {
      return '🚫 Keine Berechtigung für diese Aktion.';
    }
    if (s.contains('404') || s.contains('Not Found')) {
      return '🔍 Inhalt nicht gefunden.';
    }
    if (s.contains('500') ||
        s.contains('502') ||
        s.contains('503') ||
        s.contains('Internal Server')) {
      return '🛠️ Server überlastet — bitte gleich nochmal versuchen.';
    }
    return '⚠️ Beiträge konnten nicht geladen werden. Bitte erneut versuchen.';
  }
  
  // Feature 6 — Inline Bottom-Sheet statt Dialog
  Future<void> _showCreatePostDialog() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.6,
        maxChildSize: 0.97,
        expand: false,
        builder: (_, controller) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: CreatePostDialogV2(worldType: WorldType.energie),
        ),
      ),
    );
    if (result == true) _loadData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _auraCtrl.dispose();
    _entryCtrl.dispose();
    _orbitCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Widget _buildPillSwitcher() {
    final isChat = _tabController.index == 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Stack(
          children: [
            // Sliding pill
            AnimatedAlign(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              alignment: isChat ? Alignment.centerRight : Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                child: Container(
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: _kPurple.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: _kPurple.withValues(alpha: 0.55)),
                    boxShadow: [
                      BoxShadow(
                        color: _kPurple.withValues(alpha: 0.18),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _tabController.animateTo(0);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.article_rounded, size: 15,
                            color: !isChat ? Colors.white : Colors.white38),
                        const SizedBox(width: 6),
                        Text('Beiträge',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: !isChat ? FontWeight.w700 : FontWeight.w400,
                              color: !isChat ? Colors.white : Colors.white38,
                              letterSpacing: 0.2,
                            )),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _tabController.animateTo(1);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_rounded, size: 15,
                            color: isChat ? Colors.white : Colors.white38),
                        const SizedBox(width: 6),
                        Text('Live-Chat',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isChat ? FontWeight.w700 : FontWeight.w400,
                              color: isChat ? Colors.white : Colors.white38,
                              letterSpacing: 0.2,
                            )),
                        ListenableBuilder(
                          listenable: _notificationService,
                          builder: (context, _) {
                            final count = _notificationService.getTotalUnreadCount();
                            if (count == 0) return const SizedBox.shrink();
                            return Container(
                              margin: const EdgeInsets.only(left: 5),
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [BoxShadow(color: Colors.red.withValues(alpha: 0.5), blurRadius: 4)],
                              ),
                              child: Text(count > 9 ? '9+' : '$count',
                                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContextSubtitle() {
    final isChat = _tabController.index == 1;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: Padding(
        key: ValueKey(isChat),
        padding: const EdgeInsets.only(left: 20, top: 6, bottom: 4),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            isChat ? 'Echtzeit-Gespräche · Raum wählen' : '${_posts.length} Beiträge in der Community',
            style: const TextStyle(fontSize: 11, color: Colors.white38, letterSpacing: 0.1),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
        _buildPillSwitcher(),
        _buildContextSubtitle(),
        // TAB VIEW: Posts oder Chat
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPostsView(),
              const EnergieLiveChatScreen(),
            ],
          ),
        ),
      ],
    ),
      // ✅ Post-Button NUR im Posts-Tab anzeigen (nicht im Chat)
      floatingActionButton: _tabController.index == 0
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9C27B0).withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                onPressed: _showCreatePostDialog,
                backgroundColor: Colors.transparent,
                elevation: 0,
                icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                label: const Text(
                  'Post erstellen',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            )
          : null, // Kein Button im Chat-Tab
    );
  }
  
  List<CommunityPost> get _filteredPosts {
    switch (_selectedView) {
      case 'fotos':
        return _posts.where((p) => p.mediaUrl != null && p.mediaUrl!.isNotEmpty).toList();
      case 'trending':
        final sorted = List<CommunityPost>.from(_posts)..sort((a, b) => b.likes.compareTo(a.likes));
        return sorted;
      case 'diskussion':
        final sorted = List<CommunityPost>.from(_posts)..sort((a, b) => b.comments.compareTo(a.comments));
        return sorted;
      case 'gespeichert':
        return _posts.where((p) => _bookmarkedIds.contains(p.id)).toList();
      default:
        return _posts;
    }
  }

  Widget _buildPostsView() {
    final filtered = _filteredPosts;
    final hero = _posts.isNotEmpty
        ? (List<CommunityPost>.from(_posts)..sort((a, b) => b.likes.compareTo(a.likes))).first
        : null;

    return Container(
      color: _kBg,
      child: RefreshIndicator(
        color: _kPurple,
        backgroundColor: Colors.black87,
        onRefresh: _loadData,
        child: CustomScrollView(
          controller: _scrollCtrl,
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            _buildHeroHeader(),
            SliverToBoxAdapter(child: _buildFilterRow()),
            // Feature 7 — Live-Counter
            SliverToBoxAdapter(child: _buildLiveCounter()),
            SliverToBoxAdapter(child: _buildStatBanner()),
            // Feature 5 — Story-Bubbles
            if (_posts.isNotEmpty) SliverToBoxAdapter(child: _buildStoryBubbles()),

            if (_selectedView == 'trending')
              SliverToBoxAdapter(child: _buildTrendingSection()),

            // Feature 4 — Hero-Post
            if (hero != null && _selectedView == 'alle')
              SliverToBoxAdapter(child: _buildHeroPost(hero)),

            SliverToBoxAdapter(
              child: _buildSectionTitle('✨ Neueste Beiträge', subtitle: 'Spiritueller Austausch'),
            ),

            _isLoading
                ? SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, __) => LoadingSkeletons.postCard(),
                        childCount: 3,
                      ),
                    ),
                  )
                : filtered.isEmpty
                    ? SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.forum_outlined, size: 64, color: Colors.white.withValues(alpha: 0.3)),
                              const SizedBox(height: 16),
                              Text('Keine Beiträge',
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 16)),
                              const SizedBox(height: 8),
                              Text('Sei der Erste und erstelle einen Post!',
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14)),
                            ],
                          ),
                        ),
                      )
                    // Feature 1 — Masonry-Grid (2 Spalten)
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                        sliver: SliverToBoxAdapter(child: _buildMasonryGrid(filtered)),
                      ),
          ],
        ),
      ),
    );
  }

  // Animated hero header — mirrors home dashboard `_buildHeroHeader`
  Widget _buildHeroHeader() {
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _entryAnim,
        child: SizedBox(
          height: 180,
          child: Stack(
            children: [
              AnimatedBuilder(
                animation: Listenable.merge([_orbitCtrl, _auraCtrl]),
                builder: (_, __) => CustomPaint(
                  painter: _CommunityAuraPainter(
                    orbitProgress: _orbitCtrl.value,
                    auraProgress: _auraCtrl.value,
                    scrollOffset: _scrollOffset,
                    color: _kPurple,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, _kBg],
                    stops: const [0.45, 1.0],
                  ),
                ),
              ),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _auraCtrl,
                        builder: (_, __) => Container(
                          width: 54, height: 54,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                _kPurple.withValues(alpha: 0.45 + _auraCtrl.value * 0.2),
                                _kPurpleD.withValues(alpha: 0.1),
                              ],
                            ),
                            border: Border.all(
                                color: _kPurpleL.withValues(alpha: 0.4 + _auraCtrl.value * 0.3),
                                width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: _kPurple.withValues(alpha: 0.25 + _auraCtrl.value * 0.2),
                                blurRadius: 18, spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text('🌟', style: TextStyle(fontSize: 24)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('✨ Spirituelle Community',
                                style: TextStyle(color: Colors.white54, fontSize: 12,
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(height: 2),
                            const Text('Community',
                                style: TextStyle(color: Colors.white, fontSize: 20,
                                    fontWeight: FontWeight.bold, letterSpacing: -0.3),
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 3),
                            Row(children: [
                              AnimatedBuilder(
                                animation: _auraCtrl,
                                builder: (_, __) => Container(
                                  width: 6, height: 6,
                                  decoration: BoxDecoration(
                                    color: _kPurple.withValues(alpha: 0.5 + _auraCtrl.value * 0.5),
                                    shape: BoxShape.circle,
                                    boxShadow: [BoxShadow(color: _kPurple.withValues(alpha: 0.5), blurRadius: 4)],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text('${_posts.length} Beiträge · Welt der ENERGIE',
                                  style: const TextStyle(color: Colors.white38, fontSize: 11)),
                            ]),
                          ],
                        ),
                      ),
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

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _buildViewTab('alle', '✨ Alle', _kPurpleL),
            const SizedBox(width: 8),
            _buildViewTab('trending', '🔥 Trending', Colors.orange),
            const SizedBox(width: 8),
            _buildViewTab('fotos', '📸 Fotos', _kTeal),
            const SizedBox(width: 8),
            _buildViewTab('diskussion', '💬 Diskussion', _kPink),
            const SizedBox(width: 8),
            _buildViewTab('gespeichert', '🔖 Gespeichert', _kGold),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBanner() {
    final stats = [
      _CommStat(icon: Icons.article_outlined,   label: 'Posts',   value: _posts.length, color: _kPurple),
      _CommStat(icon: Icons.comment_outlined,   label: 'Komm.',   value: _posts.fold(0, (s, p) => s + p.comments), color: _kTeal),
      _CommStat(icon: Icons.favorite_outline,   label: 'Likes',   value: _posts.fold(0, (s, p) => s + p.likes), color: _kPink),
      _CommStat(icon: Icons.share_outlined,     label: 'Geteilt', value: _posts.fold(0, (s, p) => s + (p.shares ?? 0)), color: _kGold),
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: _kCardB,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: stats.asMap().entries.map((e) {
          final i = e.key; final s = e.value;
          return Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 3),
              decoration: i < stats.length - 1
                  ? BoxDecoration(border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.05))))
                  : null,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(s.icon, color: s.color, size: 17),
                const SizedBox(height: 4),
                Text('${s.value}',
                    style: TextStyle(color: s.color, fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 1),
                Text(s.label,
                    style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w500)),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildViewTab(String view, String label, Color color) {
    final isSelected = _selectedView == view;
    return GestureDetector(
      onTap: () => setState(() => _selectedView = view),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1),
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 10)]
              : null,
        ),
        child: Text(label,
            style: TextStyle(
                color: isSelected ? Colors.white : Colors.white54,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  Widget _buildTrendingSection() {
    const topics = ['Kraftorte', 'Meditation', 'Chakren', 'Kristalle', 'Vollmond', 'Bewusstsein', 'Heilung'];
    final colors = [_kGreen, _kPurple, _kPink, _kTeal, _kGold, _kPurpleL, _kGreen];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('✨ Spirituelle Themen',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const Text('Im Fokus', style: TextStyle(color: Colors.white38, fontSize: 11)),
            ])),
          ]),
        ),
        SizedBox(
          height: 42,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            itemCount: topics.length,
            itemBuilder: (_, i) {
              final c = colors[i % colors.length];
              return GestureDetector(
                onTap: () => setState(() => _selectedView = 'trending'),
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: c.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: c.withValues(alpha: 0.3)),
                  ),
                  child: Text('#${topics[i]}',
                      style: TextStyle(color: c, fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildPostCard(CommunityPost post) {
    final isBookmarked = _bookmarkedIds.contains(post.id);
    final badge = _postBadge(post);
    final postReactions = _reactions[post.id] ?? {};

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kPurple.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(color: _kPurple.withValues(alpha: 0.07), blurRadius: 14, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 8, 0),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [_kPurple.withValues(alpha: 0.5), _kPurpleD.withValues(alpha: 0.2)],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: _kPurpleL.withValues(alpha: 0.35), width: 1.5),
                    boxShadow: [BoxShadow(color: _kPurple.withValues(alpha: 0.3), blurRadius: 8)],
                  ),
                  child: Center(child: Text(post.authorAvatar ?? '🌟', style: const TextStyle(fontSize: 20))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Flexible(
                        child: Text(post.authorUsername,
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis),
                      ),
                      // Feature 3 — Post-Badge
                      if (badge != null) ...[
                        const SizedBox(width: 6),
                        badge,
                      ],
                    ]),
                    const SizedBox(height: 2),
                    Text(_formatTimestamp(post.createdAt),
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
                  ]),
                ),
                // Feature 9 — Bookmark-Icon
                IconButton(
                  tooltip: isBookmarked
                      ? 'Lesezeichen entfernen'
                      : 'Lesezeichen hinzufügen',
                  icon: Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: isBookmarked ? _kGold : Colors.white38,
                    size: 22,
                  ),
                  onPressed: () => _toggleBookmark(post.id),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                ),
                IconButton(
                  tooltip: 'Mehr Optionen',
                  icon: Icon(Icons.more_vert,
                      color: Colors.white.withValues(alpha: 0.5), size: 20),
                  onPressed: () => _showPostMenu(context, post),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                ),
              ],
            ),
          ),

          // ── Content ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Text(post.content,
                style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5)),
          ),

          // ── Tags ──────────────────────────────────────────────────────
          if (post.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Wrap(spacing: 6, runSpacing: 6, children: post.tags.map(_buildPostTag).toList()),
            ),

          // ── Media ─────────────────────────────────────────────────────
          if (post.mediaUrl != null && post.mediaUrl!.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kPurple.withValues(alpha: 0.2)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: post.mediaUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: 180,
                    color: _kPurple.withValues(alpha: 0.08),
                    child: Center(child: CircularProgressIndicator(color: _kPurple)),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: 180,
                    color: _kCard,
                    child: const Icon(Icons.broken_image, color: Colors.white24, size: 40),
                  ),
                ),
              ),
            ),

          // Feature 2 — Emoji-Reactions
          _buildReactionsRow(post.id, postReactions),

          // ── Actions ───────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: _kPurple.withValues(alpha: 0.12))),
            ),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
            child: PostActionsRow(post: post, accentColor: _kPurple, onPostUpdated: _loadData),
          ),
        ],
      ),
    );
  }

  Widget? _postBadge(CommunityPost post) {
    final age = DateTime.now().difference(post.createdAt);
    if (post.mediaUrl != null && post.mediaUrl!.isNotEmpty) {
      return _badge('📸 Foto', _kTeal);
    }
    if (age.inHours < 2) return _badge('✨ Neu', _kGreen);
    if (post.likes > 20) return _badge('🔥 Trending', Colors.orange);
    if (post.comments > 10) return _badge('💬 Diskussion', _kPink);
    return null;
  }

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withValues(alpha: 0.4)),
    ),
    child: Text(label, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold)),
  );

  Widget _buildReactionsRow(String postId, Map<String, int> reactions) {
    const emojis = ['❤️', '🔥', '✨', '💭', '🙏'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Row(
        children: emojis.map((e) {
          final count = reactions[e] ?? 0;
          return GestureDetector(
            onTap: () => _toggleReaction(postId, e),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: count > 0 ? _kPurple.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: count > 0 ? _kPurple.withValues(alpha: 0.45) : Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(e, style: const TextStyle(fontSize: 14)),
                if (count > 0) ...[
                  const SizedBox(width: 3),
                  Text('$count', style: TextStyle(color: _kPurpleL, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Feature 1 — Masonry-Grid (2 Spalten, abwechselnd links/rechts)
  Widget _buildMasonryGrid(List<CommunityPost> posts) {
    final left = <CommunityPost>[];
    final right = <CommunityPost>[];
    for (var i = 0; i < posts.length; i++) {
      (i.isEven ? left : right).add(posts[i]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Column(children: left.map(_buildPostCard).toList())),
        const SizedBox(width: 8),
        Expanded(child: Column(children: right.map(_buildPostCard).toList())),
      ],
    );
  }

  // Feature 4 — Hero-Post (Top-liked Post mit Glow)
  Widget _buildHeroPost(CommunityPost post) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_kPurpleD.withValues(alpha: 0.6), _kPurple.withValues(alpha: 0.2)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kPurple.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [BoxShadow(color: _kPurple.withValues(alpha: 0.25), blurRadius: 20, spreadRadius: 2)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Text('🏆', style: TextStyle(fontSize: 11)),
                SizedBox(width: 4),
                Text('Top Post der Woche', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
              ]),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Text(post.authorAvatar ?? '🌟', style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(post.authorUsername, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 8),
          Text(post.content,
              maxLines: 3, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14, height: 1.4)),
          const SizedBox(height: 10),
          Row(children: [
            Icon(Icons.favorite, color: _kPink, size: 14),
            const SizedBox(width: 4),
            Text('${post.likes}', style: TextStyle(color: _kPink, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(width: 12),
            Icon(Icons.comment_outlined, color: _kTeal, size: 14),
            const SizedBox(width: 4),
            Text('${post.comments}', style: TextStyle(color: _kTeal, fontSize: 12)),
          ]),
        ]),
      ),
    );
  }

  // Feature 5 — Story-Bubbles (Aktive Poster der letzten 24h)
  Widget _buildStoryBubbles() {
    final recentPosters = <String, String>{};
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    for (final p in _posts) {
      if (p.createdAt.isAfter(cutoff) && !recentPosters.containsKey(p.authorUsername)) {
        recentPosters[p.authorUsername] = p.authorAvatar ?? '🌟';
      }
    }
    if (recentPosters.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 82,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: math.min(recentPosters.length, 10),
        itemBuilder: (_, i) {
          final name = recentPosters.keys.elementAt(i);
          final avatar = recentPosters.values.elementAt(i);
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const SweepGradient(
                    colors: [Color(0xFFAB47BC), Color(0xFF26C6DA), Color(0xFFAB47BC)],
                  ),
                  boxShadow: [BoxShadow(color: _kPurple.withValues(alpha: 0.4), blurRadius: 8)],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2.5),
                  child: Container(
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: _kCard),
                    child: Center(child: Text(avatar, style: const TextStyle(fontSize: 22))),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 52,
                child: Text(name,
                    textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 9)),
              ),
            ]),
          );
        },
      ),
    );
  }

  // Feature 7 — Live-Counter (Aktivität basierend auf Post-Frequenz)
  Widget _buildLiveCounter() {
    final recent = _posts.where((p) => DateTime.now().difference(p.createdAt).inHours < 24).length;
    final isActive = recent > 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          width: 8, height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? _kGreen : Colors.grey,
            boxShadow: isActive ? [BoxShadow(color: _kGreen.withValues(alpha: 0.6), blurRadius: 6)] : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          isActive ? '$recent neue Posts heute · Community aktiv' : 'Sei der Erste heute!',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
        ),
      ]),
    );
  }

  Widget _buildPostTag(String tag) {
    // Farbe basierend auf Tag
    Color tagColor = Colors.purple;
    if (tag.contains('Kraftorte') || tag.contains('Erdenergie')) {
      tagColor = Colors.green;
    } else if (tag.contains('Chakren') || tag.contains('Energie')) {
      tagColor = Colors.pink;
    } else if (tag.contains('Meditation') || tag.contains('Yoga')) {
      tagColor = Colors.blue;
    } else if (tag.contains('Kristalle') || tag.contains('Heilsteine')) {
      tagColor = Colors.cyan;
    } else if (tag.contains('Vollmond') || tag.contains('Ritual')) {
      tagColor = Colors.yellow;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: tagColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tagColor.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Text(
        '#$tag',
        style: TextStyle(
          color: tagColor.withValues(alpha: 0.9),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // 3-Punkte-Menü für Posts
  void _showPostMenu(BuildContext context, CommunityPost post) async {
    // 🔐 Username aus Storage holen
    final storage = StorageService();
    final energieProfile = storage.getEnergieProfile();
    final currentUsername = energieProfile?.username ?? 'Gast';
    final isOwnPost = post.authorUsername == currentUsername;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: _kCardB,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🔧 EDIT (nur eigene Posts)
              if (isOwnPost)
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.blue),
                  title: const Text('Bearbeiten', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    _editPost(post);
                  },
                ),
              // 🗑️ DELETE (nur eigene Posts)
              if (isOwnPost)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Löschen', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    _deletePost(post);
                  },
                ),
              if (isOwnPost) const Divider(color: Colors.white24),
              // 🔔 Melden
              ListTile(
                leading: const Icon(Icons.report_outlined, color: Colors.orange),
                title: const Text('Melden', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('⚠️ Post gemeldet'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              // 🚫 Blockieren
              ListTile(
                leading: const Icon(Icons.block_outlined, color: Colors.red),
                title: const Text('Autor blockieren', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🚫 ${post.authorUsername} blockiert'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              // 🔗 Link kopieren
              ListTile(
                leading: const Icon(Icons.link_outlined, color: Colors.blue),
                title: const Text('Link kopieren', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🔗 Link kopiert'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
  
  /// ✏️ POST BEARBEITEN
  Future<void> _editPost(CommunityPost post) async {
    final contentController = TextEditingController(text: post.content);
    final tagsController = TextEditingController(text: post.tags.join(', '));

    String newContent = '';
    List<String> newTags = const [];
    bool result = false;
    try {
      result = await showDialog<bool>(
            context: context,
            builder: (context) {
              return AlertDialog(
                backgroundColor: _kCardB,
                title: const Text('Post bearbeiten',
                    style: TextStyle(color: Colors.white)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: contentController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Inhalt',
                        labelStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: tagsController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Tags (mit Komma trennen)',
                        labelStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Abbrechen'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Speichern'),
                  ),
                ],
              );
            },
          ) ??
          false;
      // Werte LESEN während Controller noch leben
      newContent = contentController.text.trim();
      newTags = tagsController.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();
    } finally {
      contentController.dispose();
      tagsController.dispose();
    }

    if (!result) return;

    // Validation: leerer Content nicht zulassen
    if (newContent.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Inhalt darf nicht leer sein'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      await _communityService.editPost(
        post.id,
        content: newContent,
        tags: newTags,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Post bearbeitet!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData(); // Reload
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('❌ Fehler: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }
  
  /// 🗑️ POST LÖSCHEN
  Future<void> _deletePost(CommunityPost post) async {
    final storage = StorageService();
    final energieProfile = storage.getEnergieProfile();
    final currentUsername = energieProfile?.username ?? 'Gast';
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _kCardB,
          title: const Text('Post löschen?', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Dieser Post wird dauerhaft gelöscht.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Löschen'),
            ),
          ],
        );
      },
    );
    
    if (confirm == true) {
      try {
        // Snapshot vor dem Löschen — für Undo
        final snapshot = post;

        await _communityService.deletePost(post.id, currentUsername);

        if (mounted) {
          _loadData(); // Reload sofort

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('🗑️ Post gelöscht'),
              backgroundColor: Colors.grey[800],
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Rückgängig',
                textColor: _kPurpleL,
                onPressed: () async {
                  // Post neu erstellen (neue ID, gleicher Inhalt)
                  try {
                    await _communityService.createPost(
                      username: currentUsername,
                      content: snapshot.content,
                      tags: snapshot.tags,
                      worldType: WorldType.energie,
                      authorAvatar: snapshot.authorAvatar,
                      mediaUrl: snapshot.mediaUrl,
                      mediaType: snapshot.mediaType,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Post wiederhergestellt'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                      _loadData();
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_friendlyErrorMessage(e)),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(_friendlyErrorMessage(e)),
                backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  // Unused: _buildEngagementStat method (kept for future use)
  // Widget _buildEngagementStat(IconData icon, int count, Color color) {
    // return Row(
      // children: [
        // Icon(
          // icon,
          // size: 18,
          // color: color.withValues(alpha: 0.7),
        // ),
        // const SizedBox(width: 4),
        // Text(
          // _formatNumber(count),
          // style: TextStyle(
            // color: Colors.white.withValues(alpha: 0.7),
            // fontSize: 13,
            // fontWeight: FontWeight.w500,
          // ),
        // ),
      // ],
    // );
  // }

  // Unused: _buildActionButton method (kept for future use)
  // Widget _buildActionButton(IconData icon, String label, Color color) {
    // return InkWell(
      // onTap: () {
        // Future feature: Implement community actions (Like, Comment, Share)
        // ScaffoldMessenger.of(context).showSnackBar(
          // SnackBar(
            // content: Text('$label Funktion coming soon'),
            // duration: const Duration(seconds: 2),
          // ),
        // );
      // },
      // child: Padding(
        // padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        // child: Row(
          // children: [
            // Icon(
              // icon,
              // size: 20,
              // color: Colors.white.withValues(alpha: 0.7),
            // ),
            // const SizedBox(width: 6),
            // Text(
              // label,
              // style: TextStyle(
                // color: Colors.white.withValues(alpha: 0.7),
                // fontSize: 13,
                // fontWeight: FontWeight.w500,
              // ),
            // ),
          // ],
        // ),
      // ),
    // );
  // }

  // ── Section title (home-dashboard style) ────────────────────────────────
  Widget _buildSectionTitle(String title, {String subtitle = ''}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          if (subtitle.isNotEmpty)
            Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
            color: _kPurple.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _kPurple.withValues(alpha: 0.28)),
          ),
          child: const Text('Alle →', style: TextStyle(color: _kPurpleL, fontSize: 10, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 60) {
      return 'vor ${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return 'vor ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'vor ${difference.inDays}d';
    } else {
      return 'vor ${(difference.inDays / 7).floor()}w';
    }
  }

  // Unused: _formatNumber method (kept for future use)
  // String _formatNumber(int number) {
    // if (number >= 1000) {
      // return '${(number / 1000).toStringAsFixed(1)}k';
    // }
    // return number.toString();
  // }
}

class _CommStat {
  final IconData icon;
  final String label;
  final int value;
  final Color color;
  const _CommStat({required this.icon, required this.label, required this.value, required this.color});
}

class _CommunityAuraPainter extends CustomPainter {
  final double orbitProgress;
  final double auraProgress;
  final double scrollOffset;
  final Color color;

  _CommunityAuraPainter({
    required this.orbitProgress,
    required this.auraProgress,
    required this.scrollOffset,
    required this.color,
  });

  static final List<Offset> _stars = List.generate(28, (i) {
    final rng = math.Random(i * 11 + 7);
    return Offset(rng.nextDouble(), rng.nextDouble());
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF08040F), Color(0xFF0D061A), Color(0xFF080410)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final glow1 = Paint()
      ..color = color.withValues(alpha: 0.06 + math.sin(auraProgress * math.pi) * 0.04)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 70);
    canvas.drawCircle(Offset(size.width * 0.4, size.height * 0.3), size.width * 0.55, glow1);

    final glow2 = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.03 + auraProgress * 0.02)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);
    canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.6), size.width * 0.3, glow2);

    final particlePaint = Paint()..color = color.withValues(alpha: 0.25);
    for (int p = 0; p < 3; p++) {
      final angle = orbitProgress * math.pi * 2 + p * (math.pi * 2 / 3);
      final radius = 26.0 + p * 12;
      final cx = size.width * 0.75 + math.cos(angle) * radius;
      final cy = size.height * 0.3 + math.sin(angle) * radius * 0.6;
      canvas.drawCircle(Offset(cx, cy - scrollOffset * 0.1), 2.0 + p * 0.5, particlePaint);
    }

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
  bool shouldRepaint(_CommunityAuraPainter old) =>
      old.orbitProgress != orbitProgress ||
      old.auraProgress != auraProgress ||
      old.scrollOffset != scrollOffset;
}
