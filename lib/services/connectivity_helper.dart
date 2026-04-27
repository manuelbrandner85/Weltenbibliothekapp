import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

/// 🌐 Schneller Connectivity-Check für Cloud-Calls.
///
/// Nutze vor sensitiven HTTP-Operationen (Post creation, Avatar-Upload,
/// Comment-Send), um sofort einen "Offline"-Hinweis zu zeigen statt 10+ Sek.
/// auf Timeout zu warten. Spart Akku und gibt User schnelles Feedback.
///
/// Verwendung:
/// ```dart
/// if (!await ConnectivityHelper.isOnline()) {
///   _showSnackBar('Keine Internet-Verbindung');
///   return;
/// }
/// ```
class ConnectivityHelper {
  ConnectivityHelper._();

  static final _connectivity = Connectivity();

  /// True wenn ein Netzwerk-Interface aktiv ist (WiFi, Mobile, Ethernet).
  /// Bei Fehler im Check default true (lieber Versuch als false-negative).
  static Future<bool> isOnline() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.any((r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ ConnectivityHelper check failed: $e');
      return true;
    }
  }

  /// Convenience: liefert true wenn KEINE Verbindung.
  static Future<bool> isOffline() async => !await isOnline();
}
