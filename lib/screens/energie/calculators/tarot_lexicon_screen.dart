// Tarot-Lexikon: alle 78 Karten browsebar mit Filter + Suche.
// Bereich A3 -- Lernmodus + Gamification ueber StreakTrackingService.

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../data/tarot_minor_arcana.dart';
import '../../../services/streak_tracking_service.dart';
import '../../../theme/wb_cinematic_tokens.dart';
import '../../../widgets/cinematic/wb_ambient_particles.dart';
import '../../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../../widgets/cinematic/wb_vignette.dart';

// Wir spiegeln die Major-Arcana hier als TarotCard-Liste, damit das
// Lexikon ohne Refactor des bestehenden tarot_oracle_screen funktioniert.
const List<TarotCard> _tarotMajor = [
  TarotCard(index: 0, name: 'Der Narr', nameEn: 'The Fool', suit: TarotSuit.major,
      emoji: '🃏', element: 'Aether',
      meaning: 'Neuer Anfang, naives Vertrauen, Sprung ins Unbekannte.',
      reversedMeaning: 'Unverantwortlichkeit, Naivität ohne Erkenntnis.'),
  TarotCard(index: 1, name: 'Der Magier', nameEn: 'The Magician', suit: TarotSuit.major,
      emoji: '🪄', element: 'Aether',
      meaning: 'Willenskraft, Manifestation, aktive Schöpfung.',
      reversedMeaning: 'Manipulation, fehlende Konzentration.'),
  TarotCard(index: 2, name: 'Die Hohepriesterin', nameEn: 'The High Priestess', suit: TarotSuit.major,
      emoji: '🌙', element: 'Aether',
      meaning: 'Intuition, verborgenes Wissen, Stille als Weisheits-Quelle.',
      reversedMeaning: 'Verdrängung der inneren Stimme.'),
  TarotCard(index: 3, name: 'Die Herrscherin', nameEn: 'The Empress', suit: TarotSuit.major,
      emoji: '👑', element: 'Aether',
      meaning: 'Fülle, Mutterprinzip, Schöpfung, sinnliche Lebenslust.',
      reversedMeaning: 'Erstickende Fürsorge, materielle Anhaftung.'),
  TarotCard(index: 4, name: 'Der Herrscher', nameEn: 'The Emperor', suit: TarotSuit.major,
      emoji: '🏛️', element: 'Aether',
      meaning: 'Struktur, Vaterprinzip, klare Grenzen.',
      reversedMeaning: 'Starre Tyrannei, Kontrollzwang.'),
  TarotCard(index: 5, name: 'Der Hierophant', nameEn: 'The Hierophant', suit: TarotSuit.major,
      emoji: '🔑', element: 'Aether',
      meaning: 'Tradition, spirituelle Lehre, Initiation.',
      reversedMeaning: 'Dogmatismus, blinder Gehorsam.'),
  TarotCard(index: 6, name: 'Die Liebenden', nameEn: 'The Lovers', suit: TarotSuit.major,
      emoji: '💞', element: 'Aether',
      meaning: 'Wahl aus dem Herzen, Vereinigung, Werte-Entscheidung.',
      reversedMeaning: 'Disharmonie, Bindungsangst.'),
  TarotCard(index: 7, name: 'Der Wagen', nameEn: 'The Chariot', suit: TarotSuit.major,
      emoji: '🏎️', element: 'Aether',
      meaning: 'Triumph durch Willenskraft, Kontrolle der Gegensätze.',
      reversedMeaning: 'Kontrollverlust, Aggression.'),
  TarotCard(index: 8, name: 'Die Kraft', nameEn: 'Strength', suit: TarotSuit.major,
      emoji: '🦁', element: 'Aether',
      meaning: 'Sanfte Stärke, innere Tapferkeit, Geduld.',
      reversedMeaning: 'Selbstzweifel, ungezähmte Triebe.'),
  TarotCard(index: 9, name: 'Der Eremit', nameEn: 'The Hermit', suit: TarotSuit.major,
      emoji: '🕯️', element: 'Aether',
      meaning: 'Inneres Licht, Rückzug, Weisheits-Suche.',
      reversedMeaning: 'Isolation, Erstarrung.'),
  TarotCard(index: 10, name: 'Das Rad des Schicksals', nameEn: 'Wheel of Fortune', suit: TarotSuit.major,
      emoji: '🎡', element: 'Aether',
      meaning: 'Wendepunkt, Zyklus, Schicksal in Bewegung.',
      reversedMeaning: 'Widerstand gegen den Wandel.'),
  TarotCard(index: 11, name: 'Die Gerechtigkeit', nameEn: 'Justice', suit: TarotSuit.major,
      emoji: '⚖️', element: 'Aether',
      meaning: 'Wahrheit, Ausgleich, karmische Balance.',
      reversedMeaning: 'Unfairness, Bias.'),
  TarotCard(index: 12, name: 'Der Gehängte', nameEn: 'The Hanged Man', suit: TarotSuit.major,
      emoji: '🙃', element: 'Aether',
      meaning: 'Perspektivwechsel, Hingabe, freiwillige Pause.',
      reversedMeaning: 'Festhalten, Stagnation.'),
  TarotCard(index: 13, name: 'Der Tod', nameEn: 'Death', suit: TarotSuit.major,
      emoji: '💀', element: 'Aether',
      meaning: 'Transformation, Ende eines Zyklus, Neugeburt.',
      reversedMeaning: 'Widerstand gegen Veränderung.'),
  TarotCard(index: 14, name: 'Die Mässigkeit', nameEn: 'Temperance', suit: TarotSuit.major,
      emoji: '🌊', element: 'Aether',
      meaning: 'Alchemie, Balance, geduldige Mischung.',
      reversedMeaning: 'Überschuss, Ungeduld.'),
  TarotCard(index: 15, name: 'Der Teufel', nameEn: 'The Devil', suit: TarotSuit.major,
      emoji: '😈', element: 'Aether',
      meaning: 'Bindung, Schatten, Sucht -- aber die Ketten sind lose.',
      reversedMeaning: 'Befreiung aus alten Mustern.'),
  TarotCard(index: 16, name: 'Der Turm', nameEn: 'The Tower', suit: TarotSuit.major,
      emoji: '🗼', element: 'Aether',
      meaning: 'Plötzliche Erkenntnis, Zerstörung falscher Strukturen.',
      reversedMeaning: 'Vermeidung der notwendigen Erschütterung.'),
  TarotCard(index: 17, name: 'Der Stern', nameEn: 'The Star', suit: TarotSuit.major,
      emoji: '⭐', element: 'Aether',
      meaning: 'Hoffnung, Heilung, Inspiration nach dem Sturm.',
      reversedMeaning: 'Verlust der Hoffnung.'),
  TarotCard(index: 18, name: 'Der Mond', nameEn: 'The Moon', suit: TarotSuit.major,
      emoji: '🌕', element: 'Aether',
      meaning: 'Illusion, Unterbewusstes, Traum.',
      reversedMeaning: 'Verwirrung lichtet sich.'),
  TarotCard(index: 19, name: 'Die Sonne', nameEn: 'The Sun', suit: TarotSuit.major,
      emoji: '☀️', element: 'Aether',
      meaning: 'Lebensfreude, Klarheit, Erfolg.',
      reversedMeaning: 'Vorübergehende Trübung.'),
  TarotCard(index: 20, name: 'Das Gericht', nameEn: 'Judgement', suit: TarotSuit.major,
      emoji: '📯', element: 'Aether',
      meaning: 'Erwachen, Berufung, höhere Einsicht.',
      reversedMeaning: 'Selbstverurteilung, verdrängter Ruf.'),
  TarotCard(index: 21, name: 'Die Welt', nameEn: 'The World', suit: TarotSuit.major,
      emoji: '🌍', element: 'Aether',
      meaning: 'Vollendung, Ganzheit, Zyklus abgeschlossen.',
      reversedMeaning: 'Unvollendete Aufgaben.'),
];

class TarotLexiconScreen extends StatefulWidget {
  const TarotLexiconScreen({super.key});

  @override
  State<TarotLexiconScreen> createState() => _TarotLexiconScreenState();
}

class _TarotLexiconScreenState extends State<TarotLexiconScreen> {
  TarotSuit? _filter; // null = alle
  String _search = '';
  final _searchCtrl = TextEditingController();
  final Set<String> _viewed = {};

  static const _gold = Color(0xFFFFD54F);
  static const _purple = Color(0xFF8E5AE2);

  @override
  void initState() {
    super.initState();
    StreakTrackingService().trackToolUsage('tarot_lexicon');
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<TarotCard> get _all => [..._tarotMajor, ...tarotMinorArcana];

  List<TarotCard> get _filtered {
    var list = _all;
    if (_filter != null) list = list.where((c) => c.suit == _filter).toList();
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((c) =>
          c.name.toLowerCase().contains(q) ||
          c.nameEn.toLowerCase().contains(q) ||
          c.keywords.any((k) => k.toLowerCase().contains(q))).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06040F),
      extendBodyBehindAppBar: true,
      appBar: const WBGlassAppBar(
        title: 'Tarot-Lexikon',
        world: WBWorld.energie,
      ),
      body: Stack(
        children: [
          const IgnorePointer(
            child: WBAmbientParticles(world: WBWorld.energie, count: 30),
          ),
          const WBVignette(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  _buildSearch(),
                  const SizedBox(height: 10),
                  _buildSuiteFilter(),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Row(children: [
                      Text('${_filtered.length} von ${_all.length} Karten',
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 11)),
                      const Spacer(),
                      if (_viewed.length >= 5)
                        Text('${_viewed.length} angesehen',
                            style: TextStyle(
                                color: _gold.withValues(alpha: 0.85),
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                    ]),
                  ),
                  const SizedBox(height: 8),
                  Expanded(child: _buildList()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: _searchCtrl,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Karte oder Stichwort suchen...',
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
        prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38),
        suffixIcon: _search.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.clear_rounded, color: Colors.white38),
                onPressed: () {
                  _searchCtrl.clear();
                  setState(() => _search = '');
                },
              ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
      onChanged: (v) => setState(() => _search = v),
    );
  }

  Widget _buildSuiteFilter() {
    final filters = <(TarotSuit?, String)>[
      (null, '🔮 Alle'),
      (TarotSuit.major, '✨ Große Arkana'),
      (TarotSuit.wands, '🔥 Stäbe'),
      (TarotSuit.cups, '💧 Kelche'),
      (TarotSuit.swords, '⚔️ Schwerter'),
      (TarotSuit.pentacles, '🪙 Münzen'),
    ];
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (_, i) {
          final (suit, label) = filters[i];
          final sel = _filter == suit;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _filter = suit),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: sel
                      ? _purple.withValues(alpha: 0.25)
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: sel ? _purple : Colors.transparent, width: 1.4),
                ),
                child: Text(label,
                    style: TextStyle(
                        color: sel ? Colors.white : Colors.white60,
                        fontSize: 12,
                        fontWeight: sel ? FontWeight.w800 : FontWeight.w500)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildList() {
    final list = _filtered;
    if (list.isEmpty) {
      return const Center(
        child: Text('Keine Treffer.',
            style: TextStyle(color: Colors.white38, fontSize: 14)),
      );
    }
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (_, i) {
        final c = list[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _cardTile(c),
        );
      },
    );
  }

  Widget _cardTile(TarotCard c) {
    return GestureDetector(
      onTap: () => _openDetail(c),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: _suiteColor(c.suit).withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Text(c.emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text('${c.suitDE} · ${c.element}',
                          style: TextStyle(
                              color: _suiteColor(c.suit),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.4)),
                      const SizedBox(height: 6),
                      Text(c.meaning,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12.5,
                              height: 1.4)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: Colors.white.withValues(alpha: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _suiteColor(TarotSuit s) => switch (s) {
        TarotSuit.major => _gold,
        TarotSuit.wands => const Color(0xFFFF6B6B),
        TarotSuit.cups => const Color(0xFF4FC3F7),
        TarotSuit.swords => const Color(0xFFB39DDB),
        TarotSuit.pentacles => const Color(0xFF81C784),
      };

  void _openDetail(TarotCard c) {
    if (_viewed.add(c.fullId)) {
      StreakTrackingService().trackToolUsage('tarot_card_viewed');
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CardDetailSheet(card: c, accent: _suiteColor(c.suit)),
    );
  }
}

class _CardDetailSheet extends StatelessWidget {
  final TarotCard card;
  final Color accent;
  const _CardDetailSheet({required this.card, required this.accent});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, ctrl) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0B0716).withValues(alpha: 0.96),
              border: Border(
                  top: BorderSide(color: accent.withValues(alpha: 0.4), width: 1.5)),
            ),
            child: ListView(
              controller: ctrl,
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Container(
                    width: 50, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(card.emoji,
                      style: const TextStyle(fontSize: 70)),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(card.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900)),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                      '${card.suitDE} · ${card.element} · ${card.nameEn}',
                      style: TextStyle(
                          color: accent.withValues(alpha: 0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4)),
                ),
                const SizedBox(height: 24),
                _section('Aufrechte Bedeutung', card.meaning, accent),
                const SizedBox(height: 12),
                _section('Umgekehrte Bedeutung', card.reversedMeaning,
                    Colors.orangeAccent),
                if (card.keywords.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('SCHLUESSELWOERTER',
                      style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6, runSpacing: 6,
                    children: card.keywords
                        .map((k) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: accent.withValues(alpha: 0.4)),
                              ),
                              child: Text(k,
                                  style: TextStyle(
                                      color: accent, fontSize: 11.5,
                                      fontWeight: FontWeight.w700)),
                            ))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(String title, String body, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(),
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5)),
          const SizedBox(height: 6),
          Text(body,
              style: const TextStyle(
                  color: Colors.white, fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }
}
