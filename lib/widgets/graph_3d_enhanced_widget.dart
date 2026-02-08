import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 🎨 ENHANCED 3D-Graph Widget mit Node-Click, Filter & Search
/// 
/// Features:
/// - ✅ Node-Click Detection mit Details-Popup
/// - ✅ Kategorie-Filter System
/// - ✅ Search-Highlight mit visueller Hervorhebung
/// - ✅ 3D Rotation & Zoom
/// - ✅ Performance-optimiert
class Graph3DEnhancedWidget extends StatefulWidget {
  final Map<String, dynamic> graphData;
  final Function(String narrativeId)? onNodeTap;
  final List<String>? availableCategories; // 🆕 Für Filter

  const Graph3DEnhancedWidget({
    super.key,
    required this.graphData,
    this.onNodeTap,
    this.availableCategories,
  });

  @override
  State<Graph3DEnhancedWidget> createState() => _Graph3DEnhancedWidgetState();
}

class _Graph3DEnhancedWidgetState extends State<Graph3DEnhancedWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  double _rotationX = 0.3;
  double _rotationY = 0.0;
  double _zoom = 1.0;
  
  // 🆕 FEATURE: Search & Filter
  String _searchQuery = '';
  Set<String> _selectedCategories = {};
  String? _highlightedNodeId;
  
  // 🆕 FEATURE: Node Selection
  String? _selectedNodeId;
  Offset? _selectedNodePosition;
  
  // Filter Panel State
  bool _showFilterPanel = false;
  bool _showSearchPanel = false;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    
    // Initialisiere alle Kategorien als ausgewählt
    if (widget.availableCategories != null) {
      _selectedCategories = Set.from(widget.availableCategories!);
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  // 🆕 Filtere Nodes nach Kategorien und Search
  List<dynamic> _getFilteredNodes() {
    final nodes = widget.graphData['nodes'] as List? ?? [];
    
    return nodes.where((node) {
      // Kategorie-Filter
      if (_selectedCategories.isNotEmpty) {
        final nodeCategory = node['category'] as String?;
        if (nodeCategory != null && !_selectedCategories.contains(nodeCategory)) {
          return false;
        }
      }
      
      // Search-Filter
      if (_searchQuery.isNotEmpty) {
        final title = (node['title'] as String? ?? '').toLowerCase();
        final description = (node['description'] as String? ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();
        return title.contains(query) || description.contains(query);
      }
      
      return true;
    }).toList();
  }

  // 🆕 Node-Click Detection
  void _handleTapUp(TapUpDetails details, Size size) {
    final filteredNodes = _getFilteredNodes();
    if (filteredNodes.isEmpty) return;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final tapX = details.localPosition.dx;
    final tapY = details.localPosition.dy;

    // Finde geklickten Node
    for (final node in filteredNodes) {
      final pos = node['position'] as Map<String, dynamic>;
      final x = (pos['x'] as num).toDouble();
      final y = (pos['y'] as num).toDouble();
      final z = (pos['z'] as num).toDouble();

      final rotatedPoint = _rotate3D(x, y, z, _rotationX, 
          _rotationY + _rotationController.value * math.pi * 2);
      final scale = _zoom * 200 / (200 + rotatedPoint['z']!);
      final screenX = centerX + rotatedPoint['x']! * scale;
      final screenY = centerY + rotatedPoint['y']! * scale;

      final isMain = node['type'] == 'main';
      final radius = (isMain ? 30.0 : 20.0) * scale;

      final distance = math.sqrt(
        math.pow(tapX - screenX, 2) + math.pow(tapY - screenY, 2),
      );

      if (distance <= radius) {
        setState(() {
          _selectedNodeId = node['id'] as String;
          _selectedNodePosition = Offset(screenX, screenY);
          _highlightedNodeId = node['id'] as String;
        });
        
        // Callback für externe Aktionen
        if (widget.onNodeTap != null) {
          widget.onNodeTap!(node['id'] as String);
        }
        
        // Zeige Details-Dialog
        _showNodeDetails(node);
        break;
      }
    }
  }

  // 🆕 Details-Dialog für geklickten Node
  void _showNodeDetails(dynamic node) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _parseColor(node['color'] as String),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      node['title'] as String? ?? 'Unbekannt',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Kategorie Badge
              if (node['category'] != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.cyan.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.cyan.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.category, color: Colors.cyan, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        node['category'] as String,
                        style: const TextStyle(color: Colors.cyan, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Beschreibung
              if (node['description'] != null)
                Text(
                  node['description'] as String,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              
              const SizedBox(height: 16),
              
              // Stats
              Row(
                children: [
                  _buildStatChip(
                    Icons.visibility,
                    '${node['views'] ?? 0}',
                    'Views',
                  ),
                  const SizedBox(width: 12),
                  _buildStatChip(
                    Icons.favorite,
                    '${node['likes'] ?? 0}',
                    'Likes',
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    if (widget.onNodeTap != null) {
                      widget.onNodeTap!(node['id'] as String);
                    }
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Details öffnen'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    foregroundColor: Colors.black,
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

  Widget _buildStatChip(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredNodes = _getFilteredNodes();
    
    if (filteredNodes.isEmpty) {
      return Container(
        height: 500,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.cyan.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                color: Colors.white38,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Keine Nodes gefunden',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _selectedCategories = Set.from(widget.availableCategories ?? []);
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Filter zurücksetzen'),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 500,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.cyan.withValues(alpha: 0.3)),
      ),
      child: Stack(
        children: [
          // 3D Graph Canvas mit Tap Detection
          GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _rotationY += details.delta.dx * 0.01;
                _rotationX -= details.delta.dy * 0.01;
                _rotationX = _rotationX.clamp(-math.pi / 2, math.pi / 2);
              });
            },
            onTapUp: (details) {
              final renderBox = context.findRenderObject() as RenderBox?;
              if (renderBox != null) {
                _handleTapUp(details, renderBox.size);
              }
            },
            child: AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: Graph3DEnhancedPainter(
                    nodes: filteredNodes,
                    edges: widget.graphData['edges'] as List? ?? [],
                    rotationX: _rotationX,
                    rotationY: _rotationY + _rotationController.value * math.pi * 2,
                    zoom: _zoom,
                    highlightedNodeId: _highlightedNodeId,
                    selectedNodeId: _selectedNodeId,
                  ),
                  child: Container(),
                );
              },
            ),
          ),

          // 🆕 Search Panel
          if (_showSearchPanel)
            Positioned(
              top: 60,
              left: 16,
              right: 80,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.cyan.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      autofocus: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Node suchen...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        prefixIcon: const Icon(Icons.search, color: Colors.cyan),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.white54),
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                    _highlightedNodeId = null;
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                          _highlightedNodeId = null;
                        });
                      },
                    ),
                    if (_searchQuery.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${filteredNodes.length} Ergebnis(se)',
                          style: const TextStyle(color: Colors.cyan, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // 🆕 Filter Panel
          if (_showFilterPanel && widget.availableCategories != null)
            Positioned(
              top: 60,
              right: 16,
              child: Container(
                width: 200,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.cyan.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.filter_list, color: Colors.cyan, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Kategorien',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...widget.availableCategories!.map((category) {
                      final isSelected = _selectedCategories.contains(category);
                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedCategories.add(category);
                            } else {
                              _selectedCategories.remove(category);
                            }
                          });
                        },
                        title: Text(
                          category,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: Colors.cyan,
                      );
                    }),
                  ],
                ),
              ),
            ),

          // Top Controls
          Positioned(
            top: 16,
            left: 16,
            child: Row(
              children: [
                _buildControlButton(
                  _showSearchPanel ? Icons.search_off : Icons.search,
                  () => setState(() => _showSearchPanel = !_showSearchPanel),
                  'Suche',
                  isActive: _showSearchPanel,
                ),
                const SizedBox(width: 8),
                if (widget.availableCategories != null)
                  _buildControlButton(
                    Icons.filter_list,
                    () => setState(() => _showFilterPanel = !_showFilterPanel),
                    'Filter',
                    isActive: _showFilterPanel,
                    badge: _selectedCategories.length < (widget.availableCategories?.length ?? 0)
                        ? '${_selectedCategories.length}'
                        : null,
                  ),
              ],
            ),
          ),

          // Right Controls (Zoom)
          Positioned(
            top: 16,
            right: 16,
            child: Column(
              children: [
                _buildControlButton(
                  Icons.add,
                  () => setState(() => _zoom = (_zoom * 1.2).clamp(0.5, 3.0)),
                  'Zoom In',
                ),
                const SizedBox(height: 8),
                _buildControlButton(
                  Icons.remove,
                  () => setState(() => _zoom = (_zoom / 1.2).clamp(0.5, 3.0)),
                  'Zoom Out',
                ),
                const SizedBox(height: 8),
                _buildControlButton(
                  Icons.refresh,
                  () => setState(() {
                    _rotationX = 0.3;
                    _rotationY = 0.0;
                    _zoom = 1.0;
                    _selectedNodeId = null;
                    _highlightedNodeId = null;
                  }),
                  'Reset',
                ),
              ],
            ),
          ),

          // Bottom Info
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.cyan.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.touch_app, color: Colors.cyan, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${filteredNodes.length} Nodes • Ziehen zum Drehen • Tippen für Details',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(
    IconData icon,
    VoidCallback onPressed,
    String tooltip, {
    bool isActive = false,
    String? badge,
  }) {
    return Tooltip(
      message: tooltip,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.cyan.withValues(alpha: 0.4)
                  : Colors.cyan.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isActive
                    ? Colors.cyan.withValues(alpha: 0.6)
                    : Colors.cyan.withValues(alpha: 0.3),
              ),
            ),
            child: IconButton(
              icon: Icon(icon, color: Colors.cyan),
              onPressed: onPressed,
              iconSize: 20,
            ),
          ),
          if (badge != null)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Center(
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Map<String, double> _rotate3D(double x, double y, double z, double angleX, double angleY) {
    final cosX = math.cos(angleX);
    final sinX = math.sin(angleX);
    final y1 = y * cosX - z * sinX;
    final z1 = y * sinX + z * cosX;

    final cosY = math.cos(angleY);
    final sinY = math.sin(angleY);
    final x2 = x * cosY + z1 * sinY;
    final z2 = -x * sinY + z1 * cosY;

    return {'x': x2, 'y': y1, 'z': z2};
  }

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.substring(1), radix: 16) + 0xFF000000);
    } catch (e) {
      return Colors.cyan;
    }
  }
}

/// Enhanced Custom Painter mit Highlight-Support
class Graph3DEnhancedPainter extends CustomPainter {
  final List<dynamic> nodes;
  final List<dynamic> edges;
  final double rotationX;
  final double rotationY;
  final double zoom;
  final String? highlightedNodeId;
  final String? selectedNodeId;

  Graph3DEnhancedPainter({
    required this.nodes,
    required this.edges,
    required this.rotationX,
    required this.rotationY,
    required this.zoom,
    this.highlightedNodeId,
    this.selectedNodeId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Projizierte Nodes berechnen
    final projectedNodes = nodes.map((node) {
      final pos = node['position'] as Map<String, dynamic>;
      final x = (pos['x'] as num).toDouble();
      final y = (pos['y'] as num).toDouble();
      final z = (pos['z'] as num).toDouble();

      final rotatedPoint = _rotate3D(x, y, z, rotationX, rotationY);
      final scale = zoom * 200 / (200 + rotatedPoint['z']!);
      final screenX = centerX + rotatedPoint['x']! * scale;
      final screenY = centerY + rotatedPoint['y']! * scale;

      return {
        'id': node['id'],
        'title': node['title'],
        'type': node['type'],
        'color': _parseColor(node['color'] as String),
        'x': screenX,
        'y': screenY,
        'z': rotatedPoint['z'],
        'scale': scale,
      };
    }).toList();

    projectedNodes.sort((a, b) => (a['z'] as double).compareTo(b['z'] as double));

    // Zeichne Edges
    for (final edge in edges) {
      try {
        final fromNode = projectedNodes.firstWhere((n) => n['id'] == edge['from']);
        final toNode = projectedNodes.firstWhere((n) => n['id'] == edge['to']);

        final isHighlighted = (fromNode['id'] == selectedNodeId || toNode['id'] == selectedNodeId);
        
        final paint = Paint()
          ..color = isHighlighted
              ? Colors.cyan.withValues(alpha: 0.6)
              : Colors.cyan.withValues(alpha: 0.3)
          ..strokeWidth = isHighlighted ? 3.0 : 2.0
          ..style = PaintingStyle.stroke;

        canvas.drawLine(
          Offset(fromNode['x'] as double, fromNode['y'] as double),
          Offset(toNode['x'] as double, toNode['y'] as double),
          paint,
        );
      } catch (e) {
        // Node nicht gefunden (gefiltert)
      }
    }

    // Zeichne Nodes
    for (final node in projectedNodes) {
      final x = node['x'] as double;
      final y = node['y'] as double;
      final scale = node['scale'] as double;
      final color = node['color'] as Color;
      final isMain = node['type'] == 'main';
      final isHighlighted = node['id'] == highlightedNodeId;
      final isSelected = node['id'] == selectedNodeId;

      // 🆕 Highlight Glow Effect
      if (isHighlighted || isSelected) {
        final glowRadius = (isMain ? 40.0 : 30.0) * scale;
        final glowPaint = Paint()
          ..color = Colors.cyan.withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
        canvas.drawCircle(Offset(x, y), glowRadius, glowPaint);
      }

      // Node Circle
      final radius = (isMain ? 30.0 : 20.0) * scale;
      final nodePaint = Paint()
        ..color = isSelected
            ? Colors.cyan
            : (isHighlighted ? color.withValues(alpha: 1.0) : color)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), radius, nodePaint);

      // Border
      final borderPaint = Paint()
        ..color = isSelected
            ? Colors.white
            : (isHighlighted
                ? Colors.cyan
                : Colors.white.withValues(alpha: 0.5))
        ..strokeWidth = (isSelected || isHighlighted ? 3.0 : 2.0) * scale
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(Offset(x, y), radius, borderPaint);

      // Label
      if (scale > 0.7 || isHighlighted || isSelected) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: _truncateText(node['title'] as String, 15),
            style: TextStyle(
              color: Colors.white,
              fontSize: (isHighlighted || isSelected ? 12 : 10) * scale,
              fontWeight: (isMain || isSelected) ? FontWeight.bold : FontWeight.normal,
              shadows: isHighlighted || isSelected
                  ? [const Shadow(color: Colors.black, blurRadius: 4)]
                  : null,
            ),
          ),
          textDirection: TextDirection.ltr,
        );

        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, y + radius + 5 * scale),
        );
      }
    }
  }

  Map<String, double> _rotate3D(double x, double y, double z, double angleX, double angleY) {
    final cosX = math.cos(angleX);
    final sinX = math.sin(angleX);
    final y1 = y * cosX - z * sinX;
    final z1 = y * sinX + z * cosX;

    final cosY = math.cos(angleY);
    final sinY = math.sin(angleY);
    final x2 = x * cosY + z1 * sinY;
    final z2 = -x * sinY + z1 * cosY;

    return {'x': x2, 'y': y1, 'z': z2};
  }

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.substring(1), radix: 16) + 0xFF000000);
    } catch (e) {
      return Colors.cyan;
    }
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  @override
  bool shouldRepaint(Graph3DEnhancedPainter oldDelegate) {
    return oldDelegate.rotationX != rotationX ||
        oldDelegate.rotationY != rotationY ||
        oldDelegate.zoom != zoom ||
        oldDelegate.highlightedNodeId != highlightedNodeId ||
        oldDelegate.selectedNodeId != selectedNodeId ||
        oldDelegate.nodes.length != nodes.length;
  }
}
