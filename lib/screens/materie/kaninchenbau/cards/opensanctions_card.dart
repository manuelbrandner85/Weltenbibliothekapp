/// 🚫 OPEN SANCTIONS — 100+ Quellen: EU, UN, US, UK, DE, Interpol, PEP-Listen
///
/// Quelle: OpenSanctions.org (kostenlos für nicht-kommerzielle Nutzung)
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/thread.dart';
import '../widgets/kb_design.dart';

class OpenSanctionsCard extends StatelessWidget {
  final List<SanctionResult> results;
  final bool loading;

  const OpenSanctionsCard(
      {super.key, required this.results, required this.loading});

  static const _accent = Color(0xFFFF5252);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: KbDesign.glassBox(tint: _accent, opacity: 0.12),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.gavel, color: _accent, size: 18),
            const SizedBox(width: 8),
            const Text('SANKTIONEN · PEP',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold)),
            const Spacer(),
            if (results.isNotEmpty)
              Text('${results.length} Treffer',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11)),
          ]),
          const SizedBox(height: 4),
          Text('OpenSanctions · EU · UN · OFAC · Interpol · 100+ Quellen',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45), fontSize: 11)),
          const SizedBox(height: 14),
          if (loading)
            _buildLoading()
          else if (results.isEmpty)
            _buildEmpty()
          else
            ...results.take(8).map(_buildResult),
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
        child: Text('Kein Eintrag in OpenSanctions-Datenbanken gefunden.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4))),
      );

  Widget _buildResult(SanctionResult r) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: r.url == null
            ? null
            : () async {
                HapticFeedback.lightImpact();
                final uri = Uri.tryParse(r.url!);
                if (uri != null && await canLaunchUrl(uri))
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: _accent.withValues(alpha: _borderOpacity(r.topics))),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(r.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              _schemaBadge(r.schema),
            ]),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 4, children: [
              ...r.topics.take(3).map((t) => _topicBadge(t)),
              ...r.countries.take(2).map((c) => _chip(c, Colors.white38)),
            ]),
            if (r.birthDate != null) ...[
              const SizedBox(height: 4),
              Text('*${r.birthDate}',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 10)),
            ],
            if (r.datasets.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Quellen: ${r.datasets.take(3).join(', ')}',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35), fontSize: 9),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ]),
        ),
      ),
    );
  }

  double _borderOpacity(List<String> topics) {
    if (topics.contains('sanction')) return 0.5;
    if (topics.contains('pep')) return 0.35;
    return 0.2;
  }

  Widget _schemaBadge(String schema) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: _accent.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(schema,
            style: const TextStyle(
                color: _accent, fontSize: 9, fontWeight: FontWeight.w700)),
      );

  Widget _topicBadge(String topic) {
    final isSanction = topic == 'sanction';
    final isPep = topic == 'pep';
    final color = isSanction
        ? _accent
        : isPep
            ? const Color(0xFFFFB300)
            : Colors.white54;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(4),
        border: isSanction
            ? Border.all(color: color.withValues(alpha: 0.4), width: 0.8)
            : null,
      ),
      child: Text(topic.toUpperCase(),
          style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5)),
    );
  }

  Widget _chip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4)),
        child: Text(label, style: TextStyle(color: color, fontSize: 9)),
      );
}
