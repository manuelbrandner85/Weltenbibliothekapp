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

  const YoutubeVideo({
    required this.videoId,
    required this.title,
    required this.channel,
    required this.thumbnail,
    required this.published,
    required this.description,
  });

  factory YoutubeVideo.fromJson(Map<String, dynamic> j) => YoutubeVideo(
        videoId: j['videoId'] as String? ?? '',
        title: j['title'] as String? ?? '',
        channel: j['channel'] as String? ?? '',
        thumbnail: j['thumbnail'] as String? ?? '',
        published: j['published'] as String? ?? '',
        description: j['description'] as String? ?? '',
      );

  String get embedUrl => 'https://www.youtube-nocookie.com/embed/$videoId?autoplay=1&hl=de&rel=0';
  String get watchUrl => 'https://www.youtube.com/watch?v=$videoId';
  String get fallbackThumbnail => 'https://img.youtube.com/vi/$videoId/mqdefault.jpg';
}

class YoutubeService {
  YoutubeService._();
  static final instance = YoutubeService._();

  final _cache = <String, List<YoutubeVideo>>{};

  Future<List<YoutubeVideo>> searchVideos(String query, {int max = 6}) async {
    final key = '$query|$max';
    if (_cache.containsKey(key)) return _cache[key]!;

    try {
      final uri = Uri.parse(ApiConfig.workerUrl)
          .resolve('/api/youtube/search')
          .replace(queryParameters: {
        'q': query,
        'lang': 'de',
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
