import '../config/api_config.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Community Interaction Service
/// Handles Likes, Comments, Shares with Cloudflare D1 Backend + Local Cache
class CommunityInteractionService {
  // Backend URLs
  static const String _backendUrl = ApiConfig.workerUrl;
  
  // SharedPreferences key prefixes
  static const String _pfxLike     = 'ci_like_';       // ci_like_{userId}_{postId} → bool
  static const String _pfxCount    = 'ci_count_';      // ci_count_{postId} → int
  static const String _pfxComments = 'ci_comments_';   // ci_comments_{postId} → JSON

  // Singleton
  static final CommunityInteractionService _instance =
      CommunityInteractionService._internal();
  factory CommunityInteractionService() => _instance;
  CommunityInteractionService._internal();

  /// No-op – SharedPreferences needs no explicit init
  Future<void> init() async {}
  
  // ============================================
  // LIKE SYSTEM
  // ============================================
  
  /// Toggle like on a post (Like/Unlike)
  Future<bool> toggleLike({
    required String postId,
    required String userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final likeKey = '$_pfxLike${userId}_$postId';
    final isLiked = prefs.getBool(likeKey) ?? false;

    try {
      await prefs.setBool(likeKey, !isLiked);

      final endpoint = isLiked ? 'unlike' : 'like';
      final response = await http.post(
        Uri.parse('$_backendUrl/api/community/$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'post_id': postId, 'user_id': userId}),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Like toggle timeout'),
      );

      if (response.statusCode == 200) {
        if (kDebugMode) debugPrint('✅ Like toggled: $postId (${!isLiked})');
        await _updateLikeCountCache(postId, !isLiked);
        return !isLiked;
      } else {
        await prefs.setBool(likeKey, isLiked);
        if (kDebugMode) debugPrint('⚠️ Like toggle failed: ${response.statusCode}');
        return isLiked;
      }
    } catch (e) {
      await prefs.setBool(likeKey, isLiked);
      if (kDebugMode) debugPrint('❌ Like error: $e');
      return isLiked;
    }
  }
  
  /// Check if user has liked a post (sync, from local cache)
  bool isLiked({required String postId, required String userId}) {
    // Synchronous read – not available from SharedPreferences; always false until async load.
    // Callers should use fetchIsLiked() for accurate state.
    return false;
  }

  /// Check if user has liked a post (async, from Supabase with cache fallback)
  Future<bool> fetchIsLiked({
    required String postId,
    required String userId,
  }) async {
    if (userId.isEmpty || postId.isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    final likeKey = '$_pfxLike${userId}_$postId';
    try {
      final supabase = Supabase.instance.client;
      final result = await supabase
          .from('likes')
          .select('id')
          .eq('article_id', postId)
          .eq('user_id', userId)
          .limit(1)
          .timeout(const Duration(seconds: 5));
      final liked = (result as List).isNotEmpty;
      await prefs.setBool(likeKey, liked);
      return liked;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ fetchIsLiked fallback to cache: $e');
      return prefs.getBool(likeKey) ?? false;
    }
  }

  /// Toggle like via Supabase directly (with optimistic UI support)
  Future<bool> toggleLikeSupabase({
    required String postId,
    required String userId,
  }) async {
    if (userId.isEmpty || postId.isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    final likeKey = '$_pfxLike${userId}_$postId';
    final currentlyLiked = prefs.getBool(likeKey) ?? false;
    await prefs.setBool(likeKey, !currentlyLiked);
    try {
      final supabase = Supabase.instance.client;
      if (currentlyLiked) {
        await supabase.from('likes').delete()
            .eq('article_id', postId).eq('user_id', userId);
      } else {
        await supabase.from('likes').insert({'article_id': postId, 'user_id': userId});
      }
      return !currentlyLiked;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ toggleLikeSupabase error: $e');
      await prefs.setBool(likeKey, currentlyLiked);
      return currentlyLiked;
    }
  }
  
  /// Get like count for a post (Supabase preferred, then cache)
  Future<int> getLikeCount(String postId) async {
    if (postId.isEmpty) return 0;
    final prefs = await SharedPreferences.getInstance();
    final countKey = '$_pfxCount$postId';

    try {
      final supabase = Supabase.instance.client;
      final result = await supabase
          .from('likes').select('id').eq('article_id', postId)
          .timeout(const Duration(seconds: 5));
      final count = (result as List).length;
      await prefs.setInt(countKey, count);
      return count;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ getLikeCount Supabase failed, trying cache: $e');
    }

    final cached = prefs.getInt(countKey);
    if (cached != null) return cached;

    try {
      final response = await http.get(
        Uri.parse('$_backendUrl/api/community/likes/$postId'),
      ).timeout(const Duration(seconds: 5),
          onTimeout: () => throw TimeoutException('Get like count timeout'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final count = data['count'] as int? ?? 0;
        await prefs.setInt(countKey, count);
        return count;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Failed to fetch like count: $e');
    }

    return 0;
  }

  Future<void> _updateLikeCountCache(String postId, bool increment) async {
    final prefs = await SharedPreferences.getInstance();
    final countKey = '$_pfxCount$postId';
    final current = prefs.getInt(countKey) ?? 0;
    final newCount = increment ? current + 1 : current - 1;
    await prefs.setInt(countKey, newCount > 0 ? newCount : 0);
  }
  
  // ============================================
  // COMMENT SYSTEM
  // ============================================
  
  /// Add comment to a post
  Future<bool> addComment({
    required String postId,
    required String userId,
    required String username,
    required String text,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/api/community/comment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'post_id': postId,
          'user_id': userId,
          'username': username,
          'text': text,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Add comment timeout'),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (kDebugMode) {
          debugPrint('✅ Comment added: $postId');
        }
        
        // Cache comment locally
        await _cacheComment(postId, {
          'user_id': userId,
          'username': username,
          'text': text,
          'timestamp': DateTime.now().toIso8601String(),
        });
        
        return true;
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ Comment failed: ${response.statusCode}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Comment error: $e');
      }
      return false;
    }
  }
  
  /// Get comments for a post
  Future<List<Map<String, dynamic>>> getComments(String postId) async {
    try {
      final response = await http.get(
        Uri.parse('$_backendUrl/api/community/comments/$postId'),
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('Get comments timeout'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final comments = (data['comments'] as List?)
            ?.map((c) => c as Map<String, dynamic>)
            .toList() ?? [];
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('$_pfxComments$postId', jsonEncode(comments));
        return comments;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Failed to fetch comments: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_pfxComments$postId');
    if (raw != null) {
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<void> _cacheComment(String postId, Map<String, dynamic> comment) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_pfxComments$postId');
    final comments = raw != null
        ? (jsonDecode(raw) as List).cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];
    comments.add(comment);
    await prefs.setString('$_pfxComments$postId', jsonEncode(comments));
  }
  
  /// Get comment count for a post
  Future<int> getCommentCount(String postId) async {
    final comments = await getComments(postId);
    return comments.length;
  }
  
  // ============================================
  // SHARE SYSTEM
  // ============================================
  
  /// Track share action (analytics)
  Future<void> trackShare({
    required String postId,
    required String userId,
    required String platform,
  }) async {
    try {
      await http.post(
        Uri.parse('$_backendUrl/api/community/share'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'post_id': postId,
          'user_id': userId,
          'platform': platform,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('Track share timeout'),
      );
      
      if (kDebugMode) {
        debugPrint('✅ Share tracked: $postId on $platform');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Share tracking failed: $e');
      }
    }
  }
  
  // ============================================
  // BATCH OPERATIONS
  // ============================================
  
  /// Preload likes for multiple posts (batch optimization)
  Future<void> preloadLikes(List<String> postIds, String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/api/community/likes/batch'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'post_ids': postIds, 'user_id': userId}),
      ).timeout(const Duration(seconds: 10),
          onTimeout: () => throw TimeoutException('Preload likes timeout'));

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        final data = jsonDecode(response.body);
        final likes  = data['likes']  as Map<String, dynamic>?;
        final counts = data['counts'] as Map<String, dynamic>?;
        if (likes != null) {
          for (final e in likes.entries) {
            await prefs.setBool('$_pfxLike${userId}_${e.key}', e.value as bool);
          }
        }
        if (counts != null) {
          for (final e in counts.entries) {
            await prefs.setInt('$_pfxCount${e.key}', e.value as int);
          }
        }
        if (kDebugMode) debugPrint('✅ Preloaded ${postIds.length} likes');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Batch preload failed: $e');
    }
  }
  
  // ============================================
  // UTILITIES
  // ============================================
  
  /// Clear all caches (for logout/reset)
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys().toList()) {
      if (key.startsWith(_pfxLike) ||
          key.startsWith(_pfxCount) ||
          key.startsWith(_pfxComments)) {
        await prefs.remove(key);
      }
    }
    if (kDebugMode) debugPrint('✅ Community cache cleared');
  }
  
  /// Get user statistics
  Future<Map<String, int>> getUserStats(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_backendUrl/api/community/user/$userId/stats'),
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('Get user stats timeout'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'total_likes_given': data['total_likes_given'] ?? 0,
          'total_comments': data['total_comments'] ?? 0,
          'total_shares': data['total_shares'] ?? 0,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Stats fetch failed: $e');
      }
    }
    
    return {
      'total_likes_given': 0,
      'total_comments': 0,
      'total_shares': 0,
    };
  }
}
