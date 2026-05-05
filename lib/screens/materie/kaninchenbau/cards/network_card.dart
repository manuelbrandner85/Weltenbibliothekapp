/// Netzwerk-Karte: Force-directed Graph mit antippbaren Knoten.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/thread.dart';
import '../widgets/kb_design.dart';
import '../widgets/network_3d_view.dart';

class NetworkCard extends StatefulWidget {
  final List<NetworkNode> nodes;
  final bool loading;
  final void Function(String label) onTapNode;

  const NetworkCard({
    super.key,
    required this.nodes,
    required this.loading,
    required this.onTapNode,
  });

  @override
  State<NetworkCard> createState() => _NetworkCardState();
}

class _NetworkCardState extends State<NetworkCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: KbDesign.glassBox(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.hub_rounded,
                  color: KbDesign.neonRedSoft, size: 18),
              const SizedBox(width: 8),
              const Text(
                'NETZWERK',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (widget.nodes.length > 1)
                InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => Network3DView(
                          nodes: widget.nodes,
                          onTapNode: widget.onTapNode,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: KbDesign.neonRed.withValues(alpha: 0.18),
                      border: Border.all(
                        color: KbDesign.neonRed.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.threed_rotation,
                            size: 12, color: KbDesign.neonRedSoft),
                        const SizedBox(width: 4),
                        Text(
                          '3D',
                          style: TextStyle(
                            color: KbDesign.neonRedSoft,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Text(
                '${widget.nodes.length} Knoten',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 260,
            child: widget.loading
                ? _buildLoading()
                : widget.nodes.isEmpty
                    ? _buildEmpty()
                    : AnimatedBuilder(
                        animation: _breath,
                        builder: (_, __) => _buildGraph(_breath.value),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() => Center(
        child: Text(
          'Keine Verbindungen gefunden',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
        ),
      );

  Widget _buildLoading() => Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: KbDesign.neonRedSoft,
          ),
        ),
      );

  Widget _buildGraph(double t) {
    return LayoutBuilder(
      builder: (_, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        final centerX = w / 2;
        final centerY = h / 2;

        // Center node
        final center = widget.nodes.firstWhere(
          (n) => n.id == 'center',
          orElse: () => widget.nodes.first,
        );
        final outer = widget.nodes.where((n) => n.id != 'center').toList();
        final radius = math.min(w, h) * 0.38;

        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Edges
            CustomPaint(
              painter: _EdgePainter(
                centerX: centerX,
                centerY: centerY,
                radius: radius,
                count: outer.length,
                breath: t,
              ),
              size: Size(w, h),
            ),
            // Center
            Positioned(
              left: centerX - 36,
              top: centerY - 36,
              child: _NodeBadge(
                label: center.label,
                type: center.type,
                isCenter: true,
                onTap: () {},
              ),
            ),
            // Outer nodes
            for (var i = 0; i < outer.length; i++)
              Builder(builder: (_) {
                final angle =
                    (i / outer.length) * 2 * math.pi + t * math.pi * 0.1;
                final wobble = 4 * math.sin((t * 2 * math.pi) + i);
                final x = centerX + (radius + wobble) * math.cos(angle);
                final y = centerY + (radius + wobble) * math.sin(angle);
                return Positioned(
                  left: x - 30,
                  top: y - 30,
                  child: _NodeBadge(
                    label: outer[i].label,
                    type: outer[i].type,
                    isCenter: false,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      widget.onTapNode(outer[i].label);
                    },
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}

class _NodeBadge extends StatelessWidget {
  final String label;
  final String type;
  final bool isCenter;
  final VoidCallback onTap;

  const _NodeBadge({
    required this.label,
    required this.type,
    required this.isCenter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = isCenter ? 72.0 : 60.0;
    final color = _typeColor(type);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.9),
              color.withValues(alpha: 0.4),
            ],
          ),
          border: Border.all(
            color: isCenter
                ? Colors.white.withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.3),
            width: isCenter ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.5),
              blurRadius: isCenter ? 22 : 14,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Text(
              label.length > 12 ? '${label.substring(0, 11)}…' : label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: isCenter ? 11 : 9,
                fontWeight: FontWeight.w600,
                height: 1.1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'person':
        return const Color(0xFF66BB6A);
      case 'company':
        return const Color(0xFF42A5F5);
      case 'org':
        return const Color(0xFFFFB74D);
      default:
        return const Color(0xFFAB47BC);
    }
  }
}

class _EdgePainter extends CustomPainter {
  final double centerX;
  final double centerY;
  final double radius;
  final int count;
  final double breath;

  _EdgePainter({
    required this.centerX,
    required this.centerY,
    required this.radius,
    required this.count,
    required this.breath,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = KbDesign.neonRed.withValues(alpha: 0.28)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < count; i++) {
      final angle = (i / count) * 2 * math.pi + breath * math.pi * 0.1;
      final wobble = 4 * math.sin((breath * 2 * math.pi) + i);
      final x = centerX + (radius + wobble) * math.cos(angle);
      final y = centerY + (radius + wobble) * math.sin(angle);
      canvas.drawLine(Offset(centerX, centerY), Offset(x, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _EdgePainter old) => old.breath != breath;
}
