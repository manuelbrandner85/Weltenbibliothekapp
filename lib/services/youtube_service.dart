import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class YoutubeVideo {
  final String videoId;
  final String title;
  final String channel;
  final String thumbnail;
  final String published;
  final String description;
  final bool isSubtitled; // true = englisches Video mit deutschen Untertiteln

  const YoutubeVideo({
    required this.videoId,
    required this.title,
    required this.channel,
    required this.thumbnail,
    required this.published,
    required this.description,
    this.isSubtitled = false,
  });

  factory YoutubeVideo.fromJson(Map<String, dynamic> j) => YoutubeVideo(
        videoId: j['videoId'] as String? ?? '',
        title: j['title'] as String? ?? '',
        channel: j['channel'] as String? ?? '',
        thumbnail: j['thumbnail'] as String? ?? '',
        published: j['published'] as String? ?? '',
        description: j['description'] as String? ?? '',
        isSubtitled: j['isSubtitled'] as bool? ?? false,
      );

  String get embedUrl =>
      'https://www.youtube-nocookie.com/embed/$videoId?autoplay=1&hl=de&rel=0';
  String get watchUrl => 'https://www.youtube.com/watch?v=$videoId';
  String get fallbackThumbnail =>
      'https://img.youtube.com/vi/$videoId/mqdefault.jpg';
}

class YoutubeService {
  YoutubeService._();
  static final instance = YoutubeService._();

  final _cache = <String, List<YoutubeVideo>>{};

  Future<List<YoutubeVideo>> searchVideos(String query, {int max = 6}) async {
    // Suffix "deutsch" entfernen — Worker kümmert sich selbst darum
    final cleanQuery = query
        .replaceAll(RegExp(r'\s+deutsch$', caseSensitive: false), '')
        .trim();
    final key = '$cleanQuery|$max';
    if (_cache.containsKey(key)) return _cache[key]!;

    try {
      final uri = Uri.parse(ApiConfig.workerUrl)
          .resolve('/api/map/youtube')
          .replace(queryParameters: {
        'q': cleanQuery,
        'max': '$max',
      });

      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as Map<String, dynamic>;

      if (data['fallback'] == true) return [];

      final items = (data['items'] as List<dynamic>? ?? [])
          .map((e) => YoutubeVideo.fromJson(e as Map<String, dynamic>))
          .where((v) => v.videoId.isNotEmpty)
          .toList();

      _cache[key] = items;
      return items;
    } catch (_) {
      return [];
    }
  }

  void clearCache() => _cache.clear();
}
