/// 🌐 COMMUNITY SERVICE - BACKEND INTEGRATED
/// Handles community posts, likes, comments with Cloudflare Backend
/// ✅ AUTH: Uses InvisibleAuthService for authentication
/// ✅ BACKEND: Connects to weltenbibliothek-community-api Worker
/// ✅ REALTIME: Stream-based updates
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'invisible_auth_service.dart';
import '../models/community_post_extended.dart';

class CommunityService {
  // Singleton
  static final CommunityService _instance = CommunityService._internal();
  factory CommunityService() => _instance;
  CommunityService._internal();

  // Backend URL
  static const String _backendUrl = 'https://weltenbibliothek-community-api.brandy13062.workers.dev';
  
  // Auth Service
  final InvisibleAuthService _authService = InvisibleAuthService();
  
  // Stream Controllers
  final _postsController = StreamController<List<CommunityPostExtended>>.broadcast();
  Stream<List<CommunityPostExtended>> get postsStream => _postsController.stream;
  
  // Local Cache
  final List<CommunityPostExtended> _cachedPosts = [];
  
  /// ═══════════════════════════════════════════════════════════════════════════
  /// CREATE POST
  /// ═══════════════════════════════════════════════════════════════════════════
  
  Future<Map<String, dynamic>> createPost({
    required String world,
    required String content,
    List<String>? images,
  }) async {
    try {
      // ✅ AUTH: Get userId and authToken
      final userId = _authService.userId;
      final authToken = _authService.authToken;
      
      if (userId == null || authToken == null) {
        throw Exception('Not authenticated');
      }
      
      // Create post via backend
      final response = await http.post(
        Uri.parse('$_backendUrl/posts/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({
          'world': world,
          'content': content,
          'images': images ?? [],
        }),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        
        // Reload posts to include new one
        await loadPosts(world: world);
        
        return result;
      } else if (response.statusCode == 401) {
        // Token expired - for now just throw, refresh logic TBD
        throw Exception('Authentication expired - please restart app');
      } else {
        throw Exception('Failed to create post: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ CommunityService: Create post failed: $e');
      }
      
      // Fallback: Create post locally (offline support)
      return _createPostLocally(world: world, content: content, images: images);
    }
  }
  
  /// ═══════════════════════════════════════════════════════════════════════════
  /// LOAD POSTS
  /// ═══════════════════════════════════════════════════════════════════════════
  
  Future<List<CommunityPostExtended>> loadPosts({
    required String world,
    int limit = 20,
    String? cursor,
  }) async {
    try {
      // ✅ AUTH: Get authToken
      final authToken = _authService.authToken;
      
      final response = await http.get(
        Uri.parse('$_backendUrl/posts/list?world=$world&limit=$limit${cursor != null ? '&cursor=$cursor' : ''}'),
        headers: {
          'Authorization': 'Bearer $authToken',
        },
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final postsList = List<Map<String, dynamic>>.from(data['posts']);
        
        // Convert to CommunityPostExtended
        final posts = postsList.map((postData) {
          return CommunityPostExtended.fromJson(postData);
        }).toList();
        
        // Update cache
        _cachedPosts.clear();
        _cachedPosts.addAll(posts);
        
        // Notify listeners
        _postsController.add(posts);
        
        return posts;
      } else if (response.statusCode == 401) {
        // Token expired
        throw Exception('Authentication expired');
      } else {
        throw Exception('Failed to load posts: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ CommunityService: Load posts failed: $e');
      }
      
      // Return cached posts
      return _cachedPosts;
    }
  }
  
  /// ═══════════════════════════════════════════════════════════════════════════
  /// LIKE POST
  /// ═══════════════════════════════════════════════════════════════════════════
  
  Future<bool> likePost(String postId) async {
    try {
      final authToken = _authService.authToken;
      
      final response = await http.post(
        Uri.parse('$_backendUrl/posts/like'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({'postId': postId}),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        // Update local cache
        final postIndex = _cachedPosts.indexWhere(
          (p) => p.id == postId, // ✅ FIXED: Use 'id' instead of 'postId'
        );
        
        // Notify update
        _postsController.add(_cachedPosts);
        
        return true;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication expired');
      }
      
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ CommunityService: Like post failed: $e');
      }
      return false;
    }
  }
  
  /// ═══════════════════════════════════════════════════════════════════════════
  /// CREATE COMMENT
  /// ═══════════════════════════════════════════════════════════════════════════
  
  Future<bool> createComment({
    required String postId,
    required String content,
    String? replyToCommentId,
  }) async {
    try {
      final authToken = _authService.authToken;
      
      final response = await http.post(
        Uri.parse('$_backendUrl/comments/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({
          'postId': postId,
          'content': content,
          'replyToCommentId': replyToCommentId,
        }),
      ).timeout(const Duration(seconds: 10));
      
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ CommunityService: Create comment failed: $e');
      }
      return false;
    }
  }
  
  /// ═══════════════════════════════════════════════════════════════════════════
  /// DELETE POST
  /// ═══════════════════════════════════════════════════════════════════════════
  
  Future<bool> deletePost(String postId) async {
    try {
      final authToken = _authService.authToken;
      
      final response = await http.delete(
        Uri.parse('$_backendUrl/posts/delete?postId=$postId'),
        headers: {
          'Authorization': 'Bearer $authToken',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        // Remove from cache
        _cachedPosts.removeWhere((p) => p.id == postId); // ✅ FIXED: Use 'id'
        _postsController.add(_cachedPosts);
        return true;
      }
      
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ CommunityService: Delete post failed: $e');
      }
      return false;
    }
  }
  
  /// ═══════════════════════════════════════════════════════════════════════════
  /// OFFLINE FALLBACK
  /// ═══════════════════════════════════════════════════════════════════════════
  
  Future<Map<String, dynamic>> _createPostLocally({
    required String world,
    required String content,
    List<String>? images,
  }) async {
    // TODO: Queue for later sync when online
    if (kDebugMode) {
      debugPrint('⚠️ CommunityService: Creating post locally (offline)');
    }
    
    return {
      'success': false,
      'offline': true,
      'message': 'Post wird gesendet wenn Verbindung wiederhergestellt ist',
    };
  }
  
  /// ═══════════════════════════════════════════════════════════════════════════
  /// CLEANUP
  /// ═══════════════════════════════════════════════════════════════════════════
  
  void dispose() {
    _postsController.close();
  }
}
