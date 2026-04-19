/// 📋 RESULT SUMMARY CARD WIDGET
/// 
/// Research result summary card with:
/// - Query and mode display
/// - Summary text with expand/collapse
/// - Confidence score with visual indicator
/// - Key findings preview (first 3)
/// - Source count and timestamp
/// - Share and save actions
/// - Expandable details
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/recherche_view_state.dart';

class ResultSummaryCard extends StatefulWidget {
  final RechercheResult result;
  final VoidCallback? onShare;
  final VoidCallback? onSave;
  final VoidCallback? onViewDetails;
  
  const ResultSummaryCard({
    super.key,
    required this.result,
    this.onShare,
    this.onSave,
    this.onViewDetails,
  });

  @override
  State<ResultSummaryCard> createState() => _ResultSummaryCardState();
}

class _ResultSummaryCardState extends State<ResultSummaryCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with query and mode
          _buildHeader(context),
          
          Divider(height: 1, color: Colors.grey[200]),
          
          // Summary section
          _buildSummarySection(context),
          
          // Key findings preview
          if (widget.result.keyFindings.isNotEmpty)
            _buildKeyFindingsPreview(context),
          
          Divider(height: 1, color: Colors.grey[200]),
          
          // Footer with metadata and actions
          _buildFooter(context),
        ],
      ),
    );
  }
  
  // ==========================================================================
  // HEADER
  // ==========================================================================
  
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Query text
          Row(
            children: [
              Icon(
                Icons.search,
                size: 20,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.result.query,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[900],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Mode badge and confidence
          Row(
            children: [
              // Mode badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getModeIcon(widget.result.mode),
                      size: 14,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getModeDisplayName(widget.result.mode),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              
              // Confidence indicator
              _buildConfidenceIndicator(context),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildConfidenceIndicator(BuildContext context) {
    final confidence = widget.result.confidence;
    final percentage = (confidence * 100).toInt();
    
    Color confidenceColor;
    IconData confidenceIcon;
    String confidenceLabel;
    
    if (confidence >= 0.8) {
      confidenceColor = Colors.green;
      confidenceIcon = Icons.verified;
      confidenceLabel = 'Hoch';
    } else if (confidence >= 0.6) {
      confidenceColor = Colors.orange;
      confidenceIcon = Icons.check_circle_outline;
      confidenceLabel = 'Mittel';
    } else {
      confidenceColor = Colors.red;
      confidenceIcon = Icons.info_outline;
      confidenceLabel = 'Niedrig';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: confidenceColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: confidenceColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            confidenceIcon,
            size: 14,
            color: confidenceColor,
          ),
          const SizedBox(width: 4),
          Text(
            '$confidenceLabel ($percentage%)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: confidenceColor,
            ),
          ),
        ],
      ),
    );
  }
  
  // ==========================================================================
  // SUMMARY SECTION
  // ==========================================================================
  
  Widget _buildSummarySection(BuildContext context) {
    final maxLines = _isExpanded ? null : 4;
    final showReadMore = widget.result.summary.length > 200;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Zusammenfassung',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          
          // Summary text
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: Text(
              widget.result.summary,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Colors.grey[800],
              ),
            ),
            secondChild: Text(
              widget.result.summary,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Colors.grey[800],
              ),
            ),
          ),
          
          // Read more button
          if (showReadMore)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Row(
                  children: [
                    Text(
                      _isExpanded ? 'Weniger anzeigen' : 'Mehr anzeigen',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    Icon(
                      _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: 18,
                      color: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  // ==========================================================================
  // KEY FINDINGS PREVIEW
  // ==========================================================================
  
  Widget _buildKeyFindingsPreview(BuildContext context) {
    final previewFindings = widget.result.keyFindings.take(3).toList();
    final remainingCount = widget.result.keyFindings.length - previewFindings.length;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 16,
                color: Colors.amber[700],
              ),
              const SizedBox(width: 6),
              Text(
                'Wichtige Erkenntnisse',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Preview findings
          ...previewFindings.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          
          // Show more findings indicator
          if (remainingCount > 0 && widget.onViewDetails != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: GestureDetector(
                onTap: widget.onViewDetails,
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Text(
                      '+$remainingCount weitere Erkenntnisse',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward,
                      size: 14,
                      color: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  // ==========================================================================
  // FOOTER
  // ==========================================================================
  
  Widget _buildFooter(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    final formattedDate = dateFormat.format(widget.result.timestamp);
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Metadata
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.source, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.result.sources.length} Quellen',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Action buttons
          Row(
            children: [
              // Share button
              if (widget.onShare != null)
                IconButton(
                  icon: const Icon(Icons.share, size: 20),
                  color: Colors.grey[700],
                  onPressed: widget.onShare,
                  tooltip: 'Teilen',
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              
              const SizedBox(width: 8),
              
              // Save button
              if (widget.onSave != null)
                IconButton(
                  icon: const Icon(Icons.bookmark_border, size: 20),
                  color: Colors.grey[700],
                  onPressed: widget.onSave,
                  tooltip: 'Speichern',
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              
              const SizedBox(width: 8),
              
              // View details button
              if (widget.onViewDetails != null)
                ElevatedButton.icon(
                  onPressed: widget.onViewDetails,
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('Details'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
  
  // ==========================================================================
  // HELPER METHODS
  // ==========================================================================
  
  IconData _getModeIcon(RechercheMode mode) {
    switch (mode) {
      case RechercheMode.simple:
        return Icons.search;
      case RechercheMode.advanced:
        return Icons.auto_awesome;
      case RechercheMode.deep:
        return Icons.psychology;
      case RechercheMode.conspiracy:
        return Icons.visibility;
      case RechercheMode.historical:
        return Icons.history_edu;
      case RechercheMode.scientific:
        return Icons.science;
    }
  }
  
  String _getModeDisplayName(RechercheMode mode) {
    switch (mode) {
      case RechercheMode.simple:
        return 'Simple';
      case RechercheMode.advanced:
        return 'Advanced';
      case RechercheMode.deep:
        return 'Deep Dive';
      case RechercheMode.conspiracy:
        return 'Conspiracy';
      case RechercheMode.historical:
        return 'Historical';
      case RechercheMode.scientific:
        return 'Scientific';
    }
  }
}
