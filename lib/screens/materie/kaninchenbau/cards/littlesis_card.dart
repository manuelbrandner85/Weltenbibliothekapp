/// 🕸️ LittleSis — Macht-Netzwerke (Personen & Firmen).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/thread.dart';
import '../widgets/kb_design.dart';

class LittleSisCard extends StatelessWidget {
  final List<LittleSisEntity> items;
  final bool loading;
  const LittleSisCard({super.key, required this.items, required this.loading});

  static const _accent = Color(0xFF6D4C41);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: KbDesign.glassBox(tint: _accent, opacity: 0.10),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.hub, color: _accent, size: 18),
          const SizedBox(width: 8),
          const Text('LITTLESIS-NETZWERK',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold)),
          const Spacer(),
          if (items.isNotEmpty)
            Text('${items.length}',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
        ]),
        const SizedBox(height: 4),
        Text('LittleSis · Wer-kennt-Wen unter Mächtigen',
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
              child: Text('Keine LittleSis-Einträge zum Thema gefunden.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4))))
        else
          ...items.take(8).map(_buildItem),
      ]),
    );
  }

  Widget _buildItem(LittleSisEntity e) {
    final isPerson = e.type.toLowerCase().contains('person');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: e.url.isEmpty
            ? null
            : () async {
                HapticFeedback.lightImpact();
                final uri = Uri.tryParse(e.url);
                if (uri != null && await canLaunchUrl(uri))
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _accent.withValues(alpha: 0.22))),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(isPerson ? Icons.person : Icons.business,
                  color: _accent, size: 15),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(e.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis)),
              if (e.type.isNotEmpty)
                Text(e.type,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 10)),
            ]),
            if (e.summary.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(e.summary,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 11,
                      height: 1.4),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis),
            ],
          ]),
        ),
      ),
    );
  }
}
