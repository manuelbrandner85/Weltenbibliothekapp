/// ✅ FAKTEN-CHECK — Aggregierte Fact-Checks von Snopes/Politifact/Correctiv etc.
///
/// Quelle: Google Fact Check Tools API (mit Key) oder Fallback-Such-Links.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/thread.dart';
import '../widgets/kb_design.dart';

class FactCheckCard extends StatelessWidget {
  final List<FactCheck> checks;
  final bool loading;

  const FactCheckCard({
    super.key,
    required this.checks,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: KbDesign.glassBox(tint: const Color(0xFF66BB6A)),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fact_check_rounded,
                  color: Color(0xFF66BB6A), size: 18),
              const SizedBox(width: 8),
              const Text(
                'FAKTEN-CHECK',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Was sagen die Fact-Checker?',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 14),
          if (loading)
            _buildLoading()
          else if (checks.isEmpty)
            _buildEmpty()
          else
            ...checks.map((c) => _buildCheck(context, c)),
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
              color: const Color(0xFF66BB6A),
            ),
          ),
        ),
      );

  Widget _buildEmpty() => Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Keine Fact-Checks gefunden.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
        ),
      );

  Widget _buildCheck(BuildContext context, FactCheck c) {
    final color = _verdictColor(c.verdict);
    return InkWell(
      onTap: c.url == null ? null : () => _open(c.url!),
      borderRadius: BorderRadius.circular(KbDesign.radiusSm),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(KbDesign.radiusSm),
          color: Colors.white.withValues(alpha: 0.04),
          border: Border.all(
            color: color.withValues(alpha: 0.18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: color.withValues(alpha: 0.18),
                  ),
                  child: Text(
                    c.verdict,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  c.publisher,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
                if (c.url != null) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.open_in_new_rounded,
                      size: 13,
                      color: Colors.white.withValues(alpha: 0.5)),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(
              c.claim,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.3,
              ),
            ),
            if (c.claimant != null && c.claimant!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '— ${c.claimant!}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _verdictColor(String verdict) {
    final v = verdict.toLowerCase();
    if (v.contains('false') || v.contains('falsch') || v.contains('wrong')) {
      return const Color(0xFFEF5350);
    }
    if (v.contains('true') || v.contains('wahr') || v.contains('correct')) {
      return const Color(0xFF66BB6A);
    }
    if (v.contains('mixed') ||
        v.contains('partly') ||
        v.contains('teilweise')) {
      return const Color(0xFFFFB74D);
    }
    return const Color(0xFF42A5F5);
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
