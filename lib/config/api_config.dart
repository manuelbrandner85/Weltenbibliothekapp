/// 🔥 WELTENBIBLIOTHEK API CONFIGURATION
/// 
/// Zentrale Konfiguration für alle Backend-API-Aufrufe
/// 
/// ⚠️ PRODUCTION-READY: Echte API-Tokens für Cloudflare Worker V3.1
library;

class ApiConfig {
  // 🌐 BASE URL
  static const String baseUrl = 'https://weltenbibliothek-api-v3.brandy13062.workers.dev';
  
  // 🔐 AUTHENTICATION
  static const String apiToken = 'y-Xiv3kKeiybDm2CV0yLFu7TSd22co6NBw3udn5Y';
  static const String cloudflareApiToken = 'y-Xiv3kKeiybDm2CV0yLFu7TSd22co6NBw3udn5Y'; // Alias for compatibility
  
  // 📡 ENDPOINTS
  static const String recherche = '/recherche'; // ⚠️ Ohne /api Prefix!
  static const String contentSearch = '/api/content/search';
  static const String chat = '/api/chat/messages'; // ⚠️ Korrekt: /messages Suffix
  static const String voiceJoin = '/voice/join';
  static const String voiceLeave = '/voice/leave';
  static const String voiceEndRoom = '/voice/end-room';
  static const String voiceRooms = '/voice/rooms';
  static const String voiceParticipants = '/voice/participants';
  static const String adminUsers = '/admin/users';
  static const String adminBan = '/admin/ban';
  static const String adminKick = '/admin/kick';
  static const String adminAudit = '/admin/audit';
  static const String adminReports = '/admin/reports';
  
  // 🔗 FULL URLs (for services that need complete URLs)
  static String get pushApiUrl => '$baseUrl/api/push';
  static String get v2ApiUrl => '$baseUrl/api/v2';
  static String get voiceApiUrl => '$baseUrl/voice';
  static String get pushRegisterUrl => '$baseUrl/api/push/register';
  static String get pushSendUrl => '$baseUrl/api/push/send';
  static String get aiApiUrl => '$baseUrl/ai';
  static String get profileApiUrl => '$baseUrl/api/sync';
  static String get cloudSyncApiUrl => '$baseUrl/api/sync';
  static String get websocketUrl => baseUrl.replaceAll('https://', 'wss://');
  
  // 🔧 INLINE TOOLS URLs
  static String get artefakteUrl => '$baseUrl/api/tools/artefakte';
  static String get chakraReadingsUrl => '$baseUrl/api/tools/chakra-readings';
  static String get connectionsUrl => '$baseUrl/api/tools/connections';
  static String get heilfrequenzUrl => '$baseUrl/api/tools/heilfrequenz';
  static String get newsTrackerUrl => '$baseUrl/api/tools/news-tracker';
  static String get patenteUrl => '$baseUrl/api/tools/patente';
  static String get traeumeUrl => '$baseUrl/api/tools/traeume';
  static String get ufoSichtungenUrl => '$baseUrl/api/tools/ufo-sichtungen';
  
  // 🛠️ UTILITY METHODS
  
  /// Get full URL for endpoint
  static String getUrl(String endpoint) => '$baseUrl$endpoint';
  
  /// Get default headers with authentication
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $apiToken',
  };
  
  /// Get headers without authentication (for public endpoints)
  static Map<String, String> get publicHeaders => {
    'Content-Type': 'application/json',
  };
}
