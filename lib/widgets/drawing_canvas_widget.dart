import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'glassmorphism_card.dart';
import 'premium_icons.dart';

/// 🎨 DRAWING CANVAS WIDGET - Handzeichnungen/Skizzen
class DrawingCanvasWidget extends StatefulWidget {
  final Function(Uint8List imageBytes) onDrawingComplete;
  
  const DrawingCanvasWidget({
    super.key,
    required this.onDrawingComplete,
  });
  
  @override
  State<DrawingCanvasWidget> createState() => _DrawingCanvasWidgetState();
}

class _DrawingCanvasWidgetState extends State<DrawingCanvasWidget> {
  final List<DrawingPoint?> _points = [];
  Color _selectedColor = Colors.white;
  double _strokeWidth = 3.0;
  
  final List<Color> _colors = [
    Colors.white,
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.purple,
    Colors.pink,
    Colors.black,
    Colors.grey,
  ];
  
  final List<double> _strokeWidths = [2.0, 4.0, 6.0];
  
  void _clear() {
    setState(() => _points.clear());
  }
  
  void _undo() {
    if (_points.isEmpty) return;
    
    setState(() {
      // Remove last continuous stroke
      int? lastNullIndex;
      for (int i = _points.length - 1; i >= 0; i--) {
        if (_points[i] == null) {
          lastNullIndex = i;
          break;
        }
      }
      
      if (lastNullIndex != null) {
        _points.removeRange(lastNullIndex, _points.length);
      } else {
        _points.clear();
      }
    });
  }
  
  Future<void> _save() async {
    // Convert canvas to image
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = const Size(400, 400);
    
    // Draw background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.black,
    );
    
    // Draw all points
    for (int i = 0; i < _points.length - 1; i++) {
      if (_points[i] != null && _points[i + 1] != null) {
        canvas.drawLine(
          _points[i]!.offset,
          _points[i + 1]!.offset,
          _points[i]!.paint,
        );
      }
    }
    
    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();
    
    widget.onDrawingComplete(bytes);
  }
  
  @override
  Widget build(BuildContext context) {
    return GlassmorphismCard(
      blur: 15,
      opacity: 0.15,
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              const GradientIcon(
                icon: Icons.draw,
                size: 28,
                colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Zeichnung erstellen',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.undo, color: Colors.white),
                onPressed: _undo,
                tooltip: 'Rückgängig',
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.white),
                onPressed: _clear,
                tooltip: 'Alles löschen',
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Canvas
          Container(
            height: 300,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: GestureDetector(
                onPanStart: (details) {
                  setState(() {
                    _points.add(
                      DrawingPoint(
                        offset: details.localPosition,
                        paint: Paint()
                          ..color = _selectedColor
                          ..strokeWidth = _strokeWidth
                          ..strokeCap = StrokeCap.round,
                      ),
                    );
                  });
                },
                onPanUpdate: (details) {
                  setState(() {
                    _points.add(
                      DrawingPoint(
                        offset: details.localPosition,
                        paint: Paint()
                          ..color = _selectedColor
                          ..strokeWidth = _strokeWidth
                          ..strokeCap = StrokeCap.round,
                      ),
                    );
                  });
                },
                onPanEnd: (details) {
                  setState(() {
                    _points.add(null);
                  });
                },
                child: CustomPaint(
                  size: Size.infinite,
                  painter: DrawingPainter(_points),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Color Picker
          Row(
            children: [
              const Text(
                'Farbe:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _colors.length,
                    itemBuilder: (context, index) {
                      final color = _colors[index];
                      final isSelected = _selectedColor == color;
                      
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () => setState(() => _selectedColor = color),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.blue
                                    : Colors.white.withValues(alpha: 0.3),
                                width: isSelected ? 3 : 2,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: Colors.blue.withValues(alpha: 0.5),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Stroke Width Picker
          Row(
            children: [
              const Text(
                'Dicke:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              ...List.generate(_strokeWidths.length, (index) {
                final width = _strokeWidths[index];
                final isSelected = _strokeWidth == width;
                
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: InkWell(
                    onTap: () => setState(() => _strokeWidth = width),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.blue.withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? Colors.blue
                              : Colors.white.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: width * 3,
                          height: width * 3,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const Spacer(),
              Text(
                ['S', 'M', 'L'][_strokeWidths.indexOf(_strokeWidth)],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _points.isEmpty ? null : _save,
              icon: const Icon(Icons.check),
              label: const Text('Zeichnung speichern'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Drawing Point - Punkt auf Canvas
class DrawingPoint {
  final Offset offset;
  final Paint paint;
  
  DrawingPoint({
    required this.offset,
    required this.paint,
  });
}

/// Drawing Painter - Custom Painter für Canvas
class DrawingPainter extends CustomPainter {
  final List<DrawingPoint?> points;
  
  DrawingPainter(this.points);
  
  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(
          points[i]!.offset,
          points[i + 1]!.offset,
          points[i]!.paint,
        );
      }
    }
  }
  
  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}
