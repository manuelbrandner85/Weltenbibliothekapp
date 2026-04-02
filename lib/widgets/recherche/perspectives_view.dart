import 'package:flutter/material.dart';
import '../../models/recherche_view_state.dart';

/// 🔮 PERSPECTIVES VIEW WIDGET
/// 
/// Zeigt verschiedene Perspektiven zu einem Recherche-Ergebnis an.
/// 
/// Features:
/// - Perspektiven-Karten mit Typ-Badge (Supporting/Opposing/Neutral/Alternative)
/// - Credibility Score als Sterne-Anzeige (0-10 → 0-5 Sterne)
/// - Expandierbarer Viewpoint (Standpunkt)
/// - Nummerierte Arguments Liste
/// - Supporting Sources als Chips
/// - Typ-spezifische Farben (Grün/Rot/Grau/Blau)
/// - Filter nach Typ (bei >3 Perspektiven)
/// - Empty State Handling
/// - Material 3 Design mit Animationen
/// 
/// Verwendung:
/// ```dart
/// PerspectivesView(
///   perspectives: result.perspectives,
///   onSourceTap: (url) => launch(url),
/// )
/// ```

class PerspectivesView extends StatefulWidget {
  final List<Perspective> perspectives;
  final Function(String)? onSourceTap;

  const PerspectivesView({
    super.key,
    required this.perspectives,
    this.onSourceTap,
  });

  @override
  State<PerspectivesView> createState() => _PerspectivesViewState();
}

class _PerspectivesViewState extends State<PerspectivesView> {
  PerspectiveType? _selectedFilter;
  final Set<int> _expandedIndices = {};

  List<Perspective> get _filteredPerspectives {
    if (_selectedFilter == null) {
      return widget.perspectives;
    }
    return widget.perspectives
        .where((p) => p.type == _selectedFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.perspectives.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.perspectives.length > 3) _buildFilterBar(context),
        if (widget.perspectives.length > 3) const SizedBox(height: 16),
        ..._buildPerspectiveCards(context),
      ],
    );
  }

  // Filter Bar (nur bei >3 Perspektiven)
  Widget _buildFilterBar(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              context,
              label: 'Alle',
              isSelected: _selectedFilter == null,
              onTap: () => setState(() => _selectedFilter = null),
              color: theme.primaryColor,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              context,
              label: 'Supporting',
              isSelected: _selectedFilter == PerspectiveType.supporting,
              onTap: () => setState(() => _selectedFilter = PerspectiveType.supporting),
              color: Colors.green,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              context,
              label: 'Opposing',
              isSelected: _selectedFilter == PerspectiveType.opposing,
              onTap: () => setState(() => _selectedFilter = PerspectiveType.opposing),
              color: Colors.red,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              context,
              label: 'Neutral',
              isSelected: _selectedFilter == PerspectiveType.neutral,
              onTap: () => setState(() => _selectedFilter = PerspectiveType.neutral),
              color: Colors.grey,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              context,
              label: 'Alternative',
              isSelected: _selectedFilter == PerspectiveType.alternative,
              onTap: () => setState(() => _selectedFilter = PerspectiveType.alternative),
              color: Colors.blue,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              context,
              label: 'Controversial',
              isSelected: _selectedFilter == PerspectiveType.controversial,
              onTap: () => setState(() => _selectedFilter = PerspectiveType.controversial),
              color: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: isSelected ? color : Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: isSelected ? 2 : 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[700],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  // Perspektiven-Karten
  List<Widget> _buildPerspectiveCards(BuildContext context) {
    final filtered = _filteredPerspectives;
    
    if (filtered.isEmpty) {
      return [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Text(
              'Keine Perspektiven für diesen Filter',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
        ),
      ];
    }

    return filtered.asMap().entries.map((entry) {
      final index = entry.key;
      final perspective = entry.value;
      final isExpanded = _expandedIndices.contains(index);

      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: _buildPerspectiveCard(
          context,
          perspective: perspective,
          index: index,
          isExpanded: isExpanded,
        ),
      );
    }).toList();
  }

  Widget _buildPerspectiveCard(
    BuildContext context, {
    required Perspective perspective,
    required int index,
    required bool isExpanded,
  }) {
    final typeColor = _getTypeColor(perspective.type);
    final typeLabel = _getTypeLabel(perspective.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            typeColor.withValues(alpha: 0.15),
            typeColor.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: typeColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: typeColor.withValues(alpha: 0.2),
            blurRadius: 15,
            spreadRadius: 1,
            offset: const Offset(0, 6),
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Name + Typ-Badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      perspective.perspectiveName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildTypeBadge(typeLabel, typeColor),
                ],
              ),
              const SizedBox(height: 12),

              // Credibility Score (Sterne)
              _buildCredibilityStars(perspective.credibility),
              const SizedBox(height: 12),

              // Viewpoint (immer sichtbar, aber gekürzt wenn collapsed)
              _buildViewpoint(perspective.viewpoint, isExpanded),

              // Expandierte Details
              if (isExpanded) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                // Arguments
                if (perspective.arguments.isNotEmpty) ...[
                  const Text(
                    '📋 Argumente:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...perspective.arguments.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${entry.key + 1}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: typeColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
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
                  const SizedBox(height: 12),
                ],

                // Supporting Sources
                if (perspective.supportingSources.isNotEmpty) ...[
                  const Text(
                    '🔗 Quellen:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: perspective.supportingSources.map((source) {
                      final displayText = source.title.length > 30 
                          ? '${source.title.substring(0, 27)}...'
                          : source.title;
                      return ActionChip(
                        label: Text(
                          displayText,
                          style: const TextStyle(fontSize: 11),
                        ),
                        avatar: const Icon(Icons.link, size: 14),
                        onPressed: widget.onSourceTap != null
                            ? () => widget.onSourceTap!(source.url)
                            : null,
                        backgroundColor: Colors.grey[100],
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      );
                    }).toList(),
                  ),
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
      ),
    );
  }

  Widget _buildTypeBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildCredibilityStars(double credibility) {
    // Credibility 0-10 → 0-5 Sterne
    final stars = (credibility / 2).clamp(0, 5);
    final fullStars = stars.floor();
    final hasHalfStar = (stars - fullStars) >= 0.5;

    return Row(
      children: [
        const Text(
          'Glaubwürdigkeit: ',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Row(
          children: List.generate(5, (index) {
            if (index < fullStars) {
              return const Icon(Icons.star, size: 16, color: Colors.amber);
            } else if (index == fullStars && hasHalfStar) {
              return const Icon(Icons.star_half, size: 16, color: Colors.amber);
            } else {
              return Icon(Icons.star_border, size: 16, color: Colors.grey[400]);
            }
          }),
        ),
        const SizedBox(width: 4),
        Text(
          '${credibility.toStringAsFixed(1)}/10',
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildViewpoint(String viewpoint, bool isExpanded) {
    final maxLines = isExpanded ? null : 2;
    
    return Text(
      viewpoint,
      maxLines: maxLines,
      overflow: isExpanded ? null : TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 13,
        color: Colors.grey[700],
        height: 1.4,
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
              Icons.visibility_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Keine Perspektiven verfügbar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Diese Recherche enthält keine verschiedenen Perspektiven.',
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

  Color _getTypeColor(PerspectiveType type) {
    switch (type) {
      case PerspectiveType.supporting:
        return Colors.green;
      case PerspectiveType.opposing:
        return Colors.red;
      case PerspectiveType.neutral:
        return Colors.grey;
      case PerspectiveType.alternative:
        return Colors.blue;
      case PerspectiveType.controversial:
        return Colors.orange;
    }
  }

  String _getTypeLabel(PerspectiveType type) {
    switch (type) {
      case PerspectiveType.supporting:
        return 'Supporting';
      case PerspectiveType.opposing:
        return 'Opposing';
      case PerspectiveType.neutral:
        return 'Neutral';
      case PerspectiveType.alternative:
        return 'Alternative';
      case PerspectiveType.controversial:
        return 'Controversial';
    }
  }
}
