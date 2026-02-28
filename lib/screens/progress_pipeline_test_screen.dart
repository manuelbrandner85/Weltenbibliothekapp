/// 🧪 PROGRESS PIPELINE TEST SCREEN
/// 
/// Test screen to preview ProgressPipeline widget with simulated progress
library;

import 'dart:async';
import 'package:flutter/material.dart';
import '../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import '../models/recherche_view_state.dart';
import '../widgets/recherche/progress_pipeline.dart';
import '../widgets/recherche/mode_selector.dart';

class ProgressPipelineTestScreen extends StatefulWidget {
  const ProgressPipelineTestScreen({super.key});

  @override
  State<ProgressPipelineTestScreen> createState() => _ProgressPipelineTestScreenState();
}

class _ProgressPipelineTestScreenState extends State<ProgressPipelineTestScreen> {
  RechercheMode _selectedMode = RechercheMode.simple;
  double _progress = 0.0;
  DateTime? _startedAt;
  bool _isRunning = false;
  Timer? _progressTimer;

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  void _startSimulation() {
    setState(() {
      _progress = 0.0;
      _startedAt = DateTime.now();
      _isRunning = true;
    });

    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _progress += 0.01;
        if (_progress >= 1.0) {
          _progress = 1.0;
          _isRunning = false;
          timer.cancel();
          
          // Show completion message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${_getModeDisplayName(_selectedMode)} abgeschlossen!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      });
    });
  }

  void _cancelSimulation() {
    _progressTimer?.cancel();
    setState(() {
      _isRunning = false;
      _progress = 0.0;
      _startedAt = null;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🛑 Recherche abgebrochen'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _resetSimulation() {
    _progressTimer?.cancel();
    setState(() {
      _isRunning = false;
      _progress = 0.0;
      _startedAt = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Progress Pipeline Test'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Mode Selector
          ModeSelector(
            selectedMode: _selectedMode,
            onModeSelected: (mode) {
              if (!_isRunning) {
                setState(() {
                  _selectedMode = mode;
                });
              }
            },
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                children: [
                  // Progress Pipeline Widget
                  if (_isRunning || _progress > 0)
                    ProgressPipeline(
                      mode: _selectedMode,
                      progress: _progress,
                      startedAt: _startedAt,
                      onCancel: _isRunning ? _cancelSimulation : null,
                    ),
                  
                  // Info card when not running
                  if (!_isRunning && _progress == 0.0)
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.search,
                            size: 64,
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Bereit für Recherche',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Wähle einen Modus und starte die Simulation',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildModeInfo(),
                        ],
                      ),
                    ),
                  
                  // Debug info
                  if (_progress > 0)
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🔍 Debug Info',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildDebugRow('Progress', '${(_progress * 100).toInt()}%'),
                          _buildDebugRow('Mode', _getModeDisplayName(_selectedMode)),
                          _buildDebugRow('Status', _isRunning ? '🟢 Running' : '🔴 Stopped'),
                          if (_startedAt != null)
                            _buildDebugRow(
                              'Elapsed',
                              '${DateTime.now().difference(_startedAt!).inSeconds}s',
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      
      // Control buttons
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isRunning ? null : _startSimulation,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Starten'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _progress > 0 ? _resetSimulation : null,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeInfo() {
    final info = _getModeInfo(_selectedMode);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                info['icon'] as IconData,
                size: 20,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                info['name'] as String,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            info['description'] as String,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.timer, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                'ca. ${info['duration']}s',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.layers, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${info['phases']} Phasen',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDebugRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  String _getModeDisplayName(RechercheMode mode) {
    switch (mode) {
      case RechercheMode.simple:
        return 'Simple';
      case RechercheMode.advanced:
        return 'Advanced';
      case RechercheMode.deep:
        return 'Deep Dive';
      case RechercheMode.conspiracy:
        return 'Conspiracy';
      case RechercheMode.historical:
        return 'Historical';
      case RechercheMode.scientific:
        return 'Scientific';
    }
  }

  Map<String, dynamic> _getModeInfo(RechercheMode mode) {
    switch (mode) {
      case RechercheMode.simple:
        return {
          'icon': Icons.search,
          'name': 'Simple Recherche',
          'description': 'Schnelle Suche mit 5 Phasen',
          'duration': 15,
          'phases': 5,
        };
      case RechercheMode.advanced:
        return {
          'icon': Icons.auto_awesome,
          'name': 'Advanced Recherche',
          'description': 'Erweiterte Recherche mit 7 Phasen',
          'duration': 30,
          'phases': 7,
        };
      case RechercheMode.deep:
        return {
          'icon': Icons.psychology,
          'name': 'Deep Dive',
          'description': 'Tiefenanalyse mit 8 Phasen',
          'duration': 45,
          'phases': 8,
        };
      case RechercheMode.conspiracy:
        return {
          'icon': Icons.visibility,
          'name': 'Conspiracy Mode',
          'description': 'Alternative Perspektiven mit 7 Phasen',
          'duration': 35,
          'phases': 7,
        };
      case RechercheMode.historical:
        return {
          'icon': Icons.history_edu,
          'name': 'Historical Research',
          'description': 'Historische Dokumente mit 7 Phasen',
          'duration': 40,
          'phases': 7,
        };
      case RechercheMode.scientific:
        return {
          'icon': Icons.science,
          'name': 'Scientific Research',
          'description': 'Wissenschaftliche Quellen mit 7 Phasen',
          'duration': 50,
          'phases': 7,
        };
    }
  }
}
