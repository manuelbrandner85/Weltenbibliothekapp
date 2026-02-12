import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TimelineEvent {
  final String title;
  final String date;
  final String description;
  final List<String> sources;
  final Color color;

  TimelineEvent({
    required this.title,
    required this.date,
    required this.description,
    required this.sources,
    required this.color,
  });
}

class ResearchTimelineScreen extends StatelessWidget {
  const ResearchTimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final events = _getTimelineEvents();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          final isLast = index == events.length - 1;
          return _buildTimelineItem(context, event, isLast);
        },
      ),
    );
  }

  Widget _buildTimelineItem(BuildContext context, TimelineEvent event, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Indicator
          Column(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: event.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: event.color, width: 3),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: event.color.withValues(alpha: 0.3),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Event Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: event.color.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date
                  Text(
                    event.date,
                    style: TextStyle(
                      color: event.color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Title
                  Text(
                    event.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Description
                  Text(
                    event.description,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                  if (event.sources.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: event.sources.map((source) {
                        return InkWell(
                          onTap: () => _launchUrl(source),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: event.color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.link, color: event.color, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  'Quelle',
                                  style: TextStyle(
                                    color: event.color,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
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

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  List<TimelineEvent> _getTimelineEvents() {
    return [
      TimelineEvent(
        title: 'Jeffrey Epstein Verhaftung',
        date: '6. Juli 2019',
        description: 'Epstein wird in New Jersey verhaftet wegen Sexhandel mit Minderjährigen',
        sources: ['https://jmail.world/'],
        color: Colors.red,
      ),
      TimelineEvent(
        title: 'Epstein Tod im Gefängnis',
        date: '10. August 2019',
        description: 'Jeffrey Epstein wird tot in seiner Zelle gefunden - offiziell Selbstmord',
        sources: ['https://jmail.world/'],
        color: Colors.orange,
      ),
      TimelineEvent(
        title: 'Ghislaine Maxwell Verhaftung',
        date: '2. Juli 2020',
        description: 'Maxwell wird in New Hampshire verhaftet',
        sources: ['https://jmail.world/'],
        color: Colors.yellow,
      ),
      TimelineEvent(
        title: 'Panama Papers Leak',
        date: '3. April 2016',
        description: '11.5 Millionen Dokumente über Offshore-Steuerhinterziehung',
        sources: ['https://www.icij.org/investigations/panama-papers/'],
        color: Colors.green,
      ),
      TimelineEvent(
        title: 'WikiLeaks Vault 7',
        date: '7. März 2017',
        description: 'CIA Hacking-Tools veröffentlicht',
        sources: ['https://wikileaks.org/vault7/'],
        color: Colors.blue,
      ),
      TimelineEvent(
        title: 'Snowden NSA Leaks',
        date: '6. Juni 2013',
        description: 'Globales Überwachungsprogramm aufgedeckt',
        sources: ['https://www.theguardian.com/world/edward-snowden'],
        color: Colors.purple,
      ),
    ];
  }
}
