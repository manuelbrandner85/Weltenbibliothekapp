/// **WELTENBIBLIOTHEK - STEP 2 VISUALISIERUNG**
/// Netzwerk-Graph Widget für Akteurs-Verbindungen
/// 
/// Zeigt Akteure, Organisationen und deren Verbindungen als interaktives Netzwerk
/// Basiert auf Analyse-Daten aus STEP 2
library;

import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

/// Akteur im Netzwerk
class NetzwerkAkteur {
  final String id;
  final String name;
  final String typ; // person, organisation, regierung, konzern
  final double einfluss; // 0.0 - 1.0
  final List<String> verbindungen; // IDs anderer Akteure
  
  const NetzwerkAkteur({
    required this.id,
    required this.name,
    required this.typ,
    required this.einfluss,
    this.verbindungen = const [],
  });
}

/// Verbindung zwischen zwei Akteuren
class NetzwerkVerbindung {
  final String von;
  final String zu;
  final String art; // finanziell, politisch, persönlich, geschäftlich
  final double staerke; // 0.0 - 1.0
  
  const NetzwerkVerbindung({
    required this.von,
    required this.zu,
    required this.art,
    required this.staerke,
  });
}

class NetzwerkGraphWidget extends StatefulWidget {
  final List<NetzwerkAkteur> akteure;
  final List<NetzwerkVerbindung> verbindungen;
  
  const NetzwerkGraphWidget({
    super.key,
    required this.akteure,
    required this.verbindungen,
  });

  @override
  State<NetzwerkGraphWidget> createState() => _NetzwerkGraphWidgetState();
}

class _NetzwerkGraphWidgetState extends State<NetzwerkGraphWidget> {
  final Graph graph = Graph();
  late SugiyamaConfiguration builder;
  NetzwerkAkteur? _selectedAkteur;
  
  @override
  void initState() {
    super.initState();
    _buildGraph();
    
    builder = SugiyamaConfiguration()
      ..nodeSeparation = (80)
      ..levelSeparation = (100)
      ..orientation = SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM;
  }

  void _buildGraph() {
    // Erstelle neuen Graph statt clear() zu verwenden
    // graph.clear(); // Nicht unterstützt in dieser GraphView-Version
    
    // Nodes erstellen
    final nodeMap = <String, Node>{};
    for (final akteur in widget.akteure) {
      final node = Node.Id(akteur.id);
      graph.addNode(node);
      nodeMap[akteur.id] = node;
    }
    
    // Edges erstellen
    for (final verbindung in widget.verbindungen) {
      final vonNode = nodeMap[verbindung.von];
      final zuNode = nodeMap[verbindung.zu];
      if (vonNode != null && zuNode != null) {
        graph.addEdge(vonNode, zuNode);
      }
    }
  }

  Color _getAkteurFarbe(String typ) {
    switch (typ.toLowerCase()) {
      case 'person':
        return Colors.blue;
      case 'organisation':
        return Colors.green;
      case 'regierung':
        return Colors.red;
      case 'konzern':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getAkteurIcon(String typ) {
    switch (typ.toLowerCase()) {
      case 'person':
        return Icons.person;
      case 'organisation':
        return Icons.business;
      case 'regierung':
        return Icons.account_balance;
      case 'konzern':
        return Icons.corporate_fare;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.akteure.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildLegende(),
        const SizedBox(height: 16),
        Expanded(
          child: InteractiveViewer(
            constrained: false,
            boundaryMargin: const EdgeInsets.all(100),
            minScale: 0.5,
            maxScale: 2.0,
            child: GraphView(
              graph: graph,
              algorithm: SugiyamaAlgorithm(builder),
              paint: Paint()
                ..color = Colors.white.withValues(alpha: 0.2)
                ..strokeWidth = 2
                ..style = PaintingStyle.stroke,
              builder: (Node node) {
                final akteur = widget.akteure.firstWhere(
                  (a) => a.id == node.key!.value,
                  orElse: () => widget.akteure.first,
                );
                
                return _buildAkteurNode(akteur);
              },
            ),
          ),
        ),
        if (_selectedAkteur != null) _buildAkteurDetails(),
      ],
    );
  }

  Widget _buildAkteurNode(NetzwerkAkteur akteur) {
    final isSelected = _selectedAkteur?.id == akteur.id;
    final size = 40.0 + (akteur.einfluss * 30.0); // 40-70px basierend auf Einfluss
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAkteur = isSelected ? null : akteur;
        });
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _getAkteurFarbe(akteur.typ),
          border: Border.all(
            color: isSelected ? Colors.yellow : Colors.white.withValues(alpha: 0.5),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _getAkteurFarbe(akteur.typ).withValues(alpha: 0.5),
              blurRadius: isSelected ? 15 : 8,
              spreadRadius: isSelected ? 3 : 1,
            ),
          ],
        ),
        child: Center(
          child: Icon(
            _getAkteurIcon(akteur.typ),
            color: Colors.white,
            size: size * 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildLegende() {
    return Card(
      color: Colors.black.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLegendeItem('Person', Icons.person, Colors.blue),
            const SizedBox(width: 16),
            _buildLegendeItem('Organisation', Icons.business, Colors.green),
            const SizedBox(width: 16),
            _buildLegendeItem('Regierung', Icons.account_balance, Colors.red),
            const SizedBox(width: 16),
            _buildLegendeItem('Konzern', Icons.corporate_fare, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendeItem(String label, IconData icon, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
          child: Icon(icon, color: Colors.white, size: 14),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildAkteurDetails() {
    final akteur = _selectedAkteur!;
    final verbindungen = widget.verbindungen
        .where((v) => v.von == akteur.id || v.zu == akteur.id)
        .toList();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        border: Border(
          top: BorderSide(color: _getAkteurFarbe(akteur.typ), width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                _getAkteurIcon(akteur.typ),
                color: _getAkteurFarbe(akteur.typ),
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      akteur.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      akteur.typ.toUpperCase(),
                      style: TextStyle(
                        color: _getAkteurFarbe(akteur.typ),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => setState(() => _selectedAkteur = null),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildEinflussAnzeige(akteur.einfluss),
          const SizedBox(height: 12),
          const Text(
            'Verbindungen:',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          ...verbindungen.map((v) => _buildVerbindungItem(v)),
        ],
      ),
    );
  }

  Widget _buildEinflussAnzeige(double einfluss) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Einfluss: ',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              '${(einfluss * 100).toStringAsFixed(0)}%',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: einfluss,
          backgroundColor: Colors.white.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation(
            einfluss > 0.7 ? Colors.red : einfluss > 0.4 ? Colors.orange : Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildVerbindungItem(NetzwerkVerbindung verbindung) {
    final andererAkteur = widget.akteure.firstWhere(
      (a) => a.id == (verbindung.von == _selectedAkteur!.id ? verbindung.zu : verbindung.von),
      orElse: () => widget.akteure.first,
    );
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.arrow_forward,
            color: Colors.white.withValues(alpha: 0.5),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              andererAkteur.name,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              verbindung.art,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),
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
            Icons.hub_outlined,
            size: 64,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'Keine Netzwerkdaten verfügbar',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
