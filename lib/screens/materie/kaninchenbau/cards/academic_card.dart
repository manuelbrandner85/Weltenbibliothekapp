/// 🎓 AKADEMIE-CARD — wissenschaftliche Papers + Citation-Counts.
///
/// Quelle: OpenAlex API (240M+ Papers, kein Key nötig).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/thread.dart';
import '../widgets/kb_design.dart';

class AcademicCard extends StatelessWidget {
  final List<AcademicPaper> papers;
  final bool loading;

  const AcademicCard({
    super.key,
    required this.papers,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: KbDesign.glassBox(tint: const Color(0xFF26A69A)),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.school_rounded,
                  color: Color(0xFF26A69A), size: 18),
              const SizedBox(width: 8),
              const Text(
                'AKADEMIE',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (papers.isNotEmpty)
                Text(
                  '${papers.length} Papers',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Was sagt die Wissenschaft?',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 14),
          if (loading)
            _buildLoading()
          else if (papers.isEmpty)
            _buildEmpty()
          else
            ...papers.map((p) => _buildPaper(context, p)),
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
              color: const Color(0xFF26A69A),
            ),
          ),
        ),
      );

  Widget _buildEmpty() => Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Keine wissenschaftlichen Papers gefunden.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
        ),
      );

  Widget _buildPaper(BuildContext context, AcademicPaper p) {
    return InkWell(
      onTap: p.url == null ? null : () => _open(p.url!),
      borderRadius: BorderRadius.circular(KbDesign.radiusSm),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(KbDesign.radiusSm),
          color: Colors.white.withValues(alpha: 0.04),
          border: Border.all(
            color: const Color(0xFF26A69A).withValues(alpha: 0.18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    p.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                ),
                if (p.url != null) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.open_in_new_rounded,
                      size: 13,
                      color: Colors.white.withValues(alpha: 0.5)),
                ],
              ],
            ),
            const SizedBox(height: 6),
            if (p.authors.isNotEmpty)
              Text(
                p.authors.join(', '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            const SizedBox(height: 6),
            Row(
              children: [
                if (p.year != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                    child: Text(
                      '${p.year}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: const Color(0xFF26A69A).withValues(alpha: 0.18),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.format_quote_rounded,
                          size: 10, color: Color(0xFF26A69A)),
                      const SizedBox(width: 3),
                      Text(
                        '${p.citations}',
                        style: const TextStyle(
                          color: Color(0xFF26A69A),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  p.source,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _open(String url) async {
    HapticFeedback.lightImpact();
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
