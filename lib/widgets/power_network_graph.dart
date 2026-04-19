/// Power Network Graph - Vereinfachte Visualisierung
/// Version: 1.0.0
library;

import 'package:flutter/material.dart';
import '../models/conspiracy_research_models.dart';

class PowerNetworkGraph extends StatefulWidget {
  final PowerNetworkResult analysis;
  
  const PowerNetworkGraph({
    super.key,
    required this.analysis,
  });

  @override
  State<PowerNetworkGraph> createState() => _PowerNetworkGraphState();
}

class _PowerNetworkGraphState extends State<PowerNetworkGraph> {
  PowerActor? _selectedActor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header mit Statistik
        _buildHeader(),
        const SizedBox(height: 16),
        
        // Actor List
        _buildActorList(),
        const SizedBox(height: 16),
        
        // Detail-Panel
        if (_selectedActor != null) _buildDetailPanel(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF1E1E1E)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.hub, color: Colors.blue, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MACHT-NETZWERK',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${widget.analysis.actors.length} Akteure • ${widget.analysis.connections.length} Verbindungen',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          // Actor Count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  '${widget.analysis.actors.length}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const Text(
                  'Akteure',
                  style: TextStyle(fontSize: 10, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActorList() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: widget.analysis.actors.length,
        itemBuilder: (context, index) {
          final actor = widget.analysis.actors[index];
          final isSelected = _selectedActor?.id == actor.id;
          return ListTile(
            selected: isSelected,
            selectedTileColor: Colors.blue.withValues(alpha: 0.2),
            leading: Icon(
              actor.isSilent ? Icons.visibility_off : Icons.visibility,
              color: actor.isSilent ? Colors.orange : Colors.green,
            ),
            title: Text(
              actor.name,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
            subtitle: Text(
              actor.type.toString().split('.').last,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${actor.influenceScore.toInt()}',
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap: () => setState(() => _selectedActor = actor),
          );
        },
      ),
    );
  }

  Widget _buildDetailPanel() {
    final actor = _selectedActor!;
    final color = actor.isSilent ? Colors.orange : Colors.green;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  actor.isSilent ? Icons.visibility_off : Icons.visibility,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      actor.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      actor.type.toString().split('.').last.toUpperCase(),
                      style: TextStyle(fontSize: 12, color: color),
                    ),
                  ],
                ),
              ),
              // Influence Score
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Einfluss: ${actor.influenceScore.toInt()}',
                  style: const TextStyle(fontSize: 11, color: Colors.blue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Verbindungen
          if (actor.connections.isNotEmpty) ...[
            const Divider(color: Colors.white10),
            const SizedBox(height: 8),
            const Text(
              'VERBINDUNGEN',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: actor.connections.map((conn) => Chip(
                label: Text(conn, style: const TextStyle(fontSize: 10)),
                backgroundColor: Colors.white10,
                side: BorderSide.none,
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
