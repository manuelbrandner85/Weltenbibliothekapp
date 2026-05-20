/// 🧬 PUBMED — 35M+ biomedizinische Studien (NCBI/NIH, kostenlos, kein Key)
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/thread.dart';
import '../widgets/kb_design.dart';

class PubMedCard extends StatelessWidget {
  final List<PubMedPaper> papers;
  final bool loading;

  const PubMedCard({super.key, required this.papers, required this.loading});

  static const _accent = Color(0xFF42A5F5);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: KbDesign.glassBox(tint: _accent, opacity: 0.10),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.biotech, color: _accent, size: 18),
            const SizedBox(width: 8),
            const Text('BIOMEDIZIN · STUDIEN',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold)),
            const Spacer(),
            if (papers.isNotEmpty)
              Text('${papers.length}',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11)),
          ]),
          const SizedBox(height: 4),
          Text('PubMed NCBI · 35M+ Studien · NIH · Peer-reviewed',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45), fontSize: 11)),
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
          child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(color: _accent, strokeWidth: 2)),
        ),
      );

  Widget _buildEmpty() => Padding(
        padding: const EdgeInsets.all(20),
        child: Text('Keine biomedizinischen Studien gefunden.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4))),
      );

  Widget _buildPaper(PubMedPaper p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () async {
          HapticFeedback.lightImpact();
          final uri = Uri.tryParse(p.url);
          if (uri != null && await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _accent.withValues(alpha: 0.22)),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('PMID',
                    style: const TextStyle(
                        color: _accent,
                        fontSize: 8,
                        fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(p.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.person_outline, color: Colors.white38, size: 11),
              const SizedBox(width: 4),
              Expanded(
                child: Text(p.authors,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
            const SizedBox(height: 3),
            Row(children: [
              Icon(Icons.science, color: Colors.white38, size: 11),
              const SizedBox(width: 4),
              Expanded(
                child: Text(p.journal,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Text(p.year,
                  style: TextStyle(
                      color: _accent.withValues(alpha: 0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w600)),
            ]),
            if (p.doi != null) ...[
              const SizedBox(height: 3),
              Text('DOI: ${p.doi}',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.25), fontSize: 9),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ]),
        ),
      ),
    );
  }
}
