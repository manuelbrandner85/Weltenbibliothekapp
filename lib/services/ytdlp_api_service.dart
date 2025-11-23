import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/audio_content.dart';

/// 🎵 yt-dlp API Service für Audio-Extraktion
/// 🌐 Nutzt Cloudflare Worker als Backend-Proxy
class YtdlpApiService {
  // 🌐 Cloudflare Worker URL (Production)
  static const String baseUrl =
      'https://weltenbibliothek.brandy13062.workers.dev/api/v1';
  static const String healthUrl =
      'https://weltenbibliothek.brandy13062.workers.dev/health';

  /// Health Check - Prüfe ob Cloudflare Worker erreichbar ist
  Future<bool> isServerHealthy() async {
    try {
      final response = await http
          .get(Uri.parse(healthUrl))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (kDebugMode) {
          debugPrint(
            '✅ Cloudflare Worker: ${data['status']} - ${data['service']}',
          );
        }
        return data['status'] == 'healthy';
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Cloudflare Worker nicht erreichbar: $e');
      }
      return false;
    }
  }

  /// Hole Video-Informationen & Audio-Stream-URL
  Future<Map<String, dynamic>?> getVideoInfo(String videoId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/video/$videoId'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (kDebugMode) {
          debugPrint('✅ Video Info geladen: ${data['title']}');
          debugPrint(
            '🎵 Audio Streams verfügbar: ${data['audioStreams']?.length ?? 0}',
          );
        }
        return data;
      } else {
        if (kDebugMode) {
          debugPrint('❌ Video Info Fehler: ${response.statusCode}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Laden der Video-Info: $e');
      }
      return null;
    }
  }

  /// Hole beste Audio-Stream-URL für direktes Abspielen
  Future<String?> getBestAudioUrl(String videoId) async {
    final videoInfo = await getVideoInfo(videoId);
    if (videoInfo != null && videoInfo['bestAudioUrl'] != null) {
      if (kDebugMode) {
        debugPrint('🎵 Beste Audio-URL: ${videoInfo['bestAudioUrl']}');
      }
      return videoInfo['bestAudioUrl'] as String;
    }
    return null;
  }

  /// Suche YouTube-Videos
  Future<List<String>> searchVideos(String query, {int maxResults = 10}) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/search?q=${Uri.encodeComponent(query)}&max_results=$maxResults',
            ),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final videoIds = List<String>.from(data['videoIds'] ?? []);
        if (kDebugMode) {
          debugPrint('🔍 Suche "$query": ${videoIds.length} Videos gefunden');
        }
        return videoIds;
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Suchfehler: $e');
      }
      return [];
    }
  }

  /// Lade vollständige AudioContent-Objekte für Video-IDs
  Future<List<AudioContent>> loadAudioContents(
    List<String> videoIds, {
    String category = 'Allgemein',
  }) async {
    final List<AudioContent> contents = [];

    for (final videoId in videoIds) {
      try {
        final videoInfo = await getVideoInfo(videoId);
        if (videoInfo != null) {
          contents.add(
            AudioContent.fromJson({
              ...videoInfo,
              'category': category,
              'addedDate': DateTime.now().toIso8601String(),
            }),
          );
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ Überspringe Video $videoId: $e');
        }
      }
    }

    return contents;
  }

  /// Test-Funktion mit Rick Astley
  Future<void> testConnection() async {
    if (kDebugMode) {
      debugPrint('🧪 Teste Cloudflare Worker Verbindung...');
    }

    final isHealthy = await isServerHealthy();
    if (!isHealthy) {
      if (kDebugMode) {
        debugPrint('❌ Cloudflare Worker nicht erreichbar!');
      }
      return;
    }

    final testVideoId = 'dQw4w9WgXcQ'; // Rick Astley - Never Gonna Give You Up
    final audioUrl = await getBestAudioUrl(testVideoId);

    if (audioUrl != null) {
      if (kDebugMode) {
        debugPrint('✅ Test erfolgreich!');
        debugPrint('🎵 Audio-URL erhalten (${audioUrl.length} Zeichen)');
        debugPrint('🌐 Cloudflare Worker funktioniert!');
      }
    } else {
      if (kDebugMode) {
        debugPrint('❌ Test fehlgeschlagen!');
      }
    }
  }
}
