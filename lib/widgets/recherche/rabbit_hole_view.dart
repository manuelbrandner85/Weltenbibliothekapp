import 'package:flutter/material.dart';
import '../../models/recherche_view_state.dart';

/// 🐰🕳️ RABBIT HOLE VIEW WIDGET
/// 
/// Visualisiert eine mehrstufige "Rabbit Hole" Recherche mit Ebenen-System.
/// 
/// Features:
/// - Layer-Karten mit Ebenen-Nummer und Namen
/// - Depth Indicator (0-1 → 0-100%)
/// - Expandierbarer Layer mit Details
/// - Sources pro Layer als Chips
/// - Connections (Verbindungen) Liste
/// - Layer-Navigation (Previous/Next)
/// - Progress Bar für Tiefe
/// - Empty State Handling
/// - Material 3 Design mit Animationen
/// 
/// Verwendung:
/// ```dart
/// RabbitHoleView(
///   layers: result.rabbitLayers,
///   onSourceTap: (url) => launch(url),
/// )
/// ```

class RabbitHoleView extends StatefulWidget {
  final List<RabbitLayer> layers;
  final Function(String)? onSourceTap;

  const RabbitHoleView({
    super.key,
    required this.layers,
    this.onSourceTap,
  });

  @override
  State<RabbitHoleView> createState() => _RabbitHoleViewState();
}

class _RabbitHoleViewState extends State<RabbitHoleView> {
  final Set<int> _expandedIndices = {};
  int _currentLayerIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.layers.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overall Depth Indicator
        _buildOverallDepthIndicator(context),
        const SizedBox(height: 16),

        // Layer Navigation (wenn >1 Layer)
        if (widget.layers.length > 1) ...[
          _buildLayerNavigation(context),
          const SizedBox(height: 16),
        ],

        // Layer Cards
        ..._buildLayerCards(context),
      ],
    );
  }

  // Overall Depth Indicator (Gesamttiefe)
  Widget _buildOverallDepthIndicator(BuildContext context) {
    final theme = Theme.of(context);
    final maxDepth = widget.layers.isEmpty 
        ? 0.0 
        : widget.layers.map((l) => l.depth).reduce((a, b) => a > b ? a : b);
    final depthPercent = (maxDepth * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor.withValues(alpha: 0.1),
            theme.primaryColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology,
                color: theme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '🐰 Rabbit Hole Tiefe',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: theme.primaryColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$depthPercent%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: maxDepth,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(theme.primaryColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.layers.length} Ebene(n) erkundet',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // Layer Navigation
  Widget _buildLayerNavigation(BuildContext context) {
    final theme = Theme.of(context);
    final canGoPrevious = _currentLayerIndex > 0;
    final canGoNext = _currentLayerIndex < widget.layers.length - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Previous Button
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 18),
            onPressed: canGoPrevious
                ? () {
                    setState(() {
                      _currentLayerIndex--;
                    });
                  }
                : null,
            color: canGoPrevious ? theme.primaryColor : Colors.grey[400],
            tooltip: 'Vorherige Ebene',
          ),

          // Current Layer Info
          Expanded(
            child: Column(
              children: [
                Text(
                  'Ebene ${_currentLayerIndex + 1} von ${widget.layers.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.layers[_currentLayerIndex].layerName,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Next Button
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 18),
            onPressed: canGoNext
                ? () {
                    setState(() {
                      _currentLayerIndex++;
                    });
                  }
                : null,
            color: canGoNext ? theme.primaryColor : Colors.grey[400],
            tooltip: 'Nächste Ebene',
          ),
        ],
      ),
    );
  }

  // Layer Cards
  List<Widget> _buildLayerCards(BuildContext context) {
    // Zeige entweder nur current layer (bei Navigation) oder alle
    final layersToShow = widget.layers.length > 1
        ? [widget.layers[_currentLayerIndex]]
        : widget.layers;

    return layersToShow.asMap().entries.map((entry) {
      final actualIndex = widget.layers.length > 1 
          ? _currentLayerIndex 
          : entry.key;
      final layer = entry.value;
      final isExpanded = _expandedIndices.contains(actualIndex);

      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: _buildLayerCard(
          context,
          layer: layer,
          index: actualIndex,
          isExpanded: isExpanded,
        ),
      );
    }).toList();
  }

  Widget _buildLayerCard(
    BuildContext context, {
    required RabbitLayer layer,
    required int index,
    required bool isExpanded,
  }) {
    final depthPercent = (layer.depth * 100).round();
    final depthColor = _getDepthColor(layer.depth);

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            depthColor.withValues(alpha: 0.18),
            depthColor.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: depthColor.withValues(alpha: 0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: depthColor.withValues(alpha: 0.25),
            blurRadius: 18,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            if (isExpanded) {
              _expandedIndices.remove(index);
            } else {
              _expandedIndices.add(index);
            }
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header mit Gradient
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    depthColor.withValues(alpha: 0.2),
                    depthColor.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Layer Number + Name
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: depthColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${layer.layerNumber}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          layer.layerName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Depth Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: depthColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$depthPercent%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Depth Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: layer.depth,
                      minHeight: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.5),
                      valueColor: AlwaysStoppedAnimation(depthColor),
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description (immer sichtbar, aber gekürzt wenn collapsed)
                  Text(
                    layer.description,
                    maxLines: isExpanded ? null : 2,
                    overflow: isExpanded ? null : TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),

                  // Expandierte Details
                  if (isExpanded) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Sources
                    if (layer.sources.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(Icons.link, size: 16, color: depthColor),
                          const SizedBox(width: 6),
                          Text(
                            'Quellen (${layer.sources.length}):',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: layer.sources.map((source) {
                          final displayText = source.title.length > 25
                              ? '${source.title.substring(0, 22)}...'
                              : source.title;
                          return ActionChip(
                            label: Text(
                              displayText,
                              style: const TextStyle(fontSize: 11),
                            ),
                            avatar: Icon(
                              Icons.article,
                              size: 14,
                              color: depthColor,
                            ),
                            onPressed: widget.onSourceTap != null
                                ? () => widget.onSourceTap!(source.url)
                                : null,
                            backgroundColor: depthColor.withValues(alpha: 0.1),
                            side: BorderSide(
                              color: depthColor.withValues(alpha: 0.3),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Connections
                    if (layer.connections.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(Icons.hub, size: 16, color: depthColor),
                          const SizedBox(width: 6),
                          Text(
                            'Verbindungen (${layer.connections.length}):',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...layer.connections.asMap().entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.arrow_right,
                                size: 18,
                                color: depthColor,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  entry.value,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],

                  // Expand/Collapse Indikator
                  const SizedBox(height: 8),
                  Center(
                    child: Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.landscape,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Kein Rabbit Hole verfügbar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Diese Recherche enthält keine mehrstufige Analyse.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getDepthColor(double depth) {
    if (depth < 0.3) {
      return Colors.green; // Oberflächlich
    } else if (depth < 0.6) {
      return Colors.orange; // Mittel
    } else {
      return Colors.red; // Tief
    }
  }
}
