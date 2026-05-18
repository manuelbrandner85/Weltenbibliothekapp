// 🥁 SCHAMANISCHE REISE · AI-Guided Multi-Phase Narrative + Drum-Pulse
//
// Komplement-Tool zum existierenden ShamanicJourneyToolScreen (Timer/Journal).
// Hier: text-geführte 5-Phasen-Reise mit AI-Narration und visuellem
// Theta-Drum-Pulse (~4 Hz, Trommel-Reise-Frequenz, ohne Audio-Asset).
//
// Phasen:
//   1. Eingang  — Tor öffnet sich zur gewählten Welt
//   2. Reise    — Wesen/Landschaft erscheint
//   3. Begegnung — Krafttier / Mittel-Mensch / Spirit-Guide
//   4. Botschaft — Antwort auf die Frage
//   5. Rückkehr — Integration & Tagebuch
//
// Welten: Untere · Mittlere · Obere (klassische schamanische Kosmologie)
//
// Safety: "Zurück ins Hier"-Button immer sichtbar.

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

class ShamanicGuidedJourneyScreen extends StatefulWidget {
  const ShamanicGuidedJourneyScreen({super.key});

  @override
  State<ShamanicGuidedJourneyScreen> createState() => _ShamanicGuidedJourneyScreenState();
}

class _ShamanicGuidedJourneyScreenState extends State<ShamanicGuidedJourneyScreen>
    with TickerProviderStateMixin {
  static const Color _bg = Color(0xFF080308);
  static const Color _gold = Color(0xFFFFB74D);
  static const String _kvKey = 'shamanic_journeys_v1';

  _Phase _phase = _Phase.pickWorld;
  _World _world = _worlds[0];
  String _question = '';
  List<String> _narration = [];
  int _currentNarrationIndex = 0;
  bool _loadingNarration = false;
  String? _error;
  List<_JourneyHistory> _history = [];

  late final AnimationController _drumCtrl;
  late final AnimationController _ambientCtrl;
  late final AnimationController _fadeCtrl;

  // 5 Phasen-Titel
  static const _phaseLabels = [
    '🌑 EINGANG',
    '🌊 REISE',
    '🦅 BEGEGNUNG',
    '✨ BOTSCHAFT',
    '🌅 RÜCKKEHR',
  ];

  @override
  void initState() {
    super.initState();
    // Theta-Drum-Beat ~4 Hz → 250ms cycle. Etwas langsamer für Visual: 280ms.
    _drumCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 280))..repeat(reverse: true);
    _ambientCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _loadHistory();
  }

  @override
  void dispose() {
    _drumCtrl.dispose();
    _ambientCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kvKey) ?? const [];
    final out = <_JourneyHistory>[];
    for (final s in raw) {
      try { out.add(_JourneyHistory.fromJson(jsonDecode(s) as Map<String, dynamic>)); } catch (_) {}
    }
    if (mounted) setState(() => _history = out);
  }

  Future<void> _persistHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _history.take(30).map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_kvKey, list);
  }

  Future<void> _startJourney() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _phase = _Phase.generating;
      _error = null;
      _narration = [];
      _currentNarrationIndex = 0;
      _loadingNarration = true;
    });
    try {
      final prompt = StringBuffer()
        ..writeln('Führe eine schamanische ${_world.label}-Reise in 5 Phasen.')
        ..writeln('Frage: "${_question.isEmpty ? "Was darf ich heute wissen?" : _question}"')
        ..writeln('Welt: ${_world.label} — ${_world.description}')
        ..writeln('')
        ..writeln('Schreibe genau 5 Absätze, JEDER GENAU MIT EINER ÜBERSCHRIFT:')
        ..writeln('1. EINGANG: Beschreibe wie sich das Tor zur ${_world.label} öffnet (60-90 Wörter)')
        ..writeln('2. REISE: Was sieht/hört/spürt der Reisende? (60-90 Wörter)')
        ..writeln('3. BEGEGNUNG: ${_world.beingType} erscheint — beschreibe es lebendig (60-90 Wörter)')
        ..writeln('4. BOTSCHAFT: Die direkte Antwort auf die Frage durch das Wesen (60-90 Wörter)')
        ..writeln('5. RÜCKKEHR: Sanfter Weg zurück, Integration (40-60 Wörter)')
        ..writeln('')
        ..writeln('Format pro Phase: "## PHASEN-TITEL\\n\\n[Text...]"')
        ..writeln('Du-Form. Lebendig, bildreich, mythologisch geerdet. '
            'Keine Disclaimer, keine Esoterik-Klischees. Keine Liste, sondern fließende Prosa.');
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
          .timeout(const Duration(seconds: 50));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final answer = ((data['answer'] ?? data['response'] ?? data['message'] ?? '') as String).trim();
        final phases = _parsePhases(answer);
        if (phases.length >= 3 && mounted) {
          setState(() {
            _narration = phases;
            _loadingNarration = false;
            _phase = _Phase.journeying;
          });
          _fadeCtrl.forward(from: 0);
          return;
        }
      }
      if (mounted) {
        setState(() {
          _error = 'AI-Reise gerade nicht verfügbar (HTTP ${res.statusCode}). Versuch\'s nochmal.';
          _loadingNarration = false;
          _phase = _Phase.pickWorld;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Netzwerk: $e';
          _loadingNarration = false;
          _phase = _Phase.pickWorld;
        });
      }
    }
  }

  List<String> _parsePhases(String text) {
    // Splittet bei "##" headers oder "1." / "2." Marken
    final lines = text.split('\n');
    final out = <String>[];
    var buf = StringBuffer();
    for (final l in lines) {
      final tr = l.trim();
      final isHeader = tr.startsWith('##') ||
          RegExp(r'^[1-5][\.\)]\s').hasMatch(tr) ||
          (tr.toUpperCase() == tr &&
              tr.length > 4 && tr.length < 50 &&
              !tr.contains(',') && tr.contains(':'));
      if (isHeader) {
        if (buf.isNotEmpty) {
          out.add(buf.toString().trim());
          buf = StringBuffer();
        }
        // Header-Zeile mit reinnehmen (entfernt ## und Zahl-Prefix)
        var header = tr.replaceAll('##', '').trim();
        header = header.replaceFirst(RegExp(r'^[1-5][\.\)]\s*'), '');
        buf.writeln(header);
      } else if (tr.isNotEmpty) {
        buf.writeln(tr);
      } else if (buf.isNotEmpty) {
        buf.writeln('');
      }
    }
    if (buf.isNotEmpty) out.add(buf.toString().trim());
    return out;
  }

  void _nextPhase() {
    HapticFeedback.selectionClick();
    if (_currentNarrationIndex < _narration.length - 1) {
      setState(() => _currentNarrationIndex++);
      _fadeCtrl.forward(from: 0);
    } else {
      setState(() => _phase = _Phase.complete);
    }
  }

  void _tagOut() {
    HapticFeedback.heavyImpact();
    setState(() {
      _phase = _Phase.pickWorld;
      _narration = [];
      _currentNarrationIndex = 0;
    });
  }

  Future<void> _save() async {
    if (_narration.isEmpty) return;
    final username = UnifiedStorageService().getUsername('energie');
    final userId = await UnifiedStorageService().getCurrentUserId() ?? 'anonym';
    final saved = await SpiritReadingService.instance.save(
      userId: userId,
      username: username,
      tool: 'shamanic_journey',
      summary: '🥁 ${_world.label} · ${_question.isEmpty ? "Reise" : _question.substring(0, math.min(50, _question.length))}',
      result: {
        'world': _world.code,
        'question': _question,
        'narration': _narration,
      },
    );
    _history.insert(
        0,
        _JourneyHistory(
          world: _world.code,
          question: _question,
          createdAt: DateTime.now().toIso8601String(),
        ));
    if (_history.length > 30) _history = _history.sublist(0, 30);
    await _persistHistory();
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(saved != null
          ? '🥁 Reise im Akasha-Tagebuch + lokaler Verlauf'
          : '🥁 Lokal gespeichert (Cloud offline)'),
      backgroundColor: _world.color,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      extendBodyBehindAppBar: true,
      appBar: WBGlassAppBar(
        world: WBWorld.energie,
        titleWidget: ShaderMask(
          shaderCallback: (r) => LinearGradient(
            colors: [_gold, _world.color],
          ).createShader(r),
          child: const Text('SCHAMANISCHE REISE',
              style: TextStyle(color: Colors.white, fontSize: 13,
                  fontWeight: FontWeight.w900, letterSpacing: 2.5)),
        ),
        actions: [
          if (_phase == _Phase.complete)
            IconButton(
              icon: const Icon(Icons.bookmark_added_rounded, color: _gold),
              tooltip: 'Speichern',
              onPressed: _save,
            ),
          if (_phase != _Phase.pickWorld)
            IconButton(
              icon: const Icon(Icons.home_rounded, color: Colors.redAccent),
              tooltip: 'Zurück ins Hier',
              onPressed: _tagOut,
            ),
          if (_phase == _Phase.pickWorld && _history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.history_rounded, color: Colors.white),
              tooltip: 'Reise-Verlauf',
              onPressed: _showHistory,
            ),
        ],
      ),
      body: Stack(fit: StackFit.expand, children: [
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.2),
              radius: 1.5,
              colors: [
                _world.color.withValues(alpha: 0.3),
                _world.color.withValues(alpha: 0.08),
                _bg,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
        // Drum-Pulse-BG (Theta-Beat-Visual)
        if (_phase != _Phase.pickWorld)
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _drumCtrl,
              builder: (_, __) => CustomPaint(
                painter: _DrumPulsePainter(
                  t: _drumCtrl.value,
                  color: _world.color,
                ),
                size: Size.infinite,
              ),
            ),
          ),
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _ambientCtrl,
            builder: (_, __) => CustomPaint(
              painter: _ShamanicOrbsPainter(_ambientCtrl.value, _world.color),
              size: Size.infinite,
            ),
          ),
        ),
        const IgnorePointer(child: WBAmbientParticles(world: WBWorld.energie, count: 32)),
        SafeArea(child: _content()),
        const IgnorePointer(child: WBVignette()),
      ]),
    );
  }

  Widget _content() {
    switch (_phase) {
      case _Phase.pickWorld: return _pickWorldPhase();
      case _Phase.generating: return _generatingPhase();
      case _Phase.journeying: return _journeyingPhase();
      case _Phase.complete: return _completePhase();
    }
  }

  Widget _pickWorldPhase() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('FRAGE AN DEN GEIST',
                    style: TextStyle(color: _gold, fontSize: 10, letterSpacing: 3, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                TextField(
                  maxLines: 3, maxLength: 200,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Optional — was möchtest du auf der Reise erfahren?',
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
        const Text('WÄHLE DEINE WELT',
            style: TextStyle(color: _gold, fontSize: 11, letterSpacing: 3, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center),
        const SizedBox(height: 14),
        ..._worlds.map(_worldCard),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
          ),
          child: Row(children: [
            const Icon(Icons.shield_rounded, color: Colors.redAccent, size: 16),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Safety · Der "Zurück ins Hier"-Button bringt dich jederzeit zurück. Verlasse eine Reise, wenn sie unangenehm wird.',
                style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
              ),
            ),
          ]),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              textAlign: TextAlign.center),
        ],
      ],
    );
  }

  Widget _worldCard(_World w) {
    final sel = w.code == _world.code;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _world = w);
            Future.delayed(const Duration(milliseconds: 200), _startJourney);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: sel
                  ? LinearGradient(colors: [w.color.withValues(alpha: 0.35), w.color.withValues(alpha: 0.12)])
                  : null,
              color: sel ? null : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: sel ? w.color : Colors.white12),
              boxShadow: sel ? [BoxShadow(color: w.color.withValues(alpha: 0.4), blurRadius: 14, spreadRadius: 1)] : null,
            ),
            child: Row(children: [
              Text(w.emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(w.label,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 3),
                  Text(w.description,
                      style: const TextStyle(color: Colors.white60, fontSize: 11, height: 1.3),
                      maxLines: 3),
                ]),
              ),
              Icon(Icons.arrow_forward_rounded, color: w.color),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _generatingPhase() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        AnimatedBuilder(
          animation: _drumCtrl,
          builder: (_, __) {
            final pulse = 1.0 + 0.3 * _drumCtrl.value;
            return Transform.scale(
              scale: pulse,
              child: Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _world.color.withValues(alpha: 0.5),
                      _world.color.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Center(
                  child: Text(_world.emoji, style: const TextStyle(fontSize: 56)),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        Text('Trommel ruft die ${_world.label}…',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Der Pfad öffnet sich',
            style: TextStyle(color: Colors.white54, fontSize: 12, fontStyle: FontStyle.italic)),
      ]),
    );
  }

  Widget _journeyingPhase() {
    if (_narration.isEmpty) return const SizedBox.shrink();
    final idx = _currentNarrationIndex.clamp(0, _narration.length - 1);
    final text = _narration[idx];
    final label = idx < _phaseLabels.length ? _phaseLabels[idx] : '✨ PHASE ${idx + 1}';
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      child: Column(children: [
        // Phasen-Indikator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_narration.length, (i) {
            final active = i <= idx;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == idx ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: active ? _world.color : Colors.white24,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
        const SizedBox(height: 14),
        Text(label,
            style: TextStyle(color: _gold, fontSize: 11, letterSpacing: 3, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        FadeTransition(
          opacity: _fadeCtrl,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _world.color.withValues(alpha: 0.2),
                      Colors.white.withValues(alpha: 0.04),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _world.color.withValues(alpha: 0.3)),
                ),
                child: SelectableText(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.8,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _nextPhase,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text(idx < _narration.length - 1 ? 'WEITER · NÄCHSTE PHASE' : 'REISE BEENDEN',
                style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _world.color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _completePhase() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          AnimatedBuilder(
            animation: _ambientCtrl,
            builder: (_, __) => Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  _gold.withValues(alpha: 0.4 + 0.2 * math.sin(_ambientCtrl.value * 2 * math.pi)),
                  Colors.transparent,
                ]),
              ),
              child: const Center(child: Text('🌅', style: TextStyle(fontSize: 50))),
            ),
          ),
          const SizedBox(height: 18),
          ShaderMask(
            shaderCallback: (r) => LinearGradient(colors: [_gold, _world.color]).createShader(r),
            child: const Text('REISE VOLLENDET',
                style: TextStyle(color: Colors.white, fontSize: 22,
                    fontWeight: FontWeight.w900, letterSpacing: 3)),
          ),
          const SizedBox(height: 8),
          const Text('Du bist zurück. Atme tief, fühle den Boden unter dir.',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.bookmark_added_rounded, size: 18),
              label: const Text('IN AKASHA SPEICHERN',
                  style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _phase = _Phase.pickWorld;
                _narration = [];
                _currentNarrationIndex = 0;
              });
            },
            icon: const Icon(Icons.replay_rounded),
            label: const Text('NEUE REISE'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: BorderSide(color: Colors.white24),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ]),
      ),
    );
  }

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF120608),
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
            const Text('REISE-VERLAUF',
                style: TextStyle(color: _gold, fontSize: 12, letterSpacing: 3, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center),
            const SizedBox(height: 14),
            if (_history.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text('Noch keine Reisen.',
                    style: TextStyle(color: Colors.white54), textAlign: TextAlign.center),
              )
            else
              ..._history.map((h) {
                final w = _worlds.firstWhere((w) => w.code == h.world, orElse: () => _worlds[0]);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: w.color.withValues(alpha: 0.2)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(w.emoji, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 6),
                      Text(w.label,
                          style: TextStyle(color: w.color, fontSize: 12, fontWeight: FontWeight.w700)),
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
                );
              }),
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

enum _Phase { pickWorld, generating, journeying, complete }

class _World {
  final String code;
  final String label;
  final String emoji;
  final String description;
  final Color color;
  final String beingType;
  const _World(this.code, this.label, this.emoji, this.description, this.color, this.beingType);
}

const List<_World> _worlds = [
  _World('lower', 'Untere Welt', '🌳',
      'Erde, Wurzeln, Krafttiere. Hier triffst du verkörperte Weisheit der Natur — Tiere, Pflanzen, Steine sprechen zu dir.',
      Color(0xFF6D4C41), 'Ein Krafttier'),
  _World('middle', 'Mittlere Welt', '🌅',
      'Alltägliche Realität, Menschen, konkrete Lösungen. Hier suchst du Hilfe für hier-und-jetzt Fragen.',
      Color(0xFFFFB300), 'Ein weiser Mensch oder Berater'),
  _World('upper', 'Obere Welt', '✨',
      'Himmel, Sterne, Spirit-Guides, Ahnen. Hier empfängst du transpersonelle Botschaften und kosmische Perspektiven.',
      Color(0xFF7E57C2), 'Ein Spirit-Guide oder Ahn'),
];

class _JourneyHistory {
  final String world;
  final String question;
  final String createdAt;
  const _JourneyHistory({
    required this.world,
    required this.question,
    required this.createdAt,
  });
  Map<String, dynamic> toJson() => {
        'world': world, 'question': question, 'createdAt': createdAt,
      };
  factory _JourneyHistory.fromJson(Map<String, dynamic> j) => _JourneyHistory(
        world: j['world'] as String? ?? 'lower',
        question: j['question'] as String? ?? '',
        createdAt: j['createdAt'] as String? ?? '',
      );
}

// ── PAINTER: Theta-Drum-Pulse (~4 Hz) ────────────────────────────────────────
class _DrumPulsePainter extends CustomPainter {
  final double t; // 0..1, pulsiert mit drumCtrl
  final Color color;
  _DrumPulsePainter({required this.t, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.4);
    // 3 konzentrische Pulse-Ringe
    for (int i = 0; i < 3; i++) {
      final phase = ((t + i / 3.0) % 1.0);
      final r = 60 + phase * 200;
      final alpha = (1 - phase) * 0.15;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = color.withValues(alpha: alpha);
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(_DrumPulsePainter old) => old.t != t;
}

// ── PAINTER: Welt-Orbs ───────────────────────────────────────────────────────
class _ShamanicOrbsPainter extends CustomPainter {
  final double t;
  final Color worldColor;
  _ShamanicOrbsPainter(this.t, this.worldColor);

  @override
  void paint(Canvas canvas, Size size) {
    _draw(canvas, Offset(size.width * 0.2, size.height * (0.3 + math.sin(t * 2 * math.pi) * 0.05)),
        100, worldColor);
    _draw(canvas, Offset(size.width * 0.85, size.height * (0.55 + math.cos(t * 2 * math.pi) * 0.04)),
        90, const Color(0xFFFFB74D));
    _draw(canvas, Offset(size.width * 0.5, size.height * (0.92 + math.sin(t * math.pi) * 0.03)),
        70, worldColor.withRed(150));
  }

  void _draw(Canvas canvas, Offset c, double r, Color color) {
    final p = Paint()
      ..color = color.withValues(alpha: 0.10)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.5);
    canvas.drawCircle(c, r, p);
  }

  @override
  bool shouldRepaint(_ShamanicOrbsPainter old) => old.t != t || old.worldColor != worldColor;
}
