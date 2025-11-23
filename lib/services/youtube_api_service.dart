// YouTube Data API v3 Integration Service
// Sucht nach Musik-Playlists mit Hive-Caching

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';

/// YouTube Data API v3 Service für Playlist-Suche
class YouTubeApiService {
  // ✅ YouTube API Key - Konfiguriert für Weltenbibliothek
  // YouTube Data API v3: https://console.cloud.google.com/
  static const String _apiKey = 'AIzaSyAYEA_GaKNJwbG5xhR2av5fENvvdLCJuQ0';

  static const String _baseUrl = 'https://www.googleapis.com/youtube/v3/search';
  static const String _boxName = 'youtube_cache';

  Box? _cacheBox;
  final http.Client _httpClient = http.Client();

  Future<void> initialize() async {
    try {
      _cacheBox = await Hive.openBox(_boxName);
      if (kDebugMode) {
        debugPrint(
          '✅ YouTube API Service initialized (Cache: ${_cacheBox!.length} entries)',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to initialize YouTube API Service: $e');
      }
    }
  }

  /// 🔍 Suche Videos via YouTube API
  /// Unterstützt 2 Modi:
  /// 1. Video-Suche: Einzelne Videos basierend auf Suchbegriff
  /// 2. Playlist-Suche: Videos aus einer YouTube Playlist (wenn usePlaylist=true)
  Future<List<String>> searchVideos({
    required String searchQuery,
    int maxResults = 10,
    bool usePlaylist = false, // 🆕 Playlist-Modus
  }) async {
    try {
      final cacheKey = usePlaylist ? 'playlist_$searchQuery' : searchQuery;
      final cachedResult = await _getCachedResult(cacheKey);
      if (cachedResult != null) {
        if (kDebugMode) {
          debugPrint('✅ Cache HIT for "$cacheKey"');
        }
        return cachedResult;
      }

      if (kDebugMode) {
        debugPrint('⚠️ Cache MISS - Calling YouTube API...');
      }

      List<String> videoIds;
      if (usePlaylist) {
        // 🆕 Playlist-Modus: Suche Playlists und hole Videos daraus
        videoIds = await _searchFromPlaylist(searchQuery, maxResults);
      } else {
        // Standard: Direkte Video-Suche
        videoIds = await _callYouTubeApi(searchQuery, maxResults);
      }

      await _cacheResult(cacheKey, videoIds);

      return videoIds;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ YouTube API Error: $e');
      }
      return [];
    }
  }

  /// 🆕 Suche nach Playlists und hole Videos daraus
  Future<List<String>> _searchFromPlaylist(
    String searchQuery,
    int maxResults,
  ) async {
    if (kDebugMode) {
      debugPrint('🔍 [PLAYLIST SEARCH] Starting search for: $searchQuery');
    }

    // Schritt 1: Suche nach Playlists
    final playlistUri = Uri.parse(_baseUrl).replace(
      queryParameters: {
        'part': 'id',
        'q': '$searchQuery playlist',
        'type': 'playlist',
        'maxResults': '1', // Nur erste Playlist
        'key': _apiKey,
      },
    );

    if (kDebugMode) {
      debugPrint('🌐 [API REQUEST] $playlistUri');
    }

    final playlistResponse = await _httpClient.get(playlistUri);

    if (kDebugMode) {
      debugPrint('📡 [API RESPONSE] Status: ${playlistResponse.statusCode}');
    }

    if (playlistResponse.statusCode != 200) {
      throw Exception('Playlist Search Error: ${playlistResponse.statusCode}');
    }

    final playlistData = json.decode(playlistResponse.body);
    final playlists = playlistData['items'] as List<dynamic>? ?? [];

    if (kDebugMode) {
      debugPrint('📊 [PLAYLISTS] Found ${playlists.length} playlists');
    }

    if (playlists.isEmpty) {
      if (kDebugMode) {
        debugPrint('⚠️ No playlist found, falling back to video search');
      }
      return _callYouTubeApi(searchQuery, maxResults);
    }

    final playlistId = playlists.first['id']['playlistId'] as String;

    if (kDebugMode) {
      debugPrint('🆔 [PLAYLIST ID] $playlistId');
    }

    // Schritt 2: Hole Videos aus der Playlist
    final playlistItemsUri =
        Uri.parse(
          'https://www.googleapis.com/youtube/v3/playlistItems',
        ).replace(
          queryParameters: {
            'part': 'snippet',
            'playlistId': playlistId,
            'maxResults': maxResults.toString(),
            'key': _apiKey,
          },
        );

    final itemsResponse = await _httpClient.get(playlistItemsUri);

    if (kDebugMode) {
      debugPrint('📡 [PLAYLIST ITEMS] Status: ${itemsResponse.statusCode}');
    }

    if (itemsResponse.statusCode != 200) {
      throw Exception('Playlist Items Error: ${itemsResponse.statusCode}');
    }

    final itemsData = json.decode(itemsResponse.body);
    final items = itemsData['items'] as List<dynamic>? ?? [];

    if (kDebugMode) {
      debugPrint('🎬 [VIDEOS] Found ${items.length} videos in playlist');
    }

    final videoIds = items
        .map((item) => item['snippet']['resourceId']['videoId'] as String?)
        .where((id) => id != null)
        .cast<String>()
        .toList();

    if (kDebugMode) {
      debugPrint('✅ [VIDEO IDS] $videoIds');
    }

    return videoIds;
  }

  Future<List<String>> _callYouTubeApi(
    String searchQuery,
    int maxResults,
  ) async {
    if (_apiKey == 'YOUR_YOUTUBE_API_KEY_HERE') {
      if (kDebugMode) {
        debugPrint('❌ YouTube API Key nicht gesetzt!');
      }
      return _getFallbackVideos(searchQuery);
    }

    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {
        'part': 'id',
        'q': searchQuery,
        'type': 'video',
        'maxResults': maxResults.toString(),
        'key': _apiKey,
        'videoEmbeddable': 'true', // ✅ Nur einbettbare Videos
        'videoSyndicated':
            'true', // ✅ Nur syndizierbare Videos (außerhalb YouTube abspielbar)
        'videoCategoryId': '10', // ✅ Music category
      },
    );

    final response = await _httpClient.get(uri);

    if (response.statusCode != 200) {
      throw Exception('YouTube API Error: ${response.statusCode}');
    }

    final jsonData = json.decode(response.body);
    final items = jsonData['items'] as List<dynamic>? ?? [];

    return items
        .map((item) => item['id']['videoId'] as String?)
        .where((id) => id != null)
        .cast<String>()
        .toList();
  }

  Future<List<String>?> _getCachedResult(String searchQuery) async {
    if (_cacheBox == null) return null;

    try {
      final cached = _cacheBox!.get(searchQuery);
      if (cached == null) return null;

      final cacheData = cached as Map<dynamic, dynamic>;
      final timestamp = cacheData['timestamp'] as int;
      final age = DateTime.now().millisecondsSinceEpoch - timestamp;

      if (age > 604800000) {
        await _cacheBox!.delete(searchQuery);
        return null;
      }

      return (cacheData['videoIds'] as List<dynamic>).cast<String>();
    } catch (e) {
      return null;
    }
  }

  Future<void> _cacheResult(String searchQuery, List<String> videoIds) async {
    if (_cacheBox == null) return;

    try {
      await _cacheBox!.put(searchQuery, {
        'videoIds': videoIds,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Cache write error: $e');
      }
    }
  }

  /// Fallback-Videos für alle 68 Genres
  /// Verwendet bekannte YouTube Music-Playlists und Channels
  List<String> _getFallbackVideos(String searchQuery) {
    final query = searchQuery.toLowerCase();

    // ═══════════════════════════════════════════════════════════════════════
    // POP GENRES
    // ═══════════════════════════════════════════════════════════════════════
    if (query.contains('dance pop') || query.contains('dance-pop')) {
      return ['4NRXx6U8ABQ', 'YQHsXMglC9A', 'CevxZvSJLk8', '3AtDnEC4zak'];
    }
    if (query.contains('teen pop')) {
      return ['kffacxfA7G4', 'hTWKbfoikeg', 'QcIy9NiNbmo', 'VvXX5yANYvE'];
    }
    if (query.contains('synth pop') || query.contains('synth-pop')) {
      return ['djV11Xbc914', 'Iwuy4hHO3YQ', 'CDl9ZMfj6aE', 'dVVZaZ8yO6o'];
    }
    if (query.contains('electropop')) {
      return ['u4U5fzLS_CM', '14G8vS8HxSw', 'Rbm6GXllBiw', 'gM89Q5Eng_M'];
    }
    if (query.contains('pop')) {
      return ['dQw4w9WgXcQ', '9bZkp7q19f0', 'CevxZvSJLk8', 'kTFZyl7hfBw'];
    }

    // ═══════════════════════════════════════════════════════════════════════
    // ROCK GENRES
    // ═══════════════════════════════════════════════════════════════════════
    if (query.contains('classic rock')) {
      return ['fJ9rUzIMcZQ', 'rY0WxgSXdEE', 'L3wKzyIN1yk', 'cd-go0i6wVI'];
    }
    if (query.contains('hard rock')) {
      return ['WGU_4-5RaxU', 'v2AC41dglnM', 'ZhIsAZO5gl0', '_Yhyp-_hX2s'];
    }
    if (query.contains('alternative rock')) {
      return ['Soa3gO7tL-c', 'YykjpeuMNEk', 'eJO5HU_7_1w', 'SlPDZgz5kOs'];
    }
    if (query.contains('indie rock')) {
      return ['qkk5wViJo-I', 'cMPEd8m79Hw', 'C2cMG33mWVY', '1w7OgIMMRc4'];
    }
    if (query.contains('punk rock')) {
      return ['RYnFIRc0k6E', 'QnFOs7QlJSI', 'Soa3gO7tL-c', 'CAMWdvo71ls'];
    }
    if (query.contains('grunge')) {
      return ['vabnZ9-ex7o', 'hTWKbfoikeg', 'QcIy9NiNbmo', 'DzJnEYgYKP4'];
    }
    if (query.contains('heavy metal') || query.contains('metal')) {
      return ['cd-go0i6wVI', 'WGU_4-5RaxU', 'v2AC41dglnM', 'ZhIsAZO5gl0'];
    }
    if (query.contains('progressive metal')) {
      return ['7yh9i0PAjck', 'NOGEyBeoBGM', 'SceZXBrYD9c', 'iw-88h-LcTk'];
    }
    if (query.contains('rock')) {
      return ['fJ9rUzIMcZQ', 'rY0WxgSXdEE', 'L3wKzyIN1yk', 'cd-go0i6wVI'];
    }

    // ═══════════════════════════════════════════════════════════════════════
    // HIP-HOP & RAP
    // ═══════════════════════════════════════════════════════════════════════
    if (query.contains('trap')) {
      return ['YqeW9_5kURI', 'xpVfcZ0ZcFM', 'S9bCLPwzSC0', 'KxlPGPupdd8'];
    }
    if (query.contains('boom bap')) {
      return ['k7HJXmCiXo0', '_JZom_gVfuw', 'iBHNgV6_VnY', 'InGtiEXQyYA'];
    }
    if (query.contains('gangsta rap')) {
      return ['_JZom_gVfuw', '6IJCFc_qkHw', 'eF8c3BjFWsw', 'N9-OFzzpKvs'];
    }
    if (query.contains('old school') || query.contains('old-school')) {
      return ['0hiUuL5uTKc', 'SW-BU6keEUw', '4ITLNzPoEqs', '_shxzlTRK44'];
    }
    if (query.contains('rap')) {
      return ['xpVfcZ0ZcFM', '_JZom_gVfuw', '6IJCFc_qkHw', 'YqeW9_5kURI'];
    }
    if (query.contains('hip hop') || query.contains('hip-hop')) {
      return ['YqeW9_5kURI', 'xpVfcZ0ZcFM', '_JZom_gVfuw', '6IJCFc_qkHw'];
    }

    // ═══════════════════════════════════════════════════════════════════════
    // EDM & ELECTRONIC
    // ═══════════════════════════════════════════════════════════════════════
    if (query.contains('house')) {
      return ['IcrbM1l_BoI', 'bx-fuY7LpSU', '2vjPBrBU-TM', '5dbG4wqN0rQ'];
    }
    if (query.contains('techno')) {
      return ['p7ZsBEuKi-Y', 'hy_Zj0MQ8Fg', 'gCYcHz2k5x0', 'Y12_cVX2exw'];
    }
    if (query.contains('trance')) {
      return ['iRA82xLsb_w', 'qdRaf0Y4Xr0', 'nM3lXWn_P9o', 'j8kl1H0i1sk'];
    }
    if (query.contains('dubstep')) {
      return ['WSeNSzJ2-Jw', 'LEGZ2hGjqUE', 'O3K1TuWkHZ0', 'eOofWzI3flA'];
    }
    if (query.contains('drum and bass') || query.contains('drum & bass')) {
      return ['ZM8cC5rBKAA', 'Y7VZ1-4TjGk', 'kON_KRmFRKk', '4H5I6y1Q8M0'];
    }
    if (query.contains('chillout')) {
      return ['5qap5aO4i9A', 'aatr_2MstrI', '1ZYbU82GVz4', 'sySlY1XKlhM'];
    }
    if (query.contains('lounge')) {
      return ['8wbYPHNYgDU', 'fEvM-OUbaKs', 'clV2OT2V0Jw', 'G7OEAgMRXzw'];
    }
    if (query.contains('synthwave')) {
      return ['0V194B4n9tI', '5_Bt6xnYX-s', 'Ss5_9ZHAeGA', 'OTYJqEVJvhE'];
    }
    if (query.contains('edm')) {
      return ['IcrbM1l_BoI', 'bx-fuY7LpSU', '2vjPBrBU-TM', '5dbG4wqN0rQ'];
    }

    // ═══════════════════════════════════════════════════════════════════════
    // JAZZ & BLUES
    // ═══════════════════════════════════════════════════════════════════════
    if (query.contains('smooth jazz')) {
      return ['HMnrl0tmd3k', 'Dx5i1t0mN78', 'vmDDOFXSgAs', 'M3w1zEd5z2s'];
    }
    if (query.contains('bebop')) {
      return ['uVL_7JNJmLk', '__OSyznVDOY', 'dU3hD9oM2qI', 'ZMNT-rSnoOU'];
    }
    if (query.contains('jazz fusion')) {
      return ['l-qgum7hFXk', 'kp7MDAiCjKE', 'OtuMyEpoch0', 'y9oO2fLDvJY'];
    }
    if (query.contains('blues')) {
      return ['Yd60nI4sa9A', '4fk2prKnYnI', 'UqCEPytSFqU', 'NLNq6vJmBts'];
    }
    if (query.contains('jazz')) {
      return ['vmDDOFXSgAs', 'Dx5i1t0mN78', 'HMnrl0tmd3k', 'M3w1zEd5z2s'];
    }

    // ═══════════════════════════════════════════════════════════════════════
    // R&B & SOUL
    // ═══════════════════════════════════════════════════════════════════════
    if (query.contains('neo soul') || query.contains('neo-soul')) {
      return ['KKOlQaVlZdU', 'btPJPFnesV4', 'TW7gXM4ljzg', 'R1TN7N6FZQE'];
    }
    if (query.contains('soul')) {
      return ['btPJPFnesV4', 'L_XJ_s5IsQc', '4m1EFMoRFvY', 'QHYwT6Hchrc'];
    }
    if (query.contains('funk')) {
      return ['StKVS0eI85I', '3GwjfUFyY6M', 'ZjkvFlKu0f8', '9egC-Jw5O7k'];
    }
    if (query.contains('r&b') || query.contains('rnb')) {
      return ['KKOlQaVlZdU', 'L_XJ_s5IsQc', '4m1EFMoRFvY', 'QHYwT6Hchrc'];
    }

    // ═══════════════════════════════════════════════════════════════════════
    // COUNTRY & FOLK
    // ═══════════════════════════════════════════════════════════════════════
    if (query.contains('bluegrass')) {
      return ['lg8ky0LJ9FM', 'myhnAZFR1po', 'aPy8sFVLAe0', 'zSif77IVQdY'];
    }
    if (query.contains('americana')) {
      return ['bpOSxM0rNPM', 'jS4w5S-Jdb4', 'FGiDDx2yIwI', 'Y2JyNueMWfc'];
    }
    if (query.contains('singer songwriter') ||
        query.contains('singer-songwriter')) {
      return ['V1bFr2SWP1I', 'NiyvOq_zSsg', 'kVdWqWZlegY', 'RDnjYPNmQXg'];
    }
    if (query.contains('folk')) {
      return ['tWjNtKRKPD4', 'W0VBgqt6C-Y', '2gmiSPMHrWQ', 'bpOSxM0rNPM'];
    }
    if (query.contains('country')) {
      return ['gBGyLY3nCt8', 'ZyhrYis509A', 'y0FBfCF2s6M', 'oijZ5GBveNo'];
    }

    // ═══════════════════════════════════════════════════════════════════════
    // REGGAE & CARIBBEAN
    // ═══════════════════════════════════════════════════════════════════════
    if (query.contains('dub')) {
      return ['HbFVi_XWFEM', 'uB1iZHJHY8c', 'FLXe_JV7Mos', 'Z3vHbOilhpc'];
    }
    if (query.contains('dancehall')) {
      return ['fy4pHaz6ljE', 'S9bCLPwzSC0', 'VBLyPm7VQac', 'hWJgwhT59j0'];
    }
    if (query.contains('ska')) {
      return ['k8Bj5Uc8yB8', 'v8K_scLZBPM', 'SOJSM46nWwo', 'cnhCghc4wHU'];
    }
    if (query.contains('reggae')) {
      return ['zaGUr6wzyT8', 'x59kS2AOrGM', 'hlVBg7_08n0', 'PlrnafjOZH4'];
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LATIN MUSIC
    // ═══════════════════════════════════════════════════════════════════════
    if (query.contains('salsa')) {
      return ['LlvUepMa31o', 'GR9vNDlsYVQ', 'IwzUs1IMdyQ', 'EK_LN3XEcnw'];
    }
    if (query.contains('bachata')) {
      return ['4KXwT76VHys', '6MXQ42CAe2o', 'PkV2bTXGCvw', 'w0yqrSqS69Y'];
    }
    if (query.contains('reggaeton')) {
      return ['kJQP7kiw5Fk', 'ByIXmwLW53o', 'pHlnOZEVNOU', 'DiItGE3eAyQ'];
    }

    // ═══════════════════════════════════════════════════════════════════════
    // INTERNATIONAL
    // ═══════════════════════════════════════════════════════════════════════
    if (query.contains('kpop') || query.contains('k-pop')) {
      return ['9bZkp7q19f0', 'pBuZEGYXA6E', 'WMweEpGlu_U', 'IHNzOHi8sJs'];
    }
    if (query.contains('jpop') || query.contains('j-pop')) {
      return ['MXPzJoTynqo', 'gBGyLY3nCt8', 'kl6JTw2LMvw', 'mraI_OxrMz0'];
    }
    if (query.contains('afrobeat')) {
      return ['qXwru3AspFc', 'Kw0_Tigs1Mo', 'nQHBOdxJAqE', 'ddgy9pPnSQ0'];
    }
    if (query.contains('world music')) {
      return ['CdXesX6mYUE', 'L2b89X3EbSI', 'RkZkekS8NQU', 'V1bFr2SWP1I'];
    }

    // ═══════════════════════════════════════════════════════════════════════
    // CLASSICAL
    // ═══════════════════════════════════════════════════════════════════════
    if (query.contains('baroque') || query.contains('barock')) {
      return ['vD9vI4Uy4V4', 'kYnU1AiY1xo', 'gUrmmj01NVA', 'BhxoTKoJhM4'];
    }
    if (query.contains('romantic') || query.contains('romantik')) {
      return ['ygbqRqyhpK4', 'M73x3O7dhmg', 'rP42C-4zL3w', 'Rb0UmrCXxVA'];
    }
    if (query.contains('opera') || query.contains('oper')) {
      return ['TE0aAF70-0o', 'cWc7vYjgnTs', 'YmXJp8Kz7sg', 'QNJMLPhxq0U'];
    }
    if (query.contains('classical') || query.contains('klassik')) {
      return ['jgpJVI3tDbY', 'N3MHeNt6Yjs', 'vD9vI4Uy4V4', 'kYnU1AiY1xo'];
    }

    // ═══════════════════════════════════════════════════════════════════════
    // OLDIES
    // ═══════════════════════════════════════════════════════════════════════
    if (query.contains('oldies') ||
        query.contains('50s') ||
        query.contains('60s') ||
        query.contains('70s') ||
        query.contains('80s') ||
        query.contains('90s')) {
      return ['djV11Xbc914', 'Iwuy4hHO3YQ', 'CDl9ZMfj6aE', 'fJ9rUzIMcZQ'];
    }

    // Default Fallback
    if (kDebugMode) {
      debugPrint('⚠️ No specific genre match for: $searchQuery');
    }
    return ['dQw4w9WgXcQ', '9bZkp7q19f0', 'fJ9rUzIMcZQ', 'IcrbM1l_BoI'];
  }

  Map<String, dynamic> getQuotaStats() {
    return {
      'cached_queries': _cacheBox?.length ?? 0,
      'estimated_quota_saved': (_cacheBox?.length ?? 0) * 100,
    };
  }

  void dispose() {
    _httpClient.close();
  }
}
