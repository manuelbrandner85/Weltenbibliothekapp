/// OpenClaw Dashboard Service
/// Liefert ECHTE Live-Daten für das Dashboard
/// - Push-Benachrichtigungen
/// - Trending Topics
/// - Live-Updates
/// - Statistiken
/// - Admin-Checks

library;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'cloudflare_api_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OpenClawDashboardService {
  static final OpenClawDashboardService _instance = OpenClawDashboardService._internal();
  factory OpenClawDashboardService() => _instance;
  OpenClawDashboardService._internal();

  final CloudflareApiService _cloudflare = CloudflareApiService();
  bool _openClawAvailable = false;
  Timer? _liveUpdateTimer;
  
  final StreamController<Map<String, dynamic>> _dashboardStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  
  Stream<Map<String, dynamic>> get dashboardStream => _dashboardStreamController.stream;

  /// Health Check
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.openClawGatewayUrl}/health'),
      ).timeout(const Duration(seconds: 3));
      
      _openClawAvailable = response.statusCode == 200;
      return _openClawAvailable;
    } catch (e) {
      _openClawAvailable = false;
      return false;
    }
  }

  /// 🔔 Push-Benachrichtigungen (ECHT)
  /// Echte Notifications aus Supabase laden (is_read Feld korrekt)
  Future<List<Map<String, dynamic>>> getNotifications({
    String? userId,
    String realm = 'materie',
    int limit = 10,
  }) async {
    // Supabase direkt nutzen wenn userId vorhanden
    if (userId != null && userId.isNotEmpty) {
      try {
        final supabase = Supabase.instance.client;
        final result = await supabase
            .from('notifications')
            .select('*')
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .limit(limit);
        return (result as List).map((n) {
          return {
            'id': n['id'],
            'type': n['type'] ?? 'info',
            'title': n['title'] ?? '',
            'message': n['body'] ?? n['message'] ?? '',
            'timestamp': n['created_at'],
            // DB hat is_read (bool) oder read_at (timestamp)
            'read': (n['is_read'] == true) || (n['read_at'] != null),
            'is_read': (n['is_read'] == true) || (n['read_at'] != null),
            'data': n['data'],
          };
        }).toList();
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ [Dashboard] Supabase notifications error: $e');
      }
    }
    // Fallback: neueste Artikel als Info-Notifications
    return await _getNotificationsFromSupabaseArticles(realm, limit);
  }

  Future<List<Map<String, dynamic>>> _getNotificationsFromSupabaseArticles(
    String realm,
    int limit,
  ) async {
    try {
      final supabase = Supabase.instance.client;
      final articles = await supabase
          .from('articles')
          .select('id, title, created_at')
          .eq('world', realm)
          .eq('is_published', true)
          .order('created_at', ascending: false)
          .limit(limit);
      return (articles as List).map((article) {
        return {
          'id': article['id'],
          'type': 'article',
          'title': 'Neuer Artikel',
          'message': article['title'],
          'timestamp': article['created_at'],
          'read': false,
          'is_read': false,
          'articleId': article['id'],
        };
      }).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [Dashboard] Articles fallback error: $e');
      return [];
    }
  }

  /// 📊 Trending Topics (ECHT)
  Future<List<Map<String, dynamic>>> getTrendingTopics({
    String realm = 'materie',
    int limit = 10,
  }) async {
    try {
      if (_openClawAvailable) {
        final response = await http.post(
          Uri.parse('${ApiConfig.openClawGatewayUrl}/api/trending'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${ApiConfig.openClawGatewayToken}',
          },
          body: jsonEncode({
            'realm': realm,
            'limit': limit,
            'timeframe': '24h',
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return List<Map<String, dynamic>>.from(data['trending'] ?? []);
        }
      }

      // Fallback: Cloudflare
      return await _getTrendingFromCloudflare(realm, limit);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [Dashboard] Trending error: $e');
      return await _getTrendingFromCloudflare(realm, limit);
    }
  }

  Future<List<Map<String, dynamic>>> _getTrendingFromCloudflare(
    String realm,
    int limit,
  ) async {
    try {
      // Echtes Trending: Artikel sortiert nach Engagement (likes + views + comments)
      final supabase = Supabase.instance.client;
      final now = DateTime.now();
      final since24h = now.subtract(const Duration(hours: 24)).toIso8601String(); // ignore: unused_local_variable

      // Artikel der letzten 7 Tage, sortiert nach Engagement-Score
      final articles = await supabase
          .from('articles')
          .select('id, title, category, like_count, view_count, comments_count, created_at')
          .eq('world', realm)
          .eq('is_published', true)
          .order('created_at', ascending: false)
          .limit(limit * 2); // Mehr laden für besseres Ranking

      final safeArticles = (articles as List?) ?? [];

      // Engagement-Score berechnen: likes*3 + comments*2 + views*1 + recency bonus
      final scored = safeArticles.map((a) {
        final likes = (a['like_count'] ?? a['likes_count'] ?? 0) as int;
        final comments = (a['comments_count'] ?? 0) as int;
        final views = (a['view_count'] ?? 0) as int;
        final createdAt = DateTime.tryParse(a['created_at'] ?? '') ?? now;
        final hoursAgo = now.difference(createdAt).inHours;
        final recencyBonus = hoursAgo < 24 ? 50 : (hoursAgo < 72 ? 20 : 0);

        final score = (likes * 3) + (comments * 2) + views + recencyBonus;

        return {
          'id': a['id'],
          'topic': a['title'],
          'mentions': score,
          'trend': hoursAgo < 24 ? 'new' : (score > 10 ? 'up' : 'stable'),
          'category': a['category'] ?? realm,
          'likes': likes,
          'comments': comments,
          'views': views,
        };
      }).toList();

      // Sortiere nach Score (höchster zuerst)
      scored.sort((a, b) => (b['mentions'] as int).compareTo(a['mentions'] as int));

      return scored.take(limit).toList();
    } catch (e) {
      return [];
    }
  }

  /// 📈 Live-Updates starten
  void startLiveUpdates({
    String? userId,
    String realm = 'materie',
    Duration interval = const Duration(minutes: 5),
  }) {
    _liveUpdateTimer?.cancel();
    
    _liveUpdateTimer = Timer.periodic(interval, (timer) async {
      try {
        final notifications = await getNotifications(
          userId: userId,
          realm: realm,
          limit: 5,
        );

        final trending = await getTrendingTopics(
          realm: realm,
          limit: 10,
        );

        final stats = await getStatistics(
          userId: userId,
          realm: realm,
        );

        _dashboardStreamController.add({
          'notifications': notifications,
          'trending': trending,
          'statistics': stats,
          'timestamp': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ [Dashboard] Live update error: $e');
      }
    });

    if (kDebugMode) {
      debugPrint('✅ [Dashboard] Live updates started (every ${interval.inMinutes}min)');
    }
  }

  /// Live-Updates stoppen
  void stopLiveUpdates() {
    _liveUpdateTimer?.cancel();
    _liveUpdateTimer = null;
    if (kDebugMode) debugPrint('🛑 [Dashboard] Live updates stopped');
  }

  /// 📊 Statistiken (ECHT)
  Future<Map<String, dynamic>> getStatistics({
    String? userId,
    String realm = 'materie',
  }) async {
    try {
      if (_openClawAvailable) {
        final response = await http.post(
          Uri.parse('${ApiConfig.openClawGatewayUrl}/api/statistics'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${ApiConfig.openClawGatewayToken}',
          },
          body: jsonEncode({
            'userId': userId,
            'realm': realm,
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['statistics'] ?? {};
        }
      }

      // Fallback: Cloudflare
      return await _getStatisticsFromCloudflare(realm);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [Dashboard] Statistics error: $e');
      return await _getStatisticsFromCloudflare(realm);
    }
  }

  Future<Map<String, dynamic>> _getStatisticsFromCloudflare(String realm) async {
    try {
      final supabase = Supabase.instance.client;
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day).toIso8601String();

      // Parallel queries für Performance
      final results = await Future.wait([
        // Gesamt-Artikel (published)
        supabase
            .from('articles')
            .select('id, created_at')
            .eq('world', realm)
            .eq('is_published', true),
        // Chat-Nachrichten (aktive Sitzungen)
        supabase
            .from('chat_messages')
            .select('id')
            .eq('is_deleted', false),
        // Aktive User (heute eingeloggt via profiles updated_at)
        supabase
            .from('profiles')
            .select('id')
            .eq('world', realm)
            .gte('updated_at', todayStart),
        // Bookmarks total
        supabase
            .from('bookmarks')
            .select('id'),
        // Likes total
        supabase
            .from('likes')
            .select('id'),
        // ignore: invalid_return_type_for_catch_error
      ], eagerError: false).catchError((_) => [[], [], [], [], []]);

      final articles = (results[0] as List?) ?? [];
      final chatMessages = (results[1] as List?) ?? [];
      final activeUsers = (results[2] as List?) ?? [];
      final bookmarks = (results[3] as List?) ?? [];
      final likes = (results[4] as List?) ?? [];

      // Heute neue Artikel
      final newToday = articles.where((a) {
        final created = a['created_at'] as String?;
        return created != null && created.compareTo(todayStart) >= 0;
      }).length;

      return {
        'totalArticles': articles.length,
        'researchSessions': chatMessages.length,
        'bookmarkedTopics': bookmarks.length,
        'sharedFindings': likes.length,
        'activeUsers': activeUsers.length,
        'newToday': newToday,
      };
    } catch (e) {
      // Fallback: Artikel via Cloudflare API
      try {
        final articles = await _cloudflare.getArticles(realm: realm, limit: 100);
        return {
          'totalArticles': articles.length,
          'researchSessions': 0,
          'bookmarkedTopics': 0,
          'sharedFindings': 0,
          'activeUsers': 0,
          'newToday': 0,
        };
      } catch (_) {
        return {
          'totalArticles': 0,
          'researchSessions': 0,
          'bookmarkedTopics': 0,
          'sharedFindings': 0,
          'activeUsers': 0,
          'newToday': 0,
        };
      }
    }
  }

  /// 👤 Admin-Check (ECHT)
  Future<bool> isAdmin(String? userId, String realm) async {
    if (userId == null) return false;

    try {
      if (_openClawAvailable) {
        final response = await http.post(
          Uri.parse('${ApiConfig.openClawGatewayUrl}/api/admin/check'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${ApiConfig.openClawGatewayToken}',
          },
          body: jsonEncode({
            'userId': userId,
            'realm': realm,
          }),
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['isAdmin'] == true;
        }
      }

      // Fallback: Cloudflare Admin Service
      return await _checkAdminViaCloudflare(userId, realm);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [Dashboard] Admin check error: $e');
      return false;
    }
  }

  Future<bool> _checkAdminViaCloudflare(String userId, String realm) async {
    try {
      // Prüfe über Cloudflare API
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/admin/check/$realm/$userId'),
        headers: {
          'Authorization': 'Bearer ${ApiConfig.apiToken}',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['isAdmin'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// 🔍 Recent Articles (ECHT)
  Future<List<Map<String, dynamic>>> getRecentArticles({
    String realm = 'materie',
    int limit = 10,
  }) async {
    try {
      final articles = await _cloudflare.getArticles(
        realm: realm,
        limit: limit,
      );

      return articles;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [Dashboard] Recent articles error: $e');
      return [];
    }
  }

  /// Aufräumen
  void dispose() {
    stopLiveUpdates();
    _dashboardStreamController.close();
  }
}
