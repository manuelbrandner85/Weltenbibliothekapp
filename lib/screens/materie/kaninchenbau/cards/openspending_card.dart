/// 💸 OpenSpending — globale Haushaltsdaten.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/thread.dart';
import '../widgets/kb_design.dart';

class OpenSpendingCard extends StatelessWidget {
  final List<OpenSpendingEntry> items;
  final bool loading;
  const OpenSpendingCard({super.key, required this.items, required this.loading});

  static const _accent = Color(0xFFEF5350);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: KbDesign.glassBox(tint: _accent, opacity: 0.10),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.savings_rounded, color: _accent, size: 18),
          const SizedBox(width: 8),
          const Text('ÖFFENTLICHE HAUSHALTE',
              style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.bold)),
          const Spacer(),
          if (items.isNotEmpty)
            Text('${items.length}', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
        ]),
        const SizedBox(height: 4),
        Text('OpenSpending · weltweite Staatsausgaben',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 11)),
        const SizedBox(height: 14),
        if (loading)
          const Center(child: Padding(padding: EdgeInsets.all(24), child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(color: _accent, strokeWidth: 2))))
        else if (items.isEmpty)
          Padding(padding: const EdgeInsets.all(20), child: Text('Keine Haushaltsdatensätze zum Thema gefunden.', style: TextStyle(color: Colors.white.withValues(alpha: 0.4))))
        else
          ...items.take(8).map(_buildItem),
      ]),
    );
  }

  Widget _buildItem(OpenSpendingEntry e) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: e.url.isEmpty ? null : () async {
          HapticFeedback.lightImpact();
          final uri = Uri.tryParse(e.url);
          if (uri != null && await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(10), border: Border.all(color: _accent.withValues(alpha: 0.22))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.pie_chart_rounded, color: _accent, size: 15),
              const SizedBox(width: 8),
              Expanded(child: Text(e.title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 4, children: [
              if (e.country.isNotEmpty)
                Text(e.country, style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 10)),
              if (e.year.isNotEmpty)
                Text(e.year, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10)),
              if (e.amount > 0)
                Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2), decoration: BoxDecoration(color: _accent.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(4)), child: Text('${e.amount.toStringAsFixed(0)} ${e.currency}', style: const TextStyle(color: _accent, fontSize: 10, fontWeight: FontWeight.w700))),
            ]),
          ]),
        ),
      ),
    );
  }
}
