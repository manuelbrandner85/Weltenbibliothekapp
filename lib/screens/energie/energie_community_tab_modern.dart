import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import '../../models/community_post.dart';
import '../../services/community_service.dart'; // ✅ Cloudflare API
// 🔐 PROFIL-DATEN
import '../../widgets/create_post_dialog_v2.dart'; // ✅ Post-Dialog
import '../../widgets/post_actions_row.dart'; // ✅ POST ACTIONS
import '../../widgets/loading_skeletons.dart'; // 💀 LOADING SKELETONS
// 👍 NEW: Like Button
// 💬 NEW: Comments Widget
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

class _EnergieCommunityTabModernState extends State<EnergieCommunityTabModern> {
  bool _isLoading = true;
  String _selectedView = 'trending'; // 'trending', 'sacred', 'experiences'

  final CommunityService _communityService = CommunityService();
  
  // ✅ Echte Posts von Cloudflare API
  List<CommunityPost> _posts = [];

  @override
  void initState() {
    super.initState();
    _loadData();
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
          SnackBar(content: Text('❌ Fehler: $e')),
        );
      }
    }
  }
  
  Future<void> _showCreatePostDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => CreatePostDialogV2(
        worldType: WorldType.energie,
      ),
    );
    if (result == true) {
      _loadData(); // ✅ Reload posts after success
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: _buildPostsView(),
      floatingActionButton: Container(
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
            ),
    );
  }
  
  // Original Posts View
  Widget _buildPostsView() {
    return Container(
      color: _kBg,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildStatBanner()),

          // Trending Energie-Tags
          if (_selectedView == 'trending')
            SliverToBoxAdapter(
              child: _buildTrendingSection(),
            ),
          
          SliverToBoxAdapter(
            child: _buildSectionTitle('✨ Neueste Beiträge', subtitle: 'Spiritueller Austausch'),
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
              : _posts.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.forum_outlined, size: 64, color: Colors.white.withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          Text(
                            'Noch keine Posts vorhanden',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sei der Erste und erstelle einen Post!',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 14,
                            ),
                          ),
                        ],
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
              // Aura orb
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0x66AB47BC), Color(0x1A4A148C)],
                  ),
                  border: Border.all(color: _kPurpleL.withValues(alpha: 0.45), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: _kPurple.withValues(alpha: 0.3), blurRadius: 16, spreadRadius: 2),
                  ],
                ),
                child: const Center(child: Text('🌟', style: TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Spirituelle Community',
                        style: TextStyle(color: Colors.white, fontSize: 19,
                            fontWeight: FontWeight.bold, letterSpacing: -0.3)),
                    const SizedBox(height: 3),
                    Row(children: [
                      Container(
                        width: 6, height: 6,
                        decoration: BoxDecoration(
                          color: _kPurple,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: _kPurple.withValues(alpha: 0.6), blurRadius: 4)],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('Teile Erfahrungen & Erkenntnisse',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 11)),
                    ]),
                  ],
                ),
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
                _buildViewTab('sacred', '🕉️ Heilig', _kPurple),
                const SizedBox(width: 10),
                _buildViewTab('experiences', '✨ Erfahrungen', _kPink),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
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
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 8, 0),
            child: Row(
              children: [
                // Avatar
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
                // Name + time
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Flexible(
                        child: Text(post.authorUsername,
                            style: const TextStyle(color: Colors.white, fontSize: 14,
                                fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _kPurple.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _kPurple.withValues(alpha: 0.3)),
                        ),
                        child: const Text('⚡ Energie',
                            style: TextStyle(fontSize: 9, color: _kPurpleL, fontWeight: FontWeight.bold)),
                      ),
                    ]),
                    const SizedBox(height: 2),
                    Text(_formatTimestamp(post.createdAt),
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
                  ]),
                ),
                IconButton(
                  icon: Icon(Icons.more_vert, color: Colors.white.withValues(alpha: 0.5), size: 20),
                  onPressed: () => _showPostMenu(context, post),
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

          // ── Media ────────────────────────────────────────────────────────
          if (post.mediaUrl != null && post.mediaUrl!.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kPurple.withValues(alpha: 0.2)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(post.mediaUrl!, fit: BoxFit.cover,
                    loadingBuilder: (_, child, prog) => prog == null ? child
                        : Container(height: 180, color: _kPurple.withValues(alpha: 0.08),
                            child: Center(child: CircularProgressIndicator(color: _kPurple,
                                value: prog.expectedTotalBytes != null
                                    ? prog.cumulativeBytesLoaded / prog.expectedTotalBytes! : null))),
                    errorBuilder: (_, __, ___) => Container(height: 180,
                        decoration: BoxDecoration(color: _kCard),
                        child: Icon(Icons.broken_image, color: Colors.white24, size: 40))),
              ),
            ),

          // ── Actions ──────────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.only(top: 10),
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
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _kCardB,
          title: const Text('Post bearbeiten', style: TextStyle(color: Colors.white)),
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
    );
    
    if (result == true) {
      try {
        final newContent = contentController.text.trim();
        final newTags = tagsController.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
        
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
            SnackBar(content: Text('❌ Fehler: $e'), backgroundColor: Colors.red),
          );
        }
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
        await _communityService.deletePost(post.id, currentUsername);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Post gelöscht!'),
              backgroundColor: Colors.green,
            ),
          );
          _loadData(); // Reload
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Fehler: $e'), backgroundColor: Colors.red),
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
