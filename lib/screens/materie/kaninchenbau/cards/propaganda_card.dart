/// 🎭 PROPAGANDA-LINSEN — wie wird das Thema medial geframt?
///
/// Quelle: Groq Llama 3.3 70B analysiert RSS-Items aus 20 deutschen Quellen
/// nach politischen Lagern (Mainstream, Alt-Links, Alt-Rechts, Investigativ).
///
/// Liefert: Kernnarrativ, Gegen-Narrativ, Auslassungen, Propaganda-Muster,
/// Recherche-Empfehlung — alles in 5 prägnanten Sätzen.
library;

import 'package:flutter/material.dart';
import '../widgets/kb_design.dart';

class PropagandaCard extends StatelessWidget {
  final String? analysis;
  final bool loading;

  const PropagandaCard({
    super.key,
    required this.analysis,
    required this.loading,
  });

  static const _accent = Color(0xFFAB47BC);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: KbDesign.glassBox(tint: _accent, opacity: 0.12),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology_rounded, color: _accent, size: 18),
              const SizedBox(width: 8),
              const Text(
                'PROPAGANDA-LINSEN',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'KI',
                  style: TextStyle(
                    color: _accent,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Framing-Analyse · Llama 3.3 · 20 Quellen vergleicht',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45), fontSize: 11),
          ),
          const SizedBox(height: 14),
          if (loading)
            _buildLoading()
          else if (analysis == null || analysis!.isEmpty)
            _buildEmpty()
          else
            _buildAnalysis(analysis!),
        ],
      ),
    );
  }

  Widget _buildLoading() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                    color: _accent, strokeWidth: 2),
              ),
              const SizedBox(height: 10),
              Text(
                'KI vergleicht Berichterstattung …',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 11),
              ),
            ],
          ),
        ),
      );

  Widget _buildEmpty() => Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Noch zu wenig RSS-Treffer für Framing-Analyse — sobald Mainstream-'
          'und Alt-Quellen geladen sind, läuft die Analyse automatisch.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
        ),
      );

  Widget _buildAnalysis(String text) {
    // Split nach den 5 erwarteten Sektionen
    final sections = <_Section>[];
    final patterns = {
      'KERNNARRATIV': Icons.menu_book_rounded,
      'GEGEN-NARRATIV': Icons.alternate_email_rounded,
      'AUSGELASSEN': Icons.gpp_bad,
      'PROPAGANDA-MUSTER': Icons.fingerprint_rounded,
      'EMPFEHLUNG': Icons.travel_explore_rounded,
    };

    for (final entry in patterns.entries) {
      final regex = RegExp(
          '${entry.key}[^:]*:\\s*([^\\n]+(?:\\n(?!${patterns.keys.join("|")}).+)*)',
          caseSensitive: false);
      final match = regex.firstMatch(text);
      if (match != null) {
        sections.add(_Section(
          label: entry.key,
          icon: entry.value,
          text: match.group(1)?.trim() ?? '',
        ));
      }
    }

    if (sections.isEmpty) {
      // Fallback: Roh-Text anzeigen
      return Text(
        text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.85),
          fontSize: 12,
          height: 1.5,
        ),
      );
    }

    return Column(
      children: sections.map((s) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _accent.withValues(alpha: 0.18)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(s.icon, color: _accent, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.label,
                        style: const TextStyle(
                          color: _accent,
                          fontSize: 10,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _Section {
  final String label;
  final IconData icon;
  final String text;
  const _Section({required this.label, required this.icon, required this.text});
}
