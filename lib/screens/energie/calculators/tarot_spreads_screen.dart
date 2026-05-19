// 🔮 TAROT-LEGESYSTEME
//
// 3 Spread-Varianten: 1-Karte (Tag), 3-Karten (V-G-Z), Keltisches Kreuz (10).
// Zieht zufällig aus 22 Großen Arkana. Klassische Bedeutungen.

import 'dart:math';

import 'package:flutter/material.dart';

class TarotSpreadsScreen extends StatefulWidget {
  const TarotSpreadsScreen({super.key});

  @override
  State<TarotSpreadsScreen> createState() => _TarotSpreadsScreenState();
}

class _TarotSpreadsScreenState extends State<TarotSpreadsScreen> {
  static const _bg = Color(0xFF06040F);
  static const _surface = Color(0xFF1A0A2E);
  static const _accent = Color(0xFF8E5AE2);

  static const List<_TarotCard> _majorArcana = [
    _TarotCard(
        0, 'Der Narr', '🃏', 'Neuer Anfang, Vertrauen, Sprung ins Unbekannte'),
    _TarotCard(1, 'Der Magier', '🪄',
        'Willenskraft, Manifestation, alle Werkzeuge da'),
    _TarotCard(
        2, 'Die Hohepriesterin', '🌙', 'Intuition, verborgenes Wissen, Stille'),
    _TarotCard(3, 'Die Herrscherin', '👑', 'Fülle, Mutterprinzip, Schöpfung'),
    _TarotCard(
        4, 'Der Herrscher', '🏛️', 'Struktur, Vaterprinzip, Klarheit, Grenzen'),
    _TarotCard(
        5, 'Der Hierophant', '🔑', 'Tradition, Lehre, spirituelle Autorität'),
    _TarotCard(
        6, 'Die Liebenden', '💞', 'Wahl, Vereinigung, Werte-Entscheidung'),
    _TarotCard(7, 'Der Wagen', '🏎️',
        'Willenstriumph, Vorwärtsbewegung, Beherrschung'),
    _TarotCard(8, 'Die Kraft', '🦁', 'Sanfte Beherrschung, innere Stärke, Mut'),
    _TarotCard(
        9, 'Der Eremit', '🕯️', 'Rückzug, Selbstreflexion, innere Suche'),
    _TarotCard(10, 'Schicksalsrad', '🎡', 'Zyklen, Wandel, Schicksals-Drehung'),
    _TarotCard(11, 'Gerechtigkeit', '⚖️',
        'Karma, Wahrheit, Konsequenzen werden gewogen'),
    _TarotCard(12, 'Der Gehängte', '🙃', 'Hingabe, Perspektivwechsel, Pause'),
    _TarotCard(
        13, 'Der Tod', '💀', 'Transformation, Ende und Anfang, Loslassen'),
    _TarotCard(14, 'Die Mäßigung', '🌈', 'Alchemie, Synthese, Mittelweg'),
    _TarotCard(
        15, 'Der Teufel', '😈', 'Anhaftung, Sucht, selbstgewählte Ketten'),
    _TarotCard(
        16, 'Der Turm', '⚡', 'Plötzlicher Bruch, Erleuchtung durch Krise'),
    _TarotCard(17, 'Der Stern', '⭐', 'Hoffnung, Inspiration, Heilung'),
    _TarotCard(18, 'Der Mond', '🌑', 'Unbewusstes, Illusionen, Träume'),
    _TarotCard(19, 'Die Sonne', '☀️', 'Klarheit, Freude, vitale Lebenskraft'),
    _TarotCard(20, 'Das Gericht', '📯',
        'Erwachen, Neubewertung, Ruf zu höherem Selbst'),
    _TarotCard(
        21, 'Die Welt', '🌍', 'Vollendung, Ganzheit, Zyklus abgeschlossen'),
  ];

  _Spread? _selected;

  @override
  Widget build(BuildContext context) {
    if (_selected != null) {
      return _SpreadView(
        spread: _selected!,
        cards: _majorArcana,
        onBack: () => setState(() => _selected = null),
      );
    }
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _accent,
        title: const Row(children: [
          Text('🔮', style: TextStyle(fontSize: 22)),
          SizedBox(width: 10),
          Text('Tarot-Legesysteme',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ]),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          _buildSpreadCard(
            _Spread(
              name: 'Tageskarte',
              emoji: '🌅',
              positions: ['Heute'],
              description:
                  'Eine Karte für den Tag — schnelle Inspiration für aktuelle Themen.',
            ),
          ),
          _buildSpreadCard(
            _Spread(
              name: '3-Karten-Legung',
              emoji: '🃏',
              positions: ['Vergangenheit', 'Gegenwart', 'Zukunft'],
              description:
                  'Klassische Linien-Legung. Eignet sich für mittelfristige Fragen.',
            ),
          ),
          _buildSpreadCard(
            _Spread(
              name: 'Beziehung',
              emoji: '💞',
              positions: [
                'Du',
                'Andere/r',
                'Verbindung',
                'Was du brauchst',
                'Was er/sie braucht'
              ],
              description:
                  '5-Karten-Beziehungslegung. Für Klärung in Beziehungs-Fragen.',
            ),
          ),
          _buildSpreadCard(
            _Spread(
              name: 'Keltisches Kreuz',
              emoji: '✝️',
              positions: [
                'Gegenwart',
                'Herausforderung',
                'Wurzel/Vergangenheit',
                'Letzte Zukunft',
                'Mögliches Ergebnis',
                'Nahe Zukunft',
                'Du selbst',
                'Umfeld',
                'Hoffnungen/Ängste',
                'Endgültiges Ergebnis',
              ],
              description:
                  'Die klassische 10-Karten-Tiefenlegung für komplexe Lebensfragen.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpreadCard(_Spread s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _accent.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selected = s),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Text(s.emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    Text('${s.positions.length} Karten',
                        style: TextStyle(
                            color: _accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(s.description,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12, height: 1.4)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: _accent.withValues(alpha: 0.7)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Spread {
  final String name;
  final String emoji;
  final List<String> positions;
  final String description;
  const _Spread({
    required this.name,
    required this.emoji,
    required this.positions,
    required this.description,
  });
}

class _TarotCard {
  final int number;
  final String name;
  final String emoji;
  final String meaning;
  const _TarotCard(this.number, this.name, this.emoji, this.meaning);
}

class _SpreadView extends StatefulWidget {
  final _Spread spread;
  final List<_TarotCard> cards;
  final VoidCallback onBack;
  const _SpreadView(
      {required this.spread, required this.cards, required this.onBack});

  @override
  State<_SpreadView> createState() => _SpreadViewState();
}

class _SpreadViewState extends State<_SpreadView> {
  static const _bg = Color(0xFF06040F);
  static const _surface = Color(0xFF1A0A2E);
  static const _accent = Color(0xFF8E5AE2);

  List<_TarotCard> _drawn = [];

  @override
  void initState() {
    super.initState();
    _draw();
  }

  void _draw() {
    final rng = Random();
    final pool = List<_TarotCard>.from(widget.cards)..shuffle(rng);
    setState(() => _drawn = pool.take(widget.spread.positions.length).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _accent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        title: Row(children: [
          Text(widget.spread.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Text(widget.spread.name,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Neu ziehen',
            onPressed: _draw,
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _drawn.length,
        itemBuilder: (_, i) {
          final c = _drawn[i];
          final pos = widget.spread.positions[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_surface, _accent.withValues(alpha: 0.15)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _accent.withValues(alpha: 0.4)),
            ),
            child: Row(children: [
              Container(
                width: 64,
                height: 96,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_accent, Color(0xFF4A148C)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber, width: 1.5),
                ),
                child: Text(c.emoji, style: const TextStyle(fontSize: 32)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pos.toUpperCase(),
                        style: TextStyle(
                            color: _accent,
                            fontSize: 10,
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('${c.number}. ${c.name}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(c.meaning,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12, height: 1.5)),
                  ],
                ),
              ),
            ]),
          );
        },
      ),
    );
  }
}
