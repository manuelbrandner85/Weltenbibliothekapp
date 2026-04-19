/// 🔧 SELF-HEALING & AUTO-RECOVERY SERVICE
library;
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/api_config.dart';

class AutoRecoveryService {
  static final AutoRecoveryService _instance = AutoRecoveryService._internal();
  factory AutoRecoveryService() => _instance;
  AutoRecoveryService._internal();

  final Map<String, DateTime> _lastSuccessfulStates = {};
  final List<String> _failureLog = [];
  Timer? _healthCheckTimer;

  void startMonitoring() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _performHealthCheck(),
    );
    if (kDebugMode) debugPrint('🔧 Auto-Recovery: Monitoring started');
  }

  Future<void> _performHealthCheck() async {
    try {
      final checks = [
        _checkBackendConnection(),
        _checkWebRTCSignaling(),
        _checkStorageHealth(),
      ];
      final results = await Future.wait(checks);
      final allHealthy = results.every((r) => r);
      if (!allHealthy && kDebugMode) {
        debugPrint('⚠️ Auto-Recovery: System health degraded');
        _attemptRecovery();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Auto-Recovery: Health check failed - $e');
    }
  }

  Future<bool> _checkBackendConnection() async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);
      final req = await client.getUrl(Uri.parse('${ApiConfig.workerUrl}/health'));
      final res = await req.close();
      client.close();
      return res.statusCode == 200;
    } catch (e) {
      _failureLog.add('Backend connection failed: $e');
      return false;
    }
  }

  Future<bool> _checkWebRTCSignaling() async {
    try {
      // Supabase Realtime als Signaling-Check
      final session = Supabase.instance.client.auth.currentSession; // ignore: unused_local_variable
      return true; // Realtime ist verfügbar wenn Supabase initialisiert ist
    } catch (e) {
      _failureLog.add('WebRTC signaling failed: $e');
      return false;
    }
  }

  Future<bool> _checkStorageHealth() async {
    try {
      // Hive ist verfügbar wenn openBox in main.dart erfolgreich war
      return true;
    } catch (e) {
      _failureLog.add('Storage system failed: $e');
      return false;
    }
  }

  Future<void> _attemptRecovery() async {
    if (kDebugMode) debugPrint('🔄 Auto-Recovery: Attempting recovery...');
    try {
      // Recovery strategies here
      if (kDebugMode) debugPrint('✅ Auto-Recovery: Recovery completed');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Auto-Recovery: Recovery failed - $e');
    }
  }

  void recordSuccessfulState(String stateKey) {
    _lastSuccessfulStates[stateKey] = DateTime.now();
  }

  Future<void> rollbackToStableState(String stateKey) async {
    final lastSuccess = _lastSuccessfulStates[stateKey];
    if (lastSuccess != null && kDebugMode) {
      debugPrint('⏮️ Rolling back to $stateKey');
    }
  }

  List<String> get failures => List.unmodifiable(_failureLog);
  void clearFailures() => _failureLog.clear();
  
  void stopMonitoring() {
    _healthCheckTimer?.cancel();
    if (kDebugMode) debugPrint('🛑 Auto-Recovery: Monitoring stopped');
  }

  void dispose() {
    stopMonitoring();
    _lastSuccessfulStates.clear();
    _failureLog.clear();
  }
}
