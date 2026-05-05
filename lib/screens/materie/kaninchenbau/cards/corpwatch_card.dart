/// ⚠️ CorpWatch — Unternehmens-Skandale (via GDELT).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/thread.dart';
import '../widgets/kb_design.dart';

class CorpWatchCard extends StatelessWidget {
  final List<CorpWatchArticle> items;
  final bool loading;
  const CorpWatchCard({super.key, required this.items, required this.loading});

  static const _accent = Color(0xFFD32F2F);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: KbDesign.glassBox(tint: _accent, opacity: 0.10),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.report_problem_rounded, color: _accent, size: 18),
          const SizedBox(width: 8),
          const Text('UNTERNEHMENS-SKANDALE',
              style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.bold)),
          const Spacer(),
          if (items.isNotEmpty)
            Text('${items.length}', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
        ]),
        const SizedBox(height: 4),
        Text('GDELT · Klagen, Betrug, Settlements, Untersuchungen',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 11)),
        const SizedBox(height: 14),
        if (loading)
          const Center(child: Padding(padding: EdgeInsets.all(24), child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(color: _accent, strokeWidth: 2))))
        else if (items.isEmpty)
          Padding(padding: const EdgeInsets.all(20), child: Text('Keine Unternehmens-Skandale zum Thema gefunden.', style: TextStyle(color: Colors.white.withValues(alpha: 0.4))))
        else
          ...items.take(8).map(_buildItem),
      ]),
    );
  }

  Widget _buildItem(CorpWatchArticle a) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: a.url.isEmpty ? null : () async {
          HapticFeedback.lightImpact();
          final uri = Uri.tryParse(a.url);
          if (uri != null && await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(10), border: Border.all(color: _accent.withValues(alpha: 0.22))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.article_rounded, color: _accent, size: 15),
              const SizedBox(width: 8),
              Expanded(child: Text(a.title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 4, children: [
              if (a.domain.isNotEmpty)
                Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2), decoration: BoxDecoration(color: _accent.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(4)), child: Text(a.domain, style: const TextStyle(color: _accent, fontSize: 9, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (a.date.isNotEmpty)
                Text(a.date.length > 10 ? a.date.substring(0, 10) : a.date, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10)),
              if (a.tone != 0)
                Text('Tonalität ${a.tone.toStringAsFixed(1)}', style: TextStyle(color: a.tone < 0 ? Colors.redAccent : Colors.greenAccent.withValues(alpha: 0.7), fontSize: 10)),
            ]),
          ]),
        ),
      ),
    );
  }
}
