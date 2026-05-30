import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/community_post.dart';
import '../../widgets/community_actions_bar.dart';

class UrsprungCommunityTab extends StatefulWidget {
  const UrsprungCommunityTab({super.key});

  @override
  State<UrsprungCommunityTab> createState() => _UrsprungCommunityTabState();
}

class _UrsprungCommunityTabState extends State<UrsprungCommunityTab> {
  static const _cyan = Color(0xFF00D4AA);
  static const _bg = Color(0xFF050510);
  static const _surface = Color(0xFF080818);

  final _client = Supabase.instance.client;
  List<CommunityPost> _posts = [];
  bool _loading = true;
  String _view = 'feed';

  String get _userId => _client.auth.currentUser?.id ?? '';
  String get _username =>
      _client.auth.currentUser?.userMetadata?['username']?.toString() ??
      'Anonym';

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final rows = await _client
          .from('community_posts')
          .select()
          .eq('world', 'ursprung')
          .order('created_at', ascending: false)
          .limit(50);
      if (!mounted) return;
      final all = _parseRows(rows);
      setState(() {
        _posts = all;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<CommunityPost> _parseRows(List<dynamic> rows) {
    return rows
        .map<CommunityPost>((r) => CommunityPost(
              id: r['id']?.toString() ?? '',
              authorUsername: r['author']?.toString() ??
                  r['username']?.toString() ??
                  'Anonym',
              authorAvatar: r['author_avatar']?.toString() ?? '👤',
              content: r['content']?.toString() ?? '',
              createdAt: DateTime.tryParse(r['created_at']?.toString() ?? '') ??
                  DateTime.now(),
              likes: (r['likes_count'] as num?)?.toInt() ?? 0,
              comments: (r['comments_count'] as num?)?.toInt() ?? 0,
              tags: [],
              worldType: WorldType.ursprung, // FIX (U5): war faelschl. energie
            ))
        .toList();
  }

  void _showCreatePost() {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Neuer Post',
              style: TextStyle(
                  color: _cyan, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 5,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Teile deine Erfahrungen...',
                hintStyle:
                    TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                filled: true,
                fillColor: const Color(0xFF0F0F28),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _cyan,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final text = ctrl.text.trim();
                  if (text.isEmpty) return;
                  Navigator.pop(ctx);
                  try {
                    await _client.from('community_posts').insert({
                      'user_id': _userId,
                      'world': 'ursprung',
                      'content': text,
                      'author': _username,
                      'username': _username,
                      'author_avatar': '👤',
                      'tags': <String>[],
                      'likes_count': 0,
                      'comments_count': 0,
                      'shares_count': 0,
                    });
                    _loadPosts();
                  } catch (_) {
                    _loadPosts();
                  }
                },
                child: const Text('Veröffentlichen'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'gerade eben';
    if (diff.inMinutes < 60) return 'vor ${diff.inMinutes} Min.';
    if (diff.inHours < 24) return 'vor ${diff.inHours} Std.';
    return 'vor ${diff.inDays} Tagen';
  }

  List<CommunityPost> get _displayed {
    if (_view == 'mine') {
      return _posts.where((p) => p.authorUsername == _username).toList();
    }
    return _posts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      floatingActionButton: FloatingActionButton(
        backgroundColor: _cyan,
        foregroundColor: Colors.black,
        onPressed: _showCreatePost,
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        color: _cyan,
        onRefresh: _loadPosts,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildPillSwitcher()),
            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: _cyan)),
              )
            else if (_displayed.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.article_outlined,
                          size: 48, color: _cyan.withValues(alpha: 0.4)),
                      const SizedBox(height: 12),
                      const Text(
                        'Noch keine Posts — sei der Erste!',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _buildCard(_displayed[i]),
                  childCount: _displayed.length,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: _surface,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'URSPRUNG COMMUNITY',
            style: TextStyle(
              color: _cyan,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Teile deine Erfahrungen',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildPillSwitcher() {
    return Container(
      color: _bg,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          _pill('Feed', 'feed'),
          const SizedBox(width: 10),
          _pill('Meine Posts', 'mine'),
        ],
      ),
    );
  }

  Widget _pill(String label, String value) {
    final selected = _view == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _view = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _cyan : _cyan.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? _cyan : _cyan.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : _cyan,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildCard(CommunityPost post) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: const Border(left: BorderSide(color: _cyan, width: 3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: _cyan.withValues(alpha: 0.2),
                  child: Text(
                    post.authorUsername.isNotEmpty
                        ? post.authorUsername[0].toUpperCase()
                        : '?',
                    style: const TextStyle(color: _cyan, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    post.authorUsername,
                    style: const TextStyle(
                        color: _cyan,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                ),
                Text(
                  _timeAgo(post.createdAt),
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(post.content,
                style: const TextStyle(color: Colors.white, fontSize: 14)),
            // FEATURE (U6): Like + Kommentar.
            CommunityActionsBar(post: post, accent: _cyan),
          ],
        ),
      ),
    );
  }
}
