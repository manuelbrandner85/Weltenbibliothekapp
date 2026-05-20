/// 🏢 FIRMEN-REGISTER — OpenCorporates (200M) + GLEIF LEI (100% kostenlos)
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/thread.dart';
import '../widgets/kb_design.dart';

class CompaniesCard extends StatelessWidget {
  final List<CompanyEntry> companies;
  final bool loading;

  const CompaniesCard(
      {super.key, required this.companies, required this.loading});

  static const _accent = Color(0xFF26A69A);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: KbDesign.glassBox(tint: _accent, opacity: 0.10),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.domain, color: _accent, size: 18),
            const SizedBox(width: 8),
            const Text('FIRMEN-REGISTER',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold)),
            const Spacer(),
            if (companies.isNotEmpty)
              Text('${companies.length}',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11)),
          ]),
          const SizedBox(height: 4),
          Text('OpenCorporates · GLEIF LEI · 200M+ globale Registrierungen',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45), fontSize: 11)),
          const SizedBox(height: 14),
          if (loading)
            _buildLoading()
          else if (companies.isEmpty)
            _buildEmpty()
          else
            ...companies.take(8).map(_buildEntry),
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
        child: Text('Keine Firmenregistrierung gefunden.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4))),
      );

  Widget _buildEntry(CompanyEntry c) {
    final statusColor = c.status.toLowerCase().contains('active')
        ? Colors.greenAccent
        : c.status.toLowerCase().contains('dissolv') ||
                c.status.toLowerCase().contains('inactiv')
            ? Colors.redAccent
            : Colors.white38;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: c.url == null
            ? null
            : () async {
                HapticFeedback.lightImpact();
                final uri = Uri.tryParse(c.url!);
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
            border: Border.all(color: _accent.withValues(alpha: 0.2)),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(c.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              _sourceBadge(c.source),
            ]),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 4, children: [
              if (c.jurisdiction.isNotEmpty) _chip(c.jurisdiction, _accent),
              if (c.type.isNotEmpty) _chip(c.type, Colors.white38),
              if (c.status.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(c.status,
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w700)),
                ),
              if (c.lei != null)
                _chip(
                    'LEI: ${c.lei!.substring(0, 8)}…', const Color(0xFF7986CB)),
            ]),
            if (c.registered != null && c.registered!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Gegründet: ${c.registered}',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 10)),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _sourceBadge(String source) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: _accent.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(source,
            style: const TextStyle(
                color: _accent,
                fontSize: 8,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8)),
      );

  Widget _chip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 9)),
      );
}
