import 'package:flutter/foundation.dart';
import '../exceptions/app_exception.dart';

/// Production-Ready Logger für Weltenbibliothek
/// 
/// Features:
/// - Verschiedene Log-Level (debug, info, warn, error, critical)
/// - Automatisches kDebugMode Filtering
/// - Integration mit AppException
/// - Stack-Trace-Logging
/// - Strukturierte Tags
/// - Kontext-Informationen
/// - Optionale externe Logger-Integration (Firebase, Sentry, etc.)
class AppLogger {
  /// Singleton-Pattern
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();

  /// Externe Logger-Callbacks (optional)
  static void Function(String level, String message, Map<String, dynamic>? context)? _externalLogger;
  
  /// Externe Logger registrieren (z.B. Firebase Analytics)
  static void registerExternalLogger(
    void Function(String level, String message, Map<String, dynamic>? context) logger
  ) {
    _externalLogger = logger;
  }

  // ============================================
  // DEBUG LOGS (nur in Debug-Mode)
  // ============================================

  /// Debug-Level Log (nur Development)
  /// 
  /// Verwendung:
  /// ```dart
  /// AppLogger.debug('User action', context: {'action': 'click'});
  /// ```
  static void debug(String message, {Map<String, dynamic>? context, String? tag}) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag]' : '';
      debugPrint('🐛 [DEBUG] $prefix $message');
      if (context != null && context.isNotEmpty) {
        debugPrint('   Context: $context');
      }
    }
  }

  // ============================================
  // INFO LOGS
  // ============================================

  /// Info-Level Log
  /// 
  /// Verwendung:
  /// ```dart
  /// AppLogger.info('User logged in', context: {'userId': '123'});
  /// ```
  static void info(String message, {Map<String, dynamic>? context, String? tag}) {
    final prefix = tag != null ? '[$tag]' : '';
    
    if (kDebugMode) {
      debugPrint('ℹ️ [INFO] $prefix $message');
      if (context != null && context.isNotEmpty) {
        debugPrint('   Context: $context');
      }
    }
    
    // Optional: Externe Logger
    _externalLogger?.call('info', message, context);
  }

  // ============================================
  // WARNING LOGS
  // ============================================

  /// Warning-Level Log
  /// 
  /// Verwendung:
  /// ```dart
  /// AppLogger.warn('Deprecated API used', context: {'api': 'old_endpoint'});
  /// ```
  static void warn(String message, {Map<String, dynamic>? context, String? tag}) {
    final prefix = tag != null ? '[$tag]' : '';
    
    if (kDebugMode) {
      debugPrint('⚠️ [WARN] $prefix $message');
      if (context != null && context.isNotEmpty) {
        debugPrint('   Context: $context');
      }
    }
    
    // Optional: Externe Logger
    _externalLogger?.call('warn', message, context);
  }

  // ============================================
  // ERROR LOGS
  // ============================================

  /// Error-Level Log
  /// 
  /// Verwendung:
  /// ```dart
  /// AppLogger.error('API call failed', error: e, stackTrace: stack);
  /// ```
  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    String? tag,
  }) {
    final prefix = tag != null ? '[$tag]' : '';
    
    if (kDebugMode) {
      debugPrint('❌ [ERROR] $prefix $message');
      if (context != null && context.isNotEmpty) {
        debugPrint('   Context: $context');
      }
      if (error != null) {
        debugPrint('   Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('   Stack Trace:\n$stackTrace');
      }
    }
    
    // Optional: Externe Logger
    _externalLogger?.call('error', message, {
      ...?context,
      if (error != null) 'error': error.toString(),
      if (stackTrace != null) 'stackTrace': stackTrace.toString(),
    });
  }

  // ============================================
  // CRITICAL LOGS (immer geloggt)
  // ============================================

  /// Critical-Level Log (wird IMMER geloggt, auch in Production)
  /// 
  /// Verwendung:
  /// ```dart
  /// AppLogger.critical('App crashed', error: e, stackTrace: stack);
  /// ```
  static void critical(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    String? tag,
  }) {
    final prefix = tag != null ? '[$tag]' : '';
    
    // Kritische Fehler werden IMMER geloggt
    debugPrint('🚨 [CRITICAL] $prefix $message');
    if (context != null && context.isNotEmpty) {
      debugPrint('   Context: $context');
    }
    if (error != null) {
      debugPrint('   Error: $error');
    }
    if (stackTrace != null) {
      debugPrint('   Stack Trace:\n$stackTrace');
    }
    
    // Optional: Externe Logger
    _externalLogger?.call('critical', message, {
      ...?context,
      if (error != null) 'error': error.toString(),
      if (stackTrace != null) 'stackTrace': stackTrace.toString(),
    });
  }

  // ============================================
  // EXCEPTION LOGGING (Integration mit AppException)
  // ============================================

  /// Log AppException mit allen Details
  /// 
  /// Verwendung:
  /// ```dart
  /// try {
  ///   // ...
  /// } catch (e) {
  ///   if (e is AppException) {
  ///     AppLogger.logException(e);
  ///   }
  /// }
  /// ```
  static void logException(AppException exception, {String? tag}) {
    final prefix = tag != null ? '[$tag]' : '';
    
    final level = _getLevelEmoji(exception.severity);
    
    if (kDebugMode || exception.severity.isCritical) {
      debugPrint('$level [${exception.severity.name.toUpperCase()}] $prefix ${exception.message}');
      
      if (exception.code != null) {
        debugPrint('   Code: ${exception.code}');
      }
      
      if (exception.context != null && exception.context!.isNotEmpty) {
        debugPrint('   Context: ${exception.context}');
      }
      
      if (exception.cause != null) {
        debugPrint('   Caused by: ${exception.cause}');
      }
      
      if (exception.stackTrace != null) {
        debugPrint('   Stack Trace:\n${exception.stackTrace}');
      }
      
      debugPrint('   Timestamp: ${exception.timestamp}');
    }
    
    // Optional: Externe Logger
    _externalLogger?.call(
      exception.severity.name,
      exception.message,
      exception.toJson(),
    );
  }

  /// Emoji für Log-Level
  static String _getLevelEmoji(ExceptionSeverity severity) {
    switch (severity) {
      case ExceptionSeverity.debug:
        return '🐛';
      case ExceptionSeverity.info:
        return 'ℹ️';
      case ExceptionSeverity.warning:
        return '⚠️';
      case ExceptionSeverity.error:
        return '❌';
      case ExceptionSeverity.critical:
        return '🚨';
    }
  }

  // ============================================
  // OPERATION LOGGING (für guard() Integration)
  // ============================================

  /// Log Operation Start
  static void operationStart(String operation, {Map<String, dynamic>? context}) {
    if (kDebugMode) {
      debugPrint('🔄 [OPERATION] Starting: $operation');
      if (context != null && context.isNotEmpty) {
        debugPrint('   Context: $context');
      }
    }
  }

  /// Log Operation Success
  static void operationSuccess(String operation, {Duration? duration, Map<String, dynamic>? context}) {
    if (kDebugMode) {
      final durationText = duration != null ? ' (${duration.inMilliseconds}ms)' : '';
      debugPrint('✅ [OPERATION] Success: $operation$durationText');
      if (context != null && context.isNotEmpty) {
        debugPrint('   Context: $context');
      }
    }
  }

  /// Log Operation Failure
  static void operationFailure(
    String operation, {
    Object? error,
    StackTrace? stackTrace,
    Duration? duration,
    Map<String, dynamic>? context,
  }) {
    if (kDebugMode) {
      final durationText = duration != null ? ' (${duration.inMilliseconds}ms)' : '';
      debugPrint('❌ [OPERATION] Failed: $operation$durationText');
      if (context != null && context.isNotEmpty) {
        debugPrint('   Context: $context');
      }
      if (error != null) {
        debugPrint('   Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('   Stack Trace:\n$stackTrace');
      }
    }
  }

  // ============================================
  // NETWORK LOGGING
  // ============================================

  /// Log HTTP Request
  static void httpRequest(String method, String url, {Map<String, dynamic>? headers}) {
    if (kDebugMode) {
      debugPrint('🌐 [HTTP] $method $url');
      if (headers != null && headers.isNotEmpty) {
        debugPrint('   Headers: $headers');
      }
    }
  }

  /// Log HTTP Response
  static void httpResponse(
    String method,
    String url,
    int statusCode, {
    Duration? duration,
    String? body,
  }) {
    if (kDebugMode) {
      final durationText = duration != null ? ' (${duration.inMilliseconds}ms)' : '';
      final statusEmoji = statusCode >= 200 && statusCode < 300 ? '✅' : '❌';
      debugPrint('$statusEmoji [HTTP] $method $url → $statusCode$durationText');
      if (body != null && body.isNotEmpty) {
        debugPrint('   Body: ${body.substring(0, body.length > 200 ? 200 : body.length)}...');
      }
    }
  }

  // ============================================
  // ANALYTICS LOGGING
  // ============================================

  /// Log Analytics Event
  static void analytics(String event, {Map<String, dynamic>? parameters}) {
    if (kDebugMode) {
      debugPrint('📊 [ANALYTICS] Event: $event');
      if (parameters != null && parameters.isNotEmpty) {
        debugPrint('   Parameters: $parameters');
      }
    }
    
    // Optional: Externe Analytics (Firebase, etc.)
    _externalLogger?.call('analytics', event, parameters);
  }

  // ============================================
  // PERFORMANCE LOGGING
  // ============================================

  /// Log Performance Metric
  static void performance(String metric, Duration duration, {Map<String, dynamic>? context}) {
    if (kDebugMode) {
      debugPrint('⚡ [PERFORMANCE] $metric: ${duration.inMilliseconds}ms');
      if (context != null && context.isNotEmpty) {
        debugPrint('   Context: $context');
      }
    }
  }

  // ============================================
  // UTILITY METHODS
  // ============================================

  /// Log Separator (für bessere Lesbarkeit)
  static void separator() {
    if (kDebugMode) {
      debugPrint('════════════════════════════════════════════════════════════════');
    }
  }

  /// Log Section Header
  static void section(String title) {
    if (kDebugMode) {
      debugPrint('');
      debugPrint('═══ $title ═══');
      debugPrint('');
    }
  }
}
