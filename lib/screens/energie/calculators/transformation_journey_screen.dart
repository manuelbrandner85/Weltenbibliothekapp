// 🦋 TRANSFORMATION-TRACKER · 5-Dimensions Daily Check-In + Streaks
//
// Tägliche Selbst-Bewertung auf 5 Dimensionen (jeweils 1-10 Slider):
// • Körper · Geist · Seele · Beziehungen · Berufung
//
// Charts:
// • 30-Tage Line-Chart pro Dimension (kombiniert)
// • Streak-Counter (aufeinanderfolgende Check-In-Tage)
// • Korrelations-Hinweise (z.B. "Körper ↑ → Geist ↑")
// • Gesamt-Score-Trend (Ø aller 5)
//
// Persistierung: SharedPreferences + spirit_readings (tool: 'transformation')

import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/storage/unified_storage_service.dart';
import '../../../services/spirit_reading_service.dart';
import '../../../theme/wb_cinematic_tokens.dart';
import '../../../widgets/cinematic/wb_ambient_particles.dart';
import '../../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../../widgets/cinematic/wb_vignette.dart';

class TransformationJourneyScreen extends StatefulWidget {
  const TransformationJourneyScreen({super.key});

  @override
  State<TransformationJourneyScreen> createState() => _TransformationJourneyScreenState();
}

class _TransformationJourneyScreenState extends State<TransformationJourneyScreen>
    with TickerProviderStateMixin {
  static const Color _bgDark = Color(0xFF080414);

  /// Theme-aware background. Light-Mode liefert helle `context.wb.bgVoid`,
  /// Dark-Mode behält den Original-Ton.
  Color _bg(BuildContext context) {
    final wb = Theme.of(context).extension<WBCinematic>();
    return wb?.bgVoid ?? _bgDark;
  }
  static const Color _primary = Color(0xFFFF7043);
  static const Color _accent = Color(0xFFAB47BC);
  static const Color _gold = Color(0xFFFFD54F);
  static const String _kvKey = 'transformation_tracker_v1';

  static const List<_Dim> _dims = [
    _Dim('body',         'Körper',        '💪', Color(0xFFE53935)),
    _Dim('mind',         'Geist',         '🧠', Color(0xFF42A5F5)),
    _Dim('soul',         'Seele',         '✨', Color(0xFF9C27B0)),
    _Dim('relations',    'Beziehungen',   '💞', Color(0xFFEC407A)),
    _Dim('purpose',      'Berufung',      '🎯', Color(0xFF66BB6A)),
  ];

  List<_Snap> _snaps = [];
  Map<String, int> _draft = {for (final d in _dims) d.code: 5};
  bool _loading = true;
  late final AnimationController _ambientCtrl;
  late final AnimationController _drawCtrl;

  @override
  void initState() {
    super.initState();
    _ambientCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    _drawCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _load();
  }

  @override
  void dispose() {
    _ambientCtrl.dispose();
    _drawCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kvKey) ?? const [];
    final out = <_Snap>[];
    for (final s in raw) {
      try { out.add(_Snap.fromJson(jsonDecode(s) as Map<String, dynamic>)); } catch (_) {}
    }
    out.sort((a, b) => b.date.compareTo(a.date));
    // Vorbelegen Draft mit letztem Snap (falls heute noch keiner)
    final today = _today();
    final hasToday = out.any((s) => s.date.substring(0, 10) == today);
    if (mounted) {
      setState(() {
        _snaps = out;
        if (!hasToday && out.isNotEmpty) {
          _draft = Map.from(out.first.values);
        }
        _loading = false;
      });
    }
    _drawCtrl.forward();
  }

  String _today() => DateTime.now().toIso8601String().substring(0, 10);

  Future<void> _save() async {
    HapticFeedback.mediumImpact();
    final today = _today();
    final snap = _Snap(
      date: '${today}T${DateTime.now().toIso8601String().substring(11)}',
      values: Map.from(_draft),
    );
    // Entferne älteren Eintrag vom gleichen Tag
    _snaps.removeWhere((s) => s.date.substring(0, 10) == today);
    _snaps.insert(0, snap);
    final prefs = await SharedPreferences.getInstance();
    final list = _snaps.take(365).map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_kvKey, list);
    // Cloud
    try {
      final username = UnifiedStorageService().getUsername('energie');
      final userId = await UnifiedStorageService().getCurrentUserId() ?? 'anonym';
      await SpiritReadingService.instance.save(
        userId: userId,
        username: username,
        tool: 'transformation',
        summary: '🦋 ${_dimensionsSummary(snap.values)}',
        result: {'snap': snap.toJson()},
      );
    } catch (_) {}
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('🦋 Check-In gespeichert · Streak $_streak'),
      backgroundColor: _primary,
    ));
  }

  String _dimensionsSummary(Map<String, int> vals) {
    final entries = vals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(2).map((e) => '${_dims.firstWhere((d) => d.code == e.key, orElse: () => _dims[0]).emoji}${e.value}').join(' ');
  }

  int get _streak {
    if (_snaps.isEmpty) return 0;
    int streak = 0;
    var checkDay = DateTime.now();
    final dayMap = <String, bool>{};
    for (final s in _snaps) {
      dayMap[s.date.substring(0, 10)] = true;
    }
    while (true) {
      final key = checkDay.toIso8601String().substring(0, 10);
      if (dayMap[key] == true) {
        streak++;
        checkDay = checkDay.subtract(const Duration(days: 1));
      } else {
        if (streak == 0) {
          // Check if yesterday — wenn ja, weiter
          checkDay = checkDay.subtract(const Duration(days: 1));
          final yKey = checkDay.toIso8601String().substring(0, 10);
          if (dayMap[yKey] == true) {
            streak = 1;
            checkDay = checkDay.subtract(const Duration(days: 1));
          } else break;
        } else break;
      }
    }
    return streak;
  }

  // Pearson-Korrelation der letzten 30 Snaps zwischen zwei Dim
  double _correlation(String a, String b) {
    final last30 = _snaps.take(30).toList();
    if (last30.length < 6) return 0;
    final xs = last30.map((s) => s.values[a]?.toDouble() ?? 0).toList();
    final ys = last30.map((s) => s.values[b]?.toDouble() ?? 0).toList();
    final mx = xs.reduce((a, b) => a + b) / xs.length;
    final my = ys.reduce((a, b) => a + b) / ys.length;
    double num = 0, dx = 0, dy = 0;
    for (int i = 0; i < xs.length; i++) {
      num += (xs[i] - mx) * (ys[i] - my);
      dx += (xs[i] - mx) * (xs[i] - mx);
      dy += (ys[i] - my) * (ys[i] - my);
    }
    if (dx == 0 || dy == 0) return 0;
    return num / math.sqrt(dx * dy);
  }

  // Top 3 Korrelationen (positiv) für Insight-Card
  List<_CorrPair> _topCorrelations() {
    final out = <_CorrPair>[];
    for (int i = 0; i < _dims.length; i++) {
      for (int j = i + 1; j < _dims.length; j++) {
        final c = _correlation(_dims[i].code, _dims[j].code);
        out.add(_CorrPair(_dims[i], _dims[j], c));
      }
    }
    out.sort((a, b) => b.value.abs().compareTo(a.value.abs()));
    return out.take(3).toList();
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
          child: const Text('TRANSFORMATION',
              style: TextStyle(color: Colors.white, fontSize: 14,
                  fontWeight: FontWeight.w900, letterSpacing: 3)),
        ),
      ),
      body: Stack(fit: StackFit.expand, children: [
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.3),
              radius: 1.5,
              colors: [Color(0x55BF360C), Color(0x33260C08), _bgDark],
            ),
          ),
        ),
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _ambientCtrl,
            builder: (_, __) => CustomPaint(
              painter: _TransOrbsPainter(_ambientCtrl.value),
              size: Size.infinite,
            ),
          ),
        ),
        const IgnorePointer(child: WBAmbientParticles(world: WBWorld.energie, count: 40)),
        SafeArea(
          child: _loading
              ? Center(child: CircularProgressIndicator(color: _primary))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
                  children: [
                    _streakRow(),
                    const SizedBox(height: 12),
                    _checkInCard(),
                    const SizedBox(height: 14),
                    _chartCard(),
                    const SizedBox(height: 12),
                    _correlationsCard(),
                  ],
                ),
        ),
        const IgnorePointer(child: WBVignette()),
      ]),
    );
  }

  Widget _streakRow() {
    final s = _streak;
    final t = _snaps.length;
    final avg = _snaps.isEmpty
        ? 0.0
        : _snaps.first.values.values.fold<int>(0, (s2, v) => s2 + v) / _dims.length;
    return Row(children: [
      _statBox('🔥 $s', 'Tag${s == 1 ? "" : "e"} Streak', _primary),
      const SizedBox(width: 8),
      _statBox('📊 $t', 'Check-Ins gesamt', _accent),
      const SizedBox(width: 8),
      _statBox('⚡ ${avg.toStringAsFixed(1)}', 'Ø heute', _gold),
    ]);
  }

  Widget _statBox(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(children: [
          Text(value,
              style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label,
              style: const TextStyle(color: Colors.white60, fontSize: 9),
              textAlign: TextAlign.center, maxLines: 2),
        ]),
      ),
    );
  }

  Widget _checkInCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [_primary.withValues(alpha: 0.18), _accent.withValues(alpha: 0.08)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('HEUTE · CHECK-IN',
                style: TextStyle(color: _gold, fontSize: 10, letterSpacing: 3, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ..._dims.map((d) {
              final v = _draft[d.code] ?? 5;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(d.emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(d.label,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: d.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: d.color.withValues(alpha: 0.5)),
                      ),
                      child: Text('$v / 10',
                          style: TextStyle(color: d.color, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ]),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: d.color,
                      inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                      thumbColor: d.color,
                      overlayColor: d.color.withValues(alpha: 0.2),
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                    ),
                    child: Slider(
                      value: v.toDouble(),
                      min: 1, max: 10,
                      divisions: 9,
                      onChanged: (val) {
                        HapticFeedback.selectionClick();
                        setState(() => _draft[d.code] = val.round());
                      },
                    ),
                  ),
                ]),
              );
            }),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_rounded, size: 16),
                label: const Text('CHECK-IN SPEICHERN',
                    style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
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

  Widget _chartCard() {
    if (_snaps.length < 2) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(children: [
              Icon(Icons.timeline_rounded, color: Colors.white.withValues(alpha: 0.3), size: 60),
              const SizedBox(height: 12),
              const Text('Noch zu wenige Check-Ins für einen Verlauf.',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 2),
              const Text('Ab dem zweiten Tag erscheint deine Linie.',
                  style: TextStyle(color: Colors.white38, fontSize: 11)),
            ]),
          ),
        ),
      );
    }
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
            const Text('VERLAUF · LETZTE 30 TAGE',
                style: TextStyle(color: _gold, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            AspectRatio(
              aspectRatio: 1.8,
              child: AnimatedBuilder(
                animation: _drawCtrl,
                builder: (_, __) => CustomPaint(
                  painter: _TransformChartPainter(
                    snaps: _snaps.take(30).toList().reversed.toList(),
                    dims: _dims,
                    reveal: _drawCtrl.value,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6, runSpacing: 4,
              alignment: WrapAlignment.center,
              children: _dims.map((d) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: d.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: d.color, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text(d.label, style: const TextStyle(color: Colors.white70, fontSize: 9)),
                ]),
              )).toList(),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _correlationsCard() {
    if (_snaps.length < 6) return const SizedBox.shrink();
    final corrs = _topCorrelations();
    if (corrs.isEmpty) return const SizedBox.shrink();
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
            const Text('KORRELATIONEN · 30 TAGE',
                style: TextStyle(color: _gold, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text(
                'Wie bewegen sich Dimensionen zusammen? +1 = im Gleichschritt, −1 = gegenläufig.',
                style: TextStyle(color: Colors.white54, fontSize: 10)),
            const SizedBox(height: 10),
            ...corrs.map((p) {
              final pos = p.value > 0;
              final color = pos ? Colors.greenAccent : Colors.redAccent;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  Text('${p.a.emoji}${p.a.label}',
                      style: TextStyle(color: p.a.color, fontSize: 12, fontWeight: FontWeight.w600)),
                  Icon(pos ? Icons.swap_horiz_rounded : Icons.swap_vert_rounded, color: color, size: 18),
                  Text('${p.b.emoji}${p.b.label}',
                      style: TextStyle(color: p.b.color, fontSize: 12, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text(p.value.toStringAsFixed(2),
                      style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
                ]),
              );
            }),
          ]),
        ),
      ),
    );
  }
}

class _Dim {
  final String code;
  final String label;
  final String emoji;
  final Color color;
  const _Dim(this.code, this.label, this.emoji, this.color);
}

class _Snap {
  final String date;
  final Map<String, int> values;
  const _Snap({required this.date, required this.values});
  Map<String, dynamic> toJson() => {'date': date, 'values': values};
  factory _Snap.fromJson(Map<String, dynamic> j) => _Snap(
        date: j['date'] as String? ?? '',
        values: ((j['values'] as Map?) ?? const {}).map((k, v) => MapEntry(k as String, (v as num).toInt())),
      );
}

class _CorrPair {
  final _Dim a;
  final _Dim b;
  final double value;
  const _CorrPair(this.a, this.b, this.value);
}

// ── PAINTER: Multi-Line-Chart ────────────────────────────────────────────────
class _TransformChartPainter extends CustomPainter {
  final List<_Snap> snaps; // chronological (oldest first)
  final List<_Dim> dims;
  final double reveal;

  _TransformChartPainter({required this.snaps, required this.dims, required this.reveal});

  @override
  void paint(Canvas canvas, Size size) {
    if (snaps.length < 2) return;
    final padX = 14.0;
    final padY = 10.0;
    final plotW = size.width - 2 * padX;
    final plotH = size.height - 2 * padY;

    // Achsen
    final axisColor = Paint()..color = Colors.white.withValues(alpha: 0.15)..strokeWidth = 1;
    canvas.drawLine(Offset(padX, padY + plotH), Offset(padX + plotW, padY + plotH), axisColor);
    // 50% line
    canvas.drawLine(Offset(padX, padY + plotH / 2),
        Offset(padX + plotW, padY + plotH / 2),
        Paint()..color = Colors.white.withValues(alpha: 0.07));

    final maxVisible = (snaps.length * reveal).ceil().clamp(2, snaps.length);

    for (final d in dims) {
      final path = Path();
      final glowPath = Path();
      for (int i = 0; i < maxVisible; i++) {
        final v = snaps[i].values[d.code]?.toDouble() ?? 5;
        final x = padX + (snaps.length == 1 ? plotW / 2 : (i / (snaps.length - 1)) * plotW);
        final y = padY + plotH - ((v - 1) / 9) * plotH;
        if (i == 0) {
          path.moveTo(x, y);
          glowPath.moveTo(x, y);
        } else {
          path.lineTo(x, y);
          glowPath.lineTo(x, y);
        }
      }
      canvas.drawPath(glowPath, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = d.color.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawPath(path, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = d.color);
    }
  }

  @override
  bool shouldRepaint(_TransformChartPainter old) =>
      old.snaps.length != snaps.length || old.reveal != reveal;
}

class _TransOrbsPainter extends CustomPainter {
  final double t;
  _TransOrbsPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    _draw(canvas, Offset(size.width * 0.2, size.height * (0.3 + math.sin(t * 2 * math.pi) * 0.05)),
        100, const Color(0xFFFF7043));
    _draw(canvas, Offset(size.width * 0.85, size.height * (0.6 + math.cos(t * 2 * math.pi) * 0.04)),
        90, const Color(0xFFAB47BC));
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
  bool shouldRepaint(_TransOrbsPainter old) => old.t != t;
}
