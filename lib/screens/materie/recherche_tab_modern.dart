import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../widgets/favorite_button.dart';
import '../../models/favorite.dart';
import 'materie_research_screen.dart';
import '../research/epstein_files_simple.dart';
import '../research/additional_sources_screen.dart';
import '../research/timeline_screen.dart';

/// Moderner Recherche-Tab im Spirit-Tab-Stil — Materie-Rot-Design
/// Alle Tools als navigierbare Karten, Kategorie-Filter, Suchleiste oben.
class RechercheTabModern extends StatefulWidget {
  const RechercheTabModern({super.key});

  @override
  State<RechercheTabModern> createState() => _RechercheTabModernState();
}

class _RechercheTabModernState extends State<RechercheTabModern>
    with TickerProviderStateMixin {

  // ── Colors (Materie = Rot/Kosmos) ──────────────────────────────────────
  static const _bg      = Color(0xFF08020A);
  static const _card    = Color(0xFF130A0A);
  static const _cardB   = Color(0xFF1A0A0A);
  static const _red     = Color(0xFFE53935);
  static const _redD    = Color(0xFF7F0000);
  static const _redL    = Color(0xFFEF9A9A);
  static const _amber   = Color(0xFFFFAB00);
  static const _cyan    = Color(0xFF00E5FF);
  static const _green   = Color(0xFF00E676);
  static const _purple  = Color(0xFF7C4DFF);

  // ── Animations ─────────────────────────────────────────────────────────
  late AnimationController _auraCtrl;
  late AnimationController _entryCtrl;
  late AnimationController _orbitCtrl;
  late Animation<double> _entryAnim;

  // ── State ──────────────────────────────────────────────────────────────
  String _selectedCategory = 'all';
  late final List<Map<String, dynamic>> _allTools;

  @override
  void initState() {
    super.initState();
    _auraCtrl  = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..forward();
    _orbitCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 14))
      ..repeat();
    _entryAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic);
    _initTools();
  }

  @override
  void dispose() {
    _auraCtrl.dispose();
    _entryCtrl.dispose();
    _orbitCtrl.dispose();
    super.dispose();
  }

  void _initTools() {
    _allTools = [
      // ── KI-ANALYSE ────────────────────────────────────────────────────
      {
        'iconEmoji': '🧠',
        'title': 'KI-Recherche',
        'subtitle': 'Tiefenanalyse via OpenClaw AI',
        'color': const Color(0xFFE53935),
        'category': 'ki',
        'routeOrScreen': () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const MaterieResearchScreen())),
      },
      {
        'iconEmoji': '👁️',
        'title': 'Propaganda\nDetector',
        'subtitle': 'Manipulation erkennen',
        'color': const Color(0xFFD32F2F),
        'category': 'ki',
        'routeOrScreen': () => Navigator.of(context).pushNamed('/propaganda-detector'),
      },
      {
        'iconEmoji': '🔍',
        'title': 'Image\nForensics',
        'subtitle': 'Bild-Manipulation analysieren',
        'color': const Color(0xFF1565C0),
        'category': 'ki',
        'routeOrScreen': () => Navigator.of(context).pushNamed('/image-forensics'),
      },
      {
        'iconEmoji': '🕸️',
        'title': 'Power\nNetwork',
        'subtitle': 'Machtnetzwerke visualisieren',
        'color': const Color(0xFF6A1B9A),
        'category': 'ki',
        'routeOrScreen': () => Navigator.of(context).pushNamed('/power-network-mapper'),
      },
      {
        'iconEmoji': '📈',
        'title': 'Event\nPredictor',
        'subtitle': 'Zukunfts-Szenarien analysieren',
        'color': const Color(0xFFF57F17),
        'category': 'ki',
        'routeOrScreen': () => Navigator.of(context).pushNamed('/event-predictor'),
      },

      // ── ARCHIVE & DOKUMENTE ───────────────────────────────────────────
      {
        'iconEmoji': '📁',
        'title': 'Epstein Files',
        'subtitle': 'Justice.gov Originaldokumente',
        'color': const Color(0xFFB71C1C),
        'category': 'archiv',
        'routeOrScreen': () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const EpsteinFilesSimpleScreen())),
      },
      {
        'iconEmoji': '📦',
        'title': 'Wayback\nArchiv',
        'subtitle': 'Internet Archive – gelöschte Seiten',
        'color': const Color(0xFF37474F),
        'category': 'archiv',
        'routeOrScreen': () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const MaterieResearchScreen())),
      },
      {
        'iconEmoji': '🔗',
        'title': 'Zusätzliche\nQuellen',
        'subtitle': 'Alternative Informationsquellen',
        'color': const Color(0xFF00695C),
        'category': 'archiv',
        'routeOrScreen': () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AdditionalSourcesScreen())),
      },

      // ── ZEITLINIE & KONTEXT ───────────────────────────────────────────
      {
        'iconEmoji': '📅',
        'title': 'Recherche\nTimeline',
        'subtitle': 'Ereignisse chronologisch',
        'color': const Color(0xFF00897B),
        'category': 'kontext',
        'routeOrScreen': () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ResearchTimelineScreen())),
      },
      {
        'iconEmoji': '🌍',
        'title': 'Geopolitik\nKarte',
        'subtitle': 'Interaktive Weltereignisse',
        'color': const Color(0xFF1565C0),
        'category': 'kontext',
        'routeOrScreen': () => Navigator.of(context).pushNamed('/geopolitik-map'),
      },
      {
        'iconEmoji': '📜',
        'title': 'Geschichte\nTimeline',
        'subtitle': 'Historische Ereignisse',
        'color': const Color(0xFF4E342E),
        'category': 'kontext',
        'routeOrScreen': () => Navigator.of(context).pushNamed('/history-timeline'),
      },
      {
        'iconEmoji': '🛸',
        'title': 'UFO\nSichtungen',
        'subtitle': 'Dokumentierte Fälle weltweit',
        'color': const Color(0xFF283593),
        'category': 'kontext',
        'routeOrScreen': () => Navigator.of(context).pushNamed('/ufo-sightings'),
      },

      // ── NETZWERKE & VERBINDUNGEN ──────────────────────────────────────
      {
        'iconEmoji': '🔬',
        'title': 'Forschungs\nArchiv',
        'subtitle': 'Wissenschaftliche Quellen',
        'color': const Color(0xFF01579B),
        'category': 'netzwerk',
        'routeOrScreen': () => Navigator.of(context).pushNamed('/research-archive'),
      },
      {
        'iconEmoji': '💊',
        'title': 'Alternative\nHeilmethoden',
        'subtitle': 'Naturheilkunde & Forschung',
        'color': const Color(0xFF2E7D32),
        'category': 'netzwerk',
        'routeOrScreen': () => Navigator.of(context).pushNamed('/alternative-healing'),
      },
      {
        'iconEmoji': '🏛️',
        'title': 'Conspiracy\nNetzwerk',
        'subtitle': 'Verbindungen visualisieren',
        'color': const Color(0xFF4527A0),
        'category': 'netzwerk',
        'routeOrScreen': () => Navigator.of(context).pushNamed('/conspiracy-network'),
      },
      {
        'iconEmoji': '📰',
        'title': 'Guardian\nNews',
        'subtitle': 'Unabhängige Nachrichtenquellen',
        'color': const Color(0xFF1B5E20),
        'category': 'netzwerk',
        'routeOrScreen': () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const MaterieResearchScreen())),
      },
    ];
  }

  List<Map<String, dynamic>> get _filteredTools {
    if (_selectedCategory == 'all') return _allTools;
    return _allTools.where((t) => t['category'] == _selectedCategory).toList();
  }

  int _count(String cat) {
    if (cat == 'all') return _allTools.length;
    return _allTools.where((t) => t['category'] == cat).length;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: const TextStyle(
        decoration: TextDecoration.none,
        decorationColor: Colors.transparent,
        fontFamily: 'Roboto',
        letterSpacing: 0.1,
        height: 1.25,
      ),
      child: Scaffold(
        backgroundColor: _bg,
        body: RefreshIndicator(
          onRefresh: () async => setState(() {}),
          color: _red,
          backgroundColor: _cardB,
          displacement: 60,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              _buildHeroHeader(),
              _buildCategoryFilter(),
              _buildDailyQuote(),
              _buildToolsGrid(),
              const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
            ],
          ),
        ),
      ),
    );
  }

  // ── HERO HEADER ────────────────────────────────────────────────────────
  Widget _buildHeroHeader() {
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _entryAnim,
        child: SizedBox(
          height: 200,
          child: Stack(
            children: [
              AnimatedBuilder(
                animation: _orbitCtrl,
                builder: (_, __) => CustomPaint(
                  painter: _RechercheCosmosPainter(
                    orbitProgress: _orbitCtrl.value,
                    auraProgress: _auraCtrl.value,
                    color: _red,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, _bg],
                    stops: const [0.45, 1.0],
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildRedOrb(),
                      const SizedBox(width: 14),
                      Expanded(child: _buildHeaderText()),
                      _buildToolCountBadge(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRedOrb() {
    return AnimatedBuilder(
      animation: _auraCtrl,
      builder: (_, __) => Container(
        width: 54, height: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              _red.withValues(alpha: 0.45 + _auraCtrl.value * 0.2),
              _redD.withValues(alpha: 0.1),
            ],
          ),
          border: Border.all(
              color: _redL.withValues(alpha: 0.4 + _auraCtrl.value * 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: _red.withValues(alpha: 0.25 + _auraCtrl.value * 0.2),
              blurRadius: 18, spreadRadius: 3,
            ),
          ],
        ),
        child: const Center(
          child: Text('🔍', style: TextStyle(fontSize: 24)),
        ),
      ),
    );
  }

  Widget _buildHeaderText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('🔎 Recherche Tools',
            style: TextStyle(color: Colors.white54, fontSize: 12,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        const Text('Wahrheit finden',
            style: TextStyle(color: Colors.white, fontSize: 20,
                fontWeight: FontWeight.bold, letterSpacing: -0.3),
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 3),
        Row(children: [
          AnimatedBuilder(
            animation: _auraCtrl,
            builder: (_, __) => Container(
              width: 6, height: 6,
              decoration: BoxDecoration(
                color: _red.withValues(alpha: 0.5 + _auraCtrl.value * 0.5),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: _red.withValues(alpha: 0.5), blurRadius: 4)],
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Text('Welt der MATERIE',
              style: TextStyle(color: Colors.white38, fontSize: 11)),
        ]),
      ],
    );
  }

  Widget _buildToolCountBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('${_allTools.length}',
            style: const TextStyle(color: _redL, fontSize: 18,
                fontWeight: FontWeight.bold)),
        const Text('Tools',
            style: TextStyle(color: Colors.white38, fontSize: 9,
                fontWeight: FontWeight.w500)),
      ]),
    );
  }

  // ── CATEGORY FILTER ────────────────────────────────────────────────────
  Widget _buildCategoryFilter() {
    return SliverToBoxAdapter(
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
            .animate(_entryAnim),
        child: FadeTransition(
          opacity: _entryAnim,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(children: [
                _chip('all',      '🔎 Alle',       _red,    _count('all')),
                const SizedBox(width: 10),
                _chip('ki',       '🧠 KI-Analyse', _amber,  _count('ki')),
                const SizedBox(width: 10),
                _chip('archiv',   '📁 Archiv',     _cyan,   _count('archiv')),
                const SizedBox(width: 10),
                _chip('kontext',  '🌍 Kontext',    _green,  _count('kontext')),
                const SizedBox(width: 10),
                _chip('netzwerk', '🕸️ Netzwerk',  _purple, _count('netzwerk')),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(String cat, String label, Color color, int count) {
    final sel = _selectedCategory == cat;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = cat),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: sel
              ? LinearGradient(colors: [color.withValues(alpha: 0.7), color.withValues(alpha: 0.3)])
              : null,
          color: sel ? null : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: sel ? color : Colors.white.withValues(alpha: 0.15),
            width: sel ? 2 : 1,
          ),
          boxShadow: sel
              ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]
              : null,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label,
              style: TextStyle(color: Colors.white, fontSize: 13,
                  fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: sel ? Colors.white.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$count',
                style: TextStyle(
                    color: sel ? Colors.white : Colors.white54,
                    fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ]),
      ),
    );
  }

  // ── DAILY QUOTE ────────────────────────────────────────────────────────
  Widget _buildDailyQuote() {
    final quotes = [
      '"Wer die Vergangenheit kontrolliert, kontrolliert die Zukunft." — Orwell',
      '"Die gefährlichste Unwahrheit ist die Wahrheit, die leicht verdreht wurde."',
      '"Folge nicht der Herde — folge der Wahrheit, auch wenn du allein gehst."',
      '"Information ist Macht. Wissen ist Freiheit."',
      '"Die erste Aufgabe der Regierung ist es, sich selbst zu regieren." — Calhoun',
    ];
    final quote = quotes[DateTime.now().day % quotes.length];

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
        child: AnimatedBuilder(
          animation: _auraCtrl,
          builder: (_, __) => Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _redD.withValues(alpha: 0.8),
                  _red.withValues(alpha: 0.3 + _auraCtrl.value * 0.1),
                  _amber.withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _redL.withValues(alpha: 0.2 + _auraCtrl.value * 0.1)),
              boxShadow: [
                BoxShadow(
                  color: _red.withValues(alpha: 0.12 + _auraCtrl.value * 0.08),
                  blurRadius: 20, offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(children: [
              AnimatedBuilder(
                animation: _orbitCtrl,
                builder: (_, __) => Transform.rotate(
                  angle: _orbitCtrl.value * math.pi * 2 * 0.06,
                  child: Text('🔎',
                      style: TextStyle(fontSize: 30 + _auraCtrl.value * 3)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Täglicher Gedanke',
                      style: TextStyle(color: Colors.white, fontSize: 13,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(quote,
                      style: TextStyle(
                          color: _redL.withValues(alpha: 0.85),
                          fontSize: 11, fontStyle: FontStyle.italic, height: 1.4)),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ── TOOLS GRID ─────────────────────────────────────────────────────────
  Widget _buildToolsGrid() {
    final tools = _filteredTools;
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.82,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, i) => _buildToolCard(tools[i]),
          childCount: tools.length,
        ),
      ),
    );
  }

  Widget _buildToolCard(Map<String, dynamic> tool) {
    final color = tool['color'] as Color;
    return GestureDetector(
      onTap: () => (tool['routeOrScreen'] as VoidCallback)(),
      child: Container(
        decoration: BoxDecoration(
          color: _card,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withValues(alpha: 0.18), _card],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.15),
                blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(children: [
            Positioned(
              right: -18, bottom: -18,
              child: Container(
                width: 70, height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.08),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [
                            color.withValues(alpha: 0.45),
                            color.withValues(alpha: 0.1),
                          ]),
                          border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
                        ),
                        child: Center(
                          child: Text(tool['iconEmoji'] as String,
                              style: const TextStyle(fontSize: 24)),
                        ),
                      ),
                      FavoriteButton(
                        itemId: 'recherche_tool_${tool['title']}',
                        itemType: FavoriteType.narrative,
                        itemTitle: (tool['title'] as String).replaceAll('\n', ' '),
                        itemDescription: tool['subtitle'] as String?,
                        size: 20,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(tool['title'] as String,
                      style: const TextStyle(color: Colors.white, fontSize: 15,
                          fontWeight: FontWeight.bold),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(tool['subtitle'] as String,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        color.withValues(alpha: 0.55),
                        color.withValues(alpha: 0.25),
                      ]),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withValues(alpha: 0.5)),
                    ),
                    child: const Center(
                      child: Text('Öffnen',
                          style: TextStyle(color: Colors.white, fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── COSMOS PAINTER ─────────────────────────────────────────────────────────
class _RechercheCosmosPainter extends CustomPainter {
  final double orbitProgress;
  final double auraProgress;
  final Color color;

  const _RechercheCosmosPainter({
    required this.orbitProgress,
    required this.auraProgress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final cy = size.height * 0.45;

    for (int i = 3; i >= 0; i--) {
      final radius = 60.0 + i * 28 + auraProgress * 14;
      final alpha  = (0.06 - i * 0.012) + auraProgress * 0.02;
      canvas.drawCircle(Offset(cx, cy), radius,
          Paint()..color = color.withValues(alpha: alpha.clamp(0.0, 1.0)));
    }

    for (int i = 0; i < 6; i++) {
      final angle = orbitProgress * math.pi * 2 + i * math.pi * 2 / 6;
      final r = 75.0 + i * 5.0;
      canvas.drawCircle(
        Offset(cx + math.cos(angle) * r, cy + math.sin(angle) * r * 0.4),
        2.5,
        Paint()..color = color.withValues(alpha: 0.22 + auraProgress * 0.15),
      );
    }
  }

  @override
  bool shouldRepaint(_RechercheCosmosPainter old) => true;
}
