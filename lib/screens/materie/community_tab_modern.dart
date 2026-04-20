import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import '../../models/community_post.dart';
import '../../services/community_service.dart'; // 🌐 ECHTE API
import '../../widgets/create_post_dialog_v2.dart'; // ✅ POST-DIALOG
import '../../widgets/loading_skeletons.dart'; // 💀 LOADING SKELETONS
import '../../widgets/article_like_button.dart'; // 👍 NEW: Like Button
import '../../widgets/article_comments_widget.dart'; // 💬 NEW: Comments Widget
import 'materie_live_chat_screen.dart'; // 💬 LIVE-CHAT INTEGRATION
import '../../services/chat_notification_service.dart'; // 🔔 NOTIFICATION SERVICE
import 'package:share_plus/share_plus.dart';

/// Modernes Community-Tab für MATERIE-Welt - Social-Media-Style
class MaterieCommunityTabModern extends StatefulWidget {
  const MaterieCommunityTabModern({super.key});

  @override
  State<MaterieCommunityTabModern> createState() => _MaterieCommunityTabModernState();
}

// ── Design palette (mirrors Materie Home Dashboard V7) ────────────────────
const _mBg    = Color(0xFF04080F);
const _mCard  = Color(0xFF0A1020);
const _mCardB = Color(0xFF0D1528);
const _mBlue  = Color(0xFF2979FF);
const _mBlueL = Color(0xFF82B1FF);
const _mCyan  = Color(0xFF00E5FF);
const _mAmber = Color(0xFFFFAB00);
const _mGreen = Color(0xFF00E676);
const _mRed   = Color(0xFFFF1744);

class _MaterieCommunityTabModernState extends State<MaterieCommunityTabModern> with TickerProviderStateMixin {
  bool _isLoading = false;
  String _selectedView = 'alle';

  // Feature 9 — Bookmarks
  Set<String> _bookmarkedIds = {};
  // Feature 2 — Reactions
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

  // 🌐 ECHTE Community-Posts von Cloudflare API
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
    final saved = prefs.getStringList('materie_bookmarks') ?? [];
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
    await prefs.setStringList('materie_bookmarks', _bookmarkedIds.toList());
  }

  void _toggleReaction(String postId, String emoji) {
    HapticFeedback.selectionClick();
    setState(() {
      _reactions[postId] ??= {};
      _reactions[postId]![emoji] = (_reactions[postId]![emoji] ?? 0) + 1;
    });
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

  /// 🌐 Lade echte Community-Posts von Cloudflare API
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final posts = await _communityService.fetchPosts(worldType: WorldType.materie);
      
      if (kDebugMode) {
        debugPrint('🔵 MATERIE Community (AKTIV): ${posts.length} posts loaded');
      }
      
      setState(() {
        _posts = posts;
        // posts loaded successfully
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🔵 MATERIE Community (AKTIV): Error loading posts: $e');
      }
      
      setState(() {
        _isLoading = false;
        // keep showing old posts if any
      });
    }
  }
  
  // Feature 6 — Inline Bottom-Sheet
  Future<void> _showCreatePostDialogV2() async {
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
          child: const CreatePostDialogV2(worldType: WorldType.materie),
        ),
      ),
    );
    if (result == true) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _mBg,
      body: Column(
        children: [
        // 💬 TAB BAR: Posts vs Live Chat
        Container(
          color: _mBg,
          child: TabBar(
            controller: _tabController,
            indicatorColor: _mBlue,
            indicatorWeight: 2,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white38,
            labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            unselectedLabelStyle: const TextStyle(fontSize: 14),
            dividerColor: Colors.white.withValues(alpha: 0.06),
            tabs: [
              const Tab(
                icon: Icon(Icons.article),
                text: 'Posts',
              ),
              Tab(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.chat_bubble),
                    // 🔔 UNREAD BADGE
                    Positioned(
                      right: -6,
                      top: -6,
                      child: ListenableBuilder(
                        listenable: _notificationService,
                        builder: (context, _) {
                          final count = _notificationService.getTotalUnreadCount();
                          if (count == 0) return const SizedBox.shrink();
                          
                          return Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withValues(alpha: 0.5),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Center(
                              child: Text(
                                count > 9 ? '9+' : count.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                text: 'Live Chat',
              ),
            ],
          ),
        ),
        
        // 💬 TAB VIEW: Posts oder Chat
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // TAB 1: Community Posts (Original)
              _buildPostsView(),
              
              // TAB 2: Live Chat (ACTIVATED!)
              const MaterieLiveChatScreen(),
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
                  colors: [Color(0xFF1565C0), Color(0xFF2979FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF2979FF).withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                onPressed: _showCreatePostDialogV2,
                backgroundColor: Colors.transparent,
                elevation: 0,
                icon: const Icon(Icons.edit, color: Colors.white, size: 24),
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
      case 'fotos': return _posts.where((p) => p.mediaUrl != null && p.mediaUrl!.isNotEmpty).toList();
      case 'trending': return (List.from(_posts)..sort((a, b) => b.likes.compareTo(a.likes))).cast<CommunityPost>();
      case 'diskussion': return (List.from(_posts)..sort((a, b) => b.comments.compareTo(a.comments))).cast<CommunityPost>();
      case 'gespeichert': return _posts.where((p) => _bookmarkedIds.contains(p.id)).toList();
      default: return _posts;
    }
  }

  // Posts View
  Widget _buildPostsView() {
    final filtered = _filteredPosts;
    final hero = _posts.isNotEmpty
        ? (List<CommunityPost>.from(_posts)..sort((a, b) => b.likes.compareTo(a.likes))).first
        : null;

    return Container(
      color: _mBg,
      child: RefreshIndicator(
        color: _mRed,
        backgroundColor: Colors.black87,
        onRefresh: _loadData,
        child: CustomScrollView(
          controller: _scrollCtrl,
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            _buildHeroHeader(),
            SliverToBoxAdapter(child: _buildFilterRow()),
            SliverToBoxAdapter(child: _buildLiveCounter()),
            SliverToBoxAdapter(child: _buildStatBanner()),
            if (_posts.isNotEmpty) SliverToBoxAdapter(child: _buildStoryBubbles()),
            if (_selectedView == 'trending') SliverToBoxAdapter(child: _buildTrendingSection()),
            if (hero != null && _selectedView == 'alle') SliverToBoxAdapter(child: _buildHeroPost(hero)),
            SliverToBoxAdapter(
              child: _buildSectionTitle('🔥 Neueste Beiträge', subtitle: 'Fakten & Recherchen'),
            ),
            _isLoading
                ? SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, __) => LoadingSkeletons.postCard(), childCount: 3,
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                    sliver: SliverToBoxAdapter(child: _buildMasonryGrid(filtered)),
                  ),
          ],
        ),
      ),
    );
  }

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

  Widget _buildHeroPost(CommunityPost post) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF1A237E).withValues(alpha: 0.6), _mBlue.withValues(alpha: 0.2)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _mBlue.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [BoxShadow(color: _mBlue.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 2)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Text('🏆', style: TextStyle(fontSize: 11)),
              SizedBox(width: 4),
              Text('Top Post der Woche', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
            ]),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Text(post.authorAvatar ?? '🌍', style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(post.authorUsername, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 8),
          Text(post.content, maxLines: 3, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14, height: 1.4)),
          const SizedBox(height: 10),
          Row(children: [
            Icon(Icons.favorite, color: _mRed, size: 14),
            const SizedBox(width: 4),
            Text('${post.likes}', style: TextStyle(color: _mRed, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(width: 12),
            Icon(Icons.comment_outlined, color: _mCyan, size: 14),
            const SizedBox(width: 4),
            Text('${post.comments}', style: TextStyle(color: _mCyan, fontSize: 12)),
          ]),
        ]),
      ),
    );
  }

  Widget _buildStoryBubbles() {
    final recentPosters = <String, String>{};
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    for (final p in _posts) {
      if (p.createdAt.isAfter(cutoff) && !recentPosters.containsKey(p.authorUsername)) {
        recentPosters[p.authorUsername] = p.authorAvatar ?? '🌍';
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
                  gradient: const SweepGradient(colors: [Color(0xFF2979FF), Color(0xFFFF1744), Color(0xFF2979FF)]),
                  boxShadow: [BoxShadow(color: _mBlue.withValues(alpha: 0.4), blurRadius: 8)],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2.5),
                  child: Container(
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: _mCard),
                    child: Center(child: Text(avatar, style: const TextStyle(fontSize: 22))),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 52,
                child: Text(name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 9)),
              ),
            ]),
          );
        },
      ),
    );
  }

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
            color: isActive ? _mGreen : Colors.grey,
            boxShadow: isActive ? [BoxShadow(color: _mGreen.withValues(alpha: 0.6), blurRadius: 6)] : null,
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
                    color: _mBlue,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, _mBg],
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
                                _mBlue.withValues(alpha: 0.45 + _auraCtrl.value * 0.2),
                                const Color(0xFF1A237E).withValues(alpha: 0.1),
                              ],
                            ),
                            border: Border.all(
                                color: _mBlueL.withValues(alpha: 0.4 + _auraCtrl.value * 0.3),
                                width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: _mBlue.withValues(alpha: 0.25 + _auraCtrl.value * 0.2),
                                blurRadius: 18, spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text('🌍', style: TextStyle(fontSize: 24)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('🔍 Materie Community',
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
                                    color: _mBlue.withValues(alpha: 0.5 + _auraCtrl.value * 0.5),
                                    shape: BoxShape.circle,
                                    boxShadow: [BoxShadow(color: _mBlue.withValues(alpha: 0.5), blurRadius: 4)],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text('${_posts.length} Beiträge · Welt der MATERIE',
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
            _buildViewTab('alle', '✨ Alle', _mBlueL),
            const SizedBox(width: 8),
            _buildViewTab('trending', '🔥 Trending', Colors.orange),
            const SizedBox(width: 8),
            _buildViewTab('fotos', '📸 Fotos', _mCyan),
            const SizedBox(width: 8),
            _buildViewTab('diskussion', '💬 Diskussion', _mAmber),
            const SizedBox(width: 8),
            _buildViewTab('gespeichert', '🔖 Gespeichert', _mGreen),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: _mCardB,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          _mStat(Icons.article_outlined, 'Posts', _posts.length, _mBlue, true),
          _mStat(Icons.comment_outlined, 'Komm.', _posts.fold(0, (s, p) => s + p.comments), _mCyan, true),
          _mStat(Icons.favorite_outline, 'Likes', _posts.fold(0, (s, p) => s + p.likes), _mAmber, true),
          _mStat(Icons.share_outlined, 'Geteilt', _posts.fold(0, (s, p) => s + (p.shares ?? 0)), _mGreen, false),
        ],
      ),
    );
  }

  Widget _mStat(IconData icon, String label, int value, Color color, bool border) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 3),
        decoration: border
            ? BoxDecoration(border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.05))))
            : null,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(height: 4),
          Text('$value', style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 1),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {String subtitle = ''}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          if (subtitle.isNotEmpty)
            Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
            color: _mBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _mBlue.withValues(alpha: 0.28)),
          ),
          child: const Text('Alle →', style: TextStyle(color: _mBlueL, fontSize: 10, fontWeight: FontWeight.w600)),
        ),
      ]),
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
              ? [BoxShadow(color: color.withValues(alpha: 0.18), blurRadius: 10)]
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
    const topics = ['Geopolitik', 'WikiLeaks', 'CERN', 'Transparenz', 'Kaninchenbau', 'Geschichte', 'UFOs'];
    final colors = [_mBlue, Colors.orange, _mCyan, _mAmber, _mGreen, _mBlueL, _mRed];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('🔥 Trending Topics',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const Text('Heiß diskutiert', style: TextStyle(color: Colors.white38, fontSize: 11)),
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
              return Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: c.withValues(alpha: 0.3)),
                ),
                child: Text('#${topics[i]}',
                    style: TextStyle(color: c, fontSize: 13, fontWeight: FontWeight.w600)),
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
        color: _mCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _mBlue.withValues(alpha: 0.13)),
        boxShadow: [BoxShadow(color: _mBlue.withValues(alpha: 0.07), blurRadius: 14, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 8, 0),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [_mBlue.withValues(alpha: 0.45), const Color(0xFF1A237E).withValues(alpha: 0.2)],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: _mBlueL.withValues(alpha: 0.35), width: 1.5),
                    boxShadow: [BoxShadow(color: _mBlue.withValues(alpha: 0.25), blurRadius: 8)],
                  ),
                  child: Center(child: Text(post.authorAvatar ?? '🌍', style: const TextStyle(fontSize: 20))),
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
                      // Feature 3 — Badge
                      if (badge != null) ...[const SizedBox(width: 6), badge],
                    ]),
                    const SizedBox(height: 2),
                    Text(_formatTimestamp(post.createdAt),
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.38), fontSize: 11)),
                  ]),
                ),
                // Feature 9 — Bookmark
                IconButton(
                  icon: Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: isBookmarked ? _mAmber : Colors.white38, size: 22,
                  ),
                  onPressed: () => _toggleBookmark(post.id),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                IconButton(
                  icon: Icon(Icons.more_vert, color: Colors.white.withValues(alpha: 0.45), size: 20),
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    backgroundColor: _mCardB,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
                    builder: (ctx) => SafeArea(
                      child: Wrap(children: [
                        ListTile(
                          leading: const Icon(Icons.share, color: Colors.white),
                          title: const Text('Teilen', style: TextStyle(color: Colors.white)),
                          onTap: () { Navigator.pop(ctx); Share.share('${post.content}\n\nGeteilt aus der Weltenbibliothek'); },
                        ),
                        ListTile(
                          leading: const Icon(Icons.flag_outlined, color: Colors.orange),
                          title: const Text('Melden', style: TextStyle(color: Colors.white)),
                          onTap: () { Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gemeldet. Danke.'))); },
                        ),
                      ]),
                    ),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ],
            ),
          ),
          // ── Content ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Text(post.content, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5)),
          ),
          // ── Tags ─────────────────────────────────────────────────────────
          if (post.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Wrap(spacing: 6, runSpacing: 6, children: post.tags.map(_buildPostTag).toList()),
            ),
          // Feature 2 — Reactions
          _buildReactionsRow(post.id, postReactions),
          // ── Actions ──────────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: _mBlue.withValues(alpha: 0.1)))),
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            child: Row(children: [
              ArticleLikeButton(articleId: post.id, initialLikes: post.likes, initiallyLiked: false),
              const SizedBox(width: 18),
              ArticleCommentsWidget(articleId: post.id, initialCommentCount: post.comments),
              const Spacer(),
              InkWell(
                onTap: () => Share.share('${post.content}\n\nGeteilt aus der Weltenbibliothek'),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.share_outlined, color: Colors.white.withValues(alpha: 0.55), size: 18),
                    const SizedBox(width: 4),
                    Text('${post.shares ?? 0}', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
                  ]),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget? _postBadge(CommunityPost post) {
    final age = DateTime.now().difference(post.createdAt);
    if (post.mediaUrl != null && post.mediaUrl!.isNotEmpty) return _badge('📸 Foto', _mCyan);
    if (age.inHours < 2) return _badge('✨ Neu', _mGreen);
    if (post.likes > 20) return _badge('🔥 Trending', Colors.orange);
    if (post.comments > 10) return _badge('💬 Diskussion', _mAmber);
    return null;
  }

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6),
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
                color: count > 0 ? _mBlue.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: count > 0 ? _mBlue.withValues(alpha: 0.45) : Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(e, style: const TextStyle(fontSize: 14)),
                if (count > 0) ...[
                  const SizedBox(width: 3),
                  Text('$count', style: TextStyle(color: _mBlueL, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPostTag(String tag) {
    // Farbe basierend auf Tag
    Color tagColor = Colors.blue;
    if (tag.contains('Geopolitik')) {
      tagColor = Colors.green;
    } else if (tag.contains('Geschichte') || tag.contains('Dokumente')) {
      tagColor = Colors.orange;
    } else if (tag.contains('Machtstrukturen') || tag.contains('Recherche')) {
      tagColor = Colors.purple;
    } else if (tag.contains('Transparenz') || tag.contains('WikiLeaks')) {
      tagColor = Colors.yellow;
    } else if (tag.contains('CERN') || tag.contains('Physik')) {
      tagColor = Colors.cyan;
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
        colors: [Color(0xFF04080F), Color(0xFF06101C), Color(0xFF04080F)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final glow1 = Paint()
      ..color = color.withValues(alpha: 0.06 + math.sin(auraProgress * math.pi) * 0.04)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 70);
    canvas.drawCircle(Offset(size.width * 0.4, size.height * 0.3), size.width * 0.55, glow1);

    final glow2 = Paint()
      ..color = const Color(0xFF82B1FF).withValues(alpha: 0.03 + auraProgress * 0.02)
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
