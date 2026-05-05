/// Netzwerk-Karte: ECHTER Wikidata-Beziehungs-Graph mit beschrifteten Kanten.
///
/// Layout: Cluster-Anordnung — Knoten gleichen Beziehungstyps gruppieren sich
/// in Sektoren. Jede Kante trägt ihr deutsches Beziehungs-Label
/// (z.B. „Mitglied", „Vorsitz", „Ehepartner").
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/thread.dart';
import '../widgets/kb_design.dart';
import '../widgets/network_3d_view.dart';

class NetworkCard extends StatefulWidget {
  final List<NetworkNode> nodes;
  final List<NetworkEdge> edges;
  final bool loading;
  final void Function(String label) onTapNode;

  const NetworkCard({
    super.key,
    required this.nodes,
    this.edges = const [],
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
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  /// Gruppiert Outer-Nodes nach Beziehungs-Label (basierend auf edges).
  /// Returnt: { 'Mitglied': [n1, n3], 'Vorsitz': [n2], … }
  Map<String, List<NetworkNode>> _clusterByRelation() {
    final clusters = <String, List<NetworkNode>>{};
    final edgeByTo = <String, NetworkEdge>{};
    for (final e in widget.edges) {
      edgeByTo[e.toId] = e; // letzte Edge pro Knoten gewinnt
    }
    for (final n in widget.nodes.where((n) => n.id != 'center')) {
      final edge = edgeByTo[n.id];
      final key = edge?.label ?? 'verwandt';
      clusters.putIfAbsent(key, () => []).add(n);
    }
    return clusters;
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
                '${widget.nodes.length - 1} Verbindungen',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Echte Wikidata-Beziehungen',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 320,
            child: widget.loading
                ? _buildLoading()
                : widget.nodes.length <= 1
                    ? _buildEmpty()
                    : AnimatedBuilder(
                        animation: _breath,
                        builder: (_, __) => _buildGraph(_breath.value),
                      ),
          ),
          if (!widget.loading && widget.edges.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildLegend(),
          ],
        ],
      ),
    );
  }

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hub_rounded,
                color: Colors.white.withValues(alpha: 0.18), size: 36),
            const SizedBox(height: 10),
            Text(
              'Keine Wikidata-Verbindungen gefunden',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
            ),
            const SizedBox(height: 4),
            Text(
              'Thema ist evtl. zu vage oder neu',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.25), fontSize: 11),
            ),
          ],
        ),
      );

  Widget _buildLoading() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: KbDesign.neonRedSoft,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'SPARQL-Abfrage läuft …',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
            ),
          ],
        ),
      );

  Widget _buildGraph(double t) {
    return LayoutBuilder(
      builder: (_, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        final centerX = w / 2;
        final centerY = h / 2;

        final center = widget.nodes.firstWhere(
          (n) => n.id == 'center',
          orElse: () => widget.nodes.first,
        );

        // Cluster nach Beziehungstyp
        final clusters = _clusterByRelation();
        final clusterKeys = clusters.keys.toList();
        final radius = math.min(w, h) * 0.36;

        // Berechne Position für jeden Knoten basierend auf Cluster
        // Jeder Cluster bekommt einen Sektor des Kreises (z.B. 90°)
        final positions = <String, Offset>{}; // nodeId → pos
        final positionAngles = <String, double>{};
        var nodeCounter = 0;
        final totalOuter = widget.nodes.length - 1;

        for (var ci = 0; ci < clusterKeys.length; ci++) {
          final key = clusterKeys[ci];
          final clusterNodes = clusters[key]!;
          // Sektor-Mitte: ci/clusterKeys * 2π
          final sectorCenter =
              (ci / clusterKeys.length) * 2 * math.pi + t * math.pi * 0.05;
          // Spreize Knoten innerhalb des Sektors
          final sectorWidth = (2 * math.pi / clusterKeys.length) *
              0.7; // 70% des Sektors nutzen
          for (var ni = 0; ni < clusterNodes.length; ni++) {
            final n = clusterNodes[ni];
            final innerOffset = clusterNodes.length == 1
                ? 0.0
                : (ni / (clusterNodes.length - 1) - 0.5) * sectorWidth;
            final angle = sectorCenter + innerOffset;
            final wobble = 3 * math.sin((t * 2 * math.pi) + nodeCounter);
            final r = radius + wobble;
            positions[n.id] = Offset(
              centerX + r * math.cos(angle),
              centerY + r * math.sin(angle),
            );
            positionAngles[n.id] = angle;
            nodeCounter++;
          }
        }

        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Edges mit Labels
            CustomPaint(
              painter: _LabeledEdgePainter(
                centerX: centerX,
                centerY: centerY,
                positions: positions,
                edges: widget.edges,
                breath: t,
              ),
              size: Size(w, h),
            ),
            // Center
            Positioned(
              left: centerX - 38,
              top: centerY - 38,
              child: _NodeBadge(
                label: center.label,
                type: center.type,
                isCenter: true,
                onTap: () {},
              ),
            ),
            // Outer nodes
            for (var n in widget.nodes.where((n) => n.id != 'center'))
              if (positions[n.id] != null)
                Positioned(
                  left: positions[n.id]!.dx - 32,
                  top: positions[n.id]!.dy - 32,
                  child: _NodeBadge(
                    label: n.label,
                    type: n.type,
                    isCenter: false,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      widget.onTapNode(n.label);
                    },
                  ),
                ),
            // Cluster-Sektor-Beschriftungen am Rand
            for (var ci = 0; ci < clusterKeys.length; ci++)
              if (totalOuter > 0)
                Builder(builder: (_) {
                  final angle = (ci / clusterKeys.length) * 2 * math.pi +
                      t * math.pi * 0.05;
                  final labelRadius = radius + 38;
                  final lx = centerX + labelRadius * math.cos(angle);
                  final ly = centerY + labelRadius * math.sin(angle);
                  return Positioned(
                    left: lx - 50,
                    top: ly - 9,
                    child: SizedBox(
                      width: 100,
                      child: Text(
                        clusterKeys[ci].toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: KbDesign.neonRedSoft.withValues(alpha: 0.85),
                          fontSize: 9,
                          letterSpacing: 1.3,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                }),
          ],
        );
      },
    );
  }

  Widget _buildLegend() {
    final clusters = _clusterByRelation();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: clusters.entries.map((e) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: KbDesign.neonRed.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: KbDesign.neonRedSoft,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '${e.key} (${e.value.length})',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
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
    final size = isCenter ? 76.0 : 64.0;
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
                : color.withValues(alpha: 0.7),
            width: isCenter ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.5),
              blurRadius: isCenter ? 24 : 14,
              spreadRadius: isCenter ? 2 : 0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: isCenter ? 10 : 9,
                fontWeight: FontWeight.w700,
                shadows: const [
                  Shadow(color: Colors.black54, blurRadius: 4),
                ],
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
        return const Color(0xFFEC407A);
      case 'company':
        return const Color(0xFF42A5F5);
      case 'org':
        return const Color(0xFFFFB74D);
      case 'place':
        return const Color(0xFF66BB6A);
      default:
        return const Color(0xFFAB47BC);
    }
  }
}

/// Zeichnet Kanten zwischen Center und outer Nodes.
/// Jede Kante hat einen Beziehungs-Label-Hintergrund auf der Mitte.
class _LabeledEdgePainter extends CustomPainter {
  final double centerX;
  final double centerY;
  final Map<String, Offset> positions;
  final List<NetworkEdge> edges;
  final double breath;

  _LabeledEdgePainter({
    required this.centerX,
    required this.centerY,
    required this.positions,
    required this.edges,
    required this.breath,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerOff = Offset(centerX, centerY);
    final paint = Paint()
      ..color = KbDesign.neonRed.withValues(alpha: 0.32)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    // Group by toId um doppelte Linien zu vermeiden (eine Edge pro Knoten)
    final drawn = <String, NetworkEdge>{};
    for (final e in edges) {
      drawn[e.toId] = e;
    }

    for (final entry in drawn.entries) {
      final pos = positions[entry.key];
      if (pos == null) continue;

      // Glow-Linie
      final glowPaint = Paint()
        ..color = KbDesign.neonRed.withValues(alpha: 0.12)
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawLine(centerOff, pos, glowPaint);

      // Haupt-Linie
      canvas.drawLine(centerOff, pos, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LabeledEdgePainter old) =>
      old.breath != breath ||
      old.edges != edges ||
      old.positions != positions;
}
