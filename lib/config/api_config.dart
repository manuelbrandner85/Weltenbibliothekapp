/// API CONFIGURATION SERVICE
/// 
/// Zentrale Verwaltung aller Backend-URLs und API-Endpoints.
/// Single Source of Truth für API-Konfiguration.
/// 
/// VORHER: 32x hardcoded URLs über 23 Dateien verteilt
/// NACHHER: 1x zentrale Konfiguration
///
/// Migration Status: ✅ COMPLETE
/// - V2 API (Primary): weltenbibliothek-api-v2.brandy13062.workers.dev
/// - All core services migrated to V2
library;

import 'package:flutter/foundation.dart';

class ApiConfig {
  // ==========================================================================
  // BACKEND URLS
  // ==========================================================================
  
  /// V2 API (PRIMARY) - All Services
  /// Verwendet für: Admin, Profile, User Management, Content Management, Tools
  static const String _v2BaseUrl = 'https://weltenbibliothek-api-v2.brandy13062.workers.dev';
  
  /// Public getter for V2 API URL
  static String get v2ApiUrl => _v2BaseUrl;
  
  // ==========================================================================
  // ENVIRONMENT CONFIGURATION
  // ==========================================================================
  
  /// Cloudflare API Token (Primary)
  /// 🔐 SECURITY: In production, use environment variables
  static const String cloudflareApiToken = 'y-Xiv3kKeiybDm2CV0yLFu7TSd22co6NBw3udn5Y';
  
  /// Cloudflare API Token (Backup)
  static const String cloudflareApiTokenBackup = 'XCz3muf7asVj-lBgXXG3ZiY9wJ_TLelzJQZ9jutB';
  
  /// Current Environment
  static const String environment = kDebugMode ? 'development' : 'production';
  
  /// Is Development Mode
  static bool get isDevelopment => kDebugMode;
  
  /// Is Production Mode
  static bool get isProduction => !kDebugMode;
  
  // ==========================================================================
  // PRIMARY API ENDPOINTS
  // ==========================================================================
  
  /// Main API Base URL (V2)
  static String get baseUrl => _v2BaseUrl;
  
  // ==========================================================================
  // SERVICE-SPECIFIC ENDPOINTS
  // ==========================================================================
  
  // --- ADMIN & MANAGEMENT (V2) ---
  
  /// Profile API Base
  static String get profileApiUrl => '$_v2BaseUrl/api/profile';
  
  /// World Admin API Base
  static String get worldAdminApiUrl => '$_v2BaseUrl/api/admin';
  
  /// User Management API Base
  static String get userManagementApiUrl => '$_v2BaseUrl/api/users';
  
  /// Content Management API Base
  static String get contentManagementApiUrl => '$_v2BaseUrl/api/content';
  
  /// Moderation API Base
  static String get moderationApiUrl => '$_v2BaseUrl/api/moderation';
  
  // --- TOOLS & COMMUNITY (V2) ---
  
  /// Tools API Base (V2)
  static String get toolsApiUrl => '$_v2BaseUrl/api/tools';
  
  /// Chat API Base
  /// ✅ PRODUCTION: Deployed Cloudflare Worker
  /// FIXED: Use actual deployed WebSocket worker
  static String get chatApiUrl => 'https://weltenbibliothek-websocket.brandy13062.workers.dev';
  
  /// Push Notification API Base
  /// Status: ✅ V2
  static String get pushApiUrl => '$_v2BaseUrl/api/push';
  
  /// AI Service API Base
  /// Status: ✅ V2
  static String get aiApiUrl => '$_v2BaseUrl/api/ai';
  
  /// Cloud Sync API Base
  /// Status: ✅ V2
  static String get cloudSyncApiUrl => '$_v2BaseUrl/api/sync';
  
  // --- WEBSOCKET ENDPOINTS ---
  
  /// WebSocket Base URL (Production - Cloudflare Durable Objects)
  /// Status: ✅ DEPLOYED
  static String get websocketUrl => 'wss://weltenbibliothek-websocket.brandy13062.workers.dev';
  
  // ==========================================================================
  // PUSH NOTIFICATION ENDPOINTS (V2.0.0)
  // ==========================================================================
  
  /// Push Notification Base URL
  static String get pushNotificationBaseUrl => 'https://weltenbibliothek-websocket.brandy13062.workers.dev';
  
  /// Register Push Token
  static String get pushRegisterUrl => '$pushNotificationBaseUrl/push/register';
  
  /// Send Push Notification
  static String get pushSendUrl => '$pushNotificationBaseUrl/push/send';
  
  // ==========================================================================
  // HEALTH CHECK & MONITORING
  // ==========================================================================
  
  /// Health Check Endpoint (V2)
  static String get healthCheckUrl => '$_v2BaseUrl/health';
  
  /// V1 Health Check (Legacy)
  /// Status: ✅ V2
  static String get legacyHealthCheckUrl => '$_v2BaseUrl/health';
  
  // ==========================================================================
  // INLINE-TOOL ENDPOINTS (V1 → V2 Migration)
  // ==========================================================================
  
  /// Chakra Scanner Endpoint
  static String get chakraReadingsUrl => '$toolsApiUrl/chakra-readings';
  
  /// Artefakt Collection Endpoint
  static String get artefakteUrl => '$toolsApiUrl/artefakte';
  
  /// Connections Board Endpoint
  static String get connectionsUrl => '$toolsApiUrl/connections';
  
  /// Heilfrequenz Player Endpoint
  static String get heilfrequenzUrl => '$toolsApiUrl/heilfrequenz-sessions';
  
  /// News Board Endpoint
  static String get newsTrackerUrl => '$toolsApiUrl/news-tracker';
  
  /// Patent Archive Endpoint
  static String get patenteUrl => '$toolsApiUrl/patente';
  
  /// Traum Tagebuch Endpoint
  static String get traeumeUrl => '$toolsApiUrl/traeume';
  
  /// UFO Sichtungen Endpoint
  static String get ufoSichtungenUrl => '$toolsApiUrl/ufo-sichtungen';
  
  /// Bewusstseins Journal Endpoint
  static String get bewusstseinsEintraegeUrl => '$toolsApiUrl/bewusstseins-eintraege';
  
  /// Group Meditation Endpoint
  static String get meditationSessionsUrl => '$toolsApiUrl/meditation-sessions';
  
  // ==========================================================================
  // TIMEOUT CONFIGURATION
  // ==========================================================================
  
  /// Default HTTP Timeout
  static const Duration defaultTimeout = Duration(seconds: 30);
  
  /// Upload Timeout (für Bilder/Files)
  static const Duration uploadTimeout = Duration(seconds: 60);
  
  /// WebSocket Timeout
  static const Duration websocketTimeout = Duration(seconds: 10);
  
  // ==========================================================================
  // RETRY CONFIGURATION
  // ==========================================================================
  
  /// Maximum Retry Attempts
  static const int maxRetries = 3;
  
  /// Retry Delay
  static const Duration retryDelay = Duration(seconds: 2);
  
  // ==========================================================================
  // DEBUG HELPERS
  // ==========================================================================
  
  /// Print API Configuration (Development only)
  static void printConfig() {
    if (kDebugMode) {
      print('=== API CONFIGURATION ===');
      print('Environment: $environment');
      print('Base URL (V2): $baseUrl');
      print('Legacy URL (V1): $_v2BaseUrl');
      print('Tools API: $toolsApiUrl');
      print('Profile API: $profileApiUrl');
      print('Admin API: $worldAdminApiUrl');
      print('Health Check: $healthCheckUrl');
      print('========================');
    }
  }
  
  /// Validate Configuration
  static bool validate() {
    try {
      // Check V2 URL
      if (!_v2BaseUrl.startsWith('https://')) {
        if (kDebugMode) print('❌ V2 URL invalid: $_v2BaseUrl');
        return false;
      }
      
      // Check V1 URL
      if (!_v2BaseUrl.startsWith('https://')) {
        if (kDebugMode) print('❌ V1 URL invalid: $_v2BaseUrl');
        return false;
      }
      
      if (kDebugMode) print('✅ API Config validated');
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ API Config validation failed: $e');
      return false;
    }
  }
  
  // ==========================================================================
  // MIGRATION HELPERS
  // ==========================================================================
  
  /// Get migration status for a service
  static String getMigrationStatus(String serviceName) {
    // V2 Services (Complete)
    const v2Services = [
      'profile_sync_service',
      'world_admin_service',
      'user_management_service',
      'content_management_service',
      'moderation_service',
      'backend_health_service',
      'admin_state',
    ];
    
    if (v2Services.contains(serviceName)) {
      return '✅ V2 (Complete)';
    }
    
    return '⏳ V1 (Migration Pending)';
  }
}
