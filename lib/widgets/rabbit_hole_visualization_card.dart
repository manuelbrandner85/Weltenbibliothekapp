/// WELTENBIBLIOTHEK v5.13 – KANINCHENBAU UI-WIDGET
/// 
/// Visualisierung der automatischen Tiefenrecherche
library;

import 'package:flutter/material.dart';
import '../models/rabbit_hole_models.dart';

/// Kaninchenbau-Visualisierung Card
class RabbitHoleVisualizationCard extends StatefulWidget {
  final RabbitHoleAnalysis analysis;
  final VoidCallback? onRefresh;
  final void Function(RabbitHoleNode)? onNodeTap;

  const RabbitHoleVisualizationCard({
    super.key,
    required this.analysis,
    this.onRefresh,
    this.onNodeTap,
  });

  @override
  State<RabbitHoleVisualizationCard> createState() => _RabbitHoleVisualizationCardState();
}

class _RabbitHoleVisualizationCardState extends State<RabbitHoleVisualizationCard> {
  int _currentPageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalLevels = RabbitHoleLevel.values.length;
    final currentLevel = _currentPageIndex + 1;
    final levelData = RabbitHoleLevel.values[_currentPageIndex];
    
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      color: Colors.grey[850],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER mit Ebenen-Fortschritt
          _buildHeader(context, currentLevel, totalLevels, levelData),
          
          const Divider(height: 1),
          
          // 🆕 NAVIGATION-BUTTONS (Zurück/Vor)
          _buildNavigationBar(currentLevel, totalLevels),
          
          const Divider(height: 1),
          
          // PAGE VIEW (eine Ebene pro Seite)
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPageIndex = index;
                });
              },
              itemCount: totalLevels,
              itemBuilder: (context, index) {
                final level = RabbitHoleLevel.values[index];
                final nodes = widget.analysis.getNodesAtLevel(level);
                final isReached = level.depth <= widget.analysis.currentDepth;
                final isActive = level.depth == widget.analysis.currentDepth;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildLevelCard(
                    context,
                    level: level,
                    nodes: nodes,
                    isReached: isReached,
                    isActive: isActive,
                  ),
                );
              },
            ),
          ),
          
          const Divider(height: 1),
          
          // STATISTIKEN
          _buildStatistics(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int currentLevel, int totalLevels, RabbitHoleLevel levelData) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple[700]!, Colors.deepPurple[900]!],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.explore, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🆕 EBENEN-FORTSCHRITT
                    Text(
                      '🕳️ Kaninchenbau – Ebene $currentLevel von $totalLevels',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // 🆕 THEMA DER EBENE
                    Row(
                      children: [
                        Icon(levelData.icon, color: levelData.color, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Thema: ${levelData.label}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Original-Thema
                    Text(
                      'Recherche: ${widget.analysis.topic}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.onRefresh != null)
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: widget.onRefresh,
                  tooltip: 'Recherche neu starten',
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatusBadge(widget.analysis.status),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Tiefe: ${widget.analysis.currentDepth}/${widget.analysis.maxDepth}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${widget.analysis.totalSources} Quellen',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 🆕 NAVIGATION-BAR (Zurück/Vor-Buttons)
  Widget _buildNavigationBar(int currentLevel, int totalLevels) {
    final canGoBack = _currentPageIndex > 0;
    final canGoForward = _currentPageIndex < totalLevels - 1;
    
    return Container(
      color: Colors.grey[800],
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ZURÜCK-BUTTON (immer sichtbar)
          ElevatedButton.icon(
            onPressed: canGoBack
                ? () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                : null,
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('Zurück'),
            style: ElevatedButton.styleFrom(
              backgroundColor: canGoBack ? Colors.deepPurple[700] : Colors.grey[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
          
          // EBENEN-INDIKATOR (Dots)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(totalLevels, (index) {
              final isCurrentLevel = index == _currentPageIndex;
              final isCompleted = index < widget.analysis.currentDepth;
              
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isCurrentLevel ? 12 : 8,
                height: isCurrentLevel ? 12 : 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? Colors.green[400]
                      : isCurrentLevel
                          ? Colors.deepPurple[400]
                          : Colors.grey[600],
                ),
              );
            }),
          ),
          
          // VOR-BUTTON (immer sichtbar)
          ElevatedButton.icon(
            onPressed: canGoForward
                ? () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                : null,
            icon: const Icon(Icons.arrow_forward, size: 16),
            label: const Text('Weiter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: canGoForward ? Colors.deepPurple[700] : Colors.grey[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(RabbitHoleStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == RabbitHoleStatus.exploring)
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          else
            Icon(
              status == RabbitHoleStatus.completed
                  ? Icons.check_circle
                  : status == RabbitHoleStatus.error
                      ? Icons.error
                      : Icons.info,
              color: Colors.white,
              size: 14,
            ),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCard(
    BuildContext context, {
    required RabbitHoleLevel level,
    required List<RabbitHoleNode> nodes,
    required bool isReached,
    required bool isActive,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: isReached ? level.color : Colors.grey[300]!,
          width: isActive ? 3 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: isReached ? level.color.withValues(alpha: 0.05) : Colors.grey[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEVEL HEADER
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isReached 
                  ? level.color.withValues(alpha: 0.1) 
                  : Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(11),
                topRight: Radius.circular(11),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isReached ? level.color : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${level.depth}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            level.icon,
                            color: isReached ? level.color : Colors.grey,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              level.label.toUpperCase(),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isReached ? level.color : Colors.grey,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isActive)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (isReached)
                  Icon(Icons.check_circle, color: level.color, size: 20),
              ],
            ),
          ),
          
          // NODE CONTENT
          if (nodes.isNotEmpty)
            ...nodes.map((node) => InkWell(
              onTap: () => widget.onNodeTap?.call(node),
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            node.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        
                        // 🆕 FALLBACK-KENNZEICHNUNG
                        if (node.isFallback) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange[700],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'KI',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                        
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getTrustScoreColor(node.trustScore),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${node.trustScore}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (node.keyFindings.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ...node.keyFindings.take(3).map((finding) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: level.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                finding,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                    if (node.sources.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${node.sources.length} Quellen',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ))
          else if (!isReached)
            Container(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Noch nicht erkundet',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'STATISTIKEN',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Ebenen',
                '${widget.analysis.currentDepth}/${widget.analysis.maxDepth}',
                Icons.layers,
                Colors.blue,
              ),
              _buildStatItem(
                'Quellen',
                '${widget.analysis.totalSources}',
                Icons.source,
                Colors.green,
              ),
              _buildStatItem(
                'Trust-Score',
                widget.analysis.averageTrustScore.toStringAsFixed(0),
                Icons.verified,
                _getTrustScoreColor(widget.analysis.averageTrustScore.toInt()),
              ),
              _buildStatItem(
                'Dauer',
                _formatDuration(widget.analysis.duration),
                Icons.timer,
                Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Color _getTrustScoreColor(int score) {
    if (score >= 75) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    }
    return '${duration.inSeconds}s';
  }
}
