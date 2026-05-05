/// 💰 GELDFLUSS-CARD — Sankey-ähnliche Flussvisualisierung.
///
/// Zeigt finanzielle Verbindungen rund um das Thema mit Beträgen.
/// Quelle: Heuristik aus Network + bekannten Pattern (Pfizer, WEF, BlackRock…).
library;

import 'package:flutter/material.dart';
import '../models/thread.dart';
import '../widgets/kb_design.dart';

class MoneyFlowCard extends StatelessWidget {
  final List<MoneyFlow> flows;
  final bool loading;

  const MoneyFlowCard({super.key, required this.flows, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: KbDesign.glassBox(tint: KbDesign.goldAccent),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attach_money_rounded,
                  color: KbDesign.goldAccent, size: 18),
              const SizedBox(width: 8),
              const Text(
                'GELDFLUSS',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (flows.isNotEmpty)
                Text(
                  '${flows.length} Verbindungen',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (loading)
            _buildLoading()
          else if (flows.isEmpty)
            _buildEmpty()
          else
            ...flows.map(_buildFlow),
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
              color: KbDesign.goldAccent,
            ),
          ),
        ),
      );

  Widget _buildEmpty() => Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Keine direkten Geldflüsse rekonstruierbar.\n'
          'Tipp: Versuche bekannte Org-Namen (Pfizer, WEF, BlackRock).',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 13,
            height: 1.4,
          ),
        ),
      );

  Widget _buildFlow(MoneyFlow f) {
    final amountText = _fmtAmount(f.amountUsd);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(KbDesign.radiusSm),
        gradient: LinearGradient(
          colors: [
            KbDesign.goldAccent.withValues(alpha: 0.06),
            KbDesign.goldAccent.withValues(alpha: 0.0),
          ],
        ),
        border: Border.all(
          color: KbDesign.goldAccent.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  f.from,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_rounded,
                  size: 16,
                  color: KbDesign.goldAccent.withValues(alpha: 0.85)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  f.to,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: KbDesign.goldAccent.withValues(alpha: 0.15),
                ),
                child: Text(
                  amountText,
                  style: TextStyle(
                    color: KbDesign.goldAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              if (f.year != null) ...[
                const SizedBox(width: 8),
                Text(
                  '${f.year}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
          if (f.purpose != null) ...[
            const SizedBox(height: 6),
            Text(
              f.purpose!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _fmtAmount(double usd) {
    if (usd >= 1e9) return '\$${(usd / 1e9).toStringAsFixed(1)}B';
    if (usd >= 1e6) return '\$${(usd / 1e6).toStringAsFixed(1)}M';
    if (usd >= 1e3) return '\$${(usd / 1e3).toStringAsFixed(1)}K';
    return '\$${usd.toStringAsFixed(0)}';
  }
}
