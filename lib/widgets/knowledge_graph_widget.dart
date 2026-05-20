import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 🕸️ KNOWLEDGE GRAPH WIDGET
// Wiederverwendbares Widget für interaktive Wissensgraphen.
// Nutzt graphview mit FruchtermanReingoldAlgorithm.
// Einsatz: KnowledgeGraphScreen + eingebettet in World-Home-Tabs
// ═══════════════════════════════════════════════════════════════════════════

// ── Daten-Modelle ────────────────────────────────────────────────────────────

class KnowledgeNode {
  final String id;
  final String label;
  final String? description;
  final String nodeType; // concept, person, event, place, artifact, theory
  final String iconEmoji;
  final Color color;
  final int weight; // 1–10, beeinflusst Node-Größe
  final bool isBookmarked;

  const KnowledgeNode({
    required this.id,
    required this.label,
    this.description,
    this.nodeType = 'concept',
    this.iconEmoji = '🔵',
    this.color = const Color(0xFF4A90D9),
    this.weight = 1,
    this.isBookmarked = false,
  });

  KnowledgeNode copyWith({bool? isBookmarked}) => KnowledgeNode(
        id: id,
        label: label,
        description: description,
        nodeType: nodeType,
        iconEmoji: iconEmoji,
        color: color,
        weight: weight,
        isBookmarked: isBookmarked ?? this.isBookmarked,
      );
}

class KnowledgeEdge {
  final String sourceId;
  final String targetId;
  final String relation; // related, causes, contradicts, supports, …
  final int strength; // 1–10

  const KnowledgeEdge({
    required this.sourceId,
    required this.targetId,
    this.relation = 'related',
    this.strength = 5,
  });
}

// ── Callback-Typen ──────────────────────────────────────────────────────────────

typedef OnNodeTap = void Function(KnowledgeNode node);
typedef OnNodeLongPress = void Function(KnowledgeNode node);

// ── Haupt-Widget ────────────────────────────────────────────────────────────────────

/// Interaktiver Force-Directed Knowledge-Graph basierend auf `graphview`.
///
/// Verwendung:
/// ```dart
/// KnowledgeGraphWidget(
///   nodes: nodes,
///   edges: edges,
///   accentColor: Color(0xFF7C4DFF),
///   onNodeTap: (node) => Navigator.push(...),
/// )
/// ```
class KnowledgeGraphWidget extends StatefulWidget {
  final List<KnowledgeNode> nodes;
  final List<KnowledgeEdge> edges;
  final Color accentColor;
  final Color backgroundColor;
  final OnNodeTap? onNodeTap;
  final OnNodeLongPress? onNodeLongPress;
  final String? highlightedNodeId;

  const KnowledgeGraphWidget({
    super.key,
    required this.nodes,
    required this.edges,
    this.accentColor = const Color(0xFF4A90D9),
    this.backgroundColor = const Color(0xFF050310),
    this.onNodeTap,
    this.onNodeLongPress,
    this.highlightedNodeId,
  });

  @override
  State<KnowledgeGraphWidget> createState() => _KnowledgeGraphWidgetState();
}

class _KnowledgeGraphWidgetState extends State<KnowledgeGraphWidget>
    with SingleTickerProviderStateMixin {
  late final Graph _graph;
  late final FruchtermanReingoldAlgorithm _algorithm;
  final _nodeMap = <String, Node>{}; // KnowledgeNode.id → graphview-Node

  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _algorithm = FruchtermanReingoldAlgorithm(iterations: 200);
    _graph = Graph()..isTree = false;
    _buildGraph();

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant KnowledgeGraphWidget old) {
    super.didUpdateWidget(old);
    // Graph neu aufbauen wenn sich Daten ändern
    if (old.nodes != widget.nodes || old.edges != widget.edges) {
      _buildGraph();
    }
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  // ── Graph aufbauen ───────────────────────────────────────────────────────────────

  void _buildGraph() {
    _graph.nodes.clear();
    _graph.edges.clear();
    _nodeMap.clear();

    // Knoten hinzufügen
    for (final kn in widget.nodes) {
      final n = Node.Id(kn.id);
      _graph.addNode(n);
      _nodeMap[kn.id] = n;
    }

    // Kanten hinzufügen
    for (final ke in widget.edges) {
      final src = _nodeMap[ke.sourceId];
      final tgt = _nodeMap[ke.targetId];
      if (src != null && tgt != null) {
        _graph.addEdge(src, tgt, paint: _edgePaint(ke));
      }
    }
  }

  Paint _edgePaint(KnowledgeEdge edge) {
    Color edgeColor;
    switch (edge.relation) {
      case 'contradicts':
        edgeColor = Colors.red.withValues(alpha: 0.6);
        break;
      case 'supports':
        edgeColor = Colors.green.withValues(alpha: 0.6);
        break;
      case 'causes':
        edgeColor = Colors.orange.withValues(alpha: 0.6);
        break;
      default:
        edgeColor = widget.accentColor.withValues(alpha: 0.4);
    }
    return Paint()
      ..color = edgeColor
      ..strokeWidth = (edge.strength / 3).clamp(1.0, 4.0)
      ..style = PaintingStyle.stroke;
  }

  // ── Node-Größe aus weight ─────────────────────────────────────────────────────────────

  double _nodeSize(int weight) => 32.0 + weight * 4.0;

  // ── Node-Widget ─────────────────────────────────────────────────────────────────────

  Widget _buildNodeWidget(KnowledgeNode kn) {
    final size = _nodeSize(kn.weight);
    final isHighlighted = widget.highlightedNodeId == kn.id;

    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (context, _) {
        return GestureDetector(
          onTap: () => widget.onNodeTap?.call(kn),
          onLongPress: () => widget.onNodeLongPress?.call(kn),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kn.color.withValues(alpha: 0.85),
              border: Border.all(
                color: isHighlighted
                    ? Colors.white
                    : kn.color.withValues(alpha: 0.6),
                width: isHighlighted ? 2.5 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: kn.color.withValues(
                    alpha: isHighlighted ? _glowAnim.value * 0.8 : 0.35,
                  ),
                  blurRadius: isHighlighted ? 16 : 8,
                  spreadRadius: isHighlighted ? 4 : 1,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  kn.iconEmoji,
                  style: TextStyle(fontSize: size * 0.38),
                ),
                // Bookmark-Indikator
                if (kn.isBookmarked)
                  Positioned(
                    top: 1,
                    right: 1,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (widget.nodes.isEmpty) {
      return _buildEmptyState();
    }

    return ClipRect(
      child: InteractiveViewer(
        constrained: false,
        boundaryMargin: const EdgeInsets.all(80),
        minScale: 0.3,
        maxScale: 3.0,
        child: GraphView(
          graph: _graph,
          algorithm: _algorithm,
          paint: Paint()
            ..color = widget.accentColor.withValues(alpha: 0.3)
            ..strokeWidth = 1.5
            ..style = PaintingStyle.stroke,
          builder: (Node node) {
            // Node-ID zurück zu KnowledgeNode mappen
            final nodeId = node.key?.value as String?;
            final kn = widget.nodes.firstWhere(
              (n) => n.id == nodeId,
              orElse: () => KnowledgeNode(
                id: nodeId ?? '',
                label: '?',
                color: widget.accentColor,
              ),
            );
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildNodeWidget(kn),
                const SizedBox(height: 4),
                // Label unter dem Knoten
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 80),
                  child: Text(
                    kn.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                      shadows: const [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_tree_outlined,
            size: 64,
            color: widget.accentColor.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Keine Knoten vorhanden',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Füge Wissensknoten hinzu\num den Graph zu füllen',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Legende ────────────────────────────────────────────────────────────────────────────

/// Kompakte Legende für Kanten-Relationen
class KnowledgeGraphLegend extends StatelessWidget {
  final Color accentColor;

  const KnowledgeGraphLegend({super.key, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('related', accentColor.withValues(alpha: 0.7), 'Verwandt'),
      ('supports', Colors.green.withValues(alpha: 0.7), 'Stützt'),
      ('contradicts', Colors.red.withValues(alpha: 0.7), 'Widerspricht'),
      ('causes', Colors.orange.withValues(alpha: 0.7), 'Verursacht'),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: items.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 3,
              decoration: BoxDecoration(
                color: item.$2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              item.$3,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 11,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

// ── Node-Detail-Sheet ──────────────────────────────────────────────────────────────────

/// Bottom-Sheet mit Details zu einem Wissensknoten
class NodeDetailSheet extends StatelessWidget {
  final KnowledgeNode node;
  final List<KnowledgeNode> connectedNodes;
  final Color accentColor;
  final VoidCallback? onBookmarkToggle;

  const NodeDetailSheet({
    super.key,
    required this.node,
    this.connectedNodes = const [],
    required this.accentColor,
    this.onBookmarkToggle,
  });

  static Future<void> show({
    required BuildContext context,
    required KnowledgeNode node,
    required List<KnowledgeNode> connectedNodes,
    required Color accentColor,
    VoidCallback? onBookmarkToggle,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => NodeDetailSheet(
        node: node,
        connectedNodes: connectedNodes,
        accentColor: accentColor,
        onBookmarkToggle: onBookmarkToggle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D1E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 12, 12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: node.color.withValues(alpha: 0.25),
                    border: Border.all(
                      color: node.color.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      node.iconEmoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        node.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: node.color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _typeLabel(node.nodeType),
                          style: TextStyle(
                            color: node.color,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Bookmark-Button
                IconButton(
                  icon: Icon(
                    node.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: node.isBookmarked
                        ? Colors.amber
                        : Colors.white.withValues(alpha: 0.4),
                    size: 22,
                  ),
                  onPressed: onBookmarkToggle,
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Colors.white.withValues(alpha: 0.4),
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(color: Color(0xFF1A1A2E), thickness: 1, height: 1),

          // Scrollbarer Inhalt
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Beschreibung
                  if (node.description != null &&
                      node.description!.isNotEmpty) ...[
                    Text(
                      node.description!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Verbundene Knoten
                  if (connectedNodes.isNotEmpty) ...[
                    Text(
                      'Verbundene Themen',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: connectedNodes.map((cn) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: cn.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: cn.color.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                cn.iconEmoji,
                                style: const TextStyle(fontSize: 13),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                cn.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _typeLabel(String type) {
    switch (type) {
      case 'concept':
        return 'Konzept';
      case 'person':
        return 'Person';
      case 'event':
        return 'Ereignis';
      case 'place':
        return 'Ort';
      case 'artifact':
        return 'Artefakt';
      case 'theory':
        return 'Theorie';
      default:
        return type;
    }
  }
}

// ── Mini-Graph (einbettbar in Home-Tabs) ─────────────────────────────────────────────────────

/// Kleiner, nicht-interaktiver Graph-Preview für Home-Tabs.
/// Nutzt CustomPaint für Performance — kein graphview overhead.
class KnowledgeMiniGraph extends StatefulWidget {
  final List<KnowledgeNode> nodes;
  final List<KnowledgeEdge> edges;
  final Color accentColor;
  final double height;

  const KnowledgeMiniGraph({
    super.key,
    required this.nodes,
    required this.edges,
    required this.accentColor,
    this.height = 160,
  });

  @override
  State<KnowledgeMiniGraph> createState() => _KnowledgeMiniGraphState();
}

class _KnowledgeMiniGraphState extends State<KnowledgeMiniGraph>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late List<Offset> _positions;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _computePositions();
  }

  @override
  void didUpdateWidget(covariant KnowledgeMiniGraph old) {
    super.didUpdateWidget(old);
    if (old.nodes != widget.nodes) _computePositions();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _computePositions() {
    final rng = math.Random(42); // deterministisch
    _positions = List.generate(
      widget.nodes.length,
      (_) => Offset(rng.nextDouble(), rng.nextDouble()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) => CustomPaint(
          painter: _MiniGraphPainter(
            nodes: widget.nodes,
            edges: widget.edges,
            positions: _positions,
            accentColor: widget.accentColor,
            animValue: _anim.value,
          ),
        ),
      ),
    );
  }
}

class _MiniGraphPainter extends CustomPainter {
  final List<KnowledgeNode> nodes;
  final List<KnowledgeEdge> edges;
  final List<Offset> positions; // normalisiert 0..1
  final Color accentColor;
  final double animValue;

  _MiniGraphPainter({
    required this.nodes,
    required this.edges,
    required this.positions,
    required this.accentColor,
    required this.animValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (nodes.isEmpty) return;
    const pad = 20.0;
    final w = size.width - pad * 2;
    final h = size.height - pad * 2;

    // Kanten
    final edgePaint = Paint()
      ..color = accentColor.withValues(alpha: 0.25)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (final edge in edges) {
      final si = nodes.indexWhere((n) => n.id == edge.sourceId);
      final ti = nodes.indexWhere((n) => n.id == edge.targetId);
      if (si < 0 || ti < 0) continue;
      final sp = Offset(
        pad + positions[si].dx * w,
        pad + positions[si].dy * h,
      );
      final tp = Offset(
        pad + positions[ti].dx * w,
        pad + positions[ti].dy * h,
      );
      canvas.drawLine(sp, tp, edgePaint);
    }

    // Knoten
    for (int i = 0; i < nodes.length; i++) {
      final kn = nodes[i];
      final pos = Offset(
        pad + positions[i].dx * w,
        pad + positions[i].dy * h,
      );
      final radius = 6.0 + kn.weight * 0.8;

      // Glow
      final pulseFactor =
          0.5 + 0.5 * math.sin(animValue * 2 * math.pi + i * 0.7);
      canvas.drawCircle(
        pos,
        radius + 3,
        Paint()
          ..color = kn.color.withValues(alpha: 0.15 * pulseFactor)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );

      // Füllung
      canvas.drawCircle(
        pos,
        radius,
        Paint()..color = kn.color.withValues(alpha: 0.8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MiniGraphPainter old) =>
      old.animValue != animValue || old.nodes != nodes;
}
