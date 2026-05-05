/// 🔬 SEMANTIC SCHOLAR — 200M+ Papiere mit Zitationsgraph (kostenlos, kein Key)
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/thread.dart';
import '../widgets/kb_design.dart';

class SemanticPapersCard extends StatelessWidget {
  final List<SemanticPaper> papers;
  final bool loading;

  const SemanticPapersCard({super.key, required this.papers, required this.loading});

  static const _accent = Color(0xFF7E57C2);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: KbDesign.glassBox(tint: _accent, opacity: 0.10),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.schema_rounded, color: _accent, size: 18),
            const SizedBox(width: 8),
            const Text('WISSENSCHAFT · ZITATIONEN',
                style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.bold)),
            const Spacer(),
            if (papers.isNotEmpty)
              Text('${papers.length}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
          ]),
          const SizedBox(height: 4),
          Text('Semantic Scholar · 200M+ Paper · AI-Zitationsgraph',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 11)),
          const SizedBox(height: 14),
          if (loading)
            _buildLoading()
          else if (papers.isEmpty)
            _buildEmpty()
          else
            ...papers.take(6).map(_buildPaper),
        ],
      ),
    );
  }

  Widget _buildLoading() => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(color: _accent, strokeWidth: 2)),
        ),
      );

  Widget _buildEmpty() => Padding(
        padding: const EdgeInsets.all(20),
        child: Text('Keine wissenschaftlichen Arbeiten gefunden.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4))),
      );

  Widget _buildPaper(SemanticPaper p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () async {
          HapticFeedback.lightImpact();
          final uri = Uri.tryParse(p.url);
          if (uri != null && await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _accent.withValues(alpha: 0.22)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Text(p.title,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    maxLines: 3, overflow: TextOverflow.ellipsis),
              ),
              if (p.openAccess != null)
                Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('OA', style: TextStyle(color: Colors.greenAccent, fontSize: 8, fontWeight: FontWeight.w800)),
                ),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.person_outline_rounded, color: Colors.white38, size: 11),
              const SizedBox(width: 4),
              Expanded(
                child: Text(p.authors,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 10),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              if (p.year != null) ...[
                const SizedBox(width: 8),
                Text('${p.year}',
                    style: TextStyle(color: _accent.withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.w600)),
              ],
            ]),
            const SizedBox(height: 4),
            Row(children: [
              _citBadge(Icons.format_quote_rounded, '${p.citations}', Colors.amber),
              const SizedBox(width: 8),
              if (p.influential > 0)
                _citBadge(Icons.star_rounded, '${p.influential} einflussreich', const Color(0xFFFF7043)),
            ]),
            if ((p.abstract_ ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(p.abstract_!,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 10, height: 1.4),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _citBadge(IconData icon, String label, Color color) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: color.withValues(alpha: 0.7), size: 11),
      const SizedBox(width: 3),
      Text(label, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 9, fontWeight: FontWeight.w600)),
    ],
  );
}
