// 📚 LERNREIHEN-INDEX
//
// Zentraler Einstiegspunkt für alle tagesweisen Lernpfade im Spirit-Tab.
// Listet 17 Reihen (Phase 1: 10 fertige, weitere folgen) mit
// Fortschrittsbalken aus SharedPreferences.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/ancestral_lines_7.dart';
import '../../../data/archetypes_12.dart';
import '../../../data/chakra_program_7.dart';
import '../../../data/earthing_program_10.dart';
import '../../../data/hermetic_laws_7.dart';
import '../../../data/kabbalah_paths_22.dart';
import '../../../data/numerology_life_path_9.dart';
import '../../../data/olympian_gods_12.dart';
import '../../../data/sacred_geometry_12.dart';
import '../../../data/shamanic_initiation_7.dart';
import '../../../widgets/lesson_series_screen.dart';

class _Series {
  final String title;
  final String emoji;
  final String tradition;
  final String storageKey;
  final Color accent;
  final List<LessonSeriesEntry> entries;
  const _Series({
    required this.title,
    required this.emoji,
    required this.tradition,
    required this.storageKey,
    required this.accent,
    required this.entries,
  });
}

class LernreihenIndexScreen extends StatefulWidget {
  const LernreihenIndexScreen({super.key});

  @override
  State<LernreihenIndexScreen> createState() => _LernreihenIndexScreenState();
}

class _LernreihenIndexScreenState extends State<LernreihenIndexScreen> {
  static const _bg = Color(0xFF06040F);
  static const _surface = Color(0xFF100B1E);

  Map<String, int> _progress = {};
  bool _loading = true;

  static final List<_Series> _series = [
    _Series(
      title: '7-Tage-Chakra-Programm',
      emoji: '🌈',
      tradition: 'Hinduistisch — 7 Energiezentren mit Mantra & Solfeggio',
      storageKey: 'lr_chakra_7',
      accent: Color(0xFFE91E63),
      entries: chakraProgram7,
    ),
    _Series(
      title: '7-Tage-Kybalion',
      emoji: '✨',
      tradition: 'Hermetisch — Die 7 universellen Prinzipien (Three Initiates, 1908)',
      storageKey: 'lr_hermetic_7',
      accent: Color(0xFFFF9800),
      entries: hermeticLaws7,
    ),
    _Series(
      title: '7-Tage-Schamanen-Initiation',
      emoji: '🥁',
      tradition: 'Core Shamanism — Drei-Welten-Modell (M. Harner)',
      storageKey: 'lr_shamanic_7',
      accent: Color(0xFF8E5AE2),
      entries: shamanicInitiation7,
    ),
    _Series(
      title: '7-Tage-Ahnen-Linien',
      emoji: '🕯️',
      tradition: 'Systemisch — Hellinger-orientiert, weibliche & männliche Linien',
      storageKey: 'lr_ancestral_7',
      accent: Color(0xFFD4A24C),
      entries: ancestralLines7,
    ),
    _Series(
      title: '9-Tage-Lebenszahlen',
      emoji: '🔢',
      tradition: 'Pythagoräische Numerologie — die 9 Grundzahlen',
      storageKey: 'lr_numerology_9',
      accent: Color(0xFF9C27B0),
      entries: numerologyLifePath9,
    ),
    _Series(
      title: '10-Tage-Earthing',
      emoji: '🌍',
      tradition: 'Naturmedizin — progressives Erdungs-Programm',
      storageKey: 'lr_earthing_10',
      accent: Color(0xFF558B2F),
      entries: earthingProgram10,
    ),
    _Series(
      title: '12-Tage-Archetypen',
      emoji: '🧠',
      tradition: 'Carol Pearson — die 12 Hauptarchetypen in 4 Stufen',
      storageKey: 'lr_archetypes_12',
      accent: Color(0xFF673AB7),
      entries: archetypes12,
    ),
    _Series(
      title: '12-Tage-Olymp',
      emoji: '🏛️',
      tradition: 'Griechisches Pantheon — die 12 Olympier (Hesiod, Homer)',
      storageKey: 'lr_olympian_12',
      accent: Color(0xFF6A1B9A),
      entries: olympianGods12,
    ),
    _Series(
      title: '12-Tage-Heilige-Geometrie',
      emoji: '🔯',
      tradition: 'Sakrale Muster — von Kreis bis Torus',
      storageKey: 'lr_geometry_12',
      accent: Color(0xFF00838F),
      entries: sacredGeometry12,
    ),
    _Series(
      title: '22-Pfade-Kabbala',
      emoji: '🌳',
      tradition: 'Hebräische Mystik — Verbindungen im Lebensbaum',
      storageKey: 'lr_kabbalah_22',
      accent: Color(0xFF00BCD4),
      entries: kabbalahPaths22,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _progress = {
      for (final s in _series)
        s.storageKey:
            (prefs.getStringList(s.storageKey) ?? const []).length,
    };
    if (mounted) setState(() => _loading = false);
  }

  void _openSeries(_Series s) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LessonSeriesScreen(
          title: s.title,
          emoji: s.emoji,
          accent: s.accent,
          storageKey: s.storageKey,
          entries: s.entries,
          tradition: s.tradition,
        ),
      ),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1530),
        title: const Row(
          children: [
            Text('📚', style: TextStyle(fontSize: 22)),
            SizedBox(width: 10),
            Text('Lernreihen',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              children: [
                _buildIntro(),
                const SizedBox(height: 16),
                for (final s in _series) _buildCard(s),
              ],
            ),
    );
  }

  Widget _buildIntro() {
    final totalEntries = _series.fold<int>(0, (a, b) => a + b.entries.length);
    final completed =
        _progress.values.fold<int>(0, (a, b) => a + b);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1530), _surface],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tagesweise Lernpfade',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Jeder Pfad ist 7–22 Tage lang. Lies eine Lektion pro Tag, '
            'beantworte die Reflexionsfrage, hake ab. Fortschritt bleibt lokal.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Text('$completed / $totalEntries Lektionen abgeschlossen',
              style: const TextStyle(
                color: Color(0xFF4DB6AC),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              )),
        ],
      ),
    );
  }

  Widget _buildCard(_Series s) {
    final done = _progress[s.storageKey] ?? 0;
    final total = s.entries.length;
    final percent = total == 0 ? 0.0 : done / total;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: s.accent.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openSeries(s),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      s.accent.withValues(alpha: 0.45),
                      s.accent.withValues(alpha: 0.1),
                    ]),
                    border: Border.all(color: s.accent.withValues(alpha: 0.5)),
                  ),
                  child: Text(s.emoji, style: const TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          )),
                      const SizedBox(height: 2),
                      Text(s.tradition,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 11,
                            height: 1.3,
                          )),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: percent,
                                minHeight: 4,
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.08),
                                valueColor: AlwaysStoppedAnimation(s.accent),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text('$done/$total',
                              style: TextStyle(
                                color: s.accent,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              )),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    color: s.accent.withValues(alpha: 0.7)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
