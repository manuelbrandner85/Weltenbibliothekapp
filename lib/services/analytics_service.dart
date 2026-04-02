/// 📊 WELTENBIBLIOTHEK - CLOUDFLARE ANALYTICS SERVICE
/// Track user behavior, events, and app performance
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class CloudflareAnalyticsService {
  static final CloudflareAnalyticsService _instance = CloudflareAnalyticsService._internal();
  factory CloudflareAnalyticsService() => _instance;
  CloudflareAnalyticsService._internal();

  // Analytics Endpoint (Cloudflare Worker)
  final String _analyticsEndpoint = '${ApiConfig.baseUrl}/analytics';
  
  // Session tracking
  String? _sessionId;
  String? _userId;
  DateTime? _sessionStart;
  
  /// Initialize analytics with user info
  void initialize({String? userId}) {
    _userId = userId;
    _sessionId = _generateSessionId();
    _sessionStart = DateTime.now();
    
    if (kDebugMode) {
      debugPrint('📊 Analytics initialized: User=$userId, Session=$_sessionId');
    }
    
    // Track app launch
    trackEvent('app_launch', properties: {
      'platform': _getPlatform(),
      'user_id': userId,
    });
  }
  
  /// Track page/screen view
  Future<void> trackScreenView(String screenName) async {
    await trackEvent('screen_view', properties: {
      'screen_name': screenName,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// Track user action/event
  Future<void> trackEvent(
    String eventName, {
    Map<String, dynamic>? properties,
  }) async {
    try {
      final eventData = {
        'event_name': eventName,
        'session_id': _sessionId,
        'user_id': _userId ?? 'anonymous',
        'timestamp': DateTime.now().toIso8601String(),
        'platform': _getPlatform(),
        'properties': properties ?? {},
      };
      
      if (kDebugMode) {
        debugPrint('📊 Analytics Event: $eventName');
        if (properties != null && properties.isNotEmpty) {
          debugPrint('   Properties: $properties');
        }
      }
      
      // Send to Cloudflare Worker (non-blocking)
      _sendAnalytics(eventData);
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Analytics Error: $e');
      }
    }
  }
  
  /// Track button click
  Future<void> trackButtonClick(String buttonName, {String? context}) async {
    await trackEvent('button_click', properties: {
      'button_name': buttonName,
      'context': context,
    });
  }
  
  /// Track message sent
  Future<void> trackMessageSent({
    required String roomId,
    required String realm,
    bool hasMedia = false,
    bool isVoice = false,
  }) async {
    await trackEvent('message_sent', properties: {
      'room_id': roomId,
      'realm': realm,
      'has_media': hasMedia,
      'is_voice': isVoice,
    });
  }
  
  /// Track article view
  Future<void> trackArticleView({
    required String articleId,
    required String category,
    required String realm,
  }) async {
    await trackEvent('article_view', properties: {
      'article_id': articleId,
      'category': category,
      'realm': realm,
    });
  }
  
  /// Track search
  Future<void> trackSearch({
    required String query,
    required String searchType,
    int? resultCount,
  }) async {
    await trackEvent('search', properties: {
      'query': query,
      'search_type': searchType,
      'result_count': resultCount,
    });
  }
  
  /// Track error
  Future<void> trackError({
    required String errorType,
    required String errorMessage,
    String? stackTrace,
    String? context,
  }) async {
    await trackEvent('error', properties: {
      'error_type': errorType,
      'error_message': errorMessage,
      'stack_trace': stackTrace,
      'context': context,
    });
  }
  
  /// Track session duration on app close
  Future<void> trackSessionEnd() async {
    if (_sessionStart != null) {
      final duration = DateTime.now().difference(_sessionStart!);
      
      await trackEvent('session_end', properties: {
        'duration_seconds': duration.inSeconds,
        'duration_minutes': duration.inMinutes,
      });
    }
  }
  
  /// Track performance metric
  Future<void> trackPerformance({
    required String metricName,
    required int durationMs,
    Map<String, dynamic>? metadata,
  }) async {
    await trackEvent('performance', properties: {
      'metric_name': metricName,
      'duration_ms': durationMs,
      'metadata': metadata,
    });
  }
  
  /// Track feature usage
  Future<void> trackFeatureUsage(String featureName) async {
    await trackEvent('feature_usage', properties: {
      'feature_name': featureName,
    });
  }
  
  /// Track user engagement
  Future<void> trackEngagement({
    required String actionType,
    String? targetId,
    Map<String, dynamic>? metadata,
  }) async {
    await trackEvent('engagement', properties: {
      'action_type': actionType,
      'target_id': targetId,
      'metadata': metadata,
    });
  }
  
  // Private: Send analytics to backend (non-blocking)
  void _sendAnalytics(Map<String, dynamic> data) {
    // Fire and forget - don't wait for response
    http.post(
      Uri.parse(_analyticsEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${ApiConfig.cloudflareApiToken}',
      },
      body: json.encode(data),
    ).timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        // Silently fail - analytics shouldn't block app
        return http.Response('timeout', 408);
      },
    ).catchError((e) {
      // Silently fail
      if (kDebugMode) {
        debugPrint('⚠️ Analytics send failed (non-critical): $e');
      }
      return http.Response('error', 500);
    });
  }
  
  // Private: Generate unique session ID
  String _generateSessionId() {
    return 'session_${DateTime.now().millisecondsSinceEpoch}_${_userId ?? "anon"}';
  }
  
  // Private: Get platform info
  String _getPlatform() {
    if (kIsWeb) {
      return 'web';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'android';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'ios';
    } else {
      return 'unknown';
    }
  }
}


/// 🐛 CRASH REPORTER
/// Simple crash reporting without Firebase

class CrashReporter {
  static final CrashReporter _instance = CrashReporter._internal();
  factory CrashReporter() => _instance;
  CrashReporter._internal();
  
  final CloudflareAnalyticsService _analytics = CloudflareAnalyticsService();
  
  /// Report a crash/error
  Future<void> reportError({
    required dynamic error,
    required StackTrace stackTrace,
    String? context,
    Map<String, dynamic>? additionalInfo,
  }) async {
    try {
      final errorInfo = {
        'error_type': error.runtimeType.toString(),
        'error_message': error.toString(),
        'stack_trace': stackTrace.toString(),
        'context': context,
        'additional_info': additionalInfo,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      if (kDebugMode) {
        debugPrint('🐛 Crash Report:');
        debugPrint('   Error: ${error.toString()}');
        debugPrint('   Context: $context');
      }
      
      // Send to analytics as error event
      await _analytics.trackError(
        errorType: error.runtimeType.toString(),
        errorMessage: error.toString(),
        stackTrace: stackTrace.toString(),
        context: context,
      );
      
      // Also log to backend crash endpoint
      _sendCrashReport(errorInfo);
      
    } catch (e) {
      // Silently fail - don't crash while reporting crash
      if (kDebugMode) {
        debugPrint('❌ Crash reporting failed: $e');
      }
    }
  }
  
  /// Report a non-fatal error
  Future<void> reportNonFatal({
    required String message,
    String? context,
    Map<String, dynamic>? additionalInfo,
  }) async {
    await _analytics.trackEvent('non_fatal_error', properties: {
      'message': message,
      'context': context,
      'additional_info': additionalInfo,
    });
  }
  
  // Private: Send crash to backend
  void _sendCrashReport(Map<String, dynamic> data) {
    final endpoint = '${ApiConfig.baseUrl}/crashes';
    
    http.post(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${ApiConfig.cloudflareApiToken}',
      },
      body: json.encode(data),
    ).timeout(
      const Duration(seconds: 5),
    ).catchError((e) {
      // Silently fail
      if (kDebugMode) {
        debugPrint('⚠️ Crash report send failed: $e');
      }
      return http.Response('error', 500);
    });
  }
}


/// 📊 PERFORMANCE TRACKER
/// Track app performance metrics

class PerformanceTracker {
  static final PerformanceTracker _instance = PerformanceTracker._internal();
  factory PerformanceTracker() => _instance;
  PerformanceTracker._internal();
  
  final CloudflareAnalyticsService _analytics = CloudflareAnalyticsService();
  final Map<String, DateTime> _startTimes = {};
  
  /// Start tracking a performance metric
  void startTrace(String traceName) {
    _startTimes[traceName] = DateTime.now();
    
    if (kDebugMode) {
      debugPrint('⏱️ Performance trace started: $traceName');
    }
  }
  
  /// Stop tracking and report
  Future<void> stopTrace(
    String traceName, {
    Map<String, dynamic>? metadata,
  }) async {
    final startTime = _startTimes[traceName];
    if (startTime == null) {
      if (kDebugMode) {
        debugPrint('⚠️ No start time for trace: $traceName');
      }
      return;
    }
    
    final duration = DateTime.now().difference(startTime);
    _startTimes.remove(traceName);
    
    if (kDebugMode) {
      debugPrint('⏱️ Performance trace completed: $traceName (${duration.inMilliseconds}ms)');
    }
    
    await _analytics.trackPerformance(
      metricName: traceName,
      durationMs: duration.inMilliseconds,
      metadata: metadata,
    );
  }
  
  /// Track a metric directly
  Future<void> trackMetric({
    required String metricName,
    required int value,
    Map<String, dynamic>? metadata,
  }) async {
    await _analytics.trackEvent('metric', properties: {
      'metric_name': metricName,
      'value': value,
      'metadata': metadata,
    });
  }
}
