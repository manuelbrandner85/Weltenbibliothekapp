/// 💰 USASpending — US-Bundesausgaben (Verträge, Zuschüsse).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/thread.dart';
import '../widgets/kb_design.dart';

class UsaSpendingCard extends StatelessWidget {
  final List<UsaSpendingAward> items;
  final bool loading;
  const UsaSpendingCard(
      {super.key, required this.items, required this.loading});

  static const _accent = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: KbDesign.glassBox(tint: _accent, opacity: 0.10),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.attach_money, color: _accent, size: 18),
            const SizedBox(width: 8),
            const Text('US-BUNDESAUSGABEN',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold)),
            const Spacer(),
            if (items.isNotEmpty)
              Text('${items.length}',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11)),
          ]),
          const SizedBox(height: 4),
          Text('USASpending · Verträge & Zuschüsse der US-Regierung',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45), fontSize: 11)),
          const SizedBox(height: 14),
          if (loading)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(24),
                    child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                            color: _accent, strokeWidth: 2))))
          else if (items.isEmpty)
            Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Keine US-Ausgaben zu diesem Thema gefunden.',
                    style:
                        TextStyle(color: Colors.white.withValues(alpha: 0.4))))
          else
            ...items.take(8).map(_buildItem),
        ],
      ),
    );
  }

  String _money(num n) {
    if (n >= 1e9) return '${(n / 1e9).toStringAsFixed(1)} Mrd \$';
    if (n >= 1e6) return '${(n / 1e6).toStringAsFixed(1)} Mio \$';
    if (n >= 1e3) return '${(n / 1e3).toStringAsFixed(0)} Tsd \$';
    return '${n.toStringAsFixed(0)} \$';
  }

  Widget _buildItem(UsaSpendingAward a) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: a.url.isEmpty
            ? null
            : () async {
                HapticFeedback.lightImpact();
                final uri = Uri.tryParse(a.url);
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
            Row(children: [
              const Icon(Icons.business, color: _accent, size: 15),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(a.recipientName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(4)),
                child: Text(_money(a.awardAmount),
                    style: const TextStyle(
                        color: _accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 6),
              if (a.agency.isNotEmpty)
                Expanded(
                    child: Text(a.agency,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)),
            ]),
            if (a.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(a.description,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 11,
                      height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ]),
        ),
      ),
    );
  }
}
