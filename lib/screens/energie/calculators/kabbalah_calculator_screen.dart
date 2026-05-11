import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 🌳 Kabbala-Rechner – Interaktiver Lebensbaum mit 10 Sephiroth
/// Cinema-Stil mit animiertem Tree of Life (CustomPainter)
class KabbalahCalculatorScreen extends StatefulWidget {
  const KabbalahCalculatorScreen({super.key});

  @override
  State<KabbalahCalculatorScreen> createState() =>
      _KabbalahCalculatorScreenState();
}

class _KabbalahCalculatorScreenState extends State<KabbalahCalculatorScreen>
    with TickerProviderStateMixin {
  late final AnimationController _treeCtrl;
  late final TabController _tabCtrl;

  int? _selectedSephira; // null = keiner ausgewählt

  @override
  void initState() {
    super.initState();
    _treeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _treeCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  void _onTreeTap(TapDownDetails details, Size canvasSize) {
    const positions = _TreeOfLifePainter.sephirothPos;
    for (int i = 0; i < positions.length; i++) {
      final pos = Offset(
        positions[i].dx * canvasSize.width,
        positions[i].dy * canvasSize.height,
      );
      if ((details.localPosition - pos).distance < 24) {
        setState(() =>
            _selectedSephira = (_selectedSephira == i) ? null : i);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06040F),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            backgroundColor: const Color(0xFF06040F),
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white70),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Baum des Lebens',
              style: TextStyle(
                color: Color(0xFF00BCD4),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            bottom: TabBar(
              controller: _tabCtrl,
              indicatorColor: const Color(0xFF00BCD4),
              labelColor: const Color(0xFF00BCD4),
              unselectedLabelColor: Colors.white38,
              tabs: const [
                Tab(text: 'Lebensbaum'),
                Tab(text: 'Die 10 Sephiroth'),
                Tab(text: 'Die 22 Pfade'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _buildTreeTab(),
            _buildSephirothTab(),
            _buildPathsTab(),
          ],
        ),
      ),
    );
  }

  // ── Tab 1: Interaktiver Lebensbaum ───────────────────────────────────────

  Widget _buildTreeTab() {
    return Column(
      children: [
        // Tree of Life Canvas
        Expanded(
          flex: 3,
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF00BCD4).withValues(alpha: 0.15),
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size =
                    Size(constraints.maxWidth, constraints.maxHeight);
                return GestureDetector(
                  onTapDown: (d) => _onTreeTap(d, size),
                  child: AnimatedBuilder(
                    animation: _treeCtrl,
                    builder: (context, child) => CustomPaint(
                      size: size,
                      painter: _TreeOfLifePainter(
                        animValue: _treeCtrl.value,
                        selectedSephira: _selectedSephira,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // Detail-Karte der ausgewählten Sephira
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _selectedSephira != null
              ? _buildSephiraDetail(_kSephiroth[_selectedSephira!])
              : Container(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Tippe auf eine Sephira um Details zu sehen',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
        ),

        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSephiraDetail(Map<String, dynamic> s) {
    final color = s['color'] as Color;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.2),
                  border: Border.all(color: color.withValues(alpha: 0.6)),
                ),
                child: Center(
                  child: Text(
                    '${_kSephiroth.indexOf(s) + 1}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s['name'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${s['hebrew'] as String} · ${s['meaning'] as String}',
                      style: TextStyle(
                        color: color.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: (s['themes'] as List<String>).map((t) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Text(t,
                  style: TextStyle(color: color, fontSize: 11)),
            )).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            s['lesson'] as String,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 2: Alle 10 Sephiroth ─────────────────────────────────────────────

  Widget _buildSephirothTab() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: _kSephiroth.length,
      itemBuilder: (context, i) {
        final s = _kSephiroth[i];
        final color = s['color'] as Color;
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.2),
                      border: Border.all(color: color.withValues(alpha: 0.6)),
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s['name'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          '${s['hebrew'] as String} – ${s['meaning'] as String}',
                          style: TextStyle(
                            color: color.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      s['pillar'] as String,
                      style: TextStyle(color: color, fontSize: 10),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Info rows
              _detailRow('Gott-Name', s['godName'] as String, color),
              _detailRow('Erz-Engel', s['archangel'] as String, color),
              _detailRow('Körper', s['body'] as String, color),
              _detailRow('Planet', s['planet'] as String, color),

              const SizedBox(height: 8),

              Text(
                s['lesson'] as String,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 8),

              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: (s['themes'] as List<String>)
                    .map((t) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: color.withValues(alpha: 0.25)),
                          ),
                          child: Text(t,
                              style:
                                  TextStyle(color: color, fontSize: 10)),
                        ))
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 3: Die 22 Pfade ──────────────────────────────────────────────────

  Widget _buildPathsTab() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: _kPaths.length,
      itemBuilder: (context, i) {
        final p = _kPaths[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFFFD54F).withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: [
              // Pfadnummer
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFD54F).withValues(alpha: 0.1),
                  border: Border.all(
                      color: const Color(0xFFFFD54F).withValues(alpha: 0.3)),
                ),
                child: Center(
                  child: Text(
                    '${i + 11}',
                    style: const TextStyle(
                      color: Color(0xFFFFD54F),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${p['from']} → ${p['to']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFAB47BC).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            p['letter'] as String,
                            style: const TextStyle(
                                color: Color(0xFFAB47BC), fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${p['tarot'] as String} · ${p['meaning'] as String}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Tree of Life Painter ─────────────────────────────────────────────────────

class _TreeOfLifePainter extends CustomPainter {
  final double animValue;
  final int? selectedSephira;

  _TreeOfLifePainter({required this.animValue, required this.selectedSephira});

  // 10 Sephiroth Positionen (normalisiert 0-1)
  static const sephirothPos = [
    Offset(0.5, 0.06),   // 1 Kether
    Offset(0.75, 0.19),  // 2 Chokmah
    Offset(0.25, 0.19),  // 3 Binah
    Offset(0.75, 0.38),  // 4 Chesed
    Offset(0.25, 0.38),  // 5 Geburah
    Offset(0.5, 0.51),   // 6 Tiphareth
    Offset(0.75, 0.64),  // 7 Netzach
    Offset(0.25, 0.64),  // 8 Hod
    Offset(0.5, 0.75),   // 9 Yesod
    Offset(0.5, 0.90),   // 10 Malkuth
  ];

  static const _sephirothColors = [
    Color(0xFFFFFFFF), // Kether
    Color(0xFFB0BEC5), // Chokmah
    Color(0xFF424242), // Binah
    Color(0xFF42A5F5), // Chesed
    Color(0xFFEF5350), // Geburah
    Color(0xFFFFEE58), // Tiphareth
    Color(0xFF66BB6A), // Netzach
    Color(0xFFFF7043), // Hod
    Color(0xFF7E57C2), // Yesod
    Color(0xFF795548), // Malkuth
  ];

  // 22 Pfade
  static const _paths = [
    [0, 1], [0, 2], [0, 5],
    [1, 2], [1, 3], [1, 5],
    [2, 4], [2, 5],
    [3, 4], [3, 5], [3, 6],
    [4, 5], [4, 7],
    [5, 6], [5, 7], [5, 8],
    [6, 7], [6, 8],
    [7, 8],
    [8, 9],
    [6, 9], [7, 9],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // Pfade zeichnen (zuerst)
    for (final path in _paths) {
      final start = Offset(
        sephirothPos[path[0]].dx * size.width,
        sephirothPos[path[0]].dy * size.height,
      );
      final end = Offset(
        sephirothPos[path[1]].dx * size.width,
        sephirothPos[path[1]].dy * size.height,
      );

      final pathPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.18 + animValue * 0.08)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      canvas.drawLine(start, end, pathPaint);
    }

    // Sephiroth zeichnen
    for (int i = 0; i < 10; i++) {
      final pos = Offset(
        sephirothPos[i].dx * size.width,
        sephirothPos[i].dy * size.height,
      );
      final color = _sephirothColors[i];
      final isSelected = selectedSephira == i;
      final radius = isSelected ? 20.0 : 14.0;

      // Glow
      final glowPaint = Paint()
        ..color = color.withValues(
            alpha: (0.25 + animValue * 0.2) * (isSelected ? 2.0 : 1.0))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(pos, radius + 8, glowPaint);

      // Fill
      canvas.drawCircle(
        pos,
        radius,
        Paint()..color = color.withValues(alpha: 0.85),
      );

      // Border
      canvas.drawCircle(
        pos,
        radius,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 2.5 : 1.2,
      );

      // Nummer
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: TextStyle(
            color: i == 1 || i == 2
                ? Colors.black87
                : Colors.black.withValues(alpha: 0.8),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        pos - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(_TreeOfLifePainter old) =>
      old.animValue != animValue || old.selectedSephira != selectedSephira;
}

// ── Daten ─────────────────────────────────────────────────────────────────────

const List<Map<String, dynamic>> _kSephiroth = [
  {
    'name': 'Kether',
    'hebrew': 'כֶּתֶר',
    'meaning': 'Krone',
    'pillar': 'Mitte',
    'color': Color(0xFFFFFFFF),
    'godName': 'Ehyeh (Ich bin)',
    'archangel': 'Metatron',
    'body': 'Kronenchakra / Pinealdrüse',
    'planet': 'Erstes Schwirren',
    'lesson': 'Die höchste Einheit. Ursprung alles Seins. Hier ist kein Unterschied, nur reines Bewusstsein.',
    'themes': ['Einheit', 'Göttlicher Wille', 'Ursprung', 'Stille'],
  },
  {
    'name': 'Chokmah',
    'hebrew': 'חָכְמָה',
    'meaning': 'Weisheit',
    'pillar': 'Gnade',
    'color': Color(0xFFB0BEC5),
    'godName': 'Jah',
    'archangel': 'Ratziel',
    'body': 'Linke Hirnhälfte / Linkes Auge',
    'planet': 'Tierkreis / Fixsterne',
    'lesson': 'Dynamische Weisheit. Erster Impuls des Schöpfers in die Existenz. Maskulines Prinzip.',
    'themes': ['Weisheit', 'Maskulinität', 'Inspiration', 'Urimpuls'],
  },
  {
    'name': 'Binah',
    'hebrew': 'בִּינָה',
    'meaning': 'Verständnis',
    'pillar': 'Schwere',
    'color': Color(0xFF424242),
    'godName': 'Elohim',
    'archangel': 'Tzaphkiel',
    'body': 'Rechte Hirnhälfte / Rechtes Auge',
    'planet': 'Saturn',
    'lesson': 'Empfangende Intelligenz. Form und Begrenzung. Feminines Prinzip. Große Mutter.',
    'themes': ['Verständnis', 'Form', 'Feminines Prinzip', 'Zeit'],
  },
  {
    'name': 'Chesed',
    'hebrew': 'חֶסֶד',
    'meaning': 'Gnade / Güte',
    'pillar': 'Gnade',
    'color': Color(0xFF42A5F5),
    'godName': 'El',
    'archangel': 'Tzadkiel',
    'body': 'Linker Arm / Linke Schulter',
    'planet': 'Jupiter',
    'lesson': 'Göttliche Gnade und Barmherzigkeit. Ausdehnung und Fülle. Königliche Großzügigkeit.',
    'themes': ['Gnade', 'Güte', 'Fülle', 'Liebe'],
  },
  {
    'name': 'Geburah',
    'hebrew': 'גְּבוּרָה',
    'meaning': 'Stärke / Gericht',
    'pillar': 'Schwere',
    'color': Color(0xFFEF5350),
    'godName': 'Elohim Gibor',
    'archangel': 'Kamael',
    'body': 'Rechter Arm / Rechte Schulter',
    'planet': 'Mars',
    'lesson': 'Göttliches Gericht und Stärke. Beschränkung des Übermaßes. Spirituelle Disziplin.',
    'themes': ['Stärke', 'Mut', 'Gericht', 'Reinigung'],
  },
  {
    'name': 'Tiphareth',
    'hebrew': 'תִּפְאֶרֶת',
    'meaning': 'Schönheit',
    'pillar': 'Mitte',
    'color': Color(0xFFFFEE58),
    'godName': 'YHVH Aloah ve-Daath',
    'archangel': 'Raphael',
    'body': 'Herz / Brust',
    'planet': 'Sonne',
    'lesson': 'Zentrum des Lebensbaums. Harmonie aller Kräfte. Sitz des höheren Selbst.',
    'themes': ['Harmonie', 'Schönheit', 'Christusbewusstsein', 'Heilung'],
  },
  {
    'name': 'Netzach',
    'hebrew': 'נֶצַח',
    'meaning': 'Sieg / Ewigkeit',
    'pillar': 'Gnade',
    'color': Color(0xFF66BB6A),
    'godName': 'YHVH Tzabaoth',
    'archangel': 'Haniel',
    'body': 'Linke Hüfte / Linkes Bein',
    'planet': 'Venus',
    'lesson': 'Natürliche Welt, Emotion und Begehren. Sieg durch Ausdauer. Kreativität und Kunst.',
    'themes': ['Natur', 'Emotion', 'Kreativität', 'Liebe'],
  },
  {
    'name': 'Hod',
    'hebrew': 'הוֹד',
    'meaning': 'Herrlichkeit / Pracht',
    'pillar': 'Schwere',
    'color': Color(0xFFFF7043),
    'godName': 'Elohim Tzabaoth',
    'archangel': 'Michael',
    'body': 'Rechte Hüfte / Rechtes Bein',
    'planet': 'Merkur',
    'lesson': 'Intellekt in Aktion. Sprache, Kommunikation, Magie. Splendor des göttlichen Lichts.',
    'themes': ['Intellekt', 'Sprache', 'Magie', 'Kommunikation'],
  },
  {
    'name': 'Yesod',
    'hebrew': 'יְסוֹד',
    'meaning': 'Fundament',
    'pillar': 'Mitte',
    'color': Color(0xFF7E57C2),
    'godName': 'Shaddai El Chai',
    'archangel': 'Gabriel',
    'body': 'Reproduktionsorgane / Sakralchakra',
    'planet': 'Mond',
    'lesson': 'Astrale Welt. Unbewusstes. Verbindung zwischen dem Göttlichen und der Manifestation.',
    'themes': ['Unterbewusstsein', 'Mond', 'Träume', 'Astral'],
  },
  {
    'name': 'Malkuth',
    'hebrew': 'מַלְכוּת',
    'meaning': 'Königreich',
    'pillar': 'Mitte',
    'color': Color(0xFF795548),
    'godName': 'Adonai ha-Aretz',
    'archangel': 'Sandalphon',
    'body': 'Füße / Wurzelchakra',
    'planet': 'Erde',
    'lesson': 'Physische Manifestation. Erde als heiliger Ort. Das Ziel aller spirituellen Energien.',
    'themes': ['Erdung', 'Materie', 'Manifestation', 'Königreich'],
  },
];

const List<Map<String, String>> _kPaths = [
  {'from': 'Kether', 'to': 'Chokmah', 'letter': 'Aleph א', 'tarot': 'Der Narr (0)', 'meaning': 'Reiner Geist, göttliche Torheit'},
  {'from': 'Kether', 'to': 'Binah', 'letter': 'Beth ב', 'tarot': 'Der Magier (I)', 'meaning': 'Schöpferischer Wille'},
  {'from': 'Kether', 'to': 'Tiphareth', 'letter': 'Gimel ג', 'tarot': 'Die Hohepriesterin (II)', 'meaning': 'Intuition, verborgenes Wissen'},
  {'from': 'Chokmah', 'to': 'Binah', 'letter': 'Daleth ד', 'tarot': 'Die Kaiserin (III)', 'meaning': 'Fruchtbarkeit, Natur'},
  {'from': 'Chokmah', 'to': 'Tiphareth', 'letter': 'Vau ו', 'tarot': 'Der Hierophant (V)', 'meaning': 'Spirituelle Führung'},
  {'from': 'Chokmah', 'to': 'Chesed', 'letter': 'Heh ה', 'tarot': 'Der Kaiser (IV)', 'meaning': 'Autorität, Struktur'},
  {'from': 'Binah', 'to': 'Tiphareth', 'letter': 'Zayin ז', 'tarot': 'Die Liebenden (VI)', 'meaning': 'Wahl, Verbindung'},
  {'from': 'Binah', 'to': 'Geburah', 'letter': 'Cheth ח', 'tarot': 'Der Wagen (VII)', 'meaning': 'Triumph durch Kontrolle'},
  {'from': 'Chesed', 'to': 'Geburah', 'letter': 'Teth ט', 'tarot': 'Die Stärke (VIII)', 'meaning': 'Innere Stärke'},
  {'from': 'Chesed', 'to': 'Tiphareth', 'letter': 'Yod י', 'tarot': 'Der Eremit (IX)', 'meaning': 'Innere Weisheit, Einsamkeit'},
  {'from': 'Chesed', 'to': 'Netzach', 'letter': 'Kaph כ', 'tarot': 'Das Rad des Schicksals (X)', 'meaning': 'Zyklus, Karma'},
  {'from': 'Geburah', 'to': 'Tiphareth', 'letter': 'Lamed ל', 'tarot': 'Die Gerechtigkeit (XI)', 'meaning': 'Kausalität, Balance'},
  {'from': 'Geburah', 'to': 'Hod', 'letter': 'Mem מ', 'tarot': 'Der Gehängte (XII)', 'meaning': 'Hingabe, neues Blickfeld'},
  {'from': 'Tiphareth', 'to': 'Netzach', 'letter': 'Nun נ', 'tarot': 'Der Tod (XIII)', 'meaning': 'Transformation, Übergang'},
  {'from': 'Tiphareth', 'to': 'Hod', 'letter': 'Samekh ס', 'tarot': 'Die Mäßigkeit (XIV)', 'meaning': 'Integration, Balance'},
  {'from': 'Tiphareth', 'to': 'Yesod', 'letter': 'Ayin ע', 'tarot': 'Der Teufel (XV)', 'meaning': 'Bindungen lösen'},
  {'from': 'Netzach', 'to': 'Hod', 'letter': 'Peh פ', 'tarot': 'Der Turm (XVI)', 'meaning': 'Plötzlicher Wandel'},
  {'from': 'Netzach', 'to': 'Yesod', 'letter': 'Tzaddi צ', 'tarot': 'Der Stern (XVII)', 'meaning': 'Hoffnung, Erneuerung'},
  {'from': 'Hod', 'to': 'Yesod', 'letter': 'Qoph ק', 'tarot': 'Der Mond (XVIII)', 'meaning': 'Illusion, Unterbewusstsein'},
  {'from': 'Netzach', 'to': 'Malkuth', 'letter': 'Resh ר', 'tarot': 'Die Sonne (XIX)', 'meaning': 'Erleuchtung, Freude'},
  {'from': 'Hod', 'to': 'Malkuth', 'letter': 'Shin ש', 'tarot': 'Das Gericht (XX)', 'meaning': 'Erwachen, Neugeburt'},
  {'from': 'Yesod', 'to': 'Malkuth', 'letter': 'Tav ת', 'tarot': 'Die Welt (XXI)', 'meaning': 'Vollendung, Ganzheit'},
];
