/// Timeout-Handler für Recherche-Service
/// Robuste Fehlerbehandlung mit Retry-Mechanismus
library;

import 'dart:async';
import 'package:flutter/foundation.dart';

class TimeoutConfig {
  final Duration rechercheDuration;
  final Duration analyseDuration;
  final int maxRetries;
  
  const TimeoutConfig({
    this.rechercheDuration = const Duration(seconds: 15),
    this.analyseDuration = const Duration(seconds: 10),
    this.maxRetries = 2,
  });
}

enum TimeoutErrorType {
  network,
  server,
  timeout,
  parser,
  unknown,
}

class TimeoutError {
  final TimeoutErrorType type;
  final String message;
  final String? details;
  final DateTime timestamp;
  
  TimeoutError({
    required this.type,
    required this.message,
    this.details,
  }) : timestamp = DateTime.now();
  
  String get userFriendlyMessage {
    switch (type) {
      case TimeoutErrorType.network:
        return '🌐 Netzwerkfehler: Bitte Internetverbindung prüfen';
      case TimeoutErrorType.server:
        return '🔧 Server-Fehler: Bitte später erneut versuchen';
      case TimeoutErrorType.timeout:
        return '⏱️ Zeitüberschreitung: Anfrage dauerte zu lange';
      case TimeoutErrorType.parser:
        return '📋 Daten-Fehler: Antwort konnte nicht verarbeitet werden';
      case TimeoutErrorType.unknown:
        return '❌ Unbekannter Fehler: $message';
    }
  }
}

class TimeoutHandler {
  final TimeoutConfig config;
  
  TimeoutHandler({TimeoutConfig? config}) 
      : config = config ?? const TimeoutConfig();
  
  /// Execute with timeout and retry
  Future<T> executeWithRetry<T>({
    required Future<T> Function() operation,
    required Duration timeout,
    String operationName = 'Operation',
  }) async {
    int attempts = 0;
    
    while (attempts < config.maxRetries) {
      attempts++;
      
      try {
        if (kDebugMode) {
          debugPrint('⏱️ [$operationName] Versuch $attempts/${config.maxRetries}...');
        }
        
        final result = await operation().timeout(
          timeout,
          onTimeout: () {
            throw TimeoutException(
              '$operationName timeout nach ${timeout.inSeconds}s',
              timeout,
            );
          },
        );
        
        if (kDebugMode) {
          debugPrint('✅ [$operationName] Erfolgreich in Versuch $attempts');
        }
        
        return result;
        
      } on TimeoutException catch (e) {
        if (kDebugMode) {
          debugPrint('⏱️ [$operationName] Timeout in Versuch $attempts: $e');
        }
        
        if (attempts >= config.maxRetries) {
          throw TimeoutError(
            type: TimeoutErrorType.timeout,
            message: '$operationName überschritt Zeitlimit',
            details: 'Timeout nach ${timeout.inSeconds}s (${config.maxRetries} Versuche)',
          );
        }
        
        // Exponential backoff
        await Future.delayed(Duration(seconds: attempts));
        
      } catch (e, stackTrace) {
        if (kDebugMode) {
          debugPrint('❌ [$operationName] Fehler in Versuch $attempts: $e');
          debugPrint('   StackTrace: $stackTrace');
        }
        
        // Classify error
        final error = _classifyError(e, operationName);
        
        // Don't retry for certain errors
        if (error.type == TimeoutErrorType.parser || 
            attempts >= config.maxRetries) {
          throw error;
        }
        
        // Retry with backoff
        await Future.delayed(Duration(seconds: attempts));
      }
    }
    
    throw TimeoutError(
      type: TimeoutErrorType.unknown,
      message: '$operationName failed nach ${config.maxRetries} Versuchen',
    );
  }
  
  TimeoutError _classifyError(dynamic error, String operationName) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('network') || 
        errorString.contains('connection') ||
        errorString.contains('socket')) {
      return TimeoutError(
        type: TimeoutErrorType.network,
        message: 'Netzwerkverbindung fehlgeschlagen',
        details: error.toString(),
      );
    }
    
    if (errorString.contains('500') || 
        errorString.contains('502') ||
        errorString.contains('503')) {
      return TimeoutError(
        type: TimeoutErrorType.server,
        message: 'Server antwortet nicht',
        details: error.toString(),
      );
    }
    
    if (errorString.contains('parse') || 
        errorString.contains('json') ||
        errorString.contains('format')) {
      return TimeoutError(
        type: TimeoutErrorType.parser,
        message: 'Daten konnten nicht verarbeitet werden',
        details: error.toString(),
      );
    }
    
    return TimeoutError(
      type: TimeoutErrorType.unknown,
      message: operationName,
      details: error.toString(),
    );
  }
}
