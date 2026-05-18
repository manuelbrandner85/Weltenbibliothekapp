// ᚱ RUNEN-ORAKEL · Cinematic Casting + AI-Lesung + Bind-Rune-Generator
//
// 24 Elder Futhark Runen mit klassischer + reversed Bedeutung.
// 3 Spreads: Tagesrune · Nornen (Urd/Verdandi/Skuld) · Asgard-Kreuz (5).
// Cast-Animation: Runen fallen aus Beutel auf Tuch.
// AI-Lesung via /api/mentor/chat (alchemist).
// Bind-Rune-Generator: kombiniere 2-3 Runen zu Sigille.
// History: SharedPreferences + spirit_readings.

import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/api_config.dart';
import '../../../core/storage/unified_storage_service.dart';
import '../../../services/spirit_reading_service.dart';
import '../../../theme/wb_cinematic_tokens.dart';
import '../../../widgets/cinematic/wb_ambient_particles.dart';
import '../../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../../widgets/cinematic/wb_vignette.dart';

class RunesOracleScreen extends StatefulWidget {
  const RunesOracleScreen({super.key});

  @override
  State<RunesOracleScreen> createState() => _RunesOracleScreenState();
}

class _RunesOracleScreenState extends State<RunesOracleScreen>
    with TickerProviderStateMixin {
  static const Color _bg = Color(0xFF050908);
  static const Color _primary = Color(0xFF1B5E20); // dark green
  static const Color _accent = Color(0xFF4DD0E1); // ice blue
  static const Color _gold = Color(0xFFFFB74D);
  static const String _kvKey = 'runes_history_v1';

  _Phase _phase = _Phase.pickSpread;
  _Spread _spread = _spreads[0];
  String _question = '';
  List<_DrawnRune> _drawn = [];
  int _focusIndex = 0;
  String? _aiReading;
  bool _loadingAi = false;
  List<_RuneHistory> _history = [];

  // Bind-Rune
  bool _bindMode = false;
  final List<int> _bindSelection = [];

  late final AnimationController _ambientCtrl;
  late final AnimationController _castCtrl;
  late final AnimationController _glowCtrl;

  @override
  void initState() {
    super.initState();
    _ambientCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    _castCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat(reverse: true);
    _loadHistory();
  }

  @override
  void dispose() {
    _ambientCtrl.dispose();
    _castCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kvKey) ?? const [];
    final out = <_RuneHistory>[];
    for (final s in raw) {
      try {
        out.add(_RuneHistory.fromJson(jsonDecode(s) as Map<String, dynamic>));
      } catch (_) {}
    }
    if (mounted) setState(() => _history = out);
  }

  Future<void> _persistHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _history.take(30).map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_kvKey, list);
  }

  Future<void> _castRunes() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _phase = _Phase.casting;
      _aiReading = null;
    });
    _castCtrl.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 1500));

    final rand = math.Random();
    final deck = List<int>.generate(_elderFuthark.length, (i) => i)..shuffle(rand);
    final picks = <_DrawnRune>[];
    for (int i = 0; i < _spread.count; i++) {
      final rune = _elderFuthark[deck[i]];
      final reversed = rand.nextDouble() < 0.30 && rune.canReverse;
      picks.add(_DrawnRune(rune: rune, reversed: reversed, position: _spread.positions[i]));
    }
    if (mounted) {
      setState(() {
        _drawn = picks;
        _focusIndex = 0;
        _phase = _Phase.revealing;
      });
    }
    HapticFeedback.heavyImpact();
  }

  Future<void> _requestAiReading() async {
    HapticFeedback.selectionClick();
    setState(() => _loadingAi = true);
    try {
      final runesText = _drawn
          .map((d) => '${d.position}: ${d.rune.name} (${d.rune.glyph})'
              '${d.reversed ? " — umgekehrt/merkstave" : ""} — ${d.rune.meaning}')
          .join('\n');
      final prompt = StringBuffer()
        ..writeln('Lies dieses Runen-Wurf in der Tradition des Elder Futhark:')
        ..writeln('Frage: "${_question.isEmpty ? "Was zeigt das Wyrd?" : _question}"')
        ..writeln('Spread: ${_spread.name}')
        ..writeln('Runen:')
        ..writeln(runesText)
        ..writeln('')
        ..writeln('Lies in 4-5 Absätzen: erst der Gesamteindruck (Wyrd), dann '
            'Rune für Rune im Kontext, dann konkrete Handlung. '
            'Nordisch-mythologisch grundiert (Odin, Yggdrasil, Nornen), '
            'aber direkt anwendbar. Du-Form, ohne Disclaimer.');
      final token = Supabase.instance.client.auth.currentSession?.accessToken ?? '';
      final res = await http
          .post(
            Uri.parse('${ApiConfig.workerUrl}/api/mentor/chat'),
            headers: {
              'Content-Type': 'application/json',
              if (token.isNotEmpty) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'personality': 'alchemist',
              'message': prompt.toString(),
              'world': 'energie',
              'conversationHistory': [],
            }),
          )
          .timeout(const Duration(seconds: 40));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final answer = (data['reply'] ?? data['answer'] ?? data['response'] ?? data['message'] ?? '') as String;
        if (mounted) {
          setState(() {
            _aiReading = answer.trim();
            _loadingAi = false;
          });
        }
        return;
      }
      if (mounted) {
        setState(() {
          _aiReading = '⚠️ AI-Lesung gerade nicht verfügbar (HTTP ${res.statusCode}).';
          _loadingAi = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _aiReading = '⚠️ Netzwerk: $e';
          _loadingAi = false;
        });
      }
    }
  }

  Future<void> _saveReading() async {
    if (_drawn.isEmpty) return;
    final username = UnifiedStorageService().getUsername('energie');
    final userId = await UnifiedStorageService().getCurrentUserId() ?? 'anonym';
    final saved = await SpiritReadingService.instance.save(
      userId: userId,
      username: username,
      tool: 'runes',
      summary: '${_spread.icon} ${_spread.name}: '
          '${_drawn.map((d) => d.rune.glyph).join(" ")}',
      result: {
        'spread': _spread.code,
        'question': _question,
        'runes': _drawn
            .map((d) => {
                  'glyph': d.rune.glyph,
                  'name': d.rune.name,
                  'reversed': d.reversed,
                  'position': d.position,
                })
            .toList(),
        'ai_reading': _aiReading,
      },
    );
    _history.insert(
        0,
        _RuneHistory(
          spread: _spread.code,
          question: _question,
          glyphs: _drawn.map((d) => d.rune.glyph).toList(),
          createdAt: DateTime.now().toIso8601String(),
        ));
    if (_history.length > 30) _history = _history.sublist(0, 30);
    await _persistHistory();
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(saved != null
          ? 'ᚷ Wyrd-Lesung im Akasha-Tagebuch + lokaler Verlauf'
          : 'ᚷ Lokal gespeichert (Cloud offline)'),
      backgroundColor: _primary,
    ));
  }

  void _reset() {
    setState(() {
      _phase = _Phase.pickSpread;
      _drawn = [];
      _aiReading = null;
      _question = '';
      _bindMode = false;
      _bindSelection.clear();
    });
  }

  void _toggleBindRune() {
    HapticFeedback.selectionClick();
    setState(() {
      _bindMode = !_bindMode;
      _bindSelection.clear();
    });
  }

  void _toggleBindSelect(int idx) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_bindSelection.contains(idx)) {
        _bindSelection.remove(idx);
      } else if (_bindSelection.length < 3) {
        _bindSelection.add(idx);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      extendBodyBehindAppBar: true,
      appBar: WBGlassAppBar(
        world: WBWorld.energie,
        titleWidget: ShaderMask(
          shaderCallback: (r) => const LinearGradient(
            colors: [_gold, _accent],
          ).createShader(r),
          child: const Text('RUNEN-ORAKEL',
              style: TextStyle(
                  color: Colors.white, fontSize: 14,
                  fontWeight: FontWeight.w900, letterSpacing: 3)),
        ),
        actions: [
          if (_phase == _Phase.revealing && _drawn.length > 1)
            IconButton(
              icon: Icon(Icons.link_rounded, color: _bindMode ? _gold : Colors.white70),
              tooltip: _bindMode ? 'Bind-Modus aus' : 'Bind-Rune erstellen',
              onPressed: _toggleBindRune,
            ),
          if (_phase == _Phase.revealing && _drawn.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.bookmark_added_rounded, color: _gold),
              tooltip: 'Speichern',
              onPressed: _saveReading,
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              tooltip: 'Neuer Wurf',
              onPressed: _reset,
            ),
          ],
          if (_phase == _Phase.pickSpread && _history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.history_rounded, color: Colors.white),
              tooltip: 'Verlauf',
              onPressed: _showHistory,
            ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.3),
                radius: 1.4,
                colors: [Color(0x661B5E20), Color(0x440D2F11), _bg],
              ),
            ),
          ),
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _ambientCtrl,
              builder: (_, __) => CustomPaint(
                painter: _RunesOrbsPainter(_ambientCtrl.value),
                size: Size.infinite,
              ),
            ),
          ),
          const IgnorePointer(
              child: WBAmbientParticles(world: WBWorld.energie, count: 32)),
          SafeArea(child: _content()),
          const IgnorePointer(child: WBVignette()),
        ],
      ),
    );
  }

  Widget _content() {
    switch (_phase) {
      case _Phase.pickSpread: return _pickSpreadPhase();
      case _Phase.casting:    return _castingPhase();
      case _Phase.revealing:  return _revealPhase();
    }
  }

  Widget _pickSpreadPhase() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [_primary.withValues(alpha: 0.3), _accent.withValues(alpha: 0.08)]),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('FRAGE AN DAS WYRD',
                    style: TextStyle(color: _gold, fontSize: 10, letterSpacing: 3, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                TextField(
                  maxLines: 2, maxLength: 140,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Optional — z.B. "Welche Kraft ruft mich?"',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    counterStyle: const TextStyle(color: Colors.white24, fontSize: 9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  onChanged: (v) => _question = v.trim(),
                ),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text('WÄHLE DEN WURF',
            style: TextStyle(color: _gold, fontSize: 11, letterSpacing: 3, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center),
        const SizedBox(height: 14),
        ..._spreads.map((s) {
          final sel = s.code == _spread.code;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  setState(() => _spread = s);
                  _castRunes();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: sel
                        ? LinearGradient(colors: [_primary.withValues(alpha: 0.4), _accent.withValues(alpha: 0.15)])
                        : null,
                    color: sel ? null : Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: sel ? _accent : Colors.white12),
                  ),
                  child: Row(children: [
                    Text(s.icon, style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(s.name,
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 3),
                        Text(s.tagline,
                            style: const TextStyle(color: Colors.white60, fontSize: 11, height: 1.3),
                            maxLines: 2),
                      ]),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _gold.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _gold.withValues(alpha: 0.4)),
                      ),
                      child: Text('${s.count}',
                          style: const TextStyle(color: _gold, fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  ]),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _castingPhase() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        AnimatedBuilder(
          animation: _castCtrl,
          builder: (_, __) {
            return SizedBox(
              width: 240, height: 240,
              child: CustomPaint(painter: _RuneCastPainter(_castCtrl.value, _accent, _gold)),
            );
          },
        ),
        const SizedBox(height: 20),
        const Text('Die Runen fallen aufs Tuch…',
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        const Text('"Ek veit at ek hekk" — ich weiß, dass ich hing',
            style: TextStyle(color: Colors.white54, fontSize: 11, fontStyle: FontStyle.italic)),
      ]),
    );
  }

  Widget _revealPhase() {
    if (_drawn.isEmpty) return const SizedBox.shrink();
    if (_bindMode) return _bindRuneView();

    final focused = _drawn[_focusIndex];
    return Column(children: [
      // Runen-Reihe
      Container(
        height: 110,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _drawn.length,
          itemBuilder: (_, i) {
            final d = _drawn[i];
            final selected = i == _focusIndex;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _focusIndex = i);
                },
                child: _runeStone(d, mini: true, selected: selected),
              ),
            );
          },
        ),
      ),

      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Column(children: [
            Text(focused.position.toUpperCase(),
                style: const TextStyle(color: _gold, fontSize: 10, letterSpacing: 3, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            _runeStone(focused, mini: false),
            const SizedBox(height: 14),
            Text(
              '${focused.rune.name}${focused.reversed ? " · merkstave" : ""}',
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Text(focused.rune.transliteration,
                style: const TextStyle(color: _accent, fontSize: 12, letterSpacing: 2)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _kv('🪓 BEDEUTUNG', focused.reversed ? focused.rune.reversedMeaning : focused.rune.meaning),
                const SizedBox(height: 8),
                _kv('⚔️ ELEMENT', focused.rune.element),
                const SizedBox(height: 8),
                _kv('🌳 GOTT/HEIM', focused.rune.deity),
              ]),
            ),
            const SizedBox(height: 18),
            if (_aiReading == null && !_loadingAi)
              ElevatedButton.icon(
                onPressed: _requestAiReading,
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('AI-WYRD-LESUNG',
                    style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              )
            else if (_loadingAi)
              Column(children: [
                AnimatedBuilder(
                  animation: _glowCtrl,
                  builder: (_, __) => Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        _accent.withValues(alpha: 0.5 + 0.3 * _glowCtrl.value),
                        Colors.transparent,
                      ]),
                    ),
                    child: const Center(child: Icon(Icons.auto_awesome, color: _gold, size: 26)),
                  ),
                ),
                const SizedBox(height: 10),
                const Text('Odin liest das Wyrd…',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ])
            else if (_aiReading != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _accent.withValues(alpha: 0.4)),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Icon(Icons.auto_awesome_rounded, color: _gold, size: 18),
                        const SizedBox(width: 6),
                        const Text('WYRD · AI-LESUNG',
                            style: TextStyle(color: _gold, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w700)),
                      ]),
                      const SizedBox(height: 10),
                      SelectableText(_aiReading!,
                          style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.6)),
                    ]),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            if (_question.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(children: [
                  const Icon(Icons.help_outline_rounded, color: _gold, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('"$_question"',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic)),
                  ),
                ]),
              ),
          ]),
        ),
      ),
    ]);
  }

  Widget _bindRuneView() {
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        decoration: BoxDecoration(
          color: _gold.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _gold.withValues(alpha: 0.4)),
        ),
        child: Column(children: [
          const Text('BIND-RUNE-GENERATOR',
              style: TextStyle(color: _gold, fontSize: 11, letterSpacing: 3, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            _bindSelection.isEmpty
                ? 'Wähle 2–3 Runen die du verbinden willst'
                : '${_bindSelection.length} Rune(n) gewählt: ${_bindSelection.map((i) => _drawn[i].rune.glyph).join(" + ")}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ]),
      ),
      // Runen-Auswahl
      Container(
        height: 100,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _drawn.length,
          itemBuilder: (_, i) {
            final d = _drawn[i];
            final sel = _bindSelection.contains(i);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () => _toggleBindSelect(i),
                child: _runeStone(d, mini: true, selected: sel),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 12),
      // Bind-Vorschau
      if (_bindSelection.length >= 2)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: AnimatedBuilder(
              animation: _glowCtrl,
              builder: (_, __) => Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: RadialGradient(colors: [
                    _gold.withValues(alpha: 0.15 + 0.1 * _glowCtrl.value),
                    Colors.transparent,
                  ]),
                ),
                child: Center(
                  child: CustomPaint(
                    size: const Size(220, 220),
                    painter: _BindRunePainter(
                      glyphs: _bindSelection.map((i) => _drawn[i].rune.glyph).toList(),
                      gold: _gold,
                      accent: _accent,
                    ),
                  ),
                ),
              ),
            ),
          ),
        )
      else
        const Expanded(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('Wähle oben mindestens 2 Runen für die Bind-Vorschau.',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                  textAlign: TextAlign.center),
            ),
          ),
        ),
    ]);
  }

  Widget _runeStone(_DrawnRune d, {bool mini = false, bool selected = false}) {
    final w = mini ? 60.0 : 180.0;
    final h = mini ? 80.0 : 240.0;
    return Container(
      width: w, height: h,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3E2723), Color(0xFF5D4037), Color(0xFF8D6E63)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(mini ? 6 : 14),
        border: Border.all(color: selected ? _gold : _accent.withValues(alpha: 0.45),
            width: selected ? 2 : 1),
        boxShadow: [
          BoxShadow(
              color: (selected ? _gold : _accent).withValues(alpha: 0.4),
              blurRadius: mini ? 6 : 16, spreadRadius: 1),
        ],
      ),
      child: Transform.rotate(
        angle: d.reversed ? math.pi : 0,
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(d.rune.glyph,
                style: TextStyle(
                    fontSize: mini ? 36 : 90,
                    color: _gold.withValues(alpha: 0.95),
                    height: 1)),
            if (!mini) ...[
              const SizedBox(height: 10),
              Text(d.rune.name.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold)),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _kv(String k, String v) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: const TextStyle(color: _gold, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(v, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5)),
        ],
      );

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A1A12),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7, minChildSize: 0.4, maxChildSize: 0.95,
        expand: false,
        builder: (_, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          children: [
            Center(
              child: Container(
                width: 42, height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('WYRD-VERLAUF',
                style: TextStyle(color: _gold, fontSize: 12, letterSpacing: 3, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center),
            const SizedBox(height: 14),
            if (_history.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text('Noch keine Würfe.', style: TextStyle(color: Colors.white54), textAlign: TextAlign.center),
              )
            else
              ..._history.map((h) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Text(h.glyphs.join(' '),
                            style: const TextStyle(color: _gold, fontSize: 20)),
                        const Spacer(),
                        Text(_fmt(h.createdAt),
                            style: const TextStyle(color: Colors.white38, fontSize: 10)),
                      ]),
                      if (h.question.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('"${h.question}"',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 11, fontStyle: FontStyle.italic),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ]),
                  )),
          ],
        ),
      ),
    );
  }

  String _fmt(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2,'0')}.${dt.month.toString().padLeft(2,'0')}.';
    } catch (_) { return ''; }
  }
}

enum _Phase { pickSpread, casting, revealing }

class _Spread {
  final String code;
  final String name;
  final String tagline;
  final String icon;
  final int count;
  final List<String> positions;
  const _Spread(this.code, this.name, this.tagline, this.icon, this.count, this.positions);
}

const List<_Spread> _spreads = [
  _Spread(
    'daily', 'Tagesrune', 'Eine Rune für den heutigen Tag.', 'ᚱ',
    1, ['Heute'],
  ),
  _Spread(
    'norns', 'Nornen-Wurf', 'Urd · Verdandi · Skuld — Vergangenheit/Gegenwart/Zukunft.', 'ᚦ',
    3, ['Urd (Vergangenheit)', 'Verdandi (Gegenwart)', 'Skuld (Zukunft)'],
  ),
  _Spread(
    'asgard', 'Asgard-Kreuz', 'Tiefer 5-Runen-Wurf für komplexe Fragen.', 'ᚹ',
    5, [
      'Wurzel der Frage',
      'Hindernis',
      'Verborgener Einfluss',
      'Empfohlene Tat',
      'Endergebnis',
    ],
  ),
];

class _Rune {
  final String glyph;
  final String name;
  final String transliteration;
  final String meaning;
  final String reversedMeaning;
  final String element;
  final String deity;
  final bool canReverse;
  const _Rune(this.glyph, this.name, this.transliteration, this.meaning,
      this.reversedMeaning, this.element, this.deity, this.canReverse);
}

const List<_Rune> _elderFuthark = [
  _Rune('ᚠ', 'Fehu', 'F', 'Vieh, Wohlstand, Anfangskapital, materielle Manifestation, Erfolg durch Energie.',
      'Verlust von Reichtum, Habsucht, Energie blockiert.', 'Feuer', 'Frey · Vanir', true),
  _Rune('ᚢ', 'Uruz', 'U', 'Ur-Stier, Urkraft, Rohenergie, Vitalität, Mut zur Verwandlung.',
      'Schwäche, missbrauchte Kraft, gehemmte Lebensenergie.', 'Erde', 'Audhumla', true),
  _Rune('ᚦ', 'Thurisaz', 'TH', 'Dorn, Riesenkraft, durchbrechende Energie, Thor\'s Hammer, Schutz.',
      'Naive Verteidigung, unbedachtes Handeln, Aggression nach innen.', 'Feuer', 'Thor', true),
  _Rune('ᚨ', 'Ansuz', 'A', 'Odin, göttlicher Atem, Inspiration, gesprochenes Wort, Offenbarung.',
      'Manipulation durch Worte, Missverständnisse, Lügen.', 'Luft', 'Odin', true),
  _Rune('ᚱ', 'Raidho', 'R', 'Reise, Rad, Reise zu sich selbst, Rhythmus, geordnete Bewegung.',
      'Stillstand, falsche Richtung, Reise unterbrochen.', 'Luft', 'Forseti', true),
  _Rune('ᚲ', 'Kenaz', 'K', 'Fackel, Erkenntnis, Klarheit, Lehrmeisterschaft, schöpferisches Feuer.',
      'Verdunklung, Verlust von Hoffnung, Erkenntnis verweigert.', 'Feuer', 'Heimdall', true),
  _Rune('ᚷ', 'Gebo', 'G', 'Gabe, Austausch, Beziehung, sakrale Vereinigung, gegenseitige Hingabe.',
      '— (kann nicht umgekehrt werden)', 'Luft', 'Odin/Gefjon', false),
  _Rune('ᚹ', 'Wunjo', 'W', 'Freude, Harmonie, Gemeinschaft, das gute Zuhause, erfüllte Sehnsucht.',
      'Unzufriedenheit, Entfremdung von Gemeinschaft, Verlust der Freude.', 'Erde', 'Odin', true),
  _Rune('ᚺ', 'Hagalaz', 'H', 'Hagel, Krise als Reinigung, unausweichlicher Wandel, alte Strukturen brechen.',
      '— (Krise ist immer Krise)', 'Wasser/Eis', 'Urd · Niflheim', false),
  _Rune('ᚾ', 'Nauthiz', 'N', 'Not, Notwendigkeit, das was sein muss, innere Disziplin im Mangel.',
      'Verstärkter Mangel, Erschöpfung, falsche Knappheits-Annahme.', 'Feuer/Eis', 'Skuld', true),
  _Rune('ᛁ', 'Isa', 'I', 'Eis, Stillstand, Selbstkonzentration, Frieren als Schutz, Pause.',
      '— (Eis ist Eis)', 'Eis', 'Verdandi · Frost', false),
  _Rune('ᛃ', 'Jera', 'J', 'Jahr, Ernte, Zyklus, das was reift, geduldige Belohnung nach Arbeit.',
      '— (Zyklus ist immer Zyklus)', 'Erde', 'Frey/Freyja', false),
  _Rune('ᛇ', 'Eihwaz', 'EI', 'Eibe, Weltbaum, Lebensbaum, Verbindung Himmel-Erde, Unsterblichkeit.',
      '— (Weltbaum steht)', 'Erde/Feuer', 'Yggdrasil', false),
  _Rune('ᛈ', 'Perthro', 'P', 'Würfelbecher, Schicksal, das Verborgene wird offenbar, Geheimnisse.',
      'Manipulation durch Geheimnisse, schlechte Gewohnheit, Stagnation.', 'Wasser', 'Urd · Wyrd', true),
  _Rune('ᛉ', 'Algiz', 'Z', 'Elch, Schutz, höheres Selbst, Verbindung zu den Göttern, sakrale Grenze.',
      'Verlust des Schutzes, Verletzlichkeit, Verbindung zu Selbst gebrochen.', 'Luft', 'Heimdall', true),
  _Rune('ᛊ', 'Sowilo', 'S', 'Sonne, Sieg, Lebenskraft, Erleuchtung, Vollendung der Tat.',
      '— (Sonne scheint)', 'Feuer', 'Sol · Sonnengott', false),
  _Rune('ᛏ', 'Tiwaz', 'T', 'Tyr, Krieger-Gerechtigkeit, Opfer für höhere Sache, klares Urteil.',
      'Ungerechtigkeit, falscher Sieg, Opfer ohne Sinn.', 'Luft', 'Tyr', true),
  _Rune('ᛒ', 'Berkano', 'B', 'Birke, Mutter, Geburt, neuer Anfang, weibliche Schöpfungskraft.',
      'Familienkrise, gestörtes Wachstum, Vernachlässigung.', 'Erde', 'Frigg/Berchta', true),
  _Rune('ᛖ', 'Ehwaz', 'E', 'Pferd, Partnerschaft, harmonische Bewegung zu zweit, Vertrauen.',
      'Disharmonie in Partnerschaft, Vertrauensbruch, Stillstand.', 'Erde', 'Sleipnir · Freyr', true),
  _Rune('ᛗ', 'Mannaz', 'M', 'Mensch, Selbst-Reflexion, Menschheit, Selbst im Bezug zu anderen.',
      'Isolation, Selbsttäuschung, kalte Einsamkeit.', 'Luft', 'Heimdall/Mensch', true),
  _Rune('ᛚ', 'Laguz', 'L', 'Wasser, Intuition, Mond, Tiefen des Unbewussten, Fluss.',
      'Angst vor Tiefe, Überflutung von Emotionen, Verirrung.', 'Wasser', 'Njörd/Mond', true),
  _Rune('ᛜ', 'Ingwaz', 'NG', 'Frey/Ing, fruchtbarer Same, innere Wachstumskraft, Potenzial.',
      '— (Same ist Same)', 'Erde', 'Frey/Ing', false),
  _Rune('ᛞ', 'Dagaz', 'D', 'Tag, Durchbruch, Erleuchtung, Übergang Nacht-zu-Tag.',
      '— (Tag bricht an)', 'Feuer/Luft', 'Dagr', false),
  _Rune('ᛟ', 'Othala', 'O', 'Erbe, Heimat, Ahnenkraft, das was uns weitergegeben wurde, Wurzeln.',
      'Vorurteil, Klan-Engstirnigkeit, ungelöste Ahnen-Themen.', 'Erde', 'Ahnen · Asgard', true),
];

class _DrawnRune {
  final _Rune rune;
  final bool reversed;
  final String position;
  const _DrawnRune({required this.rune, required this.reversed, required this.position});
}

class _RuneHistory {
  final String spread;
  final String question;
  final List<String> glyphs;
  final String createdAt;
  const _RuneHistory({
    required this.spread, required this.question,
    required this.glyphs, required this.createdAt,
  });
  Map<String, dynamic> toJson() => {
        'spread': spread, 'question': question,
        'glyphs': glyphs, 'createdAt': createdAt,
      };
  factory _RuneHistory.fromJson(Map<String, dynamic> j) => _RuneHistory(
        spread: j['spread'] as String? ?? 'daily',
        question: j['question'] as String? ?? '',
        glyphs: ((j['glyphs'] as List?) ?? const []).cast<String>(),
        createdAt: j['createdAt'] as String? ?? '',
      );
}

// ── PAINTER: 3 CineOrbs (Dark Green/Ice/Gold) ──────────────────────────────
class _RunesOrbsPainter extends CustomPainter {
  final double t;
  _RunesOrbsPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    _draw(canvas, Offset(size.width * 0.18, size.height * (0.3 + math.sin(t * 2 * math.pi) * 0.05)),
        110, const Color(0xFF1B5E20));
    _draw(canvas, Offset(size.width * 0.85, size.height * (0.55 + math.cos(t * 2 * math.pi) * 0.04)),
        100, const Color(0xFF4DD0E1));
    _draw(canvas, Offset(size.width * 0.5, size.height * (0.92 + math.sin(t * math.pi) * 0.03)),
        80, const Color(0xFFFFB74D));
  }

  void _draw(Canvas canvas, Offset c, double r, Color color) {
    final p = Paint()
      ..color = color.withValues(alpha: 0.10)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.5);
    canvas.drawCircle(c, r, p);
  }

  @override
  bool shouldRepaint(_RunesOrbsPainter old) => old.t != t;
}

// ── PAINTER: Cast-Animation ────────────────────────────────────────────────
class _RuneCastPainter extends CustomPainter {
  final double t; // 0..1
  final Color accent;
  final Color gold;
  _RuneCastPainter(this.t, this.accent, this.gold);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // Beutel oben
    final bagY = -40.0 + t * 60;
    final bagPaint = Paint()..color = const Color(0xFF3E2723);
    canvas.drawRect(
      Rect.fromCenter(center: Offset(center.dx, bagY), width: 60, height: 80),
      bagPaint,
    );
    // 5 Runen, die rausfallen
    final rand = math.Random(42);
    final paint = Paint()
      ..color = accent.withValues(alpha: 0.9)
      ..strokeWidth = 2;
    final glyphs = ['ᚠ', 'ᚹ', 'ᛟ', 'ᛇ', 'ᛞ'];
    for (int i = 0; i < 5; i++) {
      final delay = i * 0.1;
      final localT = ((t - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (localT <= 0) continue;
      final dx = (rand.nextDouble() - 0.5) * 200;
      final dy = bagY + 40 + localT * (center.dy - bagY);
      final rot = localT * (rand.nextDouble() * 4 - 2);
      canvas.save();
      canvas.translate(center.dx + dx, dy);
      canvas.rotate(rot);
      // Stein
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-22, -28, 44, 56),
          const Radius.circular(8),
        ),
        Paint()..color = const Color(0xFF5D4037),
      );
      // Glyphe
      final tp = TextPainter(
        text: TextSpan(text: glyphs[i],
            style: TextStyle(color: gold, fontSize: 28, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
    // Indikator des Beutels
    canvas.drawLine(Offset(center.dx - 20, bagY - 35), Offset(center.dx + 20, bagY - 35), paint);
  }

  @override
  bool shouldRepaint(_RuneCastPainter old) => old.t != t;
}

// ── PAINTER: Bind-Rune ──────────────────────────────────────────────────────
class _BindRunePainter extends CustomPainter {
  final List<String> glyphs;
  final Color gold;
  final Color accent;
  _BindRunePainter({required this.glyphs, required this.gold, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // Hintergrund-Kreis (heiliger Raum)
    final circlePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = accent.withValues(alpha: 0.3);
    canvas.drawCircle(center, size.width * 0.45, circlePaint);
    canvas.drawCircle(center, size.width * 0.35, circlePaint..color = accent.withValues(alpha: 0.2));

    // Vertikale Achse als Trägerlinie
    final axisPaint = Paint()
      ..color = gold.withValues(alpha: 0.4)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(center.dx, center.dy - 80),
        Offset(center.dx, center.dy + 80), axisPaint);

    // Alle Glyphen übereinander mit leichter Rotation
    for (int i = 0; i < glyphs.length; i++) {
      final angle = (i - glyphs.length / 2.0 + 0.5) * 0.3;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      final tp = TextPainter(
        text: TextSpan(text: glyphs[i],
            style: TextStyle(
                color: gold,
                fontSize: 100,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: accent, blurRadius: 8)])),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }

    // Verbindungs-Knoten (3 kleine Kreise)
    final knot = Paint()..color = gold;
    canvas.drawCircle(Offset(center.dx, center.dy - 65), 3, knot);
    canvas.drawCircle(Offset(center.dx, center.dy), 4, knot);
    canvas.drawCircle(Offset(center.dx, center.dy + 65), 3, knot);
  }

  @override
  bool shouldRepaint(_BindRunePainter old) => old.glyphs.length != glyphs.length;
}
