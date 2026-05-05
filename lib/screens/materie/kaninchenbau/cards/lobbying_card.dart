/// 🏛️ LOBBYING & EU-EINFLUSS — wer beeinflusst Brüssel?
///
/// Quelle: LobbyFacts.eu (EU Transparency Register, frei, ohne Key)
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/thread.dart';
import '../widgets/kb_design.dart';

class LobbyingCard extends StatelessWidget {
  final List<LobbyEntry> entries;
  final bool loading;

  const LobbyingCard({
    super.key,
    required this.entries,
    required this.loading,
  });

  static const _accent = Color(0xFFFFB300);

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
              const Icon(Icons.attach_money_rounded, color: _accent, size: 18),
              const SizedBox(width: 8),
              const Text(
                'LOBBYING · EU-EINFLUSS',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (entries.isNotEmpty)
                Text(
                  '${entries.length} Akteure',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'EU-Transparenzregister · LobbyFacts.eu',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45), fontSize: 11),
          ),
          const SizedBox(height: 14),
          if (loading)
            _buildLoading()
          else if (entries.isEmpty)
            _buildEmpty()
          else
            ...entries.take(8).map(_buildEntry),
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
          'Kein Eintrag im EU-Transparenzregister.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
        ),
      );

  Widget _buildEntry(LobbyEntry e) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: e.url.isEmpty
            ? null
            : () async {
                HapticFeedback.lightImpact();
                final uri = Uri.tryParse(e.url);
                if (uri != null && await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _accent.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      e.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (e.country.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        e.country,
                        style: const TextStyle(
                          color: _accent,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              if (e.category.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  e.category,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 10,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (e.budget != null)
                    _stat('Budget',
                        '€ ${_formatLargeNumber(e.budget!.toDouble())}'),
                  if (e.fullTimeStaff != null)
                    _stat('Vollzeit', '${e.fullTimeStaff}'),
                  if (e.lobbyists != null)
                    _stat('Lobbyisten', '${e.lobbyists}'),
                  if (e.meetings != null)
                    _stat('EU-Treffen', '${e.meetings}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 9)),
            const SizedBox(width: 4),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      );

  String _formatLargeNumber(double n) {
    if (n >= 1e9) return '${(n / 1e9).toStringAsFixed(1)} Mrd.';
    if (n >= 1e6) return '${(n / 1e6).toStringAsFixed(1)} Mio.';
    if (n >= 1e3) return '${(n / 1e3).toStringAsFixed(0)} k';
    return n.toStringAsFixed(0);
  }
}
