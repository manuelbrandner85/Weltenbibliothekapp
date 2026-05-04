/// Verwandte-Pfade-Karte: Bento-Grid mit nächsten Themen.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/kb_design.dart';

class RelatedPathsCard extends StatelessWidget {
  final List<String> topics;
  final bool loading;
  final void Function(String topic) onTap;

  const RelatedPathsCard({
    super.key,
    required this.topics,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: KbDesign.glassBox(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🐰', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              const Text(
                'TIEFER GRABEN',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                'tippen für neuen Faden',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (topics.isEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Keine verwandten Pfade gefunden',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
              ),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final t in topics) _ChipTile(label: t, onTap: () {
                  HapticFeedback.mediumImpact();
                  onTap(t);
                }),
              ],
            ),
        ],
      ),
    );
  }
}

class _ChipTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ChipTile({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              KbDesign.cardSurfaceAlt,
              KbDesign.cardSurface,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: KbDesign.neonRed.withValues(alpha: 0.35),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: KbDesign.neonRed.withValues(alpha: 0.15),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_outward_rounded,
                size: 14, color: KbDesign.neonRedSoft),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
