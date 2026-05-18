// 🔮 TAROT-ORAKEL · Cinematic Flip-Karten + AI-Lesung + Verlauf
//
// 3 Spreads: 1-Karte · 3-Karten (V/G/Z) · Keltisches Kreuz (10)
// Reversed-Cards: 35% Wahrscheinlichkeit, gespiegelte Bedeutung
// AI-Lesung: /api/mentor/chat (alchemist) verarbeitet die gezogenen Karten
// Speichern in spirit_readings (tool: 'tarot') + lokale History (SharedPrefs)

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

class TarotOracleScreen extends StatefulWidget {
  const TarotOracleScreen({super.key});

  @override
  State<TarotOracleScreen> createState() => _TarotOracleScreenState();
}

class _TarotOracleScreenState extends State<TarotOracleScreen>
    with TickerProviderStateMixin {
  static const Color _bg = Color(0xFF06040F);
  static const Color _primary = Color(0xFF8E5AE2);
  static const Color _accent = Color(0xFFEC407A);
  static const Color _gold = Color(0xFFFFD54F);
  static const String _kvKey = 'tarot_history_v1';

  _Phase _phase = _Phase.pickSpread;
  _Spread _spread = _spreads[0];
  String _question = '';
  List<_DrawnCard> _drawn = [];
  int _focusIndex = 0;
  String? _aiReading;
  bool _loadingAi = false;
  List<_TarotHistoryEntry> _history = [];

  late final AnimationController _ambientCtrl;
  late final AnimationController _shuffleCtrl;
  late final AnimationController _glowCtrl;

  @override
  void initState() {
    super.initState();
    _ambientCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 9),
    )..repeat();
    _shuffleCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2400),
    );
    _glowCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
    _loadHistory();
  }

  @override
  void dispose() {
    _ambientCtrl.dispose();
    _shuffleCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kvKey) ?? const [];
    final out = <_TarotHistoryEntry>[];
    for (final s in raw) {
      try {
        out.add(_TarotHistoryEntry.fromJson(jsonDecode(s) as Map<String, dynamic>));
      } catch (_) {}
    }
    if (mounted) setState(() => _history = out);
  }

  Future<void> _persistHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _history.take(30).map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_kvKey, list);
  }

  Future<void> _shuffleAndDraw() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _phase = _Phase.shuffling;
      _aiReading = null;
    });
    _shuffleCtrl.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 1600));

    final rand = math.Random();
    final deck = List<int>.generate(_majorArcana.length, (i) => i)..shuffle(rand);
    final picks = <_DrawnCard>[];
    for (int i = 0; i < _spread.count; i++) {
      final card = _majorArcana[deck[i]];
      final reversed = rand.nextDouble() < 0.35;
      picks.add(_DrawnCard(card: card, reversed: reversed, position: _spread.positions[i]));
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
      final cardsText = _drawn
          .map((d) =>
              '${d.position}: ${d.card.name}${d.reversed ? " (umgekehrt)" : ""} — ${d.card.meaning}')
          .join('\n');
      final prompt = StringBuffer()
        ..writeln('Lies das folgende Tarot-Legesystem für die Frage:')
        ..writeln('Frage: "${_question.isEmpty ? "Was darf ich heute wissen?" : _question}"')
        ..writeln('Spread: ${_spread.name}')
        ..writeln('Karten:')
        ..writeln(cardsText)
        ..writeln('')
        ..writeln('Lies in 4-6 Absätzen: erst Gesamtbild, dann Karte für Karte, '
            'dann konkrete Handlungsempfehlung. Schreib in der Du-Form, '
            'mit Wärme aber ohne Esoterik-Klischees.');
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
          _aiReading = '⚠️ AI-Lesung gerade nicht verfügbar (HTTP ${res.statusCode}). '
              'Lies die Karten selbst — die Bedeutungen stehen oben.';
          _loadingAi = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _aiReading = '⚠️ Netzwerk-Fehler beim AI-Service: $e';
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
      tool: 'tarot',
      summary: '${_spread.icon} ${_spread.name}: '
          '${_drawn.map((d) => d.card.name).join(", ")}',
      result: {
        'spread': _spread.code,
        'question': _question,
        'cards': _drawn
            .map((d) => {
                  'index': d.card.index,
                  'name': d.card.name,
                  'reversed': d.reversed,
                  'position': d.position,
                })
            .toList(),
        'ai_reading': _aiReading,
      },
    );
    // Lokale History
    _history.insert(
        0,
        _TarotHistoryEntry(
          spread: _spread.code,
          question: _question,
          cardNames: _drawn.map((d) => d.card.name).toList(),
          createdAt: DateTime.now().toIso8601String(),
        ));
    if (_history.length > 30) _history = _history.sublist(0, 30);
    await _persistHistory();
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(saved != null
          ? '🔮 Lesung im Akasha-Tagebuch + lokaler Verlauf'
          : '🔮 Lokal gespeichert (Cloud offline)'),
      backgroundColor: _primary,
    ));
  }

  void _reset() {
    setState(() {
      _phase = _Phase.pickSpread;
      _drawn = [];
      _aiReading = null;
      _question = '';
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
            colors: [_gold, _primary, _accent],
          ).createShader(r),
          child: const Text('TAROT-ORAKEL',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3)),
        ),
        actions: [
          if (_phase == _Phase.revealing && _drawn.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.bookmark_added_rounded, color: _gold),
              tooltip: 'Speichern',
              onPressed: _saveReading,
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              tooltip: 'Neue Lesung',
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
                center: Alignment(0, -0.4),
                radius: 1.5,
                colors: [
                  Color(0x554A148C),
                  Color(0x331A0A2E),
                  _bg,
                ],
              ),
            ),
          ),
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _ambientCtrl,
              builder: (_, __) => CustomPaint(
                painter: _TarotOrbsPainter(_ambientCtrl.value),
                size: Size.infinite,
              ),
            ),
          ),
          const IgnorePointer(
              child: WBAmbientParticles(world: WBWorld.energie, count: 38)),
          SafeArea(child: _buildContent()),
          const IgnorePointer(child: WBVignette()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_phase) {
      case _Phase.pickSpread:
        return _pickSpreadPhase();
      case _Phase.shuffling:
        return _shufflingPhase();
      case _Phase.revealing:
        return _revealPhase();
    }
  }

  Widget _pickSpreadPhase() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [_primary.withValues(alpha: 0.25), _accent.withValues(alpha: 0.08)]),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('STELLE EINE FRAGE',
                    style: TextStyle(color: _gold, fontSize: 10, letterSpacing: 3, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                TextField(
                  maxLines: 2,
                  maxLength: 140,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Optional — z.B. "Was darf ich loslassen?"',
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
        const Text('WÄHLE DEIN LEGESYSTEM',
            style: TextStyle(color: _gold, fontSize: 11, letterSpacing: 3, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center),
        const SizedBox(height: 14),
        ..._spreads.map((s) => _spreadCard(s)),
        if (_history.isNotEmpty) ...[
          const SizedBox(height: 18),
          Center(
            child: TextButton.icon(
              onPressed: _showHistory,
              icon: const Icon(Icons.history_rounded, color: Colors.white54, size: 16),
              label: Text('Verlauf · ${_history.length} Lesungen',
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _spreadCard(_Spread s) {
    final sel = s.code == _spread.code;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _spread = s);
            _shuffleAndDraw();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: sel
                  ? LinearGradient(colors: [_primary.withValues(alpha: 0.3), _accent.withValues(alpha: 0.15)])
                  : null,
              color: sel ? null : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: sel ? _primary : Colors.white12),
            ),
            child: Row(children: [
              Text(s.icon, style: const TextStyle(fontSize: 36)),
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
                  color: _gold.withValues(alpha: 0.15),
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
  }

  Widget _shufflingPhase() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        AnimatedBuilder(
          animation: _shuffleCtrl,
          builder: (_, __) {
            return SizedBox(
              width: 160,
              height: 220,
              child: Stack(
                children: List.generate(7, (i) {
                  final t = _shuffleCtrl.value;
                  final offset = math.sin((t * 4 + i * 0.5) * math.pi) * 30 * (1 - t);
                  final rotation = math.sin((t * 6 + i * 0.7) * math.pi) * 0.4 * (1 - t);
                  return Positioned(
                    left: 50 + offset,
                    top: 30 + i * 6.0 - i * t * 30,
                    child: Transform.rotate(
                      angle: rotation,
                      child: _cardBack(width: 60, height: 100),
                    ),
                  );
                }),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        const Text('Das Universum mischt deine Karten…',
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        const Text('Halte deine Frage im Herzen',
            style: TextStyle(color: Colors.white54, fontSize: 11, fontStyle: FontStyle.italic)),
      ]),
    );
  }

  Widget _revealPhase() {
    if (_drawn.isEmpty) return const SizedBox.shrink();
    final focused = _drawn[_focusIndex];

    return Column(children: [
      // Karten-Reihe (klein, scroll-bar)
      Container(
        height: 130,
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
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: selected
                        ? [BoxShadow(color: _primary.withValues(alpha: 0.6), blurRadius: 14, spreadRadius: 1)]
                        : null,
                  ),
                  child: _cardFace(d, mini: true, selected: selected),
                ),
              ),
            );
          },
        ),
      ),

      // Fokussierte Karte gross
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Column(children: [
            Text(focused.position.toUpperCase(),
                style: const TextStyle(color: _gold, fontSize: 10, letterSpacing: 3, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            _cardFace(focused, mini: false),
            const SizedBox(height: 14),
            Text(
              '${focused.card.name}${focused.reversed ? " — umgekehrt" : ""}',
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              focused.reversed ? focused.card.reversedMeaning : focused.card.meaning,
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            // AI-Lesung
            if (_aiReading == null && !_loadingAi)
              ElevatedButton.icon(
                onPressed: _requestAiReading,
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('AI-LESUNG ANFRAGEN',
                    style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
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
                        _primary.withValues(alpha: 0.5 + 0.3 * _glowCtrl.value),
                        Colors.transparent,
                      ]),
                    ),
                    child: const Center(child: Icon(Icons.auto_awesome, color: _gold, size: 28)),
                  ),
                ),
                const SizedBox(height: 10),
                const Text('Der Alchemist liest deine Karten…',
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
                      color: _primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _primary.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.auto_awesome_rounded, color: _gold, size: 18),
                          const SizedBox(width: 6),
                          const Text('ALCHEMIST · AI-LESUNG',
                              style: TextStyle(color: _gold, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w700)),
                        ]),
                        const SizedBox(height: 10),
                        SelectableText(_aiReading!,
                            style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.6)),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            if (_question.isNotEmpty) ...[
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
              const SizedBox(height: 14),
            ],
          ]),
        ),
      ),
    ]);
  }

  Widget _cardBack({double width = 100, double height = 160}) {
    return Container(
      width: width, height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF311B92), Color(0xFF4527A0), Color(0xFF1A0A2E)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _gold.withValues(alpha: 0.5), width: 1.2),
        boxShadow: [
          BoxShadow(color: _primary.withValues(alpha: 0.3), blurRadius: 8, spreadRadius: 1),
        ],
      ),
      child: Center(
        child: Text('☽', style: TextStyle(fontSize: width * 0.45, color: _gold.withValues(alpha: 0.7))),
      ),
    );
  }

  Widget _cardFace(_DrawnCard d, {bool mini = false, bool selected = false}) {
    final w = mini ? 60.0 : 180.0;
    final h = mini ? 95.0 : 280.0;
    return Transform.rotate(
      angle: d.reversed ? math.pi : 0,
      child: Container(
        width: w, height: h,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFF5E6D3),
              const Color(0xFFE8D4B8),
            ],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(mini ? 6 : 12),
          border: Border.all(color: selected ? _gold : _primary.withValues(alpha: 0.6), width: mini ? 1 : 2),
          boxShadow: [
            BoxShadow(color: _primary.withValues(alpha: 0.3), blurRadius: mini ? 6 : 16, spreadRadius: 1),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(d.card.emoji, style: TextStyle(fontSize: mini ? 28 : 80)),
            if (!mini) ...[
              const SizedBox(height: 10),
              Text(d.card.romanNumeral,
                  style: const TextStyle(color: Color(0xFF6A1B9A), fontSize: 16, fontWeight: FontWeight.bold)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(d.card.name,
                    style: const TextStyle(color: Color(0xFF4A148C), fontSize: 11, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0E0823),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
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
            const Text('LESUNGS-VERLAUF',
                style: TextStyle(color: _gold, fontSize: 12, letterSpacing: 3, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center),
            const SizedBox(height: 14),
            if (_history.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text('Noch keine Lesungen.',
                    style: TextStyle(color: Colors.white54), textAlign: TextAlign.center),
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
                        Text(_spreadIcon(h.spread), style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_spreadName(h.spread),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                        Text(_fmt(h.createdAt),
                            style: const TextStyle(color: Colors.white38, fontSize: 10)),
                      ]),
                      if (h.question.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('"${h.question}"',
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 11, fontStyle: FontStyle.italic),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ],
                      const SizedBox(height: 6),
                      Text(h.cardNames.join(' · '),
                          style: TextStyle(color: _primary.withValues(alpha: 0.9), fontSize: 11),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ]),
                  )),
          ],
        ),
      ),
    );
  }

  String _spreadIcon(String code) =>
      _spreads.firstWhere((s) => s.code == code, orElse: () => _spreads[0]).icon;
  String _spreadName(String code) =>
      _spreads.firstWhere((s) => s.code == code, orElse: () => _spreads[0]).name;
  String _fmt(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2,'0')}.${dt.month.toString().padLeft(2,'0')}.';
    } catch (_) { return ''; }
  }
}

enum _Phase { pickSpread, shuffling, revealing }

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
    'daily', 'Tageskarte', 'Eine Karte, eine Botschaft für heute', '🌅',
    1, ['Heute'],
  ),
  _Spread(
    'vgz', 'Vergangenheit · Gegenwart · Zukunft', 'Klassischer 3-Karten-Spread', '⚖️',
    3, ['Vergangenheit', 'Gegenwart', 'Zukunft'],
  ),
  _Spread(
    'celtic', 'Keltisches Kreuz', 'Tiefe 10-Karten-Lesung für komplexe Fragen', '✨',
    10, [
      'Gegenwart',
      'Herausforderung',
      'Wurzel/Vergangenheit',
      'Mögliche Zukunft',
      'Bewusstes Ziel',
      'Nahe Zukunft',
      'Dein Standpunkt',
      'Äußere Einflüsse',
      'Hoffnung/Furcht',
      'Endergebnis',
    ],
  ),
];

class _TarotCard {
  final int index;
  final String name;
  final String emoji;
  final String meaning;
  final String reversedMeaning;
  String get romanNumeral => _toRoman(index);
  const _TarotCard(this.index, this.name, this.emoji, this.meaning, this.reversedMeaning);
}

String _toRoman(int n) {
  const names = ['0','I','II','III','IV','V','VI','VII','VIII','IX','X','XI','XII','XIII','XIV','XV','XVI','XVII','XVIII','XIX','XX','XXI'];
  return n >= 0 && n < names.length ? names[n] : n.toString();
}

const List<_TarotCard> _majorArcana = [
  _TarotCard(0, 'Der Narr', '🃏',
      'Neuer Anfang, naives Vertrauen, Sprung ins Unbekannte. Offenheit für das Leben.',
      'Unverantwortlichkeit, Naivität ohne Erkenntnis, Vermeidung der Realität.'),
  _TarotCard(1, 'Der Magier', '🪄',
      'Willenskraft, Manifestation, alle 4 Werkzeuge liegen vor dir. Aktive Schöpfung.',
      'Manipulation, fehlende Konzentration, Talente werden missbraucht.'),
  _TarotCard(2, 'Die Hohepriesterin', '🌙',
      'Intuition, verborgenes Wissen, Stille als Weisheits-Quelle. Der innere Mond.',
      'Verdrängung der inneren Stimme, oberflächliche Antworten, Geheimnisse die schaden.'),
  _TarotCard(3, 'Die Herrscherin', '👑',
      'Fülle, Mutterprinzip, Schöpfung, sinnliche Lebenslust. Garten der Möglichkeiten.',
      'Erstickende Fürsorge, materielle Anhaftung, Kreativitäts-Blockade.'),
  _TarotCard(4, 'Der Herrscher', '🏛️',
      'Struktur, Vaterprinzip, klare Grenzen, Verantwortung übernehmen.',
      'Starre Tyrannei, Kontrollzwang, Machtmissbrauch.'),
  _TarotCard(5, 'Der Hierophant', '🔑',
      'Tradition, spirituelle Lehre, anerkannte Autorität, Initiation.',
      'Dogmatismus, blinder Gehorsam, Konventionen zerstören Authentizität.'),
  _TarotCard(6, 'Die Liebenden', '💞',
      'Wahl aus dem Herzen, Vereinigung, Werte-Entscheidung mit Konsequenz.',
      'Disharmonie, Bindungsangst, falsche Wahl aus Pflichtgefühl.'),
  _TarotCard(7, 'Der Wagen', '🏎️',
      'Willenstriumph, Vorwärtsbewegung, Beherrschung gegensätzlicher Kräfte.',
      'Kontrollverlust, planlose Aggression, Streit der inneren Kräfte.'),
  _TarotCard(8, 'Die Kraft', '🦁',
      'Sanfte innere Stärke, Mut ohne Aggression, Tier in dir liebevoll führen.',
      'Selbstzweifel, ungezähmte Wut, Schwäche durch falsche Bescheidenheit.'),
  _TarotCard(9, 'Der Eremit', '🕯️',
      'Rückzug zur Selbstfindung, innere Suche, Weisheit in der Stille.',
      'Isolation, lebensferner Rückzug, Einsamkeit als Mauer.'),
  _TarotCard(10, 'Schicksalsrad', '🎡',
      'Zyklen, Wandel, das Rad dreht sich — Glück oder Lektion folgen.',
      'Pech-Strähne als Vorwand, Verantwortung externalisieren, Stillstand.'),
  _TarotCard(11, 'Gerechtigkeit', '⚖️',
      'Karma, Wahrheit, Konsequenzen werden gewogen, kühle Klarheit.',
      'Ungerechtigkeit, voreingenommenes Urteil, Wahrheit gemieden.'),
  _TarotCard(12, 'Der Gehängte', '🙃',
      'Hingabe, Perspektivwechsel, freiwillige Pause, Erkenntnis durch Umkehr.',
      'Festhalten, Märtyrer-Komplex, sinnloses Aushalten ohne Erkenntnis.'),
  _TarotCard(13, 'Der Tod', '💀',
      'Transformation, das Alte stirbt damit Neues wachsen kann. Tor zwischen Welten.',
      'Wandel verweigert, festhalten am Verstorbenen, Stagnation.'),
  _TarotCard(14, 'Die Mäßigung', '🌈',
      'Alchemie, Synthese, der Mittelweg. Zwei Gegensätze fließen zusammen.',
      'Übertreibung, Disbalance, Extreme statt Synthese.'),
  _TarotCard(15, 'Der Teufel', '😈',
      'Anhaftung, selbstgewählte Ketten, materielle/emotionale Sucht erkennen.',
      'Befreiung aus Bindung, Ketten lösen sich, Sucht durchschaut.'),
  _TarotCard(16, 'Der Turm', '⚡',
      'Plötzlicher Bruch, Erleuchtung durch Krise, falsche Strukturen fallen.',
      'Bruch gemieden, langsame Erosion statt Befreiung, Krise eingedämmt.'),
  _TarotCard(17, 'Der Stern', '⭐',
      'Hoffnung, Inspiration, Heilung nach dem Sturm, Stille Klarheit.',
      'Hoffnungslosigkeit, ausgetrocknete Quellen, Glaubensverlust.'),
  _TarotCard(18, 'Der Mond', '🌑',
      'Unbewusstes, Illusionen, Träume, alte Ängste tauchen auf.',
      'Illusion durchschaut, Klarheit nach Unsicherheit, Träume entschlüsselt.'),
  _TarotCard(19, 'Die Sonne', '☀️',
      'Klarheit, Freude, vitale Lebenskraft, kindliche Begeisterung.',
      'Verzögerte Freude, Erfolg gedämpft, Energie nicht voll ausgelebt.'),
  _TarotCard(20, 'Das Gericht', '📯',
      'Erwachen, Ruf zu höherem Selbst, Neubewertung des Lebens.',
      'Selbsturteil, alte Reue, der Ruf wird nicht gehört.'),
  _TarotCard(21, 'Die Welt', '🌍',
      'Vollendung, Ganzheit, Zyklus abgeschlossen, Integration aller Erfahrungen.',
      'Unvollendung, Loslassen schwierig, neuer Zyklus zögert.'),
];

class _DrawnCard {
  final _TarotCard card;
  final bool reversed;
  final String position;
  const _DrawnCard({required this.card, required this.reversed, required this.position});
}

class _TarotHistoryEntry {
  final String spread;
  final String question;
  final List<String> cardNames;
  final String createdAt;
  const _TarotHistoryEntry({
    required this.spread,
    required this.question,
    required this.cardNames,
    required this.createdAt,
  });
  Map<String, dynamic> toJson() => {
        'spread': spread, 'question': question,
        'cards': cardNames, 'createdAt': createdAt,
      };
  factory _TarotHistoryEntry.fromJson(Map<String, dynamic> j) => _TarotHistoryEntry(
        spread: j['spread'] as String? ?? 'daily',
        question: j['question'] as String? ?? '',
        cardNames: ((j['cards'] as List?) ?? const []).cast<String>(),
        createdAt: j['createdAt'] as String? ?? '',
      );
}

// ── PAINTER: Tarot CineOrbs (Lila/Magenta/Gold) ─────────────────────────────
class _TarotOrbsPainter extends CustomPainter {
  final double t;
  _TarotOrbsPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    _draw(canvas, Offset(size.width * 0.2, size.height * (0.3 + math.sin(t * 2 * math.pi) * 0.05)),
        100, const Color(0xFF8E5AE2));
    _draw(canvas, Offset(size.width * 0.85, size.height * (0.55 + math.cos(t * 2 * math.pi) * 0.05)),
        110, const Color(0xFFEC407A));
    _draw(canvas, Offset(size.width * 0.5, size.height * (0.9 + math.sin(t * math.pi) * 0.04)),
        75, const Color(0xFFFFD54F));
  }

  void _draw(Canvas canvas, Offset c, double r, Color color) {
    final p = Paint()
      ..color = color.withValues(alpha: 0.10)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.5);
    canvas.drawCircle(c, r, p);
  }

  @override
  bool shouldRepaint(_TarotOrbsPainter old) => old.t != t;
}
