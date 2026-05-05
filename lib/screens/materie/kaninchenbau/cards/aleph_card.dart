/// 📁 OCCRP ALEPH — 300+ investigative Dokument-Sammlungen
///
/// FinCEN Files, LuxLeaks, Suisse Secrets, Pandora Papers, ...
/// Quelle: aleph.occrp.org (kostenlos mit optionalem Key für mehr Requests)
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/thread.dart';
import '../widgets/kb_design.dart';

class AlephCard extends StatelessWidget {
  final List<AlephDocument> documents;
  final bool loading;

  const AlephCard({super.key, required this.documents, required this.loading});

  static const _accent = Color(0xFFFF7043);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: KbDesign.glassBox(tint: _accent, opacity: 0.10),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.folder_special_rounded, color: _accent, size: 18),
            const SizedBox(width: 8),
            const Text('INVESTIGATIV-ARCHIVE',
                style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.bold)),
            const Spacer(),
            if (documents.isNotEmpty)
              Text('${documents.length}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
          ]),
          const SizedBox(height: 4),
          Text('OCCRP Aleph · 300+ Leak-Sammlungen · FinCEN · LuxLeaks · Suisse Secrets',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 11)),
          const SizedBox(height: 14),
          if (loading)
            _buildLoading()
          else if (documents.isEmpty)
            _buildEmpty()
          else
            ...documents.take(8).map(_buildDoc),
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
        child: Text('Kein Eintrag in investigativen Dokument-Archiven.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4))),
      );

  Widget _buildDoc(AlephDocument d) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: d.url == null
            ? null
            : () async {
                HapticFeedback.lightImpact();
                final uri = Uri.tryParse(d.url!);
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
            Row(children: [
              Icon(_iconForSchema(d.schema), color: _accent, size: 15),
              const SizedBox(width: 8),
              Expanded(
                child: Text(d.name,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              if (d.collection.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(d.collection,
                      style: const TextStyle(color: _accent, fontSize: 9, fontWeight: FontWeight.w700),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 6),
              ],
              if (d.country.isNotEmpty)
                Text(d.country,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10)),
              if (d.date != null) ...[
                const SizedBox(width: 8),
                Text(d.date!.length > 10 ? d.date!.substring(0, 10) : d.date!,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10)),
              ],
            ]),
            if (d.summary != null && d.summary!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(d.summary!,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11, height: 1.4),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ]),
        ),
      ),
    );
  }

  IconData _iconForSchema(String schema) {
    final s = schema.toLowerCase();
    if (s.contains('person')) return Icons.person_rounded;
    if (s.contains('company') || s.contains('legal')) return Icons.business_rounded;
    if (s.contains('document') || s.contains('email')) return Icons.description_rounded;
    if (s.contains('payment') || s.contains('asset')) return Icons.account_balance_wallet_rounded;
    return Icons.folder_rounded;
  }
}
