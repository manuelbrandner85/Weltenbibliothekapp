/// Temporal Timeline - Vereinfachte Zeitachsen-Darstellung
/// Version: 1.0.0
library;

import 'package:flutter/material.dart';
import '../models/conspiracy_research_models.dart';

class TemporalTimeline extends StatefulWidget {
  final TemporalAnalysisResult analysis;
  
  const TemporalTimeline({
    super.key,
    required this.analysis,
  });

  @override
  State<TemporalTimeline> createState() => _TemporalTimelineState();
}

class _TemporalTimelineState extends State<TemporalTimeline> {
  NarrativeSnapshot? _selectedEvent;
  bool _showOfficial = true;
  bool _showAlternative = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header mit Filtern
        _buildHeader(),
        const SizedBox(height: 16),
        
        // Timeline
        _buildTimeline(),
        const SizedBox(height: 16),
        
        // Detail-Panel
        if (_selectedEvent != null) _buildDetailPanel(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1E1E1E)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timeline, color: Colors.blue, size: 32),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'TEMPORALE WAHRHEITS-ANALYSE',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              // Event Count
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      '${widget.analysis.timeline.length}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const Text(
                      'Ereignisse',
                      style: TextStyle(fontSize: 10, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Filter
          Row(
            children: [
              const Text(
                'ANSICHT:',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
              const SizedBox(width: 12),
              _buildFilterChip('Offiziell', _showOfficial, Colors.blue, (val) {
                setState(() => _showOfficial = val);
              }),
              const SizedBox(width: 8),
              _buildFilterChip('Alternativ', _showAlternative, Colors.orange, (val) {
                setState(() => _showAlternative = val);
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool value, Color color, Function(bool) onChanged) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: value,
      onSelected: onChanged,
      selectedColor: color.withValues(alpha: 0.3),
      checkmarkColor: color,
      side: BorderSide(color: color.withValues(alpha: 0.5)),
      backgroundColor: Colors.white10,
    );
  }

  Widget _buildTimeline() {
    final events = widget.analysis.timeline
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (events.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        child: const Text(
          'Keine Ereignisse gefunden',
          style: TextStyle(color: Colors.white38),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          final isSelected = _selectedEvent?.timestamp == event.timestamp;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: InkWell(
              onTap: () => setState(() => _selectedEvent = event),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? Colors.blue.withValues(alpha: 0.2)
                      : const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.white10,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Datum
                    Text(
                      _formatDate(event.timestamp),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Offizielle Version
                    if (_showOfficial) ...[
                      const Text(
                        'OFFIZIELL:',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.officialVersion,
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                      const SizedBox(height: 12),
                    ],
                    
                    // Alternative Version
                    if (_showAlternative) ...[
                      const Text(
                        'ALTERNATIV:',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.alternativeVersion,
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                    
                    // Vergessene Info
                    if (event.forgottenInfo.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'VERGESSEN/UNTERDRÜCKT:',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ...event.forgottenInfo.map((info) => Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning, size: 10, color: Colors.red),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      info,
                                      style: const TextStyle(fontSize: 10, color: Colors.white60),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailPanel() {
    final event = _selectedEvent!;
    
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
              const Icon(Icons.event, color: Colors.blue, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _formatDate(event.timestamp),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Vergleich
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'OFFIZIELL',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.officialVersion,
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ALTERNATIV',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.alternativeVersion,
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'];
    return '${date.day}. ${months[date.month - 1]} ${date.year}';
  }
}
