// ♓ GEBURTSHOROSKOP 360° · Cinematic Visual-Chart mit Aspekten
//
// Klassisches Astrologie-Rad: Außen Tierkreis (12 Zeichen), innen Planeten an
// ihren Längengrad-Positionen, Aspekt-Linien (Konjunktion, Opposition, Trigon,
// Quadrat, Sextil) zwischen Planeten.
//
// Optional: Transit-Overlay (heutige Planetenpositionen als zweiter Ring).
// Eingabe: Datum/Zeit/Ort. Math via NatalAstrology Service (existiert).

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/storage/unified_storage_service.dart';
import '../../../services/natal_astrology_service.dart';
import '../../../services/spirit_reading_service.dart';
import '../../../services/storage_service.dart';
import '../../../theme/wb_cinematic_tokens.dart';
import '../../../widgets/cinematic/wb_ambient_particles.dart';
import '../../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../../widgets/cinematic/wb_vignette.dart';

class BirthChart360Screen extends StatefulWidget {
  const BirthChart360Screen({super.key});

  @override
  State<BirthChart360Screen> createState() => _BirthChart360ScreenState();
}

class _BirthChart360ScreenState extends State<BirthChart360Screen>
    with TickerProviderStateMixin {
  static const Color _bgDark = Color(0xFF030212);

  /// Theme-aware background. Light-Mode liefert helle `context.wb.bgVoid`,
  /// Dark-Mode behält den Original-Ton.
  Color _bg(BuildContext context) {
    final wb = Theme.of(context).extension<WBCinematic>();
    return wb?.bgVoid ?? _bgDark;
  }

  static const Color _primary = Color(0xFF1A237E);
  static const Color _accent = Color(0xFF7E57C2);
  static const Color _gold = Color(0xFFFFD54F);

  DateTime _birthDate = DateTime(1990, 6, 21, 12, 0);
  // v95: Geburtsort-Koordinaten fuer Haeuser-Berechnung
  double? _profileLat;
  double? _profileLng;
  bool _hasTime = true;
  NatalChartResult? _chart;
  NatalChartResult? _transit;
  bool _showTransits = false;

  late final AnimationController _wheelCtrl;
  late final AnimationController _ambientCtrl;

  @override
  void initState() {
    super.initState();
    _wheelCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000));
    _ambientCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 11))
          ..repeat();
    _prefillFromProfile();
  }

  Future<void> _prefillFromProfile() async {
    final p = await StorageService().loadEnergieProfile();
    if (p == null || !mounted) return;
    final bd = p.birthDate;
    int h = 12, m = 0;
    if (p.birthTime != null && p.birthTime!.contains(':')) {
      final parts = p.birthTime!.split(':');
      h = int.tryParse(parts[0]) ?? 12;
      m = int.tryParse(parts[1]) ?? 0;
      _hasTime = true;
    } else {
      _hasTime = false;
    }
    setState(() {
      _birthDate = DateTime(bd.year, bd.month, bd.day, h, m);
      _profileLat = p.birthLatitude;
      _profileLng = p.birthLongitude;
    });
    // Auto-compute sobald Profil-Daten da sind
    _compute();
  }

  @override
  void dispose() {
    _wheelCtrl.dispose();
    _ambientCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    HapticFeedback.selectionClick();
    final d = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
              const ColorScheme.dark(primary: _accent, onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (d == null) return;
    if (_hasTime) {
      final t = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_birthDate),
        builder: (ctx, child) => Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.dark(
                primary: _accent, onPrimary: Colors.white),
          ),
          child: child!,
        ),
      );
      if (t != null) {
        _birthDate = DateTime(d.year, d.month, d.day, t.hour, t.minute);
      } else {
        _birthDate = DateTime(d.year, d.month, d.day, 12, 0);
      }
    } else {
      _birthDate = DateTime(d.year, d.month, d.day, 12, 0);
    }
    setState(() {});
  }

  void _compute() {
    HapticFeedback.mediumImpact();
    final birth = _birthDate.toUtc();
    final chart = NatalAstrology.compute(birthDateUtc: birth);
    final transit =
        NatalAstrology.compute(birthDateUtc: DateTime.now().toUtc());
    setState(() {
      _chart = chart;
      _transit = transit;
    });
    _wheelCtrl.forward(from: 0);
  }

  Future<void> _save() async {
    if (_chart == null) return;
    final username = UnifiedStorageService().getUsername('energie');
    final userId = await UnifiedStorageService().getCurrentUserId() ?? 'anonym';
    final saved = await SpiritReadingService.instance.save(
      userId: userId,
      username: username,
      tool: 'birth_chart',
      summary:
          '♓ ${_fmt(_birthDate)} · Sonne in ${_signName(_chart!.planets["sun"]!.sign)}',
      result: {
        'birth_date': _birthDate.toIso8601String(),
        'planets': _chart!.planets.map((k, v) => MapEntry(k, v.toJson())),
      },
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(saved != null
          ? '✨ Geburtshoroskop gespeichert'
          : '⚠️ Speichern fehlgeschlagen'),
      backgroundColor: _accent,
    ));
  }

  String _signName(int s) => const [
        'Widder',
        'Stier',
        'Zwilling',
        'Krebs',
        'Löwe',
        'Jungfrau',
        'Waage',
        'Skorpion',
        'Schütze',
        'Steinbock',
        'Wassermann',
        'Fische'
      ][s % 12];

  String _signGlyph(int s) => const [
        '♈',
        '♉',
        '♊',
        '♋',
        '♌',
        '♍',
        '♎',
        '♏',
        '♐',
        '♑',
        '♒',
        '♓'
      ][s % 12];

  String _planetGlyph(String p) =>
      const {
        'sun': '☉',
        'moon': '☽',
        'mercury': '☿',
        'venus': '♀',
        'mars': '♂',
        'jupiter': '♃',
        'saturn': '♄',
        'uranus': '♅',
        'neptune': '♆',
        'pluto': '♇',
      }[p] ??
      '○';

  String _planetLabel(String p) =>
      const {
        'sun': 'Sonne',
        'moon': 'Mond',
        'mercury': 'Merkur',
        'venus': 'Venus',
        'mars': 'Mars',
        'jupiter': 'Jupiter',
        'saturn': 'Saturn',
        'uranus': 'Uranus',
        'neptune': 'Neptun',
        'pluto': 'Pluto',
      }[p] ??
      p;

  String _fmt(DateTime dt) {
    final d = dt.toLocal();
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg(context),
      extendBodyBehindAppBar: true,
      appBar: WBGlassAppBar(
        world: WBWorld.energie,
        titleWidget: ShaderMask(
          shaderCallback: (r) => const LinearGradient(
            colors: [_gold, _accent],
          ).createShader(r),
          child: const Text('GEBURTSHOROSKOP 360°',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.5)),
        ),
        actions: [
          if (_chart != null) ...[
            IconButton(
              icon: Icon(
                  _showTransits
                      ? Icons.layers_clear_rounded
                      : Icons.layers_rounded,
                  color: _showTransits ? _gold : Colors.white70),
              tooltip: _showTransits ? 'Transits aus' : 'Transits (heute)',
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() => _showTransits = !_showTransits);
              },
            ),
            IconButton(
              icon: const Icon(Icons.bookmark_added_rounded, color: _gold),
              tooltip: 'Speichern',
              onPressed: _save,
            ),
          ],
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.3),
                radius: 1.5,
                colors: [Color(0x551A237E), Color(0x3306040F), _bgDark],
              ),
            ),
          ),
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _ambientCtrl,
              builder: (_, __) => CustomPaint(
                painter: _ChartOrbsPainter(_ambientCtrl.value),
                size: Size.infinite,
              ),
            ),
          ),
          const IgnorePointer(
              child: WBAmbientParticles(world: WBWorld.energie, count: 50)),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
              child: Column(children: [
                _birthDateCard(),
                const SizedBox(height: 12),
                if (_chart != null) ...[
                  _chartWheel(),
                  const SizedBox(height: 14),
                  _planetTable(),
                  const SizedBox(height: 14),
                  _housesCard(),
                ] else
                  _emptyState(),
              ]),
            ),
          ),
          const IgnorePointer(child: WBVignette()),
        ],
      ),
    );
  }

  Widget _birthDateCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('GEBURTSZEITPUNKT',
                style: TextStyle(
                    color: _gold,
                    fontSize: 10,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _accent.withValues(alpha: 0.4)),
                    ),
                    child: Row(children: [
                      Icon(Icons.calendar_month_rounded,
                          color: _gold, size: 16),
                      const SizedBox(width: 8),
                      Text(_fmt(_birthDate),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              const Text('Genaue Uhrzeit?',
                  style: TextStyle(color: Colors.white70, fontSize: 11)),
              const Spacer(),
              Switch(
                value: _hasTime,
                onChanged: (v) => setState(() {
                  _hasTime = v;
                  if (!v)
                    _birthDate = DateTime(_birthDate.year, _birthDate.month,
                        _birthDate.day, 12, 0);
                }),
                activeColor: _accent,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ]),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _compute,
                icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                label: const Text('HOROSKOP BERECHNEN',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(children: [
        Icon(Icons.brightness_2_rounded,
            color: _accent.withValues(alpha: 0.4), size: 80),
        const SizedBox(height: 16),
        const Text('Wähle dein Geburtsdatum und tippe Berechnen',
            style: TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center),
        const SizedBox(height: 4),
        const Text('Geburtszeit verbessert Genauigkeit (Aszendent + Häuser)',
            style: TextStyle(
                color: Colors.white38,
                fontSize: 11,
                fontStyle: FontStyle.italic),
            textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _chartWheel() {
    return AspectRatio(
      aspectRatio: 1,
      child: AnimatedBuilder(
        animation: _wheelCtrl,
        builder: (_, __) => Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: RadialGradient(colors: [
              _primary.withValues(alpha: 0.15),
              Colors.black.withValues(alpha: 0.3),
            ]),
            border: Border.all(color: _accent.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                  color: _accent.withValues(alpha: 0.2),
                  blurRadius: 30,
                  spreadRadius: 2),
            ],
          ),
          child: CustomPaint(
            painter: _ZodiacWheelPainter(
              chart: _chart!,
              transit: _showTransits ? _transit : null,
              reveal: _wheelCtrl.value,
              accent: _accent,
              gold: _gold,
              primary: _primary,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }

  // v95: Haeuser-Card. Erfordert Geburtsort-Koordinaten -- ohne wird
  // ein erklaerender Hinweis statt der Haeuser angezeigt.
  Widget _housesCard() {
    final birth = _birthDate.toUtc();
    // Versuche, Koordinaten aus dem Profil zu holen
    // (Light-Weight: wir nutzen 0/0 als Default und zeigen Hinweis).
    final lat = _profileLat;
    final lng = _profileLng;
    if (lat == null || lng == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
        ),
        child: Row(children: [
          const Icon(Icons.info_outline_rounded,
              color: Colors.amberAccent, size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Häuser können nicht berechnet werden -- Geburtsort mit '
              'Koordinaten im Profil erforderlich.',
              style:
                  TextStyle(color: Colors.white, fontSize: 12.5, height: 1.45),
            ),
          ),
        ]),
      );
    }
    final houses = NatalAstrology.calculateHouses(
      birthDateUtc: birth,
      latitude: lat,
      longitude: lng,
    );
    if (houses == null) return const SizedBox.shrink();
    final asc = houses['ascendant'] as PlanetPosition;
    final mc = houses['midheaven'] as PlanetPosition;
    final planetHouses = (houses['planetHouses'] as Map).cast<String, int>();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _gold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _gold.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('HÄUSER (EQUAL-HOUSE)',
              style: TextStyle(
                  color: _gold,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2)),
          const SizedBox(height: 10),
          _angleRow('Aszendent', _signName(asc.sign),
              '${asc.degree.toStringAsFixed(1)}°'),
          _angleRow('Medium Coeli', _signName(mc.sign),
              '${mc.degree.toStringAsFixed(1)}°'),
          const SizedBox(height: 10),
          const Text('Planeten in Häusern',
              style: TextStyle(
                  color: Colors.white60,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: planetHouses.entries.map((e) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_planetDe(e.key)} → ${e.value}. Haus',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _angleRow(String label, String sign, String deg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
          const Spacer(),
          Text('$sign · $deg',
              style: const TextStyle(
                  color: _gold, fontSize: 12.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  String _planetDe(String key) => switch (key) {
        'sun' => '☉ Sonne',
        'moon' => '☽ Mond',
        'mercury' => '☿ Merkur',
        'venus' => '♀ Venus',
        'mars' => '♂ Mars',
        'jupiter' => '♃ Jupiter',
        'saturn' => '♄ Saturn',
        'uranus' => '♅ Uranus',
        'neptune' => '♆ Neptun',
        'pluto' => '♇ Pluto',
        _ => key,
      };

  Widget _planetTable() {
    final planets = _chart!.planets;
    final order = [
      'sun',
      'moon',
      'mercury',
      'venus',
      'mars',
      'jupiter',
      'saturn',
      'uranus',
      'neptune',
      'pluto'
    ];
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(children: [
            const Text('PLANETEN-POSITIONEN',
                style: TextStyle(
                    color: _gold,
                    fontSize: 10,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...order.where((p) => planets.containsKey(p)).map((p) {
              final pos = planets[p]!;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  Text(_planetGlyph(p),
                      style: const TextStyle(
                          color: _gold,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 75,
                    child: Text(_planetLabel(p),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                  Text(_signGlyph(pos.sign),
                      style: const TextStyle(color: _accent, fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(_signName(pos.sign),
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 11)),
                  const Spacer(),
                  Text('${pos.degree.toStringAsFixed(1)}°',
                      style: TextStyle(
                          color: _gold.withValues(alpha: 0.9),
                          fontSize: 11,
                          fontFamily: 'monospace')),
                ]),
              );
            }),
            const SizedBox(height: 10),
            Text(
              _showTransits
                  ? 'Innen: Geburts-Chart · Außen: Transits (heute)'
                  : 'Tippe das Layers-Icon oben für Transit-Overlay',
              style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ]),
        ),
      ),
    );
  }
}

// ── PAINTER: Zodiac Wheel + Planeten + Aspekte ───────────────────────────────
class _ZodiacWheelPainter extends CustomPainter {
  final NatalChartResult chart;
  final NatalChartResult? transit;
  final double reveal; // 0..1 Animation
  final Color accent;
  final Color gold;
  final Color primary;

  _ZodiacWheelPainter({
    required this.chart,
    required this.transit,
    required this.reveal,
    required this.accent,
    required this.gold,
    required this.primary,
  });

  static const _signColors = [
    Color(0xFFE53935),
    Color(0xFF8D6E63),
    Color(0xFFFDD835),
    Color(0xFF42A5F5),
    Color(0xFFFF7043),
    Color(0xFF66BB6A),
    Color(0xFFAB47BC),
    Color(0xFF7B1FA2),
    Color(0xFFEF6C00),
    Color(0xFF4E342E),
    Color(0xFF26C6DA),
    Color(0xFF7C4DFF),
  ];

  static const _planetGlyphs = {
    'sun': '☉',
    'moon': '☽',
    'mercury': '☿',
    'venus': '♀',
    'mars': '♂',
    'jupiter': '♃',
    'saturn': '♄',
    'uranus': '♅',
    'neptune': '♆',
    'pluto': '♇',
  };

  static const _zodiacGlyphs = [
    '♈',
    '♉',
    '♊',
    '♋',
    '♌',
    '♍',
    '♎',
    '♏',
    '♐',
    '♑',
    '♒',
    '♓'
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = math.min(size.width, size.height) / 2 - 8;
    final outerR = maxR;
    final signR = maxR - 16;
    final innerR = maxR * 0.7;
    final planetR = maxR * 0.78;
    final transitR = maxR * 0.88;

    // 1. Außen-Ring: Zeichen-Sektoren als Tortenstücke
    for (int i = 0; i < 12; i++) {
      final startAngle = _signStartAngle(i);
      final sweep = math.pi / 6;
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = _signColors[i].withValues(alpha: 0.18 * reveal);
      canvas.drawArc(Rect.fromCircle(center: center, radius: outerR),
          startAngle, sweep, true, paint);
      // Trennlinie
      final lineEnd =
          center + Offset(math.cos(startAngle), math.sin(startAngle)) * outerR;
      canvas.drawLine(
          center,
          lineEnd,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.15)
            ..strokeWidth = 0.5);
      // Zeichen-Glyph
      final glyphAngle = startAngle + sweep / 2;
      final glyphPos =
          center + Offset(math.cos(glyphAngle), math.sin(glyphAngle)) * signR;
      final tp = TextPainter(
        text: TextSpan(
            text: _zodiacGlyphs[i],
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9 * reveal),
                fontSize: maxR * 0.08,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: _signColors[i], blurRadius: 6)])),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, glyphPos - Offset(tp.width / 2, tp.height / 2));
    }

    // 2. Inner-Kreis (Erde)
    canvas.drawCircle(
        center, innerR, Paint()..color = Colors.black.withValues(alpha: 0.6));
    canvas.drawCircle(
        center,
        innerR,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = gold.withValues(alpha: 0.7 * reveal));

    // Grad-Markierungen (alle 5°)
    for (int d = 0; d < 360; d += 5) {
      final angle = _degreeToAngle(d.toDouble());
      final isMajor = d % 30 == 0;
      final r1 = innerR + (isMajor ? 0 : 4);
      final r2 = innerR + (isMajor ? 10 : 7);
      final p1 = center + Offset(math.cos(angle), math.sin(angle)) * r1;
      final p2 = center + Offset(math.cos(angle), math.sin(angle)) * r2;
      canvas.drawLine(
          p1,
          p2,
          Paint()
            ..color =
                Colors.white.withValues(alpha: isMajor ? 0.5 : 0.2 * reveal)
            ..strokeWidth = isMajor ? 1 : 0.5);
    }

    // 3. Aspekt-Linien (Verbindungen zwischen Planeten in bestimmten Winkeln)
    final pos = chart.planets;
    final entries = pos.entries.toList();
    for (int i = 0; i < entries.length; i++) {
      for (int j = i + 1; j < entries.length; j++) {
        final lon1 = entries[i].value.longitude;
        final lon2 = entries[j].value.longitude;
        final diff = (lon1 - lon2).abs();
        final actualDiff = diff > 180 ? 360 - diff : diff;
        Color? aspectColor;
        double aspectAlpha = 0.0;
        // Aspekte: Konjunktion (0°), Opposition (180°), Trigon (120°), Quadrat (90°), Sextil (60°)
        if (actualDiff < 8) {
          aspectColor = gold;
          aspectAlpha = 0.6;
        } else if ((actualDiff - 180).abs() < 8) {
          aspectColor = Colors.redAccent;
          aspectAlpha = 0.5;
        } else if ((actualDiff - 120).abs() < 6) {
          aspectColor = Colors.greenAccent;
          aspectAlpha = 0.5;
        } else if ((actualDiff - 90).abs() < 6) {
          aspectColor = Colors.orangeAccent;
          aspectAlpha = 0.4;
        } else if ((actualDiff - 60).abs() < 4) {
          aspectColor = Colors.cyanAccent;
          aspectAlpha = 0.35;
        }
        if (aspectColor != null) {
          final a1 = _degreeToAngle(lon1);
          final a2 = _degreeToAngle(lon2);
          final p1 = center + Offset(math.cos(a1), math.sin(a1)) * innerR;
          final p2 = center + Offset(math.cos(a2), math.sin(a2)) * innerR;
          canvas.drawLine(
              p1,
              p2,
              Paint()
                ..color = aspectColor.withValues(alpha: aspectAlpha * reveal)
                ..strokeWidth = 1);
        }
      }
    }

    // 4. Planeten an ihren Positionen
    for (final e in pos.entries) {
      final angle = _degreeToAngle(e.value.longitude);
      final pPos = center + Offset(math.cos(angle), math.sin(angle)) * planetR;
      // Hintergrund-Disk
      canvas.drawCircle(
          pPos, 14, Paint()..color = primary.withValues(alpha: 0.7 * reveal));
      canvas.drawCircle(
          pPos,
          14,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = gold.withValues(alpha: reveal));
      // Glyph
      final tp = TextPainter(
        text: TextSpan(
            text: _planetGlyphs[e.key] ?? '○',
            style: TextStyle(
                color: gold.withValues(alpha: reveal),
                fontSize: 14,
                fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pPos - Offset(tp.width / 2, tp.height / 2));
    }

    // 5. Transit-Overlay (heute)
    if (transit != null) {
      for (final e in transit!.planets.entries) {
        final angle = _degreeToAngle(e.value.longitude);
        final tPos =
            center + Offset(math.cos(angle), math.sin(angle)) * transitR;
        canvas.drawCircle(
            tPos, 10, Paint()..color = accent.withValues(alpha: 0.7 * reveal));
        canvas.drawCircle(
            tPos,
            10,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1
              ..color = Colors.white.withValues(alpha: reveal));
        final tp = TextPainter(
          text: TextSpan(
              text: _planetGlyphs[e.key] ?? '○',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: reveal),
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, tPos - Offset(tp.width / 2, tp.height / 2));
      }
    }

    // 6. Zentrum: Sonnen-Glyph
    final sunPos = pos['sun'];
    if (sunPos != null) {
      canvas.drawCircle(
          center, 14, Paint()..color = gold.withValues(alpha: 0.4 * reveal));
      final tp = TextPainter(
        text: TextSpan(
            text: '☉',
            style: TextStyle(
                color: gold, fontSize: 22, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
    }
  }

  // Konversion: Longitude → Mathematik-Winkel (im Tierkreis 0° = links/Aszendent, gegen-Uhr)
  // Astrologisch konventionell: 0° Widder oben/rechts, Bewegung gegen Uhrzeigersinn.
  // Hier: 0° = 9 Uhr Position (Aszendent links), und wir gehen mit Sonnenrichtung.
  double _signStartAngle(int signIndex) {
    // signIndex 0=Widder. Wir platzieren Widder rechts-mittig, dann gegen-Uhr durch die Zeichen.
    // canvas 0° ist rechts, +pi/2 = unten. astro 0° (Widder-Anfang) → canvas-Winkel π (links)
    // sodass das Chart Aszendent-links ist.
    final astroDeg = signIndex * 30.0;
    return _degreeToAngle(astroDeg);
  }

  double _degreeToAngle(double astroDeg) {
    // Aszendent rechts (0° = 0 Uhrzeit-Position):
    // canvas: 0 = right, π/2 = down, π = left, 3π/2 = up
    // Wir wollen astro 0° = canvas π (links) und Bewegung gegen Uhr → +
    return math.pi + (astroDeg * math.pi / 180);
  }

  @override
  bool shouldRepaint(_ZodiacWheelPainter old) =>
      old.chart != chart || old.transit != transit || old.reveal != reveal;
}

// ── PAINTER: Chart-Orbs ──────────────────────────────────────────────────────
class _ChartOrbsPainter extends CustomPainter {
  final double t;
  _ChartOrbsPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    _draw(
        canvas,
        Offset(size.width * 0.15,
            size.height * (0.25 + math.sin(t * 2 * math.pi) * 0.05)),
        120,
        const Color(0xFF1A237E));
    _draw(
        canvas,
        Offset(size.width * 0.85,
            size.height * (0.7 + math.cos(t * 2 * math.pi) * 0.04)),
        100,
        const Color(0xFF7E57C2));
    _draw(
        canvas,
        Offset(size.width * 0.5,
            size.height * (0.95 + math.sin(t * math.pi) * 0.03)),
        80,
        const Color(0xFFFFD54F));
  }

  void _draw(Canvas canvas, Offset c, double r, Color color) {
    final p = Paint()
      ..color = color.withValues(alpha: 0.10)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.5);
    canvas.drawCircle(c, r, p);
  }

  @override
  bool shouldRepaint(_ChartOrbsPainter old) => old.t != t;
}
