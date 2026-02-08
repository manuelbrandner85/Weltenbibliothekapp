/// Netzwerk-Graph Widget für Akteurs-Verbindungen
/// Zeigt Beziehungen zwischen Akteuren als interaktiven Graphen
/// 
/// VERWENDUNG:
/// - Machtstrukturen visualisieren
/// - Geldflüsse zwischen Akteuren zeigen
/// - Verbindungen und Einflüsse darstellen
library;

import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import '../models/analyse_models.dart';

class NetzwerkGraphWidget extends StatefulWidget {
  final List<Akteur> akteure;
  final List<Geldfluss> geldfluesse;
  final String titel;

  const NetzwerkGraphWidget({
    super.key,
    required this.akteure,
    required this.geldfluesse,
    this.titel = 'Akteurs-Netzwerk',
  });

  @override
  State<NetzwerkGraphWidget> createState() => _NetzwerkGraphWidgetState();
}

class _NetzwerkGraphWidgetState extends State<NetzwerkGraphWidget> {
  final Graph graph = Graph()..isTree = false;
  late BuchheimWalkerConfiguration builder;

  @override
  void initState() {
    super.initState();
    _buildGraph();
    
    builder = BuchheimWalkerConfiguration()
      ..siblingSeparation = 100
      ..levelSeparation = 150
      ..subtreeSeparation = 150
      ..orientation = BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM;
  }

  void _buildGraph() {
    // Knoten erstellen (Akteure)
    final nodeMap = <String, Node>{};
    for (final akteur in widget.akteure) {
      final node = Node.Id(akteur.id);
      graph.addNode(node);
      nodeMap[akteur.id] = node;
    }

    // Kanten erstellen (Verbindungen aus Geldflüssen)
    for (final geldfluss in widget.geldfluesse) {
      final fromNode = nodeMap[geldfluss.vonAkteurId];
      final toNode = nodeMap[geldfluss.zuAkteurId];
      
      if (fromNode != null && toNode != null) {
        graph.addEdge(fromNode, toNode);
      }
    }

    // Zusätzliche Verbindungen aus Akteur-Verbindungen
    for (final akteur in widget.akteure) {
      final fromNode = nodeMap[akteur.id];
      if (fromNode != null) {
        for (final verbindungId in akteur.verbindungen) {
          final toNode = nodeMap[verbindungId];
          if (toNode != null) {
            graph.addEdge(fromNode, toNode);
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.akteure.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titel
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            widget.titel,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),

        // Graph
        Container(
          height: 400,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: InteractiveViewer(
            constrained: false,
            boundaryMargin: const EdgeInsets.all(100),
            minScale: 0.5,
            maxScale: 3.0,
            child: GraphView(
              graph: graph,
              algorithm: BuchheimWalkerAlgorithm(
                builder,
                TreeEdgeRenderer(builder),
              ),
              paint: Paint()
                ..color = Colors.blue
                ..strokeWidth = 2
                ..style = PaintingStyle.stroke,
              builder: (Node node) {
                final akteur = widget.akteure.firstWhere(
                  (a) => a.id == node.key?.value,
                  orElse: () => Akteur(
                    id: '',
                    name: 'Unbekannt',
                    typ: AkteurTyp.person,
                  ),
                );
                return _buildAkteurNode(akteur);
              },
            ),
          ),
        ),

        // Legende
        Padding(
          padding: const EdgeInsets.all(16),
          child: _buildLegende(),
        ),
      ],
    );
  }

  Widget _buildAkteurNode(Akteur akteur) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: akteur.farbe.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: akteur.farbe,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(akteur.icon, color: akteur.farbe, size: 24),
          const SizedBox(height: 4),
          SizedBox(
            width: 80,
            child: Text(
              akteur.name,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (akteur.machtindex != null) ...[
            const SizedBox(height: 4),
            Container(
              width: 60,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: akteur.machtindex,
                child: Container(
                  decoration: BoxDecoration(
                    color: akteur.farbe,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegende() {
    final typen = widget.akteure.map((a) => a.typ).toSet().toList();
    
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: typen.map((typ) {
        final beispielAkteur = widget.akteure.firstWhere((a) => a.typ == typ);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(beispielAkteur.icon, color: beispielAkteur.farbe, size: 16),
            const SizedBox(width: 6),
            Text(
              typ.name,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_tree,
              size: 64,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Keine Netzwerk-Daten verfügbar',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
