import 'package:flutter/foundation.dart';
import 'app_exception.dart';
import 'specialized_exceptions.dart';

// ============================================
// ASYNC GUARD FUNCTION
// ============================================

/// Generic Guard-Funktion für asynchrone Operationen mit verbessertem Error-Handling
/// 
/// Features:
/// - Automatisches Exception-Wrapping
/// - Kontext-Informationen
/// - Error-Recovery-Callback
/// - Debug-Logging
/// - Stack-Trace-Preservation
/// 
/// Beispiel:
/// ```dart
/// final user = await guard(
///   () async => await fetchUser(userId),
///   operationName: 'Fetch User Profile',
///   context: {'userId': userId},
///   onError: (error, stackTrace) async {
///     // Fallback zu cached data
///     return await getCachedUser(userId);
///   },
/// );
/// ```
Future<T> guard<T>(
  Future<T> Function() action, {
  /// Name der Operation für bessere Fehlermeldungen
  String? operationName,
  
  /// Zusätzliche Kontext-Informationen (Parameter, State, etc.)
  Map<String, dynamic>? context,
  
  /// Optional: Error-Recovery-Callback
  /// Wird aufgerufen wenn ein Fehler auftritt
  /// Kann einen Fallback-Wert zurückgeben
  Future<T> Function(Object error, StackTrace stackTrace)? onError,
  
  /// Soll die Exception nach dem Handling erneut geworfen werden?
  /// Default: true (Exception wird weitergegeben)
  bool shouldRethrow = true,
}) async {
  try {
    // Debug-Logging: Operation Start
    if (kDebugMode && operationName != null) {
      debugPrint('🔄 [GUARD] Starting operation: $operationName');
    }
    
    // Führe die eigentliche Operation aus
    final result = await action();
    
    // Debug-Logging: Operation Success
    if (kDebugMode && operationName != null) {
      debugPrint('✅ [GUARD] Operation completed: $operationName');
    }
    
    return result;
    
  } catch (e, stackTrace) {
    // Debug-Logging: Operation Failed
    if (kDebugMode) {
      debugPrint('❌ [GUARD] Error in ${operationName ?? "operation"}: $e');
      if (context != null && context.isNotEmpty) {
        debugPrint('   Context: $context');
      }
    }
    
    // Versuche Error-Recovery (falls Callback vorhanden)
    if (onError != null) {
      try {
        if (kDebugMode) {
          debugPrint('🔄 [GUARD] Attempting error recovery...');
        }
        
        final recoveredValue = await onError(e, stackTrace);
        
        if (kDebugMode) {
          debugPrint('✅ [GUARD] Error recovery successful');
        }
        
        return recoveredValue;
        
      } catch (recoveryError) {
        // Error-Recovery ist fehlgeschlagen
        if (kDebugMode) {
          debugPrint('⚠️ [GUARD] Error recovery failed: $recoveryError');
        }
        
        // Original-Exception weiterwerfen (nicht Recovery-Exception)
        // Fall through zum Exception-Wrapping unten
      }
    }
    
    // AppException direkt weiterwerfen (bereits wrapped)
    if (e is AppException) {
      if (shouldRethrow) {
        rethrow;
      }
      return throw e;
    }
    
    // Andere Exceptions in AppException wrappen
    final wrappedException = AppException(
      operationName != null 
        ? 'Operation "$operationName" failed' 
        : 'Operation failed',
      code: 'OPERATION_FAILED',
      cause: e,
      stackTrace: stackTrace,
      context: context,
      severity: ExceptionSeverity.error,
    );
    
    if (shouldRethrow) {
      throw wrappedException;
    }
    return throw wrappedException;
  }
}

// ============================================
// SYNC GUARD FUNCTION
// ============================================

/// Synchrone Version der Guard-Funktion
/// 
/// Für nicht-asynchrone Operationen
/// 
/// Beispiel:
/// ```dart
/// final result = guardSync(
///   () => parseJson(jsonString),
///   operationName: 'Parse JSON',
///   context: {'jsonString': jsonString},
/// );
/// ```
T guardSync<T>(
  T Function() action, {
  String? operationName,
  Map<String, dynamic>? context,
  T Function(Object error, StackTrace stackTrace)? onError,
  bool shouldRethrow = true,
}) {
  try {
    if (kDebugMode && operationName != null) {
      debugPrint('🔄 [GUARD] Starting operation: $operationName');
    }
    
    final result = action();
    
    if (kDebugMode && operationName != null) {
      debugPrint('✅ [GUARD] Operation completed: $operationName');
    }
    
    return result;
    
  } catch (e, stackTrace) {
    if (kDebugMode) {
      debugPrint('❌ [GUARD] Error in ${operationName ?? "operation"}: $e');
      if (context != null && context.isNotEmpty) {
        debugPrint('   Context: $context');
      }
    }
    
    if (onError != null) {
      try {
        if (kDebugMode) {
          debugPrint('🔄 [GUARD] Attempting error recovery...');
        }
        
        final recoveredValue = onError(e, stackTrace);
        
        if (kDebugMode) {
          debugPrint('✅ [GUARD] Error recovery successful');
        }
        
        return recoveredValue;
        
      } catch (recoveryError) {
        if (kDebugMode) {
          debugPrint('⚠️ [GUARD] Error recovery failed: $recoveryError');
        }
      }
    }
    
    if (e is AppException) {
      if (shouldRethrow) {
        rethrow;
      }
      return throw e;
    }
    
    final wrappedException = AppException(
      operationName != null 
        ? 'Operation "$operationName" failed' 
        : 'Operation failed',
      code: 'OPERATION_FAILED',
      cause: e,
      stackTrace: stackTrace,
      context: context,
      severity: ExceptionSeverity.error,
    );
    
    if (shouldRethrow) {
      throw wrappedException;
    }
    return throw wrappedException;
  }
}

// ============================================
// SPECIALIZED GUARD FUNCTIONS
// ============================================

/// Guard-Funktion speziell für API-Calls
/// 
/// Wrapped automatisch in NetworkException bei Fehlern
/// 
/// Beispiel:
/// ```dart
/// final response = await guardApi(
///   () async => await http.get(url),
///   url: url.toString(),
///   method: 'GET',
/// );
/// ```
Future<T> guardApi<T>(
  Future<T> Function() action, {
  String? url,
  String? method,
  String? operationName,
  Map<String, dynamic>? context,
  Future<T> Function(Object error, StackTrace stackTrace)? onError,
}) async {
  try {
    return await guard(
      action,
      operationName: operationName ?? 'API Call: ${method ?? "?"} $url',
      context: {
        if (url != null) 'url': url,
        if (method != null) 'method': method,
        ...?context,
      },
      onError: onError,
    );
  } catch (e, stackTrace) {
    // Wrap in NetworkException
    throw NetworkException(
      'API call failed',
      url: url,
      method: method,
      cause: e,
      stackTrace: stackTrace,
    );
  }
}

/// Guard-Funktion speziell für Storage-Operationen
/// 
/// Wrapped automatisch in StorageException bei Fehlern
Future<T> guardStorage<T>(
  Future<T> Function() action, {
  required String operation,
  String? key,
  Map<String, dynamic>? context,
  Future<T> Function(Object error, StackTrace stackTrace)? onError,
}) async {
  try {
    return await guard(
      action,
      operationName: 'Storage: $operation',
      context: {
        'operation': operation,
        if (key != null) 'key': key,
        ...?context,
      },
      onError: onError,
    );
  } catch (e, stackTrace) {
    throw StorageException(
      'Storage operation failed: $operation',
      operation: operation,
      key: key,
      cause: e,
      stackTrace: stackTrace,
    );
  }
}

// ============================================
// RETRY LOGIC
// ============================================

/// Guard mit automatischem Retry bei Fehlern
/// 
/// Beispiel:
/// ```dart
/// final data = await guardWithRetry(
///   () async => await fetchData(),
///   maxRetries: 3,
///   retryDelay: Duration(seconds: 1),
///   operationName: 'Fetch Data',
/// );
/// ```
Future<T> guardWithRetry<T>(
  Future<T> Function() action, {
  int maxRetries = 3,
  Duration retryDelay = const Duration(seconds: 1),
  String? operationName,
  Map<String, dynamic>? context,
  /// Soll bei diesem Fehler retry versucht werden?
  bool Function(Object error)? shouldRetry,
}) async {
  int attempt = 0;
  Object? lastError;
  StackTrace? lastStackTrace;
  
  while (attempt <= maxRetries) {
    try {
      if (kDebugMode && attempt > 0) {
        debugPrint('🔄 [RETRY] Attempt ${attempt + 1}/${maxRetries + 1}: $operationName');
      }
      
      return await guard(
        action,
        operationName: operationName,
        context: {
          'attempt': attempt + 1,
          'maxRetries': maxRetries,
          ...?context,
        },
      );
      
    } catch (e, stackTrace) {
      lastError = e;
      lastStackTrace = stackTrace;
      
      // Check ob retry sinnvoll ist
      if (shouldRetry != null && !shouldRetry(e)) {
        if (kDebugMode) {
          debugPrint('⚠️ [RETRY] Error not retryable, aborting');
        }
        rethrow;
      }
      
      attempt++;
      
      if (attempt <= maxRetries) {
        if (kDebugMode) {
          debugPrint('⏳ [RETRY] Waiting ${retryDelay.inSeconds}s before retry...');
        }
        await Future.delayed(retryDelay);
      }
    }
  }
  
  // Alle Retries fehlgeschlagen
  if (kDebugMode) {
    debugPrint('❌ [RETRY] All retries exhausted for: $operationName');
  }
  
  throw AppException(
    'Operation failed after $maxRetries retries',
    code: 'RETRY_EXHAUSTED',
    cause: lastError,
    stackTrace: lastStackTrace,
    context: {
      'maxRetries': maxRetries,
      'operationName': operationName,
      ...?context,
    },
  );
}

// ============================================
// TIMEOUT GUARD
// ============================================

/// Guard mit Timeout
/// 
/// Beispiel:
/// ```dart
/// final data = await guardWithTimeout(
///   () async => await slowOperation(),
///   timeout: Duration(seconds: 10),
///   operationName: 'Slow Operation',
/// );
/// ```
Future<T> guardWithTimeout<T>(
  Future<T> Function() action, {
  required Duration timeout,
  String? operationName,
  Map<String, dynamic>? context,
}) async {
  try {
    return await guard(
      action,
      operationName: operationName,
      context: context,
    ).timeout(
      timeout,
      onTimeout: () {
        throw TimeoutException(
          'Operation timed out after ${timeout.inSeconds}s',
          timeout: timeout,
          operation: operationName,
        );
      },
    );
  } catch (e, stackTrace) {
    if (e is TimeoutException) {
      rethrow;
    }
    
    throw AppException(
      'Operation with timeout failed',
      code: 'TIMEOUT_OPERATION_FAILED',
      cause: e,
      stackTrace: stackTrace,
      context: {
        'timeoutSeconds': timeout.inSeconds,
        ...?context,
      },
    );
  }
}
