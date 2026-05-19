import 'dart:math' as math;
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════
// PLANET CALCULATOR — vereinfachte astronomische Berechnungen (lokal, kein API)
// ═══════════════════════════════════════════════════════════════════════════

class PlanetCalculator {
  static const double _epoch = 2451545.0; // J2000.0 = 1. Jan 2000 12:00 UT

  static double _julianDay(DateTime dt) {
    final a = (14 - dt.month) ~/ 12;
    final y = dt.year + 4800 - a;
    final m = dt.month + 12 * a - 3;
    return dt.day +
        (153 * m + 2) ~/ 5 +
        365 * y +
        y ~/ 4 -
        y ~/ 100 +
        y ~/ 400 -
        32045 +
        (dt.hour - 12) / 24.0 +
        dt.minute / 1440.0;
  }

  // Mittlere tägliche Bewegung (Grad/Tag) + J2000 Epochen-Position (Grad)
  static const Map<String, Map<String, double>> _planets = {
    'Sonne': {'speed': 0.9856, 'epoch': 280.46},
    'Mond': {'speed': 13.1764, 'epoch': 218.32},
    'Merkur': {'speed': 4.0923, 'epoch': 252.25},
    'Venus': {'speed': 1.6021, 'epoch': 181.98},
    'Mars': {'speed': 0.5240, 'epoch': 355.43},
    'Jupiter': {'speed': 0.0831, 'epoch': 34.35},
    'Saturn': {'speed': 0.0335, 'epoch': 50.08},
    'Uranus': {'speed': 0.0117, 'epoch': 314.05},
    'Neptun': {'speed': 0.0060, 'epoch': 304.35},
    'Pluto': {'speed': 0.0040, 'epoch': 238.96},
  };

  static double getPlanetDegree(String planet, DateTime date) {
    final jd = _julianDay(date);
    final t = jd - _epoch;
    final data = _planets[planet]!;
    return (data['epoch']! + data['speed']! * t) % 360;
  }

  static String getZodiacSign(double degree) {
    const signs = [
      'Widder ♈',
      'Stier ♉',
      'Zwillinge ♊',
      'Krebs ♋',
      'Löwe ♌',
      'Jungfrau ♍',
      'Waage ♎',
      'Skorpion ♏',
      'Schütze ♐',
      'Steinbock ♑',
      'Wassermann ♒',
      'Fische ♓'
    ];
    return signs[(degree ~/ 30).clamp(0, 11)];
  }

  /// Grad innerhalb des Tierkreiszeichens (0–29°)
  static String getDegreeInSign(double degree) {
    final d = degree % 30;
    final deg = d.floor();
    final minutes = ((d - deg) * 60).floor();
    return "$deg°$minutes'";
  }

  /// Retrograd-Erkennung (vereinfacht: rückläufige Bewegung über 3 Tage)
  static bool isRetrograde(String planet, DateTime date) {
    final today = getPlanetDegree(planet, date);
    final before =
        getPlanetDegree(planet, date.subtract(const Duration(days: 3)));
    var diff = today - before;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;
    return diff < 0;
  }

  /// Mondphase 0=Neumond … 1=Vollmond (zyklisch)
  static double getMoonPhase(DateTime date) {
    final jd = _julianDay(date);
    // Synodischer Zyklus: 29.53059 Tage
    final phase = ((jd - 2451550.1) / 29.53059) % 1.0;
    return phase < 0 ? phase + 1.0 : phase;
  }

  static String getMoonPhaseName(double phase) {
    if (phase < 0.03 || phase > 0.97) return 'Neumond 🌑';
    if (phase < 0.22) return 'Zunehmend ☽';
    if (phase < 0.28) return 'Erstes Viertel 🌓';
    if (phase < 0.47) return 'Zunehmend ☽';
    if (phase < 0.53) return 'Vollmond 🌕';
    if (phase < 0.72) return 'Abnehmend ☾';
    if (phase < 0.78) return 'Letztes Viertel 🌗';
    return 'Abnehmend ☾';
  }

  /// Planetare Aspekte: Winkel zwischen zwei Planeten (nur intern verwendet)
  static List<_Aspect> _getAspects(DateTime date) {
    final planetNames = _planets.keys.toList();
    final aspects = <_Aspect>[];
    const aspectDefs = [
      _AspectDef('Konjunktion', 0, 8, '☌', Color(0xFFFFD700)),
      _AspectDef('Sextil', 60, 6, '⚹', Color(0xFF66BB6A)),
      _AspectDef('Quadrat', 90, 8, '□', Color(0xFFEF5350)),
      _AspectDef('Trigon', 120, 8, '△', Color(0xFF42A5F5)),
      _AspectDef('Opposition', 180, 8, '☍', Color(0xFFEC407A)),
    ];

    for (int i = 0; i < planetNames.length; i++) {
      for (int j = i + 1; j < planetNames.length; j++) {
        final degA = getPlanetDegree(planetNames[i], date);
        final degB = getPlanetDegree(planetNames[j], date);
        var diff = (degA - degB).abs();
        if (diff > 180) diff = 360 - diff;

        for (final def in aspectDefs) {
          if ((diff - def.angle).abs() <= def.orb) {
            aspects.add(_Aspect(
              planet1: planetNames[i],
              planet2: planetNames[j],
              type: def.name,
              symbol: def.symbol,
              color: def.color,
              exactness: 1 - ((diff - def.angle).abs() / def.orb),
            ));
            break;
          }
        }
      }
    }
    aspects.sort((a, b) => b.exactness.compareTo(a.exactness));
    return aspects.take(6).toList();
  }
}

class _AspectDef {
  final String name;
  final double angle;
  final double orb;
  final String symbol;
  final Color color;
  const _AspectDef(this.name, this.angle, this.orb, this.symbol, this.color);
}

class _Aspect {
  final String planet1;
  final String planet2;
  final String type;
  final String symbol;
  final Color color;
  final double exactness;
  const _Aspect({
    required this.planet1,
    required this.planet2,
    required this.type,
    required this.symbol,
    required this.color,
    required this.exactness,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// PLANETARY TRANSIT SCREEN
// ═══════════════════════════════════════════════════════════════════════════

class PlanetaryTransitScreen extends StatefulWidget {
  const PlanetaryTransitScreen({super.key});

  @override
  State<PlanetaryTransitScreen> createState() => _PlanetaryTransitScreenState();
}

class _PlanetaryTransitScreenState extends State<PlanetaryTransitScreen>
    with TickerProviderStateMixin {
  // ── Animationen ──────────────────────────────────────────────────────────
  late final AnimationController _orbitCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _entryCtrl;
  late final Animation<double> _entryAnim;

  // ── State ────────────────────────────────────────────────────────────────
  int _tabIndex = 0; // 0=Planeten, 1=Transite, 2=Energie-Prognose
  final DateTime _today = DateTime.now();

  // ── Farben ───────────────────────────────────────────────────────────────
  static const _bg = Color(0xFF06040F);
  static const _card = Color(0xFF0E0A1C);
  static const _purple = Color(0xFFAB47BC);
  static const _teal = Color(0xFF26C6DA);
  static const _gold = Color(0xFFFFD54F);
  static const _retroRed = Color(0xFFEF5350);

  static const Map<String, String> _planetEmojis = {
    'Sonne': '☀️',
    'Mond': '🌙',
    'Merkur': '☿',
    'Venus': '♀',
    'Mars': '♂',
    'Jupiter': '♃',
    'Saturn': '♄',
    'Uranus': '♅',
    'Neptun': '♆',
    'Pluto': '♇',
  };

  static const Map<String, Color> _planetColors = {
    'Sonne': Color(0xFFFFD54F),
    'Mond': Color(0xFFE0E0E0),
    'Merkur': Color(0xFFB0BEC5),
    'Venus': Color(0xFFEC407A),
    'Mars': Color(0xFFEF5350),
    'Jupiter': Color(0xFFFF9800),
    'Saturn': Color(0xFFBCAAA4),
    'Uranus': Color(0xFF80DEEA),
    'Neptun': Color(0xFF42A5F5),
    'Pluto': Color(0xFFAB47BC),
  };

  static const Map<String, String> _planetMeanings = {
    'Sonne': 'Identität & Lebenskraft — dein essentielles Selbst',
    'Mond': 'Emotionen & Intuition — dein inneres Gefühlsleben',
    'Merkur': 'Kommunikation & Denken — Botschaften und Ideen',
    'Venus': 'Liebe & Schönheit — Beziehungen und Ästhetik',
    'Mars': 'Energie & Wille — Antrieb und Mut',
    'Jupiter': 'Expansion & Glück — Wachstum und Weisheit',
    'Saturn': 'Struktur & Karma — Lektionen und Verantwortung',
    'Uranus': 'Revolution & Intuition — Durchbrüche und Erwachen',
    'Neptun': 'Spiritualität & Illusion — Träume und Mitgefühl',
    'Pluto': 'Transformation & Macht — Tod und Wiedergeburt',
  };

  @override
  void initState() {
    super.initState();
    _orbitCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 20))
          ..repeat();
    _pulseCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat(reverse: true);
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _entryAnim =
        CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic);
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _orbitCtrl.dispose();
    _pulseCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // Ambient Hintergrund
          _buildAmbientBg(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildTabBar(),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmbientBg() {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) => Stack(children: [
        Container(color: _bg),
        Positioned(
          top: -60,
          right: -40,
          child: _buildOrb(_purple, 220, 0.10 + _pulseCtrl.value * 0.04),
        ),
        Positioned(
          bottom: -80,
          left: -60,
          child: _buildOrb(_teal, 200, 0.08 + _pulseCtrl.value * 0.03),
        ),
        Positioned(
          top: 180,
          left: 60,
          child: _buildOrb(_gold, 120, 0.05 + _pulseCtrl.value * 0.03),
        ),
      ]),
    );
  }

  Widget _buildOrb(Color color, double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [
          color.withValues(alpha: opacity),
          color.withValues(alpha: 0),
        ]),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return SizedBox(
      height: 200,
      child: Stack(children: [
        // Orbital-Animation
        AnimatedBuilder(
          animation: _orbitCtrl,
          builder: (_, __) => CustomPaint(
            painter: _OrbitalPainter(
              progress: _orbitCtrl.value,
              pulseProgress: _pulseCtrl.value,
            ),
            child: const SizedBox.expand(),
          ),
        ),
        // Gradient-Fade unten
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, _bg],
              stops: const [0.5, 1.0],
            ),
          ),
        ),
        // Text-Inhalt
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: FadeTransition(
            opacity: _entryAnim,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white70, size: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('🪐 Planeten & Transite',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 12),
                _buildDateBadge(),
                const SizedBox(height: 8),
                const Text(
                  'Kosmische Einflüsse — heute',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildDateBadge() {
    final months = [
      'Januar',
      'Februar',
      'März',
      'April',
      'Mai',
      'Juni',
      'Juli',
      'August',
      'September',
      'Oktober',
      'November',
      'Dezember',
    ];
    final days = [
      'Montag',
      'Dienstag',
      'Mittwoch',
      'Donnerstag',
      'Freitag',
      'Samstag',
      'Sonntag'
    ];
    final weekday = days[_today.weekday - 1];
    final label =
        '$weekday, ${_today.day}. ${months[_today.month - 1]} ${_today.year}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: _purple.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _purple.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500)),
    );
  }

  // ── Tab Bar ───────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    const tabs = ['🪐 Planeten', '⚡ Transite', '✨ Energie', '🌒 Finsternisse'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: List.generate(4, (i) {
          final selected = _tabIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tabIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: selected
                      ? LinearGradient(colors: [
                          _purple.withValues(alpha: 0.7),
                          _teal.withValues(alpha: 0.4),
                        ])
                      : null,
                  color: selected ? null : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected
                        ? _purple
                        : Colors.white.withValues(alpha: 0.12),
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Center(
                  child: Text(tabs[i],
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.white54,
                        fontSize: 12,
                        fontWeight:
                            selected ? FontWeight.bold : FontWeight.normal,
                      )),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────
  Widget _buildBody() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: switch (_tabIndex) {
        0 => _buildPlanetList(),
        1 => _buildTransitEvents(),
        2 => _buildEnergyForecast(),
        _ => _buildEclipses(),
      },
    );
  }

  // ── TAB 3: Finsternisse-Kalender ─────────────────────────────────────────
  // Daten aus NASA GSFC Eclipse Catalog (Solar: eclipse.gsfc.nasa.gov/solar.html
  // Lunar: eclipse.gsfc.nasa.gov/lunar.html). UTC-Maxima, manuell kuratiert.
  // Hinweis: kein `const` möglich — DateTime.utc() hat keinen const-Konstruktor.
  static final List<
      ({
        DateTime date,
        String type,
        String name,
        String region,
        String meaning
      })> _eclipses = [
    // 2026
    (
      date: _d(2026, 2, 17),
      type: 'Sonne (ringförmig)',
      name: 'Antarktis-Sonnenfinsternis',
      region: 'Antarktis, Südspitze Afrikas',
      meaning: 'Wassermann-Energie · Loslassen kollektiver Strukturen'
    ),
    (
      date: _d(2026, 3, 3),
      type: 'Mond (Total)',
      name: 'Totale Mondfinsternis',
      region: 'Pazifik, Amerika, Asien',
      meaning: 'Jungfrau · klare Erkenntnis durch Schatten'
    ),
    (
      date: _d(2026, 8, 12),
      type: 'Sonne (Total)',
      name: 'Spanien-Total-Sonnenfinsternis',
      region: 'Grönland, Island, Spanien',
      meaning: 'Löwe · neue Identität sichtbar machen'
    ),
    (
      date: _d(2026, 8, 28),
      type: 'Mond (partiell)',
      name: 'Partielle Mondfinsternis',
      region: 'Amerika, Europa, Afrika',
      meaning: 'Fische · Auflösen alter Träume'
    ),
    // 2027
    (
      date: _d(2027, 2, 6),
      type: 'Sonne (ringförmig)',
      name: 'Süd-Atlantik-Ringförmige',
      region: 'Chile, Argentinien, Atlantik',
      meaning: 'Wassermann · Innovation jenseits Konvention'
    ),
    (
      date: _d(2027, 8, 2),
      type: 'Sonne (Total)',
      name: 'Sahara-Total-Sonnenfinsternis',
      region: 'Marokko, Spanien, Ägypten, Saudi',
      meaning: 'Löwe · seltene 6:23 Min Totalität'
    ),
    // 2028
    (
      date: _d(2028, 1, 12),
      type: 'Mond (partiell)',
      name: 'Partielle Mondfinsternis',
      region: 'Europa, Afrika, Asien',
      meaning: 'Krebs · familiäre Wurzeln klären'
    ),
    (
      date: _d(2028, 1, 26),
      type: 'Sonne (ringförmig)',
      name: 'Ringförmige über Spanien',
      region: 'Ecuador, Brasilien, Spanien',
      meaning: 'Wassermann · kollektives Erwachen'
    ),
    (
      date: _d(2028, 7, 22),
      type: 'Sonne (Total)',
      name: 'Australien-Total',
      region: 'Australien, Neuseeland',
      meaning: 'Krebs · emotionale Heimkehr'
    ),
    // 2029
    (
      date: _d(2029, 1, 14),
      type: 'Sonne (partiell)',
      name: 'Partielle Sonnenfinsternis',
      region: 'Arktis, Nord-Europa',
      meaning: 'Steinbock · Strukturbruch'
    ),
    (
      date: _d(2029, 6, 12),
      type: 'Sonne (partiell)',
      name: 'Partielle Sonnenfinsternis',
      region: 'Arktis',
      meaning: 'Zwillinge · Wahrheit aus mehreren Perspektiven'
    ),
    (
      date: _d(2029, 6, 26),
      type: 'Mond (Total)',
      name: 'Totale Mondfinsternis',
      region: 'Amerika, Europa, Afrika',
      meaning: 'Steinbock · Karriere/Lebensaufgabe-Wendepunkt'
    ),
    (
      date: _d(2029, 12, 20),
      type: 'Mond (Total)',
      name: 'Totale Mondfinsternis',
      region: 'Pazifik, Asien',
      meaning: 'Zwillinge · Kommunikations-Klärung'
    ),
    // 2030
    (
      date: _d(2030, 6, 1),
      type: 'Sonne (ringförmig)',
      name: 'Sahara-Ringförmige',
      region: 'Algerien, Tunesien, Griechenland, Russland',
      meaning: 'Zwillinge · neue Lernfelder'
    ),
    (
      date: _d(2030, 11, 25),
      type: 'Sonne (Total)',
      name: 'Süd-Afrika-Total',
      region: 'Botswana, Südafrika, Australien',
      meaning: 'Schütze · Sinnsuche und Expansion'
    ),
  ];

  static DateTime _d(int y, int m, int d) => DateTime.utc(y, m, d);

  Widget _buildEclipses() {
    final upcoming = _eclipses
        .where((e) => e.date.isAfter(_today.subtract(const Duration(days: 1))))
        .toList();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      physics: const BouncingScrollPhysics(),
      itemCount: upcoming.length + 1,
      itemBuilder: (_, i) {
        if (i == 0) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                _purple.withValues(alpha: 0.25),
                _teal.withValues(alpha: 0.1),
              ]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _purple.withValues(alpha: 0.4)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🌒 Finsternisse 2026-2030',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 6),
                Text(
                  'Sonnen- und Mondfinsternisse markieren astrologische Wendepunkte. '
                  'Daten aus NASA GSFC Eclipse Catalog. Wirkung ±6 Monate.',
                  style: TextStyle(
                      color: Colors.white70, fontSize: 12, height: 1.5),
                ),
              ],
            ),
          );
        }
        final e = upcoming[i - 1];
        final isSolar = e.type.startsWith('Sonne');
        final daysUntil = e.date.difference(_today).inDays;
        final color = isSolar ? _gold : _purple;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(isSolar ? '☀️' : '🌑',
                      style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold)),
                        Text(e.type,
                            style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${e.date.day}.${e.date.month}.${e.date.year}',
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                      Text(daysUntil == 0 ? 'heute' : 'in $daysUntil Tagen',
                          style: TextStyle(color: color, fontSize: 10)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('📍 ${e.region}',
                  style: const TextStyle(color: Colors.white60, fontSize: 11)),
              const SizedBox(height: 4),
              Text(e.meaning,
                  style: TextStyle(
                      color: color.withValues(alpha: 0.9),
                      fontSize: 12,
                      fontStyle: FontStyle.italic)),
            ],
          ),
        );
      },
    );
  }

  // ── TAB 0: Planetenliste ──────────────────────────────────────────────────
  Widget _buildPlanetList() {
    final planetNames = PlanetCalculator._planets.keys.toList();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      physics: const BouncingScrollPhysics(),
      itemCount: planetNames.length,
      itemBuilder: (_, i) {
        final name = planetNames[i];
        final degree = PlanetCalculator.getPlanetDegree(name, _today);
        final sign = PlanetCalculator.getZodiacSign(degree);
        final degStr = PlanetCalculator.getDegreeInSign(degree);
        final retro = PlanetCalculator.isRetrograde(name, _today);
        final color = _planetColors[name]!;
        final emoji = _planetEmojis[name]!;
        final meaning = _planetMeanings[name]!;

        return FadeTransition(
          opacity: _entryAnim,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: retro
                    ? _retroRed.withValues(alpha: 0.5)
                    : color.withValues(alpha: 0.25),
                width: retro ? 1.5 : 1,
              ),
              boxShadow: retro
                  ? [
                      BoxShadow(
                          color: _retroRed.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4))
                    ]
                  : [
                      BoxShadow(
                          color: color.withValues(alpha: 0.10),
                          blurRadius: 10,
                          offset: const Offset(0, 4))
                    ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                // Planet-Orb
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      color.withValues(alpha: 0.4),
                      color.withValues(alpha: 0.08),
                    ]),
                    border: Border.all(color: color.withValues(alpha: 0.5)),
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          if (retro) _buildRetroGrade(),
                        ]),
                        const SizedBox(height: 3),
                        Text('im $sign  ·  $degStr',
                            style: TextStyle(
                                color: color.withValues(alpha: 0.9),
                                fontSize: 12,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text(meaning,
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 11),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ]),
                ),
              ]),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRetroGrade() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _retroRed.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _retroRed.withValues(alpha: 0.5)),
      ),
      child: const Text('℞ Rückläufig',
          style: TextStyle(
              color: Color(0xFFEF9A9A),
              fontSize: 10,
              fontWeight: FontWeight.bold)),
    );
  }

  // ── TAB 1: Transit-Events ─────────────────────────────────────────────────
  Widget _buildTransitEvents() {
    final moonPhase = PlanetCalculator.getMoonPhase(_today);
    final moonPhaseName = PlanetCalculator.getMoonPhaseName(moonPhase);
    final aspects = PlanetCalculator._getAspects(_today);

    // Retrograde Planeten
    final retrogrades = PlanetCalculator._planets.keys
        .where((p) => PlanetCalculator.isRetrograde(p, _today))
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      physics: const BouncingScrollPhysics(),
      children: [
        // Mondphase
        _buildSectionHeader('🌙 Mondphase heute'),
        _buildMoonPhaseCard(moonPhase, moonPhaseName),
        const SizedBox(height: 16),

        // Planetare Aspekte
        _buildSectionHeader('⚡ Aktuelle Aspekte'),
        if (aspects.isEmpty)
          _buildEmptyCard('Keine markanten Aspekte heute')
        else
          ...aspects.map((a) => _buildAspectCard(a)),
        const SizedBox(height: 16),

        // Retrograde Planeten
        _buildSectionHeader('℞ Rückläufige Planeten'),
        if (retrogrades.isEmpty)
          _buildEmptyCard('Kein Planet ist derzeit rückläufig')
        else
          ...retrogrades.map((p) => _buildRetroCard(p)),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title,
          style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5)),
    );
  }

  Widget _buildMoonPhaseCard(double phase, String phaseName) {
    final illumination = (phase < 0.5 ? phase * 2 : (1 - phase) * 2) * 100;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1A2E),
            const Color(0xFF16213E).withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border:
            Border.all(color: const Color(0xFFE0E0E0).withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, __) => Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                const Color(0xFFE0E0E0)
                    .withValues(alpha: 0.4 + _pulseCtrl.value * 0.15),
                const Color(0xFFE0E0E0).withValues(alpha: 0.05),
              ]),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE0E0E0)
                      .withValues(alpha: 0.2 + _pulseCtrl.value * 0.1),
                  blurRadius: 16,
                )
              ],
            ),
            child: Center(
              child: Text(
                phase < 0.03 || phase > 0.97
                    ? '🌑'
                    : phase < 0.5
                        ? '🌙'
                        : '🌕',
                style: const TextStyle(fontSize: 30),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(phaseName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Beleuchtung: ${illumination.toStringAsFixed(0)}%',
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: illumination / 100,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFFE0E0E0)),
                minHeight: 6,
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildAspectCard(_Aspect aspect) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: aspect.color.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: aspect.color.withValues(alpha: 0.18),
            border: Border.all(color: aspect.color.withValues(alpha: 0.5)),
          ),
          child: Center(
            child: Text(aspect.symbol,
                style: TextStyle(
                    color: aspect.color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${aspect.planet1} ${aspect.symbol} ${aspect.planet2}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
            Text(aspect.type,
                style: TextStyle(
                    color: aspect.color.withValues(alpha: 0.8), fontSize: 11)),
          ]),
        ),
        // Exaktheits-Indikator
        Column(children: [
          Text('${(aspect.exactness * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                  color: aspect.color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
          const Text('exakt',
              style: TextStyle(color: Colors.white38, fontSize: 9)),
        ]),
      ]),
    );
  }

  Widget _buildRetroCard(String planet) {
    final planetColor = _planetColors[planet]!;
    final emoji = _planetEmojis[planet]!;
    final degree = PlanetCalculator.getPlanetDegree(planet, _today);
    final sign = PlanetCalculator.getZodiacSign(degree);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _retroRed.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(color: _retroRed.withValues(alpha: 0.10), blurRadius: 8),
          BoxShadow(color: planetColor.withValues(alpha: 0.06), blurRadius: 4),
        ],
      ),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$planet rückläufig',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
            Text('im $sign — Rückblick & Revision',
                style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _retroRed.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _retroRed.withValues(alpha: 0.5)),
          ),
          child: const Text('℞',
              style: TextStyle(
                  color: Color(0xFFEF9A9A),
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(children: [
        Icon(Icons.check_circle_outline, color: Colors.white30, size: 20),
        const SizedBox(width: 10),
        Text(message,
            style: const TextStyle(color: Colors.white38, fontSize: 12)),
      ]),
    );
  }

  // ── TAB 2: Energie-Prognose ───────────────────────────────────────────────
  Widget _buildEnergyForecast() {
    final moonPhase = PlanetCalculator.getMoonPhase(_today);
    final moonSign = PlanetCalculator.getZodiacSign(
        PlanetCalculator.getPlanetDegree('Mond', _today));
    final sunSign = PlanetCalculator.getZodiacSign(
        PlanetCalculator.getPlanetDegree('Sonne', _today));

    final forecast = _generateForecast(moonPhase, moonSign, sunSign);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildForecastHero(forecast),
        const SizedBox(height: 16),
        _buildSectionHeader('🌟 Tages-Energien'),
        ..._buildEnergyCards(moonPhase, moonSign),
        const SizedBox(height: 16),
        _buildSectionHeader('💫 Empfehlungen für heute'),
        _buildRecommendations(moonPhase),
      ],
    );
  }

  Map<String, String> _generateForecast(
      double phase, String moonSign, String sunSign) {
    // Matrix: Mondphase × Mondzeichen → Botschaft
    final phaseKey = phase < 0.25
        ? 'new'
        : phase < 0.5
            ? 'waxing'
            : phase < 0.75
                ? 'full'
                : 'waning';
    final Map<String, Map<String, String>> matrix = {
      'new': {
        'default':
            'Neuanfänge liegen in der Luft. Pflanze heute die Samen deiner Wünsche.',
        'Widder ♈':
            'Mutige Impulse erwachen. Beginne etwas Neues mit Entschlossenheit.',
        'Stier ♉': 'Manifestiere materiellen Wohlstand. Setze konkrete Ziele.',
        'Zwillinge ♊':
            'Neue Gedanken strömen ein. Schreibe deine Visionen auf.',
        'Krebs ♋':
            'Emotionale Reinigung — lass Altes los und öffne dich für Neues.',
      },
      'waxing': {
        'default':
            'Deine Energie wächst. Nimm aktiv Schritte in Richtung deiner Träume.',
        'Löwe ♌': 'Strahlende Schöpferkraft. Zeige dich der Welt.',
        'Jungfrau ♍': 'Verfeinere deine Pläne mit Präzision und Hingabe.',
        'Waage ♎': 'Suche Harmonie und Balance in allen Beziehungen.',
        'Skorpion ♏':
            'Tiefe Transformation ist möglich. Tauche in dein Inneres.',
      },
      'full': {
        'default':
            'Vollmond — Höchste Energie. Ernte die Früchte deiner Arbeit.',
        'Schütze ♐': 'Expansion und Abenteuer. Folge deiner höheren Wahrheit.',
        'Steinbock ♑':
            'Struktur und Verantwortung — deine Ausdauer zahlt sich aus.',
        'Wassermann ♒': 'Revolutionäre Einsichten. Denke außerhalb der Box.',
        'Fische ♓':
            'Mystische Verbindung zum Universum. Meditation ist jetzt besonders kraftvoll.',
      },
      'waning': {
        'default': 'Loslassen und Reinigen. Räume auf was nicht mehr dient.',
        'Widder ♈': 'Beende begonnene Projekte mit Mut und Entschlossenheit.',
        'Stier ♉': 'Dankbarkeit für das Manifestierte. Schätze was du hast.',
        'Zwillinge ♊': 'Reflexion über deine Kommunikationsmuster.',
        'Krebs ♋': 'Emotionale Verarbeitung und Heilung der Vergangenheit.',
      },
    };

    final phaseMap = matrix[phaseKey]!;
    final message = phaseMap[moonSign] ?? phaseMap['default']!;

    return {
      'message': message,
      'moon_sign': moonSign,
      'sun_sign': sunSign,
      'phase': PlanetCalculator.getMoonPhaseName(phase),
    };
  }

  Widget _buildForecastHero(Map<String, String> forecast) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _purple.withValues(alpha: 0.4 + _pulseCtrl.value * 0.1),
              _teal.withValues(alpha: 0.2),
              _gold.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
              color: _purple.withValues(alpha: 0.35 + _pulseCtrl.value * 0.1)),
          boxShadow: [
            BoxShadow(
              color: _purple.withValues(alpha: 0.2 + _pulseCtrl.value * 0.1),
              blurRadius: 20,
            )
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('✨', style: TextStyle(fontSize: 28 + _pulseCtrl.value * 4)),
            const SizedBox(width: 10),
            const Text('Energie-Prognose heute',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 12),
          Text(forecast['message']!,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.5,
                  fontStyle: FontStyle.italic)),
          const SizedBox(height: 14),
          Row(children: [
            _buildForecastBadge('☀️ ${forecast['sun_sign']}', _gold),
            const SizedBox(width: 8),
            _buildForecastBadge(
                '🌙 ${forecast['moon_sign']}', const Color(0xFFE0E0E0)),
            const SizedBox(width: 8),
            _buildForecastBadge(forecast['phase']!, _purple),
          ]),
        ]),
      ),
    );
  }

  Widget _buildForecastBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  List<Widget> _buildEnergyCards(double phase, String moonSign) {
    final energies = [
      {'icon': '🧘', 'title': 'Meditation', 'desc': _getMeditationTip(phase)},
      {'icon': '💫', 'title': 'Manifestation', 'desc': _getManifestTip(phase)},
      {'icon': '🌿', 'title': 'Heilpflanzen', 'desc': _getHerbTip(moonSign)},
      {'icon': '🎨', 'title': 'Kreativität', 'desc': _getCreativityTip(phase)},
    ];
    return energies
        .map((e) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _purple.withValues(alpha: 0.18)),
              ),
              child: Row(children: [
                Text(e['icon']!, style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e['title']!,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 3),
                        Text(e['desc']!,
                            style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                                height: 1.4)),
                      ]),
                ),
              ]),
            ))
        .toList();
  }

  String _getMeditationTip(double phase) {
    if (phase < 0.25) return 'Stille Meditation zum Setzen von Absichten';
    if (phase < 0.5)
      return 'Dynamische Meditation — Energie in Bewegung bringen';
    if (phase < 0.75) return 'Dankbarkeitsmeditation im Vollmond-Licht';
    return 'Loslassmeditation — was darf gehen?';
  }

  String _getManifestTip(double phase) {
    if (phase < 0.25)
      return 'Schreibe deine Wünsche auf — Neumond lädt zum Säen ein';
    if (phase < 0.5) return 'Handle aktiv — die Energie unterstützt Wachstum';
    if (phase < 0.75) return 'Vollende Projekte und ernte deine Arbeit';
    return 'Räume auf und mache Platz für Neues';
  }

  String _getHerbTip(String moonSign) {
    if (moonSign.contains('Stier') || moonSign.contains('Jungfrau')) {
      return 'Erd-Kräuter: Weihrauch, Myrthe, Rosmarin';
    }
    if (moonSign.contains('Krebs') || moonSign.contains('Fische')) {
      return 'Wasser-Kräuter: Kamille, Lavendel, Jasmin';
    }
    if (moonSign.contains('Widder') || moonSign.contains('Löwe')) {
      return 'Feuer-Kräuter: Ingwer, Kardamom, Zimt';
    }
    return 'Luft-Kräuter: Pfefferminze, Salbei, Anis';
  }

  String _getCreativityTip(double phase) {
    if (phase < 0.25) return 'Vision-Boards erstellen und Träume visualisieren';
    if (phase < 0.5) return 'Aktive Schöpfung — mach deine Ideen real';
    if (phase < 0.75) return 'Feiere deine Kreationen — teile sie mit der Welt';
    return 'Reflektiere vergangene Werke — was hat dich bewegt?';
  }

  Widget _buildRecommendations(double phase) {
    final recs = phase < 0.5
        ? [
            '🌱 Neue Projekte starten',
            '📝 Absichten schriftlich festhalten',
            '🏃 Aktiv werden und Energie entfalten',
            '🌞 Kontakte knüpfen und vernetzen',
          ]
        : [
            '🧹 Aufräumen und loslassen',
            '🙏 Dankbarkeit praktizieren',
            '😴 Mehr Ruhe und Rückzug',
            '📖 Reflexion und innere Einkehr',
          ];
    return Column(
      children: recs
          .map((r) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _teal.withValues(alpha: 0.2)),
                ),
                child: Row(children: [
                  Text(r,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 13)),
                ]),
              ))
          .toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ORBITAL PAINTER — animierter Planeten-Header
// ═══════════════════════════════════════════════════════════════════════════
class _OrbitalPainter extends CustomPainter {
  final double progress;
  final double pulseProgress;

  _OrbitalPainter({required this.progress, required this.pulseProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final cy = size.height * 0.5;

    final orbits = [
      _OrbitConfig(
          radius: 55, speed: 1.0, color: const Color(0xFFFFD54F), size: 6),
      _OrbitConfig(
          radius: 80, speed: 0.6, color: const Color(0xFFAB47BC), size: 5),
      _OrbitConfig(
          radius: 108, speed: 0.35, color: const Color(0xFF26C6DA), size: 4.5),
      _OrbitConfig(
          radius: 140, speed: 0.2, color: const Color(0xFFEC407A), size: 4),
    ];

    // Orbitlinien
    for (final o in orbits) {
      canvas.drawCircle(
        Offset(cx, cy),
        o.radius,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.06)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
    }

    // Zentrum-Sonne
    final sunPulse = 14.0 + pulseProgress * 4;
    canvas.drawCircle(
      Offset(cx, cy),
      sunPulse + 6,
      Paint()
        ..color = const Color(0xFFFFD54F)
            .withValues(alpha: 0.12 + pulseProgress * 0.06),
    );
    canvas.drawCircle(
      Offset(cx, cy),
      sunPulse,
      Paint()..color = const Color(0xFFFFD54F).withValues(alpha: 0.35),
    );
    canvas.drawCircle(
      Offset(cx, cy),
      sunPulse - 5,
      Paint()..color = const Color(0xFFFFE082),
    );

    // Planeten auf Orbits
    for (final o in orbits) {
      final angle = progress * math.pi * 2 * o.speed;
      final px = cx + math.cos(angle) * o.radius;
      final py = cy + math.sin(angle) * o.radius * 0.6;

      // Glow
      canvas.drawCircle(
        Offset(px, py),
        o.size + 4,
        Paint()..color = o.color.withValues(alpha: 0.2),
      );
      // Planet
      canvas.drawCircle(
        Offset(px, py),
        o.size,
        Paint()..color = o.color,
      );
    }
  }

  @override
  bool shouldRepaint(_OrbitalPainter old) => true;
}

class _OrbitConfig {
  final double radius;
  final double speed;
  final Color color;
  final double size;
  const _OrbitConfig({
    required this.radius,
    required this.speed,
    required this.color,
    required this.size,
  });
}
