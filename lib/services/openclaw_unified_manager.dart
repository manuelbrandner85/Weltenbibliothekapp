/// 🦞 OpenClaw Unified Service Manager
/// 
/// Intelligenter Manager für alle OpenClaw-Services:
/// - 🤖 Admin & Moderation
/// - 🎙️ WebRTC & VoiceChat
/// - 🔍 Research & Analysis
/// - 📊 Analytics & Insights
/// - 🎬 Media Scraping (Bilder, PDFs, Videos, Audio)
/// 
/// Features:
/// - Automatisches Fallback-Management
/// - Service-Health-Monitoring
/// - Load-Balancing
/// - Intelligent Caching
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'openclaw_admin_service.dart';
import 'openclaw_webrtc_proxy_service.dart';
import 'openclaw_gateway_service.dart';
import 'openclaw_media_scraper_service.dart';
import 'ai_service_manager.dart';

/// Unified Service Manager für alle OpenClaw-Features
class OpenClawUnifiedManager {
  static final OpenClawUnifiedManager _instance = OpenClawUnifiedManager._internal();
  factory OpenClawUnifiedManager() => _instance;
  OpenClawUnifiedManager._internal() {
    _init();
  }

  // Service-Instanzen
  late final OpenClawAdminService adminService;
  late final OpenClawWebRTCProxyService webrtcService;
  late final OpenClawGatewayService gatewayService;
  late final OpenClawMediaScraperService mediaService;
  late final AIServiceManager aiService;

  // Service-Status
  bool _isInitialized = false;
  Map<String, bool> _serviceHealth = {};
  Timer? _healthCheckTimer;

  // ════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ════════════════════════════════════════════════════════════

  void _init() {
    if (_isInitialized) return;

    adminService = OpenClawAdminService();
    webrtcService = OpenClawWebRTCProxyService();
    gatewayService = OpenClawGatewayService();
    mediaService = OpenClawMediaScraperService();
    aiService = AIServiceManager();

    _startHealthMonitoring();
    _isInitialized = true;

    if (kDebugMode) {
      debugPrint('🦞 [OpenClaw Unified] Manager initialized with Media Scraper');
    }
  }

  // ════════════════════════════════════════════════════════════
  // ADMIN FUNKTIONEN
  // ════════════════════════════════════════════════════════════

  /// 🤖 KI-gestützte Content-Moderation
  /// 
  /// Analysiert Content automatisch und gibt Empfehlungen
  Future<Map<String, dynamic>> moderateContent({
    required String content,
    required String contentType,
    required String world,
    String? userId,
    String? username,
  }) async {
    try {
      return await adminService.analyzeContent(
        content: content,
        contentType: contentType,
        world: world,
        userId: userId,
        username: username,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [OpenClaw Unified] Content moderation failed: $e');
      }
      rethrow;
    }
  }

  /// 🎯 Ban-Empfehlung für User
  Future<Map<String, dynamic>> recommendBan({
    required String userId,
    required String world,
    List<Map<String, dynamic>>? recentMessages,
    List<Map<String, dynamic>>? reports,
  }) async {
    try {
      return await adminService.recommendBanAction(
        userId: userId,
        world: world,
        recentMessages: recentMessages,
        reports: reports,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [OpenClaw Unified] Ban recommendation failed: $e');
      }
      rethrow;
    }
  }

  /// 📊 Detaillierte User-Analytics
  Future<Map<String, dynamic>> getUserAnalytics({
    required String userId,
    required String world,
    int daysBack = 30,
  }) async {
    try {
      return await adminService.getUserAnalytics(
        userId: userId,
        world: world,
        daysBack: daysBack,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [OpenClaw Unified] User analytics failed: $e');
      }
      rethrow;
    }
  }

  /// 🔍 Verdächtige Muster erkennen
  Future<Map<String, dynamic>> detectSuspiciousPatterns({
    required String userId,
    required String world,
  }) async {
    try {
      return await adminService.detectSuspiciousPatterns(
        userId: userId,
        world: world,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [OpenClaw Unified] Pattern detection failed: $e');
      }
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════
  // WEBRTC / VOICECHAT FUNKTIONEN
  // ════════════════════════════════════════════════════════════

  /// 🎙️ Intelligentes Voice Room Join
  /// 
  /// Verwendet OpenClaw für optimale Room-Zuweisung
  Future<EnhancedJoinResponse> joinVoiceRoom({
    required String roomId,
    required String userId,
    required String username,
    required String world,
  }) async {
    try {
      return await webrtcService.joinVoiceRoomIntelligent(
        roomId: roomId,
        userId: userId,
        username: username,
        world: world,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [OpenClaw Unified] Voice join failed: $e');
      }
      rethrow;
    }
  }

  /// 🔊 Audio-Stream moderieren
  Future<Map<String, dynamic>> moderateAudio({
    required String userId,
    required String roomId,
    Map<String, dynamic>? audioMetrics,
  }) async {
    try {
      return await webrtcService.moderateAudioStream(
        userId: userId,
        roomId: roomId,
        audioMetrics: audioMetrics,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [OpenClaw Unified] Audio moderation failed: $e');
      }
      rethrow;
    }
  }

  /// 🎯 Optimalen Voice-Room finden
  Future<String?> findOptimalVoiceRoom({
    required String world,
    required String userId,
    List<String>? availableRooms,
  }) async {
    try {
      return await webrtcService.findOptimalRoom(
        world: world,
        userId: userId,
        availableRooms: availableRooms,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [OpenClaw Unified] Room matching failed: $e');
      }
      return null;
    }
  }

  /// 📊 Voice-Analytics abrufen
  Future<Map<String, dynamic>> getVoiceAnalytics({
    required String userId,
    required String roomId,
    int daysBack = 7,
  }) async {
    try {
      return await webrtcService.getVoiceAnalytics(
        userId: userId,
        roomId: roomId,
        daysBack: daysBack,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [OpenClaw Unified] Voice analytics failed: $e');
      }
      rethrow;
    }
  }

  /// 🛡️ Voice-Abuse erkennen
  Future<Map<String, dynamic>> detectVoiceAbuse({
    required String userId,
    required String roomId,
  }) async {
    try {
      return await webrtcService.detectVoiceAbuse(
        userId: userId,
        roomId: roomId,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [OpenClaw Unified] Abuse detection failed: $e');
      }
      rethrow;
    }
  }

  /// 🚪 Voice Room verlassen
  Future<void> leaveVoiceRoom(String userId) async {
    try {
      await webrtcService.leaveVoiceRoom(userId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [OpenClaw Unified] Leave room failed: $e');
      }
    }
  }

  // ════════════════════════════════════════════════════════════
  // AI RESEARCH FUNKTIONEN (bestehend)
  // ════════════════════════════════════════════════════════════

  /// 🔍 Recherche durchführen
  Future<Map<String, dynamic>> performResearch({
    required String query,
    int minWords = 500,
  }) async {
    try {
      // AIServiceManager nutzt automatisch OpenClaw oder Cloudflare Fallback
      final result = await aiService.research(query: query);
      return result;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [OpenClaw Unified] Research failed: $e');
      }
      rethrow;
    }
  }

  /// 🕵️ Propaganda-Analyse
  Future<Map<String, dynamic>> analyzePropaganda({
    required String text,
  }) async {
    try {
      return await gatewayService.detectPropaganda(text: text);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [OpenClaw Unified] Propaganda analysis failed: $e');
      }
      rethrow;
    }
  }

  /// 💭 Traum-Analyse
  Future<Map<String, dynamic>> analyzeDream({
    required String description,
  }) async {
    try {
      return await aiService.analyzeDream(dreamText: description);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [OpenClaw Unified] Dream analysis failed: $e');
      }
      rethrow;
    }
  }

  /// 🧘 Chakra-Empfehlungen
  Future<Map<String, dynamic>> getChakraRecommendations({
    required String chakra,
  }) async {
    try {
      return await aiService.getChakraRecommendations(
        chakra: chakra,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [OpenClaw Unified] Chakra recommendations failed: $e');
      }
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════
  // SERVICE-HEALTH & MONITORING
  // ════════════════════════════════════════════════════════════

  /// Startet automatisches Health-Monitoring
  void _startHealthMonitoring() {
    _healthCheckTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      await _performHealthCheck();
    });

    // Initial health check
    _performHealthCheck();
  }

  /// Führt Health-Check für alle Services durch
  Future<void> _performHealthCheck() async {
    if (kDebugMode) {
      debugPrint('🔍 [OpenClaw Unified] Performing health check...');
    }

    try {
      final results = await Future.wait([
        adminService.checkServiceHealth(),
        webrtcService.checkServiceHealth(),
      ]);

      _serviceHealth = {
        'admin': results[0],
        'webrtc': results[1],
        'gateway': results[0], // Gateway ist bei Admin integriert
      };

      if (kDebugMode) {
        debugPrint('✅ [OpenClaw Unified] Health check complete');
        _serviceHealth.forEach((service, healthy) {
          debugPrint('   $service: ${healthy ? "✅" : "❌"}');
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [OpenClaw Unified] Health check failed: $e');
      }
    }
  }

  /// Gibt aktuellen Service-Status zurück
  Map<String, dynamic> getSystemStatus() {
    return {
      'initialized': _isInitialized,
      'services': {
        'admin': {
          'available': _serviceHealth['admin'] ?? false,
          'features': [
            'Content Moderation',
            'Ban Recommendations',
            'User Analytics',
            'Pattern Detection',
          ],
        },
        'webrtc': {
          'available': _serviceHealth['webrtc'] ?? false,
          'features': [
            'Intelligent Room Join',
            'Audio Moderation',
            'Room Matching',
            'Voice Analytics',
            'Abuse Detection',
          ],
        },
        'ai': {
          'available': true,
          'features': [
            'Research Tool',
            'Propaganda Detection',
            'Dream Analysis',
            'Chakra Recommendations',
          ],
        },
      },
      'fallback': {
        'enabled': true,
        'services': ['Cloudflare Admin', 'Cloudflare WebRTC', 'Cloudflare AI'],
      },
    };
  }

  /// Gibt Liste der verfügbaren Features zurück
  List<String> getAvailableFeatures() {
    final features = <String>[];

    if (_serviceHealth['admin'] == true) {
      features.addAll([
        'KI-gestützte Content-Moderation',
        'Intelligente Ban-Empfehlungen',
        'Advanced User-Analytics',
        'Pattern-basierte Abuse-Detection',
      ]);
    }

    if (_serviceHealth['webrtc'] == true) {
      features.addAll([
        'Intelligentes Voice Room Join',
        'Echtzeit Audio-Moderation',
        'Smart Room-Matching',
        'Voice-Session-Analytics',
        'Voice-Abuse-Detection',
      ]);
    }

    features.addAll([
      'Recherche-Tool (500+ Wörter)',
      'Propaganda-Detektor',
      'Traum-Analyse',
      'Chakra-Scanner',
      'Meditation-Generator',
      'Intelligentes Bilder-Scraping',
      'PDF-Verarbeitung & Text-Extraktion',
      'Video-Scraping & Thumbnail-Generierung',
      'Audio-Scraping & Transkription',
      'Web-Content-Extraktion',
    ]);

    return features;
  }

  // ════════════════════════════════════════════════════════════
  // 🎬 MEDIA-SCRAPING FUNKTIONEN
  // ════════════════════════════════════════════════════════════

  /// 🖼️ Bild scrapen und optimieren
  Future<Map<String, dynamic>> scrapeImage({
    required String url,
    int? maxWidth,
    int? maxHeight,
    String? format,
    int quality = 85,
  }) async {
    try {
      return await mediaService.scrapeImage(
        url: url,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        format: format,
        quality: quality,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [OpenClaw Unified] Image scraping failed: $e');
      }
      rethrow;
    }
  }

  /// 📄 PDF scrapen und verarbeiten
  Future<Map<String, dynamic>> scrapePDF({
    required String url,
    bool extractText = true,
    bool generateThumbnails = true,
    int maxThumbnails = 5,
  }) async {
    try {
      return await mediaService.scrapePDF(
        url: url,
        extractText: extractText,
        generateThumbnails: generateThumbnails,
        maxThumbnails: maxThumbnails,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [OpenClaw Unified] PDF scraping failed: $e');
      }
      rethrow;
    }
  }

  /// 🎥 Video scrapen und verarbeiten
  Future<Map<String, dynamic>> scrapeVideo({
    required String url,
    String? format,
    int? maxWidth,
    int? maxHeight,
    bool generateThumbnail = true,
  }) async {
    try {
      return await mediaService.scrapeVideo(
        url: url,
        format: format,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        generateThumbnail: generateThumbnail,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [OpenClaw Unified] Video scraping failed: $e');
      }
      rethrow;
    }
  }

  /// 🎵 Audio scrapen und verarbeiten
  Future<Map<String, dynamic>> scrapeAudio({
    required String url,
    String? format,
    int bitrate = 128000,
    bool generateWaveform = false,
    bool transcribe = false,
  }) async {
    try {
      return await mediaService.scrapeAudio(
        url: url,
        format: format,
        bitrate: bitrate,
        generateWaveform: generateWaveform,
        transcribe: transcribe,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [OpenClaw Unified] Audio scraping failed: $e');
      }
      rethrow;
    }
  }

  /// 🌐 Web-Content scrapen
  Future<Map<String, dynamic>> scrapeWebContent({
    required String url,
    bool extractImages = true,
    bool extractVideos = true,
    bool convertToMarkdown = true,
  }) async {
    try {
      return await mediaService.scrapeWebContent(
        url: url,
        extractImages: extractImages,
        extractVideos: extractVideos,
        convertToMarkdown: convertToMarkdown,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [OpenClaw Unified] Web scraping failed: $e');
      }
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════
  // CACHE MANAGEMENT
  // ════════════════════════════════════════════════════════════

  /// Cache für alle Services leeren
  void clearAllCaches() {
    adminService.clearCache();
    mediaService.clearCache();
    // webrtcService hat keinen Cache
    
    if (kDebugMode) {
      debugPrint('🗑️ [OpenClaw Unified] All caches cleared');
    }
  }

  // ════════════════════════════════════════════════════════════
  // CLEANUP
  // ════════════════════════════════════════════════════════════

  /// Cleanup bei App-Beendigung
  void dispose() {
    _healthCheckTimer?.cancel();
    webrtcService.dispose();
    
    if (kDebugMode) {
      debugPrint('👋 [OpenClaw Unified] Manager disposed');
    }
  }
}
