// Crystal-Combiner: 2 Kristalle waehlen, Synergie-Analyse anzeigen.
// Bereich K3.

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../data/crystal_library.dart';
import '../../../services/streak_tracking_service.dart';
import '../../../widgets/cinematic/wb_ambient_particles.dart';
import '../../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../../widgets/cinematic/wb_vignette.dart';
import '../../../theme/wb_cinematic_tokens.dart';

class CrystalCombinerScreen extends StatefulWidget {
  const CrystalCombinerScreen({super.key});

  @override
  State<CrystalCombinerScreen> createState() => _CrystalCombinerScreenState();
}

class _CrystalCombinerScreenState extends State<CrystalCombinerScreen> {
  CrystalEntry? _a;
  CrystalEntry? _b;
  String _search = '';
  final _searchCtrl = TextEditingController();
  static const _accent = Color(0xFF9C27B0);

  @override
  void initState() {
    super.initState();
    StreakTrackingService().trackToolUsage('crystal_combiner');
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<CrystalEntry> get _filtered {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return crystalLibrary;
    return crystalLibrary
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            c.tags.any((t) => t.toLowerCase().contains(q)))
        .toList();
  }

  // Analysiert die Synergie zwischen zwei Kristallen.
  Map<String, dynamic> _synergy(CrystalEntry a, CrystalEntry b) {
    final sharedTags = a.tags.toSet().intersection(b.tags.toSet()).toList();
    final sharedIntentions =
        a.intentions.toSet().intersection(b.intentions.toSet()).toList();
    final sameChakra = a.chakra != null && a.chakra == b.chakra;
    final sameElement = a.element != null && a.element == b.element;

    // Kompatibilitaets-Bewertung (0-100):
    int score = 50;
    score += sharedTags.length * 8;
    score += sharedIntentions.length * 10;
    if (sameChakra) score += 12;
    if (sameElement) score += 8;
    // Konflikt-Heuristik: starke Gegensaetze schmaelern Score.
    if (a.chakra == 'Wurzel' && b.chakra == 'Krone') score -= 6;
    if (a.element == 'Feuer' && b.element == 'Wasser') score -= 8;
    if (a.element == 'Erde' && b.element == 'Luft') score -= 5;
    score = score.clamp(0, 100);

    String label;
    String advice;
    if (score >= 80) {
      label = 'Starke Synergie';
      advice = 'Diese beiden Kristalle verstaerken sich gegenseitig. '
          'Trage sie zusammen oder lege sie naheinander.';
    } else if (score >= 60) {
      label = 'Gute Ergaenzung';
      advice = 'Ergaenzen sich gut. Nutze beide fuer ein abgerundetes '
          'Energiefeld -- z.B. einen am Koerper, einen im Raum.';
    } else if (score >= 40) {
      label = 'Spannungsfeld';
      advice = 'Treffen unterschiedliche Energien -- kann nuetzlich sein zum '
          'Balancieren, aber nicht ueber Stunden zusammen tragen.';
    } else {
      label = 'Eher trennen';
      advice = 'Die Schwingungen ziehen in verschiedene Richtungen. '
          'Besser einzeln nutzen oder zeitlich getrennt.';
    }

    return {
      'score': score,
      'label': label,
      'advice': advice,
      'sharedTags': sharedTags,
      'sharedIntentions': sharedIntentions,
      'sameChakra': sameChakra,
      'sameElement': sameElement,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06040F),
      extendBodyBehindAppBar: true,
      appBar: const WBGlassAppBar(
        title: 'Kristall-Kombi',
        world: WBWorld.energie,
      ),
      body: Stack(
        children: [
          const IgnorePointer(
              child: WBAmbientParticles(world: WBWorld.energie, count: 24)),
          const WBVignette(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
              child: Column(
                children: [
                  _slots(),
                  if (_a != null && _b != null) ...[
                    const SizedBox(height: 14),
                    _synergyCard(_synergy(_a!, _b!)),
                  ],
                  const SizedBox(height: 14),
                  _searchField(),
                  const SizedBox(height: 10),
                  Expanded(child: _crystalList()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _slots() {
    return Row(
      children: [
        Expanded(child: _slot(_a, 'A', () => setState(() => _a = null))),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.add_rounded, color: _accent, size: 24),
        ),
        Expanded(child: _slot(_b, 'B', () => setState(() => _b = null))),
      ],
    );
  }

  Widget _slot(CrystalEntry? c, String label, VoidCallback onClear) {
    final empty = c == null;
    return Container(
      height: 90,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: empty
            ? null
            : LinearGradient(colors: [
                c.displayColor.withValues(alpha: 0.3),
                c.displayColor.withValues(alpha: 0.08),
              ]),
        color: empty ? Colors.white.withValues(alpha: 0.05) : null,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: empty
              ? Colors.white.withValues(alpha: 0.15)
              : c.displayColor.withValues(alpha: 0.6),
          width: empty ? 1 : 1.6,
        ),
      ),
      child: empty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_circle_outline_rounded,
                      color: Colors.white38, size: 26),
                  const SizedBox(height: 4),
                  Text('Kristall $label',
                      style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            )
          : Row(children: [
              Text(c.emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(c.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800)),
                    Text(c.chakra ?? '',
                        style: TextStyle(
                            color: c.displayColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white60, size: 18),
                onPressed: onClear,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ]),
    );
  }

  Widget _synergyCard(Map<String, dynamic> s) {
    final score = s['score'] as int;
    final label = s['label'] as String;
    final advice = s['advice'] as String;
    final sharedTags = (s['sharedTags'] as List).cast<String>();
    final sharedIntentions = (s['sharedIntentions'] as List).cast<String>();

    Color tone;
    if (score >= 80) {
      tone = const Color(0xFF66BB6A);
    } else if (score >= 60) {
      tone = const Color(0xFFFFD54F);
    } else if (score >= 40) {
      tone = const Color(0xFFFFB300);
    } else {
      tone = const Color(0xFFEF5350);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: tone.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: tone.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text('$score%',
                    style: TextStyle(
                        color: tone,
                        fontSize: 28,
                        fontWeight: FontWeight.w900)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800)),
                ),
              ]),
              const SizedBox(height: 8),
              Text(advice,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 13, height: 1.5)),
              if (sharedTags.isNotEmpty || sharedIntentions.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text('Gemeinsam:',
                    style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    ...sharedTags.map(_pill),
                    ...sharedIntentions.map(_pill),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: _accent.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _accent.withValues(alpha: 0.5)),
        ),
        child: Text(t,
            style: const TextStyle(
                color: Color(0xFFCE93D8),
                fontSize: 10.5,
                fontWeight: FontWeight.w700)),
      );

  Widget _searchField() {
    return TextField(
      controller: _searchCtrl,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Kristall suchen...',
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
        prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
      onChanged: (v) => setState(() => _search = v),
    );
  }

  Widget _crystalList() {
    final list = _filtered;
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (_, i) {
        final c = list[i];
        final selected = (c.name == _a?.name) || (c.name == _b?.name);
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: GestureDetector(
            onTap: () => _pick(c),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected
                    ? c.displayColor.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected
                      ? c.displayColor
                      : Colors.white.withValues(alpha: 0.08),
                  width: selected ? 1.4 : 1,
                ),
              ),
              child: Row(children: [
                Text(c.emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700)),
                      Text(
                        [c.chakra, c.element]
                            .where((e) => e != null)
                            .join(' · '),
                        style: TextStyle(
                            color: c.displayColor.withValues(alpha: 0.9),
                            fontSize: 10.5),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_rounded,
                      color: Color(0xFFCE93D8), size: 18),
              ]),
            ),
          ),
        );
      },
    );
  }

  void _pick(CrystalEntry c) {
    setState(() {
      // Wenn schon ausgewaehlt -> abwaehlen
      if (_a?.name == c.name) {
        _a = null;
      } else if (_b?.name == c.name) {
        _b = null;
      } else if (_a == null) {
        _a = c;
      } else if (_b == null) {
        _b = c;
      } else {
        // beide voll -> aelteren ueberschreiben
        _a = _b;
        _b = c;
      }
    });
  }
}
