/// 🚨 WELTENBIBLIOTHEK - ERROR REPORTING SERVICE
/// Centralized error tracking and reporting
/// Features: Error logging, crash reports, user feedback, analytics

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// Service for tracking and reporting app errors
class ErrorReportingService {
  static final ErrorReportingService _instance = ErrorReportingService._internal();
  factory ErrorReportingService() => _instance;
  ErrorReportingService._internal();

  // Error storage
  final List<ErrorReport> _errorHistory = [];
  static const int maxErrorHistory = 100;
  
  // Error reporting endpoint (Cloudflare Worker)
  String get _errorEndpoint => 'https://weltenbibliothek-api-v2.brandy13062.workers.dev/errors/report';
  
  bool _isInitialized = false;

  /// Initialize error reporting
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Setup Flutter error handlers
    FlutterError.onError = (FlutterErrorDetails details) {
      // Log to console in debug mode
      if (kDebugMode) {
        FlutterError.presentError(details);
      }
      
      // Report to backend
      reportError(
        error: details.exception,
        stackTrace: details.stack,
        context: details.context?.toString() ?? 'Flutter Framework',
        fatal: true,
      );
    };
    
    // Setup Dart error handlers
    PlatformDispatcher.instance.onError = (error, stack) {
      reportError(
        error: error,
        stackTrace: stack,
        context: 'Dart Runtime',
        fatal: true,
      );
      return true;
    };
    
    _isInitialized = true;
    
    if (kDebugMode) {
      print('✅ ErrorReporting: Initialized');
    }
  }

  /// Report an error
  Future<void> reportError({
    required Object error,
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? additionalData,
    bool fatal = false,
  }) async {
    try {
      final errorReport = ErrorReport(
        error: error.toString(),
        stackTrace: stackTrace?.toString(),
        context: context,
        additionalData: additionalData,
        fatal: fatal,
        timestamp: DateTime.now(),
      );
      
      // Add to history
      _errorHistory.add(errorReport);
      if (_errorHistory.length > maxErrorHistory) {
        _errorHistory.removeAt(0);
      }
      
      // Log to console in debug mode
      if (kDebugMode) {
        print('🚨 ErrorReport: ${errorReport.error}');
        if (errorReport.stackTrace != null) {
          print('Stack: ${errorReport.stackTrace}');
        }
      }
      
      // Send to backend (non-blocking)
      _sendErrorToBackend(errorReport);
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ ErrorReporting: Failed to report error - $e');
      }
    }
  }

  /// Send error to backend
  Future<void> _sendErrorToBackend(ErrorReport report) async {
    try {
      final response = await http.post(
        Uri.parse(_errorEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(report.toJson()),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('✅ ErrorReporting: Error sent to backend');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ ErrorReporting: Failed to send error to backend - $e');
      }
    }
  }

  /// Report a custom message
  void reportMessage(
    String message, {
    String? context,
    Map<String, dynamic>? data,
  }) {
    reportError(
      error: message,
      context: context,
      additionalData: data,
      fatal: false,
    );
  }

  /// Report a warning
  void reportWarning(
    String warning, {
    String? context,
    Map<String, dynamic>? data,
  }) {
    if (kDebugMode) {
      print('⚠️ Warning: $warning');
    }
    
    reportError(
      error: 'WARNING: $warning',
      context: context,
      additionalData: data,
      fatal: false,
    );
  }

  /// Report network error
  void reportNetworkError(
    String endpoint,
    int? statusCode,
    String? message,
  ) {
    reportError(
      error: 'Network Error: $endpoint',
      context: 'HTTP Request',
      additionalData: {
        'endpoint': endpoint,
        'status_code': statusCode,
        'message': message,
      },
      fatal: false,
    );
  }

  /// Get error history
  List<ErrorReport> getErrorHistory({int? limit}) {
    if (limit == null) return List.from(_errorHistory);
    
    final startIndex = _errorHistory.length > limit 
        ? _errorHistory.length - limit 
        : 0;
    return _errorHistory.sublist(startIndex);
  }

  /// Clear error history
  void clearHistory() {
    _errorHistory.clear();
    
    if (kDebugMode) {
      print('🗑️ ErrorReporting: History cleared');
    }
  }

  /// Get error statistics
  Map<String, dynamic> getStatistics() {
    final totalErrors = _errorHistory.length;
    final fatalErrors = _errorHistory.where((e) => e.fatal).length;
    final recentErrors = _errorHistory
        .where((e) => e.timestamp.isAfter(
          DateTime.now().subtract(const Duration(hours: 24))
        ))
        .length;
    
    return {
      'total_errors': totalErrors,
      'fatal_errors': fatalErrors,
      'recent_errors_24h': recentErrors,
      'non_fatal_errors': totalErrors - fatalErrors,
    };
  }

  /// Export error history as JSON
  String exportErrorHistory() {
    final data = _errorHistory.map((e) => e.toJson()).toList();
    return jsonEncode(data);
  }
}

/// Error report data class
class ErrorReport {
  final String error;
  final String? stackTrace;
  final String? context;
  final Map<String, dynamic>? additionalData;
  final bool fatal;
  final DateTime timestamp;

  ErrorReport({
    required this.error,
    this.stackTrace,
    this.context,
    this.additionalData,
    required this.fatal,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'stack_trace': stackTrace,
      'context': context,
      'additional_data': additionalData,
      'fatal': fatal,
      'timestamp': timestamp.toIso8601String(),
      'platform': kIsWeb ? 'web' : 'mobile',
      'app_version': '45.0.0',
    };
  }

  factory ErrorReport.fromJson(Map<String, dynamic> json) {
    return ErrorReport(
      error: json['error'] as String,
      stackTrace: json['stack_trace'] as String?,
      context: json['context'] as String?,
      additionalData: json['additional_data'] as Map<String, dynamic>?,
      fatal: json['fatal'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

/// Extension for easy error reporting
extension ErrorReportingExtension on Object {
  /// Report this object as an error
  void report({
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? data,
  }) {
    ErrorReportingService().reportError(
      error: this,
      stackTrace: stackTrace,
      context: context,
      additionalData: data,
    );
  }
}
