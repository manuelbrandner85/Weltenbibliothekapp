import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';

/// Community Interaction Service
/// Handles Likes, Comments, Shares with Cloudflare D1 Backend + Local Cache
class CommunityInteractionService {
  // Backend URLs
  static const String _backendUrl = 'https://api-backend.brandy13062.workers.dev';
  
  // Hive Boxes
  static const String _likesBox = 'user_likes';
  static const String _commentsBox = 'post_comments';
  static const String _likeCacheBox = 'like_cache';
  
  // Singleton
  static final CommunityInteractionService _instance = 
      CommunityInteractionService._internal();
  factory CommunityInteractionService() => _instance;
  CommunityInteractionService._internal();
  
  /// Initialize Hive boxes
  Future<void> init() async {
    await Hive.openBox(_likesBox);
    await Hive.openBox(_commentsBox);
    await Hive.openBox(_likeCacheBox);
  }
  
  // ============================================
  // LIKE SYSTEM
  // ============================================
  
  /// Toggle like on a post (Like/Unlike)
  Future<bool> toggleLike({
    required String postId,
    required String userId,
  }) async {
    final box = Hive.box(_likesBox);
    final likeKey = '${userId}_$postId';
    final isLiked = box.get(likeKey, defaultValue: false);
    
    try {
      // Toggle local state
      await box.put(likeKey, !isLiked);
      
      // Sync with backend
      final endpoint = isLiked ? 'unlike' : 'like';
      final response = await http.post(
        Uri.parse('$_backendUrl/api/community/$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'post_id': postId,
          'user_id': userId,
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        if (kDebugMode) {
          debugPrint('✅ Like toggled: $postId (${!isLiked})');
        }
        
        // Update like count cache
        await _updateLikeCountCache(postId, !isLiked);
        
        return !isLiked;
      } else {
        // Rollback on failure
        await box.put(likeKey, isLiked);
        if (kDebugMode) {
          debugPrint('⚠️ Like toggle failed: ${response.statusCode}');
        }
        return isLiked;
      }
    } catch (e) {
      // Rollback on error
      await box.put(likeKey, isLiked);
      if (kDebugMode) {
        debugPrint('❌ Like error: $e');
      }
      return isLiked;
    }
  }
  
  /// Check if user has liked a post
  bool isLiked({
    required String postId,
    required String userId,
  }) {
    final box = Hive.box(_likesBox);
    final likeKey = '${userId}_$postId';
    return box.get(likeKey, defaultValue: false);
  }
  
  /// Get like count for a post (with cache)
  Future<int> getLikeCount(String postId) async {
    final cacheBox = Hive.box(_likeCacheBox);
    
    // Check cache first
    final cached = cacheBox.get(postId);
    if (cached != null) {
      return cached as int;
    }
    
    // Fetch from backend
    try {
      final response = await http.get(
        Uri.parse('$_backendUrl/api/community/likes/$postId'),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final count = data['count'] ?? 0;
        
        // Cache result
        await cacheBox.put(postId, count);
        
        return count;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to fetch like count: $e');
      }
    }
    
    return 0;
  }
  
  /// Update like count cache
  Future<void> _updateLikeCountCache(String postId, bool increment) async {
    final cacheBox = Hive.box(_likeCacheBox);
    final current = cacheBox.get(postId, defaultValue: 0) as int;
    final newCount = increment ? current + 1 : current - 1;
    await cacheBox.put(postId, newCount > 0 ? newCount : 0);
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
      ).timeout(const Duration(seconds: 10));
      
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
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final comments = (data['comments'] as List?)
            ?.map((c) => c as Map<String, dynamic>)
            .toList() ?? [];
        
        // Cache comments
        final box = Hive.box(_commentsBox);
        await box.put(postId, comments);
        
        return comments;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to fetch comments: $e');
      }
    }
    
    // Return cached comments on failure
    final box = Hive.box(_commentsBox);
    final cached = box.get(postId);
    if (cached != null) {
      return (cached as List).map((c) => c as Map<String, dynamic>).toList();
    }
    
    return [];
  }
  
  /// Cache comment locally
  Future<void> _cacheComment(String postId, Map<String, dynamic> comment) async {
    final box = Hive.box(_commentsBox);
    final existing = box.get(postId, defaultValue: <Map<String, dynamic>>[]);
    final comments = (existing as List).map((c) => c as Map<String, dynamic>).toList();
    comments.add(comment);
    await box.put(postId, comments);
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
      ).timeout(const Duration(seconds: 5));
      
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
    final box = Hive.box(_likesBox);
    final cacheBox = Hive.box(_likeCacheBox);
    
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/api/community/likes/batch'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'post_ids': postIds,
          'user_id': userId,
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final likes = data['likes'] as Map<String, dynamic>?;
        final counts = data['counts'] as Map<String, dynamic>?;
        
        // Cache likes
        if (likes != null) {
          for (final entry in likes.entries) {
            final likeKey = '${userId}_${entry.key}';
            await box.put(likeKey, entry.value);
          }
        }
        
        // Cache counts
        if (counts != null) {
          for (final entry in counts.entries) {
            await cacheBox.put(entry.key, entry.value);
          }
        }
        
        if (kDebugMode) {
          debugPrint('✅ Preloaded ${postIds.length} likes');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Batch preload failed: $e');
      }
    }
  }
  
  // ============================================
  // UTILITIES
  // ============================================
  
  /// Clear all caches (for logout/reset)
  Future<void> clearCache() async {
    await Hive.box(_likesBox).clear();
    await Hive.box(_commentsBox).clear();
    await Hive.box(_likeCacheBox).clear();
    
    if (kDebugMode) {
      debugPrint('✅ Community cache cleared');
    }
  }
  
  /// Get user statistics
  Future<Map<String, int>> getUserStats(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_backendUrl/api/community/user/$userId/stats'),
      ).timeout(const Duration(seconds: 5));
      
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
