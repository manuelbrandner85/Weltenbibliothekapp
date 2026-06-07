// MYSTISCHE ORTE - kuratierte Liste von 24 echten mystischen Plaetzen
// weltweit (heilige Staetten, antike Wunder, Naturphaenomene,
// ungeloeste Raetsel). Inspiriert statt veraengstigt.

import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/wb_cinematic_tokens.dart';
import '../../widgets/cinematic/wb_ambient_particles.dart';
import '../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../widgets/cinematic/wb_vignette.dart';

// ============================================================
// Data model
// ============================================================

enum _Category { heilig, antik, natur, raetselhaft }

class _MysticPlace {
  final String emoji;
  final String name;
  final String region;
  final String description;
  final double lat;
  final double lng;
  final _Category category;

  const _MysticPlace({
    required this.emoji,
    required this.name,
    required this.region,
    required this.description,
    required this.lat,
    required this.lng,
    required this.category,
  });
}

// Category accent colors
const Color _kHeiligColor = Color(0xFFFFD700);
const Color _kAntikColor = Color(0xFFD7A86E);
const Color _kNaturColor = Color(0xFF00BCD4);
const Color _kRaetselColor = Color(0xFF7C4DFF);

Color _colorFor(_Category c) {
  switch (c) {
    case _Category.heilig:
      return _kHeiligColor;
    case _Category.antik:
      return _kAntikColor;
    case _Category.natur:
      return _kNaturColor;
    case _Category.raetselhaft:
      return _kRaetselColor;
  }
}

String _labelFor(_Category c) {
  switch (c) {
    case _Category.heilig:
      return 'Heilig';
    case _Category.antik:
      return 'Antik';
    case _Category.natur:
      return 'Natur';
    case _Category.raetselhaft:
      return 'Raetselhaft';
  }
}

// The curated 24 places.
const List<_MysticPlace> _kPlaces = <_MysticPlace>[
  // ============== HEILIG ==============
  _MysticPlace(
    emoji: '🌀',
    name: 'Stonehenge',
    region: 'Wiltshire, UK',
    description: '5000 Jahre alter Sonnenkreis - wer bewegte die 25t-Steine?',
    lat: 51.1789,
    lng: -1.8262,
    category: _Category.heilig,
  ),
  _MysticPlace(
    emoji: '🪨',
    name: 'Externsteine',
    region: 'Deutschland',
    description:
        'Heiliger Sandsteinfels der Germanen mit praezisem Sonnenwend-Loch',
    lat: 51.8689,
    lng: 8.9181,
    category: _Category.heilig,
  ),
  _MysticPlace(
    emoji: '🏔️',
    name: 'Glastonbury Tor',
    region: 'England',
    description: 'Huegel des Avalon-Mythos, Schnittpunkt von Ley-Linien',
    lat: 51.1442,
    lng: -2.6989,
    category: _Category.heilig,
  ),
  _MysticPlace(
    emoji: '⛰️',
    name: 'Mt Kailash',
    region: 'Tibet',
    description: 'Heiligster Berg der Welt fuer 4 Religionen - nie bestiegen',
    lat: 31.0668,
    lng: 81.3119,
    category: _Category.heilig,
  ),
  _MysticPlace(
    emoji: '🌋',
    name: 'Sedona Vortex',
    region: 'Arizona, USA',
    description: 'Energie-Vortex-Punkte, magnetische Anomalien',
    lat: 34.8697,
    lng: -111.7610,
    category: _Category.heilig,
  ),
  _MysticPlace(
    emoji: '🟥',
    name: 'Uluru',
    region: 'Australien',
    description:
        'Heiliger Monolith der Aborigines, aendert die Farbe mit der Sonne',
    lat: -25.3444,
    lng: 131.0369,
    category: _Category.heilig,
  ),

  // ============== ANTIK ==============
  _MysticPlace(
    emoji: '🔺',
    name: 'Pyramiden von Gizeh',
    region: 'Aegypten',
    description:
        '2.3 Mio Steinbloecke ueber 2.5t - Bautechnik bis heute Raetsel',
    lat: 29.9792,
    lng: 31.1342,
    category: _Category.antik,
  ),
  _MysticPlace(
    emoji: '🏯',
    name: 'Machu Picchu',
    region: 'Peru',
    description: 'Inka-Stadt 2400m hoch, ohne Moertel gebaut, erdbebensicher',
    lat: -13.1631,
    lng: -72.5450,
    category: _Category.antik,
  ),
  _MysticPlace(
    emoji: '🏛️',
    name: 'Petra',
    region: 'Jordanien',
    description:
        'Aus rosa Fels gehauene Stadt, 1812 nach 600 Jahren wiederentdeckt',
    lat: 30.3285,
    lng: 35.4444,
    category: _Category.antik,
  ),
  _MysticPlace(
    emoji: '🗿',
    name: 'Goebekli Tepe',
    region: 'Tuerkei',
    description:
        'Aeltester Tempel der Welt, 11.500 Jahre - aelter als Ackerbau',
    lat: 37.2231,
    lng: 38.9224,
    category: _Category.antik,
  ),
  _MysticPlace(
    emoji: '☀️',
    name: 'Teotihuacan',
    region: 'Mexiko',
    description: 'Wer baute die Sonnen-Pyramide? Erbauer-Volk verschollen',
    lat: 19.6925,
    lng: -98.8438,
    category: _Category.antik,
  ),
  _MysticPlace(
    emoji: '🛕',
    name: 'Angkor Wat',
    region: 'Kambodscha',
    description: 'Groesster religioeser Bau der Welt, exakte Stern-Ausrichtung',
    lat: 13.4125,
    lng: 103.8670,
    category: _Category.antik,
  ),

  // ============== NATUR ==============
  _MysticPlace(
    emoji: '🛸',
    name: 'Nazca-Linien',
    region: 'Peru',
    description: 'Geoglyphen nur aus der Luft erkennbar - von wem fuer wen?',
    lat: -14.7390,
    lng: -75.1300,
    category: _Category.natur,
  ),
  _MysticPlace(
    emoji: '🪞',
    name: 'Salar de Uyuni',
    region: 'Bolivien',
    description: 'Groesster Spiegel der Welt - Himmel zu Erde',
    lat: -20.1338,
    lng: -67.4891,
    category: _Category.natur,
  ),
  _MysticPlace(
    emoji: '🕳️',
    name: 'Lichi Lava-Hoehlen',
    region: 'Island',
    description: 'Tief im Erdinneren, Geothermal-Tunnel',
    lat: 64.1466,
    lng: -21.9426,
    category: _Category.natur,
  ),
  _MysticPlace(
    emoji: '🌊',
    name: 'Bermuda-Dreieck',
    region: 'Atlantik',
    description: 'Schiffe und Flugzeuge verschwinden seit Jahrzehnten',
    lat: 25.0000,
    lng: -71.0000,
    category: _Category.natur,
  ),
  _MysticPlace(
    emoji: '🏰',
    name: 'Bran Castle (Dracula)',
    region: 'Rumaenien',
    description: 'Bram Stokers Vorlage thront ueber den Karpaten',
    lat: 45.5149,
    lng: 25.3674,
    category: _Category.natur,
  ),
  _MysticPlace(
    emoji: '💧',
    name: 'Plitvicka Jezera',
    region: 'Kroatien',
    description: '16 Seen kaskadieren uebereinander in tuerkisem Wasser',
    lat: 44.8654,
    lng: 15.5820,
    category: _Category.natur,
  ),

  // ============== RAETSELHAFT ==============
  _MysticPlace(
    emoji: '🐉',
    name: 'Loch Ness',
    region: 'Schottland',
    description: 'Tiefer als die Nordsee, Sonarbilder bleiben ungeloest',
    lat: 57.3229,
    lng: -4.4244,
    category: _Category.raetselhaft,
  ),
  _MysticPlace(
    emoji: '🪨',
    name: 'Bimini-Road',
    region: 'Bahamas',
    description:
        'Versunkene "Strasse" aus rechteckigen Steinen - Natur oder Bau?',
    lat: 25.7651,
    lng: -79.2786,
    category: _Category.raetselhaft,
  ),
  _MysticPlace(
    emoji: '🌊',
    name: 'Yonaguni Monument',
    region: 'Japan',
    description:
        'Versunkene Stein-Strukturen, moeglicherweise 10.000 Jahre alt',
    lat: 24.4338,
    lng: 123.0117,
    category: _Category.raetselhaft,
  ),
  _MysticPlace(
    emoji: '🗿',
    name: 'Easter Island',
    region: 'Pazifik',
    description: '887 Moai-Statuen - wie wurden sie bewegt?',
    lat: -27.1127,
    lng: -109.3497,
    category: _Category.raetselhaft,
  ),
  _MysticPlace(
    emoji: '🪨',
    name: 'Carnac-Steine',
    region: 'Frankreich',
    description: '3000 Megalithen in geraden Reihen, aelter als Stonehenge',
    lat: 47.5827,
    lng: -3.0760,
    category: _Category.raetselhaft,
  ),
  _MysticPlace(
    emoji: '🌲',
    name: 'Crooked Forest',
    region: 'Polen',
    description: '400 Kiefern wachsen 90 Grad gebogen - niemand weiss warum',
    lat: 53.2086,
    lng: 14.4793,
    category: _Category.raetselhaft,
  ),
];

// ============================================================
// Screen
// ============================================================

class GeheimeKarteScreen extends StatefulWidget {
  const GeheimeKarteScreen({super.key});

  @override
  State<GeheimeKarteScreen> createState() => _GeheimeKarteScreenState();
}

class _GeheimeKarteScreenState extends State<GeheimeKarteScreen>
    with TickerProviderStateMixin {
  static const String _prefsKey = 'mystic_visited_v1';

  _Category? _filter; // null = all
  Set<String> _visited = <String>{};
  bool _loaded = false;

  late final AnimationController _orbCtrl;

  @override
  void initState() {
    super.initState();
    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
    _loadVisited();
  }

  @override
  void dispose() {
    _orbCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadVisited() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null && raw.isNotEmpty) {
        final list = (jsonDecode(raw) as List<dynamic>).cast<String>();
        if (mounted) {
          setState(() {
            _visited = list.toSet();
            _loaded = true;
          });
          return;
        }
      }
    } catch (_) {
      // Silent fallback to empty set.
    }
    if (mounted) {
      setState(() => _loaded = true);
    }
  }

  Future<void> _toggleVisited(String name) async {
    HapticFeedback.selectionClick();
    setState(() {
      if (_visited.contains(name)) {
        _visited.remove(name);
      } else {
        _visited.add(name);
      }
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(_visited.toList()));
    } catch (_) {
      // Persist failure is non-fatal.
    }
  }

  Future<void> _openInMaps(_MysticPlace place) async {
    HapticFeedback.lightImpact();
    final url =
        'https://www.google.com/maps/search/?api=1&query=${place.lat},${place.lng}';
    final uri = Uri.parse(url);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) {
        await _fallbackCopy(url);
      }
    } catch (_) {
      await _fallbackCopy(url);
    }
  }

  Future<void> _fallbackCopy(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Karten-Link kopiert: $url'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1A1A2E),
      ),
    );
  }

  List<_MysticPlace> get _filtered {
    if (_filter == null) return _kPlaces;
    return _kPlaces.where((p) => p.category == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final totalVisited = _visited.length;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF02040A),
      appBar: WBGlassAppBar(
        titleWidget: ShaderMask(
          shaderCallback: (rect) => const LinearGradient(
            colors: [_kHeiligColor, Color(0xFF8AA3FF)],
          ).createShader(rect),
          child: Text(
            'MYSTISCHE ORTE',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w300,
              fontSize: 16,
              letterSpacing: 4.0,
              color: Colors.white,
            ),
          ),
        ),
        world: WBWorld.neutral,
      ),
      body: Stack(
        children: [
          // Background gradient
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.3, -0.6),
                  radius: 1.3,
                  colors: [
                    Color(0xFF0E0822),
                    Color(0xFF02040A),
                  ],
                ),
              ),
            ),
          ),
          // CineOrbs
          AnimatedBuilder(
            animation: _orbCtrl,
            builder: (_, __) => CustomPaint(
              size: Size.infinite,
              painter: _OrbPainter(t: _orbCtrl.value),
            ),
          ),
          // Particles
          const Positioned.fill(
            child: IgnorePointer(
              child: WBAmbientParticles(
                world: WBWorld.neutral,
                count: 50,
                maxRadius: 1.8,
                speed: 0.25,
              ),
            ),
          ),
          // Vignette
          const Positioned.fill(
            child: WBVignette(intensity: 0.5),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: kToolbarHeight),
                _buildStatsHeader(totalVisited),
                _buildFilterChips(),
                Expanded(
                  child: _loaded
                      ? _buildList(filtered)
                      : const Center(
                          child: CircularProgressIndicator(
                            color: _kHeiligColor,
                            strokeWidth: 2,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader(int visited) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          WBSpace.xl, WBSpace.lg, WBSpace.xl, WBSpace.sm),
      child: Row(
        children: [
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white70,
                  letterSpacing: 1.2,
                ),
                children: [
                  TextSpan(
                    text: '${_kPlaces.length}',
                    style: const TextStyle(
                      color: _kHeiligColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const TextSpan(text: ' ORTE  -  '),
                  TextSpan(
                    text: '$visited',
                    style: const TextStyle(
                      color: _kNaturColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const TextSpan(text: ' BESUCHT'),
                ],
              ),
            ),
          ),
          if (visited > 0)
            GestureDetector(
              onTap: () async {
                HapticFeedback.mediumImpact();
                setState(() => _visited.clear());
                try {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove(_prefsKey);
                } catch (e) { if (kDebugMode) debugPrint('geheime_karte_screen: silent catch -> $e'); }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: WBSpace.md, vertical: WBSpace.xs),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(WBRadius.pill),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15), width: 1),
                ),
                child: Text(
                  'RESET',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Colors.white54,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final chips = <Widget>[
      _buildChip(label: 'Alle', color: const Color(0xFF8AA3FF), category: null),
      _buildChip(
          label: _labelFor(_Category.heilig),
          color: _kHeiligColor,
          category: _Category.heilig),
      _buildChip(
          label: _labelFor(_Category.antik),
          color: _kAntikColor,
          category: _Category.antik),
      _buildChip(
          label: _labelFor(_Category.natur),
          color: _kNaturColor,
          category: _Category.natur),
      _buildChip(
          label: 'Raetselhaft',
          color: _kRaetselColor,
          category: _Category.raetselhaft),
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: WBSpace.xl),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: WBSpace.sm),
        itemBuilder: (_, i) => chips[i],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required Color color,
    required _Category? category,
  }) {
    final active = _filter == category;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _filter = category);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
            horizontal: WBSpace.lg, vertical: WBSpace.sm),
        decoration: BoxDecoration(
          color: active
              ? color.withValues(alpha: 0.20)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(WBRadius.pill),
          border: Border.all(
            color: active
                ? color.withValues(alpha: 0.65)
                : Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.30),
                    blurRadius: 14,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.0,
            color: active ? color : Colors.white60,
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<_MysticPlace> places) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
          WBSpace.lg, WBSpace.lg, WBSpace.lg, WBSpace.huge),
      itemCount: places.length,
      separatorBuilder: (_, __) => const SizedBox(height: WBSpace.md),
      itemBuilder: (_, i) {
        final p = places[i];
        return _PlaceCard(
          place: p,
          visited: _visited.contains(p.name),
          onOpenMap: () => _openInMaps(p),
          onToggle: () => _toggleVisited(p.name),
        );
      },
    );
  }
}

// ============================================================
// Card widget
// ============================================================

class _PlaceCard extends StatelessWidget {
  final _MysticPlace place;
  final bool visited;
  final VoidCallback onOpenMap;
  final VoidCallback onToggle;

  const _PlaceCard({
    required this.place,
    required this.visited,
    required this.onOpenMap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _colorFor(place.category);
    final bgAlpha = visited ? 0.18 : 0.08;

    return ClipRRect(
      borderRadius: BorderRadius.circular(WBRadius.lg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: Color.lerp(
              const Color(0xFF0A0A18),
              Colors.black,
              visited ? 0.55 : 0.0,
            )!
                .withValues(alpha: bgAlpha + 0.55),
            borderRadius: BorderRadius.circular(WBRadius.lg),
            border: Border.all(
              color: accent.withValues(alpha: visited ? 0.55 : 0.30),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: visited ? 0.18 : 0.10),
                blurRadius: 18,
                spreadRadius: 0,
              ),
            ],
          ),
          padding: const EdgeInsets.all(WBSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Emoji
                  Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(WBRadius.md),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.30),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      place.emoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                  const SizedBox(width: WBSpace.md),
                  // Name + region + description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                place.name,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                            if (visited)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _kNaturColor.withValues(alpha: 0.20),
                                  borderRadius:
                                      BorderRadius.circular(WBRadius.pill),
                                  border: Border.all(
                                    color: _kNaturColor.withValues(alpha: 0.55),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  '✓ BESUCHT',
                                  style: GoogleFonts.inter(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    color: _kNaturColor,
                                    letterSpacing: 1.4,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          place.region.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: accent.withValues(alpha: 0.95),
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: WBSpace.sm),
                        Text(
                          place.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Colors.white70,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: WBSpace.md),
              // Action row
              Row(
                children: [
                  Expanded(
                    child: _actionButton(
                      icon: '🗺️',
                      label: 'IN KARTE OEFFNEN',
                      color: accent,
                      onTap: onOpenMap,
                    ),
                  ),
                  const SizedBox(width: WBSpace.sm),
                  Expanded(
                    child: _actionButton(
                      icon: visited ? '↺' : '📌',
                      label: visited ? 'ZURUECKSETZEN' : 'ALS BESUCHT',
                      color: visited ? Colors.white60 : _kNaturColor,
                      onTap: onToggle,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required String icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: WBSpace.md, vertical: WBSpace.sm),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(WBRadius.sm),
          border: Border.all(
            color: color.withValues(alpha: 0.40),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// CineOrb painter (subtle slow blobs)
// ============================================================

class _OrbPainter extends CustomPainter {
  final double t;
  const _OrbPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final orbs = <_Orb>[
      _Orb(
        center: Offset(
          size.width * (0.25 + 0.10 * math.sin(t * 2 * math.pi)),
          size.height * (0.30 + 0.05 * math.cos(t * 2 * math.pi)),
        ),
        radius: size.width * 0.55,
        color: _kHeiligColor.withValues(alpha: 0.08),
      ),
      _Orb(
        center: Offset(
          size.width * (0.85 + 0.05 * math.cos(t * 2 * math.pi * 0.7)),
          size.height * (0.55 + 0.08 * math.sin(t * 2 * math.pi * 0.7)),
        ),
        radius: size.width * 0.65,
        color: _kRaetselColor.withValues(alpha: 0.09),
      ),
      _Orb(
        center: Offset(
          size.width * 0.5,
          size.height * (0.90 + 0.04 * math.sin(t * 2 * math.pi * 0.4)),
        ),
        radius: size.width * 0.50,
        color: _kNaturColor.withValues(alpha: 0.07),
      ),
    ];

    for (final o in orbs) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [o.color, Colors.transparent],
        ).createShader(Rect.fromCircle(center: o.center, radius: o.radius));
      canvas.drawCircle(o.center, o.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbPainter old) => old.t != t;
}

class _Orb {
  final Offset center;
  final double radius;
  final Color color;
  const _Orb({
    required this.center,
    required this.radius,
    required this.color,
  });
}
