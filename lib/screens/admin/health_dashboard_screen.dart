/// 🏥 WELTENBIBLIOTHEK - HEALTH DASHBOARD SCREEN
/// Admin monitoring dashboard for backend services
/// Features: Real-time status, latency graphs, error rates

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/health_check_service.dart';
import '../../services/haptic_feedback_service.dart';
import 'dart:async';

class HealthDashboardScreen extends StatefulWidget {
  const HealthDashboardScreen({super.key});

  @override
  State<HealthDashboardScreen> createState() => _HealthDashboardScreenState();
}

class _HealthDashboardScreenState extends State<HealthDashboardScreen> {
  final HealthCheckService _healthService = HealthCheckService();
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _initializeHealth();
  }

  Future<void> _initializeHealth() async {
    await _healthService.initialize();
    _healthService.startMonitoring(interval: const Duration(seconds: 30));
    
    // UI refresh timer
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _healthService.stopMonitoring();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshHealth() async {
    await HapticFeedbackService().refresh();
    await _healthService.checkAllServices();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _healthService,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        appBar: AppBar(
          title: const Text('🏥 Health Dashboard'),
          backgroundColor: const Color(0xFF1A1A2E),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshHealth,
              tooltip: 'Aktualisieren',
            ),
          ],
        ),
        body: Consumer<HealthCheckService>(
          builder: (context, healthService, child) {
            return RefreshIndicator(
              onRefresh: _refreshHealth,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overall Status Card
                    _buildOverallStatusCard(healthService),
                    
                    const SizedBox(height: 20),
                    
                    // Metrics Row
                    _buildMetricsRow(healthService),
                    
                    const SizedBox(height: 24),
                    
                    // Services Status
                    _buildSectionHeader('Services Status'),
                    const SizedBox(height: 12),
                    ...healthService.serviceHealth.entries.map((entry) {
                      return _buildServiceCard(entry.key, entry.value);
                    }),
                    
                    const SizedBox(height: 24),
                    
                    // Monitoring Status
                    _buildMonitoringCard(healthService),
                    
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Overall Status Card
  Widget _buildOverallStatusCard(HealthCheckService service) {
    final status = service.overallStatus;
    final color = _getStatusColor(status);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.2),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            _getStatusIcon(status),
            color: color,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'System ${_getStatusText(status)}',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${service.serviceHealth.length} Services überwacht',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  /// Metrics Row
  Widget _buildMetricsRow(HealthCheckService service) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            icon: Icons.speed,
            label: 'Avg Latency',
            value: '${service.averageLatency.toStringAsFixed(0)}ms',
            color: service.averageLatency < 200 ? Colors.green : Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.error_outline,
            label: 'Error Rate',
            value: '${service.errorRate.toStringAsFixed(1)}%',
            color: service.errorRate < 5 ? Colors.green : Colors.red,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.check_circle_outline,
            label: 'Total Checks',
            value: '${service.totalChecks}',
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  /// Metric Card
  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white60,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Service Card
  Widget _buildServiceCard(String key, ServiceHealth health) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(health.status).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getStatusColor(health.status).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getStatusIcon(health.status),
                  color: _getStatusColor(health.status),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      health.serviceName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      health.statusText,
                      style: TextStyle(
                        fontSize: 14,
                        color: _getStatusColor(health.status),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: health.latencyMs < 200
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${health.latencyMs}ms',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: health.latencyMs < 200 ? Colors.green : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          
          if (health.errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      health.errorMessage!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 8),
          Text(
            'Last checked: ${_formatTime(health.lastChecked)}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white38,
            ),
          ),
        ],
      ),
    );
  }

  /// Monitoring Card
  Widget _buildMonitoringCard(HealthCheckService service) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: service.isMonitoring
                  ? Colors.green.withValues(alpha: 0.2)
                  : Colors.grey.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              service.isMonitoring ? Icons.visibility : Icons.visibility_off,
              color: service.isMonitoring ? Colors.green : Colors.grey,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Auto-Monitoring',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  service.isMonitoring
                      ? 'Aktiv - Prüfung alle 30s'
                      : 'Inaktiv',
                  style: TextStyle(
                    fontSize: 14,
                    color: service.isMonitoring ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Section Header
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  /// Helper: Get status color
  Color _getStatusColor(HealthStatus status) {
    switch (status) {
      case HealthStatus.healthy:
        return Colors.green;
      case HealthStatus.degraded:
        return Colors.orange;
      case HealthStatus.unhealthy:
        return Colors.red;
      case HealthStatus.unknown:
        return Colors.grey;
    }
  }

  /// Helper: Get status icon
  IconData _getStatusIcon(HealthStatus status) {
    switch (status) {
      case HealthStatus.healthy:
        return Icons.check_circle;
      case HealthStatus.degraded:
        return Icons.warning;
      case HealthStatus.unhealthy:
        return Icons.error;
      case HealthStatus.unknown:
        return Icons.help;
    }
  }

  /// Helper: Get status text
  String _getStatusText(HealthStatus status) {
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

  /// Helper: Format time
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else {
      return '${diff.inHours}h ago';
    }
  }
}
