/// AI-Insight-Karte (Virgil): KI-erzeugte non-obvious Verbindungen.
library;

import 'package:flutter/material.dart';
import '../widgets/kb_design.dart';

class AiInsightCard extends StatelessWidget {
  final String? insight;
  final bool loading;

  const AiInsightCard({
    super.key,
    required this.insight,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(KbDesign.radiusMd),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1010),
            KbDesign.cardSurface,
          ],
        ),
        border: Border.all(
          color: KbDesign.goldAccent.withValues(alpha: 0.5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: KbDesign.goldAccent.withValues(alpha: 0.18),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded,
                  color: KbDesign.goldAccent, size: 16),
              const SizedBox(width: 8),
              Text(
                'VIRGIL · KI-EINSICHT',
                style: TextStyle(
                  color: KbDesign.goldAccent,
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (loading)
            const _ThinkingDots()
          else if (insight == null || insight!.trim().isEmpty)
            Text(
              'VIRGIL hat noch nichts entdeckt — vielleicht beim nächsten Faden.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Text(
              insight!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.6,
                letterSpacing: 0.2,
              ),
            ),
        ],
      ),
    );
  }
}

class _ThinkingDots extends StatefulWidget {
  const _ThinkingDots();
  @override
  State<_ThinkingDots> createState() => _ThinkingDotsState();
}

class _ThinkingDotsState extends State<_ThinkingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        return Row(
          children: [
            Text(
              'denkt nach',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(width: 8),
            for (var i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Opacity(
                  opacity: ((((_c.value * 3) - i).clamp(0.0, 1.0))),
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: KbDesign.goldAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
