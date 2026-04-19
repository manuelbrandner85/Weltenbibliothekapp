/// Pattern Heatmap - Muster-Überlappungen visualisieren
/// Version: 1.0.0
library;

import 'package:flutter/material.dart';
import '../models/conspiracy_research_models.dart';

class PatternHeatmap extends StatefulWidget {
  final PatternDetectionResult analysis;
  
  const PatternHeatmap({
    super.key,
    required this.analysis,
  });

  @override
  State<PatternHeatmap> createState() => _PatternHeatmapState();
}

class _PatternHeatmapState extends State<PatternHeatmap> {
  RecurringPattern? _selectedPattern;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        _buildHeader(),
        const SizedBox(height: 16),
        
        // Heatmap Grid
        _buildHeatmapGrid(),
        const SizedBox(height: 16),
        
        // Detail Panel
        if (_selectedPattern != null) _buildDetailPanel(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C4DFF), Color(0xFF1E1E1E)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.grid_on, color: Colors.purple, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MUSTER-ÜBERLAPPUNGEN',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${widget.analysis.patterns.length} Muster erkannt',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          // Confidence Score
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  '${widget.analysis.patterns.length}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
                const Text(
                  'Muster',
                  style: TextStyle(fontSize: 10, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapGrid() {
    final patterns = widget.analysis.patterns;
    if (patterns.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        child: const Text(
          'Keine Muster erkannt',
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
      child: Column(
        children: [
          // Legend
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              children: [
                const Text(
                  'INTENSITÄT:',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
                const SizedBox(width: 16),
                _buildLegendItem('Niedrig', Colors.green),
                _buildLegendItem('Mittel', Colors.orange),
                _buildLegendItem('Hoch', Colors.red),
              ],
            ),
          ),
          
          // Grid
          Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.2,
              ),
              itemCount: patterns.length,
              itemBuilder: (context, index) => _buildPatternCell(patterns[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.white60),
          ),
        ],
      ),
    );
  }

  Widget _buildPatternCell(RecurringPattern pattern) {
    final isSelected = _selectedPattern?.name == pattern.name;
    final intensity = pattern.patternScore;
    final color = _getIntensityColor(intensity);
    
    return GestureDetector(
      onTap: () => setState(() => _selectedPattern = pattern),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.3),
            width: isSelected ? 2.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Frequency Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${(intensity * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 8),
            
            // Pattern Name
            Text(
              pattern.name,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            
            // Occurrence Count
            Text(
              '${pattern.occurrences.length} Vorkommen',
              style: const TextStyle(fontSize: 9, color: Colors.white60),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailPanel() {
    final pattern = _selectedPattern!;
    final color = _getIntensityColor(pattern.patternScore);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.pattern, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pattern.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Score: ${(pattern.patternScore * 100).toStringAsFixed(0)}%',
                      style: TextStyle(fontSize: 12, color: color),
                    ),
                  ],
                ),
              ),
              // Frequency
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${pattern.occurrences.length} Vorkommen',
                  style: TextStyle(fontSize: 11, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Methods
          if (pattern.methods.isNotEmpty) ...[
            const Text(
              'METHODEN',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              pattern.methods.join(' → '),
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
            const SizedBox(height: 12),
          ],
          
          // Occurrences
          const Divider(color: Colors.white10),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'VORKOMMEN',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${pattern.occurrences.length}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Occurrence List
          Container(
            constraints: const BoxConstraints(maxHeight: 150),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: pattern.occurrences.length,
              itemBuilder: (context, index) {
                final occurrence = pattern.occurrences[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          occurrence,
                          style: const TextStyle(fontSize: 11, color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getIntensityColor(double intensity) {
    if (intensity >= 0.7) return Colors.red;
    if (intensity >= 0.4) return Colors.orange;
    return Colors.green;
  }
}
