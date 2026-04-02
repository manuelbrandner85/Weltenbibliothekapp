import 'package:flutter/material.dart';
import '../services/backend_recherche_service.dart';

/// Source Type Badge Widget
/// 
/// Zeigt den Quellen-Typ an (Mainstream/Alternative/Unabhängig)
class SourceTypeBadge extends StatelessWidget {
  final SourceType sourceType;
  final bool showLabel;

  const SourceTypeBadge({
    super.key,
    required this.sourceType,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: sourceType.color.withValues(alpha: 0.2),
        border: Border.all(
          color: sourceType.color,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIcon(),
            color: sourceType.color,
            size: 16,
          ),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              sourceType.label,
              style: TextStyle(
                color: sourceType.color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getIcon() {
    switch (sourceType) {
      case SourceType.mainstream:
        return Icons.corporate_fare;
      case SourceType.alternative:
        return Icons.visibility;
      case SourceType.independent:
        return Icons.verified_user;
    }
  }
}

/// Source Card with Badge
class SourceCard extends StatelessWidget {
  final SearchSource source;

  const SourceCard({
    super.key,
    required this.source,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1A1A1A),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // Open URL - TODO: Add URL launcher
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      source.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SourceTypeBadge(sourceType: source.sourceType),
                ],
              ),
              
              // URL
              const SizedBox(height: 4),
              Text(
                source.url,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              // Snippet if available
              if (source.snippet.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  source.snippet,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
