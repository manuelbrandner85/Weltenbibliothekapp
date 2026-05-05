/// 🚨 SKANDALE & KONTROVERSEN — was geht schief?
///
/// Quelle: GDELT 2.0 mit negativem Sentiment-Filter (tone < -3)
/// Zeigt deutsche Berichte aus den letzten 180 Tagen mit auffällig
/// negativem Tonfall (potenzielle Skandale, Kritik, Skandale).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/thread.dart';
import '../widgets/kb_design.dart';

class SkandaleCard extends StatelessWidget {
  final List<Skandal> items;
  final bool loading;

  const SkandaleCard({
    super.key,
    required this.items,
    required this.loading,
  });

  static const _accent = Color(0xFFEF5350);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: KbDesign.glassBox(tint: _accent),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department_rounded,
                  color: _accent, size: 18),
              const SizedBox(width: 8),
              const Text(
                'SKANDALE · KONTROVERSEN',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (items.isNotEmpty)
                Text(
                  '${items.length}',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'GDELT · DE Berichte mit negativem Tonfall · 180 Tage',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45), fontSize: 11),
          ),
          const SizedBox(height: 14),
          if (loading)
            _buildLoading()
          else if (items.isEmpty)
            _buildEmpty()
          else
            ...items.take(8).map(_buildItem),
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
            child:
                CircularProgressIndicator(color: _accent, strokeWidth: 2),
          ),
        ),
      );

  Widget _buildEmpty() => Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Keine kontroversen Berichte gefunden — ggf. weniger negative '
          'Berichterstattung als erwartet.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
        ),
      );

  Widget _buildItem(Skandal s) {
    final intensity = (-s.tone / 10).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: s.url.isEmpty
            ? null
            : () async {
                HapticFeedback.lightImpact();
                final uri = Uri.tryParse(s.url);
                if (uri != null && await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: _accent.withValues(alpha: 0.2 + intensity * 0.4)),
          ),
          child: Row(
            children: [
              // Tone-Bar
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.4 + intensity * 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          s.domain,
                          style: const TextStyle(
                              color: _accent,
                              fontSize: 9,
                              fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 8),
                        if (s.tone < 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: _accent.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              'Tonfall ${s.tone.toStringAsFixed(1)}',
                              style: const TextStyle(
                                color: _accent,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
