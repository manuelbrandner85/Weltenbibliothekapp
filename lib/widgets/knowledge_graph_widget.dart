import 'dart:math' as math;
import 'package:flutter/material.dart';

// ── Datenmodelle ─────────────────────────────────────────────────────────────────────────
class KnowledgeNode {
  final String id;
  final String slug;
  final String title;
  final String? description;
  final String world;
  final String? category;
  final String? icon;
  final int level;
  final bool discovered;

  const KnowledgeNode({
    required this.id,
    required this.slug,
    required this.title,
    this.description,
    required this.world,
    this.category,
    this.icon,
    this.level = 1,
    this.discovered = false,
  });

  Color get worldColor {
    switch (world) {
      case 'ursprung': return const Color(0xFFFFD700);
      case 'vorhang':  return const Color(0xFFE53935);
      case 'energie':  return const Color(0xFF7C4DFF);
      case 'materie':  return const Color(0xFF2196F3);
      default:         return Colors.grey;
    }
  }
}

class KnowledgeEdge {
  final String id;
  final String sourceId;
  final String targetId;
  final String relation;
  final double strength;

  const KnowledgeEdge({
    required this.id,
    required this.sourceId,
    required this.targetId,
    required this.relation,
    this.strength = 1.0,
  });

  Color get relationColor {
    switch (relation) {
      case 'basiert_auf':   return const Color(0xFF4FC3F7);
      case 'enthält':       return const Color(0xFF81C784);
      case 'führt_zu':      return const Color(0xFFFFB74D);
      case 'ähnlich':       return const Color(0xFFCE93D8);
      case 'widerspricht':  return const Color(0xFFEF9A9A);
      default:              return Colors.grey;
    }
  }
}

// ── Layout-Node (Fruchterman-Reingold) ──────────────────────────────────────────────
class _LayoutNode {
  final KnowledgeNode node;
  double x;
  double y;
  double vx = 0;
  double vy = 0;
  int degree = 0;

  _LayoutNode({required this.node, required this.x, required this.y});
}

// ── Fruchterman-Reingold Layout Engine ───────────────────────────────────────────
class FRLayout {
  static List<_LayoutNode> compute({
    required List<KnowledgeNode> nodes,
    required List<KnowledgeEdge> edges,
    required Size size,
    int iterations = 120,
  }) {
    if (nodes.isEmpty) return [];
    final rng = math.Random(42);
    final layoutNodes = nodes.map((n) => _LayoutNode(
      node: n,
      x: rng.nextDouble() * size.width,
      y: rng.nextDouble() * size.height,
    )).toList();

    final nodeIndex = {for (var i = 0; i < layoutNodes.length; i++) nodes[i].id: i};

    for (final e in edges) {
      final si = nodeIndex[e.sourceId];
      final ti = nodeIndex[e.targetId];
      if (si != null && ti != null) {
        layoutNodes[si].degree++;
        layoutNodes[ti].degree++;
      }
    }

    final area = size.width * size.height;
    final k = math.sqrt(area / math.max(1, nodes.length)) * 0.9;
    final kSq = k * k;

    double temperature = size.width * 0.3;
    const cooling = 0.95;

    for (int iter = 0; iter < iterations; iter++) {
      for (int i = 0; i < layoutNodes.length; i++) {
        double fx = 0, fy = 0;
        for (int j = 0; j < layoutNodes.length; j++) {
          if (i == j) continue;
          final dx = layoutNodes[i].x - layoutNodes[j].x;
          final dy = layoutNodes[i].y - layoutNodes[j].y;
          final dist = math.sqrt(dx * dx + dy * dy);
          if (dist < 0.01) continue;
          final f = kSq / dist;
          fx += (dx / dist) * f;
          fy += (dy / dist) * f;
        }
        layoutNodes[i].vx += fx;
        layoutNodes[i].vy += fy;
      }

      for (final e in edges) {
        final si = nodeIndex[e.sourceId];
        final ti = nodeIndex[e.targetId];
        if (si == null || ti == null) continue;
        final src = layoutNodes[si];
        final tgt = layoutNodes[ti];
        final dx = tgt.x - src.x;
        final dy = tgt.y - src.y;
        final dist = math.sqrt(dx * dx + dy * dy);
        if (dist < 0.01) continue;
        final f = (dist * dist / k) * e.strength;
        src.vx += (dx / dist) * f;
        src.vy += (dy / dist) * f;
        tgt.vx -= (dx / dist) * f;
        tgt.vy -= (dy / dist) * f;
      }

      for (final n in layoutNodes) {
        final mag = math.sqrt(n.vx * n.vx + n.vy * n.vy);
        if (mag > 0) {
          final capped = math.min(mag, temperature);
          n.x += (n.vx / mag) * capped;
          n.y += (n.vy / mag) * capped;
        }
        n.vx = 0;
        n.vy = 0;
        n.x = n.x.clamp(60, size.width - 60);
        n.y = n.y.clamp(60, size.height - 60);
      }

      temperature *= cooling;
    }

    return layoutNodes;
  }
}

// ── CustomPainter ──────────────────────────────────────────────────────────────────────
class KnowledgeGraphPainter extends CustomPainter {
  final List<_LayoutNode> layoutNodes;
  final List<KnowledgeEdge> edges;
  final Map<String, int> nodeIndexById;
  final String? highlightNodeId;
  final double pulseValue;

  KnowledgeGraphPainter({
    required this.layoutNodes,
    required this.edges,
    required this.nodeIndexById,
    this.highlightNodeId,
    this.pulseValue = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawEdges(canvas);
    _drawNodes(canvas);
  }

  void _drawEdges(Canvas canvas) {
    for (final edge in edges) {
      final si = nodeIndexById[edge.sourceId];
      final ti = nodeIndexById[edge.targetId];
      if (si == null || ti == null) continue;
      final src = layoutNodes[si];
      final tgt = layoutNodes[ti];

      final alpha = (0.2 + edge.strength * 0.2).clamp(0.15, 0.7);
      final paint = Paint()
        ..color = edge.relationColor.withValues(alpha: alpha)
        ..strokeWidth = (edge.strength * 1.2).clamp(0.5, 3.0)
        ..style = PaintingStyle.stroke;

      final p1 = Offset(src.x, src.y);
      final p2 = Offset(tgt.x, tgt.y);
      canvas.drawLine(p1, p2, paint);
      _drawArrow(canvas, p1, p2, edge.relationColor.withValues(alpha: alpha + 0.1));
    }
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to, Color color) {
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len < 30) return;

    final nx = dx / len;
    final ny = dy / len;
    const arrowLen = 8.0;
    const arrowWidth = 4.0;

    final tipX = to.dx - nx * 18;
    final tipY = to.dy - ny * 18;

    final p1 = Offset(tipX - nx * arrowLen + ny * arrowWidth, tipY - ny * arrowLen - nx * arrowWidth);
    final p2 = Offset(tipX - nx * arrowLen - ny * arrowWidth, tipY - ny * arrowLen + nx * arrowWidth);
    final tip = Offset(tipX, tipY);

    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final path = Path()..moveTo(tip.dx, tip.dy)..lineTo(p1.dx, p1.dy)..lineTo(p2.dx, p2.dy)..close();
    canvas.drawPath(path, paint);
  }

  void _drawNodes(Canvas canvas) {
    for (final ln in layoutNodes) {
      final node = ln.node;
      final isHighlighted = highlightNodeId == node.id;
      final baseRadius = (12.0 + ln.degree * 2.5).clamp(12.0, 30.0);
      final radius = isHighlighted ? baseRadius + 4 + pulseValue * 4 : baseRadius;
      final center = Offset(ln.x, ln.y);
      final color = node.worldColor;

      if (!node.discovered) {
        canvas.drawCircle(center, radius,
            Paint()..color = color.withValues(alpha: 0.15)..style = PaintingStyle.fill);
        canvas.drawCircle(center, radius,
            Paint()..color = color.withValues(alpha: 0.3)..style = PaintingStyle.stroke..strokeWidth = 1.5);
        final tp = TextPainter(
          text: const TextSpan(text: '?', style: TextStyle(color: Colors.white38, fontSize: 14, fontWeight: FontWeight.bold)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
      } else {
        if (isHighlighted) {
          canvas.drawCircle(center, radius + 8,
              Paint()..color = color.withValues(alpha: 0.25 + pulseValue * 0.15)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16));
        }
        final gradient = RadialGradient(colors: [
          color.withValues(alpha: 0.9),
          color.withValues(alpha: 0.5),
        ]).createShader(Rect.fromCircle(center: center, radius: radius));
        canvas.drawCircle(center, radius, Paint()..shader = gradient..style = PaintingStyle.fill);
        canvas.drawCircle(center, radius,
            Paint()..color = color.withValues(alpha: isHighlighted ? 0.95 : 0.6)
              ..style = PaintingStyle.stroke
              ..strokeWidth = isHighlighted ? 2.5 : 1.5);

        if (node.icon != null && node.icon!.isNotEmpty) {
          final iconSize = (radius * 0.9).clamp(10.0, 20.0);
          final tp = TextPainter(
            text: TextSpan(text: node.icon, style: TextStyle(fontSize: iconSize)),
            textDirection: TextDirection.ltr,
          )..layout();
          tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
        }
      }

      if (ln.degree >= 2 || isHighlighted) {
        final label = node.discovered ? node.title : '???';
        final tp = TextPainter(
          text: TextSpan(text: label, style: TextStyle(
            color: node.discovered ? Colors.white.withValues(alpha: 0.85) : Colors.white24,
            fontSize: 9.5,
            fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w400,
          )),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout(maxWidth: 80);
        tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy + radius + 3));
      }
    }
  }

  @override
  bool shouldRepaint(KnowledgeGraphPainter old) =>
      old.pulseValue != pulseValue ||
      old.highlightNodeId != highlightNodeId ||
      old.layoutNodes != layoutNodes;
}

// ── KnowledgeGraphWidget ──────────────────────────────────────────────────────────────
class KnowledgeGraphWidget extends StatefulWidget {
  final List<KnowledgeNode> nodes;
  final List<KnowledgeEdge> edges;
  final String? worldFilter;
  final String? searchQuery;
  final void Function(KnowledgeNode)? onNodeTap;

  const KnowledgeGraphWidget({
    super.key,
    required this.nodes,
    required this.edges,
    this.worldFilter,
    this.searchQuery,
    this.onNodeTap,
  });

  @override
  State<KnowledgeGraphWidget> createState() => _KnowledgeGraphWidgetState();
}

class _KnowledgeGraphWidgetState extends State<KnowledgeGraphWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  List<_LayoutNode> _layoutNodes = [];
  Map<String, int> _nodeIndexById = {};
  String? _highlightNodeId;
  bool _layoutDone = false;

  static const _canvasSize = Size(1800, 1800);

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _computeLayout();
  }

  @override
  void didUpdateWidget(KnowledgeGraphWidget old) {
    super.didUpdateWidget(old);
    if (old.nodes != widget.nodes ||
        old.edges != widget.edges ||
        old.worldFilter != widget.worldFilter) {
      _computeLayout();
    }
  }

  void _computeLayout() {
    final filteredNodes = widget.worldFilter == null
        ? widget.nodes
        : widget.nodes.where((n) => n.world == widget.worldFilter).toList();

    final nodeIds = {for (final n in filteredNodes) n.id};
    final filteredEdges = widget.edges
        .where((e) => nodeIds.contains(e.sourceId) && nodeIds.contains(e.targetId))
        .toList();

    final layout = FRLayout.compute(
      nodes: filteredNodes,
      edges: filteredEdges,
      size: _canvasSize,
      iterations: 150,
    );

    setState(() {
      _layoutNodes = layout;
      _nodeIndexById = {for (var i = 0; i < layout.length; i++) layout[i].node.id: i};
      _layoutDone = true;
    });
  }

  List<KnowledgeEdge> get _filteredEdges {
    final nodeIds = {for (final ln in _layoutNodes) ln.node.id};
    return widget.edges
        .where((e) => nodeIds.contains(e.sourceId) && nodeIds.contains(e.targetId))
        .toList();
  }

  void _handleTap(TapDownDetails details) {
    for (final ln in _layoutNodes) {
      final nodeRadius = (12.0 + ln.degree * 2.5).clamp(12.0, 30.0) + 8.0;
      final dx = ln.x - details.localPosition.dx;
      final dy = ln.y - details.localPosition.dy;
      if (dx * dx + dy * dy <= nodeRadius * nodeRadius) {
        setState(() => _highlightNodeId = ln.node.id);
        widget.onNodeTap?.call(ln.node);
        return;
      }
    }
    setState(() => _highlightNodeId = null);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_layoutDone || _layoutNodes.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF7C4DFF)));
    }

    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, _) {
        return GestureDetector(
          onTapDown: _handleTap,
          child: CustomPaint(
            size: _canvasSize,
            painter: KnowledgeGraphPainter(
              layoutNodes: _layoutNodes,
              edges: _filteredEdges,
              nodeIndexById: _nodeIndexById,
              highlightNodeId: _highlightNodeId,
              pulseValue: _pulseCtrl.value,
            ),
          ),
        );
      },
    );
  }
}
