/// A1: KI-Kaninchenbau-Pfade — reiche Pfade mit Typ, Aufhaenger, Suchbegriff.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/thread.dart';
import '../widgets/kb_design.dart';

class RabbitHolePathsCard extends StatelessWidget {
  final List<RabbitPath> paths;
  final bool loading;
  final void Function(String query) onTap;

  const RabbitHolePathsCard({
    super.key,
    required this.paths,
    required this.loading,
    required this.onTap,
  });

  IconData _iconFor(String type) {
    switch (type) {
      case 'person':
        return Icons.person_rounded;
      case 'organisation':
        return Icons.account_balance_rounded;
      case 'ereignis':
        return Icons.event_rounded;
      case 'ort':
        return Icons.place_rounded;
      case 'geldfluss':
        return Icons.attach_money_rounded;
      case 'dokument':
        return Icons.description_rounded;
      default:
        return Icons.psychology_rounded;
    }
  }

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
                'KANINCHENBAU-PFADE',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                'KI · tippen gräbt tiefer',
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
          else if (paths.isEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Keine weiterführenden Pfade gefunden',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
              ),
            )
          else
            for (final p in paths) ...[
              _PathTile(
                path: p,
                icon: _iconFor(p.type),
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onTap(p.query);
                },
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _PathTile extends StatelessWidget {
  final RabbitPath path;
  final IconData icon;
  final VoidCallback onTap;
  const _PathTile({required this.path, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [KbDesign.cardSurfaceAlt, KbDesign.cardSurface],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: KbDesign.neonRed.withValues(alpha: 0.30),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: KbDesign.neonRed.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: KbDesign.neonRedSoft),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          path.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_outward,
                          size: 14, color: KbDesign.neonRedSoft),
                    ],
                  ),
                  if (path.hook.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      path.hook,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
