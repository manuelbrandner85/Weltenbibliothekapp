import 'package:flutter_test/flutter_test.dart';
import 'package:weltenbibliothek/utils/error_handler.dart';
import 'dart:io';
import 'dart:async';

void main() {
  group('ErrorHandler - Exception Normalization', () {
    test('normalizeError - AppException passthrough', () {
      final original = NetworkException.noConnection();
      final normalized = ErrorHandler.normalizeError(original);
      
      expect(normalized, same(original));
    });
    
    test('normalizeError - SocketException to NetworkException', () {
      final error = const SocketException('Connection failed');
      final normalized = ErrorHandler.normalizeError(error);
      
      expect(normalized, isA<NetworkException>());
      expect(normalized.message, contains('Internetverbindung'));
    });
    
    test('normalizeError - TimeoutException to NetworkException', () {
      final error = TimeoutException('Timeout');
      final normalized = ErrorHandler.normalizeError(error);
      
      expect(normalized, isA<NetworkException>());
      expect(normalized.message, contains('Zeitüberschreitung'));
    });
    
    test('normalizeError - FormatException to DataException', () {
      final error = const FormatException('Invalid format');
      final normalized = ErrorHandler.normalizeError(error);
      
      expect(normalized, isA<DataException>());
      expect(normalized.message, contains('Datenformat'));
    });
    
    test('normalizeError - unknown error', () {
      final error = Exception('Unknown error');
      final normalized = ErrorHandler.normalizeError(error);
      
      expect(normalized, isA<DataException>());
      expect(normalized.message, contains('Unbekannter Fehler'));
    });
  });
  
  group('NetworkException - Factory Methods', () {
    test('noConnection factory', () {
      final exception = NetworkException.noConnection();
      
      expect(exception.message, 'Keine Internetverbindung');
      expect(exception.details, isNotNull);
    });
    
    test('timeout factory', () {
      final exception = NetworkException.timeout();
      
      expect(exception.message, 'Zeitüberschreitung');
      expect(exception.details, contains('Server antwortet nicht'));
    });
    
    test('serverError factory', () {
      final exception = NetworkException.serverError(500);
      
      expect(exception.message, 'Server-Fehler');
      expect(exception.details, contains('500'));
    });
  });
  
  group('DataException - Factory Methods', () {
    test('notFound factory', () {
      final exception = DataException.notFound('Artikel');
      
      expect(exception.message, 'Artikel nicht gefunden');
      expect(exception.details, isNotNull);
    });
    
    test('invalidFormat factory', () {
      final exception = DataException.invalidFormat();
      
      expect(exception.message, contains('Ungültiges Datenformat'));
    });
    
    test('corruptedData factory', () {
      final exception = DataException.corruptedData();
      
      expect(exception.message, 'Beschädigte Daten');
    });
  });
  
  group('StorageException - Factory Methods', () {
    test('readFailed factory', () {
      final exception = StorageException.readFailed();
      
      expect(exception.message, 'Lesefehler');
    });
    
    test('writeFailed factory', () {
      final exception = StorageException.writeFailed();
      
      expect(exception.message, 'Schreibfehler');
    });
    
    test('insufficientSpace factory', () {
      final exception = StorageException.insufficientSpace();
      
      expect(exception.message, contains('Speicherplatz'));
    });
  });
  
  group('AuthException - Factory Methods', () {
    test('unauthorized factory', () {
      final exception = AuthException.unauthorized();
      
      expect(exception.message, 'Nicht autorisiert');
    });
    
    test('sessionExpired factory', () {
      final exception = AuthException.sessionExpired();
      
      expect(exception.message, 'Sitzung abgelaufen');
    });
    
    test('invalidCredentials factory', () {
      final exception = AuthException.invalidCredentials();
      
      expect(exception.message, contains('Anmeldedaten'));
    });
  });
  
  group('ValidationException - Factory Methods', () {
    test('invalidInput factory', () {
      final exception = ValidationException.invalidInput('email');
      
      expect(exception.message, 'Ungültige Eingabe');
      expect(exception.details, contains('email'));
    });
    
    test('multipleErrors factory', () {
      final errors = {
        'email': 'Ungültige E-Mail',
        'password': 'Zu kurz',
      };
      final exception = ValidationException.multipleErrors(errors);
      
      expect(exception.message, contains('Mehrere'));
      expect(exception.fieldErrors, equals(errors));
    });
  });
  
  group('ErrorHandler - getUserMessage', () {
    test('getUserMessage from AppException', () {
      final exception = NetworkException.noConnection();
      final message = ErrorHandler.getUserMessage(exception);
      
      expect(message, exception.userMessage);
    });
    
    test('getUserMessage from generic error', () {
      final error = Exception('Test error');
      final message = ErrorHandler.getUserMessage(error);
      
      expect(message, isNotEmpty);
      expect(message, contains('Fehler'));
    });
  });
  
  group('RetryPolicy - Execution', () {
    test('execute succeeds on first attempt', () async {
      final policy = const RetryPolicy(maxAttempts: 3);
      var callCount = 0;
      
      final result = await policy.execute(() async {
        callCount++;
        return 'success';
      });
      
      expect(result, 'success');
      expect(callCount, 1);
    });
    
    test('execute succeeds after retry', () async {
      final policy = const RetryPolicy(
        maxAttempts: 3,
        initialDelay: Duration(milliseconds: 10),
      );
      var callCount = 0;
      
      final result = await policy.execute(() async {
        callCount++;
        if (callCount < 2) {
          throw NetworkException.timeout();
        }
        return 'success';
      });
      
      expect(result, 'success');
      expect(callCount, 2);
    });
    
    test('execute fails after max attempts', () async {
      final policy = const RetryPolicy(
        maxAttempts: 2,
        initialDelay: Duration(milliseconds: 10),
      );
      var callCount = 0;
      
      expect(
        () => policy.execute(() async {
          callCount++;
          throw NetworkException.timeout();
        }),
        throwsA(isA<NetworkException>()),
      );
      
      await Future.delayed(const Duration(milliseconds: 100));
      expect(callCount, 2);
    });
    
    test('execute does not retry ValidationException', () async {
      final policy = const RetryPolicy(
        maxAttempts: 3,
        initialDelay: Duration(milliseconds: 10),
      );
      var callCount = 0;
      
      expect(
        () => policy.execute(() async {
          callCount++;
          throw ValidationException.invalidInput('test');
        }),
        throwsA(isA<ValidationException>()),
      );
      
      await Future.delayed(const Duration(milliseconds: 100));
      expect(callCount, 1); // No retry
    });
  });
  
  group('ErrorHandlingExtension', () {
    test('withErrorHandling returns result on success', () async {
      final result = await Future.value(42).withErrorHandling();
      
      expect(result, 42);
    });
    
    test('withErrorHandling returns fallback on error', () async {
      final result = await Future<int>.error(Exception('Test'))
          .withErrorHandling(fallbackValue: 0);
      
      expect(result, 0);
    });
    
    test('withErrorHandling retries on NetworkException', () async {
      var callCount = 0;
      
      Future<String> operation() async {
        callCount++;
        return 'success';
      }
      
      final result = await Future<String>.error(NetworkException.timeout())
          .withErrorHandling(retry: operation);
      
      expect(result, 'success');
      expect(callCount, 1);
    });
  });
}
