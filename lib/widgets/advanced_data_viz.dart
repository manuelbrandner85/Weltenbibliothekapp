import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Advanced Data Visualization Widget für MATERIE-Research
class AdvancedDataViz extends StatelessWidget {
  final int sourceCount;
  final String topicId;

  const AdvancedDataViz({
    super.key,
    required this.sourceCount,
    required this.topicId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0D47A1).withValues(alpha: 0.25),
            const Color(0xFF1565C0).withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2196F3).withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2196F3).withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Network Graph Visualization
          Expanded(
            flex: 2,
            child: CustomPaint(
              painter: NetworkGraphPainter(topicId.hashCode),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Live Chart
          Expanded(
            flex: 3,
            child: CustomPaint(
              painter: LiveChartPainter(topicId.hashCode),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Stats Display
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF4CAF50),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF4CAF50),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'LIVE',
                    style: TextStyle(
                      fontSize: 9,
                      color: Color(0xFF4CAF50),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '$sourceCount',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2196F3),
                  shadows: [
                    Shadow(color: Color(0xFF2196F3), blurRadius: 15),
                  ],
                ),
              ),
              const Text(
                'Quellen',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '+12% ↑',
                  style: TextStyle(
                    fontSize: 9,
                    color: Color(0xFF4CAF50),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Network Graph Painter - Shows connected nodes
class NetworkGraphPainter extends CustomPainter {
  final int seed;

  NetworkGraphPainter(this.seed);

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);
    final nodes = <Offset>[];
    
    // Generate 6 nodes
    for (int i = 0; i < 6; i++) {
      nodes.add(Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      ));
    }
    
    // Draw connections
    final linePaint = Paint()
      ..color = const Color(0xFF2196F3).withValues(alpha: 0.3)
      ..strokeWidth = 1.5;
    
    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        if ((i + j + seed) % 3 == 0) {
          canvas.drawLine(nodes[i], nodes[j], linePaint);
        }
      }
    }
    
    // Draw nodes
    for (final node in nodes) {
      final nodePaint = Paint()
        ..color = const Color(0xFF2196F3)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      
      canvas.drawCircle(node, 4, nodePaint);
      
      // Node ring
      final ringPaint = Paint()
        ..color = const Color(0xFF2196F3).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      
      canvas.drawCircle(node, 6, ringPaint);
    }
  }

  @override
  bool shouldRepaint(NetworkGraphPainter oldDelegate) => false;
}

/// Live Chart Painter - Animated line chart
class LiveChartPainter extends CustomPainter {
  final int seed;

  LiveChartPainter(this.seed);

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);
    final points = <Offset>[];
    final dataPoints = 20;
    
    // Generate data points
    for (int i = 0; i < dataPoints; i++) {
      final x = (i / (dataPoints - 1)) * size.width;
      final baseY = size.height * 0.7;
      final variance = random.nextDouble() * size.height * 0.5;
      final y = baseY - variance;
      points.add(Offset(x, y));
    }
    
    // Draw area under curve
    final areaPath = Path();
    areaPath.moveTo(0, size.height);
    for (final point in points) {
      areaPath.lineTo(point.dx, point.dy);
    }
    areaPath.lineTo(size.width, size.height);
    areaPath.close();
    
    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF2196F3).withValues(alpha: 0.4),
          const Color(0xFF2196F3).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.drawPath(areaPath, areaPaint);
    
    // Draw line
    final linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    
    final linePaint = Paint()
      ..color = const Color(0xFF2196F3)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    
    canvas.drawPath(linePath, linePaint);
    
    // Draw data points
    for (final point in points) {
      canvas.drawCircle(
        point,
        2.5,
        Paint()
          ..color = const Color(0xFF2196F3)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(LiveChartPainter oldDelegate) => false;
}

/// Heatmap Visualization
class HeatmapViz extends StatelessWidget {
  const HeatmapViz({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Row(
        children: List.generate(12, (week) {
          return Expanded(
            child: Column(
              children: List.generate(7, (day) {
                final random = math.Random(week * 7 + day);
                final intensity = random.nextDouble();
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: Color.lerp(
                        const Color(0xFF0D47A1).withValues(alpha: 0.2),
                        const Color(0xFF2196F3),
                        intensity,
                      ),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: intensity > 0.7
                          ? [
                              BoxShadow(
                                color: const Color(0xFF2196F3).withValues(alpha: 0.6),
                                blurRadius: 4,
                              ),
                            ]
                          : null,
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}
