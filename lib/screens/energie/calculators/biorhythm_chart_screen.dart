// 📊 BIORHYTHMUS · 90-Tage-Chart mit Mond + Astro-Korrelation
//
// 6 Zyklen (3 klassisch + 3 erweitert):
// • Physical 23d · Emotional 28d · Intellectual 33d
// • Intuition 38d · Aesthetic 43d · Spiritual 53d
//
// Math: sin(2π · daysSinceBirth / cycleLength)
//
// 90-Tage Forecast als Line-Chart mit Critical-Days-Markern (Null-Durchgänge).
// Heute-Wert prominent mit Energie-Empfehlung (Was tun heute?).
// Mond-Phase als zusätzliches Overlay (subtile Welle).

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/storage/unified_storage_service.dart';
import '../../../services/spirit_reading_service.dart';
import '../../../theme/wb_cinematic_tokens.dart';
import '../../../widgets/cinematic/wb_ambient_particles.dart';
import '../../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../../widgets/cinematic/wb_vignette.dart';

class BiorhythmChartScreen extends StatefulWidget {
  const BiorhythmChartScreen({super.key});

  @override
  State<BiorhythmChartScreen> createState() => _BiorhythmChartScreenState();
}

class _BiorhythmChartScreenState extends State<BiorhythmChartScreen>
    with TickerProviderStateMixin {
  static const Color _bgDark = Color(0xFF030814);

  /// Theme-aware background. Light-Mode liefert helle `context.wb.bgVoid`,
  /// Dark-Mode behält den Original-Ton.
  Color _bg(BuildContext context) {
    final wb = Theme.of(context).extension<WBCinematic>();
    return wb?.bgVoid ?? _bgDark;
  }
  static const Color _primary = Color(0xFF26C6DA);
  static const Color _accent = Color(0xFFFF6F00);
  static const Color _gold = Color(0xFFFFD54F);

  DateTime _birthDate = DateTime(1990, 6, 21);
  int _windowDays = 90;
  int _focusOffset = 0; // 0 = heute, +i = i Tage in der Zukunft
  late final AnimationController _drawCtrl;
  late final AnimationController _ambientCtrl;

  static const List<_Cycle> _cycles = [
    _Cycle('physical',     'Physisch',     23, Color(0xFFE53935), '💪'),
    _Cycle('emotional',    'Emotional',    28, Color(0xFFEC407A), '💖'),
    _Cycle('intellectual', 'Intellektuell',33, Color(0xFF42A5F5), '🧠'),
    _Cycle('intuitive',    'Intuition',    38, Color(0xFF7C4DFF), '🌌'),
    _Cycle('aesthetic',    'Ästhetisch',   43, Color(0xFFFFB74D), '🎨'),
    _Cycle('spiritual',    'Spirituell',   53, Color(0xFF66BB6A), '✨'),
  ];

  Set<String> _enabled = {'physical', 'emotional', 'intellectual'};

  @override
  void initState() {
    super.initState();
    _drawCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _ambientCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    _drawCtrl.forward();
  }

  @override
  void dispose() {
    _drawCtrl.dispose();
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
          colorScheme: const ColorScheme.dark(primary: _primary, onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (d == null) return;
    setState(() => _birthDate = d);
    _drawCtrl.forward(from: 0);
  }

  void _toggleCycle(String code) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_enabled.contains(code)) {
        if (_enabled.length > 1) _enabled.remove(code);
      } else {
        _enabled.add(code);
      }
    });
  }

  double _cycleValue(int cycleLength, int dayOffset) {
    final daysSinceBirth = DateTime.now()
        .add(Duration(days: dayOffset))
        .difference(_birthDate)
        .inDays
        .toDouble();
    return math.sin(2 * math.pi * daysSinceBirth / cycleLength);
  }

  double _moonPhase(int dayOffset) {
    // -1 (Neumond) bis +1 (Vollmond)
    final t = DateTime.now().add(Duration(days: dayOffset));
    final ref = DateTime(2000, 1, 6, 18, 14);
    final days = t.difference(ref).inSeconds / 86400.0;
    final phase = (days / 29.530588853) % 1.0;
    return math.sin(phase * 2 * math.pi);
  }

  String _phaseLabel(int dayOffset) {
    final t = DateTime.now().add(Duration(days: dayOffset));
    final ref = DateTime(2000, 1, 6, 18, 14);
    final days = t.difference(ref).inSeconds / 86400.0;
    final phase = (days / 29.530588853) % 1.0;
    if (phase < 0.05 || phase > 0.95) return '🌑 Neumond';
    if (phase < 0.25) return '🌒 zunehmend';
    if (phase < 0.30) return '🌓 1. Viertel';
    if (phase < 0.5) return '🌔 zunehmend voll';
    if (phase < 0.55) return '🌕 Vollmond';
    if (phase < 0.75) return '🌖 abnehmend';
    if (phase < 0.80) return '🌗 letztes Viertel';
    return '🌘 abnehmend';
  }

  Future<void> _save() async {
    final username = UnifiedStorageService().getUsername('energie');
    final userId = await UnifiedStorageService().getCurrentUserId() ?? 'anonym';
    final today = <String, double>{};
    for (final c in _cycles) {
      today[c.code] = _cycleValue(c.length, 0);
    }
    final saved = await SpiritReadingService.instance.save(
      userId: userId,
      username: username,
      tool: 'biorhythm',
      summary: '📊 ${_fmtDate(_birthDate)} → heute',
      result: {
        'birth_date': _birthDate.toIso8601String(),
        'today': today,
        'moon': _moonPhase(0),
      },
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(saved != null ? '📊 Biorhythmus gespeichert' : '⚠️ Speichern fehlgeschlagen'),
      backgroundColor: _primary,
    ));
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2,'0')}.${d.month.toString().padLeft(2,'0')}.${d.year}';

  String _energyAdvice() {
    final phys = _cycleValue(23, _focusOffset);
    final emo = _cycleValue(28, _focusOffset);
    final intel = _cycleValue(33, _focusOffset);
    final avg = (phys + emo + intel) / 3;
    if (avg > 0.6) return '🚀 Hoch-Energie · Großes anpacken, körperlich fordernd, kreative Sprünge.';
    if (avg > 0.2) return '⚡ Solider Tag · Routinen, Verabredungen, kleinere Schritte.';
    if (avg > -0.2) return '🌿 Übergang · Geduldig sein, beobachten, nicht überfordern.';
    if (avg > -0.6) return '🛌 Niedrige Phase · Erholung, lesen, planen, nicht performen.';
    return '🌑 Tief · Tag der Stille. Was darf integriert werden?';
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
            colors: [_gold, _primary, _accent],
          ).createShader(r),
          child: const Text('BIORHYTHMUS',
              style: TextStyle(color: Colors.white, fontSize: 14,
                  fontWeight: FontWeight.w900, letterSpacing: 3)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_added_rounded, color: _gold),
            tooltip: 'Heute speichern',
            onPressed: _save,
          ),
        ],
      ),
      body: Stack(fit: StackFit.expand, children: [
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.3),
              radius: 1.5,
              colors: [Color(0x550D2F4E), Color(0x33060F1A), _bgDark],
            ),
          ),
        ),
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _ambientCtrl,
            builder: (_, __) => CustomPaint(
              painter: _BioOrbsPainter(_ambientCtrl.value),
              size: Size.infinite,
            ),
          ),
        ),
        const IgnorePointer(child: WBAmbientParticles(world: WBWorld.energie, count: 30)),
        SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
            children: [
              _birthDateCard(),
              const SizedBox(height: 12),
              _todayCard(),
              const SizedBox(height: 12),
              _cycleToggleRow(),
              const SizedBox(height: 12),
              _chartCard(),
              const SizedBox(height: 12),
              _criticalDaysCard(),
            ],
          ),
        ),
        const IgnorePointer(child: WBVignette()),
      ]),
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
          child: GestureDetector(
            onTap: _pickDate,
            child: Row(children: [
              Icon(Icons.cake_rounded, color: _gold),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('GEBURTSDATUM',
                      style: TextStyle(color: _gold, fontSize: 9, letterSpacing: 2, fontWeight: FontWeight.w700)),
                  Text(_fmtDate(_birthDate),
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  Text('${DateTime.now().difference(_birthDate).inDays} Tage gelebt',
                      style: const TextStyle(color: Colors.white54, fontSize: 11)),
                ]),
              ),
              Icon(Icons.edit_calendar_rounded, color: _primary, size: 20),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _todayCard() {
    final offset = _focusOffset;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_primary.withValues(alpha: 0.2), _accent.withValues(alpha: 0.08)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _primary.withValues(alpha: 0.3)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(
                offset == 0
                    ? 'HEUTE'
                    : (offset > 0 ? '+$offset TAGE' : '${offset} TAGE'),
                style: const TextStyle(color: _gold, fontSize: 10, letterSpacing: 3, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(_phaseLabel(offset),
                  style: const TextStyle(color: Colors.white70, fontSize: 11)),
            ]),
            const SizedBox(height: 10),
            ..._cycles.where((c) => _enabled.contains(c.code)).map((c) {
              final v = _cycleValue(c.length, offset);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(children: [
                  Text(c.emoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  SizedBox(width: 90,
                      child: Text(c.label,
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))),
                  Expanded(
                    child: SizedBox(
                      height: 10,
                      child: Stack(children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: Container(width: 1, height: 10, color: Colors.white24),
                        ),
                        // Wert-Balken
                        FractionallySizedBox(
                          alignment: v > 0 ? Alignment.centerLeft : Alignment.centerRight,
                          widthFactor: v.abs() * 0.5,
                          child: Align(
                            alignment: v > 0 ? Alignment.centerLeft : Alignment.centerRight,
                            child: Container(
                              margin: EdgeInsets.only(left: v > 0 ? MediaQuery.of(context).size.width * 0.3 : 0),
                            ),
                          ),
                        ),
                        LayoutBuilder(builder: (_, c2) {
                          final mid = c2.maxWidth / 2;
                          final w = (c2.maxWidth / 2) * v.abs();
                          return Stack(children: [
                            Positioned(
                              left: v > 0 ? mid : mid - w,
                              top: 1,
                              child: Container(
                                width: w, height: 8,
                                decoration: BoxDecoration(
                                  color: c.color,
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [BoxShadow(color: c.color.withValues(alpha: 0.5), blurRadius: 6)],
                                ),
                              ),
                            ),
                          ]);
                        }),
                      ]),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 44,
                    child: Text('${(v * 100).round()}%',
                        textAlign: TextAlign.end,
                        style: TextStyle(color: c.color, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ]),
              );
            }),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(_energyAdvice(),
                  style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.5)),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _cycleToggleRow() {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _cycles.length,
        itemBuilder: (_, i) {
          final c = _cycles[i];
          final sel = _enabled.contains(c.code);
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => _toggleCycle(c.code),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: sel ? c.color.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: sel ? c.color : Colors.transparent),
                ),
                child: Row(children: [
                  Text(c.emoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(c.label,
                      style: TextStyle(color: sel ? Colors.white : Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 3),
                  Text('${c.length}d',
                      style: const TextStyle(color: Colors.white38, fontSize: 9)),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _chartCard() {
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
            Row(children: [
              const Text('$_kChartTitle '),
              const Spacer(),
              ..._windowOptions.map((w) {
                final sel = w == _windowDays;
                return Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: GestureDetector(
                    onTap: () => setState(() => _windowDays = w),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: sel ? _primary.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: sel ? _primary : Colors.transparent),
                      ),
                      child: Text('${w}d',
                          style: TextStyle(color: sel ? Colors.white : Colors.white60, fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                  ),
                );
              }),
            ]),
            const SizedBox(height: 8),
            GestureDetector(
              onPanUpdate: (d) {
                final dx = d.delta.dx;
                final maxOffset = _windowDays ~/ 2;
                setState(() {
                  _focusOffset = (_focusOffset - (dx / 4).round()).clamp(-maxOffset, maxOffset);
                });
              },
              child: AspectRatio(
                aspectRatio: 1.7,
                child: AnimatedBuilder(
                  animation: _drawCtrl,
                  builder: (_, __) => CustomPaint(
                    painter: _BiorhythmChartPainter(
                      birthDate: _birthDate,
                      cycles: _cycles.where((c) => _enabled.contains(c.code)).toList(),
                      windowDays: _windowDays,
                      focusOffset: _focusOffset,
                      reveal: _drawCtrl.value,
                      gold: _gold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Wisch links/rechts um zu navigieren · Heute = Mitte',
              style: const TextStyle(color: Colors.white38, fontSize: 10, fontStyle: FontStyle.italic),
            ),
          ]),
        ),
      ),
    );
  }

  static const _kChartTitle = 'VERLAUF';
  static const _windowOptions = [30, 90, 180];

  Widget _criticalDaysCard() {
    // Finde Critical-Days (Null-Durchgänge) der aktivierten Zyklen in den nächsten 30 Tagen
    final criticals = <_CriticalDay>[];
    for (int d = 1; d <= 30; d++) {
      for (final c in _cycles.where((c) => _enabled.contains(c.code))) {
        final v0 = _cycleValue(c.length, d - 1);
        final v1 = _cycleValue(c.length, d);
        if (v0.sign != v1.sign) {
          criticals.add(_CriticalDay(d, c));
        }
      }
    }
    criticals.sort((a, b) => a.daysFromNow.compareTo(b.daysFromNow));
    final top = criticals.take(6).toList();
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
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('KRITISCHE TAGE · NÄCHSTE 30 TAGE',
                style: TextStyle(color: _gold, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text(
                'Null-Durchgänge der Zyklen = volatil. Wichtige Entscheidungen lieber drum-herum.',
                style: TextStyle(color: Colors.white54, fontSize: 10)),
            const SizedBox(height: 8),
            if (top.isEmpty)
              const Text('Keine kritischen Tage in den nächsten 30 Tagen.',
                  style: TextStyle(color: Colors.white60, fontSize: 12))
            else
              ...top.map((cd) {
                final date = DateTime.now().add(Duration(days: cd.daysFromNow));
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(children: [
                    Text(cd.cycle.emoji, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    SizedBox(width: 80,
                        child: Text(cd.cycle.label,
                            style: TextStyle(color: cd.cycle.color, fontSize: 12, fontWeight: FontWeight.w600))),
                    Expanded(
                      child: Text('${date.day}.${date.month}.',
                          style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ),
                    Text('in ${cd.daysFromNow}d',
                        style: const TextStyle(color: Colors.white54, fontSize: 11)),
                  ]),
                );
              }),
          ]),
        ),
      ),
    );
  }
}

class _Cycle {
  final String code;
  final String label;
  final int length;
  final Color color;
  final String emoji;
  const _Cycle(this.code, this.label, this.length, this.color, this.emoji);
}

class _CriticalDay {
  final int daysFromNow;
  final _Cycle cycle;
  const _CriticalDay(this.daysFromNow, this.cycle);
}

// ── PAINTER: Biorhythmus Line-Chart ──────────────────────────────────────────
class _BiorhythmChartPainter extends CustomPainter {
  final DateTime birthDate;
  final List<_Cycle> cycles;
  final int windowDays;
  final int focusOffset;
  final double reveal; // 0..1
  final Color gold;

  _BiorhythmChartPainter({
    required this.birthDate,
    required this.cycles,
    required this.windowDays,
    required this.focusOffset,
    required this.reveal,
    required this.gold,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final padX = 16.0;
    final padY = 18.0;
    final plotW = w - 2 * padX;
    final plotH = h - 2 * padY;
    final centerY = padY + plotH / 2;

    // Achsen
    final axisPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(padX, centerY), Offset(padX + plotW, centerY), axisPaint);
    // 50% lines
    canvas.drawLine(Offset(padX, padY + plotH * 0.25),
        Offset(padX + plotW, padY + plotH * 0.25),
        Paint()..color = Colors.white.withValues(alpha: 0.07));
    canvas.drawLine(Offset(padX, padY + plotH * 0.75),
        Offset(padX + plotW, padY + plotH * 0.75),
        Paint()..color = Colors.white.withValues(alpha: 0.07));

    // Heute-Linie (Mitte des Fensters)
    final today = focusOffset;
    final halfWindow = windowDays ~/ 2;
    final startOffset = today - halfWindow;
    final endOffset = today + halfWindow;
    final todayX = padX + ((today - startOffset) / (endOffset - startOffset)) * plotW;
    canvas.drawLine(
      Offset(todayX, padY),
      Offset(todayX, padY + plotH),
      Paint()..color = gold.withValues(alpha: 0.5)..strokeWidth = 1.5,
    );

    // Heute-Label
    final tp = TextPainter(
      text: TextSpan(text: 'heute', style: TextStyle(color: gold, fontSize: 9, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(todayX - tp.width / 2, padY - 14));

    // Linien für jeden Zyklus
    final visiblePoints = (windowDays + 1).clamp(2, 600);
    final maxVisible = (visiblePoints * reveal).ceil();
    for (final c in cycles) {
      final path = Path();
      final glowPath = Path();
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = c.color;
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5)
        ..color = c.color.withValues(alpha: 0.4);

      for (int i = 0; i < maxVisible && i <= windowDays; i++) {
        final dayOffset = startOffset + i;
        final daysSinceBirth = DateTime.now()
            .add(Duration(days: dayOffset))
            .difference(birthDate)
            .inDays
            .toDouble();
        final v = math.sin(2 * math.pi * daysSinceBirth / c.length);
        final x = padX + (i / windowDays) * plotW;
        final y = centerY - (v * plotH / 2 * 0.9);
        if (i == 0) {
          path.moveTo(x, y);
          glowPath.moveTo(x, y);
        } else {
          path.lineTo(x, y);
          glowPath.lineTo(x, y);
        }
      }
      canvas.drawPath(glowPath, glowPaint);
      canvas.drawPath(path, paint);

      // Critical-Days (Null-Durchgänge) als kleine Punkte
      for (int i = 1; i < maxVisible && i <= windowDays; i++) {
        final dayOffset = startOffset + i;
        final v0 = math.sin(2 * math.pi * DateTime.now().add(Duration(days: dayOffset - 1)).difference(birthDate).inDays / c.length);
        final v1 = math.sin(2 * math.pi * DateTime.now().add(Duration(days: dayOffset)).difference(birthDate).inDays / c.length);
        if (v0.sign != v1.sign) {
          final x = padX + (i / windowDays) * plotW;
          canvas.drawCircle(Offset(x, centerY), 3, Paint()..color = gold);
          canvas.drawCircle(Offset(x, centerY), 6,
              Paint()..color = gold.withValues(alpha: 0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
        }
      }
    }

    // Skala-Labels (-100, 0, +100)
    _drawScaleLabel(canvas, '+100%', padY);
    _drawScaleLabel(canvas, '0', centerY);
    _drawScaleLabel(canvas, '-100%', padY + plotH);
  }

  void _drawScaleLabel(Canvas canvas, String text, double y) {
    final ltp = TextPainter(
      text: TextSpan(text: text, style: const TextStyle(color: Colors.white38, fontSize: 8)),
      textDirection: TextDirection.ltr,
    )..layout();
    ltp.paint(canvas, Offset(2, y - ltp.height / 2));
  }

  @override
  bool shouldRepaint(_BiorhythmChartPainter old) =>
      old.birthDate != birthDate || old.windowDays != windowDays ||
      old.focusOffset != focusOffset || old.reveal != reveal ||
      old.cycles.length != cycles.length;
}

// ── PAINTER: Bio-Orbs ────────────────────────────────────────────────────────
class _BioOrbsPainter extends CustomPainter {
  final double t;
  _BioOrbsPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    _draw(canvas, Offset(size.width * 0.2, size.height * (0.3 + math.sin(t * 2 * math.pi) * 0.05)),
        100, const Color(0xFF26C6DA));
    _draw(canvas, Offset(size.width * 0.85, size.height * (0.6 + math.cos(t * 2 * math.pi) * 0.04)),
        90, const Color(0xFFFF6F00));
    _draw(canvas, Offset(size.width * 0.5, size.height * (0.92 + math.sin(t * math.pi) * 0.03)),
        70, const Color(0xFFFFD54F));
  }

  void _draw(Canvas canvas, Offset c, double r, Color color) {
    final p = Paint()
      ..color = color.withValues(alpha: 0.10)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.5);
    canvas.drawCircle(c, r, p);
  }

  @override
  bool shouldRepaint(_BioOrbsPainter old) => old.t != t;
}
