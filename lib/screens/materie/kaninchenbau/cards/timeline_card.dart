/// Zeitstrahl-Karte: horizontaler scrollbarer Verlauf.
library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/thread.dart';
import '../widgets/kb_design.dart';

class TimelineCard extends StatelessWidget {
  final List<TimelineEntry> entries;
  final bool loading;

  const TimelineCard({
    super.key,
    required this.entries,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: KbDesign.glassBox(tint: KbDesign.goldAccent),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_toggle_off_rounded,
                  color: KbDesign.goldAccent, size: 18),
              const SizedBox(width: 8),
              const Text(
                'ZEITSTRAHL',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'Keine Zeitstrahl-Einträge gefunden',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                ),
              ),
            )
          else
            SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: entries.length,
                itemBuilder: (_, i) => _TimelineNode(entry: entries[i]),
              ),
            ),
        ],
      ),
    );
  }
}

class _TimelineNode extends StatelessWidget {
  final TimelineEntry entry;
  const _TimelineNode({required this.entry});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: InkWell(
        onTap: () async {
          if (entry.sourceUrl != null) {
            final uri = Uri.tryParse(entry.sourceUrl!);
            if (uri != null) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${entry.year}',
                style: TextStyle(
                  color: KbDesign.goldAccent,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(height: 1, color: KbDesign.goldAccent.withValues(alpha: 0.4)),
              const SizedBox(height: 8),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: KbDesign.goldAccent,
                  boxShadow: [
                    BoxShadow(
                      color: KbDesign.goldAccent.withValues(alpha: 0.6),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  entry.title,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
