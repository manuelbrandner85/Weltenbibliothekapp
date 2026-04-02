/// WELTENBIBLIOTHEK v5.11 – INTERNATIONALE PERSPEKTIVEN UI
/// 
/// Visualisiert wie dasselbe Thema international unterschiedlich dargestellt wird
library;

import 'package:flutter/material.dart';
import '../models/international_perspectives.dart';

/// Widget für internationale Perspektiven-Analyse
class InternationalPerspectivesWidget extends StatefulWidget {
  final InternationalPerspectivesAnalysis analysis;
  
  const InternationalPerspectivesWidget({
    super.key,
    required this.analysis,
  });
  
  @override
  State<InternationalPerspectivesWidget> createState() => 
      _InternationalPerspectivesWidgetState();
}

class _InternationalPerspectivesWidgetState 
    extends State<InternationalPerspectivesWidget> {
  String? _selectedRegion;
  
  @override
  void initState() {
    super.initState();
    // Wähle primäre Region als Standard
    _selectedRegion = widget.analysis.primaryRegion;
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple[700]!, Colors.purple[900]!],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.public, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'INTERNATIONALE PERSPEKTIVEN',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Wie wird "${widget.analysis.topic}" weltweit dargestellt?',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          
          // QUELLEN-VERTEILUNG
          _buildSourceDistribution(),
          
          const Divider(height: 1),
          
          // REGIONEN-TABS
          _buildRegionTabs(),
          
          const Divider(height: 1),
          
          // PERSPEKTIVEN-DETAILS
          if (_selectedRegion != null)
            _buildPerspectiveDetails(_selectedRegion!),
          
          const Divider(height: 1),
          
          // VERGLEICHS-SECTION
          _buildComparisonSection(),
        ],
      ),
    );
  }
  
  Widget _buildSourceDistribution() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'QUELLEN-AUFTEILUNG',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: widget.analysis.perspectives.map((perspective) {
              final regionDef = InternationalPerspective.getRegionDefinition(perspective.region);
              if (regionDef == null || perspective.sources.isEmpty) return const SizedBox.shrink();
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: regionDef.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: regionDef.color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      regionDef.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: regionDef.color,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: regionDef.color,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${perspective.sources.length}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRegionTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: widget.analysis.perspectives.map((perspective) {
          final regionDef = InternationalPerspective.getRegionDefinition(
            perspective.region,
          );
          if (regionDef == null) return const SizedBox.shrink();
          
          final isSelected = _selectedRegion == perspective.region;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                setState(() => _selectedRegion = perspective.region);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? regionDef.color 
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected 
                        ? regionDef.color 
                        : Colors.grey[300]!,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      regionDef.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? Colors.white.withValues(alpha: 0.3)
                            : regionDef.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${perspective.sources.length}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : regionDef.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildPerspectiveDetails(String region) {
    final perspective = widget.analysis.getPerspectiveByRegion(region);
    if (perspective == null) return const SizedBox.shrink();
    
    final regionDef = InternationalPerspective.getRegionDefinition(region);
    if (regionDef == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // NARRATIVE
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: regionDef.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: regionDef.color.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_stories, color: regionDef.color, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'NARRATIVE',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: regionDef.color,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  perspective.narrative,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // HAUPTPUNKTE
          Text(
            'HAUPTPUNKTE',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: regionDef.color,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          ...perspective.keyPoints.map((point) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: regionDef.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    point,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )),
          
          const SizedBox(height: 16),
          
          // QUELLEN
          Text(
            'QUELLEN (${perspective.sources.length})',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: regionDef.color,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          ...perspective.sources.take(5).map((source) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '• $source',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          )),
          if (perspective.sources.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '... und ${perspective.sources.length - 5} weitere',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildComparisonSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.compare_arrows, color: Colors.indigo[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'INTERNATIONALER VERGLEICH',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo[900],
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // GEMEINSAME PUNKTE
          if (widget.analysis.commonPoints.isNotEmpty) ...[
            Text(
              '✅ GEMEINSAME PUNKTE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 8),
            ...widget.analysis.commonPoints.map((point) => Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 8),
              child: Text(
                '• $point',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            )),
            const SizedBox(height: 12),
          ],
          
          // UNTERSCHIEDE
          if (widget.analysis.differences.isNotEmpty) ...[
            Text(
              '⚖️ UNTERSCHIEDE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.orange[700],
              ),
            ),
            const SizedBox(height: 8),
            ...widget.analysis.differences.map((diff) => Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 8),
              child: Text(
                '• $diff',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            )),
          ],
        ],
      ),
    );
  }
}
