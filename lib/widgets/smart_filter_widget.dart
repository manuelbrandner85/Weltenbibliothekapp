// lib/widgets/smart_filter_widget.dart
// WELTENBIBLIOTHEK v9.0 - FEATURE 15: SMART FILTERS
// Tag-based filtering with multi-select and active filter indicators

import 'package:flutter/material.dart';
import '../services/auto_tagging_service.dart';

/// Smart Filter Widget
/// Provides tag-based filtering with category organization
class SmartFilterWidget extends StatefulWidget {
  final Function(List<String> activeTags)? onFilterChanged;
  final List<String>? initialTags;
  final bool showTrending;

  const SmartFilterWidget({
    super.key,
    this.onFilterChanged,
    this.initialTags,
    this.showTrending = true,
  });

  @override
  State<SmartFilterWidget> createState() => _SmartFilterWidgetState();
}

class _SmartFilterWidgetState extends State<SmartFilterWidget> {
  final Set<String> _activeTags = {};
  List<TrendingTag> _trendingTags = [];
  bool _isExpanded = false;
  bool _isLoadingTrending = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialTags != null) {
      _activeTags.addAll(widget.initialTags!);
    }
    if (widget.showTrending) {
      _loadTrendingTags();
    }
  }

  Future<void> _loadTrendingTags() async {
    setState(() => _isLoadingTrending = true);
    try {
      final tags = await AutoTaggingService().getTrendingTags(limit: 10);
      if (mounted) {
        setState(() {
          _trendingTags = tags;
          _isLoadingTrending = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingTrending = false);
      }
    }
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_activeTags.contains(tag)) {
        _activeTags.remove(tag);
      } else {
        _activeTags.add(tag);
      }
    });
    widget.onFilterChanged?.call(_activeTags.toList());
  }

  void _clearFilters() {
    setState(() => _activeTags.clear());
    widget.onFilterChanged?.call([]);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _activeTags.isEmpty 
              ? Colors.white10 
              : Colors.purple.withValues(alpha: 0.5),
          width: 1,
        ),
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
                  color: Colors.purple.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.filter_list,
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
                      'Smart Filter',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Nach Tags filtern',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Active Filter Count
              if (_activeTags.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_activeTags.length}',
                    style: const TextStyle(
                      color: Colors.purple,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              
              const SizedBox(width: 8),
              
              // Expand/Collapse Button
              IconButton(
                onPressed: () => setState(() => _isExpanded = !_isExpanded),
                icon: Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white70,
                ),
                tooltip: _isExpanded ? 'Einklappen' : 'Erweitern',
              ),
            ],
          ),
          
          // Active Tags (Always Visible)
          if (_activeTags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _activeTags.map((tag) => _buildActiveTagChip(tag)).toList(),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_activeTags.length} Filter aktiv',
                  style: const TextStyle(
                    color: Colors.purple,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.clear, size: 16, color: Colors.red),
                  label: const Text(
                    'Alle löschen',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
          
          // Expanded Content
          if (_isExpanded) ...[
            const Divider(color: Colors.white10),
            const SizedBox(height: 12),
            
            // Trending Tags Section
            if (widget.showTrending) ...[
              Row(
                children: [
                  const Icon(Icons.trending_up, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    'Trending Tags',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_isLoadingTrending)
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _trendingTags
                    .map((trending) => _buildTrendingTagChip(trending))
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],
            
            // Category Sections
            ..._buildCategorySections(),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveTagChip(String tag) {
    return Material(
      color: Colors.purple,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => _toggleTag(tag),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check, color: Colors.white, size: 14),
              const SizedBox(width: 4),
              Text(
                tag,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.close, color: Colors.white70, size: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendingTagChip(TrendingTag trending) {
    final isActive = _activeTags.contains(trending.tag);
    
    return Material(
      color: isActive 
          ? Colors.purple
          : Colors.orange.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => _toggleTag(trending.tag),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                trending.trendEmoji,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(width: 4),
              Text(
                trending.tag,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.orange,
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(${trending.count})',
                style: TextStyle(
                  color: isActive ? Colors.white70 : Colors.orange.shade700,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTagChip(String tag) {
    final isActive = _activeTags.contains(tag);
    
    return Material(
      color: isActive 
          ? Colors.purple
          : Colors.blue.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => _toggleTag(tag),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            tag,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.blue,
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCategorySections() {
    final categories = AutoTaggingService.getTagCategories();
    final widgets = <Widget>[];
    
    for (final entry in categories.entries) {
      widgets.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.key,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: entry.value.map((tag) => _buildCategoryTagChip(tag)).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    }
    
    return widgets;
  }
}
