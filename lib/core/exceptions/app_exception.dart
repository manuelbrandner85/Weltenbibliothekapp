import 'package:flutter/foundation.dart';

/// Basis-Exception-Klasse für alle App-Fehler
/// 
/// Diese Klasse bietet strukturiertes Error-Handling mit:
/// - Error-Codes für systematische Behandlung
/// - Stack-Trace-Preservation für Debugging
/// - Kontext-Informationen (Parameter, Timestamp)
/// - Severity-Level für Priorisierung
/// - JSON-Export für Analytics/Monitoring
class AppException implements Exception {
  /// Menschenlesbare Fehlermeldung
  final String message;
  
  /// Eindeutiger Error-Code (z.B. 'NETWORK_ERROR', 'AUTH_FAILED')
  final String? code;
  
  /// Original-Exception die zu diesem Fehler geführt hat
  final Object? cause;
  
  /// Stack-Trace für Debugging
  final StackTrace? stackTrace;
  
  /// Zusätzliche Kontext-Informationen (Parameter, State, etc.)
  final Map<String, dynamic>? context;
  
  /// Zeitstempel wann der Fehler aufgetreten ist
  final DateTime timestamp;
  
  /// Schweregrad des Fehlers
  final ExceptionSeverity severity;

  /// Konstruktor für AppException
  /// 
  /// [message] ist die Haupt-Fehlermeldung
  /// [code] ist ein optionaler Error-Code für systematische Behandlung
  /// [cause] ist die ursprüngliche Exception (falls vorhanden)
  /// [stackTrace] sollte immer mitgegeben werden für Debugging
  /// [context] kann zusätzliche Informationen enthalten
  /// [severity] bestimmt die Wichtigkeit (default: error)
  AppException(
    this.message, {
    this.code,
    this.cause,
    this.stackTrace,
    this.context,
    this.severity = ExceptionSeverity.error,
  }) : timestamp = DateTime.now();

  @override
  String toString() {
    final buffer = StringBuffer();
    
    // Header mit Severity und Message
    buffer.writeln('[$severity] $message');
    
    // Error-Code
    if (code != null) {
      buffer.writeln('Error Code: $code');
    }
    
    // Kontext-Informationen
    if (context != null && context!.isNotEmpty) {
      buffer.writeln('Context:');
      context!.forEach((key, value) {
        buffer.writeln('  $key: $value');
      });
    }
    
    // Original-Exception
    if (cause != null) {
      buffer.writeln('Caused by: $cause');
    }
    
    // Stack-Trace (nur im Debug-Modus)
    if (kDebugMode && stackTrace != null) {
      buffer.writeln('\nStack trace:');
      buffer.writeln(stackTrace.toString());
    }
    
    return buffer.toString();
  }

  /// Konvertiere Exception zu JSON für Logging/Analytics
  /// 
  /// Nützlich für:
  /// - Firebase Analytics
  /// - Sentry/Crashlytics
  /// - Custom Logging-Services
  /// - Error-Monitoring-Dashboards
  Map<String, dynamic> toJson() => {
    'message': message,
    'code': code,
    'cause': cause?.toString(),
    'context': context,
    'timestamp': timestamp.toIso8601String(),
    'severity': severity.name,
  };

  /// Erstelle eine Kopie mit geänderten Werten
  AppException copyWith({
    String? message,
    String? code,
    Object? cause,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    ExceptionSeverity? severity,
  }) {
    return AppException(
      message ?? this.message,
      code: code ?? this.code,
      cause: cause ?? this.cause,
      stackTrace: stackTrace ?? this.stackTrace,
      context: context ?? this.context,
      severity: severity ?? this.severity,
    );
  }
}

/// Fehler-Schweregrad für Priorisierung
/// 
/// Verwendung:
/// - [debug]: Nur für Entwicklung, keine Production-Relevanz
/// - [info]: Informativ, kein eigentlicher Fehler
/// - [warning]: Warnung, App läuft weiter aber mit Einschränkungen
/// - [error]: Fehler, Operation fehlgeschlagen
/// - [critical]: Kritischer Fehler, App-Zustand gefährdet
enum ExceptionSeverity {
  /// Nur für Entwicklung/Debugging
  debug,
  
  /// Informativ, kein Fehler
  info,
  
  /// Warnung, App läuft weiter
  warning,
  
  /// Fehler, Operation fehlgeschlagen
  error,
  
  /// Kritischer Fehler, App-Zustand gefährdet
  critical;

  /// Ist dieser Fehler kritisch?
  bool get isCritical => this == ExceptionSeverity.critical;
  
  /// Ist dieser Fehler ein Error oder schlimmer?
  bool get isError => index >= ExceptionSeverity.error.index;
  
  /// Ist dieser Fehler eine Warnung oder schlimmer?
  bool get isWarning => index >= ExceptionSeverity.warning.index;
}
