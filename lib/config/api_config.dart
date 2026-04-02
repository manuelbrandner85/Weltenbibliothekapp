/// 🔥 WELTENBIBLIOTHEK API CONFIGURATION
///
/// Zentrale Konfiguration für alle Backend-API-Aufrufe.
///
/// ⚠️ SICHERHEITSREGEL:
///   - KEINE hardcodierten Tokens oder Secrets!
///   - Alle sensitiven Werte kommen aus dart-define oder serverseitigen Secrets.
///   - Für den Flutter-Build: --dart-define=CLOUDFLARE_WORKER_URL=https://...
///
/// VERWENDUNG (Build-Befehl):
///   flutter build apk \
///     --dart-define=CLOUDFLARE_WORKER_URL=https://weltenbibliothek-api.brandy13062.workers.dev \
///     --dart-define=SUPABASE_URL=https://adtviduaftdquvfjpojb.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=eyJ...
library;

class ApiConfig {
  // ──────────────────────────────────────────────────────────────
  // 🌐 CLOUDFLARE WORKER (Haupt-Backend: Edge API, AI, Proxy)
  // ──────────────────────────────────────────────────────────────

  /// Einziger produktiver Cloudflare Worker.
  /// Alle anderen Worker-URLs (v2, v3, backend-v3-2, community-api)
  /// sind veraltet und wurden konsolidiert.
  static const String workerUrl = String.fromEnvironment(
    'CLOUDFLARE_WORKER_URL',
    defaultValue: 'https://weltenbibliothek-api.brandy13062.workers.dev',
  );

  // Rückwärtskompatibilität – zeigen alle auf den einen Worker
  static String get baseUrl => workerUrl;
  static String get mainApiUrl => workerUrl;
  static String get mediaApiUrl => workerUrl;
  static String get communityApiUrl => workerUrl;
  static String get rechercheApiUrl => workerUrl;

  // ──────────────────────────────────────────────────────────────
  // 🟢 SUPABASE (Auth, Datenbank, Realtime, Storage)
  // ──────────────────────────────────────────────────────────────

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://adtviduaftdquvfjpojb.supabase.co',
  );

  /// Anon Key ist öffentlich – darf im Client sein.
  /// Wird durch Row Level Security (RLS) auf Server-Seite abgesichert.
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    // Anon Key ist public, darf hier als Fallback stehen
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFkdHZpZHVhZnRkcXV2Zmpwb2piIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUxMzY3OTcsImV4cCI6MjA5MDcxMjc5N30.LPtmnjukb6o2CA16RDjoStqYb_1bipNULD4tgOfuD98',
  );

  // Service Role Key: NIEMALS im Client – nur als Wrangler Secret auf dem Server!
  // static const String supabaseServiceRoleKey = '...'; // ← VERBOTEN

  // ──────────────────────────────────────────────────────────────
  // 🦞 OPENCLAW AI GATEWAY (Hostinger VPS)
  // ──────────────────────────────────────────────────────────────

  /// Basis-URL des OpenClaw AI Gateways.
  /// Sollte auf HTTPS migriert werden (aktuell HTTP).
  static const String openClawGatewayUrl = String.fromEnvironment(
    'OPENCLAW_GATEWAY_URL',
    defaultValue: 'http://72.62.154.95:50074',
  );

  /// OpenClaw Gateway Token – aus dart-define, KEIN Hardcode.
  static const String openClawGatewayToken = String.fromEnvironment(
    'OPENCLAW_GATEWAY_TOKEN',
    defaultValue: '', // Leer = Gateway-Calls schlagen graceful fehl
  );

  // ──────────────────────────────────────────────────────────────
  // 📡 API ENDPOINTS (Cloudflare Worker)
  // ──────────────────────────────────────────────────────────────

  // Recherche
  static const String recherche = '/recherche';
  static const String contentSearch = '/api/content/search';

  // Chat
  static const String chat = '/api/chat/messages';

  // Voice (bleibt auf Cloudflare – Durable Objects / State)
  static const String voiceJoin = '/voice/join';
  static const String voiceLeave = '/voice/leave';
  static const String voiceEndRoom = '/voice/end-room';
  static const String voiceRooms = '/voice/rooms';
  static const String voiceParticipants = '/voice/participants';
  static String get webrtcSignalingUrl =>
      workerUrl.replaceAll('https://', 'wss://') + '/voice/signaling';

  // Admin (moderative Aktionen, bleibt auf Cloudflare)
  static const String adminUsers = '/admin/users';
  static const String adminBan = '/admin/ban';
  static const String adminKick = '/admin/kick';
  static const String adminAudit = '/admin/audit';
  static const String adminReports = '/admin/reports';

  // Inline Tools (Cloudflare Worker)
  static String get artefakteUrl => '$workerUrl/api/tools/artefakte';
  static String get chakraReadingsUrl => '$workerUrl/api/tools/chakra-readings';
  static String get connectionsUrl => '$workerUrl/api/tools/connections';
  static String get heilfrequenzUrl => '$workerUrl/api/tools/heilfrequenz';
  static String get newsTrackerUrl => '$workerUrl/api/tools/news-tracker';
  static String get patenteUrl => '$workerUrl/api/tools/patente';
  static String get traeumeUrl => '$workerUrl/api/tools/traeume';
  static String get ufoSichtungenUrl => '$workerUrl/api/tools/ufo-sichtungen';

  // ──────────────────────────────────────────────────────────────
  // 🔗 FULL URLS (Rückwärtskompatibilität)
  // ──────────────────────────────────────────────────────────────

  static String get pushApiUrl => '$workerUrl/api/push';
  static String get v2ApiUrl => '$workerUrl/api/v2';
  static String get voiceApiUrl => '$workerUrl/voice';
  static String get pushRegisterUrl => '$workerUrl/api/push/register';
  static String get pushSendUrl => '$workerUrl/api/push/send';
  static String get aiApiUrl => '$workerUrl/ai';
  static String get profileApiUrl => '$workerUrl/api/sync';
  static String get cloudSyncApiUrl => '$workerUrl/api/sync';
  static String get websocketUrl =>
      workerUrl.replaceAll('https://', 'wss://');

  // ──────────────────────────────────────────────────────────────
  // 🛠️ UTILITY METHODS
  // ──────────────────────────────────────────────────────────────

  /// Vollständige URL für einen Endpunkt.
  static String getUrl(String endpoint) => '$workerUrl$endpoint';

  /// Standard-Header für öffentliche Endpunkte (kein Auth-Token im Client).
  static Map<String, String> get publicHeaders => {
        'Content-Type': 'application/json',
      };

  /// Header mit Bearer-Token – Token kommt vom Server/Session, NICHT hardcodiert.
  /// [token] wird aus der aktuellen User-Session übergeben.
  static Map<String, String> headersWithToken(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // DEPRECATED – für Rückwärtskompatibilität, liefert leere Header
  @Deprecated('Nutze headersWithToken(userToken) oder publicHeaders')
  static Map<String, String> get headers => publicHeaders;

  @Deprecated('Admin-Aktionen laufen serverseitig – Token nicht im Client')
  static Map<String, String> get adminHeaders => publicHeaders;

  @Deprecated('WebRTC-Token nicht im Client speichern')
  static Map<String, String> get webrtcHeaders => publicHeaders;
}
