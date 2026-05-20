/// 🇪🇺 EU-ABSTIMMUNGEN — HowTheyVote.eu · Europaparlament-Votes (kostenlos, kein Key)
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/thread.dart';
import '../widgets/kb_design.dart';

class EuVotesCard extends StatelessWidget {
  final List<EuVote> votes;
  final bool loading;

  const EuVotesCard({super.key, required this.votes, required this.loading});

  static const _accent = Color(0xFF5C6BC0);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: KbDesign.glassBox(tint: _accent, opacity: 0.10),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.how_to_vote, color: _accent, size: 18),
            const SizedBox(width: 8),
            const Text('EU-PARLAMENT · ABSTIMMUNGEN',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold)),
            const Spacer(),
            if (votes.isNotEmpty)
              Text('${votes.length}',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11)),
          ]),
          const SizedBox(height: 4),
          Text('HowTheyVote.eu · Europaparlament · Transparenz-Datenbank',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45), fontSize: 11)),
          const SizedBox(height: 14),
          if (loading)
            _buildLoading()
          else if (votes.isEmpty)
            _buildEmpty()
          else
            ...votes.take(6).map(_buildVote),
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
              child: CircularProgressIndicator(color: _accent, strokeWidth: 2)),
        ),
      );

  Widget _buildEmpty() => Padding(
        padding: const EdgeInsets.all(20),
        child: Text('Keine EU-Parlamentsabstimmungen gefunden.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4))),
      );

  Widget _buildVote(EuVote v) {
    final total = v.forCount + v.againstCount + v.abstainCount;
    final forPct = total > 0 ? v.forCount / total : 0.0;
    final againstPct = total > 0 ? v.againstCount / total : 0.0;
    final passed = v.result.toLowerCase().contains('adopt') ||
        v.result.toLowerCase().contains('pass') ||
        v.forCount > v.againstCount;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () async {
          HapticFeedback.lightImpact();
          final uri = Uri.tryParse(v.url);
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
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Text(v.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: (passed ? Colors.green : Colors.red)
                      .withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: (passed ? Colors.greenAccent : Colors.redAccent)
                        .withValues(alpha: 0.4),
                    width: 0.8,
                  ),
                ),
                child: Text(passed ? 'ANGENOMMEN' : 'ABGELEHNT',
                    style: TextStyle(
                      color: passed ? Colors.greenAccent : Colors.redAccent,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                    )),
              ),
            ]),
            const SizedBox(height: 8),
            _buildVoteBar(forPct, againstPct),
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _voteCount('✓ ${v.forCount}', Colors.greenAccent),
              _voteCount('✗ ${v.againstCount}', Colors.redAccent),
              _voteCount('○ ${v.abstainCount}', Colors.white38),
              Text(v.date.length > 10 ? v.date.substring(0, 10) : v.date,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 9)),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _buildVoteBar(double forPct, double againstPct) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        height: 6,
        child: Row(children: [
          Expanded(
            flex: (forPct * 100).round(),
            child: Container(color: Colors.greenAccent.withValues(alpha: 0.7)),
          ),
          Expanded(
            flex: (againstPct * 100).round(),
            child: Container(color: Colors.redAccent.withValues(alpha: 0.7)),
          ),
          Expanded(
            flex: ((1 - forPct - againstPct).clamp(0.0, 1.0) * 100).round(),
            child: Container(color: Colors.white12),
          ),
        ]),
      ),
    );
  }

  Widget _voteCount(String label, Color color) => Text(label,
      style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700));
}
