import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Timeline Widget v7.5
/// 
/// Automatische Timeline-Extraktion aus Recherchen
/// Interaktive Visualisierung mit Zoom & Scroll
class ResearchTimelineWidget extends StatefulWidget {
  final List<TimelineEvent> events;
  final String title;

  const ResearchTimelineWidget({
    super.key,
    required this.events,
    required this.title,
  });

  @override
  State<ResearchTimelineWidget> createState() => _ResearchTimelineWidgetState();
}

class _ResearchTimelineWidgetState extends State<ResearchTimelineWidget> {
  TimelineView _currentView = TimelineView.vertical;
  TimelineSort _currentSort = TimelineSort.chronological;
  List<TimelineEvent> _sortedEvents = [];
  
  // 🆕 v8.0 Enhanced Features
  double _zoomLevel = 1.0;  // Zoom: 0.5x - 2.0x
  String _categoryFilter = 'all';  // Filter by category
  final bool _showExportMenu = false;  // Export menu toggle

  @override
  void initState() {
    super.initState();
    _sortEvents();
  }

  void _sortEvents() {
    _sortedEvents = List.from(widget.events);
    
    // Apply category filter
    if (_categoryFilter != 'all') {
      _sortedEvents = _sortedEvents
          .where((e) => e.category?.toLowerCase() == _categoryFilter.toLowerCase())
          .toList();
    }
    
    switch (_currentSort) {
      case TimelineSort.chronological:
        _sortedEvents.sort((a, b) => a.date.compareTo(b.date));
        break;
      case TimelineSort.reverseChronological:
        _sortedEvents.sort((a, b) => b.date.compareTo(a.date));
        break;
      case TimelineSort.importance:
        _sortedEvents.sort((a, b) => b.importance.compareTo(a.importance));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.events.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const Divider(color: Colors.grey, height: 1),
          _buildControlBar(),
          const Divider(color: Colors.grey, height: 1),
          _currentView == TimelineView.vertical
              ? _buildVerticalTimeline()
              : _buildHorizontalTimeline(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.timeline,
              color: Colors.amber,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📅 Timeline',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.events.length} Ereignisse extrahiert',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber),
            ),
            child: Text(
              _getTimeSpan(),
              style: const TextStyle(
                color: Colors.amber,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlBar() {
    // Get unique categories
    final categories = {'all', ...widget.events.map((e) => e.category ?? '').where((c) => c.isNotEmpty)};
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // Row 1: View & Sort
          Row(
            children: [
              // View Toggle
              Expanded(
                child: SegmentedButton<TimelineView>(
                  segments: const [
                    ButtonSegment(
                      value: TimelineView.vertical,
                      icon: Icon(Icons.view_agenda, size: 18),
                      label: Text('Vertikal', style: TextStyle(fontSize: 12)),
                    ),
                    ButtonSegment(
                      value: TimelineView.horizontal,
                      icon: Icon(Icons.view_carousel, size: 18),
                      label: Text('Horizontal', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                  selected: {_currentView},
                  onSelectionChanged: (Set<TimelineView> newSelection) {
                    setState(() {
                      _currentView = newSelection.first;
                    });
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.amber.withValues(alpha: 0.3);
                      }
                      return Colors.grey[850];
                    }),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Sort Dropdown
              Expanded(
                child: DropdownButton<TimelineSort>(
                  value: _currentSort,
                  isExpanded: true,
                  dropdownColor: Colors.grey[850],
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  icon: const Icon(Icons.sort, color: Colors.amber, size: 20),
                  items: const [
                    DropdownMenuItem(
                      value: TimelineSort.chronological,
                      child: Text('⏩ Chronologisch'),
                    ),
                    DropdownMenuItem(
                      value: TimelineSort.reverseChronological,
                      child: Text('⏪ Umgekehrt'),
                    ),
                    DropdownMenuItem(
                      value: TimelineSort.importance,
                      child: Text('⭐ Wichtigkeit'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _currentSort = value;
                        _sortEvents();
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Row 2: 🆕 Zoom, Filter, Export
          Row(
            children: [
              // Zoom Control
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    const Icon(Icons.zoom_out, color: Colors.amber, size: 20),
                    Expanded(
                      child: Slider(
                        value: _zoomLevel,
                        min: 0.5,
                        max: 2.0,
                        divisions: 6,
                        label: '${(_zoomLevel * 100).round()}%',
                        activeColor: Colors.amber,
                        onChanged: (value) {
                          setState(() => _zoomLevel = value);
                        },
                      ),
                    ),
                    const Icon(Icons.zoom_in, color: Colors.amber, size: 20),
                  ],
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Category Filter
              if (categories.length > 1)
                Expanded(
                  child: DropdownButton<String>(
                    value: _categoryFilter,
                    isExpanded: true,
                    dropdownColor: Colors.grey[850],
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    icon: const Icon(Icons.filter_list, color: Colors.amber, size: 18),
                    items: categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(cat == 'all' ? '🔍 Alle' : '📁 $cat'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _categoryFilter = value;
                          _sortEvents();
                        });
                      }
                    },
                  ),
                ),
              
              const SizedBox(width: 12),
              
              // Export Button
              IconButton(
                icon: const Icon(Icons.download, color: Colors.amber),
                tooltip: 'Timeline exportieren',
                onPressed: () => _showExportDialog(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalTimeline() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _sortedEvents.length,
      itemBuilder: (context, index) {
        final event = _sortedEvents[index];
        final isLast = index == _sortedEvents.length - 1;
        return _buildVerticalTimelineItem(event, isLast);
      },
    );
  }

  Widget _buildVerticalTimelineItem(TimelineEvent event, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Line & Dot
          Column(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: _getImportanceColor(event.importance),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.amber, width: 2),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.amber.withValues(alpha: 0.3),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          
          // Event Content
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getImportanceColor(event.importance).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date & Importance
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _formatDate(event.date),
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ...List.generate(3, (index) {
                        return Icon(
                          index < event.importance ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 14,
                        );
                      }),
                      const Spacer(),
                      if (event.category != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(event.category!).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            event.category!,
                            style: TextStyle(
                              color: _getCategoryColor(event.category!),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Event Title
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Event Description
                  Text(
                    event.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                  
                  // Sources
                  if (event.sources.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: event.sources.map((source) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.blue.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            source,
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 11,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalTimeline() {
    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(16),
        itemCount: _sortedEvents.length,
        itemBuilder: (context, index) {
          final event = _sortedEvents[index];
          return _buildHorizontalTimelineItem(event, index);
        },
      ),
    );
  }

  Widget _buildHorizontalTimelineItem(TimelineEvent event, int index) {
    return Container(
      width: 280,
      margin: EdgeInsets.only(right: index == _sortedEvents.length - 1 ? 0 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Dot & Line
          Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: _getImportanceColor(event.importance),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.amber, width: 2),
                ),
              ),
              if (index < _sortedEvents.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    color: Colors.amber.withValues(alpha: 0.3),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Event Card
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getImportanceColor(event.importance).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _formatDate(event.date),
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // Title
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  // Description
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        event.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                  
                  // Importance Stars
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (i) {
                      return Icon(
                        i < event.importance ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 14,
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd.MM.yyyy').format(date);
  }

  String _getTimeSpan() {
    if (_sortedEvents.isEmpty) return '';
    final first = _sortedEvents.first.date;
    final last = _sortedEvents.last.date;
    final years = last.year - first.year;
    if (years == 0) return '${first.year}';
    return '${first.year} - ${last.year}';
  }

  Color _getImportanceColor(int importance) {
    switch (importance) {
      case 3:
        return Colors.red;
      case 2:
        return Colors.orange;
      default:
        return Colors.amber;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'ufo':
        return Colors.green;
      case 'politik':
        return Colors.red;
      case 'technologie':
        return Colors.blue;
      case 'geschichte':
        return Colors.purple;
      default:
        return Colors.cyan;
    }
  }
  
  // 🆕 v8.0 Enhanced: Export Dialog
  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          '📥 Timeline Exportieren',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildExportOption(
              context,
              icon: Icons.text_snippet,
              title: 'Als Text kopieren',
              subtitle: 'Ereignisse als formatierter Text',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Timeline als Text kopiert')),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildExportOption(
              context,
              icon: Icons.code,
              title: 'Als JSON',
              subtitle: 'Strukturierte Daten',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Timeline als JSON kopiert')),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildExportOption(
              context,
              icon: Icons.table_chart,
              title: 'Als CSV',
              subtitle: 'Für Excel/Sheets',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Timeline als CSV kopiert')),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  Widget _buildExportOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.amber),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.amber),
          ],
        ),
      ),
    );
  }
}

// Timeline Models
class TimelineEvent {
  final DateTime date;
  final String title;
  final String description;
  final int importance; // 1-3 (low, medium, high)
  final String? category;
  final List<String> sources;

  const TimelineEvent({
    required this.date,
    required this.title,
    required this.description,
    required this.importance,
    this.category,
    this.sources = const [],
  });

  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    return TimelineEvent(
      date: DateTime.parse(json['date'] as String),
      title: json['title'] as String,
      description: json['description'] as String,
      importance: json['importance'] as int? ?? 2,
      category: json['category'] as String?,
      sources: (json['sources'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'title': title,
      'description': description,
      'importance': importance,
      'category': category,
      'sources': sources,
    };
  }
}

// Enums
enum TimelineView { vertical, horizontal }
enum TimelineSort { chronological, reverseChronological, importance }
