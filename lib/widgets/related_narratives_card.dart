// lib/widgets/related_narratives_card.dart
// WELTENBIBLIOTHEK v9.0 - SPRINT 2: AI RESEARCH ASSISTANT
// Feature 14.3: Related Narratives Widget
// Display related narratives with similarity scores

import 'package:flutter/material.dart';
import '../models/narrative.dart';
import '../services/narrative_connection_service.dart';

/// Related Narratives Card Widget
/// Shows narratives related to the current one with similarity scoring
class RelatedNarrativesCard extends StatelessWidget {
  final Narrative currentNarrative;
  final Function(Narrative)? onNarrativeTap;
  final int maxItems;

  const RelatedNarrativesCard({
    super.key,
    required this.currentNarrative,
    this.onNarrativeTap,
    this.maxItems = 5,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<NarrativeConnection>>(
      future: NarrativeConnectionService().findRelatedNarratives(
        currentNarrative,
        limit: maxItems,
        minSimilarity: 0.3,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard();
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyCard();
        }

        final connections = snapshot.data!;

        return Card(
          color: const Color(0xFF1A1A1A),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.hub_outlined,
                        color: Colors.purple,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ähnliche Themen',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Entdecke verwandte Narrative',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Count Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${connections.length}',
                        style: const TextStyle(
                          color: Colors.purple,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Connection List
                ...connections.map((connection) => _buildConnectionItem(context, connection)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildConnectionItem(BuildContext context, NarrativeConnection connection) {
    return InkWell(
      onTap: () => onNarrativeTap?.call(connection.targetNarrative),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getSimilarityColor(connection.similarityScore).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Similarity Score
            Row(
              children: [
                // Connection Type Icon
                Text(
                  connection.connectionType.icon,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 8),
                
                // Title
                Expanded(
                  child: Text(
                    connection.targetNarrative.titel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Similarity Score
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getSimilarityColor(connection.similarityScore).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getSimilarityColor(connection.similarityScore),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${connection.similarityPercent}%',
                    style: TextStyle(
                      color: _getSimilarityColor(connection.similarityScore),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Connection Type Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    connection.connectionType.label,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Strength Label
                Text(
                  connection.strengthLabel,
                  style: TextStyle(
                    color: _getSimilarityColor(connection.similarityScore).withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            
            // Shared Tags
            if (connection.sharedTags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: connection.sharedTags.take(3).map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        color: Colors.purple,
                        fontSize: 9,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Card(
      color: const Color(0xFF1A1A1A),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const CircularProgressIndicator(
              color: Colors.purple,
              strokeWidth: 2,
            ),
            const SizedBox(height: 16),
            Text(
              'Suche ähnliche Narrative...',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Card(
      color: const Color(0xFF1A1A1A),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(
              Icons.hub_outlined,
              color: Colors.grey.shade600,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Keine ähnlichen Narrative gefunden',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getSimilarityColor(double similarity) {
    if (similarity >= 0.8) return Colors.green;
    if (similarity >= 0.6) return Colors.lightGreen;
    if (similarity >= 0.4) return Colors.orange;
    return Colors.red;
  }
}
