/// 🏥 BACKEND HEALTH MONITOR SCREEN
/// Debug-Screen zur Überwachung aller Backend-Services
/// 
/// Features:
/// - Live Health-Checks für alle 6 APIs
/// - Farbcodierung: Grün (OK), Rot (Fehler), Orange (Warnung)
/// - Refresh-Button
/// - Detail-Infos (Version, Message)
library;

import 'package:flutter/material.dart';
 // OpenClaw v2.0
import '../../services/backend_health_service.dart';
import '../../theme/wb_cinematic_tokens.dart';
import '../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../widgets/cinematic/wb_glass_card.dart';
import '../../widgets/cinematic/wb_vignette.dart';

class BackendHealthMonitorScreen extends StatefulWidget {
  const BackendHealthMonitorScreen({super.key});

  @override
  State<BackendHealthMonitorScreen> createState() => _BackendHealthMonitorScreenState();
}

class _BackendHealthMonitorScreenState extends State<BackendHealthMonitorScreen> {
  Map<String, HealthStatus> _healthStatuses = {};
  bool _isLoading = false;
  DateTime? _lastCheck;

  @override
  void initState() {
    super.initState();
    _checkHealth();
  }

  Future<void> _checkHealth() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final statuses = await BackendHealthService.checkAllServices();
      setState(() {
        _healthStatuses = statuses;
        _lastCheck = DateTime.now();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Health-Check: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final healthyCount = _healthStatuses.values.where((s) => s.isHealthy).length;
    final totalCount = _healthStatuses.length;

    return Scaffold(
      backgroundColor: const Color(0xFF050310),
      appBar: WBGlassAppBar(
        world: WBWorld.neutral,
        title: '🏥 Backend Health Monitor',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _checkHealth,
            tooltip: 'Refresh',
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: _isLoading && _healthStatuses.isEmpty
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(context.wb.palette(WBWorld.neutral).primary),
              ),
            )
          : Stack(
            children: [
              const Positioned.fill(child: WBVignette()),
              RefreshIndicator(
              onRefresh: _checkHealth,
              child: ListView(
                padding: EdgeInsets.fromLTRB(WBSpace.lg, kToolbarHeight + MediaQuery.of(context).padding.top + WBSpace.lg, WBSpace.lg, WBSpace.lg),
                children: [
                  // 📊 OVERVIEW CARD
                  _buildOverviewCard(healthyCount, totalCount),
                  const SizedBox(height: 16),

                  // 🏥 HEALTH STATUS LIST
                  ..._healthStatuses.entries.map((entry) {
                    return _buildHealthCard(entry.key, entry.value);
                  }),

                  // 📅 LAST CHECK TIMESTAMP
                  if (_lastCheck != null) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'Letzter Check: ${_formatTime(_lastCheck!)}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 80), // Bottom padding
                ],
              ),
            ),
            ],
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _checkHealth,
        backgroundColor: const Color(0xFF2196F3),
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.refresh),
        label: Text(_isLoading ? 'Checking...' : 'Refresh All'),
      ),
    );
  }

  /// Overview Card mit Gesamtstatus
  Widget _buildOverviewCard(int healthy, int total) {
    final percentage = total > 0 ? (healthy / total * 100).toInt() : 0;
    final color = percentage >= 80
        ? Colors.green
        : percentage >= 50
            ? Colors.orange
            : Colors.red;

    return WBGlassCard(
      world: WBWorld.neutral,
      elevated: true,
      padding: const EdgeInsets.all(WBSpace.xl),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Gesamtstatus',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(WBRadius.pill),
                  border: Border.all(color: color, width: 1),
                ),
                child: Text('$percentage%',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
          const SizedBox(height: WBSpace.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
              const SizedBox(width: WBSpace.sm),
              Text('$healthy von $total Services',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  /// Health Card für einzelnen Service
  Widget _buildHealthCard(String serviceName, HealthStatus status) {
    final color = status.isHealthy ? Colors.green : Colors.red;
    final icon = status.isHealthy ? Icons.check_circle : Icons.error;

    return Padding(
      padding: const EdgeInsets.only(bottom: WBSpace.md),
      child: WBGlassCard(
        world: WBWorld.neutral,
        padding: const EdgeInsets.all(WBSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: WBSpace.md),
                Expanded(
                  child: Text(serviceName,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(WBRadius.sm),
                    border: Border.all(color: color, width: 1),
                  ),
                  child: Text(status.isHealthy ? 'ONLINE' : 'OFFLINE',
                      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            if (status.version != null) ...[
              const SizedBox(height: 8),
              Text(
                'Version: ${status.version}',
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 13,
                ),
              ),
            ],
            if (status.message != null) ...[
              const SizedBox(height: 4),
              Text(status.message!,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';
  }
}
