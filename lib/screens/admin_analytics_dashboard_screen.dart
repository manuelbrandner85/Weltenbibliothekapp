import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/analytics_service.dart';
import 'dart:convert';

/// 📊 Admin Analytics Dashboard
///
/// Zeigt umfassende Analytics-Daten für Administratoren
class AdminAnalyticsDashboardScreen extends StatefulWidget {
  const AdminAnalyticsDashboardScreen({super.key});

  @override
  State<AdminAnalyticsDashboardScreen> createState() =>
      _AdminAnalyticsDashboardScreenState();
}

class _AdminAnalyticsDashboardScreenState
    extends State<AdminAnalyticsDashboardScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();

  bool _isLoading = true;
  String _selectedTimeRange = '7d'; // 24h, 7d, 30d, all
  Map<String, dynamic>? _summaryData;
  Map<String, dynamic>? _webrtcMetrics;
  Map<String, dynamic>? _userEngagement;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Lade verschiedene Metriken parallel
      final results = await Future.wait([
        _analyticsService.getSummary(timeRange: _selectedTimeRange),
        _analyticsService.getWebRTCMetrics(timeRange: _selectedTimeRange),
        _analyticsService.getUserEngagement(timeRange: _selectedTimeRange),
      ]);

      if (mounted) {
        setState(() {
          _summaryData = results[0];
          _webrtcMetrics = results[1];
          _userEngagement = results[2];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
            tooltip: 'Aktualisieren',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.file_download),
            tooltip: 'Export',
            onSelected: (format) => _exportData(format),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'json',
                child: Text('JSON exportieren'),
              ),
              const PopupMenuItem(value: 'csv', child: Text('CSV exportieren')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Fehler: $_error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadAnalytics,
                    child: const Text('Erneut versuchen'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time Range Selector
                    _buildTimeRangeSelector(),

                    const SizedBox(height: 24),

                    // Summary Cards
                    _buildSummaryCards(),

                    const SizedBox(height: 24),

                    // WebRTC Metrics
                    _buildWebRTCSection(),

                    const SizedBox(height: 24),

                    // User Engagement
                    _buildUserEngagementSection(),

                    const SizedBox(height: 24),

                    // Event Analytics
                    _buildEventAnalyticsSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.calendar_today),
            const SizedBox(width: 12),
            const Text(
              'Zeitraum:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: '24h', label: Text('24h')),
                  ButtonSegment(value: '7d', label: Text('7 Tage')),
                  ButtonSegment(value: '30d', label: Text('30 Tage')),
                  ButtonSegment(value: 'all', label: Text('Gesamt')),
                ],
                selected: {_selectedTimeRange},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _selectedTimeRange = newSelection.first;
                  });
                  _loadAnalytics();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    if (_summaryData == null) return const SizedBox.shrink();

    final totalUsers = _summaryData!['total_users'] ?? 0;
    final totalEvents = _summaryData!['total_events'] ?? 0;
    final totalStreams = _summaryData!['total_streams'] ?? 0;
    final totalMessages = _summaryData!['total_messages'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Übersicht',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildMetricCard(
              title: 'Benutzer',
              value: totalUsers.toString(),
              icon: Icons.people,
              color: Colors.blue,
            ),
            _buildMetricCard(
              title: 'Events',
              value: totalEvents.toString(),
              icon: Icons.event,
              color: Colors.purple,
            ),
            _buildMetricCard(
              title: 'Live-Streams',
              value: totalStreams.toString(),
              icon: Icons.videocam,
              color: Colors.red,
            ),
            _buildMetricCard(
              title: 'Nachrichten',
              value: totalMessages.toString(),
              icon: Icons.message,
              color: Colors.green,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebRTCSection() {
    if (_webrtcMetrics == null) return const SizedBox.shrink();

    final successRate = (_webrtcMetrics!['success_rate'] ?? 0.0) * 100;
    final avgQuality = _webrtcMetrics!['avg_quality'] ?? 0.0;
    final totalConnections = _webrtcMetrics!['total_connections'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'WebRTC-Metriken',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildMetricRow(
                  'Erfolgsrate',
                  '${successRate.toStringAsFixed(1)}%',
                  successRate,
                  Colors.green,
                ),
                const Divider(height: 24),
                _buildMetricRow(
                  'Durchschn. Qualität',
                  '${avgQuality.toStringAsFixed(1)}/5.0',
                  avgQuality / 5.0,
                  Colors.blue,
                ),
                const Divider(height: 24),
                ListTile(
                  leading: const Icon(Icons.connect_without_contact),
                  title: const Text('Verbindungen'),
                  trailing: Text(
                    totalConnections.toString(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserEngagementSection() {
    if (_userEngagement == null) return const SizedBox.shrink();

    final activeUsers = _userEngagement!['active_users'] ?? 0;
    final avgSessionDuration = _userEngagement!['avg_session_duration'] ?? 0;
    final topEvents = _userEngagement!['top_events'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nutzer-Engagement',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline, color: Colors.blue),
                  title: const Text('Aktive Nutzer'),
                  trailing: Text(
                    activeUsers.toString(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.timer, color: Colors.orange),
                  title: const Text('Durchschn. Sitzungsdauer'),
                  trailing: Text(
                    '${(avgSessionDuration / 60).toStringAsFixed(1)} min',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
                if (topEvents.isNotEmpty) ...[
                  const Divider(height: 24),
                  const Text(
                    'Top Events',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...topEvents.take(5).map((event) {
                    return ListTile(
                      dense: true,
                      leading: const Icon(
                        Icons.star,
                        size: 16,
                        color: Colors.amber,
                      ),
                      title: Text(event['type'] as String),
                      trailing: Text(
                        event['count'].toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventAnalyticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Event-Analytics',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.info_outline, color: Colors.blue),
                  title: Text('Detaillierte Event-Statistiken'),
                  subtitle: Text('Verfügbar nach Server-Integration'),
                ),
                const Divider(),
                TextButton.icon(
                  onPressed: () {
                    // TODO: Implementiere detaillierte Event-Analytics
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Feature wird implementiert...'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.insights),
                  label: const Text('Detaillierte Analyse öffnen'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricRow(
    String label,
    String value,
    double progress,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Future<void> _exportData(String format) async {
    try {
      final data = {
        'time_range': _selectedTimeRange,
        'exported_at': DateTime.now().toIso8601String(),
        'summary': _summaryData,
        'webrtc_metrics': _webrtcMetrics,
        'user_engagement': _userEngagement,
      };

      if (format == 'json') {
        final jsonString = const JsonEncoder.withIndent('  ').convert(data);

        if (kDebugMode) {
          debugPrint('📊 Analytics Export (JSON):');
          debugPrint(jsonString);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ JSON-Export in Console ausgegeben'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else if (format == 'csv') {
        // CSV-Export (vereinfacht)
        final csvLines = [
          'Metric,Value',
          'Total Users,${_summaryData?['total_users'] ?? 0}',
          'Total Events,${_summaryData?['total_events'] ?? 0}',
          'Total Streams,${_summaryData?['total_streams'] ?? 0}',
          'Total Messages,${_summaryData?['total_messages'] ?? 0}',
          'WebRTC Success Rate,${_webrtcMetrics?['success_rate'] ?? 0}',
          'Active Users,${_userEngagement?['active_users'] ?? 0}',
        ];

        final csvString = csvLines.join('\n');

        if (kDebugMode) {
          debugPrint('📊 Analytics Export (CSV):');
          debugPrint(csvString);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ CSV-Export in Console ausgegeben'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Export fehlgeschlagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
