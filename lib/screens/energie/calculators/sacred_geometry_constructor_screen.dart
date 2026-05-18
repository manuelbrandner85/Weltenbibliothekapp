// 🔯 HEILIGE GEOMETRIE KONSTRUKTOR · Interaktiver Cinematic Touch-Editor
//
// Hyperrealistisch-cinematic im Stil der anderen aufgewerteten Spirit-Tools:
// WBGlassAppBar mit ShaderMask-Titel, 6-Layer-BG (Radial-Nebula → CineOrbs →
// 36 Ambient-Particles → Light-Beam → Vignette), BackdropFilter-Karten.
//
// 6 progressive Konstruktions-Stufen — jede baut auf der vorigen auf:
//   1. Vesica Piscis (2 sich schneidende Kreise)
//   2. Seed of Life (7 Kreise · Vesica × 6)
//   3. Egg of Life (8 Kreise · 3D-Andeutung)
//   4. Flower of Life (19 Kreise · klassische Form)
//   5. Fruit of Life (13 Kreise · Verbindungs-Linien)
//   6. Metatrons Würfel (Linien zwischen allen 13 Zentren)
//
// Touch-Interaktion:
// - Tap: bewegt Zentrum
// - Pan: skaliert Radius
// - Long-Press: rotiert um 30°
// - Slider unten: Stroke-Reveal-Animation 0–100%
//
// "Bedeutung" Bottom-Sheet pro Stufe mit Mythos + Meditation.
// "Saven" speichert Snapshot in spirit_readings (tool: 'geometry').

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/wb_cinematic_tokens.dart';
import '../../../widgets/cinematic/wb_ambient_particles.dart';
import '../../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../../widgets/cinematic/wb_vignette.dart';
import '../../../services/spirit_reading_service.dart';
import '../../../core/storage/unified_storage_service.dart';

class SacredGeometryConstructorScreen extends StatefulWidget {
  const SacredGeometryConstructorScreen({super.key});

  @override
  State<SacredGeometryConstructorScreen> createState() =>
      _SacredGeometryConstructorScreenState();
}

class _SacredGeometryConstructorScreenState
    extends State<SacredGeometryConstructorScreen>
    with TickerProviderStateMixin {
  static const Color _bg = Color(0xFF050216);
  static const Color _primary = Color(0xFF00BCD4); // cyan
  static const Color _accent = Color(0xFFAB47BC); // magenta-violet
  static const Color _gold = Color(0xFFFFD54F);

  // ── State ───────────────────────────────────────────────────────────────
  int _stage = 0; // 0..5
  Offset _center = const Offset(0.5, 0.5); // normiert 0..1
  double _radius = 0.18; // normiert relativ zur kleineren Achse
  double _rotation = 0.0; // in Radians
  double _reveal = 1.0; // 0..1 — Stroke-Reveal-Animation

  late final AnimationController _glowCtrl;
  late final AnimationController _revealCtrl;
  late final AnimationController _ambientCtrl;
  bool _isMeditation = false;

  static const List<_StageInfo> _stages = [
    _StageInfo(
      name: 'Vesica Piscis',
      tagline: 'Schnittpunkt zweier Welten',
      symbol: '✶',
      mythos:
          'Die Vesica Piscis ("Fisch-Blase") entsteht wenn sich zwei Kreise so durchdringen, dass jeder durch das Zentrum des anderen läuft. In christlicher Mystik ist sie das Symbol der Christus-Mandorla — der Übergang zwischen Himmel und Erde. Pythagoras nannte sie "die heiligste Zahl" weil aus ihrer Höhe (√3) und Breite (1) die Quadratwurzeln aller heiligen Verhältnisse hervorgehen.',
      meditation:
          'Atme tief in die Mandelform zwischen den Kreisen. Stell dir vor: linker Kreis = du, rechter Kreis = die Welt, Schnittfläche = Begegnung. Halte den Blick weich.',
      element: 'Wasser',
    ),
    _StageInfo(
      name: 'Seed of Life',
      tagline: 'Sieben Tage der Schöpfung',
      symbol: '✸',
      mythos:
          'Aus der Vesica Piscis entstehen durch Rotation um den Mittelpunkt 6 weitere identische Kreise — die Saat des Lebens. In der Genesis sind das die 7 Schöpfungstage (1 Zentrum + 6 Tage). In Sumer und Ägypten ist sie das älteste Symbol für das Universum als Ganzes — die Matrix aus der alle Formen entstehen.',
      meditation:
          'Zähle beim Atmen jeden der 6 Kreise einzeln. Jeder ist ein Tag, ein Aspekt, ein Bewusstseinszustand. Im siebten — dem Zentrum — bist du.',
      element: 'Äther',
    ),
    _StageInfo(
      name: 'Egg of Life',
      tagline: 'Embryo der Realität',
      symbol: '◐',
      mythos:
          'Der Egg of Life ist die dreidimensionale Erweiterung der Saat: 8 Kugeln wie in den ersten Zellteilungen eines Embryos. Drunvalo Melchizedek beschreibt es als die geometrische Struktur die ein menschlicher Embryo in den ersten 8 Zellteilungen einnimmt — die "Lebensblaupause" jeder DNA.',
      meditation:
          'Lege die Hand aufs Herz. Spüre den ursprünglichen Embryo-Impuls — die erste Teilung die du je vollzogen hast. Aus 1 wurde 2, aus 2 wurde 4, aus 4 wurde 8.',
      element: 'Erde',
    ),
    _StageInfo(
      name: 'Flower of Life',
      tagline: 'Blume aller Möglichkeiten',
      symbol: '❀',
      mythos:
          'Mit 19 Kreisen erblüht die Saat zur klassischen Blume des Lebens — in den Tempeln von Abydos in Ägypten in Stein graviert (ohne Werkzeug-Spuren!), bei Leonardo da Vinci als geometrische Studie, in Buddhistischen Tempeln in China, in indischen Vedanta-Texten. Sie enthält ALLE platonischen Körper, das goldene Verhältnis und die Vesica-Schnitte aller Hauptgeometrien.',
      meditation:
          'Lass den Blick auf das Zentrum fallen, ohne zu fokussieren. Periphere Wahrnehmung. Nach 30 Sekunden beginnt das Muster zu pulsieren — das ist nicht Einbildung sondern die Reaktion der Retina auf die perfekte Symmetrie.',
      element: 'Licht',
    ),
    _StageInfo(
      name: 'Fruit of Life',
      tagline: 'Dreizehn Aspekte der Schöpfung',
      symbol: '❉',
      mythos:
          'Wenn man nur die 13 zentralen Kreise der Flower of Life isoliert, erscheint die Frucht des Lebens. Sie ist der Schlüssel zu Metatron\'s Cube — die 13 Punkte enthalten alle Information aller platonischen Körper. In der jüdischen Kabbala entspricht das den 13 Aspekten des Schöpfers, in der Sufi-Tradition den 13 Stationen des Geistes.',
      meditation:
          'Zähle die 13 Kreise. Frage dich bei jedem: Welcher Lebensbereich ist das? Familie, Arbeit, Geist, Körper, Beziehung… 13 Säulen tragen dein Leben.',
      element: 'Geist',
    ),
    _StageInfo(
      name: 'Metatron\'s Cube',
      tagline: 'Bauplan der platonischen Körper',
      symbol: '✦',
      mythos:
          'Verbindet man jeden der 13 Zentren der Frucht des Lebens mit jedem anderen — entsteht Metatron\'s Würfel: das Diagramm das ALLE 5 platonischen Körper (Tetraeder, Hexaeder, Oktaeder, Dodekaeder, Ikosaeder) gleichzeitig enthält. Der Erzengel Metatron schreibt nach jüdischer Tradition die Akasha-Chronik mit diesem Werkzeug. Es ist die geometrische Sprache mit der die Realität "berechnet" wird.',
      meditation:
          'Atme die 5 Elemente: Tetraeder = Feuer, Hexaeder = Erde, Oktaeder = Luft, Dodekaeder = Äther/Universum, Ikosaeder = Wasser. Jeder Zug zeichnet eine andere Form ein.',
      element: 'Alles',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
    _revealCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _ambientCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _replayReveal();
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _revealCtrl.dispose();
    _ambientCtrl.dispose();
    super.dispose();
  }

  void _replayReveal() {
    _revealCtrl.forward(from: 0);
  }

  void _setStage(int s) {
    if (s < 0 || s > 5) return;
    HapticFeedback.selectionClick();
    setState(() => _stage = s);
    _replayReveal();
  }

  void _showInfo() {
    final info = _stages[_stage];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0E0823),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 32),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: Text(info.symbol,
                  style: const TextStyle(fontSize: 70)),
            ),
            const SizedBox(height: 8),
            Center(
              child: ShaderMask(
                shaderCallback: (r) => const LinearGradient(
                  colors: [_gold, _accent],
                ).createShader(r),
                child: Text(
                  info.name.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
              ),
            ),
            Center(
              child: Text(info.tagline,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                      fontStyle: FontStyle.italic)),
            ),
            const SizedBox(height: 22),
            _chipRow([
              '🜂 ${info.element}',
              'Stufe ${_stage + 1}/6',
              info.name == 'Metatron\'s Cube' ? '★ Vollendung' : '↑ Weiter',
            ]),
            const SizedBox(height: 22),
            _sectionLabel('📜 MYTHOS'),
            const SizedBox(height: 8),
            SelectableText(info.mythos,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.6)),
            const SizedBox(height: 22),
            _sectionLabel('🧘 MEDITATION'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _accent.withValues(alpha: 0.3)),
              ),
              child: SelectableText(info.meditation,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.6,
                      fontStyle: FontStyle.italic)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chipRow(List<String> chips) => Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: chips
            .map((c) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _primary.withValues(alpha: 0.4)),
                  ),
                  child: Text(c,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ))
            .toList(),
      );

  Widget _sectionLabel(String t) => Text(t,
      style: const TextStyle(
          color: _gold, fontSize: 11, letterSpacing: 3, fontWeight: FontWeight.w700));

  Future<void> _saveSnapshot() async {
    final info = _stages[_stage];
    final username = UnifiedStorageService().getUsername('energie');
    final userId =
        await UnifiedStorageService().getCurrentUserId() ?? 'anonym';
    final saved = await SpiritReadingService.instance.save(
      userId: userId,
      username: username,
      tool: 'geometry',
      summary: '${info.symbol} ${info.name}',
      result: {
        'stage': _stage,
        'stage_name': info.name,
        'center_x': _center.dx,
        'center_y': _center.dy,
        'radius': _radius,
        'rotation': _rotation,
        'element': info.element,
      },
    );
    if (!mounted) return;
    final ok = saved != null;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? '✨ ${info.name} im Akasha-Tagebuch gespeichert'
          : '⚠️ Speichern fehlgeschlagen — versuch\'s erneut'),
      backgroundColor: ok ? _primary : Colors.redAccent,
      duration: const Duration(seconds: 3),
    ));
  }

  void _toggleMeditation() {
    HapticFeedback.mediumImpact();
    setState(() => _isMeditation = !_isMeditation);
  }

  void _handleCanvasTap(TapDownDetails details, Size canvasSize) {
    HapticFeedback.selectionClick();
    setState(() {
      _center = Offset(
        (details.localPosition.dx / canvasSize.width).clamp(0.15, 0.85),
        (details.localPosition.dy / canvasSize.height).clamp(0.15, 0.85),
      );
    });
  }

  void _handleCanvasPan(DragUpdateDetails details, Size canvasSize) {
    final delta = details.delta.dx + details.delta.dy;
    setState(() {
      _radius = (_radius + delta / 1200).clamp(0.05, 0.32);
    });
  }

  void _handleLongPress() {
    HapticFeedback.heavyImpact();
    setState(() {
      _rotation += math.pi / 6; // 30°
    });
  }

  @override
  Widget build(BuildContext context) {
    final info = _stages[_stage];

    return Scaffold(
      backgroundColor: _bg,
      extendBodyBehindAppBar: true,
      appBar: WBGlassAppBar(
        world: WBWorld.energie,
        titleWidget: ShaderMask(
          shaderCallback: (r) => const LinearGradient(
            colors: [_gold, _primary, _accent],
          ).createShader(r),
          child: const Text(
            'GEOMETRIE-KONSTRUKTOR',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: Colors.white),
            tooltip: 'Bedeutung',
            onPressed: _showInfo,
          ),
          IconButton(
            icon: Icon(_isMeditation ? Icons.self_improvement_rounded : Icons.brightness_4_rounded,
                color: _gold),
            tooltip: _isMeditation ? 'Konstruktion zeigen' : 'Meditations-Modus',
            onPressed: _toggleMeditation,
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Layer 1: Radial-Nebula-BG
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(_center.dx * 2 - 1, _center.dy * 2 - 1),
                radius: 1.4,
                colors: [
                  _accent.withValues(alpha: 0.25),
                  const Color(0xFF1A0833).withValues(alpha: 0.5),
                  _bg,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // Layer 2: CineOrbs hinter dem Canvas (subtil)
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _ambientCtrl,
              builder: (_, __) => CustomPaint(
                painter: _CineOrbsPainter(_ambientCtrl.value),
                size: Size.infinite,
              ),
            ),
          ),

          // Layer 3: Ambient particles
          const IgnorePointer(child: WBAmbientParticles(world: WBWorld.energie, count: 36)),

          // Layer 4: Interaktiver Canvas
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 8),
                // Tagline-Karte
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          children: [
                            Text(info.symbol,
                                style: const TextStyle(fontSize: 28)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(info.name,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5)),
                                  Text(info.tagline,
                                      style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.65),
                                          fontSize: 11,
                                          fontStyle: FontStyle.italic)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _gold.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _gold.withValues(alpha: 0.4)),
                              ),
                              child: Text('${_stage + 1}/6',
                                  style: const TextStyle(
                                      color: _gold,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Canvas (Square)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: LayoutBuilder(
                          builder: (_, constraints) {
                            final size = Size(constraints.maxWidth, constraints.maxHeight);
                            return GestureDetector(
                              onTapDown: (d) => _handleCanvasTap(d, size),
                              onPanUpdate: (d) => _handleCanvasPan(d, size),
                              onLongPress: _handleLongPress,
                              child: Stack(children: [
                                // Glassmorpher Hintergrund des Canvases
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: _primary.withValues(alpha: 0.3), width: 1.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _accent.withValues(alpha: 0.18),
                                        blurRadius: 30,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                                // Geometrie selbst
                                AnimatedBuilder(
                                  animation: Listenable.merge([_glowCtrl, _revealCtrl]),
                                  builder: (_, __) => CustomPaint(
                                    painter: _SacredGeometryPainter(
                                      stage: _stage,
                                      center: _center,
                                      radius: _radius,
                                      rotation: _rotation,
                                      reveal: _revealCtrl.value,
                                      glow: _glowCtrl.value,
                                      meditation: _isMeditation,
                                      primary: _primary,
                                      accent: _accent,
                                      gold: _gold,
                                    ),
                                    size: size,
                                  ),
                                ),
                              ]),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                // Stage-Stepper + Aktionen
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: Column(
                          children: [
                            // Stage-Auswahl als horizontale Pills
                            SizedBox(
                              height: 38,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _stages.length,
                                itemBuilder: (_, i) {
                                  final sel = i == _stage;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: GestureDetector(
                                      onTap: () => _setStage(i),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 250),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          gradient: sel
                                              ? LinearGradient(
                                                  colors: [_primary, _accent])
                                              : null,
                                          color: sel ? null : Colors.white.withValues(alpha: 0.05),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                              color: sel
                                                  ? Colors.transparent
                                                  : Colors.white12),
                                        ),
                                        child: Row(children: [
                                          Text(_stages[i].symbol,
                                              style: const TextStyle(fontSize: 14)),
                                          const SizedBox(width: 6),
                                          Text(_stages[i].name,
                                              style: TextStyle(
                                                  color: sel ? Colors.white : Colors.white60,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.5)),
                                        ]),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Tap = verschieben · Pan = skalieren · Long-Press = rotieren',
                              style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 10,
                                  letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _replayReveal,
                                    icon: const Icon(Icons.replay_rounded, size: 16),
                                    label: const Text('Animation'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white70,
                                      side: BorderSide(color: _primary.withValues(alpha: 0.5)),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _saveSnapshot,
                                    icon: const Icon(Icons.bookmark_added_rounded, size: 16),
                                    label: const Text('Speichern'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _accent,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Layer 5: Vignette
          const IgnorePointer(child: WBVignette()),
        ],
      ),
    );
  }
}

class _StageInfo {
  final String name;
  final String tagline;
  final String symbol;
  final String mythos;
  final String meditation;
  final String element;
  const _StageInfo({
    required this.name,
    required this.tagline,
    required this.symbol,
    required this.mythos,
    required this.meditation,
    required this.element,
  });
}

// ── PAINTER: Sacred Geometry ────────────────────────────────────────────────
class _SacredGeometryPainter extends CustomPainter {
  final int stage;
  final Offset center;
  final double radius; // normiert
  final double rotation;
  final double reveal; // 0..1
  final double glow; // 0..1 für puls
  final bool meditation;
  final Color primary, accent, gold;

  _SacredGeometryPainter({
    required this.stage,
    required this.center,
    required this.radius,
    required this.rotation,
    required this.reveal,
    required this.glow,
    required this.meditation,
    required this.primary,
    required this.accent,
    required this.gold,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(center.dx * size.width, center.dy * size.height);
    final r = radius * math.min(size.width, size.height);

    // Sammle alle Zentren für die aktuelle Stufe
    final centers = _collectCenters(c, r);

    // Painter-Settings
    final glowAlpha = (0.5 + 0.5 * glow).clamp(0.0, 1.0);
    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = primary.withValues(alpha: 0.85 * glowAlpha);
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
      ..color = accent.withValues(alpha: 0.35 * glowAlpha);

    // Berechne wie viele Kreise gerade gemalt werden sollen (Stroke-Reveal-Animation)
    final visibleCount = (centers.length * reveal).ceil();

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(rotation);
    canvas.translate(-c.dx, -c.dy);

    // Stage 0..4: Kreise zeichnen
    for (int i = 0; i < visibleCount && i < centers.length; i++) {
      canvas.drawCircle(centers[i], r, glowPaint);
      canvas.drawCircle(centers[i], r, basePaint);
    }

    // Stage 5: Metatron's Cube — Linien zwischen allen Zentren
    if (stage == 5 && reveal > 0.4) {
      final lineProgress = ((reveal - 0.4) / 0.6).clamp(0.0, 1.0);
      final connections = <Offset>[];
      for (int i = 0; i < centers.length; i++) {
        for (int j = i + 1; j < centers.length; j++) {
          connections.add(centers[i]);
          connections.add(centers[j]);
        }
      }
      final lineCount = (connections.length / 2 * lineProgress).floor() * 2;
      final linePaint = Paint()
        ..strokeWidth = 1.0
        ..color = gold.withValues(alpha: 0.45 * glowAlpha);
      final lineGlow = Paint()
        ..strokeWidth = 3.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
        ..color = gold.withValues(alpha: 0.22 * glowAlpha);
      for (int i = 0; i < lineCount; i += 2) {
        if (i + 1 < connections.length) {
          canvas.drawLine(connections[i], connections[i + 1], lineGlow);
          canvas.drawLine(connections[i], connections[i + 1], linePaint);
        }
      }
    }

    // Zentrale Punkte als kleine Glow-Dots
    if (!meditation) {
      final dotPaint = Paint()..color = gold.withValues(alpha: 0.9 * glowAlpha);
      final dotGlow = Paint()
        ..color = gold.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      for (int i = 0; i < visibleCount && i < centers.length; i++) {
        canvas.drawCircle(centers[i], 3, dotGlow);
        canvas.drawCircle(centers[i], 2, dotPaint);
      }
    }

    canvas.restore();
  }

  // Liefert die Zentren aller Kreise für die aktuelle Stufe.
  // Reihenfolge ist die Construction-Order (für Stroke-Reveal-Animation).
  List<Offset> _collectCenters(Offset c, double r) {
    final out = <Offset>[c];

    if (stage == 0) {
      // Vesica Piscis: 1 zentraler + 1 verschoben
      out.add(Offset(c.dx + r, c.dy));
    } else if (stage >= 1) {
      // Seed of Life (und höher): zentraler Kreis + 6 ringsherum auf Hexagon-Positionen
      for (int i = 0; i < 6; i++) {
        final angle = i * math.pi / 3;
        out.add(Offset(c.dx + r * math.cos(angle), c.dy + r * math.sin(angle)));
      }
    }
    if (stage == 2) {
      // Egg: 8 Kreise (1 + 7)
      out.add(Offset(c.dx, c.dy + r * 2));
    }
    if (stage >= 3) {
      // Flower of Life: weitere 12 äußere Kreise (insgesamt 19)
      for (int i = 0; i < 6; i++) {
        final angle = i * math.pi / 3 + math.pi / 6;
        out.add(Offset(
          c.dx + r * math.sqrt(3) * math.cos(angle),
          c.dy + r * math.sqrt(3) * math.sin(angle),
        ));
      }
      for (int i = 0; i < 6; i++) {
        final angle = i * math.pi / 3;
        out.add(Offset(
          c.dx + r * 2 * math.cos(angle),
          c.dy + r * 2 * math.sin(angle),
        ));
      }
    }
    if (stage >= 4) {
      // Fruit of Life: nur die 13 zentralen behalten (entferne die 6 äußersten und Vesica-Partner)
      // Reset: 1 zentral + 6 inner + 6 hex-pos = 13
      out.clear();
      out.add(c);
      for (int i = 0; i < 6; i++) {
        final angle = i * math.pi / 3;
        out.add(Offset(c.dx + r * math.cos(angle), c.dy + r * math.sin(angle)));
      }
      for (int i = 0; i < 6; i++) {
        final angle = i * math.pi / 3;
        out.add(Offset(
          c.dx + r * 2 * math.cos(angle),
          c.dy + r * 2 * math.sin(angle),
        ));
      }
    }
    // stage 5 nutzt dieselben 13 Zentren, nur mit Linien verbunden
    return out;
  }

  @override
  bool shouldRepaint(_SacredGeometryPainter old) =>
      old.stage != stage ||
      old.center != center ||
      old.radius != radius ||
      old.rotation != rotation ||
      old.reveal != reveal ||
      old.glow != glow ||
      old.meditation != meditation;
}

// ── PAINTER: Subtle CineOrbs ────────────────────────────────────────────────
class _CineOrbsPainter extends CustomPainter {
  final double t;
  _CineOrbsPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    _drawOrb(canvas,
        Offset(size.width * 0.2, size.height * (0.3 + math.sin(t * 2 * math.pi) * 0.05)),
        90, const Color(0xFF00BCD4));
    _drawOrb(canvas,
        Offset(size.width * 0.85, size.height * (0.55 + math.cos(t * 2 * math.pi) * 0.05)),
        110, const Color(0xFFAB47BC));
    _drawOrb(canvas,
        Offset(size.width * 0.5, size.height * (0.9 + math.sin(t * math.pi) * 0.04)),
        70, const Color(0xFFFFD54F));
  }

  void _drawOrb(Canvas canvas, Offset pos, double r, Color color) {
    final p = Paint()
      ..color = color.withValues(alpha: 0.08)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.4);
    canvas.drawCircle(pos, r, p);
  }

  @override
  bool shouldRepaint(_CineOrbsPainter old) => old.t != t;
}
