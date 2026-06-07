// 💡 HIDDEN FACTS - Cinematic Karten-Stack Screen
//
// Ersetzt den vorherigen Standard-AlertDialog im Easter Egg Menue.
// Cinematic Glassmorphism + Welt-neutrale Akzente + Karten-Stack-UI
// mit Swipe/Tap-Navigation + Favoriten-System via SharedPreferences.

import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/hidden_facts.dart';
import '../../theme/wb_cinematic_tokens.dart';
import '../../widgets/cinematic/wb_ambient_particles.dart';
import '../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../widgets/cinematic/wb_vignette.dart';

class HiddenFactsScreen extends StatefulWidget {
  const HiddenFactsScreen({super.key});

  @override
  State<HiddenFactsScreen> createState() => _HiddenFactsScreenState();
}

class _HiddenFactsScreenState extends State<HiddenFactsScreen>
    with TickerProviderStateMixin {
  static const Color _bgDark = Color(0xFF03020A);

  /// Theme-aware background. Light-Mode liefert helle `context.wb.bgVoid`,
  /// Dark-Mode behält den Original-Ton.
  Color _bg(BuildContext context) {
    final wb = Theme.of(context).extension<WBCinematic>();
    return wb?.bgVoid ?? _bgDark;
  }

  static const Color _primary = Color(0xFFFFA726); // Hidden-Facts Orange
  static const Color _gold = Color(0xFFFFD700);

  static const _kFavoritesKey = 'hidden_facts_favorites_v1';
  static const _kSeenKey = 'hidden_facts_seen_v1';

  late final AnimationController _ambientCtrl;
  late final AnimationController _enterCtrl;
  late final PageController _pageCtrl;
  int _currentIndex = 0;
  late List<Map<String, String>> _facts;
  Set<String> _favorites = <String>{};
  Set<String> _seen = <String>{};
  String _filter = 'Alle'; // 'Alle' oder Kategorie-Name

  List<String> get _categories {
    final cats = HiddenFacts.facts
        .map((f) => f['category'] ?? '')
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['Alle', ...cats];
  }

  @override
  void initState() {
    super.initState();
    _facts = HiddenFacts.getAllFacts();
    _ambientCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _pageCtrl = PageController(viewportFraction: 0.85);
    _loadPrefs();
  }

  @override
  void dispose() {
    _ambientCtrl.dispose();
    _enterCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favRaw = prefs.getString(_kFavoritesKey);
      final seenRaw = prefs.getString(_kSeenKey);
      if (mounted) {
        setState(() {
          if (favRaw != null) {
            try {
              _favorites = (jsonDecode(favRaw) as List).cast<String>().toSet();
            } catch (e) { if (kDebugMode) debugPrint('hidden_facts_screen: silent catch -> $e'); }
          }
          if (seenRaw != null) {
            try {
              _seen = (jsonDecode(seenRaw) as List).cast<String>().toSet();
            } catch (e) { if (kDebugMode) debugPrint('hidden_facts_screen: silent catch -> $e'); }
          }
        });
      }
    } catch (e) { if (kDebugMode) debugPrint('hidden_facts_screen: silent catch -> $e'); }
    _markSeen(_currentIndex);
  }

  Future<void> _persistFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kFavoritesKey, jsonEncode(_favorites.toList()));
    } catch (e) { if (kDebugMode) debugPrint('hidden_facts_screen: silent catch -> $e'); }
  }

  Future<void> _persistSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kSeenKey, jsonEncode(_seen.toList()));
    } catch (e) { if (kDebugMode) debugPrint('hidden_facts_screen: silent catch -> $e'); }
  }

  String _idFor(Map<String, String> fact) => fact['title'] ?? '';

  void _markSeen(int idx) {
    final visible = _visibleFacts;
    if (idx < 0 || idx >= visible.length) return;
    final id = _idFor(visible[idx]);
    if (id.isEmpty || _seen.contains(id)) return;
    setState(() => _seen.add(id));
    _persistSeen();
  }

  void _toggleFavorite(Map<String, String> fact) {
    final id = _idFor(fact);
    if (id.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      if (_favorites.contains(id)) {
        _favorites.remove(id);
      } else {
        _favorites.add(id);
      }
    });
    _persistFavorites();
  }

  List<Map<String, String>> get _visibleFacts {
    if (_filter == 'Alle') return _facts;
    if (_filter == '★ Favoriten') {
      return _facts.where((f) => _favorites.contains(_idFor(f))).toList();
    }
    return _facts.where((f) => (f['category'] ?? '') == _filter).toList();
  }

  void _setFilter(String f) {
    HapticFeedback.selectionClick();
    setState(() {
      _filter = f;
      _currentIndex = 0;
    });
    if (_pageCtrl.hasClients) {
      _pageCtrl.jumpToPage(0);
    }
    _markSeen(0);
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleFacts;
    return Scaffold(
      backgroundColor: _bg(context),
      extendBodyBehindAppBar: true,
      appBar: WBGlassAppBar(
        world: WBWorld.neutral,
        titleWidget: ShaderMask(
          shaderCallback: (r) => const LinearGradient(
            colors: [_gold, _primary],
          ).createShader(r),
          child: const Text(
            'WUSSTEN SIE SCHON?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.5,
            ),
          ),
        ),
      ),
      body: Stack(fit: StackFit.expand, children: [
        // Radial-Gradient Hintergrund
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.4,
              colors: [Color(0x55663C00), Color(0x33331E00), _bgDark],
            ),
          ),
        ),
        // Orbs
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _ambientCtrl,
            builder: (_, __) => CustomPaint(
              painter: _HfOrbsPainter(_ambientCtrl.value),
              size: Size.infinite,
            ),
          ),
        ),
        const IgnorePointer(
          child: WBAmbientParticles(world: WBWorld.neutral, count: 50),
        ),

        // Content
        SafeArea(
          child: FadeTransition(
            opacity: _enterCtrl,
            child: Column(children: [
              const SizedBox(height: 8),
              _buildStatsHeader(),
              const SizedBox(height: 12),
              _buildFilterChips(),
              const SizedBox(height: 8),
              if (visible.isEmpty)
                Expanded(child: _buildEmptyState())
              else
                Expanded(child: _buildCardStack(visible)),
              const SizedBox(height: 8),
              if (visible.isNotEmpty) _buildBottomBar(visible),
              const SizedBox(height: 16),
            ]),
          ),
        ),

        const IgnorePointer(child: WBVignette()),
      ]),
    );
  }

  Widget _buildStatsHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _stat('${_facts.length}', 'Fakten gesamt'),
          _stat('${_seen.length}', 'Gesehen', accent: _gold),
          _stat('${_favorites.length}', 'Favoriten', accent: _primary),
        ],
      ),
    );
  }

  Widget _stat(String value, String label, {Color accent = Colors.white}) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
              color: accent,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              shadows: [
                Shadow(color: accent.withValues(alpha: 0.5), blurRadius: 8)
              ],
            )),
        Text(label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 10,
              letterSpacing: 1,
            )),
      ],
    );
  }

  Widget _buildFilterChips() {
    final cats = [
      'Alle',
      '★ Favoriten',
      ..._categories.where((c) => c != 'Alle')
    ];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: cats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final c = cats[i];
          final selected = c == _filter;
          return GestureDetector(
            onTap: () => _setFilter(c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: selected
                    ? _primary.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected
                      ? _primary
                      : Colors.white.withValues(alpha: 0.12),
                ),
              ),
              child: Text(
                c,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('📭',
              style: TextStyle(
                fontSize: 80,
                shadows: [
                  Shadow(color: _primary.withValues(alpha: 0.4), blurRadius: 16)
                ],
              )),
          const SizedBox(height: 12),
          Text(
            _filter == '★ Favoriten'
                ? 'Noch keine Favoriten'
                : 'Keine Fakten in dieser Kategorie',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            _filter == '★ Favoriten'
                ? 'Tippe das ★ Icon auf einer Karte um sie zu speichern'
                : '',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCardStack(List<Map<String, String>> visible) {
    return PageView.builder(
      controller: _pageCtrl,
      itemCount: visible.length,
      onPageChanged: (i) {
        setState(() => _currentIndex = i);
        HapticFeedback.selectionClick();
        _markSeen(i);
      },
      itemBuilder: (_, i) {
        final fact = visible[i];
        final id = _idFor(fact);
        final isFav = _favorites.contains(id);
        final isSeen = _seen.contains(id);
        return AnimatedScale(
          scale: i == _currentIndex ? 1.0 : 0.93,
          duration: const Duration(milliseconds: 250),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _primary.withValues(alpha: 0.18),
                        _primary.withValues(alpha: 0.04),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _primary.withValues(alpha: 0.35)),
                    boxShadow: [
                      BoxShadow(
                        color: _primary.withValues(alpha: 0.15),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _primary.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                fact['category'] ?? '?',
                                style: const TextStyle(
                                  color: _gold,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (isSeen)
                              Icon(Icons.check_circle,
                                  size: 16,
                                  color: _gold.withValues(alpha: 0.7)),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => _toggleFavorite(fact),
                              child: AnimatedScale(
                                scale: isFav ? 1.15 : 1.0,
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  isFav ? Icons.star : Icons.star_border,
                                  color: isFav ? _gold : Colors.white70,
                                  size: 24,
                                  shadows: isFav
                                      ? [
                                          Shadow(
                                              color:
                                                  _gold.withValues(alpha: 0.6),
                                              blurRadius: 8)
                                        ]
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          fact['title'] ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            height: 1.25,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: SingleChildScrollView(
                            child: SelectableText(
                              fact['fact'] ?? '',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 14.5,
                                height: 1.55,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar(List<Map<String, String>> visible) {
    return Column(children: [
      // Page-Indikator als Dots (max 30 dots, sonst Text)
      if (visible.length <= 30)
        Wrap(
          spacing: 4,
          alignment: WrapAlignment.center,
          children: List.generate(visible.length, (i) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: i == _currentIndex ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == _currentIndex
                    ? _gold
                    : Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        )
      else
        Text(
          '${_currentIndex + 1} / ${visible.length}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 11,
            letterSpacing: 2,
          ),
        ),
    ]);
  }
}

class _HfOrbsPainter extends CustomPainter {
  final double t;
  _HfOrbsPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    _draw(
        canvas,
        Offset(size.width * 0.2,
            size.height * (0.3 + math.sin(t * 2 * math.pi) * 0.04)),
        110,
        const Color(0xFFFFA726));
    _draw(
        canvas,
        Offset(size.width * 0.85,
            size.height * (0.6 + math.cos(t * 2 * math.pi) * 0.04)),
        100,
        const Color(0xFFFFD700));
  }

  void _draw(Canvas canvas, Offset c, double r, Color color) {
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = color.withValues(alpha: 0.12)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.5),
    );
  }

  @override
  bool shouldRepaint(_HfOrbsPainter old) => old.t != t;
}
