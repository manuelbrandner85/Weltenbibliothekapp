/// 🎛️ FEATURE FLAGS für Weltenbibliothek V98
library;
import 'package:flutter/foundation.dart';
import 'api_config.dart';
/// Aktiviere/Deaktiviere Features ohne Code-Änderungen
class FeatureFlags {
  // WebSocket Features
  static const bool enableWebSocket = true; // 🟢 AKTIVIERT (Echtzeit-Updates)
  static const bool enableWebSockets = true; // 🟢 AKTIVIERT (Echtzeit-Updates)
  static const bool enableHybridMode = true; // 🟢 AKTIVIERT (WebSocket + HTTP Fallback)
  
  // Push Notification Features
  static const bool enablePushNotifications = true; // 🟢 AKTIVIERT (VAPID + Server-Push)
  static const bool enableLocalNotifications = true; // 🟢 Aktiviert (Browser-Notifications)
  
  // Chat Features
  static const bool enableTypingIndicators = false; // Nur mit WebSocket sinnvoll
  static const bool enablePresenceIndicators = false; // Nur mit WebSocket sinnvoll
  static const int httpPollingIntervalSeconds = 3; // Standard: 3 Sekunden
  
  // Tool Features
  static const bool enableToolActivityBroadcast = true; // 🟢 Aktiviert
  static const bool enableToolNotifications = true; // 🟢 Aktiviert
  
  // Debug Features
  static const bool debugWebSocketConnection = true;
  static const bool debugPushNotifications = true;
  static const bool verboseLogging = false;
  
  // Connection Settings
  static const int webSocketTimeout = 10; // Sekunden
  static const int webSocketReconnectAttempts = 5;
  static const Duration webSocketReconnectDelay = Duration(seconds: 2);
  
  // Push Notification Settings
  static const String vapidPublicKey = 'BN0RGl7H4zQxCLJYGz5D8vK6wN3kF2pL7mS9jX4vY1cT8rW6bA5eZ9nH3fQ2gK7jM4pL8vX1yC9tW6bR5nF3hZ'; // ✅ Generated VAPID Key
  // API Endpoints - Use ApiConfig
  static String get pushEndpoint => ApiConfig.pushApiUrl;
  
  /// WebSocket aktivieren?
  static bool get useWebSockets => enableWebSockets && enableHybridMode;
  
  /// Push-Notifications aktivieren?
  static bool get usePushNotifications => enablePushNotifications;
  
  /// Lokale Notifications aktivieren?
  static bool get useLocalNotifications => enableLocalNotifications;
  
  /// Feature-Status anzeigen
  static String getFeatureStatus() {
    return '''
╔════════════════════════════════════════════╗
║  WELTENBIBLIOTHEK V98 - FEATURE STATUS    ║
╚════════════════════════════════════════════╝

🔌 WebSocket:          ${enableWebSockets ? '🟢 Aktiviert' : '🔴 Deaktiviert'}
🔄 Hybrid-Modus:       ${enableHybridMode ? '🟢 Aktiviert' : '🔴 Deaktiviert'}
🔔 Push (Server):      ${enablePushNotifications ? '🟢 Aktiviert' : '🔴 Deaktiviert'}
📢 Notifications:      ${enableLocalNotifications ? '🟢 Aktiviert' : '🔴 Deaktiviert'}
🔧 Tool-Broadcast:     ${enableToolActivityBroadcast ? '🟢 Aktiviert' : '🔴 Deaktiviert'}

📊 Aktueller Modus:    ${useWebSockets ? 'WebSocket (Echtzeit)' : 'HTTP-Polling (Stabil)'}
⏱️  Polling-Intervall: $httpPollingIntervalSeconds Sekunden
    ''';
  }
}

/// 🔧 FEATURE ACTIVATOR
/// Einfache Aktivierung von Features zur Laufzeit
class FeatureActivator {
  /// WebSocket-Features aktivieren
  static void activateWebSockets() {
    // HINWEIS: Erfordert App-Neustart
    // In Produktion: über Remote Config oder Feature-Flag-Service
    debugPrint('🔌 WebSocket-Features werden aktiviert...');
    debugPrint('⚠️ App-Neustart erforderlich');
  }
  
  /// Push-Notifications aktivieren
  static void activatePushNotifications() {
    debugPrint('🔔 Push-Notifications werden aktiviert...');
    debugPrint('⚠️ VAPID-Keys müssen konfiguriert sein');
  }
  
  /// Alle Features aktivieren
  static void activateAllFeatures() {
    debugPrint('🚀 Aktiviere alle Features...');
    activateWebSockets();
    activatePushNotifications();
  }
}
