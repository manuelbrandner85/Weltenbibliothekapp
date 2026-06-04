import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 🚀 POST CREATION HELPER SERVICES
/// Alle Services für die 10 neuen Features

/// ═══════════════════════════════════════════════════════════════════════════
/// FEATURE 1: EMOJI PICKER - Emoji Categories & Data
/// ═══════════════════════════════════════════════════════════════════════════

class EmojiService {
  static const Map<String, List<String>> emojiCategories = {
    'Smileys': [
      '😀',
      '😃',
      '😄',
      '😁',
      '😅',
      '😂',
      '🤣',
      '😊',
      '😇',
      '🙂',
      '🙃',
      '😉',
      '😌',
      '😍',
      '🥰',
      '😘',
      '😗',
      '😙',
      '😚',
      '😋'
    ],
    'Gesten': [
      '👋',
      '🤚',
      '🖐',
      '✋',
      '🖖',
      '👌',
      '🤌',
      '🤏',
      '✌',
      '🤞',
      '🤟',
      '🤘',
      '🤙',
      '👈',
      '👉',
      '👆',
      '🖕',
      '👇',
      '☝',
      '👍'
    ],
    'Herzen': [
      '❤️',
      '🧡',
      '💛',
      '💚',
      '💙',
      '💜',
      '🖤',
      '🤍',
      '🤎',
      '💔',
      '❣️',
      '💕',
      '💞',
      '💓',
      '💗',
      '💖',
      '💘',
      '💝',
      '💟'
    ],
    'Symbole': [
      '✨',
      '⭐',
      '🌟',
      '💫',
      '✅',
      '❌',
      '🔥',
      '💧',
      '🌈',
      '☀️',
      '🌙',
      '⚡',
      '☁️',
      '🌸',
      '🌺',
      '🌻',
      '🌹',
      '🌷',
      '🌼'
    ],
    'Objekte': [
      '📱',
      '💻',
      '⌚',
      '📷',
      '📚',
      '📖',
      '✏️',
      '📝',
      '🎨',
      '🎭',
      '🎪',
      '🎬',
      '🎵',
      '🎸',
      '🎹',
      '🎺',
      '🎻',
      '🥁',
      '🎮'
    ],
  };

  static List<String> getAllEmojis() {
    return emojiCategories.values.expand((list) => list).toList();
  }

  static const _kFrequentKey = 'frequent_emojis_v1';
  static const _kFallback = ['😀', '❤️', '👍', '🔥', '✨', '🎉', '💯', '👏'];

  /// Synchroner Default (Aufrufer der nicht awaiten kann). Fuer eine
  /// echte personalisierte Liste [loadFrequentEmojis] verwenden.
  static List<String> getFrequentEmojis() => _kFallback;

  static Future<List<String>> loadFrequentEmojis() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_kFrequentKey);
    if (stored == null || stored.isEmpty) return _kFallback;
    return stored;
  }

  /// Erhoeht den Use-Count fuer das Emoji und persistiert die 8
  /// haeufigsten in SharedPreferences. Best-effort.
  static Future<void> recordEmojiUsed(String emoji) async {
    if (emoji.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('${_kFrequentKey}__counts');
    final counts = <String, int>{};
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        decoded.forEach((k, v) => counts[k] = (v as num).toInt());
      } catch (_) {/* corrupt -> reset */}
    }
    counts[emoji] = (counts[emoji] ?? 0) + 1;
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(8).map((e) => e.key).toList();
    await prefs.setStringList(_kFrequentKey, top);
    await prefs.setString('${_kFrequentKey}__counts', jsonEncode(counts));
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// FEATURE 7: HASHTAG SUGGESTIONS - Trending & Popular Tags
/// ═══════════════════════════════════════════════════════════════════════════

class HashtagService {
  // Trending Hashtags (kann später aus Analytics kommen)
  static const Map<String, List<String>> trendingTags = {
    'energie': [
      'Spiritualität',
      'Meditation',
      'Chakra',
      'Energie',
      'Bewusstsein',
      'Transformation',
      'Heilung',
      'Manifestation',
      'Achtsamkeit',
      'Yoga',
    ],
    'materie': [
      'Forschung',
      'Wissenschaft',
      'Technologie',
      'Innovation',
      'Geopolitik',
      'Wirtschaft',
      'Bildung',
      'Gesellschaft',
      'Umwelt',
      'Zukunft',
    ],
  };

  static List<String> getTrendingTags(String worldType) {
    return trendingTags[worldType] ?? [];
  }

  static List<String> searchTags(String query, String worldType) {
    if (query.isEmpty) return getTrendingTags(worldType);

    final allTags = getTrendingTags(worldType);
    return allTags
        .where((tag) => tag.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  static String formatTag(String tag) {
    // Entferne # wenn vorhanden, füge es dann wieder hinzu
    final clean = tag.replaceAll('#', '').trim();
    return clean.isEmpty ? '' : '#$clean';
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// FEATURE 9: MENTION SYSTEM - User Search & Autocomplete
/// ═══════════════════════════════════════════════════════════════════════════

class MentionService {
  // Cached user list from Supabase (populated on first call)
  static List<Map<String, String>> _cachedUsers = [];
  static DateTime? _lastFetch;

  /// Fetch real users from Supabase profiles table
  static Future<void> _ensureUsersLoaded() async {
    if (_cachedUsers.isNotEmpty &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < const Duration(minutes: 5)) {
      return; // Use cache
    }
    try {
      final result = await _fetchUsersFromSupabase();
      _cachedUsers = result;
      _lastFetch = DateTime.now();
    } catch (e) {
      debugPrint('MentionService: Supabase fetch failed: $e');
    }
  }

  static Future<List<Map<String, String>>> _fetchUsersFromSupabase() async {
    try {
      final supa = Supabase.instance.client;
      final rows = await supa
          .from('profiles')
          .select('username, avatar_emoji')
          .order('created_at', ascending: false)
          .limit(200);
      return (rows as List)
          .where((r) =>
              r['username'] != null && (r['username'] as String).isNotEmpty)
          .map((r) => {
                'username': r['username'] as String,
                'avatar': (r['avatar_emoji'] as String?) ?? '👤',
              })
          .toList();
    } catch (_) {
      return [];
    }
  }

  static List<Map<String, String>> searchUsers(String query) {
    // Trigger async load; return cached results synchronously
    _ensureUsersLoaded();

    final users = _cachedUsers;
    if (users.isEmpty) return []; // No cached users yet
    if (query.isEmpty) return users.take(5).toList();

    return users
        .where((user) =>
            user['username']!.toLowerCase().contains(query.toLowerCase()))
        .take(5)
        .toList();
  }

  static List<String> extractMentions(String text) {
    final regex = RegExp(r'@(\w+)');
    final matches = regex.allMatches(text);
    return matches.map((m) => m.group(1)!).toList();
  }

  static String formatMention(String username) {
    return '@$username';
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// FEATURE 10: LINK PREVIEW - URL Metadata Extraction
/// ═══════════════════════════════════════════════════════════════════════════

class LinkPreviewService {
  static final RegExp _urlRegex = RegExp(
    r'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)',
    caseSensitive: false,
  );

  static List<String> extractUrls(String text) {
    final matches = _urlRegex.allMatches(text);
    return matches.map((m) => m.group(0)!).toList();
  }

  /// Holt die Ziel-URL, parst Open-Graph- und Twitter-Card-Meta-Tags
  /// und liefert Title / Description / Image / Domain zurueck.
  /// Timeout 6s, niemals werfen -- Fehler werden als null gemeldet.
  static Future<Map<String, dynamic>?> fetchLinkPreview(String url) async {
    try {
      final uri = Uri.parse(url);
      final res = await http.get(
        uri,
        headers: const {
          'User-Agent':
              'Mozilla/5.0 (compatible; WeltenbibliothekBot/1.0; +https://weltenbibliothek.app)',
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        },
      ).timeout(const Duration(seconds: 6));
      if (res.statusCode < 200 || res.statusCode >= 400) return null;

      // HTML auf ersten 256KB beschraenken -- og-Tags stehen im <head>
      final html =
          res.body.length > 262144 ? res.body.substring(0, 262144) : res.body;

      String? meta(String property) {
        // og:* und twitter:* sowohl als property als auch name unterstuetzen
        final patterns = [
          RegExp(
              '<meta[^>]+property=["\']${RegExp.escape(property)}["\'][^>]+content=["\']([^"\']+)["\']',
              caseSensitive: false),
          RegExp(
              '<meta[^>]+name=["\']${RegExp.escape(property)}["\'][^>]+content=["\']([^"\']+)["\']',
              caseSensitive: false),
          RegExp(
              '<meta[^>]+content=["\']([^"\']+)["\'][^>]+property=["\']${RegExp.escape(property)}["\']',
              caseSensitive: false),
        ];
        for (final p in patterns) {
          final m = p.firstMatch(html);
          if (m != null) return m.group(1);
        }
        return null;
      }

      final ogTitle = meta('og:title') ?? meta('twitter:title');
      final ogDesc = meta('og:description') ??
          meta('twitter:description') ??
          meta('description');
      final ogImage = meta('og:image') ?? meta('twitter:image');

      // Fallback: <title>...</title>
      String? title = ogTitle;
      if (title == null) {
        final tm = RegExp(r'<title>([^<]+)</title>', caseSensitive: false)
            .firstMatch(html);
        title = tm?.group(1)?.trim();
      }

      return {
        'url': url,
        'title': title ?? uri.host,
        'description': ogDesc ?? '',
        'imageUrl': ogImage,
        'domain': uri.host.replaceFirst('www.', ''),
      };
    } catch (e) {
      if (kDebugMode) debugPrint('Link preview error: $e');
      return null;
    }
  }

  static String getDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.replaceFirst('www.', '');
    } catch (e) {
      return url;
    }
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// FEATURE 5: IMAGE EDITOR - Filter & Transform Helpers
/// ═══════════════════════════════════════════════════════════════════════════

class ImageEditorService {
  static const List<Map<String, dynamic>> filters = [
    {'name': 'Original', 'icon': '🖼️'},
    {'name': 'B&W', 'icon': '⬛'},
    {'name': 'Vintage', 'icon': '📷'},
    {'name': 'Warm', 'icon': '🔥'},
    {'name': 'Cool', 'icon': '❄️'},
    {'name': 'Bright', 'icon': '☀️'},
  ];

  // Diese Methoden würden mit image_editor Package implementiert
  static Future<dynamic> cropImage(dynamic imageFile) async {
    // TODO: Implement with image_cropper package
    return imageFile;
  }

  static Future<dynamic> applyFilter(
      dynamic imageFile, String filterName) async {
    // TODO: Implement with image package filters
    return imageFile;
  }

  static Future<dynamic> addText(dynamic imageFile, String text) async {
    // TODO: Implement text overlay
    return imageFile;
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// FEATURE 6 & 8: DRAFT & SCHEDULED POSTS - Storage Service
/// ═══════════════════════════════════════════════════════════════════════════

/// Lokale Persistenz fuer Entwuerfe und geplante Posts.
///
/// Speichert pro Welt-Typ eine Liste von Maps in SharedPreferences.
/// Schema-Keys:
///   post_drafts__<world>     -> JSON-Array von Draft-Maps
///   post_scheduled__<world>  -> JSON-Array von Scheduled-Maps
///
/// Drafts/Scheduled bekommen eine generierte `id` falls noch nicht vorhanden
/// (DateTime.now().millisecondsSinceEpoch + Index).
class DraftService {
  static String _draftKey(String world) => 'post_drafts__$world';
  static String _schedKey(String world) => 'post_scheduled__$world';

  static String _worldOf(Map<String, dynamic> data) {
    final w = data['worldType'] ?? data['world'];
    if (w is String && w.isNotEmpty) return w;
    return 'materie';
  }

  static Future<List<Map<String, dynamic>>> _read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
            .toList();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('DraftService decode error: $e');
    }
    return <Map<String, dynamic>>[];
  }

  static Future<void> _write(
      String key, List<Map<String, dynamic>> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(list));
  }

  static Future<void> saveDraft(Map<String, dynamic> draftData) async {
    final world = _worldOf(draftData);
    final key = _draftKey(world);
    final list = await _read(key);
    final data = Map<String, dynamic>.from(draftData);
    data['id'] = data['id'] ?? 'draft_${DateTime.now().millisecondsSinceEpoch}';
    data['savedAt'] = DateTime.now().toIso8601String();
    // Existierenden Draft mit gleicher id ueberschreiben
    list.removeWhere((d) => d['id'] == data['id']);
    list.insert(0, data);
    await _write(key, list);
    if (kDebugMode) debugPrint('Draft saved: ${data['id']}');
  }

  static Future<List<Map<String, dynamic>>> getDrafts(String worldType) async {
    return _read(_draftKey(worldType));
  }

  static Future<void> deleteDraft(String draftId) async {
    // Wir kennen die Welt nicht -- in allen Buckets entfernen.
    for (final world in const ['materie', 'energie', 'vorhang', 'ursprung']) {
      final key = _draftKey(world);
      final list = await _read(key);
      final before = list.length;
      list.removeWhere((d) => d['id'] == draftId);
      if (list.length != before) await _write(key, list);
    }
  }

  static Future<void> schedulePost(
      Map<String, dynamic> postData, DateTime scheduledFor) async {
    final world = _worldOf(postData);
    final key = _schedKey(world);
    final list = await _read(key);
    final data = Map<String, dynamic>.from(postData);
    data['id'] = data['id'] ?? 'sched_${DateTime.now().millisecondsSinceEpoch}';
    data['scheduledFor'] = scheduledFor.toIso8601String();
    data['savedAt'] = DateTime.now().toIso8601String();
    list.removeWhere((d) => d['id'] == data['id']);
    list.insert(0, data);
    await _write(key, list);
    if (kDebugMode) debugPrint('Post scheduled for: $scheduledFor');
  }

  static Future<List<Map<String, dynamic>>> getScheduledPosts(
      String worldType) async {
    return _read(_schedKey(worldType));
  }

  static Future<void> deleteScheduledPost(String scheduledId) async {
    for (final world in const ['materie', 'energie', 'vorhang', 'ursprung']) {
      final key = _schedKey(world);
      final list = await _read(key);
      final before = list.length;
      list.removeWhere((d) => d['id'] == scheduledId);
      if (list.length != before) await _write(key, list);
    }
  }
}
