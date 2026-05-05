/// 🌍 GLOBALE AUSWIRKUNGEN — pro Land: Mentions + Sentiment.
///
/// Liste statt Karte (kein flutter_map nötig). Sortiert nach Mentions.
/// Sentiment-Bar rot (negativ) → grün (positiv).
library;

import 'package:flutter/material.dart';
import '../models/thread.dart';
import '../widgets/kb_design.dart';

class GlobalImpactCard extends StatelessWidget {
  final List<GlobalImpact> impacts;
  final bool loading;

  const GlobalImpactCard({
    super.key,
    required this.impacts,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final maxMentions = impacts.isEmpty
        ? 1
        : impacts.map((e) => e.mentions).reduce((a, b) => a > b ? a : b);

    return Container(
      decoration: KbDesign.glassBox(tint: const Color(0xFF42A5F5)),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.public_rounded,
                  color: Color(0xFF42A5F5), size: 18),
              const SizedBox(width: 8),
              const Text(
                'GLOBALE AUSWIRKUNGEN',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Wo wird darüber geschrieben? Wie wird es bewertet?',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 14),
          if (loading)
            _buildLoading()
          else if (impacts.isEmpty)
            _buildEmpty()
          else
            ...impacts.map((i) => _buildRow(i, maxMentions)),
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
              color: const Color(0xFF42A5F5),
            ),
          ),
        ),
      );

  Widget _buildEmpty() => Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Keine internationalen Berichte zu diesem Thema gefunden.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
        ),
      );

  Widget _buildRow(GlobalImpact i, int maxMentions) {
    final pct = i.mentions / maxMentions;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                child: Text(
                  i.country,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  i.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '${i.mentions}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Mentions-Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Container(
              height: 4,
              color: Colors.white.withValues(alpha: 0.06),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: pct.clamp(0.02, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _sentColor(i.sentiment).withValues(alpha: 0.7),
                          _sentColor(i.sentiment),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Text(
                _sentLabel(i.sentiment),
                style: TextStyle(
                  color: _sentColor(i.sentiment).withValues(alpha: 0.85),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _sentColor(double s) {
    if (s < -0.3) return const Color(0xFFEF5350);
    if (s > 0.3) return const Color(0xFF66BB6A);
    return const Color(0xFFB0BEC5);
  }

  String _sentLabel(double s) {
    if (s < -0.3) return 'überwiegend negativ';
    if (s > 0.3) return 'überwiegend positiv';
    return 'neutral / gemischt';
  }
}
