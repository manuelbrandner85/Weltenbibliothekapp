// ⚡ GLITCH-MATRIX-DETEKTOR - Tagebuch fuer Realitaets-Anomalien
//
// 6 Glitch-Typen: Mandela-Effekt, Deja-vu, Synchronizitaet, Realitaets-Hick,
// Numerische Repetition (11:11), Verschwundenes Objekt. Speichert lokal in
// SharedPreferences. Zeigt Cluster (z.B. "3 Glitches diese Woche").

import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/wb_cinematic_tokens.dart';
import '../../widgets/cinematic/wb_ambient_particles.dart';
import '../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../widgets/cinematic/wb_vignette.dart';

class GlitchMatrixDetektorScreen extends StatefulWidget {
  const GlitchMatrixDetektorScreen({super.key});

  @override
  State<GlitchMatrixDetektorScreen> createState() => _GlitchMatrixDetektorScreenState();
}

class _GlitchMatrixDetektorScreenState extends State<GlitchMatrixDetektorScreen>
    with TickerProviderStateMixin {
  static const _kKey = 'glitch_journal_v1';
  static const Color _bg = Color(0xFF050010);
  static const Color _primary = Color(0xFFFF7043);
  static const Color _gold = Color(0xFFFFD700);

  List<_Glitch> _glitches = [];
  bool _loading = true;
  _GlitchType? _selectedType;
  final _noteCtrl = TextEditingController();
  int _intensity = 3;
  late final AnimationController _ambientCtrl;

  static final _types = [
    _GlitchType('mandela', 'Mandela-Effekt', '🧠', 'Etwas in der Vergangenheit ist anders als du erinnerst', const Color(0xFFE91E63)),
    _GlitchType('dejavu', 'Déjà-vu', '🌀', 'Moment fühlte sich exakt schon mal erlebt an', const Color(0xFF7C4DFF)),
    _GlitchType('synchro', 'Synchronizität', '✨', 'Sinnvoller Zufall - alles passt magisch zusammen', const Color(0xFFFFD700)),
    _GlitchType('hick', 'Realitäts-Hick', '⚡', 'Etwas änderte sich beim Hinsehen - Ort, Person, Detail', const Color(0xFFFF7043)),
    _GlitchType('numbers', '11:11 / Zahlen', '🔢', 'Wiederholende Zahlen-Muster (11:11, 333, 444)', const Color(0xFF26C6DA)),
    _GlitchType('missing', 'Verschwunden', '👻', 'Objekt/Erinnerung war da, jetzt nicht mehr - oder umgekehrt', const Color(0xFF66BB6A)),
  ];

  @override
  void initState() {
    super.initState();
    _ambientCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();
    _selectedType = _types.first;
    _load();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _ambientCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kKey) ?? const [];
    _glitches = raw.map((s) {
      try { return _Glitch.fromJson(jsonDecode(s) as Map<String, dynamic>); }
      catch (_) { return null; }
    }).whereType<_Glitch>().toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (_selectedType == null || _noteCtrl.text.trim().isEmpty) return;
    HapticFeedback.mediumImpact();
    _glitches.insert(0, _Glitch(
      type: _selectedType!.code,
      note: _noteCtrl.text.trim(),
      intensity: _intensity,
      createdAt: DateTime.now(),
    ));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kKey,
        _glitches.take(200).map((g) => jsonEncode(g.toJson())).toList());
    _noteCtrl.clear();
    setState(() => _intensity = 3);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('⚡ Glitch geloggt (${_glitches.length} total)'),
      backgroundColor: _primary,
    ));
  }

  int _clusterThisWeek() {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return _glitches.where((g) => g.createdAt.isAfter(cutoff)).length;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: _bg,
        body: Center(child: CircularProgressIndicator(color: _primary)),
      );
    }
    return Scaffold(
      backgroundColor: _bg,
      extendBodyBehindAppBar: true,
      appBar: WBGlassAppBar(
        world: WBWorld.neutral,
        titleWidget: ShaderMask(
          shaderCallback: (r) => const LinearGradient(colors: [_gold, _primary]).createShader(r),
          child: const Text('GLITCH-MATRIX',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 3)),
        ),
      ),
      body: Stack(fit: StackFit.expand, children: [
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center, radius: 1.5,
              colors: [Color(0x55BF360C), Color(0x33260C08), _bg],
            ),
          ),
        ),
        IgnorePointer(child: AnimatedBuilder(
          animation: _ambientCtrl,
          builder: (_, __) => CustomPaint(painter: _GmOrbsPainter(_ambientCtrl.value), size: Size.infinite),
        )),
        const IgnorePointer(child: WBAmbientParticles(world: WBWorld.neutral, count: 40)),
        SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
            children: [
              // Header-Stats
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(children: [
                      _stat('${_glitches.length}', 'Total', _gold),
                      _stat('${_clusterThisWeek()}', 'Diese Woche', _primary),
                      _stat('${_types.length}', 'Typen', Colors.white70),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Composer
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('NEUER GLITCH',
                          style: TextStyle(color: _gold, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Wrap(spacing: 6, runSpacing: 6, children: _types.map((t) {
                        final sel = t.code == _selectedType?.code;
                        return GestureDetector(
                          onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedType = t); },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: sel ? t.color.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: sel ? t.color : Colors.transparent),
                            ),
                            child: Text('${t.emoji} ${t.label}',
                                style: TextStyle(color: sel ? Colors.white : Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                        );
                      }).toList()),
                      if (_selectedType != null) ...[
                        const SizedBox(height: 6),
                        Text(_selectedType!.description,
                            style: const TextStyle(color: Colors.white54, fontSize: 11, fontStyle: FontStyle.italic)),
                      ],
                      const SizedBox(height: 10),
                      TextField(
                        controller: _noteCtrl,
                        maxLines: 3, maxLength: 500,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Was war anders? Wo? Wann?',
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.04),
                          counterStyle: const TextStyle(color: Colors.white24, fontSize: 9),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(children: [
                        const Text('Intensität:', style: TextStyle(color: Colors.white60, fontSize: 11)),
                        const SizedBox(width: 8),
                        ...List.generate(5, (i) {
                          final n = i + 1;
                          return GestureDetector(
                            onTap: () { HapticFeedback.lightImpact(); setState(() => _intensity = n); },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: Icon(
                                n <= _intensity ? Icons.flash_on : Icons.flash_off,
                                color: n <= _intensity ? _primary : Colors.white24,
                                size: 20,
                              ),
                            ),
                          );
                        }),
                      ]),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _save,
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text('GLITCH LOGGEN',
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
              ),

              const SizedBox(height: 18),
              if (_glitches.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('Noch keine Glitches geloggt.', style: TextStyle(color: Colors.white54))),
                )
              else ...[
                const Text('VERLAUF',
                    style: TextStyle(color: _gold, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                ..._glitches.take(30).map((g) {
                  final t = _types.firstWhere((x) => x.code == g.type, orElse: () => _types.first);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: t.color.withValues(alpha: 0.3)),
                    ),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(t.emoji, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Text(t.label, style: TextStyle(color: t.color, fontSize: 11, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 6),
                            ...List.generate(g.intensity, (_) =>
                                Icon(Icons.flash_on, color: t.color.withValues(alpha: 0.5), size: 10)),
                            const Spacer(),
                            Text(_fmt(g.createdAt),
                                style: const TextStyle(color: Colors.white38, fontSize: 10)),
                          ]),
                          const SizedBox(height: 2),
                          Text(g.note, style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.4)),
                        ]),
                      ),
                    ]),
                  );
                }),
              ],
            ],
          ),
        ),
        const IgnorePointer(child: WBVignette()),
      ]),
    );
  }

  Widget _stat(String value, String label, Color color) {
    return Expanded(
      child: Column(children: [
        Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
      ]),
    );
  }

  String _fmt(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 2) return 'jetzt';
    if (diff.inHours < 1) return 'vor ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'vor ${diff.inHours}h';
    if (diff.inDays < 7) return 'vor ${diff.inDays}d';
    return '${dt.day}.${dt.month}.';
  }
}

class _GlitchType {
  final String code;
  final String label;
  final String emoji;
  final String description;
  final Color color;
  const _GlitchType(this.code, this.label, this.emoji, this.description, this.color);
}

class _Glitch {
  final String type;
  final String note;
  final int intensity;
  final DateTime createdAt;
  const _Glitch({required this.type, required this.note, required this.intensity, required this.createdAt});

  Map<String, dynamic> toJson() => {
        'type': type,
        'note': note,
        'intensity': intensity,
        'created': createdAt.toIso8601String(),
      };

  factory _Glitch.fromJson(Map<String, dynamic> j) => _Glitch(
        type: j['type'] as String? ?? 'mandela',
        note: j['note'] as String? ?? '',
        intensity: (j['intensity'] as int?) ?? 3,
        createdAt: DateTime.tryParse(j['created'] as String? ?? '') ?? DateTime.now(),
      );
}

class _GmOrbsPainter extends CustomPainter {
  final double t;
  _GmOrbsPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    _draw(canvas, Offset(size.width * 0.2, size.height * (0.3 + math.sin(t * 2 * math.pi) * 0.05)),
        100, const Color(0xFFFF7043));
    _draw(canvas, Offset(size.width * 0.85, size.height * (0.55 + math.cos(t * 2 * math.pi) * 0.04)),
        90, const Color(0xFFFFD700));
    _draw(canvas, Offset(size.width * 0.5, size.height * (0.92 + math.sin(t * math.pi) * 0.03)),
        70, const Color(0xFFE91E63));
  }

  void _draw(Canvas canvas, Offset c, double r, Color color) {
    final p = Paint()
      ..color = color.withValues(alpha: 0.10)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.5);
    canvas.drawCircle(c, r, p);
  }

  @override
  bool shouldRepaint(_GmOrbsPainter old) => old.t != t;
}
