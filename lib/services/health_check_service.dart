/// HEALTH CHECK SERVICE (v103)
///
/// Real-time backend service monitoring for admin dashboard.
/// Previously every service URL pointed at ApiConfig.baseUrl -- three
/// pings to the same Worker pretending to be different services. Now we
/// actually distinguish:
///   - Worker        -> /health endpoint on Cloudflare Worker
///   - LiveKit       -> HTTP probe against livekitUrl
///   - Supabase REST -> trivial profiles query
///   - Supabase RT   -> realtime channel subscribe with timeout
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/api_config.dart';

enum HealthStatus { healthy, degraded, unhealthy, unknown }

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

class HealthCheckService extends ChangeNotifier {
  static final HealthCheckService _instance = HealthCheckService._internal();
  factory HealthCheckService() => _instance;
  HealthCheckService._internal();

  final Map<String, ServiceHealth> _serviceHealth = {};
  Timer? _healthCheckTimer;
  bool _isMonitoring = false;

  int _totalChecks = 0;
  int _failedChecks = 0;
  double get errorRate =>
      _totalChecks > 0 ? (_failedChecks / _totalChecks) * 100 : 0;

  Map<String, ServiceHealth> get serviceHealth => _serviceHealth;
  bool get isMonitoring => _isMonitoring;
  int get totalChecks => _totalChecks;
  int get failedChecks => _failedChecks;

  Future<void> initialize() async {
    if (kDebugMode) debugPrint('🏥 HealthCheck: Initializing...');
    await checkAllServices();
    if (kDebugMode) debugPrint('✅ HealthCheck: Initialized');
  }

  void startMonitoring({Duration interval = const Duration(seconds: 30)}) {
    if (_isMonitoring) return;
    _isMonitoring = true;
    _healthCheckTimer = Timer.periodic(interval, (_) => checkAllServices());
    if (kDebugMode) {
      debugPrint(
          '🔄 HealthCheck: Monitoring started (interval: ${interval.inSeconds}s)');
    }
  }

  void stopMonitoring() {
    _healthCheckTimer?.cancel();
    _isMonitoring = false;
    if (kDebugMode) debugPrint('⏸️ HealthCheck: Monitoring stopped');
  }

  Future<void> checkAllServices() async {
    await Future.wait([
      _checkWorker(),
      _checkLivekit(),
      _checkSupabaseRest(),
      _checkSupabaseRealtime(),
    ]);
    notifyListeners();
  }

  Future<void> _checkWorker() async {
    final sw = Stopwatch()..start();
    _totalChecks++;
    try {
      final res = await http
          .get(Uri.parse('${ApiConfig.workerUrl}/health'))
          .timeout(const Duration(seconds: 5));
      sw.stop();
      if (res.statusCode == 200) {
        _serviceHealth['worker'] = ServiceHealth(
          serviceName: 'Cloudflare Worker',
          status: HealthStatus.healthy,
          latencyMs: sw.elapsedMilliseconds,
          lastChecked: DateTime.now(),
          metadata: _safeJson(res.body),
        );
      } else {
        _failedChecks++;
        _serviceHealth['worker'] = ServiceHealth(
          serviceName: 'Cloudflare Worker',
          status: HealthStatus.degraded,
          latencyMs: sw.elapsedMilliseconds,
          errorMessage: 'HTTP ${res.statusCode}',
          lastChecked: DateTime.now(),
        );
      }
    } catch (e) {
      _failedChecks++;
      sw.stop();
      _serviceHealth['worker'] = ServiceHealth(
        serviceName: 'Cloudflare Worker',
        status: HealthStatus.unhealthy,
        latencyMs: sw.elapsedMilliseconds,
        errorMessage: e.toString(),
        lastChecked: DateTime.now(),
      );
    }
  }

  Future<void> _checkLivekit() async {
    final sw = Stopwatch()..start();
    _totalChecks++;
    try {
      const raw = ApiConfig.livekitUrl;
      if (raw.isEmpty) {
        sw.stop();
        _serviceHealth['livekit'] = ServiceHealth(
          serviceName: 'LiveKit',
          status: HealthStatus.unknown,
          latencyMs: 0,
          errorMessage: 'LIVEKIT_URL not configured',
          lastChecked: DateTime.now(),
        );
        return;
      }
      final probeUrl = raw
          .replaceFirst('wss://', 'https://')
          .replaceFirst('ws://', 'http://');
      final res = await http
          .get(Uri.parse(probeUrl))
          .timeout(const Duration(seconds: 5));
      sw.stop();
      // LiveKit antwortet auf GET / mit 200 oder 426 (Upgrade Required) --
      // beides bedeutet Server lebt.
      final ok = res.statusCode == 200 || res.statusCode == 426;
      if (ok) {
        _serviceHealth['livekit'] = ServiceHealth(
          serviceName: 'LiveKit',
          status: HealthStatus.healthy,
          latencyMs: sw.elapsedMilliseconds,
          lastChecked: DateTime.now(),
        );
      } else {
        _failedChecks++;
        _serviceHealth['livekit'] = ServiceHealth(
          serviceName: 'LiveKit',
          status: HealthStatus.degraded,
          latencyMs: sw.elapsedMilliseconds,
          errorMessage: 'HTTP ${res.statusCode}',
          lastChecked: DateTime.now(),
        );
      }
    } catch (e) {
      _failedChecks++;
      sw.stop();
      _serviceHealth['livekit'] = ServiceHealth(
        serviceName: 'LiveKit',
        status: HealthStatus.unhealthy,
        latencyMs: sw.elapsedMilliseconds,
        errorMessage: e.toString(),
        lastChecked: DateTime.now(),
      );
    }
  }

  Future<void> _checkSupabaseRest() async {
    final sw = Stopwatch()..start();
    _totalChecks++;
    try {
      await Supabase.instance.client
          .from('profiles')
          .select('id')
          .limit(1)
          .timeout(const Duration(seconds: 5));
      sw.stop();
      _serviceHealth['supabase_rest'] = ServiceHealth(
        serviceName: 'Supabase REST',
        status: HealthStatus.healthy,
        latencyMs: sw.elapsedMilliseconds,
        lastChecked: DateTime.now(),
      );
    } catch (e) {
      _failedChecks++;
      sw.stop();
      _serviceHealth['supabase_rest'] = ServiceHealth(
        serviceName: 'Supabase REST',
        status: HealthStatus.unhealthy,
        latencyMs: sw.elapsedMilliseconds,
        errorMessage: e.toString(),
        lastChecked: DateTime.now(),
      );
    }
  }

  Future<void> _checkSupabaseRealtime() async {
    final sw = Stopwatch()..start();
    _totalChecks++;
    final completer = Completer<bool>();
    Timer? timeout;
    RealtimeChannel? channel;
    try {
      channel = Supabase.instance.client.channel('health_check');
      timeout = Timer(const Duration(seconds: 5), () {
        if (!completer.isCompleted) completer.complete(false);
      });
      channel.subscribe((status, [error]) {
        if (status == RealtimeSubscribeStatus.subscribed &&
            !completer.isCompleted) {
          completer.complete(true);
        }
      });
      final ok = await completer.future;
      sw.stop();
      if (ok) {
        _serviceHealth['supabase_realtime'] = ServiceHealth(
          serviceName: 'Supabase Realtime',
          status: HealthStatus.healthy,
          latencyMs: sw.elapsedMilliseconds,
          lastChecked: DateTime.now(),
        );
      } else {
        _failedChecks++;
        _serviceHealth['supabase_realtime'] = ServiceHealth(
          serviceName: 'Supabase Realtime',
          status: HealthStatus.degraded,
          latencyMs: sw.elapsedMilliseconds,
          errorMessage: 'Subscribe timeout',
          lastChecked: DateTime.now(),
        );
      }
    } catch (e) {
      _failedChecks++;
      sw.stop();
      _serviceHealth['supabase_realtime'] = ServiceHealth(
        serviceName: 'Supabase Realtime',
        status: HealthStatus.unhealthy,
        latencyMs: sw.elapsedMilliseconds,
        errorMessage: e.toString(),
        lastChecked: DateTime.now(),
      );
    } finally {
      timeout?.cancel();
      try {
        await channel?.unsubscribe();
      } catch (e) { if (kDebugMode) debugPrint('health_check_service: silent catch -> $e'); }
    }
  }

  Map<String, dynamic>? _safeJson(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic>
          ? decoded
          : Map<String, dynamic>.from(decoded as Map);
    } catch (_) {
      return null;
    }
  }

  HealthStatus get overallStatus {
    if (_serviceHealth.isEmpty) return HealthStatus.unknown;
    final unhealthy = _serviceHealth.values
        .where((s) => s.status == HealthStatus.unhealthy)
        .length;
    final degraded = _serviceHealth.values
        .where((s) => s.status == HealthStatus.degraded)
        .length;
    if (unhealthy > 0) return HealthStatus.unhealthy;
    if (degraded > 0) return HealthStatus.degraded;
    return HealthStatus.healthy;
  }

  double get averageLatency {
    if (_serviceHealth.isEmpty) return 0;
    final total =
        _serviceHealth.values.map((s) => s.latencyMs).reduce((a, b) => a + b);
    return total / _serviceHealth.length;
  }

  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}
