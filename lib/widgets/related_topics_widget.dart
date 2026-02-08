import 'package:flutter/material.dart';

/// Related Topics Widget v7.5
/// 
/// Zeigt verwandte Themen und Vorschläge nach Recherche
class RelatedTopicsWidget extends StatelessWidget {
  final String currentQuery;
  final List<RelatedTopic> relatedTopics;
  final Function(String) onTopicTap;

  const RelatedTopicsWidget({
    super.key,
    required this.currentQuery,
    required this.relatedTopics,
    required this.onTopicTap,
  });

  @override
  Widget build(BuildContext context) {
    if (relatedTopics.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.explore,
                    color: Colors.purple,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🔗 Verwandte Themen',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Das könnte dich auch interessieren',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.grey, height: 1),

          // Topics Grid
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: relatedTopics.map((topic) {
                return _buildTopicCard(context, topic);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicCard(BuildContext context, RelatedTopic topic) {
    return InkWell(
      onTap: () => onTopicTap(topic.query),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minWidth: 140),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getCategoryColor(topic.category).withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon & Category
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getCategoryIcon(topic.category),
                  color: _getCategoryColor(topic.category),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    topic.category,
                    style: TextStyle(
                      fontSize: 11,
                      color: _getCategoryColor(topic.category),
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Topic Title
            Text(
              topic.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            
            // Relevance Score
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...List.generate(5, (index) {
                  return Icon(
                    index < topic.relevanceScore ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 14,
                  );
                }),
                const SizedBox(width: 6),
                Text(
                  '${(topic.relevanceScore * 20).toInt()}%',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'ufo':
        return Icons.public;
      case 'geheimgesellschaften':
        return Icons.groups;
      case 'technologie':
        return Icons.science;
      case 'geschichte':
        return Icons.history_edu;
      case 'politik':
        return Icons.gavel;
      case 'mind control':
        return Icons.psychology;
      default:
        return Icons.lightbulb;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'ufo':
        return Colors.green;
      case 'geheimgesellschaften':
        return Colors.purple;
      case 'technologie':
        return Colors.blue;
      case 'geschichte':
        return Colors.orange;
      case 'politik':
        return Colors.red;
      case 'mind control':
        return Colors.pink;
      default:
        return Colors.cyan;
    }
  }
}

// Related Topic Model
class RelatedTopic {
  final String query;
  final String title;
  final String category;
  final int relevanceScore; // 1-5 stars

  const RelatedTopic({
    required this.query,
    required this.title,
    required this.category,
    required this.relevanceScore,
  });

  factory RelatedTopic.fromJson(Map<String, dynamic> json) {
    return RelatedTopic(
      query: json['query'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      relevanceScore: json['relevanceScore'] as int? ?? 3,
    );
  }
}
