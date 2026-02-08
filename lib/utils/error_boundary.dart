import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// Global Error Boundary - Verhindert App-Crashes
/// 
/// VERWENDUNG in main.dart:
/// ```dart
/// void main() {
///   ErrorBoundary.initialize();
///   runApp(const MyApp());
/// }
/// ```
class ErrorBoundary {
  ErrorBoundary._(); // Private constructor
  
  /// Initialisiere Error Handling
  static void initialize() {
    // 🛡️ Flutter Framework Errors abfangen
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      
      if (kDebugMode) {
        // Debug: Vollständiger Stack Trace
        debugPrint('🔴 FLUTTER ERROR CAUGHT:');
        debugPrint('Error: ${details.exception}');
        debugPrint('Stack: ${details.stack}');
      } else {
        // Production: Kurze Error-Info
        debugPrint('❌ Error: ${details.exception}');
      }
      
      // Optional: Error an Backend senden (Cloudflare Worker)
      _reportErrorToBackend(details);
    };
    
    // 🛡️ Async Errors abfangen (außerhalb Flutter Framework)
    PlatformDispatcher.instance.onError = (error, stack) {
      if (kDebugMode) {
        debugPrint('🔴 ASYNC ERROR CAUGHT:');
        debugPrint('Error: $error');
        debugPrint('Stack: $stack');
      } else {
        debugPrint('❌ Async Error: $error');
      }
      
      return true; // Error wurde behandelt
    };
    
    if (kDebugMode) {
      debugPrint('✅ Error Boundary initialized');
    }
  }
  
  /// Sende Error-Report an Backend (optional)
  static Future<void> _reportErrorToBackend(FlutterErrorDetails details) async {
    try {
      // TODO: Error an Cloudflare Worker senden für Monitoring
      // Nur in Production Mode
      if (!kDebugMode) {
        // await http.post(
        //   Uri.parse('https://weltenbibliothek-worker.brandy13062.workers.dev/api/error-report'),
        //   body: jsonEncode({
        //     'error': details.exception.toString(),
        //     'stack': details.stack.toString(),
        //     'timestamp': DateTime.now().toIso8601String(),
        //   }),
        // );
      }
    } catch (e) {
      // Stilles Fehlschlagen - keine zusätzlichen Errors werfen
      if (kDebugMode) {
        debugPrint('⚠️ Failed to report error: $e');
      }
    }
  }
}

/// Error Widget - Zeigt benutzerfreundliche Fehlermeldung
class AppErrorWidget extends StatelessWidget {
  final FlutterErrorDetails? errorDetails;
  final String? customMessage;
  
  const AppErrorWidget({
    super.key,
    this.errorDetails,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Error Icon
                Icon(
                  Icons.error_outline,
                  size: 80,
                  color: Colors.red.withValues(alpha: 0.8),
                ),
                
                const SizedBox(height: 24),
                
                // Error Titel
                const Text(
                  '⚠️ Oops! Etwas ist schiefgelaufen',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // Error Nachricht
                Text(
                  customMessage ?? 
                  'Die App hat einen unerwarteten Fehler festgestellt.\n'
                  'Bitte starte die App neu.',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                
                // Reload Button
                ElevatedButton.icon(
                  onPressed: () {
                    // App neu starten (nur in Development möglich)
                    // In Production: Zeige nur Nachricht zum manuellen Neustart
                    if (kDebugMode) {
                      debugPrint('🔄 App restart triggered');
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('App neu starten'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                // Debug Info (nur in Debug Mode)
                if (kDebugMode && errorDetails != null) ...[
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🐛 Debug Info:',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          errorDetails!.exception.toString(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
