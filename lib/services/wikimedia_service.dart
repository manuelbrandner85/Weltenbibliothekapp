import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class WikimediaService {
  WikimediaService._();
  static final instance = WikimediaService._();

  final _cache = <String, List<String>>{};

  Future<List<String>> searchImages(String query, {int max = 6}) async {
    if (_cache.containsKey(query)) return _cache[query]!;
    try {
      final uri = Uri.parse(ApiConfig.workerUrl)
          .resolve('/api/map/wikimedia')
          .replace(queryParameters: {'q': query});
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final images = (data['images'] as List<dynamic>? ?? [])
          .cast<String>()
          .take(max)
          .toList();
      _cache[query] = images;
      return images;
    } catch (_) {
      return [];
    }
  }

  void clearCache() => _cache.clear();
}
