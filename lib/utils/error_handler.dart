/// Centralized Error Handler
/// Provides consistent error handling across the app with user-friendly messages
library;

import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:async';

/// Base app exception
abstract class AppException implements Exception {
  final String message;
  final String? details;
  final dynamic originalError;
  final StackTrace? stackTrace;
  
  const AppException({
    required this.message,
    this.details,
    this.originalError,
    this.stackTrace,
  });
  
  /// User-friendly error message in German
  String get userMessage => message;
  
  /// Technical details for logging
  String get technicalDetails => details ?? originalError?.toString() ?? 'Keine Details verfügbar';
  
  @override
  String toString() => '$runtimeType: $message';
}

/// Network-related errors
class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.details,
    super.originalError,
    super.stackTrace,
  });
  
  factory NetworkException.noConnection() => const NetworkException(
    message: 'Keine Internetverbindung',
    details: 'Bitte überprüfen Sie Ihre Netzwerkverbindung',
  );
  
  factory NetworkException.timeout() => const NetworkException(
    message: 'Zeitüberschreitung',
    details: 'Der Server antwortet nicht. Bitte versuchen Sie es später erneut.',
  );
  
  factory NetworkException.serverError(int statusCode) => NetworkException(
    message: 'Server-Fehler',
    details: 'HTTP Status: $statusCode',
  );
  
  factory NetworkException.unknown(dynamic error) => NetworkException(
    message: 'Netzwerkfehler',
    details: 'Ein unerwarteter Netzwerkfehler ist aufgetreten',
    originalError: error,
  );
}

/// Data-related errors
class DataException extends AppException {
  const DataException({
    required super.message,
    super.details,
    super.originalError,
    super.stackTrace,
  });
  
  factory DataException.notFound(String itemType) => DataException(
    message: '$itemType nicht gefunden',
    details: 'Die angeforderten Daten existieren nicht',
  );
  
  factory DataException.invalidFormat() => const DataException(
    message: 'Ungültiges Datenformat',
    details: 'Die empfangenen Daten haben ein ungültiges Format',
  );
  
  factory DataException.corruptedData() => const DataException(
    message: 'Beschädigte Daten',
    details: 'Die Daten sind beschädigt und können nicht gelesen werden',
  );
}

/// Storage-related errors
class StorageException extends AppException {
  const StorageException({
    required super.message,
    super.details,
    super.originalError,
    super.stackTrace,
  });
  
  factory StorageException.readFailed() => const StorageException(
    message: 'Lesefehler',
    details: 'Die Daten konnten nicht gelesen werden',
  );
  
  factory StorageException.writeFailed() => const StorageException(
    message: 'Schreibfehler',
    details: 'Die Daten konnten nicht gespeichert werden',
  );
  
  factory StorageException.insufficientSpace() => const StorageException(
    message: 'Nicht genügend Speicherplatz',
    details: 'Bitte geben Sie Speicherplatz frei und versuchen Sie es erneut',
  );
}

/// Authentication errors
class AuthException extends AppException {
  const AuthException({
    required super.message,
    super.details,
    super.originalError,
    super.stackTrace,
  });
  
  factory AuthException.unauthorized() => const AuthException(
    message: 'Nicht autorisiert',
    details: 'Sie haben keine Berechtigung für diese Aktion',
  );
  
  factory AuthException.sessionExpired() => const AuthException(
    message: 'Sitzung abgelaufen',
    details: 'Bitte melden Sie sich erneut an',
  );
  
  factory AuthException.invalidCredentials() => const AuthException(
    message: 'Ungültige Anmeldedaten',
    details: 'Benutzername oder Passwort sind falsch',
  );
}

/// Validation errors
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;
  
  const ValidationException({
    required super.message,
    super.details,
    this.fieldErrors,
    super.originalError,
    super.stackTrace,
  });
  
  factory ValidationException.invalidInput(String field) => ValidationException(
    message: 'Ungültige Eingabe',
    details: 'Das Feld "$field" enthält ungültige Daten',
  );
  
  factory ValidationException.multipleErrors(Map<String, String> errors) => ValidationException(
    message: 'Mehrere Validierungsfehler',
    details: 'Bitte überprüfen Sie Ihre Eingaben',
    fieldErrors: errors,
  );
}

/// Error Handler - Centralized error processing
class ErrorHandler {
  ErrorHandler._(); // Private constructor
  
  /// Converts any error into an AppException
  static AppException normalizeError(dynamic error, [StackTrace? stackTrace]) {
    if (error is AppException) {
      return error;
    }
    
    if (error is SocketException) {
      return NetworkException.noConnection();
    }
    
    if (error is TimeoutException) {
      return NetworkException.timeout();
    }
    
    if (error is HttpException) {
      return NetworkException.unknown(error);
    }
    
    if (error is FormatException) {
      return DataException.invalidFormat();
    }
    
    // Unknown error
    return DataException(
      message: 'Unbekannter Fehler',
      details: 'Ein unerwarteter Fehler ist aufgetreten',
      originalError: error,
      stackTrace: stackTrace,
    );
  }
  
  /// Logs error for debugging
  static void logError(AppException error) {
    if (kDebugMode) {
      debugPrint('=== ERROR ===');
      debugPrint('Type: ${error.runtimeType}');
      debugPrint('Message: ${error.message}');
      debugPrint('Details: ${error.technicalDetails}');
      if (error.stackTrace != null) {
        debugPrint('Stack Trace:\n${error.stackTrace}');
      }
      debugPrint('=============');
    }
  }
  
  /// Handles error with optional retry callback
  static Future<T?> handleError<T>({
    required dynamic error,
    StackTrace? stackTrace,
    Future<T> Function()? retry,
    T? fallbackValue,
  }) async {
    final appError = normalizeError(error, stackTrace);
    logError(appError);
    
    // If retry callback is provided and it's a network error, attempt retry
    if (retry != null && appError is NetworkException) {
      try {
        return await retry();
      } catch (retryError, retryStackTrace) {
        // Retry failed, log and return fallback
        logError(normalizeError(retryError, retryStackTrace));
        return fallbackValue;
      }
    }
    
    return fallbackValue;
  }
  
  /// Gets user-friendly error message
  static String getUserMessage(dynamic error) {
    if (error is AppException) {
      return error.userMessage;
    }
    
    final normalized = normalizeError(error);
    return normalized.userMessage;
  }
}

/// Retry mechanism for async operations
class RetryPolicy {
  final int maxAttempts;
  final Duration initialDelay;
  final Duration maxDelay;
  final double backoffMultiplier;
  
  const RetryPolicy({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 10),
    this.backoffMultiplier = 2.0,
  });
  
  /// Executes function with exponential backoff retry
  Future<T> execute<T>(Future<T> Function() operation) async {
    var attempt = 0;
    var delay = initialDelay;
    
    while (true) {
      attempt++;
      
      try {
        return await operation();
      } catch (error, stackTrace) {
        final appError = ErrorHandler.normalizeError(error, stackTrace);
        
        // Don't retry on validation or auth errors
        if (appError is ValidationException || appError is AuthException) {
          rethrow;
        }
        
        // If max attempts reached, throw error
        if (attempt >= maxAttempts) {
          ErrorHandler.logError(appError);
          rethrow;
        }
        
        // Wait before retry with exponential backoff
        if (kDebugMode) {
          debugPrint('Retry attempt $attempt/$maxAttempts after ${delay.inSeconds}s');
        }
        
        await Future.delayed(delay);
        
        // Increase delay for next attempt
        delay = Duration(
          milliseconds: (delay.inMilliseconds * backoffMultiplier).round(),
        );
        
        // Cap at max delay
        if (delay > maxDelay) {
          delay = maxDelay;
        }
      }
    }
  }
}

/// Extension for easier error handling in async functions
extension ErrorHandlingExtension<T> on Future<T> {
  /// Wraps Future with error handling
  Future<T?> withErrorHandling({
    Future<T> Function()? retry,
    T? fallbackValue,
  }) async {
    try {
      return await this;
    } catch (error, stackTrace) {
      return await ErrorHandler.handleError<T>(
        error: error,
        stackTrace: stackTrace,
        retry: retry,
        fallbackValue: fallbackValue,
      );
    }
  }
}
