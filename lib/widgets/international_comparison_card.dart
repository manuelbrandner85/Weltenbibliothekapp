/// WELTENBIBLIOTHEK v5.12 – INTERNATIONALER VERGLEICH UI
/// 
/// Zeigt wie dasselbe Thema in verschiedenen Regionen unterschiedlich dargestellt wird
/// mit klarer Trennung:
/// - 🇩🇪 Darstellung DE
/// - 🇺🇸 Darstellung EN  
/// - 🌍 Internationale Perspektive
/// 
/// Jede Sicht hat:
/// - Eigene Quellen
/// - Eigener Vertrauensscore
/// - Eigener Tonfall/Narrative
library;

import 'package:flutter/material.dart';
import '../models/international_perspectives.dart';
import '../utils/quellen_bewertung.dart';

/// Hauptwidget für internationalen Vergleich
class InternationalComparisonCard extends StatelessWidget {
  final InternationalPerspectivesAnalysis analysis;
  
  const InternationalComparisonCard({
    super.key,
    required this.analysis,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          _buildHeader(),
          
          const Divider(height: 1),
          
          // REGIONALE DARSTELLUNGEN
          ...analysis.perspectives.map((perspective) => 
            _buildRegionalPerspectiveSection(context, perspective)
          ),
          
          const Divider(height: 1),
          
          // VERGLEICHS-ZUSAMMENFASSUNG
          _buildComparisonSummary(),
        ],
      ),
    );
  }
  
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo[700]!, Colors.indigo[900]!],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '━━━━━━━━━━━━━━━━━━━━',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.public, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'INTERNATIONALER VERGLEICH',
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
          const Text(
            '━━━━━━━━━━━━━━━━━━━━',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Wie wird "${analysis.topic}" international dargestellt?',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: analysis.perspectives
              .map((perspective) {
                final regionDef = InternationalPerspective.getRegionDefinition(perspective.region);
                if (regionDef == null) return const SizedBox.shrink();
                
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${regionDef.label} ${perspective.sources.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                );
              }).toList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRegionalPerspectiveSection(
    BuildContext context, 
    InternationalPerspective perspective,
  ) {
    final regionDef = InternationalPerspective.getRegionDefinition(perspective.region);
    if (regionDef == null) return const SizedBox.shrink();
    
    // Quellen bewerten und Durchschnittsscore berechnen
    final bewertungen = perspective.sources
        .map((source) => QuellenBewertung.analyseQuelle(source))
        .toList();
    final durchschnittScore = bewertungen.isEmpty 
        ? -1.0
        : bewertungen
            .where((b) => b.istBewertet)
            .map((b) => b.vertrauensScore.toDouble())
            .fold<double>(0.0, (sum, score) => sum + score) / 
          bewertungen.where((b) => b.istBewertet).length;
    
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: regionDef.color.withValues(alpha: 0.3), width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // REGION-HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: regionDef.color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      regionDef.label,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: regionDef.color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      regionDef.label,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                // VERTRAUENSSCORE-BADGE
                if (durchschnittScore >= 0) _buildTrustScoreBadge(durchschnittScore),
              ],
            ),
          ),
          
          // NARRATIVE
          Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.format_quote, color: regionDef.color, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'TONFALL & NARRATIVE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: regionDef.color,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    perspective.narrative,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[800],
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // HAUPTPUNKTE
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.list_alt, color: regionDef.color, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'HAUPTPUNKTE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: regionDef.color,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
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
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // QUELLEN MIT BEWERTUNGEN
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.source, color: regionDef.color, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'QUELLEN (${perspective.sources.length})',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: regionDef.color,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    if (durchschnittScore >= 0)
                      Text(
                        'Ø ${durchschnittScore.toStringAsFixed(0)}/100',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _getScoreColor(durchschnittScore.toInt()),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                ...bewertungen.take(3).map((bewertung) {
                  final sourceIndex = bewertungen.indexOf(bewertung);
                  final source = perspective.sources[sourceIndex];
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            source,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (bewertung.istBewertet)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getScoreColor(bewertung.vertrauensScore),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${bewertung.vertrauensScore}',
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
                }),
                if (perspective.sources.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '... und ${perspective.sources.length - 3} weitere Quellen',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTrustScoreBadge(double score) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getScoreColor(score.toInt()),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            'Ø ${score.toStringAsFixed(0)}/100',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildComparisonSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.amber[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.compare_arrows, color: Colors.amber, size: 24),
              SizedBox(width: 8),
              Text(
                'VERGLEICH & ANALYSE',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // GEMEINSAME PUNKTE
          if (analysis.commonPoints.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[700], size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '✅ GEMEINSAME PUNKTE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[900],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...analysis.commonPoints.map((point) => Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 8),
                    child: Text(
                      '• $point',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[800],
                      ),
                    ),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          // UNTERSCHIEDE
          if (analysis.differences.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.balance, color: Colors.orange[700], size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '⚖️ UNTERSCHIEDE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[900],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...analysis.differences.map((diff) => Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 8),
                    child: Text(
                      '• $diff',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[800],
                      ),
                    ),
                  )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Color _getScoreColor(int score) {
    if (score >= 75) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }
}
