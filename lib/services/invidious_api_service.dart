// 🔧 Invidious API Service
// Verwendet Invidious als Proxy zu YouTube um Geo-Blocking und Beschränkungen zu umgehen
//
// Invidious API Dokumentation: https://docs.invidious.io/api/
// Öffentliche Instanzen: https://docs.invidious.io/instances/

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// 🎵 Audio Stream Daten
class InvidiousAudioStream {
  final String url;
  final String type; // MIME type (z.B. "audio/mp4", "audio/webm")
  final String container; // Container (z.B. "mp4", "webm")
  final String encoding; // Codec (z.B. "opus", "aac")
  final int bitrate; // Bitrate in bits/s
  final int contentLength; // Größe in Bytes
  final String itag;

  InvidiousAudioStream({
    required this.url,
    required this.type,
    required this.container,
    required this.encoding,
    required this.bitrate,
    required this.contentLength,
    required this.itag,
  });

  factory InvidiousAudioStream.fromJson(Map<String, dynamic> json) {
    return InvidiousAudioStream(
      url: json['url'] ?? '',
      type: json['type'] ?? '',
      container: json['container'] ?? '',
      encoding: json['encoding'] ?? '',
      bitrate: int.tryParse(json['bitrate']?.toString() ?? '0') ?? 0,
      contentLength: int.tryParse(json['clen']?.toString() ?? '0') ?? 0,
      itag: json['itag']?.toString() ?? '',
    );
  }

  /// Ist das ein reiner Audio-Stream?
  bool get isAudioOnly {
    return !type.toLowerCase().contains('video') &&
        (encoding.toLowerCase().contains('opus') ||
            encoding.toLowerCase().contains('aac') ||
            encoding.toLowerCase().contains('mp4a'));
  }

  @override
  String toString() {
    return 'InvidiousAudioStream(encoding: $encoding, bitrate: ${bitrate ~/ 1000}kbps, container: $container)';
  }
}

/// 📹 Video-Informationen von Invidious
class InvidiousVideoInfo {
  final String videoId;
  final String title;
  final String author;
  final int lengthSeconds;
  final List<InvidiousAudioStream> audioStreams;
  final String? error;

  InvidiousVideoInfo({
    required this.videoId,
    required this.title,
    required this.author,
    required this.lengthSeconds,
    required this.audioStreams,
    this.error,
  });

  bool get hasError => error != null && error!.isNotEmpty;
  bool get hasAudioStreams => audioStreams.isNotEmpty;

  /// Bester Audio-Stream (höchste Bitrate)
  InvidiousAudioStream? get bestAudioStream {
    if (audioStreams.isEmpty) return null;

    // Filter nur Audio-only Streams
    final audioOnly = audioStreams.where((s) => s.isAudioOnly).toList();
    if (audioOnly.isEmpty) return null;

    // Sortiere nach Bitrate (höchste zuerst)
    audioOnly.sort((a, b) => b.bitrate.compareTo(a.bitrate));
    return audioOnly.first;
  }
}

/// 🔧 Invidious API Service
///
/// Verwendet öffentliche Invidious-Instanzen als Proxy zu YouTube
/// um Geo-Blocking, Altersbeschränkungen und andere Limitierungen zu umgehen.
class InvidiousApiService {
  /// 🌐 Öffentliche Invidious-Instanzen (sortiert nach Zuverlässigkeit)
  ///
  /// Diese Instanzen werden automatisch rotiert wenn eine ausfällt.
  /// Quelle: https://docs.invidious.io/instances/
  static final List<String> _instances = [
    'https://inv.nadeko.net',
    'https://yewtu.be',
    'https://invidious.nerdvpn.de',
    'https://invidious.f5.si',
    'https://inv.riverside.rocks',
    'https://invidious.flokinet.to',
    'https://yt.artemislena.eu',
    'https://invidious.privacydev.net',
  ];

  int _currentInstanceIndex = 0;
  final http.Client _httpClient = http.Client();

  /// 🔄 Aktuelle Invidious-Instanz
  String get currentInstance => _instances[_currentInstanceIndex];

  /// 🔄 Wechsle zur nächsten Instanz (bei Fehler)
  void _rotateInstance() {
    _currentInstanceIndex = (_currentInstanceIndex + 1) % _instances.length;
    if (kDebugMode) {
      debugPrint('🔄 Invidious: Wechsle zu Instanz: $currentInstance');
    }
  }

  /// 🎵 Hole Video-Informationen und Audio-Streams
  ///
  /// [videoId]: YouTube Video-ID (z.B. "dQw4w9WgXcQ")
  /// [region]: ISO 3166 Ländercode (default "US")
  ///
  /// Wirft Exception bei Fehler.
  Future<InvidiousVideoInfo> getVideoInfo(
    String videoId, {
    String region = 'US',
    int maxRetries = 3,
  }) async {
    Exception? lastError;

    // Versuche mit verschiedenen Instanzen (bei Fehler automatisch wechseln)
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final url = '$currentInstance/api/v1/videos/$videoId?region=$region';

        if (kDebugMode) {
          debugPrint('🔍 Invidious: Hole Video-Info von $currentInstance');
          debugPrint('   URL: $url');
        }

        final response = await _httpClient
            .get(Uri.parse(url), headers: {'Accept': 'application/json'})
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body) as Map<String, dynamic>;

          // Prüfe auf Error in Response
          if (json.containsKey('error')) {
            final errorMsg = json['error']?.toString() ?? 'Unknown error';
            if (kDebugMode) {
              debugPrint('❌ Invidious: Video-Error: $errorMsg');
            }
            return InvidiousVideoInfo(
              videoId: videoId,
              title: '',
              author: '',
              lengthSeconds: 0,
              audioStreams: [],
              error: errorMsg,
            );
          }

          // Extrahiere Audio-Streams aus adaptiveFormats
          final List<InvidiousAudioStream> audioStreams = [];

          if (json.containsKey('adaptiveFormats')) {
            final formats = json['adaptiveFormats'] as List;

            for (final format in formats) {
              try {
                final stream = InvidiousAudioStream.fromJson(format);

                // Nur Audio-only Streams hinzufügen
                if (stream.isAudioOnly && stream.url.isNotEmpty) {
                  audioStreams.add(stream);
                }
              } catch (e) {
                if (kDebugMode) {
                  debugPrint('⚠️ Invidious: Fehler beim Parsen von Format: $e');
                }
              }
            }
          }

          if (kDebugMode) {
            debugPrint(
              '✅ Invidious: ${audioStreams.length} Audio-Streams gefunden',
            );
            for (final stream in audioStreams) {
              debugPrint('   - $stream');
            }
          }

          return InvidiousVideoInfo(
            videoId: videoId,
            title: json['title']?.toString() ?? '',
            author: json['author']?.toString() ?? '',
            lengthSeconds: json['lengthSeconds'] as int? ?? 0,
            audioStreams: audioStreams,
          );
        } else if (response.statusCode == 404) {
          // Video nicht gefunden (nicht verfügbar)
          return InvidiousVideoInfo(
            videoId: videoId,
            title: '',
            author: '',
            lengthSeconds: 0,
            audioStreams: [],
            error: 'Video not found (404)',
          );
        } else {
          throw Exception('HTTP ${response.statusCode}: ${response.body}');
        }
      } catch (e) {
        lastError = Exception('Invidious request failed: $e');

        if (kDebugMode) {
          debugPrint('❌ Invidious: Fehler mit $currentInstance: $e');
        }

        // Wechsle zur nächsten Instanz und versuche nochmal
        _rotateInstance();

        if (attempt < maxRetries - 1) {
          // Kurze Pause vor erneutem Versuch
          await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
        }
      }
    }

    // Alle Versuche fehlgeschlagen
    throw lastError ?? Exception('All Invidious instances failed');
  }

  /// 🔍 Suche nach Videos
  ///
  /// [query]: Suchbegriff (z.B. "hip hop music")
  /// [maxResults]: Maximale Anzahl Ergebnisse (default 10)
  ///
  /// Gibt Liste von Video-IDs zurück.
  Future<List<String>> searchVideos(String query, {int maxResults = 10}) async {
    Exception? lastError;

    // Versuche mit verschiedenen Instanzen
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        final url =
            '$currentInstance/api/v1/search?q=${Uri.encodeComponent(query)}&type=video&sort_by=relevance';

        if (kDebugMode) {
          debugPrint('🔍 Invidious: Suche "$query" auf $currentInstance');
        }

        final response = await _httpClient
            .get(Uri.parse(url), headers: {'Accept': 'application/json'})
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final List<dynamic> results = jsonDecode(response.body);

          final videoIds = results
              .where((item) => item['type'] == 'video')
              .map((item) => item['videoId']?.toString() ?? '')
              .where((id) => id.isNotEmpty)
              .take(maxResults)
              .toList();

          if (kDebugMode) {
            debugPrint('✅ Invidious: ${videoIds.length} Videos gefunden');
          }

          return videoIds;
        } else {
          throw Exception('HTTP ${response.statusCode}');
        }
      } catch (e) {
        lastError = Exception('Invidious search failed: $e');

        if (kDebugMode) {
          debugPrint('❌ Invidious: Such-Fehler mit $currentInstance: $e');
        }

        _rotateInstance();

        if (attempt < 2) {
          await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
        }
      }
    }

    throw lastError ?? Exception('All Invidious instances failed');
  }

  /// 🧪 Teste Invidious-Instanz
  ///
  /// Prüft ob die aktuelle Instanz erreichbar ist.
  Future<bool> testCurrentInstance() async {
    try {
      final url = '$currentInstance/api/v1/stats';
      final response = await _httpClient
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));

      final isHealthy = response.statusCode == 200;

      if (kDebugMode) {
        debugPrint(
          isHealthy
              ? '✅ Invidious: $currentInstance ist erreichbar'
              : '❌ Invidious: $currentInstance ist nicht erreichbar (${response.statusCode})',
        );
      }

      return isHealthy;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Invidious: $currentInstance Test fehlgeschlagen: $e');
      }
      return false;
    }
  }

  /// 🔄 Finde funktionierende Instanz
  ///
  /// Testet alle Instanzen und wählt die erste funktionierende aus.
  Future<bool> findWorkingInstance() async {
    for (int i = 0; i < _instances.length; i++) {
      if (await testCurrentInstance()) {
        return true;
      }
      _rotateInstance();
    }

    if (kDebugMode) {
      debugPrint('❌ Invidious: Keine funktionierende Instanz gefunden!');
    }

    return false;
  }

  /// 🧹 Cleanup
  void dispose() {
    _httpClient.close();
  }
}
