import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/community_post.dart';
import 'supabase_service.dart';

/// SupabaseCommunityService – direct Supabase backend for community posts.
/// Replaces the old Cloudflare-based CommunityService.
class SupabaseCommunityService {
  static final SupabaseCommunityService _instance =
      SupabaseCommunityService._internal();
  factory SupabaseCommunityService() => _instance;
  SupabaseCommunityService._internal();

  final _db = Supabase.instance.client;

  // ── Posts ─────────────────────────────────────────────────────────────────

  /// Load posts for a world (newest first).
  Future<List<CommunityPost>> fetchPosts({
    required WorldType worldType,
    int limit = 30,
  }) async {
    try {
      final worldStr = worldType == WorldType.materie ? 'materie' : 'energie';
      final rows = await _db
          .from('community_posts')
          .select()
          .eq('world_type', worldStr)
          .order('created_at', ascending: false)
          .limit(limit);

      return (rows as List).map((r) => _rowToPost(r)).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [Community] fetchPosts error: $e');
      return [];
    }
  }

  /// Supabase stream of posts (realtime updates).
  Stream<List<CommunityPost>> streamPosts({required WorldType worldType}) {
    final worldStr = worldType == WorldType.materie ? 'materie' : 'energie';
    return _db
        .from('community_posts')
        .stream(primaryKey: ['id'])
        .eq('world_type', worldStr)
        .order('created_at', ascending: false)
        .limit(30)
        .map((rows) => rows.map((r) => _rowToPost(r)).toList());
  }

  /// Create a new post.
  Future<void> createPost({
    required String content,
    required WorldType worldType,
    List<String> tags = const [],
    String? mediaUrl,
    String? mediaType,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Nicht eingeloggt');

    final meta = user.userMetadata;
    final username = meta?['username'] as String? ?? 'Anonym';
    final avatar = meta?['avatar'] as String? ?? '👤';
    final worldStr = worldType == WorldType.materie ? 'materie' : 'energie';

    await _db.from('community_posts').insert({
      'user_id':    user.id,
      'username':   username,
      'avatar':     avatar,
      'content':    content,
      'world_type': worldStr,
      'tags':       tags,
      'media_url':  mediaUrl,
      'media_type': mediaType,
      'likes_count':    0,
      'comments_count': 0,
    });
  }

  // ── Likes ─────────────────────────────────────────────────────────────────

  /// Toggle like for a post. Returns new like state (true = liked).
  Future<bool> toggleLike(String postId) async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) throw Exception('Nicht eingeloggt');

    final existing = await _db
        .from('post_likes')
        .select('id')
        .eq('post_id', postId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existing != null) {
      // Unlike
      await _db
          .from('post_likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', userId);
      await _db.rpc('decrement_likes', params: {'p_post_id': postId})
          .catchError((_) async {
        await _db
            .from('community_posts')
            .update({'likes_count': 0})
            .eq('id', postId);
        return null;
      });
      return false;
    } else {
      // Like
      await _db.from('post_likes').insert({
        'post_id': postId,
        'user_id': userId,
      });
      await _db.rpc('increment_likes', params: {'p_post_id': postId})
          .catchError((_) async {
        return null;
      });
      return true;
    }
  }

  /// Check if current user liked a post.
  Future<bool> hasLiked(String postId) async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return false;
    final row = await _db
        .from('post_likes')
        .select('id')
        .eq('post_id', postId)
        .eq('user_id', userId)
        .maybeSingle();
    return row != null;
  }

  // ── Comments ──────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getComments(String postId) async {
    try {
      final rows = await _db
          .from('post_comments')
          .select()
          .eq('post_id', postId)
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [Community] getComments error: $e');
      return [];
    }
  }

  Future<void> addComment({
    required String postId,
    required String text,
  }) async {
    final user = _db.auth.currentUser;
    if (user == null) throw Exception('Nicht eingeloggt');

    final meta = user.userMetadata;
    await _db.from('post_comments').insert({
      'post_id':  postId,
      'user_id':  user.id,
      'username': meta?['username'] as String? ?? 'Anonym',
      'avatar':   meta?['avatar'] as String? ?? '👤',
      'text':     text,
    });
  }

  // ── Edit / Delete ─────────────────────────────────────────────────────────

  Future<void> editPost(
    String postId, {
    required String content,
    List<String> tags = const [],
  }) async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) throw Exception('Nicht eingeloggt');
    await _db
        .from('community_posts')
        .update({'content': content, 'tags': tags})
        .eq('id', postId)
        .eq('user_id', userId);
  }

  Future<void> deletePost(String postId, String username) async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) throw Exception('Nicht eingeloggt');
    await _db
        .from('community_posts')
        .delete()
        .eq('id', postId)
        .eq('user_id', userId);
  }

  // ── Trending Tags ─────────────────────────────────────────────────────────

  /// Returns top trending tags for a world (by occurrence count).
  Future<List<Map<String, dynamic>>> getTrendingTags({
    required WorldType worldType,
    int limit = 10,
  }) async {
    try {
      final worldStr = worldType == WorldType.materie ? 'materie' : 'energie';
      final rows = await _db
          .from('community_posts')
          .select('tags')
          .eq('world_type', worldStr)
          .order('created_at', ascending: false)
          .limit(200);

      final tagCount = <String, int>{};
      for (final row in (rows as List)) {
        final tags = row['tags'];
        if (tags is List) {
          for (final t in tags) {
            final tag = t.toString();
            if (tag.isNotEmpty) tagCount[tag] = (tagCount[tag] ?? 0) + 1;
          }
        }
      }

      final sorted = tagCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sorted.take(limit).map((e) => {
        'tag':   e.key,
        'count': e.value,
      }).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [Community] getTrendingTags error: $e');
      return [];
    }
  }

  // ── Helper ────────────────────────────────────────────────────────────────

  CommunityPost _rowToPost(Map<String, dynamic> r) {
    final worldStr = r['world_type'] as String? ?? 'materie';
    final worldType =
        worldStr == 'energie' ? WorldType.energie : WorldType.materie;

    List<String> tags = [];
    final rawTags = r['tags'];
    if (rawTags is List) tags = rawTags.map((t) => t.toString()).toList();

    return CommunityPost(
      id:             r['id']?.toString() ?? '',
      authorUsername: r['username'] as String? ?? 'Anonym',
      authorAvatar:   r['avatar'] as String? ?? '👤',
      content:        r['content'] as String? ?? '',
      createdAt:      r['created_at'] != null
          ? DateTime.parse(r['created_at'] as String)
          : DateTime.now(),
      likes:          (r['likes_count'] as num?)?.toInt() ?? 0,
      comments:       (r['comments_count'] as num?)?.toInt() ?? 0,
      shares:         0,
      tags:           tags,
      worldType:      worldType,
      mediaUrl:       r['media_url'] as String?,
      mediaType:      r['media_type'] as String?,
    );
  }
}
