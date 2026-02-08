/// **WELTENBIBLIOTHEK - STEP 3 VISUALISIERUNG**
/// Mindmap Widget für Themenverknüpfungen
/// 
/// Zeigt Themen, Konzepte und deren Verbindungen als interaktive Mindmap
library;

import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Mindmap-Knoten
class MindmapKnoten {
  final String id;
  final String titel;
  final String kategorie; // haupt, unter, detail
  final List<String> unterKnoten; // IDs der Unterthemen
  final int tiefe; // 0 = Hauptthema, 1 = Unterthema, etc.
  final Color? customColor;
  
  const MindmapKnoten({
    required this.id,
    required this.titel,
    required this.kategorie,
    this.unterKnoten = const [],
    this.tiefe = 0,
    this.customColor,
  });
}

class MindmapWidget extends StatefulWidget {
  final String hauptthema;
  final List<MindmapKnoten> knoten;
  
  const MindmapWidget({
    super.key,
    required this.hauptthema,
    required this.knoten,
  });

  @override
  State<MindmapWidget> createState() => _MindmapWidgetState();
}

class _MindmapWidgetState extends State<MindmapWidget> {
  String? _expandedKnotenId;
  String? _selectedKnotenId;
  final TransformationController _transformationController = TransformationController();
  
  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Color _getKnotenColor(int tiefe) {
    const colors = [
      Color(0xFF2196F3), // Blau - Hauptthema
      Color(0xFF4CAF50), // Grün - Unterthemen
      Color(0xFF9C27B0), // Lila - Details
      Color(0xFFFF9800), // Orange - Weitere Details
    ];
    return colors[tiefe.clamp(0, colors.length - 1)];
  }

  double _getKnotenSize(int tiefe) {
    switch (tiefe) {
      case 0:
        return 120.0; // Hauptthema
      case 1:
        return 90.0; // Unterthemen
      case 2:
        return 70.0; // Details
      default:
        return 60.0; // Weitere Details
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.knoten.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildControls(),
        const SizedBox(height: 16),
        Expanded(
          child: InteractiveViewer(
            transformationController: _transformationController,
            boundaryMargin: const EdgeInsets.all(200),
            minScale: 0.5,
            maxScale: 2.5,
            child: Center(
              child: CustomPaint(
                painter: _MindmapPainter(
                  knoten: widget.knoten,
                  expandedId: _expandedKnotenId,
                  selectedId: _selectedKnotenId,
                  getColor: _getKnotenColor,
                  getSize: _getKnotenSize,
                ),
                child: SizedBox(
                  width: 800,
                  height: 600,
                  child: _buildInteractiveNodes(),
                ),
              ),
            ),
          ),
        ),
        if (_selectedKnotenId != null) _buildKnotenDetails(),
      ],
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.zoom_in, color: Colors.white),
          onPressed: () {
            final matrix = _transformationController.value.clone();
            matrix.scale(1.2);
            _transformationController.value = matrix;
          },
        ),
        IconButton(
          icon: const Icon(Icons.zoom_out, color: Colors.white),
          onPressed: () {
            final matrix = _transformationController.value.clone();
            matrix.scale(0.8);
            _transformationController.value = matrix;
          },
        ),
        IconButton(
          icon: const Icon(Icons.center_focus_strong, color: Colors.white),
          onPressed: () {
            _transformationController.value = Matrix4.identity();
          },
        ),
        IconButton(
          icon: Icon(
            _expandedKnotenId == null ? Icons.unfold_more : Icons.unfold_less,
            color: Colors.white,
          ),
          onPressed: () {
            setState(() {
              _expandedKnotenId = _expandedKnotenId == null ? widget.knoten.first.id : null;
            });
          },
        ),
      ],
    );
  }

  Widget _buildInteractiveNodes() {
    return Stack(
      children: widget.knoten.map((knoten) {
        final position = _calculateNodePosition(knoten);
        final size = _getKnotenSize(knoten.tiefe);
        
        return Positioned(
          left: position.dx - size / 2,
          top: position.dy - size / 2,
          child: GestureDetector(
            onTap: () {
              setState(() {
                if (_selectedKnotenId == knoten.id) {
                  _selectedKnotenId = null;
                } else {
                  _selectedKnotenId = knoten.id;
                  _expandedKnotenId = knoten.id;
                }
              });
            },
            child: _buildKnotenWidget(knoten),
          ),
        );
      }).toList(),
    );
  }

  Offset _calculateNodePosition(MindmapKnoten knoten) {
    const centerX = 400.0;
    const centerY = 300.0;
    
    if (knoten.tiefe == 0) {
      return const Offset(centerX, centerY);
    }
    
    // Finde Parent-Knoten
    final parentIndex = widget.knoten.indexWhere(
      (k) => k.unterKnoten.contains(knoten.id),
    );
    
    if (parentIndex == -1) {
      return const Offset(centerX, centerY);
    }
    
    final parent = widget.knoten[parentIndex];
    final parentPos = _calculateNodePosition(parent);
    
    // Berechne Position basierend auf Index unter Geschwistern
    final geschwister = widget.knoten.where((k) => k.tiefe == knoten.tiefe).toList();
    final index = geschwister.indexOf(knoten);
    final total = geschwister.length;
    
    final radius = 150.0 * knoten.tiefe;
    final angleStep = (2 * math.pi) / math.max(total, 3);
    final angle = angleStep * index;
    
    final x = parentPos.dx + radius * math.cos(angle);
    final y = parentPos.dy + radius * math.sin(angle);
    
    return Offset(x, y);
  }

  Widget _buildKnotenWidget(MindmapKnoten knoten) {
    final size = _getKnotenSize(knoten.tiefe);
    final color = knoten.customColor ?? _getKnotenColor(knoten.tiefe);
    final isSelected = _selectedKnotenId == knoten.id;
    final isExpanded = _expandedKnotenId == knoten.id;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(
          color: isSelected ? Colors.yellow : Colors.white.withValues(alpha: 0.5),
          width: isSelected ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: isSelected ? 15 : isExpanded ? 10 : 5,
            spreadRadius: isSelected ? 3 : isExpanded ? 2 : 1,
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            knoten.titel,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: knoten.tiefe == 0 ? 14 : 11,
              fontWeight: knoten.tiefe == 0 ? FontWeight.bold : FontWeight.normal,
            ),
            maxLines: knoten.tiefe == 0 ? 3 : 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildKnotenDetails() {
    final knoten = widget.knoten.firstWhere((k) => k.id == _selectedKnotenId);
    final unterThemen = widget.knoten
        .where((k) => knoten.unterKnoten.contains(k.id))
        .toList();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(
            color: knoten.customColor ?? _getKnotenColor(knoten.tiefe),
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: knoten.customColor ?? _getKnotenColor(knoten.tiefe),
                ),
                child: Center(
                  child: Text(
                    knoten.tiefe.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      knoten.titel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      knoten.kategorie.toUpperCase(),
                      style: TextStyle(
                        color: knoten.customColor ?? _getKnotenColor(knoten.tiefe),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => setState(() => _selectedKnotenId = null),
              ),
            ],
          ),
          if (unterThemen.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Unterthemen:',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: unterThemen.map((unter) {
                return Chip(
                  label: Text(
                    unter.titel,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  backgroundColor: _getKnotenColor(unter.tiefe).withValues(alpha: 0.5),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_tree,
            size: 64,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'Keine Mindmap-Daten verfügbar',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _MindmapPainter extends CustomPainter {
  final List<MindmapKnoten> knoten;
  final String? expandedId;
  final String? selectedId;
  final Color Function(int) getColor;
  final double Function(int) getSize;
  
  _MindmapPainter({
    required this.knoten,
    this.expandedId,
    this.selectedId,
    required this.getColor,
    required this.getSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Zeichne Verbindungslinien
    for (final knotenItem in knoten) {
      for (final unterId in knotenItem.unterKnoten) {
        final unterKnoten = knoten.firstWhere(
          (k) => k.id == unterId,
          orElse: () => knoten.first,
        );
        
        final von = _calculatePosition(knotenItem, size);
        final zu = _calculatePosition(unterKnoten, size);
        
        paint.color = (knotenItem.customColor ?? getColor(knotenItem.tiefe)).withValues(alpha: 0.5);
        
        canvas.drawLine(von, zu, paint);
      }
    }
  }

  Offset _calculatePosition(MindmapKnoten knotenItem, Size size) {
    const centerX = 400.0;
    const centerY = 300.0;
    
    if (knotenItem.tiefe == 0) {
      return const Offset(centerX, centerY);
    }
    
    final parentIndex = knoten.indexWhere(
      (k) => k.unterKnoten.contains(knotenItem.id),
    );
    
    if (parentIndex == -1) {
      return const Offset(centerX, centerY);
    }
    
    final parent = knoten[parentIndex];
    final parentPos = _calculatePosition(parent, size);
    
    final geschwister = knoten.where((k) => k.tiefe == knotenItem.tiefe).toList();
    final index = geschwister.indexOf(knotenItem);
    final total = geschwister.length;
    
    final radius = 150.0 * knotenItem.tiefe;
    final angleStep = (2 * math.pi) / math.max(total, 3);
    final angle = angleStep * index;
    
    final x = parentPos.dx + radius * math.cos(angle);
    final y = parentPos.dy + radius * math.sin(angle);
    
    return Offset(x, y);
  }

  @override
  bool shouldRepaint(_MindmapPainter oldDelegate) {
    return oldDelegate.expandedId != expandedId ||
        oldDelegate.selectedId != selectedId;
  }
}
