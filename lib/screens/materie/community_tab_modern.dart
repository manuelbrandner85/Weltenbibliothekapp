import 'package:flutter/material.dart';
 // OpenClaw v2.0
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import '../../models/community_post.dart';
import '../../services/community_service.dart'; // 🌐 ECHTE API
import '../../widgets/create_post_dialog_v2.dart'; // ✅ POST-DIALOG
import '../../widgets/loading_skeletons.dart'; // 💀 LOADING SKELETONS
import '../../widgets/article_like_button.dart'; // 👍 NEW: Like Button
import '../../widgets/article_comments_widget.dart'; // 💬 NEW: Comments Widget
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

class _MaterieCommunityTabModernState extends State<MaterieCommunityTabModern> {
  bool _isLoading = false;
  String _selectedView = 'all';

  final CommunityService _communityService = CommunityService();
  
  // 🌐 ECHTE Community-Posts von Cloudflare API
  List<CommunityPost> _posts = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final posts = await _communityService.fetchPosts(worldType: WorldType.materie);
      if (mounted) {
        setState(() {
          _posts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('🔵 MATERIE Community: Error loading posts: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  /// ✅ Zeige Post-Erstellungs-Dialog
  Future<void> _showCreatePostDialogV2() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const CreatePostDialogV2(worldType: WorldType.materie),
    );
    
    if (result == true) {
      _loadData(); // Reload nach erfolgreicher Erstellung
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _mBg,
      body: _buildPostsView(),
      floatingActionButton: Container(
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
      ),
    );
  }
  
  // Posts View
  Widget _buildPostsView() {
    return Container(
      color: _mBg,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildStatBanner()),
          if (_selectedView == 'trending')
            SliverToBoxAdapter(child: _buildTrendingSection()),
          SliverToBoxAdapter(
            child: _buildSectionTitle('🔥 Neueste Beiträge', subtitle: 'Fakten & Recherchen'),
          ),
          // Community-Posts
          _isLoading
              ? SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => LoadingSkeletons.postCard(),
                      childCount: 3, // Show 3 skeleton posts
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildPostCard(_posts[index]),
                      childCount: _posts.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title row ─────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar orb (cosmos style)
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0x552979FF), Color(0x1A1A237E)],
                  ),
                  border: Border.all(color: _mBlueL.withValues(alpha: 0.4), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: _mBlue.withValues(alpha: 0.3), blurRadius: 14, spreadRadius: 2),
                  ],
                ),
                child: const Center(child: Text('🌍', style: TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Materie Community',
                      style: TextStyle(color: Colors.white, fontSize: 19,
                          fontWeight: FontWeight.bold, letterSpacing: -0.3)),
                  const SizedBox(height: 3),
                  Row(children: [
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(
                        color: _mGreen,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: _mGreen.withValues(alpha: 0.6), blurRadius: 4)],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('Teile Recherchen & Erkenntnisse',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
                  ]),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ── View-Chips ─────────────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildViewTab('trending', '🔥 Trending', Colors.orange),
                const SizedBox(width: 10),
                _buildViewTab('following', '👥 Following', _mBlue),
                const SizedBox(width: 10),
                _buildViewTab('community', '💬 Alle Posts', _mCyan),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _mCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _mBlue.withValues(alpha: 0.13)),
        boxShadow: [
          BoxShadow(color: _mBlue.withValues(alpha: 0.07), blurRadius: 14, offset: const Offset(0, 5)),
        ],
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
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _mBlue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _mBlue.withValues(alpha: 0.3)),
                        ),
                        child: const Text('🌍 Materie',
                            style: TextStyle(fontSize: 9, color: _mBlueL, fontWeight: FontWeight.bold)),
                      ),
                    ]),
                    const SizedBox(height: 2),
                    Text(_formatTimestamp(post.createdAt),
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.38), fontSize: 11)),
                  ]),
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
                          onTap: () { Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gemeldet. Danke.')));
                          },
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
            child: Text(post.content,
                style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5)),
          ),

          // ── Tags ─────────────────────────────────────────────────────────
          if (post.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Wrap(spacing: 6, runSpacing: 6,
                  children: post.tags.map(_buildPostTag).toList()),
            ),

          // ── Actions row ──────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.only(top: 10),
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
                    Text('${post.shares ?? 0}',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
                  ]),
                ),
              ),
            ]),
          ),
        ],
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
