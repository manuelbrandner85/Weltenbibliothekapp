/// 📂 DOKUMENT-ARCHIV — geleakte und FOIA-freigegebene Dokumente.
///
/// Quellen: Internet Archive (live), WikiLeaks-Suche, CIA Reading Room,
/// National Security Archive (GWU).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/thread.dart';
import '../widgets/kb_design.dart';

class DocumentsCard extends StatelessWidget {
  final List<LeakedDocument> docs;
  final bool loading;

  const DocumentsCard({super.key, required this.docs, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: KbDesign.glassBox(tint: const Color(0xFFFFB74D)),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.folder_open_rounded,
                  color: Color(0xFFFFB74D), size: 18),
              const SizedBox(width: 8),
              const Text(
                'DOKUMENT-ARCHIV',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (docs.isNotEmpty)
                Text(
                  '${docs.length} Quellen',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Geleakte & freigegebene Akten',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 14),
          if (loading)
            _buildLoading()
          else if (docs.isEmpty)
            _buildEmpty()
          else
            ...docs.map((d) => _buildDoc(context, d)),
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
              color: const Color(0xFFFFB74D),
            ),
          ),
        ),
      );

  Widget _buildEmpty() => Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Keine Dokumente gefunden.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
        ),
      );

  Widget _buildDoc(BuildContext context, LeakedDocument d) {
    return InkWell(
      onTap: () => _open(context, d.url),
      borderRadius: BorderRadius.circular(KbDesign.radiusSm),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(KbDesign.radiusSm),
          color: Colors.white.withValues(alpha: 0.04),
          border: Border.all(
            color: const Color(0xFFFFB74D).withValues(alpha: 0.18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _archiveBadge(d.archive),
                if (d.date != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    d.date!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 10,
                    ),
                  ),
                ],
                const Spacer(),
                Icon(Icons.open_in_new_rounded,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.5)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              d.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
            if (d.snippet != null && d.snippet!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                d.snippet!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
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

  Widget _archiveBadge(String archive) {
    final color = _archiveColor(archive);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: color.withValues(alpha: 0.18),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 0.7),
      ),
      child: Text(
        archive,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Color _archiveColor(String archive) {
    switch (archive) {
      case 'WikiLeaks':
        return const Color(0xFFEF5350);
      case 'CIA Reading Room':
        return const Color(0xFF66BB6A);
      case 'NSA Archive':
        return const Color(0xFFAB47BC);
      case 'ICIJ Leaks':
        return const Color(0xFFFFD54F);
      case 'DDoSecrets':
        return const Color(0xFFFF7043);
      case 'Cryptome':
        return const Color(0xFF80CBC4);
      case 'Internet Archive':
      default:
        return const Color(0xFF42A5F5);
    }
  }

  Future<void> _open(BuildContext context, String url) async {
    HapticFeedback.lightImpact();
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
