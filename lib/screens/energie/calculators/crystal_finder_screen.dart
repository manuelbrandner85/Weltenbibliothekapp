// Crystal-Finder: 3-Fragen-Wizard liefert Top-3 Kristall-Empfehlungen.
// Bereich K2.

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../data/crystal_library.dart';
import '../../../services/streak_tracking_service.dart';
import '../../../widgets/cinematic/wb_ambient_particles.dart';
import '../../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../../widgets/cinematic/wb_vignette.dart';
import '../../../theme/wb_cinematic_tokens.dart';
import 'crystal_ritual_screen.dart';

class CrystalFinderScreen extends StatefulWidget {
  const CrystalFinderScreen({super.key});

  @override
  State<CrystalFinderScreen> createState() => _CrystalFinderScreenState();
}

class _CrystalFinderScreenState extends State<CrystalFinderScreen> {
  int _step = 0;
  String? _intention;
  String? _chakra;
  String? _element;

  static const _accent = Color(0xFF9C27B0);

  // 12 thematische Intentions als erste Frage.
  static const _intentions = <(String, String, String)>[
    ('Beruhigung', '🌊', 'Stress, Schlaf, Geduld'),
    ('Mut', '🔥', 'Vor Auftritten, neuen Schritten'),
    ('Liebe', '💗', 'Selbstliebe, Beziehung, Versoehnung'),
    ('Schutz', '🛡️', 'Vor Energien, Stress, Streit'),
    ('Erdung', '🌳', 'Bodenstaendigkeit, Ruhe im Sturm'),
    ('Klarheit', '💎', 'Entscheidungen, klares Denken'),
    ('Wohlstand', '💰', 'Geld, Erfolg, Manifestation'),
    ('Kreativitaet', '🎨', 'Bei Blockaden, vor Erschaffung'),
    ('Heilung', '🌿', 'Koerperlich oder emotional'),
    ('Konzentration', '📚', 'Lernen, Pruefungen, Buero'),
    ('Spiritualitaet', '✨', 'Meditation, hoehere Verbindung'),
    ('Loslassen', '🍂', 'Trauer, Trennung, alte Muster'),
  ];

  static const _chakras = <(String, Color)>[
    ('Wurzel', Color(0xFFE53935)),
    ('Sakral', Color(0xFFFF6D00)),
    ('Solarplexus', Color(0xFFFFD600)),
    ('Herz', Color(0xFF43A047)),
    ('Hals', Color(0xFF1E88E5)),
    ('Stirn', Color(0xFF5E35B1)),
    ('Krone', Color(0xFF8E24AA)),
  ];

  static const _elements = <(String, String)>[
    ('Erde', '🌍'),
    ('Wasser', '💧'),
    ('Feuer', '🔥'),
    ('Luft', '🌬️'),
    ('Aether', '✨'),
  ];

  @override
  void initState() {
    super.initState();
    StreakTrackingService().trackToolUsage('crystal_finder');
  }

  List<CrystalEntry> _results() {
    var list = crystalLibrary.toList();
    if (_intention != null) {
      list = list
          .where((c) =>
              c.intentions.any(
                  (i) => i.toLowerCase().contains(_intention!.toLowerCase())) ||
              c.tags.any(
                  (t) => t.toLowerCase().contains(_intention!.toLowerCase())))
          .toList();
    }
    if (_chakra != null) {
      final pref = list.where((c) => c.chakra == _chakra).toList();
      if (pref.isNotEmpty) list = pref;
    }
    if (_element != null) {
      final pref = list.where((c) => c.element == _element).toList();
      if (pref.isNotEmpty) list = pref;
    }
    return list.take(3).toList();
  }

  void _next() {
    if (_step < 3) setState(() => _step++);
  }

  void _reset() {
    setState(() {
      _step = 0;
      _intention = null;
      _chakra = null;
      _element = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06040F),
      extendBodyBehindAppBar: true,
      appBar: const WBGlassAppBar(
        title: 'Kristall-Finder',
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
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildStep(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    if (_step == 0) return _intentionStep();
    if (_step == 1) return _chakraStep();
    if (_step == 2) return _elementStep();
    return _resultsStep();
  }

  Widget _intentionStep() {
    return Column(
      key: const ValueKey('int'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _progress(0),
        const SizedBox(height: 16),
        const Text('Was suchst du gerade?',
            style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5)),
        const SizedBox(height: 6),
        const Text('Waehle das Thema, das gerade am staerksten klopft.',
            style: TextStyle(color: Colors.white60, fontSize: 13)),
        const SizedBox(height: 20),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.6,
            ),
            itemCount: _intentions.length,
            itemBuilder: (_, i) {
              final (label, emoji, hint) = _intentions[i];
              final sel = _intention == label;
              return GestureDetector(
                onTap: () => setState(() => _intention = label),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: sel
                        ? _accent.withValues(alpha: 0.25)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color:
                          sel ? _accent : Colors.white.withValues(alpha: 0.1),
                      width: sel ? 1.6 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(height: 4),
                      Text(label,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                      const Spacer(),
                      Text(hint,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 10.5)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _intention != null ? _next : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Weiter',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          ),
        ),
      ],
    );
  }

  Widget _chakraStep() {
    return Column(
      key: const ValueKey('chakra'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _progress(1),
        const SizedBox(height: 16),
        const Text('Welcher Bereich braucht Aufmerksamkeit?',
            style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5)),
        const SizedBox(height: 6),
        const Text('Du kannst auch ueberspringen, wenn unklar.',
            style: TextStyle(color: Colors.white60, fontSize: 13)),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.builder(
            itemCount: _chakras.length,
            itemBuilder: (_, i) {
              final (name, color) = _chakras[i];
              final sel = _chakra == name;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _chakra = sel ? null : name),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: sel
                          ? color.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color:
                            sel ? color : Colors.white.withValues(alpha: 0.1),
                        width: sel ? 1.6 : 1,
                      ),
                    ),
                    child: Row(children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700)),
                      const Spacer(),
                      if (sel) Icon(Icons.check_circle, color: color, size: 18),
                    ]),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                _chakra = null;
                _next();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Ueberspringen'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: _next,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Weiter',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _elementStep() {
    return Column(
      key: const ValueKey('elem'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _progress(2),
        const SizedBox(height: 16),
        const Text('Welche Energie zieht dich gerade?',
            style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5)),
        const SizedBox(height: 6),
        const Text('Optional. Hilft die Empfehlung zu verfeinern.',
            style: TextStyle(color: Colors.white60, fontSize: 13)),
        const SizedBox(height: 20),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.4,
            ),
            itemCount: _elements.length,
            itemBuilder: (_, i) {
              final (name, emoji) = _elements[i];
              final sel = _element == name;
              return GestureDetector(
                onTap: () => setState(() => _element = sel ? null : name),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: sel
                        ? _accent.withValues(alpha: 0.25)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color:
                          sel ? _accent : Colors.white.withValues(alpha: 0.1),
                      width: sel ? 1.6 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 30)),
                      const SizedBox(height: 6),
                      Text(name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              _step++;
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Empfehlungen zeigen',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          ),
        ),
      ],
    );
  }

  Widget _resultsStep() {
    final results = _results();
    return Column(
      key: const ValueKey('result'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white60),
            onPressed: _reset,
          ),
          const SizedBox(width: 4),
          const Text('Deine Empfehlungen',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900)),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 4, children: [
          if (_intention != null) _chip(_intention!),
          if (_chakra != null) _chip(_chakra!),
          if (_element != null) _chip(_element!),
        ]),
        const SizedBox(height: 14),
        Expanded(
          child: results.isEmpty
              ? const Center(
                  child: Text(
                      'Keine perfekte Uebereinstimmung.\n'
                      'Versuche andere Kriterien.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white60)),
                )
              : ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _resultCard(results[i], i + 1),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _chip(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _accent.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _accent.withValues(alpha: 0.5)),
        ),
        child: Text(text,
            style: const TextStyle(
                color: Color(0xFFCE93D8),
                fontSize: 11,
                fontWeight: FontWeight.w700)),
      );

  Widget _resultCard(CrystalEntry c, int rank) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CrystalRitualScreen(crystal: c)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  c.displayColor.withValues(alpha: 0.22),
                  Colors.white.withValues(alpha: 0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.displayColor.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.displayColor.withValues(alpha: 0.4),
                    ),
                    child: Text('$rank',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(width: 10),
                  Text(c.emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800)),
                        Text(
                          [c.chakra, c.element]
                              .where((e) => e != null)
                              .join(' · '),
                          style: TextStyle(
                              color: c.displayColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                Text(c.spiritualEffect,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13, height: 1.5)),
                if (c.howToUse.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_outline_rounded,
                            color: Color(0xFFFFD54F), size: 14),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(c.howToUse,
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  height: 1.4)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _progress(int current) {
    return Row(
        children: List.generate(3, (i) {
      final active = i <= current;
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: active ? _accent : Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      );
    }));
  }
}
