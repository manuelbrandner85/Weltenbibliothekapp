/// 🏥 WELTENBIBLIOTHEK - HEALTH CHECK SERVICE
/// Real-time backend service monitoring for admin dashboard
/// Features: API health, latency tracking, error rates, WebSocket status

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Service Health Status
enum HealthStatus {
  healthy,
  degraded,
  unhealthy,
  unknown,
}

/// Service Health Info
class ServiceHealth {
  final String serviceName;
  final HealthStatus status;
  final int latencyMs;
  final String? errorMessage;
  final DateTime lastChecked;
  final Map<String, dynamic>? metadata;

  ServiceHealth({
    required this.serviceName,
    required this.status,
    required this.latencyMs,
    this.errorMessage,
    required this.lastChecked,
    this.metadata,
  });

  String get statusEmoji {
    switch (status) {
      case HealthStatus.healthy:
        return '✅';
      case HealthStatus.degraded:
        return '⚠️';
      case HealthStatus.unhealthy:
        return '❌';
      case HealthStatus.unknown:
        return '❓';
    }
  }

  String get statusText {
    switch (status) {
      case HealthStatus.healthy:
        return 'Healthy';
      case HealthStatus.degraded:
        return 'Degraded';
      case HealthStatus.unhealthy:
        return 'Unhealthy';
      case HealthStatus.unknown:
        return 'Unknown';
    }
  }
}

/// Health Check Service
class HealthCheckService extends ChangeNotifier {
  static final HealthCheckService _instance = HealthCheckService._internal();
  factory HealthCheckService() => _instance;
  HealthCheckService._internal();

  // Service endpoints
  static const String _chatApiUrl = 'https://weltenbibliothek-websocket.brandy13062.workers.dev';
  static const String _voiceApiUrl = 'https://weltenbibliothek-voice.brandy13062.workers.dev';
  static const String _storageApiUrl = 'https://weltenbibliothek-r2.brandy13062.workers.dev';

  // Health data
  final Map<String, ServiceHealth> _serviceHealth = {};
  Timer? _healthCheckTimer;
  bool _isMonitoring = false;

  // Metrics
  int _totalChecks = 0;
  int _failedChecks = 0;
  double get errorRate => _totalChecks > 0 ? (_failedChecks / _totalChecks) * 100 : 0;

  // Getters
  Map<String, ServiceHealth> get serviceHealth => _serviceHealth;
  bool get isMonitoring => _isMonitoring;
  int get totalChecks => _totalChecks;
  int get failedChecks => _failedChecks;

  /// Initialize health monitoring
  Future<void> initialize() async {
    if (kDebugMode) {
      print('🏥 HealthCheck: Initializing...');
    }
    
    // Initial check
    await checkAllServices();
    
    if (kDebugMode) {
      print('✅ HealthCheck: Initialized');
    }
  }

  /// Start continuous monitoring
  void startMonitoring({Duration interval = const Duration(seconds: 30)}) {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    _healthCheckTimer = Timer.periodic(interval, (_) {
      checkAllServices();
    });
    
    if (kDebugMode) {
      print('🔄 HealthCheck: Monitoring started (interval: ${interval.inSeconds}s)');
    }
  }

  /// Stop monitoring
  void stopMonitoring() {
    _healthCheckTimer?.cancel();
    _isMonitoring = false;
    
    if (kDebugMode) {
      print('⏸️ HealthCheck: Monitoring stopped');
    }
  }

  /// Check all services
  Future<void> checkAllServices() async {
    await Future.wait([
      _checkChatApi(),
      _checkVoiceApi(),
      _checkStorageApi(),
    ]);
    
    notifyListeners();
  }

  /// Check Chat API health
  Future<void> _checkChatApi() async {
    final stopwatch = Stopwatch()..start();
    _totalChecks++;
    
    try {
      final response = await http.get(
        Uri.parse('$_chatApiUrl/health'),
      ).timeout(const Duration(seconds: 5));
      
      stopwatch.stop();
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _serviceHealth['chat_api'] = ServiceHealth(
          serviceName: 'Chat API',
          status: HealthStatus.healthy,
          latencyMs: stopwatch.elapsedMilliseconds,
          lastChecked: DateTime.now(),
          metadata: data,
        );
      } else {
        _failedChecks++;
        _serviceHealth['chat_api'] = ServiceHealth(
          serviceName: 'Chat API',
          status: HealthStatus.degraded,
          latencyMs: stopwatch.elapsedMilliseconds,
          errorMessage: 'HTTP ${response.statusCode}',
          lastChecked: DateTime.now(),
        );
      }
    } catch (e) {
      _failedChecks++;
      stopwatch.stop();
      _serviceHealth['chat_api'] = ServiceHealth(
        serviceName: 'Chat API',
        status: HealthStatus.unhealthy,
        latencyMs: stopwatch.elapsedMilliseconds,
        errorMessage: e.toString(),
        lastChecked: DateTime.now(),
      );
    }
  }

  /// Check Voice API health
  Future<void> _checkVoiceApi() async {
    final stopwatch = Stopwatch()..start();
    _totalChecks++;
    
    try {
      final response = await http.get(
        Uri.parse('$_voiceApiUrl/health'),
      ).timeout(const Duration(seconds: 5));
      
      stopwatch.stop();
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _serviceHealth['voice_api'] = ServiceHealth(
          serviceName: 'Voice API',
          status: HealthStatus.healthy,
          latencyMs: stopwatch.elapsedMilliseconds,
          lastChecked: DateTime.now(),
          metadata: data,
        );
      } else {
        _failedChecks++;
        _serviceHealth['voice_api'] = ServiceHealth(
          serviceName: 'Voice API',
          status: HealthStatus.degraded,
          latencyMs: stopwatch.elapsedMilliseconds,
          errorMessage: 'HTTP ${response.statusCode}',
          lastChecked: DateTime.now(),
        );
      }
    } catch (e) {
      _failedChecks++;
      stopwatch.stop();
      _serviceHealth['voice_api'] = ServiceHealth(
        serviceName: 'Voice API',
        status: HealthStatus.unhealthy,
        latencyMs: stopwatch.elapsedMilliseconds,
        errorMessage: e.toString(),
        lastChecked: DateTime.now(),
      );
    }
  }

  /// Check Storage API health
  Future<void> _checkStorageApi() async {
    final stopwatch = Stopwatch()..start();
    _totalChecks++;
    
    try {
      final response = await http.get(
        Uri.parse('$_storageApiUrl/health'),
      ).timeout(const Duration(seconds: 5));
      
      stopwatch.stop();
      
      if (response.statusCode == 200) {
        _serviceHealth['storage_api'] = ServiceHealth(
          serviceName: 'Storage API',
          status: HealthStatus.healthy,
          latencyMs: stopwatch.elapsedMilliseconds,
          lastChecked: DateTime.now(),
        );
      } else {
        _failedChecks++;
        _serviceHealth['storage_api'] = ServiceHealth(
          serviceName: 'Storage API',
          status: HealthStatus.degraded,
          latencyMs: stopwatch.elapsedMilliseconds,
          errorMessage: 'HTTP ${response.statusCode}',
          lastChecked: DateTime.now(),
        );
      }
    } catch (e) {
      _failedChecks++;
      stopwatch.stop();
      _serviceHealth['storage_api'] = ServiceHealth(
        serviceName: 'Storage API',
        status: HealthStatus.unhealthy,
        latencyMs: stopwatch.elapsedMilliseconds,
        errorMessage: e.toString(),
        lastChecked: DateTime.now(),
      );
    }
  }

  /// Get overall system status
  HealthStatus get overallStatus {
    if (_serviceHealth.isEmpty) return HealthStatus.unknown;
    
    final unhealthyCount = _serviceHealth.values
        .where((s) => s.status == HealthStatus.unhealthy)
        .length;
    
    final degradedCount = _serviceHealth.values
        .where((s) => s.status == HealthStatus.degraded)
        .length;
    
    if (unhealthyCount > 0) return HealthStatus.unhealthy;
    if (degradedCount > 0) return HealthStatus.degraded;
    return HealthStatus.healthy;
  }

  /// Get average latency
  double get averageLatency {
    if (_serviceHealth.isEmpty) return 0;
    
    final total = _serviceHealth.values
        .map((s) => s.latencyMs)
        .reduce((a, b) => a + b);
    
    return total / _serviceHealth.length;
  }

  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}
