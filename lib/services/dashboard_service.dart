import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cloudflare_api_service.dart';

/// DashboardService – direct Supabase queries replacing OpenClawDashboardService.
/// Provides identical return keys for drop-in compatibility with home_tab_v5.dart.
class DashboardService {
  static final DashboardService _instance = DashboardService._internal();
  factory DashboardService() => _instance;
  DashboardService._internal();

  final _db = Supabase.instance.client;
  final _cf = CloudflareApiService();

  // ── Statistics ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getStatistics({
    String? userId,
    String realm = 'materie',
  }) async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day).toIso8601String();

      List<dynamic> results;
      try {
        results = await Future.wait([
          _db.from('articles').select('id, created_at').eq('world', realm).eq('is_published', true),
          _db.from('chat_messages').select('id').eq('is_deleted', false),
          _db.from('profiles').select('id').eq('world', realm).gte('updated_at', todayStart),
          _db.from('bookmarks').select('id'),
          _db.from('likes').select('id'),
        ], eagerError: false);
      } catch (_) {
        results = [[], [], [], [], []];
      }

      final articles    = (results[0] as List?) ?? [];
      final chatMsgs    = (results[1] as List?) ?? [];
      final activeUsers = (results[2] as List?) ?? [];
      final bookmarks   = (results[3] as List?) ?? [];
      final likes       = (results[4] as List?) ?? [];

      final newToday = articles.where((a) {
        final c = a['created_at'] as String?;
        return c != null && c.compareTo(todayStart) >= 0;
      }).length;

      return {
        'totalArticles':    articles.length,
        'researchSessions': chatMsgs.length,
        'bookmarkedTopics': bookmarks.length,
        'sharedFindings':   likes.length,
        'activeUsers':      activeUsers.length,
        'newToday':         newToday,
      };
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [Dashboard] getStatistics error: $e');
      try {
        final articles = await _cf.getArticles(realm: realm, limit: 100);
        return {
          'totalArticles': articles.length,
          'researchSessions': 0, 'bookmarkedTopics': 0,
          'sharedFindings': 0, 'activeUsers': 0, 'newToday': 0,
        };
      } catch (_) {
        return {
          'totalArticles': 0, 'researchSessions': 0, 'bookmarkedTopics': 0,
          'sharedFindings': 0, 'activeUsers': 0, 'newToday': 0,
        };
      }
    }
  }

  // ── Recent Articles ───────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getRecentArticles({
    String realm = 'materie',
    int limit = 10,
  }) async {
    try {
      return await _cf.getArticles(realm: realm, limit: limit);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [Dashboard] getRecentArticles error: $e');
      return [];
    }
  }

  // ── Trending Topics ───────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getTrendingTopics({
    String realm = 'materie',
    int limit = 10,
  }) async {
    try {
      final now = DateTime.now();
      final articles = await _db
          .from('articles')
          .select('id, title, category, like_count, view_count, comments_count, created_at')
          .eq('world', realm)
          .eq('is_published', true)
          .order('created_at', ascending: false)
          .limit(limit * 2);

      final safeArticles = (articles as List?) ?? [];

      final scored = safeArticles.map((a) {
        final likes    = (a['like_count'] ?? a['likes_count'] ?? 0) as int;
        final comments = (a['comments_count'] ?? 0) as int;
        final views    = (a['view_count'] ?? 0) as int;
        final createdAt = DateTime.tryParse(a['created_at'] ?? '') ?? now;
        final hoursAgo  = now.difference(createdAt).inHours;
        final recency   = hoursAgo < 24 ? 50 : (hoursAgo < 72 ? 20 : 0);
        final score     = (likes * 3) + (comments * 2) + views + recency;

        return {
          'id':       a['id'],
          'topic':    a['title'],
          'mentions': score,
          'trend':    hoursAgo < 24 ? 'new' : (score > 10 ? 'up' : 'stable'),
          'category': a['category'] ?? realm,
          'likes': likes, 'comments': comments, 'views': views,
        };
      }).toList();

      scored.sort((a, b) =>
          (b['mentions'] as int).compareTo(a['mentions'] as int));
      return scored.take(limit).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [Dashboard] getTrendingTopics error: $e');
      return [];
    }
  }

  // ── Notifications ─────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getNotifications({
    String? userId,
    String realm = 'materie',
    int limit = 10,
  }) async {
    if (userId != null && userId.isNotEmpty) {
      try {
        final result = await _db
            .from('notifications')
            .select('*')
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .limit(limit);
        return (result as List).map((n) => {
          'id':        n['id'],
          'type':      n['type'] ?? 'info',
          'title':     n['title'] ?? '',
          'message':   n['body'] ?? n['message'] ?? '',
          'timestamp': n['created_at'],
          'read':      (n['is_read'] == true) || (n['read_at'] != null),
          'is_read':   (n['is_read'] == true) || (n['read_at'] != null),
          'data':      n['data'],
        }).toList();
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ [Dashboard] getNotifications error: $e');
      }
    }
    // Fallback: latest articles as info-notifications
    try {
      final articles = await _db
          .from('articles')
          .select('id, title, created_at')
          .eq('world', realm)
          .eq('is_published', true)
          .order('created_at', ascending: false)
          .limit(limit);
      return (articles as List).map((a) => {
        'id':        a['id'],
        'type':      'article',
        'title':     'Neuer Artikel',
        'message':   a['title'],
        'timestamp': a['created_at'],
        'read': false, 'is_read': false,
        'articleId': a['id'],
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Admin Check ───────────────────────────────────────────────────────────

  Future<bool> isAdmin(String? userId, String realm) async {
    if (userId == null || userId.isEmpty) return false;
    try {
      final profile = await _db
          .from('user_profiles')
          .select('is_admin')
          .eq('id', userId)
          .maybeSingle()
          .timeout(const Duration(seconds: 4));
      return profile?['is_admin'] == true;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [Dashboard] isAdmin error: $e');
      return false;
    }
  }
}
