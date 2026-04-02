/// 🚨 WELTENBIBLIOTHEK - ERROR DASHBOARD SCREEN
/// Developer-friendly error monitoring interface
/// Features: Error list, statistics, export, clear
library;

import 'package:flutter/material.dart';
import '../../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../services/error_reporting_service.dart';

class ErrorDashboardScreen extends StatefulWidget {
  const ErrorDashboardScreen({super.key});

  @override
  State<ErrorDashboardScreen> createState() => _ErrorDashboardScreenState();
}

class _ErrorDashboardScreenState extends State<ErrorDashboardScreen> {
  final ErrorReportingService _errorService = ErrorReportingService();
  List<ErrorReport> _errors = [];
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadErrors();
  }

  void _loadErrors() {
    setState(() {
      _errors = _errorService.getErrorHistory();
      _stats = _errorService.getStatistics();
    });
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Historie löschen?'),
        content: const Text(
          'Alle gespeicherten Fehler werden gelöscht. '
          'Diese Aktion kann nicht rückgängig gemacht werden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _errorService.clearHistory();
      _loadErrors();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Fehlerhistorie gelöscht'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _exportHistory() async {
    try {
      final json = _errorService.exportErrorHistory();
      await Clipboard.setData(ClipboardData(text: json));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Fehlerhistorie in Zwischenablage kopiert'),
            backgroundColor: Colors.green,
          ),
        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🚨 Error Dashboard'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Exportieren',
            onPressed: _exportHistory,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Löschen',
            onPressed: _clearHistory,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Aktualisieren',
            onPressed: _loadErrors,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Statistics Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Statistiken',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Gesamt',
                          '${_stats['total_errors'] ?? 0}',
                          Icons.bug_report,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          'Fatal',
                          '${_stats['fatal_errors'] ?? 0}',
                          Icons.error,
                          Colors.red,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          '24h',
                          '${_stats['recent_errors_24h'] ?? 0}',
                          Icons.access_time,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          'Warnings',
                          '${_stats['non_fatal_errors'] ?? 0}',
                          Icons.warning,
                          Colors.amber,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Error List
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.list,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Fehlerhistorie',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  if (_errors.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          '✅ Keine Fehler gefunden!\nDie App läuft stabil.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    )
                  else
                    ..._errors.reversed.map((error) => _buildErrorTile(error)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorTile(ErrorReport error) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm:ss');
    
    return ExpansionTile(
      leading: Icon(
        error.fatal ? Icons.error : Icons.warning,
        color: error.fatal ? Colors.red : Colors.orange,
      ),
      title: Text(
        error.error,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: Text(
        dateFormat.format(error.timestamp),
        style: const TextStyle(fontSize: 12),
      ),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (error.context != null) ...[
                Text(
                  'Context: ${error.context}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              
              if (error.stackTrace != null) ...[
                const Text(
                  'Stack Trace:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    error.stackTrace!,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              
              if (error.additionalData != null) ...[
                const Text(
                  'Additional Data:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  error.additionalData.toString(),
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
