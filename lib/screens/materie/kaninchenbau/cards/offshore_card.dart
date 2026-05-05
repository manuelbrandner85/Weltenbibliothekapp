/// 🌊 OFFSHORE-LEAKS — Panama Papers, Pandora Papers, Paradise Papers
///
/// Quelle: ICIJ Offshore Leaks Database (icij.org) — kostenlos, kein Key
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/thread.dart';
import '../widgets/kb_design.dart';

class OffshoreCard extends StatelessWidget {
  final List<OffshoreEntity> entities;
  final bool loading;

  const OffshoreCard({super.key, required this.entities, required this.loading});

  static const _accent = Color(0xFF00BCD4);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: KbDesign.glassBox(tint: _accent, opacity: 0.10),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.water_rounded, color: _accent, size: 18),
            const SizedBox(width: 8),
            const Text('OFFSHORE-LEAKS',
                style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.bold)),
            const Spacer(),
            if (entities.isNotEmpty)
              Text('${entities.length}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
          ]),
          const SizedBox(height: 4),
          Text('ICIJ · Panama Papers · Pandora Papers · Paradise Papers',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 11)),
          const SizedBox(height: 14),
          if (loading)
            _buildLoading()
          else if (entities.isEmpty)
            _buildEmpty()
          else
            ...entities.take(8).map(_buildEntity),
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
        child: Text('Kein Eintrag in den Offshore-Leaks-Datenbanken gefunden.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4))),
      );

  Widget _buildEntity(OffshoreEntity e) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: e.url == null
            ? null
            : () async {
                HapticFeedback.lightImpact();
                final uri = Uri.tryParse(e.url!);
                if (uri != null && await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _accent.withValues(alpha: 0.25)),
          ),
          child: Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accent.withValues(alpha: 0.14),
              ),
              alignment: Alignment.center,
              child: Icon(_iconForType(e.type), color: _accent, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.name,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Wrap(spacing: 6, children: [
                  if (e.type.isNotEmpty) _badge(e.type, _accent),
                  if (e.jurisdiction.isNotEmpty) _badge(e.jurisdiction, Colors.white38),
                  if (e.leakType.isNotEmpty) _badge(e.leakType, const Color(0xFFFF7043)),
                ]),
              ]),
            ),
            if (e.url != null) Icon(Icons.open_in_new_rounded, color: _accent, size: 14),
          ]),
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(text, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700)),
      );

  IconData _iconForType(String type) {
    final t = type.toLowerCase();
    if (t.contains('officer') || t.contains('person')) return Icons.person_rounded;
    if (t.contains('entity') || t.contains('company')) return Icons.business_rounded;
    if (t.contains('address')) return Icons.location_on_rounded;
    return Icons.account_balance_rounded;
  }
}
