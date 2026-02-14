/// 🌐 WELTENBIBLIOTHEK - CENTRALIZED HTTP HELPER
/// Production-ready HTTP client with:
/// - Automatic retry logic
/// - Timeout handling
/// - Error handling
/// - Response validation
/// - Logging
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// HTTP Response wrapper with success/error state
class HttpResult<T> {
  final bool success;
  final T? data;
  final String? error;
  final int? statusCode;
  
  const HttpResult.success(this.data, {this.statusCode})
      : success = true,
        error = null;
  
  const HttpResult.error(this.error, {this.statusCode})
      : success = false,
        data = null;
}

/// Centralized HTTP Helper with retry logic
class HttpHelper {
  /// Default timeout for all requests
  static const Duration defaultTimeout = Duration(seconds: 15);
  
  /// Max retry attempts
  static const int maxRetries = 3;
  
  /// Delay between retries (exponential backoff)
  static Duration _retryDelay(int attempt) {
    return Duration(seconds: 2 * attempt); // 2s, 4s, 6s
  }
  
  /// GET request with retry logic (supports Uri and custom parsing)
  static Future<T> get<T>({
    required Uri uri,
    Map<String, String>? headers,
    Duration? timeout,
    bool enableRetry = true,
    required T Function(String body) parseResponse,
  }) async {
    final result = await _executeWithRetry(
      () => _performGet(uri.toString(), headers: headers, timeout: timeout),
      enableRetry: enableRetry,
      operation: 'GET $uri',
    );
    
    if (result.success) {
      return parseResponse(jsonEncode(result.data));
    } else {
      throw Exception(result.error ?? 'GET request failed');
    }
  }
  
  /// POST request with retry logic (supports Uri and custom parsing)
  static Future<T> post<T>({
    required Uri uri,
    Map<String, String>? headers,
    required Map<String, dynamic> body,
    Duration? timeout,
    bool enableRetry = true,
    required T Function(String body) parseResponse,
  }) async {
    final result = await _executeWithRetry(
      () => _performPost(uri.toString(), headers: headers, body: body, timeout: timeout),
      enableRetry: enableRetry,
      operation: 'POST $uri',
    );
    
    if (result.success) {
      return parseResponse(jsonEncode(result.data));
    } else {
      throw Exception(result.error ?? 'POST request failed');
    }
  }
  
  /// PUT request with retry logic (supports Uri and custom parsing)
  static Future<T> put<T>({
    required Uri uri,
    Map<String, String>? headers,
    required Map<String, dynamic> body,
    Duration? timeout,
    bool enableRetry = true,
    required T Function(String body) parseResponse,
  }) async {
    final result = await _executeWithRetry(
      () => _performPut(uri.toString(), headers: headers, body: body, timeout: timeout),
      enableRetry: enableRetry,
      operation: 'PUT $uri',
    );
    
    if (result.success) {
      return parseResponse(jsonEncode(result.data));
    } else {
      throw Exception(result.error ?? 'PUT request failed');
    }
  }
  
  /// DELETE request with retry logic (supports Uri and custom parsing)
  static Future<T> delete<T>({
    required Uri uri,
    Map<String, String>? headers,
    Duration? timeout,
    bool enableRetry = true,
    required T Function(String body) parseResponse,
  }) async {
    final result = await _executeWithRetry(
      () => _performDelete(uri.toString(), headers: headers, timeout: timeout),
      enableRetry: enableRetry,
      operation: 'DELETE $uri',
    );
    
    if (result.success) {
      return parseResponse(jsonEncode(result.data));
    } else {
      throw Exception(result.error ?? 'DELETE request failed');
    }
  }
  
  // ==================== PRIVATE METHODS ====================
  
  /// Execute request with retry logic
  static Future<HttpResult<Map<String, dynamic>>> _executeWithRetry(
    Future<HttpResult<Map<String, dynamic>>> Function() request, {
    required bool enableRetry,
    required String operation,
  }) async {
    int attempt = 0;
    
    while (true) {
      attempt++;
      
      try {
        if (kDebugMode && attempt > 1) {
          debugPrint('🔄 [HTTP] Retry attempt $attempt/$maxRetries for $operation');
        }
        
        final result = await request();
        
        // Success - return immediately
        if (result.success) {
          if (kDebugMode && attempt > 1) {
            debugPrint('✅ [HTTP] Success after $attempt attempts: $operation');
          }
          return result;
        }
        
        // Error - check if should retry
        if (!enableRetry || attempt >= maxRetries) {
          if (kDebugMode) {
            debugPrint('❌ [HTTP] Failed after $attempt attempts: $operation');
          }
          return result;
        }
        
        // Check if error is retryable
        final isRetryable = _isRetryableError(result.statusCode);
        if (!isRetryable) {
          if (kDebugMode) {
            debugPrint('⚠️ [HTTP] Non-retryable error (${result.statusCode}): $operation');
          }
          return result;
        }
        
        // Wait before retry
        final delay = _retryDelay(attempt);
        if (kDebugMode) {
          debugPrint('⏳ [HTTP] Waiting ${delay.inSeconds}s before retry...');
        }
        await Future.delayed(delay);
        
      } catch (e) {
        if (kDebugMode) {
          debugPrint('💥 [HTTP] Exception in attempt $attempt: $e');
        }
        
        if (!enableRetry || attempt >= maxRetries) {
          return HttpResult.error('Request failed: $e');
        }
        
        await Future.delayed(_retryDelay(attempt));
      }
    }
  }
  
  /// Check if HTTP status code is retryable
  static bool _isRetryableError(int? statusCode) {
    if (statusCode == null) return true; // Network errors are retryable
    
    // Retry on server errors (5xx) and rate limiting (429)
    return statusCode >= 500 || statusCode == 429 || statusCode == 408;
  }
  
  /// Perform GET request
  static Future<HttpResult<Map<String, dynamic>>> _performGet(
    String url, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse(url),
            headers: headers,
          )
          .timeout(timeout ?? defaultTimeout);
      
      return _parseResponse(response, url);
    } on http.ClientException catch (e) {
      return HttpResult.error('Network error: ${e.message}');
    } on FormatException catch (e) {
      return HttpResult.error('Invalid response format: ${e.message}');
    } catch (e) {
      return HttpResult.error('Request failed: $e');
    }
  }
  
  /// Perform POST request
  static Future<HttpResult<Map<String, dynamic>>> _performPost(
    String url, {
    Map<String, String>? headers,
    dynamic body,
    Duration? timeout,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: headers,
            body: body is String ? body : jsonEncode(body),
          )
          .timeout(timeout ?? defaultTimeout);
      
      return _parseResponse(response, url);
    } on http.ClientException catch (e) {
      return HttpResult.error('Network error: ${e.message}');
    } on FormatException catch (e) {
      return HttpResult.error('Invalid response format: ${e.message}');
    } catch (e) {
      return HttpResult.error('Request failed: $e');
    }
  }
  
  /// Perform PUT request
  static Future<HttpResult<Map<String, dynamic>>> _performPut(
    String url, {
    Map<String, String>? headers,
    dynamic body,
    Duration? timeout,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse(url),
            headers: headers,
            body: body is String ? body : jsonEncode(body),
          )
          .timeout(timeout ?? defaultTimeout);
      
      return _parseResponse(response, url);
    } on http.ClientException catch (e) {
      return HttpResult.error('Network error: ${e.message}');
    } on FormatException catch (e) {
      return HttpResult.error('Invalid response format: ${e.message}');
    } catch (e) {
      return HttpResult.error('Request failed: $e');
    }
  }
  
  /// Perform DELETE request
  static Future<HttpResult<Map<String, dynamic>>> _performDelete(
    String url, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    try {
      final response = await http
          .delete(
            Uri.parse(url),
            headers: headers,
          )
          .timeout(timeout ?? defaultTimeout);
      
      return _parseResponse(response, url);
    } on http.ClientException catch (e) {
      return HttpResult.error('Network error: ${e.message}');
    } on FormatException catch (e) {
      return HttpResult.error('Invalid response format: ${e.message}');
    } catch (e) {
      return HttpResult.error('Request failed: $e');
    }
  }
  
  /// Parse HTTP response
  static HttpResult<Map<String, dynamic>> _parseResponse(
    http.Response response,
    String url,
  ) {
    if (kDebugMode) {
      debugPrint('📡 [HTTP] ${response.request?.method} ${response.statusCode} $url');
    }
    
    // Success status codes (2xx)
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        if (response.body.isEmpty) {
          return HttpResult.success({}, statusCode: response.statusCode);
        }
        
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return HttpResult.success(data, statusCode: response.statusCode);
      } catch (e) {
        return HttpResult.error(
          'Invalid JSON response: $e',
          statusCode: response.statusCode,
        );
      }
    }
    
    // Error status codes
    String errorMessage;
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      errorMessage = data['error']?.toString() ?? 
                     data['message']?.toString() ?? 
                     'HTTP ${response.statusCode}';
    } catch (e) {
      errorMessage = 'HTTP ${response.statusCode}: ${response.body}';
    }
    
    return HttpResult.error(errorMessage, statusCode: response.statusCode);
  }
}
