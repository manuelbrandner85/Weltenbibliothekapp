/// 🇩🇪 POLITISCHE VERNETZUNG (DE) — Bundestags-Abgeordnete zum Thema.
///
/// Quelle: abgeordnetenwatch.de Open API (kein Key)
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/thread.dart';
import '../widgets/kb_design.dart';

class AbgeordneteCard extends StatelessWidget {
  final List<Abgeordneter> politicians;
  final bool loading;

  const AbgeordneteCard({
    super.key,
    required this.politicians,
    required this.loading,
  });

  static const _accent = Color(0xFF66BB6A);

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
              const Icon(Icons.gavel_rounded, color: _accent, size: 18),
              const SizedBox(width: 8),
              const Text(
                'POLITIK · BUNDESTAG',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (politicians.isNotEmpty)
                Text(
                  '${politicians.length}',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'abgeordnetenwatch.de · DE Politiker zum Thema',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45), fontSize: 11),
          ),
          const SizedBox(height: 14),
          if (loading)
            _buildLoading()
          else if (politicians.isEmpty)
            _buildEmpty()
          else
            ...politicians.map(_buildEntry),
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
          'Keine deutschen Politiker zum Thema gefunden.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
        ),
      );

  Widget _buildEntry(Abgeordneter p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: p.url == null
            ? null
            : () async {
                HapticFeedback.lightImpact();
                final uri = Uri.tryParse(p.url!);
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
            border: Border.all(color: _accent.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accent.withValues(alpha: 0.18),
                ),
                alignment: Alignment.center,
                child: Text(
                  p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: _accent,
                      fontSize: 16,
                      fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 6,
                      children: [
                        if (p.party.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: _accent.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              p.party,
                              style: const TextStyle(
                                color: _accent,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        if (p.profession != null && p.profession!.isNotEmpty)
                          Text(
                            p.profession!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 10,
                            ),
                          ),
                        if (p.birthYear != null)
                          Text(
                            '*${p.birthYear}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: _accent, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
