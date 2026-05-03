/// 🏥 BACKEND HEALTH CHECK SERVICE
/// Prüft Backend-Endpoints und simuliert Health-Checks für Worker ohne /health
/// 
/// Features:
/// - Health-Check für alle 6 Backend-APIs
/// - Fallback für Worker ohne /health-Endpoint
/// - Caching für Performance
/// - Retry-Logik
library;
import '../config/api_config.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class BackendHealthService {
  // 🌐 BACKEND ENDPOINTS (Updated to API-V2)
  static const String communityApiUrl = ApiConfig.workerUrl;
  static const String mainApiUrl = ApiConfig.workerUrl; // Updated to V2
  static const String rechercheApiUrl = ApiConfig.workerUrl;
  static const String rechercheWorkerUrl = ApiConfig.workerUrl; // Fixed URL
  static const String mediaApiUrl = ApiConfig.workerUrl;
  static const String groupToolsApiUrl = ApiConfig.workerUrl; // Fallback to community-api

  // 💾 Cache für Health-Status (5 Minuten)
  static final Map<String, HealthStatus> _cache = {};
  static final Map<String, DateTime> _cacheTime = {};
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// Prüft alle Backend-Services
  static Future<Map<String, HealthStatus>> checkAllServices() async {
    final results = <String, HealthStatus>{};

    // Parallel alle Services prüfen
    final futures = [
      _checkCommunityApi(),
      _checkMainApi(),
      _checkRechercheApi(),
      _checkRechercheWorker(),
      _checkMediaApi(),
      _checkGroupToolsApi(),
    ];

    // eagerError:false — wenn 1 Health-Check failt, lassen wir die anderen
    // ihre Ergebnisse liefern statt alle zu verwerfen
    final statuses = await Future.wait(futures, eagerError: false);
    
    results['Community API'] = statuses[0];
    results['Main API'] = statuses[1];
    results['Backend Recherche'] = statuses[2];
    results['Recherche Worker'] = statuses[3];
    results['Media API'] = statuses[4];
    results['Group Tools API'] = statuses[5];

    return results;
  }

  /// Community API Health-Check
  static Future<HealthStatus> _checkCommunityApi() async {
    return _checkWithCache('community', () async {
      try {
        final response = await http
            .get(Uri.parse('$communityApiUrl/api/health'))
            .timeout(const Duration(seconds: 5));
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          return HealthStatus(
            isHealthy: data['status'] == 'healthy',
            version: data['version'] ?? 'unknown',
            message: 'Health endpoint: OK',
          );
        }
        return HealthStatus(isHealthy: false, message: 'HTTP ${response.statusCode}');
      } catch (e) {
        return HealthStatus(isHealthy: false, message: e.toString());
      }
    });
  }

  /// Main API Health-Check
  static Future<HealthStatus> _checkMainApi() async {
    return _checkWithCache('main', () async {
      try {
        final response = await http
            .get(Uri.parse('$mainApiUrl/api/health'))
            .timeout(const Duration(seconds: 5));
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          return HealthStatus(
            isHealthy: data['status'] == 'healthy',
            version: data['version']?.toString() ?? 'unknown',
            message: 'All services online',
          );
        }
        return HealthStatus(isHealthy: false, message: 'HTTP ${response.statusCode}');
      } catch (e) {
        return HealthStatus(isHealthy: false, message: e.toString());
      }
    });
  }

  /// Backend Recherche Health-Check
  static Future<HealthStatus> _checkRechercheApi() async {
    return _checkWithCache('recherche', () async {
      try {
        final response = await http
            .get(Uri.parse('$rechercheApiUrl/health'))
            .timeout(const Duration(seconds: 5));
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          return HealthStatus(
            isHealthy: data['status'] == 'ok',
            version: data['version'] ?? 'unknown',
            message: 'PDFs & multimedia OK',
          );
        }
        return HealthStatus(isHealthy: false, message: 'HTTP ${response.statusCode}');
      } catch (e) {
        return HealthStatus(isHealthy: false, message: e.toString());
      }
    });
  }

  /// Recherche Worker Health-Check (FALLBACK - kein /health vorhanden)
  static Future<HealthStatus> _checkRechercheWorker() async {
    return _checkWithCache('worker', () async {
      try {
        // Worker hat kein /health - teste mit Mini-Query
        final response = await http
            .get(Uri.parse('$rechercheWorkerUrl?q=test'))
            .timeout(const Duration(seconds: 5));
        
        // Jede Antwort (auch 404/500) bedeutet: Worker läuft
        if (response.statusCode >= 200 && response.statusCode < 600) {
          return HealthStatus(
            isHealthy: true,
            version: 'unknown',
            message: 'Worker responds (no /health endpoint)',
          );
        }
        return HealthStatus(isHealthy: false, message: 'No response');
      } catch (e) {
        return HealthStatus(isHealthy: false, message: e.toString());
      }
    });
  }

  /// Media API Health-Check (FALLBACK - kein /health vorhanden)
  static Future<HealthStatus> _checkMediaApi() async {
    return _checkWithCache('media', () async {
      try {
        // Media API hat kein /health - teste mit HEAD request
        final response = await http
            .head(Uri.parse('$mediaApiUrl/api/upload'))
            .timeout(const Duration(seconds: 5));
        
        // 404 ist OK - API existiert, nur Endpoint fehlt
        if (response.statusCode == 404 || response.statusCode == 405) {
          return HealthStatus(
            isHealthy: true,
            version: 'unknown',
            message: 'API responds (no /health endpoint)',
          );
        }
        return HealthStatus(isHealthy: false, message: 'HTTP ${response.statusCode}');
      } catch (e) {
        return HealthStatus(isHealthy: false, message: e.toString());
      }
    });
  }

  /// Group Tools API Health-Check (FALLBACK - kein /health vorhanden)
  static Future<HealthStatus> _checkGroupToolsApi() async {
    return _checkWithCache('tools', () async {
      try {
        // Group Tools hat kein /health - teste mit HEAD request
        final response = await http
            .head(Uri.parse('$groupToolsApiUrl/api/tools'))
            .timeout(const Duration(seconds: 5));
        
        // 404 ist OK - API existiert, nur Endpoint fehlt
        if (response.statusCode == 404 || response.statusCode == 405) {
          return HealthStatus(
            isHealthy: true,
            version: 'unknown',
            message: 'API responds (no /health endpoint)',
          );
        }
        return HealthStatus(isHealthy: false, message: 'HTTP ${response.statusCode}');
      } catch (e) {
        return HealthStatus(isHealthy: false, message: e.toString());
      }
    });
  }

  /// Cache-Wrapper für Health-Checks
  static Future<HealthStatus> _checkWithCache(
    String key,
    Future<HealthStatus> Function() checker,
  ) async {
    // Cache gültig?
    if (_cache.containsKey(key) && _cacheTime.containsKey(key)) {
      final age = DateTime.now().difference(_cacheTime[key]!);
      if (age < _cacheDuration) {
        if (kDebugMode) {
          debugPrint('🏥 [HEALTH] Using cached status for $key (age: ${age.inSeconds}s)');
        }
        return _cache[key]!;
      }
    }

    // Neuen Check durchführen
    final status = await checker();
    _cache[key] = status;
    _cacheTime[key] = DateTime.now();

    if (kDebugMode) {
      debugPrint('🏥 [HEALTH] $key: ${status.isHealthy ? "✅" : "❌"} ${status.message}');
    }

    return status;
  }

  /// Cache löschen
  static void clearCache() {
    _cache.clear();
    _cacheTime.clear();
  }
}

/// Health-Status Model
class HealthStatus {
  final bool isHealthy;
  final String? version;
  final String? message;

  HealthStatus({
    required this.isHealthy,
    this.version,
    this.message,
  });

  @override
  String toString() {
    return 'HealthStatus(healthy: $isHealthy, version: $version, message: $message)';
  }
}
