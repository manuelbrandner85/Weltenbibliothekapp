// Mantra-Guide: Einsteigerfreundliches Mantra-Tool.
// Bereiche M1 (Einsteiger), M2 (Wirkungsfilter), M3 (Situations),
// M4 (Dauer), M5 (Journal), M6 (21-Tage-Plan).

import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/mantras_extended.dart';
import '../../../services/streak_tracking_service.dart';
import '../../../widgets/cinematic/wb_ambient_particles.dart';
import '../../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../../widgets/cinematic/wb_vignette.dart';
import '../../../theme/wb_cinematic_tokens.dart';

class MantraGuideScreen extends StatefulWidget {
  const MantraGuideScreen({super.key});

  @override
  State<MantraGuideScreen> createState() => _MantraGuideScreenState();
}

class _MantraGuideScreenState extends State<MantraGuideScreen>
    with TickerProviderStateMixin {
  late TabController _tabs;
  static const _accent = Color(0xFF9C27B0);
  static const _gold = Color(0xFFC9A84C);

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
    StreakTrackingService().trackToolUsage('mantra_guide');
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06040F),
      extendBodyBehindAppBar: true,
      appBar: WBGlassAppBar(
        title: 'Mantra-Guide',
        world: WBWorld.energie,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(42),
          child: TabBar(
            controller: _tabs,
            isScrollable: true,
            indicatorColor: _accent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            labelStyle: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4),
            tabs: const [
              Tab(text: 'START'),
              Tab(text: 'WIRKUNG'),
              Tab(text: 'SITUATION'),
              Tab(text: '21-TAGE'),
              Tab(text: 'JOURNAL'),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          const IgnorePointer(
              child: WBAmbientParticles(world: WBWorld.energie, count: 24)),
          const WBVignette(),
          SafeArea(
            child: TabBarView(
              controller: _tabs,
              children: const [
                _IntroTab(),
                _EffectsTab(),
                _SituationsTab(),
                _JourneyTab(),
                _JournalTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const accentColor = _accent;
  static const goldColor = _gold;
}

// ══════════════════════════════════════════════════════════════════════
// TAB 1 -- EINSTEIGER (M1)
// ══════════════════════════════════════════════════════════════════════
class _IntroTab extends StatelessWidget {
  const _IntroTab();

  static const _cards = [
    (
      icon: Icons.help_outline_rounded,
      title: 'Was ist ein Mantra?',
      body:
          'Ein Mantra ist ein heiliger Klang. Du wiederholst ihn -- gesprochen, '
          'leise gedacht oder im Rhythmus deines Atems. Die Wiederholung beruhigt '
          'den Geist und legt eine Spur in dein Bewusstsein.\n\nKein Glauben '
          'noetig -- du kannst es einfach probieren und spueren wie es wirkt.',
    ),
    (
      icon: Icons.gps_fixed_rounded,
      title: 'Wofuer brauche ich das?',
      body: 'Mantras sind wie Werkzeuge:\n\n'
          '• Bei Stress -- statt zu gruebeln, hast du ein Anker-Wort.\n'
          '• Bei Schlafproblemen -- der Atem-Rhythmus fuehrt dich runter.\n'
          '• Vor schweren Gespraechen -- du sammelst dich.\n'
          '• Bei Selbstkritik -- du brichst die Schleife.\n\n'
          'Du musst kein "spiritueller Mensch" sein. Es funktioniert auch '
          'wenn du es nur als Atem-Anker nutzt.',
    ),
    (
      icon: Icons.timer_outlined,
      title: 'Wie oft? Wie lange?',
      body:
          'Klassisch: 108 Wiederholungen (eine Mala). Das sind ca. 3-7 min.\n\n'
          'Fuer Anfaenger:\n'
          '• 9 Wiederholungen: Mini-Atempause (30 sec)\n'
          '• 27 Wiederholungen: Kurze Praxis (1-2 min)\n'
          '• 54 Wiederholungen: Mittel (3-4 min)\n'
          '• 108 Wiederholungen: Volle Mala (5-7 min)\n\n'
          'Konsistenz schlaegt Laenge. Lieber jeden Tag 9x als einmal pro '
          'Woche 108x.',
    ),
    (
      icon: Icons.lightbulb_outline_rounded,
      title: 'Wie spreche ich es aus?',
      body: 'Korrekte Aussprache hilft, ist aber nicht zwingend.\n\n'
          'Wichtiger:\n'
          '• Klar und langsam -- nicht hetzen.\n'
          '• Im Atem-Rhythmus -- eine Wiederholung = ein Atemzyklus.\n'
          '• Erst laut probieren, dann fluestern, dann nur denken.\n\n'
          'Du musst kein Sanskrit-Profi sein. Die Wirkung kommt vom '
          'bewussten Wiederholen, nicht von der perfekten Phonetik.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        const SizedBox(height: 8),
        const Text('Erst lesen -- dann ueben.',
            style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        const Text('4 kurze Karten erklaeren das Wichtigste.',
            style: TextStyle(color: Colors.white60, fontSize: 13)),
        const SizedBox(height: 18),
        ..._cards.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _introCard(c.icon, c.title, c.body),
            )),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFC9A84C).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: const Color(0xFFC9A84C).withValues(alpha: 0.4)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.tips_and_updates_rounded,
                    color: Color(0xFFC9A84C), size: 18),
                SizedBox(width: 8),
                Text('Tipp fuer den Anfang',
                    style: TextStyle(
                        color: Color(0xFFC9A84C),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5)),
              ]),
              SizedBox(height: 6),
              Text(
                  'Starte mit OM oder So Ham. Beide sind einfach, brauchen '
                  'keine Sanskrit-Kenntnisse, und du kannst sie ueberall '
                  'ueben -- im Bus, vorm Einschlafen, beim Spazieren.',
                  style: TextStyle(
                      color: Colors.white, fontSize: 13, height: 1.5)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _introCard(IconData icon, String title, String body) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: const Color(0xFF9C27B0).withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF9C27B0).withValues(alpha: 0.25),
                  ),
                  child: const Icon(Icons.help_outline_rounded,
                      color: Color(0xFFCE93D8), size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800)),
                ),
              ]),
              const SizedBox(height: 10),
              Text(body,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 13.5, height: 1.6)),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// TAB 2 -- WIRKUNGS-FILTER (M2)
// ══════════════════════════════════════════════════════════════════════
class _EffectsTab extends StatefulWidget {
  const _EffectsTab();
  @override
  State<_EffectsTab> createState() => _EffectsTabState();
}

class _EffectsTabState extends State<_EffectsTab> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final effects = allMantraEffects;
    final filtered =
        _selected == null ? mantraLibrary : mantrasForEffect(_selected!);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        const Text('Wirkung waehlen:',
            style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _filterChip('Alle', _selected == null,
                () => setState(() => _selected = null)),
            ...effects.map((e) => _filterChip(
                e, _selected == e, () => setState(() => _selected = e))),
          ],
        ),
        const SizedBox(height: 16),
        ...filtered.map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _MantraCard(mantra: m),
            )),
      ],
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF9C27B0).withValues(alpha: 0.28)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFFCE93D8)
                : Colors.white.withValues(alpha: 0.12),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600)),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// TAB 3 -- SITUATIONS-FILTER (M3)
// ══════════════════════════════════════════════════════════════════════
class _SituationsTab extends StatefulWidget {
  const _SituationsTab();
  @override
  State<_SituationsTab> createState() => _SituationsTabState();
}

class _SituationsTabState extends State<_SituationsTab> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final situations = allMantraSituations;
    final filtered =
        _selected == null ? <MantraEntry>[] : mantrasForSituation(_selected!);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        const Text('Waehle deine aktuelle Situation:',
            style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...situations.map((s) {
          final sel = s == _selected;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: GestureDetector(
              onTap: () => setState(() => _selected = sel ? null : s),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: sel
                      ? const Color(0xFF9C27B0).withValues(alpha: 0.22)
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: sel
                        ? const Color(0xFFCE93D8)
                        : Colors.white.withValues(alpha: 0.1),
                    width: sel ? 1.4 : 1,
                  ),
                ),
                child: Row(children: [
                  Icon(
                      sel
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked,
                      color: sel ? const Color(0xFFCE93D8) : Colors.white38,
                      size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(s,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight:
                                sel ? FontWeight.w800 : FontWeight.w600)),
                  ),
                ]),
              ),
            ),
          );
        }),
        if (filtered.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Empfohlene Mantras:',
              style: TextStyle(
                  color: Color(0xFFCE93D8),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5)),
          const SizedBox(height: 8),
          ...filtered.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _MantraCard(mantra: m),
              )),
        ],
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// TAB 4 -- 21-TAGE-REISE (M6)
// ══════════════════════════════════════════════════════════════════════
class _JourneyTab extends StatefulWidget {
  const _JourneyTab();
  @override
  State<_JourneyTab> createState() => _JourneyTabState();
}

class _JourneyTabState extends State<_JourneyTab> {
  static const _kKey = 'mantra_journey_v1';
  Set<int> _done = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kKey) ?? const [];
    if (!mounted) return;
    setState(() {
      _done = raw.map(int.parse).toSet();
      _loading = false;
    });
  }

  Future<void> _toggle(int day) async {
    HapticFeedback.lightImpact();
    setState(() {
      if (_done.contains(day)) {
        _done.remove(day);
      } else {
        _done.add(day);
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kKey, _done.map((d) => d.toString()).toList());
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final completed = _done.length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFC9A84C).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: const Color(0xFFC9A84C).withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('21-TAGE-BERUHIGUNGS-REISE',
                  style: TextStyle(
                      color: Color(0xFFC9A84C),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5)),
              const SizedBox(height: 6),
              const Text(
                  'Sanfter Einstieg in die Mantra-Praxis. Jeden Tag ein '
                  'Mantra + ein Fokus. Steigerung von 9 auf 108 Wiederholungen '
                  'ueber 3 Wochen.',
                  style: TextStyle(
                      color: Colors.white, fontSize: 12.5, height: 1.45)),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: completed / 21,
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                valueColor: const AlwaysStoppedAnimation(Color(0xFFC9A84C)),
              ),
              const SizedBox(height: 6),
              Text('$completed von 21 Tagen abgeschlossen',
                  style: const TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...mantraJourney21Days.map((d) {
          final day = int.parse(d['day']!);
          final mantraId = d['mantra']!;
          final mantra = mantraLibrary.firstWhere((m) => m.id == mantraId,
              orElse: () => mantraLibrary.first);
          final done = _done.contains(day);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => _toggle(day),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: done
                      ? const Color(0xFF66BB6A).withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: done
                        ? const Color(0xFF66BB6A).withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.1),
                    width: done ? 1.4 : 1,
                  ),
                ),
                child: Row(children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done
                          ? const Color(0xFF66BB6A)
                          : const Color(0xFF9C27B0).withValues(alpha: 0.2),
                    ),
                    child: done
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 18)
                        : Text('$day',
                            style: const TextStyle(
                                color: Color(0xFFCE93D8),
                                fontSize: 12,
                                fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(width: 10),
                  Text(mantra.emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(mantra.translit,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w800)),
                        Text(d['focus']!,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${d['reps']}x',
                        style: const TextStyle(
                            color: Color(0xFFFFD54F),
                            fontSize: 11,
                            fontWeight: FontWeight.w800)),
                  ),
                ]),
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// TAB 5 -- JOURNAL (M5)
// ══════════════════════════════════════════════════════════════════════
class _JournalTab extends StatefulWidget {
  const _JournalTab();
  @override
  State<_JournalTab> createState() => _JournalTabState();
}

class _JournalTabState extends State<_JournalTab> {
  static const _kKey = 'mantra_journal_v1';
  List<Map<String, dynamic>> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kKey);
    if (raw == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() {
        _entries = list;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Stack(children: [
      ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          const Text('Wie war deine Praxis?',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text(
              'Kurzer Eintrag nach jeder Mantra-Praxis hilft dir zu sehen, '
              'was bei dir wirkt.',
              style:
                  TextStyle(color: Colors.white60, fontSize: 12, height: 1.4)),
          const SizedBox(height: 14),
          if (_entries.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(
                  child: Text('Noch keine Eintraege.',
                      style: TextStyle(color: Colors.white38))),
            )
          else
            ..._entries.reversed.map(_entryCard),
        ],
      ),
      Positioned(
        right: 18,
        bottom: 18,
        child: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF9C27B0),
          foregroundColor: Colors.white,
          onPressed: () => _showAddDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('Neuer Eintrag'),
        ),
      ),
    ]);
  }

  Widget _entryCard(Map<String, dynamic> e) {
    final ts = DateTime.tryParse(e['ts'] as String? ?? '');
    final feeling = (e['feeling'] as num?)?.toInt() ?? 5;
    final mantra = e['mantra'] as String? ?? '';
    final note = e['note'] as String? ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: const Color(0xFF9C27B0).withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(mantra,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800)),
              const Spacer(),
              if (ts != null)
                Text(
                    '${ts.day}.${ts.month}. ${ts.hour}:${ts.minute.toString().padLeft(2, '0')}',
                    style:
                        const TextStyle(color: Colors.white60, fontSize: 11)),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              const Text('Stimmung:',
                  style: TextStyle(color: Colors.white60, fontSize: 11)),
              const SizedBox(width: 8),
              ...List.generate(
                  10,
                  (i) => Container(
                        width: 12,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: i < feeling
                              ? const Color(0xFFCE93D8)
                              : Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      )),
              const SizedBox(width: 6),
              Text('$feeling/10',
                  style: const TextStyle(
                      color: Color(0xFFCE93D8),
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ]),
            if (note.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(note,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      height: 1.4,
                      fontStyle: FontStyle.italic)),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context) async {
    const mantras = mantraLibrary;
    var selectedMantra = mantras.first.translit;
    var feeling = 7.0;
    final noteCtrl = TextEditingController();

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: const Color(0xFF0B0716),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheet) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
                20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Neuer Journal-Eintrag',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                DropdownButton<String>(
                  value: selectedMantra,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1A1430),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  items: mantras
                      .map((m) => DropdownMenuItem(
                            value: m.translit,
                            child: Text('${m.emoji}  ${m.translit}'),
                          ))
                      .toList(),
                  onChanged: (v) => setSheet(() => selectedMantra = v!),
                ),
                const SizedBox(height: 14),
                Text('Stimmung: ${feeling.toInt()}/10',
                    style: const TextStyle(
                        color: Color(0xFFCE93D8),
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
                Slider(
                  value: feeling,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  activeColor: const Color(0xFF9C27B0),
                  onChanged: (v) => setSheet(() => feeling = v),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: noteCtrl,
                  style: const TextStyle(color: Colors.white),
                  maxLength: 100,
                  decoration: const InputDecoration(
                    hintText: '2-3 Worte: wie war es?',
                    hintStyle: TextStyle(color: Colors.white38),
                    counterStyle: TextStyle(color: Colors.white38),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, {
                      'ts': DateTime.now().toIso8601String(),
                      'mantra': selectedMantra,
                      'feeling': feeling.toInt(),
                      'note': noteCtrl.text.trim(),
                    }),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9C27B0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Speichern',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );

    if (result == null || !mounted) return;
    setState(() => _entries.add(result));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kKey, jsonEncode(_entries));
  }
}

// ══════════════════════════════════════════════════════════════════════
// MANTRA-CARD (gemeinsam fuer Effects + Situations)
// ══════════════════════════════════════════════════════════════════════
class _MantraCard extends StatefulWidget {
  final MantraEntry mantra;
  const _MantraCard({required this.mantra});

  @override
  State<_MantraCard> createState() => _MantraCardState();
}

class _MantraCardState extends State<_MantraCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final m = widget.mantra;
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: const Color(0xFF9C27B0).withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(m.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.translit,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800)),
                    Text(m.simpleTranslation,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Color(0xFFCE93D8),
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              if (m.recommendedReps != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC9A84C).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${m.recommendedReps}x',
                      style: const TextStyle(
                          color: Color(0xFFFFD54F),
                          fontSize: 11,
                          fontWeight: FontWeight.w800)),
                ),
              const SizedBox(width: 4),
              Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                color: Colors.white60,
                size: 22,
              ),
            ]),
            if (_expanded) ...[
              const SizedBox(height: 12),
              _row('Sanskrit', m.sanskrit, true),
              _row('Aussprache', m.pronunciation, false),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(m.beginnerExplanation,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12.5, height: 1.55)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: m.effects
                    .map((e) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF9C27B0).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(e,
                              style: const TextStyle(
                                  color: Color(0xFFCE93D8),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700)),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, bool sanskrit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                  color: sanskrit ? const Color(0xFFFFD54F) : Colors.white,
                  fontSize: sanskrit ? 17 : 12.5,
                  height: 1.4,
                )),
          ),
        ],
      ),
    );
  }
}
