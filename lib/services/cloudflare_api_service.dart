import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import 'local_chat_storage_service.dart';
import 'supabase_service.dart'; // 🔥 Supabase Client für Direct Fallback

/// Cloudflare API Service für Weltenbibliothek
/// Ersetzt Firebase Firestore mit Cloudflare D1 + Workers
/// 
/// ✅ PRODUCTION MODE: Offline-First Chat mit lokaler Speicherung
class CloudflareApiService {
  // ✅ PRODUCTION MODE: Mock-Service deaktiviert
  
  // 📦 Local Chat Storage for offline-first functionality
  final LocalChatStorageService _localChat = LocalChatStorageService();
  
  // 🌐 API URLs - Centralized via ApiConfig
  // Migration Status: ✅ V2 Complete
  
  // Community API (Articles, Users, Analytics)
  // Note: Separate Worker, will migrate when community-v2 available
  static String get baseUrl => ApiConfig.workerUrl;
  
  // Main API (Chat + Knowledge + WebSocket) - Using Deployed WebSocket Worker
  // FIXED: Use actual deployed worker name
  static String get mainApiUrl => ApiConfig.workerUrl;
  
  // Media Upload API (R2 Storage)
  // Note: Separate Worker, will migrate when media-v2 available
  static String get mediaApiUrl => ApiConfig.workerUrl;
  
  // Chat Features API (Reactions, Read Receipts, Polls)
  // Note: Separate Worker, will migrate when chat-features-v2 available
  static String get chatFeaturesApiUrl => ApiConfig.workerUrl;
  
  // Chat Reactions API (Redirect to Chat Features)
  static String get reactionsApiUrl => chatFeaturesApiUrl;
  
  // ⚠️ SECURITY: API Token from ApiConfig
  // Set CLOUDFLARE_API_TOKEN environment variable before building
  // For development: Use --dart-define=CLOUDFLARE_API_TOKEN=your_token_here
  static String get apiToken {
    // Try environment variable first
    const envToken = String.fromEnvironment('CLOUDFLARE_API_TOKEN', defaultValue: '');
    if (envToken.isNotEmpty) {
      return envToken;
    }
    // Fallback to ApiConfig token
    return ApiConfig.cloudflareApiToken;
  }
  
  // Singleton Pattern
  static final CloudflareApiService _instance = CloudflareApiService._internal();
  factory CloudflareApiService() => _instance;
  CloudflareApiService._internal();
  
  // Gemeinsame Headers (MIT Authorization für authentifizierte Requests)
  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    // Add Authorization if token is available
    if (apiToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $apiToken';
    }
    
    return headers;
  }

  // ═══════════════════════════════════════════════════════════
  // ARTICLE METHODS
  // ═══════════════════════════════════════════════════════════

  /// Get articles with optional filters
  Future<List<Map<String, dynamic>>> getArticles({
    String? realm,
    String? category,
    int limit = 20,
    int offset = 0,
  }) async {
    final params = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    
    if (realm != null) params['realm'] = realm;
    if (category != null) params['category'] = category;

    final uri = Uri.parse('$baseUrl/api/articles').replace(queryParameters: params);
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load articles: ${response.statusCode}');
    }
  }

  /// Get single article by ID
  Future<Map<String, dynamic>> getArticle(String articleId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/articles/$articleId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load article: ${response.statusCode}');
    }
  }

  /// Create new article
  Future<Map<String, dynamic>> createArticle(Map<String, dynamic> articleData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/articles'),
      headers: _headers,
      body: json.encode(articleData),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create article: ${response.statusCode}');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // CHAT METHODS
  // ═══════════════════════════════════════════════════════════

  /// Get chat messages for a room
  Future<List<Map<String, dynamic>>> getChatMessages(
    String roomId, {
    String? realm,
    int limit = 50,
  }) async {
    if (kDebugMode) {
      debugPrint('💬 getChatMessages: room=$roomId realm=$realm limit=$limit');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 1️⃣ PRIMARY: Supabase direct query (no worker join-issue)
    // ─────────────────────────────────────────────────────────────────────────
    try {
      final supaResult = await supabase
          .from('chat_messages')
          .select(
              'id,room_id,user_id,username,avatar_url,content,message,message_type,created_at,is_deleted')
          .eq('room_id', roomId)
          .eq('is_deleted', false)
          .order('created_at', ascending: true)
          .limit(limit);

      final supaMessages = (supaResult as List<dynamic>)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .where((m) => m['is_deleted'] != true)
          .map((m) => {
                ...m,
                'id': m['id'],             // ✅ immer vorhanden für Edit/Delete
                'message_id': m['id'],     // ✅ Alias für Edit/Delete-Aufrufe
                'userId': m['user_id'],
                'user_id': m['user_id'],
                'timestamp': m['created_at'],
                'created_at': m['created_at'],
                'avatarEmoji': m['avatar_emoji'] ?? '👤',
                'message': m['message'] ?? m['content'] ?? '',
                'content': m['content'] ?? m['message'] ?? '',
                'deleted': false,
              })
          .toList();

      if (kDebugMode) {
        debugPrint('✅ Supabase direct: ${supaMessages.length} messages for $roomId');
      }
      return supaMessages;
    } catch (supaErr) {
      if (kDebugMode) {
        debugPrint('⚠️ Supabase direct failed: $supaErr – trying Worker fallback...');
      }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 2️⃣ FALLBACK: Cloudflare Worker API
    // ─────────────────────────────────────────────────────────────────────────
    final queryParams = {
      'room': roomId,
      'realm': realm ?? 'energie',
      'limit': limit.toString(),
    };
    final uri = Uri.parse('$mainApiUrl/api/chat/messages')
        .replace(queryParameters: queryParams);

    try {
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> messages = data['messages'] ?? [];

        if (kDebugMode) {
          debugPrint('✅ Worker messages: ${messages.length} for $roomId');
        }

        return messages
            .map((e) => e as Map<String, dynamic>)
            .where((msg) => msg['deleted'] != true)
            .map((msg) {
              final userId = msg['userId'] ?? msg['user_id'];
              final timestamp = msg['timestamp'] ?? msg['created_at'];
              return {
                ...msg,
                'userId': userId,
                'user_id': userId,
                'timestamp': timestamp,
                'created_at': timestamp,
                'avatarEmoji': msg['avatarEmoji'] ?? msg['avatar_emoji'] ?? '👤',
                'message': msg['message'] ?? msg['content'] ?? '',
                'content': msg['content'] ?? msg['message'] ?? '',
              };
            })
            .toList();
      }
    } catch (workerErr) {
      if (kDebugMode) {
        debugPrint('⚠️ Worker also failed: $workerErr');
      }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 3️⃣ LAST RESORT: Local storage
    // ─────────────────────────────────────────────────────────────────────────
    try {
      final messages = await _localChat.getMessages(
        roomId,
        realm ?? 'energie',
        limit: limit,
      );
      if (kDebugMode) {
        debugPrint('✅ Local storage: ${messages.length} messages (last resort)');
      }
      return messages;
    } catch (_) {
      return [];
    }
  }

  /// Send chat message – 🟢 Supabase-only (gem. Zielarchitektur v2.0).
  /// Erfordert eingeloggten User (SupabaseAuth). Tool-Bot-Posts (userId == 'tool_bot')
  /// sind als einzige Ausnahme anonym erlaubt.
  Future<Map<String, dynamic>> sendChatMessage({
    required String roomId,
    required String realm,
    required String userId,
    required String username,
    required String message,
    String? avatarEmoji,
    String? avatarUrl,
    String? mediaType,
    String? mediaUrl,
  }) async {
    if (kDebugMode) debugPrint('💬 [Chat] Send: $username → $roomId');

    final isBot = userId == 'tool_bot';
    final messageType = switch (mediaType) {
      'audio' => 'voice',
      'image' => 'image',
      'file'  => 'file',
      _       => null,
    };

    try {
      final result = await SupabaseChatService.instance.sendMessage(
        roomId: roomId,
        message: message,
        username: username,
        avatarUrl: avatarUrl,
        messageType: messageType,
        allowAnonymous: isBot,
      );
      if (kDebugMode) debugPrint('✅ [Chat] Supabase insert OK: ${result['id']}');
      return Map<String, dynamic>.from(result);
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [Chat] Send failed: $e');
      rethrow;
    }
  }

  /// 🆕 Sende Tool-Aktivitäts-Nachricht im Chat
  /// Postet automatisch, wenn ein User ein Tool nutzt
  Future<void> sendToolActivityMessage({
    required String roomId,
    required String realm,
    required String username,
    required String toolName,
    required String activity,
  }) async {
    try {
      // Emoji-Mapping für Tools
      final toolEmojis = {
        'debatte': '🗳️',
        'zeitleiste': '📜',
        'sichtungen': '🛸',
        'recherche': '🔍',
        'experiment': '🔬',
        'session': '🧘',
        'traumanalyse': '✨',
        'energie': '🌈',
        'weisheit': '🕉️',
        'heilung': '💚',
      };
      
      final emoji = toolEmojis[toolName] ?? '🛠️';
      final message = '$emoji $username nutzt $toolName: $activity';
      
      await sendChatMessage(
        roomId: roomId,
        realm: realm,
        userId: 'tool_bot',
        username: '🤖 Tool-Bot',
        message: message,
      );
    } catch (e) {
      debugPrint('⚠️ Tool-Aktivitäts-Nachricht konnte nicht gesendet werden: $e');
      // Fehler wird ignoriert, damit Tool-Nutzung nicht blockiert wird
    }
  }

  /// Edit chat message – 🟢 Supabase-only (RLS prüft Ownership / Admin).
  Future<Map<String, dynamic>> editChatMessage({
    required String roomId,
    required String messageId,
    required String userId,
    required String username,
    required String newMessage,
    String? realm,
    bool? isAdmin,
  }) async {
    if (kDebugMode) debugPrint('🔧 [Chat] Edit: $messageId');
    try {
      final result = await SupabaseChatService.instance.editMessage(
        messageId: messageId,
        newMessage: newMessage,
        isAdmin: isAdmin ?? false,
      );
      return {'success': true, 'message': result};
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [Chat] Edit failed: $e');
      rethrow;
    }
  }

  /// Delete chat message – 🟢 Supabase-only, soft-delete (is_deleted = true).
  Future<Map<String, dynamic>> deleteChatMessage({
    required String roomId,
    required String messageId,
    required String userId,
    required String username,
    String? realm,
    bool? isAdmin,
  }) async {
    if (kDebugMode) debugPrint('🗑️ [Chat] Delete: $messageId');
    try {
      await SupabaseChatService.instance.deleteMessage(
        messageId: messageId,
        isAdmin: isAdmin ?? false,
      );
      return {'success': true, 'message': 'Nachricht gelöscht'};
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [Chat] Delete failed: $e');
      rethrow;
    }
  }



  // ═══════════════════════════════════════════════════════════
  // USER METHODS
  // ═══════════════════════════════════════════════════════════

  /// Get user by ID
  Future<Map<String, dynamic>> getUser(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/users/$userId'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load user: ${response.statusCode}');
    }
  }

  /// Create new user
  Future<Map<String, dynamic>> createUser({
    required String username,
    String? email,
    String? avatarUrl,
    String realm = 'both',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/users'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'email': email,
        'avatar_url': avatarUrl,
        'realm': realm,
      }),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create user: ${response.statusCode}');
    }
  }

  /// Update user
  Future<void> updateUser(String userId, Map<String, dynamic> updates) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/users/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(updates),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update user: ${response.statusCode}');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // SAVED ARTICLES METHODS
  // ═══════════════════════════════════════════════════════════

  /// Get saved articles for user
  Future<List<Map<String, dynamic>>> getSavedArticles(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/saved/$userId'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load saved articles: ${response.statusCode}');
    }
  }

  /// Save article for user
  Future<void> saveArticle(String userId, String articleId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/saved'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': userId,
        'article_id': articleId,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to save article: ${response.statusCode}');
    }
  }

  /// Unsave article
  Future<void> unsaveArticle(String userId, String articleId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/saved/$userId/$articleId'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to unsave article: ${response.statusCode}');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // SEARCH METHODS
  // ═══════════════════════════════════════════════════════════

  /// Search content
  Future<List<Map<String, dynamic>>> search({
    required String query,
    String? realm,
    int limit = 20,
  }) async {
    final params = <String, String>{
      'q': query,
      'limit': limit.toString(),
    };
    
    if (realm != null) params['realm'] = realm;

    final uri = Uri.parse('$baseUrl/api/search').replace(queryParameters: params);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to search: ${response.statusCode}');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // USER CONTENT METHODS
  // ═══════════════════════════════════════════════════════════

  /// Get user content
  Future<List<Map<String, dynamic>>> getUserContent({
    String? realm,
    String? type,
    int limit = 20,
  }) async {
    final params = <String, String>{
      'limit': limit.toString(),
    };
    
    if (realm != null) params['realm'] = realm;
    if (type != null) params['type'] = type;

    final uri = Uri.parse('$baseUrl/api/content').replace(queryParameters: params);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load content: ${response.statusCode}');
    }
  }

  /// Create user content
  Future<Map<String, dynamic>> createUserContent(Map<String, dynamic> contentData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/content'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(contentData),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create content: ${response.statusCode}');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // NOTIFICATION METHODS
  // ═══════════════════════════════════════════════════════════

  /// Get notifications for user
  Future<List<Map<String, dynamic>>> getNotifications(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/notifications/$userId')
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Notification fetch timeout'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load notifications: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Keine Internetverbindung');
    } on TimeoutException {
      throw Exception('Anfrage dauert zu lange');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Get notifications error: $e');
      }
      rethrow;
    }
  }

  /// Create notification
  Future<void> createNotification(Map<String, dynamic> notificationData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/notifications'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(notificationData),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Create notification timeout'),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to create notification: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Keine Internetverbindung');
    } on TimeoutException {
      throw Exception('Anfrage dauert zu lange');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Create notification error: $e');
      }
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // LIKES & COMMENTS METHODS (NEW)
  // ═══════════════════════════════════════════════════════════

  /// Like an article
  Future<Map<String, dynamic>> likeArticle({
    required String articleId,
    required String userId,
    required String username,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/articles/$articleId/like'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'username': username,
        }),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Like article timeout'),
      );

      if (response.statusCode == 201 || response.statusCode == 409) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to like article: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Keine Internetverbindung');
    } on TimeoutException {
      throw Exception('Anfrage dauert zu lange');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Like article error: $e');
      }
      rethrow;
    }
  }

  /// Unlike an article
  Future<void> unlikeArticle({
    required String articleId,
    required String userId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/articles/$articleId/like?user_id=$userId'),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Unlike article timeout'),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to unlike article: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Keine Internetverbindung');
    } on TimeoutException {
      throw Exception('Anfrage dauert zu lange');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Unlike article error: $e');
      }
      rethrow;
    }
  }

  /// Get article likes
  Future<List<Map<String, dynamic>>> getArticleLikes(String articleId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/articles/$articleId/likes'),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Get likes timeout'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load likes: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Keine Internetverbindung');
    } on TimeoutException {
      throw Exception('Anfrage dauert zu lange');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Get likes error: $e');
      }
      rethrow;
    }
  }

  /// Get article comments
  Future<List<Map<String, dynamic>>> getArticleComments(String articleId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/articles/$articleId/comments'),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Get comments timeout'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load comments: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Keine Internetverbindung');
    } on TimeoutException {
      throw Exception('Anfrage dauert zu lange');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Get comments error: $e');
      }
      rethrow;
    }
  }

  /// Add comment to article
  Future<Map<String, dynamic>> addComment({
    required String articleId,
    required String userId,
    required String username,
    required String content,
    String? parentCommentId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/articles/$articleId/comments'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'username': username,
          'content': content,
          'parent_comment_id': parentCommentId,
        }),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Add comment timeout'),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to add comment: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Keine Internetverbindung');
    } on TimeoutException {
      throw Exception('Anfrage dauert zu lange');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Add comment error: $e');
      }
      rethrow;
    }
  }

  /// Edit comment
  Future<void> editComment({
    required String commentId,
    required String content,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/comments/$commentId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'content': content}),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Edit comment timeout'),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to edit comment: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Keine Internetverbindung');
    } on TimeoutException {
      throw Exception('Anfrage dauert zu lange');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Edit comment error: $e');
      }
      rethrow;
    }
  }

  /// Delete comment
  Future<void> deleteComment(String commentId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/comments/$commentId'),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Delete comment timeout'),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete comment: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Keine Internetverbindung');
    } on TimeoutException {
      throw Exception('Anfrage dauert zu lange');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Delete comment error: $e');
      }
      rethrow;
    }
  }

  /// Get article stats (likes, comments, views, shares)
  Future<Map<String, dynamic>> getArticleStats(String articleId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/articles/$articleId/stats'),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Get stats timeout'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load stats: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Keine Internetverbindung');
    } on TimeoutException {
      throw Exception('Anfrage dauert zu lange');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Get stats error: $e');
      }
      rethrow;
    }
  }

  /// Get user profile
  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/$userId/profile'),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Get profile timeout'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load profile: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Keine Internetverbindung');
    } on TimeoutException {
      throw Exception('Anfrage dauert zu lange');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Get profile error: $e');
      }
      rethrow;
    }
  }

  /// Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? bio,
    String? location,
    String? website,
    String? avatarUrl,
    String? bannerUrl,
    String? preferredRealm,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/users/$userId/profile'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'bio': bio,
        'location': location,
        'website': website,
        'avatar_url': avatarUrl,
        'banner_url': bannerUrl,
        'preferred_realm': preferredRealm,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update profile: ${response.statusCode}');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ANALYTICS METHODS
  // ═══════════════════════════════════════════════════════════

  /// Get analytics
  Future<List<Map<String, dynamic>>> getAnalytics({
    String realm = 'overall',
    String? date,
  }) async {
    final params = <String, String>{
      'realm': realm,
    };
    
    if (date != null) params['date'] = date;

    final uri = Uri.parse('$baseUrl/api/analytics').replace(queryParameters: params);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load analytics: ${response.statusCode}');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // MEDIA UPLOAD METHODS (R2 Storage)
  // ═══════════════════════════════════════════════════════════

  /// Upload media file (image/video) to R2 Storage
  /// Supports: JPG, PNG, WebP (images), MP4, WebM (videos)
  /// Max size: 5MB (images), 50MB (videos)
  Future<Map<String, dynamic>> uploadMedia({
    required List<int> fileBytes,
    required String fileName,
    required String mediaType, // 'image' or 'video'
    required String worldType,  // 'materie' or 'energie'
    required String username,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('🔼 Uploading media: $fileName ($mediaType) to $worldType');
      }
      
      final request = http.MultipartRequest(
        'POST', 
        Uri.parse('$mediaApiUrl/api/media/upload'),
      );
      
      // Add file
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
        ),
      );
      
      // Add metadata
      request.fields['media_type'] = mediaType;
      request.fields['world_type'] = worldType;
      request.fields['username'] = username;
      
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 201) {
        final result = json.decode(response.body);
        if (kDebugMode) {
          debugPrint('✅ Media uploaded: ${result['media_url']}');
        }
        return result;
      } else {
        if (kDebugMode) {
          debugPrint('❌ Upload failed: ${response.statusCode} - ${response.body}');
        }
        throw Exception('Failed to upload media: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Upload error: $e');
      }
      rethrow;
    }
  }
  
  /// Get media file URL
  Future<String> getMediaUrl(String fileName) async {
    final response = await http.get(
      Uri.parse('$mediaApiUrl/api/media/$fileName'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['media_url'];
    } else {
      throw Exception('Failed to get media URL: ${response.statusCode}');
    }
  }
  
  /// Delete media file
  Future<void> deleteMedia(String fileName, String username) async {
    final response = await http.delete(
      Uri.parse('$mediaApiUrl/api/media/$fileName'),
      headers: {
        ..._headers,
        'X-Username': username,
      },
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to delete media: ${response.statusCode}');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // CHAT REACTIONS METHODS
  // ═══════════════════════════════════════════════════════════

  /// Add reaction to chat message
  /// Supports 18 emojis: 👍👎❤️😂🔥✨💎🌟💫⚡🌈🔮🧘✨🎯💪🙏🤔
  Future<Map<String, dynamic>> addReaction({
    required String messageId,
    required String emoji,
    required String username,
    required String userId,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('👍 Adding reaction: $emoji to message $messageId by $username');
      }
      
      final response = await http.post(
        Uri.parse('$reactionsApiUrl/chat/messages/$messageId/reactions'),
        headers: _headers,
        body: json.encode({
          'emoji': emoji,
          'username': username,
        }),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 201) {
        final result = json.decode(response.body);
        if (kDebugMode) {
          debugPrint('✅ Reaction added successfully');
        }
        return result;
      } else {
        if (kDebugMode) {
          debugPrint('❌ Add reaction failed: ${response.statusCode} - ${response.body}');
        }
        throw Exception('Failed to add reaction: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Add reaction error: $e');
      }
      rethrow;
    }
  }
  
  /// Remove reaction from chat message
  Future<void> removeReaction({
    required String messageId,
    required String emoji,
    required String username,
    required String userId,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('👎 Removing reaction: $emoji from message $messageId by $username');
      }
      
      final response = await http.delete(
        Uri.parse('$reactionsApiUrl/chat/messages/$messageId/reactions/$emoji'),
        headers: {
          ..._headers,
          'X-Username': username,
        },
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        if (kDebugMode) {
          debugPrint('✅ Reaction removed successfully');
        }
      } else {
        if (kDebugMode) {
          debugPrint('❌ Remove reaction failed: ${response.statusCode} - ${response.body}');
        }
        throw Exception('Failed to remove reaction: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Remove reaction error: $e');
      }
      rethrow;
    }
  }
  
  /// Get all reactions for a message
  Future<Map<String, dynamic>> getMessageReactions(String messageId) async {
    final response = await http.get(
      Uri.parse('$reactionsApiUrl/chat/messages/$messageId/reactions'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get reactions: ${response.statusCode}');
    }
  }
  
  /// Get user's reactions for a message
  Future<List<String>> getUserReactions(String messageId, String username) async {
    final response = await http.get(
      Uri.parse('$reactionsApiUrl/chat/messages/$messageId/reactions/user/$username'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> emojis = data['emojis'] ?? [];
      return emojis.cast<String>();
    } else {
      throw Exception('Failed to get user reactions: ${response.statusCode}');
    }
  }
  
  // ==================== FEATURE 6: PINNED MESSAGES ====================
  
  /// Pin message in room
  Future<void> pinMessage({
    required String room,
    required String messageId,
    required String userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$reactionsApiUrl/chat/pin'),
        headers: _headers,
        body: json.encode({
          'room': room,
          'message_id': messageId,
          'user_id': userId,
        }),
      );
      
      if (response.statusCode != 201) {
        throw Exception('Failed to pin message: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Pin message error: $e');
      rethrow;
    }
  }
  
  /// Get pinned message for room
  Future<Map<String, dynamic>?> getPinnedMessage(String room) async {
    try {
      final response = await http.get(
        Uri.parse('$reactionsApiUrl/chat/pin/$room'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Get pinned message error: $e');
      return null;
    }
  }
  
  /// Unpin message in room
  Future<void> unpinMessage(String room) async {
    try {
      await http.delete(
        Uri.parse('$reactionsApiUrl/chat/pin/$room'),
        headers: _headers,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Unpin message error: $e');
    }
  }
  
  // ==================== FEATURE 8: READ RECEIPTS ====================
  
  /// Mark message as read
  Future<void> markAsRead({
    required String messageId,
    required String userId,
    required String username,
  }) async {
    try {
      await http.post(
        Uri.parse('$reactionsApiUrl/chat/read'),
        headers: _headers,
        body: json.encode({
          'message_id': messageId,
          'user_id': userId,
          'username': username,
        }),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Mark as read error: $e');
    }
  }
  
  /// Get read receipts for message
  Future<List<Map<String, dynamic>>> getReadReceipts(String messageId) async {
    try {
      final response = await http.get(
        Uri.parse('$reactionsApiUrl/chat/read/$messageId'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Get read receipts error: $e');
      return [];
    }
  }
  
  // ==================== FEATURE 10: POLLS ====================
  
  /// Create poll
  Future<String?> createPoll({
    required String room,
    required String userId,
    required String username,
    required String question,
    required List<String> options,
    String? expiresAt,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$reactionsApiUrl/chat/polls'),
        headers: _headers,
        body: json.encode({
          'room': room,
          'user_id': userId,
          'username': username,
          'question': question,
          'options': options,
          'expires_at': expiresAt,
        }),
      );
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['poll_id'];
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Create poll error: $e');
      return null;
    }
  }
  
  /// Get polls for room
  Future<List<Map<String, dynamic>>> getPolls(String room) async {
    try {
      final response = await http.get(
        Uri.parse('$reactionsApiUrl/chat/polls/$room'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Get polls error: $e');
      return [];
    }
  }
  
  /// Vote on poll
  Future<void> voteOnPoll({
    required String pollId,
    required String userId,
    required String username,
    required int optionIndex,
  }) async {
    try {
      await http.post(
        Uri.parse('$reactionsApiUrl/chat/polls/$pollId/vote'),
        headers: _headers,
        body: json.encode({
          'user_id': userId,
          'username': username,
          'option_index': optionIndex,
        }),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Vote on poll error: $e');
      rethrow;
    }
  }
  
  // ==================== MEDIA UPLOAD ====================
  
  /// Upload file to Cloudflare R2 Storage
  /// Upload media file (image/audio) to R2
  Future<Map<String, dynamic>> uploadFile({
    required List<int> fileBytes,
    required String fileName,
    required String contentType,
    required String type, // 'image' or 'audio'
    required String userId,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$reactionsApiUrl/media/upload'), // Updated endpoint
      );
      
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
      ));
      
      // Add form fields
      request.fields['type'] = type;
      request.fields['user_id'] = userId;
      
      request.headers.addAll({
        'Content-Type': 'multipart/form-data',
      });
      
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Upload failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Upload error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 🎤 VOICE MESSAGE UPLOAD
  // ═══════════════════════════════════════════════════════════

  /// Upload voice message to Cloudflare R2
  /// Returns the public URL of the uploaded voice file
  Future<String> uploadVoiceMessage({
    required String filePath,
    required String userId,
    required String roomId,
    String realm = 'energie',
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('🎤 Uploading voice message from: $filePath');
      }

      // Read file bytes
      final file = File(filePath);
      final fileBytes = await file.readAsBytes();
      final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}_${userId}_$roomId.m4a';

      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$mediaApiUrl/upload'),
      );

      // Add file
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
      ));

      // Add form fields
      request.fields['type'] = 'voice';
      request.fields['user_id'] = userId;
      request.fields['room_id'] = roomId;
      request.fields['realm'] = realm;

      // Add headers
      request.headers.addAll({
        'Content-Type': 'multipart/form-data',
      });

      // Add API token to headers (if available)
      if (const String.fromEnvironment('CLOUDFLARE_API_TOKEN', defaultValue: '').isNotEmpty) {
        request.headers['Authorization'] = 'Bearer ${const String.fromEnvironment('CLOUDFLARE_API_TOKEN')}';
      }

      if (kDebugMode) {
        debugPrint('🌐 Uploading to: $mediaApiUrl/upload');
        debugPrint('📦 File: $fileName (${fileBytes.length} bytes)');
      }

      // Send request with timeout
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60), // Longer timeout for voice files
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final voiceUrl = data['url'] ?? data['file_url'] ?? data['media_url'];

        if (voiceUrl == null) {
          throw Exception('Upload succeeded but no URL in response: ${response.body}');
        }

        if (kDebugMode) {
          debugPrint('✅ Voice uploaded: $voiceUrl');
        }

        return voiceUrl;
      } else {
        throw Exception('Upload failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Voice upload error: $e');
      }
      rethrow;
    }
  }
  
  // ═══════════════════════════════════════════════════════════
  // USER STATS METHODS
  // ═══════════════════════════════════════════════════════════
  
  /// Save user stats to Cloudflare D1
  Future<void> saveUserStats({
    required String userId,
    required Map<String, dynamic> stats,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.profileApiUrl}/stats');
      
      final response = await http.post(
        url,
        headers: _headers,
        body: json.encode({
          'userId': userId,
          'stats': stats,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      ).timeout(
        const Duration(seconds: 10),
      );
      
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to save stats: ${response.statusCode}');
      }
      
      if (kDebugMode) {
        debugPrint('✅ Stats saved for user: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Stats save error: $e');
      }
      // Don't throw - stats sync is non-critical
    }
  }
  
  /// Get user stats from Cloudflare D1
  Future<Map<String, dynamic>?> getUserStats(String userId) async {
    try {
      final url = Uri.parse('${ApiConfig.profileApiUrl}/stats/$userId');
      
      final response = await http.get(
        url,
        headers: _headers,
      ).timeout(
        const Duration(seconds: 10),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Stats fetch error: $e');
      }
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // SOCIAL & PERSONALIZATION METHODS (NEW)
  // ═══════════════════════════════════════════════════════════

  /// Get personalized recommendations for user
  Future<List<Map<String, dynamic>>> getRecommendations({
    required String userId,
    String? realm,
    int limit = 10,
  }) async {
    try {
      final params = <String, String>{
        'user_id': userId,
        'limit': limit.toString(),
      };
      if (realm != null) params['realm'] = realm;

      final uri = Uri.parse('$baseUrl/api/recommendations').replace(queryParameters: params);
      final response = await http.get(uri, headers: _headers).timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting recommendations: $e');
      }
      return [];
    }
  }

  /// Get user activity history
  Future<List<Map<String, dynamic>>> getUserActivity({
    required String userId,
    int limit = 20,
  }) async {
    try {
      final params = <String, String>{
        'user_id': userId,
        'limit': limit.toString(),
      };

      final uri = Uri.parse('$baseUrl/api/users/$userId/activity').replace(queryParameters: params);
      final response = await http.get(uri, headers: _headers).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting user activity: $e');
      }
      return [];
    }
  }

  /// Get user collections (reading lists, bookmarks, etc.)
  Future<List<Map<String, dynamic>>> getUserCollections({
    required String userId,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/users/$userId/collections');
      final response = await http.get(uri, headers: _headers).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting user collections: $e');
      }
      return [];
    }
  }

  /// Check if current user is following another user
  Future<bool> isFollowing({
    required String currentUserId,
    required String targetUserId,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/users/$currentUserId/following/$targetUserId');
      final response = await http.get(uri, headers: _headers).timeout(
        const Duration(seconds: 5),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['is_following'] ?? false;
      }
      
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error checking follow status: $e');
      }
      return false;
    }
  }

  /// Follow a user
  Future<bool> followUser({
    required String currentUserId,
    required String targetUserId,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/users/$currentUserId/follow');
      final response = await http.post(
        uri,
        headers: _headers,
        body: json.encode({'target_user_id': targetUserId}),
      ).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (kDebugMode) {
          debugPrint('✅ Successfully followed user: $targetUserId');
        }
        return true;
      }
      
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error following user: $e');
      }
      return false;
    }
  }

  /// Unfollow a user
  Future<bool> unfollowUser({
    required String currentUserId,
    required String targetUserId,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/users/$currentUserId/unfollow');
      final response = await http.post(
        uri,
        headers: _headers,
        body: json.encode({'target_user_id': targetUserId}),
      ).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (kDebugMode) {
          debugPrint('✅ Successfully unfollowed user: $targetUserId');
        }
        return true;
      }
      
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error unfollowing user: $e');
      }
      return false;
    }
  }
}

