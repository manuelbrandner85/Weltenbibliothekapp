/// 🦞 OpenClaw Admin Service - Intelligente Admin-Funktionen über OpenClaw Gateway
/// 
/// Bietet erweiterte Admin-Features mit KI-gestützter Moderation und Entscheidungsfindung
/// 
/// Features:
/// - 🤖 KI-gestützte Content-Moderation
/// - 🎯 Intelligente Ban-Empfehlungen
/// - 📊 Advanced Analytics & Insights
/// - 🔍 Pattern-basierte User-Analyse
/// - ⚖️ Faire Entscheidungsvorschläge
library;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'world_admin_service.dart'; // Fallback zu Cloudflare

/// OpenClaw Admin Service mit KI-gestützten Admin-Features
class OpenClawAdminService {
  static final OpenClawAdminService _instance = OpenClawAdminService._internal();
  factory OpenClawAdminService() => _instance;
  OpenClawAdminService._internal();

  // OpenClaw Gateway Configuration
  static String get _gatewayUrl => ApiConfig.openClawGatewayUrl;
  static String get _gatewayToken => ApiConfig.openClawGatewayToken;
  
  // Fallback Service
  final WorldAdminService _fallback = WorldAdminService();
  
  // Cache für schnellere Antworten
  final Map<String, dynamic> _cache = {};
  static const Duration _cacheDuration = Duration(minutes: 5);

  // ════════════════════════════════════════════════════════════
  // 🤖 KI-GESTÜTZTE CONTENT-MODERATION
  // ════════════════════════════════════════════════════════════

  /// Analysiert Content mit KI und gibt Moderations-Empfehlung
  /// 
  /// Features:
  /// - Toxizitäts-Erkennung
  /// - Spam-Detection
  /// - Hate-Speech-Analyse
  /// - Context-Awareness
  /// 
  /// Returns:
  /// {
  ///   'shouldModerate': bool,
  ///   'severity': 'low' | 'medium' | 'high' | 'critical',
  ///   'reasons': List<String>,
  ///   'confidence': 0.0 - 1.0,
  ///   'suggestedAction': 'warn' | 'mute' | 'ban' | 'delete',
  ///   'explanation': String
  /// }
  Future<Map<String, dynamic>> analyzeContent({
    required String content,
    required String contentType, // 'message' | 'post' | 'comment'
    required String world,
    String? userId,
    String? username,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('🤖 [OpenClaw Admin] Analyzing content for moderation');
      }

      final response = await http.post(
        Uri.parse('$_gatewayUrl/admin/analyze-content'),
        headers: {
          'Authorization': 'Bearer $_gatewayToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'content': content,
          'content_type': contentType,
          'world': world,
          'user_id': userId,
          'username': username,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (kDebugMode) {
          debugPrint('✅ [OpenClaw Admin] Content analysis complete');
          debugPrint('   Severity: ${data['severity']}');
          debugPrint('   Should Moderate: ${data['shouldModerate']}');
        }

        return {
          'service': 'openclaw',
          'success': true,
          ...data,
        };
      } else {
        throw Exception('OpenClaw analysis failed: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [OpenClaw Admin] Content analysis failed: $e');
        debugPrint('   Using rule-based fallback...');
      }

      // Fallback: Einfache regel-basierte Analyse
      return _simpleModerationFallback(content);
    }
  }

  /// Fallback: Einfache regel-basierte Content-Moderation
  Map<String, dynamic> _simpleModerationFallback(String content) {
    final lowerContent = content.toLowerCase();
    
    // Einfache Spam-Erkennung
    final spamPatterns = ['http://', 'https://', 'www.', 'buy now', 'click here'];
    final hasSpam = spamPatterns.any((pattern) => lowerContent.contains(pattern));
    
    // Einfache Toxizitäts-Erkennung
    final toxicWords = ['idiot', 'stupid', 'hate', 'kill', 'die'];
    final hasToxic = toxicWords.any((word) => lowerContent.contains(word));
    
    final shouldModerate = hasSpam || hasToxic;
    final severity = hasToxic ? 'high' : hasSpam ? 'medium' : 'low';
    
    return {
      'service': 'fallback',
      'success': true,
      'shouldModerate': shouldModerate,
      'severity': severity,
      'reasons': [
        if (hasSpam) 'Possible spam detected',
        if (hasToxic) 'Potentially toxic language',
      ],
      'confidence': 0.6,
      'suggestedAction': hasToxic ? 'warn' : hasSpam ? 'delete' : 'none',
      'explanation': 'Rule-based analysis (OpenClaw unavailable)',
    };
  }

  // ════════════════════════════════════════════════════════════
  // 🎯 INTELLIGENTE BAN-EMPFEHLUNGEN
  // ════════════════════════════════════════════════════════════

  /// Analysiert User-Verhalten und gibt Ban-Empfehlung
  /// 
  /// Berücksichtigt:
  /// - Vergangene Verstöße
  /// - Häufigkeit von Reports
  /// - Content-Qualität
  /// - Community-Feedback
  /// 
  /// Returns:
  /// {
  ///   'shouldBan': bool,
  ///   'banDuration': 'permanent' | '1d' | '7d' | '30d',
  ///   'reason': String,
  ///   'evidence': List<String>,
  ///   'confidence': 0.0 - 1.0
  /// }
  Future<Map<String, dynamic>> recommendBanAction({
    required String userId,
    required String world,
    List<Map<String, dynamic>>? recentMessages,
    List<Map<String, dynamic>>? reports,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('🎯 [OpenClaw Admin] Analyzing ban recommendation for user $userId');
      }

      final response = await http.post(
        Uri.parse('$_gatewayUrl/admin/recommend-ban'),
        headers: {
          'Authorization': 'Bearer $_gatewayToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id': userId,
          'world': world,
          'recent_messages': recentMessages ?? [],
          'reports': reports ?? [],
          'timestamp': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (kDebugMode) {
          debugPrint('✅ [OpenClaw Admin] Ban recommendation complete');
          debugPrint('   Should Ban: ${data['shouldBan']}');
          debugPrint('   Confidence: ${data['confidence']}');
        }

        return {
          'service': 'openclaw',
          'success': true,
          ...data,
        };
      } else {
        throw Exception('OpenClaw ban recommendation failed: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [OpenClaw Admin] Ban recommendation failed: $e');
      }

      // Fallback: Konservative Empfehlung
      return {
        'service': 'fallback',
        'success': true,
        'shouldBan': false,
        'banDuration': 'none',
        'reason': 'Manual review recommended (AI unavailable)',
        'evidence': [],
        'confidence': 0.5,
      };
    }
  }

  // ════════════════════════════════════════════════════════════
  // 📊 ADVANCED USER ANALYTICS
  // ════════════════════════════════════════════════════════════

  /// Erstellt detailliertes User-Profil für Admin-Entscheidungen
  /// 
  /// Analysiert:
  /// - Aktivitätsmuster
  /// - Content-Qualität
  /// - Community-Engagement
  /// - Verhaltens-Trends
  /// 
  /// Returns:
  /// {
  ///   'riskScore': 0-100,
  ///   'activityLevel': 'low' | 'medium' | 'high',
  ///   'contentQuality': 'poor' | 'average' | 'good' | 'excellent',
  ///   'warnings': List<String>,
  ///   'insights': List<String>
  /// }
  Future<Map<String, dynamic>> getUserAnalytics({
    required String userId,
    required String world,
    int daysBack = 30,
  }) async {
    // Cache-Key
    final cacheKey = 'user_analytics_${userId}_${world}_$daysBack';
    
    // Cache prüfen
    if (_cache.containsKey(cacheKey)) {
      final cached = _cache[cacheKey];
      if (DateTime.now().difference(cached['timestamp']).inMinutes < _cacheDuration.inMinutes) {
        if (kDebugMode) {
          debugPrint('📦 [OpenClaw Admin] Using cached analytics for $userId');
        }
        return cached['data'];
      }
    }

    try {
      if (kDebugMode) {
        debugPrint('📊 [OpenClaw Admin] Fetching user analytics for $userId');
      }

      final response = await http.get(
        Uri.parse('$_gatewayUrl/admin/user-analytics/$userId')
            .replace(queryParameters: {
          'world': world,
          'days_back': daysBack.toString(),
        }),
        headers: {
          'Authorization': 'Bearer $_gatewayToken',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Cache speichern
        _cache[cacheKey] = {
          'timestamp': DateTime.now(),
          'data': {'service': 'openclaw', 'success': true, ...data},
        };

        if (kDebugMode) {
          debugPrint('✅ [OpenClaw Admin] User analytics complete');
          debugPrint('   Risk Score: ${data['riskScore']}');
        }

        return _cache[cacheKey]['data'];
      } else {
        throw Exception('OpenClaw analytics failed: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [OpenClaw Admin] Analytics failed: $e');
      }

      // Fallback: Basis-Analytics
      return {
        'service': 'fallback',
        'success': true,
        'riskScore': 50,
        'activityLevel': 'medium',
        'contentQuality': 'average',
        'warnings': ['AI analytics unavailable'],
        'insights': ['Manual review recommended'],
      };
    }
  }

  // ════════════════════════════════════════════════════════════
  // 🔍 PATTERN-BASIERTE USER-ANALYSE
  // ════════════════════════════════════════════════════════════

  /// Erkennt verdächtige Aktivitätsmuster
  /// 
  /// Patterns:
  /// - Spam-Behavior
  /// - Bot-Activity
  /// - Coordinated Attacks
  /// - Multi-Account Abuse
  Future<Map<String, dynamic>> detectSuspiciousPatterns({
    required String userId,
    required String world,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_gatewayUrl/admin/detect-patterns'),
        headers: {
          'Authorization': 'Bearer $_gatewayToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id': userId,
          'world': world,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return {
          'service': 'openclaw',
          'success': true,
          ...jsonDecode(response.body),
        };
      } else {
        throw Exception('Pattern detection failed: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [OpenClaw Admin] Pattern detection failed: $e');
      }

      return {
        'service': 'fallback',
        'success': true,
        'patterns': [],
        'suspiciousActivity': false,
      };
    }
  }

  // ════════════════════════════════════════════════════════════
  // 🛠️ UTILITY METHODS
  // ════════════════════════════════════════════════════════════

  /// Cache leeren
  void clearCache() {
    _cache.clear();
    if (kDebugMode) {
      debugPrint('🗑️ [OpenClaw Admin] Cache cleared');
    }
  }

  /// Service-Status prüfen
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
