import 'package:flutter/material.dart';
import '../../services/ai_summarization_service.dart';

/// 🤖 SOURCE SUMMARY WIDGET
/// Displays AI-generated summaries for research sources
/// Features: TL;DR, Bullet-Points, Expandable content
class SourceSummaryWidget extends StatefulWidget {
  final String sourceText;
  final String? sourceTitle;
  final bool showBullets;
  final bool initiallyExpanded;
  
  const SourceSummaryWidget({
    super.key,
    required this.sourceText,
    this.sourceTitle,
    this.showBullets = true,
    this.initiallyExpanded = false,
  });
  
  @override
  State<SourceSummaryWidget> createState() => _SourceSummaryWidgetState();
}

class _SourceSummaryWidgetState extends State<SourceSummaryWidget> {
  final AiSummarizationService _aiService = AiSummarizationService();
  
  String? _tldrSummary;
  List<String>? _bulletPoints;
  bool _isLoading = false;
  bool _isExpanded = false;
  bool _showFullText = false;
  
  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    if (_isExpanded) {
      _loadSummary();
    }
  }
  
  Future<void> _loadSummary() async {
    if (_tldrSummary != null) return; // Already loaded
    
    setState(() => _isLoading = true);
    
    try {
      final tldr = await _aiService.generateTLDR(widget.sourceText);
      final bullets = widget.showBullets
          ? await _aiService.generateBulletPoints(widget.sourceText, maxPoints: 5)
          : null;
      
      if (mounted) {
        setState(() {
          _tldrSummary = tldr;
          _bulletPoints = bullets;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white.withValues(alpha: 0.05),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          ListTile(
            leading: const Icon(Icons.auto_awesome, color: Colors.cyan, size: 28),
            title: Text(
              widget.sourceTitle ?? 'KI-Zusammenfassung',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            trailing: IconButton(
              icon: Icon(
                _isExpanded ? Icons.expand_less : Icons.expand_more,
                color: Colors.white70,
              ),
              onPressed: () {
                setState(() => _isExpanded = !_isExpanded);
                if (_isExpanded && _tldrSummary == null) {
                  _loadSummary();
                }
              },
            ),
          ),
          
          // Content
          if (_isExpanded) ...[
            const Divider(color: Colors.white24, height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          children: [
                            CircularProgressIndicator(strokeWidth: 2),
                            SizedBox(height: 12),
                            Text(
                              'KI-Zusammenfassung wird generiert...',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // TL;DR Section
                        if (_tldrSummary != null) ...[
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.cyan.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'TL;DR',
                                  style: TextStyle(
                                    color: Colors.cyan,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _tldrSummary!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ],
                        
                        // Bullet Points Section
                        if (_bulletPoints != null && _bulletPoints!.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          const Text(
                            '📌 Wichtigste Punkte:',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._bulletPoints!.map((point) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '• ',
                                      style: TextStyle(
                                        color: Colors.cyan,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        point,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                        
                        // Show Full Text Button
                        if (!_showFullText) ...[
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: () {
                              setState(() => _showFullText = true);
                            },
                            icon: const Icon(Icons.article, size: 18),
                            label: const Text('Volltext anzeigen'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.cyan,
                            ),
                          ),
                        ],
                        
                        // Full Text
                        if (_showFullText) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '📄 Volltext:',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.sourceText,
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() => _showFullText = false);
                                  },
                                  icon: const Icon(Icons.close, size: 16),
                                  label: const Text('Schließen'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ],
      ),
    );
  }
}
