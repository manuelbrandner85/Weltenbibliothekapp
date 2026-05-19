// Birthstone-Matcher: Kristall-Empfehlungen aus Geburtsmonat,
// Sternzeichen UND Lebenszahl. Bereich K4.

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../data/crystal_library.dart';
import '../../../models/energie_profile.dart';
import '../../../services/spirit_calculations/numerology_engine.dart';
import '../../../services/storage_service.dart';
import '../../../services/streak_tracking_service.dart';
import '../../../widgets/cinematic/wb_ambient_particles.dart';
import '../../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../../widgets/cinematic/wb_vignette.dart';
import '../../../theme/wb_cinematic_tokens.dart';
import 'crystal_ritual_screen.dart';

class BirthstoneMatcherScreen extends StatefulWidget {
  const BirthstoneMatcherScreen({super.key});

  @override
  State<BirthstoneMatcherScreen> createState() =>
      _BirthstoneMatcherScreenState();
}

class _BirthstoneMatcherScreenState extends State<BirthstoneMatcherScreen> {
  EnergieProfile? _profile;
  bool _loading = true;
  static const _accent = Color(0xFFC9A84C);

  @override
  void initState() {
    super.initState();
    StreakTrackingService().trackToolUsage('birthstone_matcher');
    _load();
  }

  Future<void> _load() async {
    final p = await StorageService().loadEnergieProfile();
    if (!mounted) return;
    setState(() {
      _profile = p;
      _loading = false;
    });
  }

  String _zodiacFor(DateTime d) {
    final m = d.month;
    final day = d.day;
    if ((m == 3 && day >= 21) || (m == 4 && day <= 19)) return 'Widder';
    if ((m == 4 && day >= 20) || (m == 5 && day <= 20)) return 'Stier';
    if ((m == 5 && day >= 21) || (m == 6 && day <= 20)) return 'Zwillinge';
    if ((m == 6 && day >= 21) || (m == 7 && day <= 22)) return 'Krebs';
    if ((m == 7 && day >= 23) || (m == 8 && day <= 22)) return 'Loewe';
    if ((m == 8 && day >= 23) || (m == 9 && day <= 22)) return 'Jungfrau';
    if ((m == 9 && day >= 23) || (m == 10 && day <= 22)) return 'Waage';
    if ((m == 10 && day >= 23) || (m == 11 && day <= 21)) return 'Skorpion';
    if ((m == 11 && day >= 22) || (m == 12 && day <= 21)) return 'Schuetze';
    if ((m == 12 && day >= 22) || (m == 1 && day <= 19)) return 'Steinbock';
    if ((m == 1 && day >= 20) || (m == 2 && day <= 18)) return 'Wassermann';
    return 'Fische';
  }

  /// Scoring: pro Treffer 1 Punkt. Sortiert nach Score, dann Name.
  List<(CrystalEntry, int)> _scored() {
    if (_profile == null) return [];
    final bd = _profile!.birthDate;
    final month = bd.month;
    final zodiac = _zodiacFor(bd);
    final lifePath = NumerologyEngine.calculateLifePath(bd);
    final reduced = lifePath > 9
        ? (lifePath == 11 || lifePath == 22 || lifePath == 33
            ? lifePath
            : lifePath % 10)
        : lifePath;

    final scored = <(CrystalEntry, int)>[];
    for (final c in crystalLibrary) {
      int s = 0;
      if (c.birthMonths.contains(month)) s += 3;
      if (c.zodiac.contains(zodiac)) s += 2;
      if (c.lifePathNumber == reduced) s += 2;
      if (s > 0) scored.add((c, s));
    }
    scored.sort((a, b) {
      if (a.$2 != b.$2) return b.$2.compareTo(a.$2);
      return a.$1.name.compareTo(b.$1.name);
    });
    return scored.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06040F),
      extendBodyBehindAppBar: true,
      appBar: const WBGlassAppBar(
        title: 'Geburtsstein-Matcher',
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
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _profile == null
                      ? _noProfile()
                      : _matches(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _noProfile() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Text(
          'Profil mit Geburtsdatum benoetigt -- bitte erst im Profil-Editor eingeben.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
        ),
      ),
    );
  }

  Widget _matches() {
    final bd = _profile!.birthDate;
    final zodiac = _zodiacFor(bd);
    final lp = NumerologyEngine.calculateLifePath(bd);
    final scored = _scored();
    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _accent.withValues(alpha: 0.4)),
          ),
          child: Row(children: [
            const Icon(Icons.auto_awesome_rounded, color: _accent, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      _profile!.firstName.isEmpty
                          ? 'Deine Kristalle'
                          : '${_profile!.firstName}s Kristalle',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800)),
                  Text(
                    '${bd.day}.${bd.month}.${bd.year} · $zodiac · Lebenszahl $lp',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        if (scored.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text('Keine perfekte Uebereinstimmung gefunden.',
                  style: TextStyle(color: Colors.white60)),
            ),
          )
        else
          ...scored.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _crystalCard(e.value.$1, e.value.$2, e.key + 1),
              )),
      ],
    );
  }

  Widget _crystalCard(CrystalEntry c, int score, int rank) {
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
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _accent.withValues(alpha: 0.6),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.6),
                          width: 1.2),
                    ),
                    child: Text('$rank',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(width: 10),
                  Text(c.emoji, style: const TextStyle(fontSize: 26)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
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
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('$score Treffer',
                        style: const TextStyle(
                            color: _accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w800)),
                  ),
                ]),
                const SizedBox(height: 10),
                Text(c.spiritualEffect,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13, height: 1.5)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (c.birthMonths.contains(_profile!.birthDate.month))
                      _matchPill('Geburtsmonat'),
                    if (c.zodiac.contains(_zodiacFor(_profile!.birthDate)))
                      _matchPill('Sternzeichen'),
                    if (c.lifePathNumber != null &&
                        c.lifePathNumber ==
                            NumerologyEngine.calculateLifePath(
                                _profile!.birthDate))
                      _matchPill('Lebenszahl'),
                  ],
                ),
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
                            color: _accent, size: 14),
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

  Widget _matchPill(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF66BB6A).withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: const Color(0xFF66BB6A).withValues(alpha: 0.5)),
        ),
        child: Text('✓ $label',
            style: const TextStyle(
                color: Color(0xFF81C784),
                fontSize: 10.5,
                fontWeight: FontWeight.w700)),
      );
}
