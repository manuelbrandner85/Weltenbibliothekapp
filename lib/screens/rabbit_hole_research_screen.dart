/// WELTENBIBLIOTHEK v5.13 – KANINCHENBAU-RECHERCHE SCREEN
/// 
/// Vollständig integriert mit echten Backend-Daten
/// KEINE Mock-Daten - nur echte API-Calls
library;

import 'package:flutter/material.dart';
import '../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import 'dart:async';
import '../models/rabbit_hole_models.dart';
import '../services/rabbit_hole_service.dart';
import '../widgets/rabbit_hole_visualization_card.dart';

class RabbitHoleResearchScreen extends StatefulWidget {
  final String initialTopic;

  const RabbitHoleResearchScreen({
    super.key,
    this.initialTopic = '',
  });

  @override
  State<RabbitHoleResearchScreen> createState() => _RabbitHoleResearchScreenState();
}

class _RabbitHoleResearchScreenState extends State<RabbitHoleResearchScreen> {
  final _searchController = TextEditingController();
  final _service = RabbitHoleService();
  
  RabbitHoleAnalysis? _currentAnalysis;
  bool _isLoading = false;
  String? _errorMessage;
  RabbitHoleConfig _selectedConfig = RabbitHoleConfig.standard;
  
  final List<RabbitHoleEvent> _events = [];
  
  /// 🆕 Bricht Recherche ab
  void _cancelRabbitHole() {
    _service.cancelResearch();
    setState(() {
      _isLoading = false;
      _errorMessage = 'Recherche abgebrochen';
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🛑 Kaninchenbau-Recherche abgebrochen'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialTopic.isNotEmpty) {
      _searchController.text = widget.initialTopic;
      // Auto-start wenn Topic vorgegeben ist
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startRabbitHole();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🕳️ Kaninchenbau-Recherche'),
        backgroundColor: Colors.deepPurple[700],
        actions: [
          // Config-Button
          PopupMenuButton<RabbitHoleConfig>(
            icon: const Icon(Icons.settings),
            onSelected: (config) {
              setState(() => _selectedConfig = config);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: RabbitHoleConfig.quick,
                child: Text('Schnell (4 Ebenen)'),
              ),
              const PopupMenuItem(
                value: RabbitHoleConfig.standard,
                child: Text('Standard (6 Ebenen)'),
              ),
              const PopupMenuItem(
                value: RabbitHoleConfig.deep,
                child: Text('Tief (6 Ebenen + Delay)'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // SUCHFELD & START-BUTTON
            _buildSearchSection(),
            
            // FEHLER-ANZEIGE
            if (_errorMessage != null) _buildErrorBanner(),
            
            // LIVE-EVENT-LOG (während Recherche)
            if (_isLoading && _events.isNotEmpty) _buildEventLog(),
            
            // HAUPT-CONTENT
            Expanded(
              child: _buildMainContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple[50],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            enabled: !_isLoading,
            decoration: InputDecoration(
              hintText: 'Thema eingeben (z.B. "MK Ultra", "Panama Papers")',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
            ),
            onChanged: (value) => setState(() {}),
            onSubmitted: (value) => _startRabbitHole(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading || _searchController.text.trim().isEmpty
                  ? null
                  : _startRabbitHole,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.explore, size: 24),
              label: Text(
                _isLoading ? 'Erkundet Ebenen...' : '🕳️ KANINCHENBAU STARTEN',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          
          // 🆕 ABBRUCH-BUTTON (nur sichtbar während Recherche)
          if (_isLoading) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _cancelRabbitHole,
                icon: const Icon(Icons.cancel, color: Colors.red),
                label: const Text(
                  '🛑 RECHERCHE ABBRECHEN',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Colors.red, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                'Konfiguration: ${_getConfigLabel(_selectedConfig)}',
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

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: 13,
                color: Colors.red[900],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => setState(() => _errorMessage = null),
            color: Colors.red[700],
          ),
        ],
      ),
    );
  }

  Widget _buildEventLog() {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.stream, color: Colors.green[400], size: 16),
              const SizedBox(width: 6),
              Text(
                'LIVE-LOG',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[400],
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _events.length,
              itemBuilder: (context, index) {
                final event = _events[_events.length - 1 - index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    _formatEvent(event),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green[300],
                      fontFamily: 'monospace',
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (_currentAnalysis == null && !_isLoading) {
      return _buildEmptyState();
    }

    if (_isLoading && _currentAnalysis == null) {
      return _buildLoadingState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16),
      child: RabbitHoleVisualizationCard(
        analysis: _currentAnalysis!,
        onRefresh: () => _startRabbitHole(),
        onNodeTap: (node) => _showNodeDetails(node),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.explore_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Bereit für Tiefenrecherche',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Gib ein Thema ein und starte den Kaninchenbau.\n'
              'Das System erkundet automatisch alle 6 Ebenen.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildLevelOverview(),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple[700]!),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Erkunde Kaninchenbau...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Automatische Tiefenrecherche läuft',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelOverview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'EBENEN-ÜBERSICHT',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          ...RabbitHoleLevel.values.map((level) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: level.color,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${level.depth}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(level.icon, size: 16, color: level.color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    level.label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  String _getConfigLabel(RabbitHoleConfig config) {
    if (config.maxDepth == 4) return 'Schnell (4 Ebenen)';
    if (config.delayBetweenLevels.inSeconds > 2) return 'Tief (6 Ebenen + Delay)';
    return 'Standard (6 Ebenen)';
  }

  String _formatEvent(RabbitHoleEvent event) {
    final time = '${event.timestamp.hour.toString().padLeft(2, '0')}:'
        '${event.timestamp.minute.toString().padLeft(2, '0')}:'
        '${event.timestamp.second.toString().padLeft(2, '0')}';

    if (event is RabbitHoleStarted) {
      return '[$time] 🚀 Start: ${event.topic}';
    } else if (event is RabbitHoleLevelCompleted) {
      return '[$time] ✅ Ebene ${event.level.depth} abgeschlossen: ${event.node.title}';
    } else if (event is RabbitHoleCompleted) {
      return '[$time] 🎉 Kaninchenbau abgeschlossen!';
    } else if (event is RabbitHoleError) {
      return '[$time] ❌ Fehler: ${event.message}';
    }
    return '[$time] Event: ${event.runtimeType}';
  }

  Future<void> _startRabbitHole() async {
    final topic = _searchController.text.trim();
    if (topic.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _events.clear();
      _currentAnalysis = null;
    });

    try {
      // Starte Kaninchenbau mit echten Backend-Daten
      final analysis = await _service.startRabbitHole(
        topic: topic,
        config: _selectedConfig,
        onEvent: (event) {
          setState(() {
            _events.add(event);
            
            // Update Analysis während Erkundung
            if (event is RabbitHoleLevelCompleted) {
              if (_currentAnalysis == null) {
                _currentAnalysis = RabbitHoleAnalysis(
                  topic: topic,
                  nodes: [event.node],
                  status: RabbitHoleStatus.exploring,
                  startTime: DateTime.now(),
                  maxDepth: _selectedConfig.maxDepth,
                );
              } else {
                _currentAnalysis = RabbitHoleAnalysis(
                  topic: _currentAnalysis!.topic,
                  nodes: [..._currentAnalysis!.nodes, event.node],
                  status: RabbitHoleStatus.exploring,
                  startTime: _currentAnalysis!.startTime,
                  maxDepth: _currentAnalysis!.maxDepth,
                );
              }
            }
          });
        },
      );

      setState(() {
        _currentAnalysis = analysis;
        _isLoading = false;
      });

      // Zeige Success-Snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Kaninchenbau abgeschlossen: ${analysis.currentDepth} Ebenen, '
              '${analysis.totalSources} Quellen',
            ),
            backgroundColor: Colors.green[700],
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Fehler beim Starten des Kaninchenbaus: $e';
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Fehler: $e'),
            backgroundColor: Colors.red[700],
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _showNodeDetails(RabbitHoleNode node) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: node.level.color,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(node.level.icon, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          node.level.label,
                          style: TextStyle(
                            fontSize: 12,
                            color: node.level.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          node.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getTrustScoreColor(node.trustScore),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${node.trustScore}/100',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Content
              const Text(
                'INHALT',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                node.content,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  height: 1.5,
                ),
              ),
              
              if (node.keyFindings.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  'HAUPTERKENNTNISSE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                ...node.keyFindings.map((finding) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: node.level.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          finding,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
              
              if (node.sources.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  'QUELLEN',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                ...node.sources.map((source) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '• $source',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                )),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getTrustScoreColor(int score) {
    if (score >= 75) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }
}
