import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Related Narratives Graph Widget
class RelatedNarrativesGraph extends StatefulWidget {
  final String narrativeId;
  final String narrativeTitle;

  const RelatedNarrativesGraph({
    super.key,
    required this.narrativeId,
    required this.narrativeTitle,
  });

  @override
  State<RelatedNarrativesGraph> createState() => _RelatedNarrativesGraphState();
}

class _RelatedNarrativesGraphState extends State<RelatedNarrativesGraph> {
  static const String _backendUrl = 'https://api-backend.brandy13062.workers.dev';
  
  List<Map<String, dynamic>> _relatedNarratives = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRelated();
  }

  Future<void> _loadRelated() async {
    try {
      final response = await http.get(
        Uri.parse('$_backendUrl/api/narrative/${widget.narrativeId}'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _relatedNarratives = List<Map<String, dynamic>>.from(
            data['related'] ?? [],
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading related: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_relatedNarratives.isEmpty) {
      return const Center(
        child: Text('Keine verwandten Narrative gefunden'),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.hub, color: Colors.purple),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '🔗 Verwandte Narrative',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Center Node
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.narrativeTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Related Nodes
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _relatedNarratives.map((narrative) {
                return _buildRelatedNode(narrative);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelatedNode(Map<String, dynamic> narrative) {
    final title = narrative['title'] as String? ?? 'Unknown';
    
    return InkWell(
      onTap: () => _openNarrative(narrative),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.purple.withAlpha((0.2 * 255).round()),
          border: Border.all(color: Colors.purple),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.link, size: 16, color: Colors.purple),
            const SizedBox(width: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.purple,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openNarrative(Map<String, dynamic> narrative) {
    // Navigate to narrative detail
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Öffne: ${narrative['title']}')),
    );
  }
}
