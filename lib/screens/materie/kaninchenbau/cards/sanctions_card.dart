/// 🚫 SANKTIONEN — OFAC, EU, UK, UN Listen.
///
/// Quelle: OpenSanctions API (kein Key).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/thread.dart';
import '../widgets/kb_design.dart';

class SanctionsCard extends StatelessWidget {
  final List<SanctionEntry> entries;
  final bool loading;

  const SanctionsCard({
    super.key,
    required this.entries,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: KbDesign.glassBox(tint: const Color(0xFFEF5350)),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.gpp_bad,
                  color: Color(0xFFEF5350), size: 18),
              const SizedBox(width: 8),
              const Text(
                'SANKTIONEN',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (entries.isNotEmpty)
                Text(
                  '${entries.length} Treffer',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'OFAC · EU · UK · UN — wer ist gelistet?',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 14),
          if (loading)
            _buildLoading()
          else if (entries.isEmpty)
            _buildEmpty()
          else
            ...entries.map((e) => _buildEntry(context, e)),
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
              color: const Color(0xFFEF5350),
            ),
          ),
        ),
      );

  Widget _buildEmpty() => Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Keine Sanktionseinträge gefunden — gut so?',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
        ),
      );

  Widget _buildEntry(BuildContext context, SanctionEntry e) {
    return InkWell(
      onTap: e.url == null ? null : () => _open(e.url!),
      borderRadius: BorderRadius.circular(KbDesign.radiusSm),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(KbDesign.radiusSm),
          color: Colors.white.withValues(alpha: 0.04),
          border: Border.all(
            color: const Color(0xFFEF5350).withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    e.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (e.url != null)
                  Icon(Icons.open_in_new_rounded,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.5)),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (e.type != null && e.type!.isNotEmpty)
                  _badge(e.type!, Colors.white.withValues(alpha: 0.5)),
                if (e.country != null && e.country!.isNotEmpty)
                  _badge(e.country!.toUpperCase(),
                      Colors.white.withValues(alpha: 0.5)),
                ...e.sanctioningAuthorities
                    .map((a) => _badge(a, const Color(0xFFEF5350))),
              ],
            ),
            if (e.reason != null && e.reason!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                e.reason!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: color.withValues(alpha: 0.18),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 0.7),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      );

  Future<void> _open(String url) async {
    HapticFeedback.lightImpact();
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
