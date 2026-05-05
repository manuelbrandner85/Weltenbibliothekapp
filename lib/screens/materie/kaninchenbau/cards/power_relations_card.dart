/// 🕸️ MACHTBEZIEHUNGEN — wer kennt wen wirklich?
///
/// Quelle: LittleSis API (kein Key).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/thread.dart';
import '../widgets/kb_design.dart';

class PowerRelationsCard extends StatelessWidget {
  final List<PowerRelation> relations;
  final bool loading;

  const PowerRelationsCard({
    super.key,
    required this.relations,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: KbDesign.glassBox(tint: const Color(0xFFFF8A65)),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.diversity_3_rounded,
                  color: Color(0xFFFF8A65), size: 18),
              const SizedBox(width: 8),
              const Text(
                'MACHTBEZIEHUNGEN',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (relations.isNotEmpty)
                Text(
                  '${relations.length} Verbindungen',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Aufsichtsräte · Spenden · Familie · Anstellungen',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 14),
          if (loading)
            _buildLoading()
          else if (relations.isEmpty)
            _buildEmpty()
          else
            ...relations.map((r) => _buildRelation(context, r)),
        ],
      ),
    );
  }

  Widget _buildLoading() => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: const Color(0xFFFF8A65),
            ),
          ),
        ),
      );

  Widget _buildEmpty() => Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Keine LittleSis-Beziehungen gefunden.\n'
          'Tipp: funktioniert am besten bei US-Personen/Organisationen.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            height: 1.4,
          ),
        ),
      );

  Widget _buildRelation(BuildContext context, PowerRelation r) {
    return InkWell(
      onTap: r.url == null ? null : () => _open(r.url!),
      borderRadius: BorderRadius.circular(KbDesign.radiusSm),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(KbDesign.radiusSm),
          color: Colors.white.withValues(alpha: 0.04),
          border: Border.all(
            color: const Color(0xFFFF8A65).withValues(alpha: 0.18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    r.entity1,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: const Color(0xFFFF8A65).withValues(alpha: 0.18),
                  ),
                  child: Text(
                    r.relationType,
                    style: const TextStyle(
                      color: Color(0xFFFF8A65),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    r.entity2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (r.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                r.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11.5,
                  height: 1.3,
                ),
              ),
            ],
            if (r.amount != null && r.amount! > 0) ...[
              const SizedBox(height: 4),
              Text(
                _fmtAmount(r.amount!.toDouble()),
                style: TextStyle(
                  color: KbDesign.goldAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _fmtAmount(double usd) {
    if (usd >= 1e6) return '\$${(usd / 1e6).toStringAsFixed(1)}M';
    if (usd >= 1e3) return '\$${(usd / 1e3).toStringAsFixed(1)}K';
    return '\$${usd.toStringAsFixed(0)}';
  }

  Future<void> _open(String url) async {
    HapticFeedback.lightImpact();
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
