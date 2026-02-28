/// 🦞 OpenClaw Media Scraper Service
/// 
/// Intelligentes Scraping für alle Medientypen:
/// - 🖼️ Bilder (JPEG, PNG, WebP, GIF, SVG)
/// - 📄 PDFs (Dokumente, Reports, Papers)
/// - 🎥 Videos (MP4, WebM, MKV, AVI)
/// - 🎵 Audio (MP3, WAV, OGG, M4A)
/// - 🌐 Web-Content (HTML, XML, JSON)
/// 
/// Features:
/// - KI-gestützte Content-Extraktion
/// - Format-Konvertierung
/// - Qualitäts-Optimierung
/// - Metadaten-Extraktion
/// - Thumbnail-Generierung
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// OpenClaw Media Scraper für intelligentes Content-Scraping
class OpenClawMediaScraperService {
  static final OpenClawMediaScraperService _instance = OpenClawMediaScraperService._internal();
  factory OpenClawMediaScraperService() => _instance;
  OpenClawMediaScraperService._internal();

  // OpenClaw Gateway Configuration
  static String get _gatewayUrl => ApiConfig.openClawGatewayUrl;
  static String get _gatewayToken => ApiConfig.openClawGatewayToken;

  // Cache für gescrapte Medien
  final Map<String, CachedMedia> _mediaCache = {};
  static const Duration _cacheDuration = Duration(hours: 24);

  // ════════════════════════════════════════════════════════════
  // 🖼️ BILDER SCRAPEN & OPTIMIEREN
  // ════════════════════════════════════════════════════════════

  /// Scrapt und optimiert Bilder mit OpenClaw
  /// 
  /// Features:
  /// - Intelligente Qualitäts-Optimierung
  /// - Format-Konvertierung (WebP für Web)
  /// - Größen-Anpassung
  /// - Metadaten-Extraktion
  /// - Thumbnail-Generierung
  /// 
  /// Returns:
  /// {
  ///   'success': true,
  ///   'url': 'optimized_image_url',
  ///   'originalUrl': 'source_url',
  ///   'format': 'webp',
  ///   'width': 1920,
  ///   'height': 1080,
  ///   'size': 145678, // bytes
  ///   'thumbnail': 'thumbnail_url',
  ///   'metadata': {...}
  /// }
  Future<Map<String, dynamic>> scrapeImage({
    required String url,
    int? maxWidth,
    int? maxHeight,
    String? format, // 'webp', 'jpeg', 'png'
    int quality = 85,
  }) async {
    try {
      // Cache prüfen
      final cacheKey = 'image_$url';
      if (_mediaCache.containsKey(cacheKey)) {
        final cached = _mediaCache[cacheKey]!;
        if (DateTime.now().difference(cached.timestamp) < _cacheDuration) {
          if (kDebugMode) {
            debugPrint('📦 [OpenClaw Media] Using cached image: $url');
          }
          return cached.data;
        }
      }

      if (kDebugMode) {
        debugPrint('🖼️ [OpenClaw Media] Scraping image: $url');
      }

      final response = await http.post(
        Uri.parse('$_gatewayUrl/media/scrape-image'),
        headers: {
          'Authorization': 'Bearer $_gatewayToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'url': url,
          'max_width': maxWidth,
          'max_height': maxHeight,
          'format': format ?? 'webp',
          'quality': quality,
          'generate_thumbnail': true,
          'extract_metadata': true,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Cache speichern
        _mediaCache[cacheKey] = CachedMedia(
          data: {'service': 'openclaw', 'success': true, ...data},
          timestamp: DateTime.now(),
        );

        if (kDebugMode) {
          debugPrint('✅ [OpenClaw Media] Image scraped successfully');
          debugPrint('   Format: ${data['format']}');
          debugPrint('   Size: ${data['width']}x${data['height']}');
        }

        return _mediaCache[cacheKey]!.data;
      } else {
        throw Exception('Image scraping failed: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [OpenClaw Media] Image scraping failed: $e');
        debugPrint('   Falling back to direct download...');
      }

      // Fallback: Direkt herunterladen
      return await _fallbackImageDownload(url);
    }
  }

  /// Fallback: Direktes Bild-Download
  Future<Map<String, dynamic>> _fallbackImageDownload(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        return {
          'service': 'fallback',
          'success': true,
          'url': url,
          'originalUrl': url,
          'format': _getFormatFromUrl(url),
          'size': response.bodyBytes.length,
          'data': response.bodyBytes,
        };
      } else {
        throw Exception('Direct download failed: ${response.statusCode}');
      }
    } catch (e) {
      return {
        'service': 'fallback',
        'success': false,
        'error': e.toString(),
        'url': url,
      };
    }
  }

  // ════════════════════════════════════════════════════════════
  // 📄 PDFs SCRAPEN & VERARBEITEN
  // ════════════════════════════════════════════════════════════

  /// Scrapt und verarbeitet PDFs mit OpenClaw
  /// 
  /// Features:
  /// - Text-Extraktion
  /// - Metadaten-Extraktion (Autor, Titel, Seitenzahl)
  /// - Thumbnail-Generierung
  /// - Volltextsuche-Vorbereitung
  /// - Kompression
  /// 
  /// Returns:
  /// {
  ///   'success': true,
  ///   'url': 'processed_pdf_url',
  ///   'originalUrl': 'source_url',
  ///   'pages': 42,
  ///   'size': 1234567,
  ///   'text': 'extracted_text',
  ///   'metadata': {
  ///     'title': 'Document Title',
  ///     'author': 'Author Name',
  ///     'created': '2024-01-01'
  ///   },
  ///   'thumbnails': ['page1.jpg', 'page2.jpg']
  /// }
  Future<Map<String, dynamic>> scrapePDF({
    required String url,
    bool extractText = true,
    bool generateThumbnails = true,
    int maxThumbnails = 5,
  }) async {
    try {
      // Cache prüfen
      final cacheKey = 'pdf_$url';
      if (_mediaCache.containsKey(cacheKey)) {
        final cached = _mediaCache[cacheKey]!;
        if (DateTime.now().difference(cached.timestamp) < _cacheDuration) {
          if (kDebugMode) {
            debugPrint('📦 [OpenClaw Media] Using cached PDF: $url');
          }
          return cached.data;
        }
      }

      if (kDebugMode) {
        debugPrint('📄 [OpenClaw Media] Scraping PDF: $url');
      }

      final response = await http.post(
        Uri.parse('$_gatewayUrl/media/scrape-pdf'),
        headers: {
          'Authorization': 'Bearer $_gatewayToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'url': url,
          'extract_text': extractText,
          'generate_thumbnails': generateThumbnails,
          'max_thumbnails': maxThumbnails,
          'extract_metadata': true,
        }),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Cache speichern
        _mediaCache[cacheKey] = CachedMedia(
          data: {'service': 'openclaw', 'success': true, ...data},
          timestamp: DateTime.now(),
        );

        if (kDebugMode) {
          debugPrint('✅ [OpenClaw Media] PDF scraped successfully');
          debugPrint('   Pages: ${data['pages']}');
          debugPrint('   Size: ${data['size']} bytes');
        }

        return _mediaCache[cacheKey]!.data;
      } else {
        throw Exception('PDF scraping failed: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [OpenClaw Media] PDF scraping failed: $e');
        debugPrint('   Falling back to direct download...');
      }

      // Fallback: Direkt herunterladen
      return await _fallbackPDFDownload(url);
    }
  }

  /// Fallback: Direktes PDF-Download
  Future<Map<String, dynamic>> _fallbackPDFDownload(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        return {
          'service': 'fallback',
          'success': true,
          'url': url,
          'originalUrl': url,
          'size': response.bodyBytes.length,
          'data': response.bodyBytes,
        };
      } else {
        throw Exception('Direct PDF download failed: ${response.statusCode}');
      }
    } catch (e) {
      return {
        'service': 'fallback',
        'success': false,
        'error': e.toString(),
        'url': url,
      };
    }
  }

  // ════════════════════════════════════════════════════════════
  // 🎥 VIDEOS SCRAPEN & VERARBEITEN
  // ════════════════════════════════════════════════════════════

  /// Scrapt und verarbeitet Videos mit OpenClaw
  /// 
  /// Features:
  /// - Format-Konvertierung (MP4 für Web)
  /// - Thumbnail-Generierung
  /// - Metadaten-Extraktion
  /// - Untertitel-Extraktion
  /// - Kompression/Optimierung
  /// 
  /// Returns:
  /// {
  ///   'success': true,
  ///   'url': 'processed_video_url',
  ///   'originalUrl': 'source_url',
  ///   'format': 'mp4',
  ///   'duration': 120, // seconds
  ///   'width': 1920,
  ///   'height': 1080,
  ///   'size': 12345678,
  ///   'thumbnail': 'thumbnail_url',
  ///   'metadata': {...}
  /// }
  Future<Map<String, dynamic>> scrapeVideo({
    required String url,
    String? format, // 'mp4', 'webm'
    int? maxWidth,
    int? maxHeight,
    bool generateThumbnail = true,
  }) async {
    try {
      // Cache prüfen
      final cacheKey = 'video_$url';
      if (_mediaCache.containsKey(cacheKey)) {
        final cached = _mediaCache[cacheKey]!;
        if (DateTime.now().difference(cached.timestamp) < _cacheDuration) {
          if (kDebugMode) {
            debugPrint('📦 [OpenClaw Media] Using cached video: $url');
          }
          return cached.data;
        }
      }

      if (kDebugMode) {
        debugPrint('🎥 [OpenClaw Media] Scraping video: $url');
      }

      final response = await http.post(
        Uri.parse('$_gatewayUrl/media/scrape-video'),
        headers: {
          'Authorization': 'Bearer $_gatewayToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'url': url,
          'format': format ?? 'mp4',
          'max_width': maxWidth,
          'max_height': maxHeight,
          'generate_thumbnail': generateThumbnail,
          'extract_metadata': true,
        }),
      ).timeout(const Duration(minutes: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Cache speichern
        _mediaCache[cacheKey] = CachedMedia(
          data: {'service': 'openclaw', 'success': true, ...data},
          timestamp: DateTime.now(),
        );

        if (kDebugMode) {
          debugPrint('✅ [OpenClaw Media] Video scraped successfully');
          debugPrint('   Duration: ${data['duration']}s');
          debugPrint('   Size: ${data['width']}x${data['height']}');
        }

        return _mediaCache[cacheKey]!.data;
      } else {
        throw Exception('Video scraping failed: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [OpenClaw Media] Video scraping failed: $e');
      }

      // Fallback: Original-URL zurückgeben
      return {
        'service': 'fallback',
        'success': true,
        'url': url,
        'originalUrl': url,
        'note': 'Using original video URL',
      };
    }
  }

  // ════════════════════════════════════════════════════════════
  // 🎵 AUDIO SCRAPEN & VERARBEITEN
  // ════════════════════════════════════════════════════════════

  /// Scrapt und verarbeitet Audio mit OpenClaw
  /// 
  /// Features:
  /// - Format-Konvertierung (MP3 für Web)
  /// - Qualitäts-Optimierung
  /// - Metadaten-Extraktion (ID3 Tags)
  /// - Waveform-Generierung
  /// - Transkription (optional)
  /// 
  /// Returns:
  /// {
  ///   'success': true,
  ///   'url': 'processed_audio_url',
  ///   'originalUrl': 'source_url',
  ///   'format': 'mp3',
  ///   'duration': 180, // seconds
  ///   'bitrate': 128000,
  ///   'size': 2345678,
  ///   'metadata': {
  ///     'title': 'Track Title',
  ///     'artist': 'Artist Name',
  ///     'album': 'Album Name'
  ///   },
  ///   'waveform': [...]
  /// }
  Future<Map<String, dynamic>> scrapeAudio({
    required String url,
    String? format, // 'mp3', 'ogg', 'wav'
    int bitrate = 128000,
    bool generateWaveform = false,
    bool transcribe = false,
  }) async {
    try {
      // Cache prüfen
      final cacheKey = 'audio_$url';
      if (_mediaCache.containsKey(cacheKey)) {
        final cached = _mediaCache[cacheKey]!;
        if (DateTime.now().difference(cached.timestamp) < _cacheDuration) {
          if (kDebugMode) {
            debugPrint('📦 [OpenClaw Media] Using cached audio: $url');
          }
          return cached.data;
        }
      }

      if (kDebugMode) {
        debugPrint('🎵 [OpenClaw Media] Scraping audio: $url');
      }

      final response = await http.post(
        Uri.parse('$_gatewayUrl/media/scrape-audio'),
        headers: {
          'Authorization': 'Bearer $_gatewayToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'url': url,
          'format': format ?? 'mp3',
          'bitrate': bitrate,
          'generate_waveform': generateWaveform,
          'transcribe': transcribe,
          'extract_metadata': true,
        }),
      ).timeout(const Duration(minutes: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Cache speichern
        _mediaCache[cacheKey] = CachedMedia(
          data: {'service': 'openclaw', 'success': true, ...data},
          timestamp: DateTime.now(),
        );

        if (kDebugMode) {
          debugPrint('✅ [OpenClaw Media] Audio scraped successfully');
          debugPrint('   Duration: ${data['duration']}s');
          debugPrint('   Bitrate: ${data['bitrate']}');
        }

        return _mediaCache[cacheKey]!.data;
      } else {
        throw Exception('Audio scraping failed: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [OpenClaw Media] Audio scraping failed: $e');
      }

      // Fallback: Original-URL zurückgeben
      return {
        'service': 'fallback',
        'success': true,
        'url': url,
        'originalUrl': url,
        'note': 'Using original audio URL',
      };
    }
  }

  // ════════════════════════════════════════════════════════════
  // 🌐 WEB-CONTENT SCRAPEN
  // ════════════════════════════════════════════════════════════

  /// Scrapt und extrahiert Web-Content mit OpenClaw
  /// 
  /// Features:
  /// - Intelligente Content-Extraktion
  /// - HTML→Markdown Konvertierung
  /// - Hauptinhalt-Erkennung
  /// - Metadaten-Extraktion
  /// - Medien-Inventar (alle Bilder/Videos auf Seite)
  Future<Map<String, dynamic>> scrapeWebContent({
    required String url,
    bool extractImages = true,
    bool extractVideos = true,
    bool convertToMarkdown = true,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('🌐 [OpenClaw Media] Scraping web content: $url');
      }

      final response = await http.post(
        Uri.parse('$_gatewayUrl/media/scrape-web'),
        headers: {
          'Authorization': 'Bearer $_gatewayToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'url': url,
          'extract_images': extractImages,
          'extract_videos': extractVideos,
          'convert_to_markdown': convertToMarkdown,
          'extract_metadata': true,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (kDebugMode) {
          debugPrint('✅ [OpenClaw Media] Web content scraped');
          debugPrint('   Images found: ${(data['images'] as List?)?.length ?? 0}');
          debugPrint('   Videos found: ${(data['videos'] as List?)?.length ?? 0}');
        }

        return {
          'service': 'openclaw',
          'success': true,
          ...data,
        };
      } else {
        throw Exception('Web scraping failed: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [OpenClaw Media] Web scraping failed: $e');
      }

      return {
        'service': 'fallback',
        'success': false,
        'error': e.toString(),
        'url': url,
      };
    }
  }

  // ════════════════════════════════════════════════════════════
  // 🛠️ UTILITY METHODS
  // ════════════════════════════════════════════════════════════

  /// Format aus URL extrahieren
  String _getFormatFromUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return 'unknown';
    
    final path = uri.path.toLowerCase();
    if (path.endsWith('.jpg') || path.endsWith('.jpeg')) return 'jpeg';
    if (path.endsWith('.png')) return 'png';
    if (path.endsWith('.webp')) return 'webp';
    if (path.endsWith('.gif')) return 'gif';
    if (path.endsWith('.svg')) return 'svg';
    if (path.endsWith('.pdf')) return 'pdf';
    if (path.endsWith('.mp4')) return 'mp4';
    if (path.endsWith('.webm')) return 'webm';
    if (path.endsWith('.mp3')) return 'mp3';
    if (path.endsWith('.wav')) return 'wav';
    if (path.endsWith('.ogg')) return 'ogg';
    
    return 'unknown';
  }

  /// Cache leeren
  void clearCache() {
    _mediaCache.clear();
    if (kDebugMode) {
      debugPrint('🗑️ [OpenClaw Media] Cache cleared');
    }
  }

  /// Cache-Größe abrufen
  int getCacheSize() {
    return _mediaCache.length;
  }

  /// Service-Health-Check
  Future<bool> checkServiceHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$_gatewayUrl/health'),
        headers: {'Authorization': 'Bearer $_gatewayToken'},
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

// ════════════════════════════════════════════════════════════
// MODELS
// ════════════════════════════════════════════════════════════

/// Cached Media Item
class CachedMedia {
  final Map<String, dynamic> data;
  final DateTime timestamp;

  CachedMedia({
    required this.data,
    required this.timestamp,
  });
}
