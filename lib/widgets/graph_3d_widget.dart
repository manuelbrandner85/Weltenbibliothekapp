import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 3D-Visualisierungs-Widget für Narrative-Netzwerk
/// 
/// Zeigt Narrative als interaktive 3D-Nodes mit Verbindungen
class Graph3DWidget extends StatefulWidget {
  final Map<String, dynamic> graphData;
  final Function(String narrativeId)? onNodeTap;

  const Graph3DWidget({
    super.key,
    required this.graphData,
    this.onNodeTap,
  });

  @override
  State<Graph3DWidget> createState() => _Graph3DWidgetState();
}

class _Graph3DWidgetState extends State<Graph3DWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  double _rotationX = 0.3;
  double _rotationY = 0.0;
  double _zoom = 1.0;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.graphData['nodes'] == null) {
      return const Center(
        child: Text('Keine Graph-Daten verfügbar'),
      );
    }

    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.cyan.withValues(alpha: 0.3)),
      ),
      child: Stack(
        children: [
          // 3D Graph Canvas
          GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _rotationY += details.delta.dx * 0.01;
                _rotationX -= details.delta.dy * 0.01;
                _rotationX = _rotationX.clamp(-math.pi / 2, math.pi / 2);
              });
            },
            child: AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: Graph3DPainter(
                    graphData: widget.graphData,
                    rotationX: _rotationX,
                    rotationY: _rotationY + _rotationController.value * math.pi * 2,
                    zoom: _zoom,
                    onNodeTap: widget.onNodeTap,
                  ),
                  child: Container(),
                );
              },
            ),
          ),

          // Controls
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
                  }),
                  'Reset',
                ),
              ],
            ),
          ),

          // Info
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
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.touch_app, color: Colors.cyan, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Ziehen zum Drehen • Tippen für Details',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(IconData icon, VoidCallback onPressed, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.cyan.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.cyan.withValues(alpha: 0.3)),
        ),
        child: IconButton(
          icon: Icon(icon, color: Colors.cyan),
          onPressed: onPressed,
          iconSize: 20,
        ),
      ),
    );
  }
}

/// Custom Painter für 3D Graph
class Graph3DPainter extends CustomPainter {
  final Map<String, dynamic> graphData;
  final double rotationX;
  final double rotationY;
  final double zoom;
  final Function(String narrativeId)? onNodeTap;

  Graph3DPainter({
    required this.graphData,
    required this.rotationX,
    required this.rotationY,
    required this.zoom,
    this.onNodeTap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    final nodes = graphData['nodes'] as List;
    final edges = graphData['edges'] as List? ?? [];

    // Projizierte Nodes berechnen
    final projectedNodes = nodes.map((node) {
      final pos = node['position'] as Map<String, dynamic>;
      final x = (pos['x'] as num).toDouble();
      final y = (pos['y'] as num).toDouble();
      final z = (pos['z'] as num).toDouble();

      // 3D Rotation
      final rotatedPoint = _rotate3D(x, y, z, rotationX, rotationY);

      // Perspektive Projektion
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

    // Sortiere nach Z (hinten nach vorne)
    projectedNodes.sort((a, b) => (a['z'] as double).compareTo(b['z'] as double));

    // Zeichne Edges (Verbindungen)
    for (final edge in edges) {
      final fromNode = projectedNodes.firstWhere((n) => n['id'] == edge['from']);
      final toNode = projectedNodes.firstWhere((n) => n['id'] == edge['to']);

      final paint = Paint()
        ..color = Colors.cyan.withValues(alpha: 0.3)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(fromNode['x'] as double, fromNode['y'] as double),
        Offset(toNode['x'] as double, toNode['y'] as double),
        paint,
      );
    }

    // Zeichne Nodes
    for (final node in projectedNodes) {
      final x = node['x'] as double;
      final y = node['y'] as double;
      final scale = node['scale'] as double;
      final color = node['color'] as Color;
      final isMain = node['type'] == 'main';

      // Node Circle
      final radius = (isMain ? 30.0 : 20.0) * scale;
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), radius, paint);

      // Border
      final borderPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..strokeWidth = 2.0 * scale
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(Offset(x, y), radius, borderPaint);

      // Label (nur bei großen Nodes)
      if (scale > 0.7) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: _truncateText(node['title'] as String, 15),
            style: TextStyle(
              color: Colors.white,
              fontSize: 10 * scale,
              fontWeight: isMain ? FontWeight.bold : FontWeight.normal,
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
    // Rotation um X-Achse
    final cosX = math.cos(angleX);
    final sinX = math.sin(angleX);
    final y1 = y * cosX - z * sinX;
    final z1 = y * sinX + z * cosX;

    // Rotation um Y-Achse
    final cosY = math.cos(angleY);
    final sinY = math.sin(angleY);
    final x2 = x * cosY + z1 * sinY;
    final z2 = -x * sinY + z1 * cosY;

    return {'x': x2, 'y': y1, 'z': z2};
  }

  Color _parseColor(String hexColor) {
    return Color(int.parse(hexColor.substring(1), radix: 16) + 0xFF000000);
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  @override
  bool shouldRepaint(Graph3DPainter oldDelegate) {
    return oldDelegate.rotationX != rotationX ||
        oldDelegate.rotationY != rotationY ||
        oldDelegate.zoom != zoom;
  }
}
