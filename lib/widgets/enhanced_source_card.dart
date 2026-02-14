import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Enhanced Source Card - Expandable Quelle mit vollständigem Text
class EnhancedSourceCard extends StatefulWidget {
  final Map<String, dynamic> source;

  const EnhancedSourceCard({
    super.key,
    required this.source,
  });

  @override
  State<EnhancedSourceCard> createState() => _EnhancedSourceCardState();
}

class _EnhancedSourceCardState extends State<EnhancedSourceCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final String title = widget.source['title'] ?? 'Quelle';
    final String url = widget.source['url'] ?? '';
    final String snippet = widget.source['snippet'] ?? '';
    final String category = widget.source['category'] ?? 'Unbekannt';
    final Map<String, dynamic>? metadata = widget.source['metadata'];
    final String? domain = metadata?['domain'];
    final String? credibility = metadata?['credibility'];

    // Count lines to determine if "Show More" is needed
    final textSpan = TextSpan(
      text: snippet,
      style: const TextStyle(fontSize: 14),
    );
    final textPainter = TextPainter(
      text: textSpan,
      maxLines: 5,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: MediaQuery.of(context).size.width - 64);
    final bool needsExpansion = textPainter.didExceedMaxLines;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER: Titel + Icon
            InkWell(
              onTap: () => _launchUrl(context, url),
              child: Row(
                children: [
                  _buildCredibilityIcon(credibility),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.open_in_new, size: 20, color: Colors.grey),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // METADATA: Domain + Kategorie
            Row(
              children: [
                if (domain != null) ...[
                  const Icon(Icons.language, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    domain,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(category).withAlpha((0.2 * 255).round()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _getCategoryColor(category),
                    ),
                  ),
                ),
              ],
            ),
            
            if (snippet.isNotEmpty) ...[
              const SizedBox(height: 12),
              
              // ✅ EXPANDABLE TEXT - Shows full content
              Text(
                snippet,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.5,
                ),
                maxLines: _isExpanded ? null : 5,
                overflow: _isExpanded ? TextOverflow.visible : TextOverflow.fade,
              ),
              
              // ✅ SHOW MORE / SHOW LESS BUTTON
              if (needsExpansion) ...[
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isExpanded ? 'Weniger anzeigen' : 'Mehr anzeigen',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        size: 20,
                        color: Colors.blueAccent,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCredibilityIcon(String? credibility) {
    switch (credibility) {
      case 'official':
        return const Icon(Icons.verified, color: Colors.blue, size: 24);
      case 'investigative':
        return const Icon(Icons.fact_check, color: Colors.purple, size: 24);
      case 'alternative':
        return const Icon(Icons.source, color: Colors.orange, size: 24);
      case 'mainstream':
        return const Icon(Icons.newspaper, color: Colors.grey, size: 24);
      default:
        return const Icon(Icons.article, color: Colors.green, size: 24);
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'government':
      case 'regierung':
        return Colors.blue;
      case 'investigative journalism':
        return Colors.purple;
      case 'alternative media':
      case 'alternative medien':
        return Colors.orange;
      case 'archives':
      case 'archive':
        return Colors.brown;
      case 'science':
      case 'wissenschaft':
        return Colors.teal;
      case 'video':
        return Colors.red;
      case 'community':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _launchUrl(BuildContext context, String url) async {
    try {
      final Uri uri = Uri.parse(url);
      
      if (!await canLaunchUrl(uri)) {
        throw 'Kann URL nicht öffnen: $url';
      }
      
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Fehler beim Öffnen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
