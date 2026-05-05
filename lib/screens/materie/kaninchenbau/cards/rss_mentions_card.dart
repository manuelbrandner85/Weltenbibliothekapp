/// 📰 ECHTE MEDIEN-MENTIONS — RSS aus 11 Quellen, gefiltert nach Topic.
///
/// Quelle: Worker /api/rss/aggregate.
/// Lens-Tags: establishment, alt-left, alt-right, state-russia, wire …
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/thread.dart';
import '../widgets/kb_design.dart';

class RssMentionsCard extends StatelessWidget {
  final List<RssItem> items;
  final bool loading;

  const RssMentionsCard({
    super.key,
    required this.items,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: KbDesign.glassBox(tint: const Color(0xFF90CAF9)),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rss_feed_rounded,
                  color: Color(0xFF90CAF9), size: 18),
              const SizedBox(width: 8),
              const Text(
                'AKTUELLE MEDIEN',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (items.isNotEmpty)
                Text(
                  '${items.length} Artikel',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Live-RSS aus 11 Quellen — Spiegel/FAZ/Tichy/NDS/RT/Reuters/...',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 14),
          if (loading)
            _buildLoading()
          else if (items.isEmpty)
            _buildEmpty()
          else
            ...items.take(15).map((i) => _buildItem(context, i)),
        ],
      ),
    );
  }

  Widget _buildLoading() => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: const Color(0xFF90CAF9),
            ),
          ),
        ),
      );

  Widget _buildEmpty() => Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Keine aktuellen Mentions in den überwachten Feeds.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
        ),
      );

  Widget _buildItem(BuildContext context, RssItem i) {
    final lensColor = _lensColor(i.lens);
    return InkWell(
      onTap: () async {
        HapticFeedback.lightImpact();
        final uri = Uri.tryParse(i.url);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      borderRadius: BorderRadius.circular(KbDesign.radiusSm),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(KbDesign.radiusSm),
          color: Colors.white.withValues(alpha: 0.04),
          border: Border(
            left: BorderSide(color: lensColor, width: 3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  i.source,
                  style: TextStyle(
                    color: lensColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: lensColor.withValues(alpha: 0.15),
                  ),
                  child: Text(
                    _lensLabel(i.lens),
                    style: TextStyle(
                      color: lensColor.withValues(alpha: 0.9),
                      fontSize: 8.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(Icons.open_in_new_rounded,
                    size: 12, color: Colors.white.withValues(alpha: 0.4)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              i.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _lensColor(String lens) {
    if (lens.contains('alt')) return const Color(0xFFFF7043);
    if (lens.contains('state')) return const Color(0xFFEF5350);
    if (lens.contains('wire')) return const Color(0xFF80CBC4);
    return const Color(0xFF90CAF9);
  }

  String _lensLabel(String lens) {
    if (lens.contains('alt-left')) return 'ALT LINKS';
    if (lens.contains('alt-right')) return 'ALT RECHTS';
    if (lens.contains('alt')) return 'ALTERNATIV';
    if (lens.contains('state-russia')) return 'STAATSMEDIEN';
    if (lens.contains('wire')) return 'NACHRICHTENAGENTUR';
    if (lens.contains('left')) return 'ESTABLISHMENT LINKS';
    if (lens.contains('right')) return 'ESTABLISHMENT RECHTS';
    return 'ESTABLISHMENT';
  }
}
