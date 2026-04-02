import 'package:flutter/material.dart';

/// Timeline Event Model
class TimelineEvent {
  final int year;
  final String event;

  TimelineEvent({
    required this.year,
    required this.event,
  });

  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    return TimelineEvent(
      year: json['year'] as int,
      event: json['event'] as String,
    );
  }
}

/// Timeline Visualization Widget
class TimelineVisualization extends StatelessWidget {
  final List<TimelineEvent> events;
  final String title;

  const TimelineVisualization({
    super.key,
    required this.events,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const SizedBox.shrink();
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
                const Icon(Icons.timeline, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '📅 Timeline: $title',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...events.asMap().entries.map((entry) {
              final index = entry.key;
              final event = entry.value;
              final isLast = index == events.length - 1;
              
              return _buildTimelineItem(
                event: event,
                isLast: isLast,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required TimelineEvent event,
    required bool isLast,
  }) {
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
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.blue.withAlpha((0.3 * 255).round()),
                  ),
                ),
            ],
          ),
          
          const SizedBox(width: 12),
          
          // Event Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withAlpha((0.2 * 255).round()),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      event.year.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.event,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact Timeline Chip (for cards)
class CompactTimelineChip extends StatelessWidget {
  final List<TimelineEvent> events;

  const CompactTimelineChip({
    super.key,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const SizedBox.shrink();
    }

    final firstYear = events.first.year;
    final lastYear = events.last.year;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withAlpha((0.2 * 255).round()),
        border: Border.all(color: Colors.blue),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timeline, size: 14, color: Colors.blue),
          const SizedBox(width: 4),
          Text(
            '$firstYear - $lastYear',
            style: const TextStyle(
              fontSize: 11,
              color: Colors.blue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
