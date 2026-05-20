// ☯ I-GING-ORAKEL · cinematic Münzwurf + Wandlung + AI-Lesung + Journal
//
// 4-Phasen-Flow:
//   1. IDLE: User formuliert Frage, drückt 'Münzen werfen'
//   2. THROWING: 6 Linien × 3 Münzen werden animiert geworfen (~10s)
//   3. RESULT: Hexagramm + ggf. Wandlungs-Hexagramm + AI-Lesung
//   4. JOURNAL: Verlaufs-Liste aller Befragungen (lokal SharedPreferences)

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/api_config.dart';
import '../../../theme/wb_cinematic_tokens.dart';
import '../../../widgets/cinematic/wb_ambient_particles.dart';
import '../../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../../widgets/cinematic/wb_vignette.dart';
import '../../../data/iching_kingwen_64.dart';
import '../../../widgets/lesson_series_screen.dart';

enum _Phase { idle, throwing, result, journal }

class IChingOracleScreen extends StatefulWidget {
  const IChingOracleScreen({super.key});

  @override
  State<IChingOracleScreen> createState() => _IChingOracleScreenState();
}

class _IChingOracleScreenState extends State<IChingOracleScreen>
    with TickerProviderStateMixin {
  static const _bg = Color(0xFF050310);
  static const _primary = Color(0xFFB39DDB);
  static const _accent = Color(0xFF7C4DFF);
  static const _gold = Color(0xFFFFD54F);
  static const _kvKey = 'iching_journal_v1';

  late final AnimationController _bgCtrl;
  late final AnimationController _coinCtrl;

  _Phase _phase = _Phase.idle;
  final _questionCtrl = TextEditingController();
  int _currentLine = 0; // 0..5
  final List<int> _lineValues =
      []; // 6=alter Yin, 7=junges Yang, 8=junges Yin, 9=altes Yang
  String? _aiInterpretation;
  bool _aiLoading = false;
  List<_JournalEntry> _journal = [];

  @override
  void initState() {
    super.initState();
    _bgCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..repeat(reverse: true);
    _coinCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _loadJournal();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _coinCtrl.dispose();
    _questionCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadJournal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kvKey);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        _journal = list
            .map((e) => _JournalEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }
    if (mounted) setState(() {});
  }

  Future<void> _saveJournal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _kvKey, jsonEncode(_journal.map((e) => e.toJson()).toList()));
  }

  Future<void> _throwAll() async {
    setState(() {
      _phase = _Phase.throwing;
      _currentLine = 0;
      _lineValues.clear();
      _aiInterpretation = null;
    });
    for (var i = 0; i < 6; i++) {
      await _throwOneLine();
      setState(() => _currentLine = i + 1);
    }
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _phase = _Phase.result);
    await _saveCurrentToJournal();
  }

  Future<void> _throwOneLine() async {
    final rng = math.Random();
    _coinCtrl.reset();
    await _coinCtrl.forward();
    HapticFeedback.mediumImpact();
    // 3 Münzen, jede 2 oder 3 (Yin/Yang) → Summe 6/7/8/9
    var sum = 0;
    for (var i = 0; i < 3; i++) {
      sum += rng.nextBool() ? 2 : 3;
    }
    _lineValues.add(sum);
    await Future.delayed(const Duration(milliseconds: 250));
  }

  int _primaryHexIdx() {
    // Lines bottom-up. Build binary: yang=1, yin=0.
    // primary: 6→yin, 7→yang, 8→yin, 9→yang (alte werden zur Norm)
    var bin = 0;
    for (var i = 0; i < _lineValues.length; i++) {
      final v = _lineValues[i];
      final yang = v == 7 || v == 9;
      if (yang) bin |= (1 << i);
    }
    return _kingWenIndexFromBinary(bin);
  }

  int? _changingHexIdx() {
    // Nur wenn mindestens 1 alte Linie (6 oder 9) → Wandlung
    if (!_lineValues.any((v) => v == 6 || v == 9)) return null;
    var bin = 0;
    for (var i = 0; i < _lineValues.length; i++) {
      final v = _lineValues[i];
      // Alte Linien wandeln sich: 6→yang, 9→yin. Junge bleiben.
      final yang = v == 6 || v == 7;
      if (yang) bin |= (1 << i);
    }
    return _kingWenIndexFromBinary(bin);
  }

  // Binary (bottom-up, 6 bits) → King-Wen-Index (1..64)
  // Standard-Lookup nach Wilhelm. Vereinfachte Permutation:
  static const List<int> _kingWenLookup = [
    2,
    24,
    7,
    19,
    15,
    36,
    46,
    11,
    16,
    51,
    40,
    54,
    62,
    55,
    32,
    34,
    8,
    3,
    29,
    60,
    39,
    63,
    48,
    5,
    45,
    17,
    47,
    58,
    31,
    49,
    28,
    43,
    23,
    27,
    4,
    41,
    52,
    22,
    18,
    26,
    35,
    21,
    64,
    38,
    56,
    30,
    50,
    14,
    20,
    42,
    59,
    61,
    53,
    37,
    57,
    9,
    12,
    25,
    6,
    10,
    33,
    13,
    44,
    1,
  ];

  int _kingWenIndexFromBinary(int bin) {
    return _kingWenLookup[bin];
  }

  Future<void> _saveCurrentToJournal() async {
    final primaryIdx = _primaryHexIdx();
    final changingIdx = _changingHexIdx();
    _journal.insert(
        0,
        _JournalEntry(
          timestamp: DateTime.now(),
          question: _questionCtrl.text.trim(),
          primaryHex: primaryIdx,
          changingHex: changingIdx,
          changingLines: [
            for (var i = 0; i < _lineValues.length; i++)
              if (_lineValues[i] == 6 || _lineValues[i] == 9) i
          ],
        ));
    if (_journal.length > 50) _journal = _journal.sublist(0, 50);
    await _saveJournal();
  }

  Future<void> _runAILesung() async {
    setState(() => _aiLoading = true);
    final primary = ichingKingWen64[_primaryHexIdx() - 1];
    final changing = _changingHexIdx() != null
        ? ichingKingWen64[_changingHexIdx()! - 1]
        : null;
    final question = _questionCtrl.text.trim();

    final message = StringBuffer()
      ..writeln(
          'Meine Frage: ${question.isEmpty ? "(keine konkrete Frage)" : question}')
      ..writeln('')
      ..writeln('Primäres Hexagramm: ${primary.title} (${primary.subtitle})')
      ..writeln('Bedeutung: ${primary.meaning}');
    if (changing != null) {
      message
        ..writeln('')
        ..writeln(
            'Wandlungs-Hexagramm: ${changing.title} (${changing.subtitle})')
        ..writeln('Bedeutung: ${changing.meaning}');
    }
    message
      ..writeln('')
      ..writeln(
          'Bitte deute meine Befragung im Stil der Wilhelm-Übersetzung. Beziehe '
          'mich konkret auf meine Frage. Strukturiere: 1) Was die Situation jetzt zeigt '
          '2) Die richtige Haltung 3) Konkrete nächste Handlung.');

    try {
      final token =
          Supabase.instance.client.auth.currentSession?.accessToken ?? '';
      final uid = Supabase.instance.client.auth.currentUser?.id ?? '';
      final res = await http
          .post(
            Uri.parse('${ApiConfig.workerUrl}/api/mentor/chat'),
            headers: {
              'Content-Type': 'application/json',
              if (token.isNotEmpty) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'personality': 'heiler',
              'message': message.toString(),
              'conversationHistory': [],
              'world': 'energie',
              'userId': uid,
              'systemPrompt':
                  'Du bist ein erfahrener I-Ging-Deuter im Stil von Richard Wilhelm. '
                      'Du sprichst weise, knapp, mit konkreten Hinweisen. Du erkennst '
                      'die Symbolik der Trigramme und Linien-Wandlungen.',
              'mentorDisplayName': 'I-Ging-Deuter',
              'mentorAvatarEmoji': '☯',
            }),
          )
          .timeout(const Duration(seconds: 45));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final reply = (data['response'] as String?) ??
            (data['message'] as String?) ??
            (data['reply'] as String?);
        if (mounted) {
          setState(() => _aiInterpretation = reply ?? '(keine Antwort)');
        }
      } else {
        if (mounted) {
          setState(() => _aiInterpretation = 'Worker-Fehler ${res.statusCode}');
        }
      }
    } catch (e) {
      if (mounted) setState(() => _aiInterpretation = 'Netzwerk-Fehler: $e');
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  void _resetToIdle() {
    setState(() {
      _phase = _Phase.idle;
      _lineValues.clear();
      _currentLine = 0;
      _aiInterpretation = null;
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
          shaderCallback: (r) =>
              const LinearGradient(colors: [_gold, _accent]).createShader(r),
          child: const Text('I-GING ORAKEL',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3.2,
                  color: Colors.white)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: _gold),
            onPressed: () => setState(() => _phase = _Phase.journal),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _bgCtrl,
        builder: (_, child) => Stack(
          children: [
            Positioned.fill(
                child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(
                      0.4 - _bgCtrl.value * 0.5, -0.4 + _bgCtrl.value * 0.3),
                  radius: 1.4,
                  colors: [
                    _accent.withValues(alpha: 0.20),
                    _primary.withValues(alpha: 0.09),
                    const Color(0xFF050310),
                  ],
                  stops: const [0, 0.5, 1],
                ),
              ),
            )),
            Positioned(
                top: -100 + _bgCtrl.value * 60,
                right: -70,
                child: _orb(_accent, 360, 0.15 + _bgCtrl.value * 0.06)),
            Positioned(
                bottom: -120 + _bgCtrl.value * 40,
                left: -60,
                child: _orb(_primary, 300, 0.12)),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.45,
              left: MediaQuery.of(context).size.width * 0.3,
              child: _orb(_gold, 200, 0.08),
            ),
            const Positioned.fill(
                child: IgnorePointer(
                    child:
                        WBAmbientParticles(world: WBWorld.energie, count: 32))),
            const Positioned.fill(child: IgnorePointer(child: WBVignette())),
            child!,
          ],
        ),
        child: SafeArea(
          child: switch (_phase) {
            _Phase.idle => _buildIdle(),
            _Phase.throwing => _buildThrowing(),
            _Phase.result => _buildResult(),
            _Phase.journal => _buildJournal(),
          },
        ),
      ),
    );
  }

  Widget _buildIdle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      child: Column(
        children: [
          const SizedBox(height: 20),
          ShaderMask(
            shaderCallback: (r) =>
                const LinearGradient(colors: [_gold, _accent, _gold])
                    .createShader(r),
            child: const Text('☯',
                style: TextStyle(fontSize: 120, color: Colors.white, shadows: [
                  Shadow(color: Colors.black87, blurRadius: 32),
                ])),
          ),
          const SizedBox(height: 20),
          const Text('Stell deine Frage',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  border: Border.all(color: _accent.withValues(alpha: 0.35)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: _questionCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText:
                        'z.B. "Wie sollte ich mit dieser Veränderung umgehen?"',
                    hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 13),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _throwAll,
              icon: const Text('🪙', style: TextStyle(fontSize: 20)),
              label: const Text('MÜNZEN WERFEN · 6 LINIEN',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, letterSpacing: 1.8)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '3-Münzen-Methode · 6 Würfe von unten nach oben\nAlte Linien (6/9) wandeln sich zum zweiten Hexagramm',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 11, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildThrowing() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text('LINIE ${_currentLine + 1} VON 6',
              style: TextStyle(
                  color: _gold,
                  fontSize: 12,
                  letterSpacing: 3,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('Münzen fallen…',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 20),
          // Coin tumble animation
          SizedBox(
            height: 140,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 3; i++) ...[
                  AnimatedBuilder(
                    animation: _coinCtrl,
                    builder: (_, __) {
                      final phase = _coinCtrl.value;
                      final rotation = phase * math.pi * 8 + i * math.pi / 4;
                      final offsetY = (1 - math.sin(phase * math.pi)) * 80;
                      return Transform.translate(
                        offset: Offset(0, offsetY),
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.003)
                            ..rotateY(rotation),
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(colors: [
                                _gold,
                                _gold.withValues(alpha: 0.6)
                              ]),
                              boxShadow: [
                                BoxShadow(
                                  color: _gold.withValues(alpha: 0.6),
                                  blurRadius: 18,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text('☯',
                                  style: TextStyle(
                                      fontSize: 28, color: Colors.black87)),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  if (i < 2) const SizedBox(width: 14),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          // Schon geworfene Linien (von unten nach oben)
          for (var i = 5; i >= 0; i--)
            _renderLine(i, isPlaceholder: i >= _lineValues.length),
        ],
      ),
    );
  }

  Widget _renderLine(int idx, {required bool isPlaceholder}) {
    if (isPlaceholder) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        height: 6,
        width: 80,
        color: Colors.white.withValues(alpha: 0.06),
      );
    }
    final v = _lineValues[idx];
    final yang = v == 7 || v == 9;
    final changing = v == 6 || v == 9;
    if (yang) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        height: 6,
        width: 80,
        decoration: BoxDecoration(
          color: changing ? _gold : Colors.white,
          boxShadow: changing
              ? [BoxShadow(color: _gold.withValues(alpha: 0.7), blurRadius: 10)]
              : null,
        ),
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 3),
            height: 6,
            width: 35,
            decoration: BoxDecoration(
              color: changing ? _gold : Colors.white,
              boxShadow: changing
                  ? [
                      BoxShadow(
                          color: _gold.withValues(alpha: 0.7), blurRadius: 10)
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 3),
            height: 6,
            width: 35,
            decoration: BoxDecoration(
              color: changing ? _gold : Colors.white,
              boxShadow: changing
                  ? [
                      BoxShadow(
                          color: _gold.withValues(alpha: 0.7), blurRadius: 10)
                    ]
                  : null,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildResult() {
    final primaryIdx = _primaryHexIdx();
    final changingIdx = _changingHexIdx();
    final primary = ichingKingWen64[primaryIdx - 1];
    final changing =
        changingIdx != null ? ichingKingWen64[changingIdx - 1] : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_questionCtrl.text.trim().isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Text('"${_questionCtrl.text.trim()}"',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontStyle: FontStyle.italic)),
            ),
          _hexCard('PRIMÄRES HEXAGRAMM', primary, _lineValues,
              isChanging: false),
          if (changing != null) ...[
            const SizedBox(height: 14),
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _gold.withValues(alpha: 0.5)),
                ),
                child: const Text('↓ wandelt sich zu ↓',
                    style: TextStyle(
                        color: _gold,
                        fontSize: 11,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 14),
            _hexCard('WANDLUNGS-HEXAGRAMM', changing, _lineValues,
                isChanging: true),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _gold.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _gold.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'SICH WANDELNDE LINIEN (${_lineValues.where((v) => v == 6 || v == 9).length})',
                      style: const TextStyle(
                          color: _gold,
                          fontSize: 10,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  for (var i = 0; i < _lineValues.length; i++)
                    if (_lineValues[i] == 6 || _lineValues[i] == 9)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          'Linie ${i + 1} (${_lineValues[i] == 9 ? "Altes Yang" : "Altes Yin"}): '
                          '${_lineValues[i] == 9 ? "Voll-ausgereiftes Yang wandelt sich zu Yin — das Maximum kippt." : "Voll-ausgereiftes Yin wandelt sich zu Yang — die Stille bricht auf."}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12, height: 1.4),
                        ),
                      ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          // AI-Lesung
          if (_aiInterpretation == null && !_aiLoading)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _runAILesung,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('AI-LESUNG (WILHELM-STIL)',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          if (_aiLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: _gold),
              ),
            ),
          if (_aiInterpretation != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  _gold.withValues(alpha: 0.15),
                  _accent.withValues(alpha: 0.08)
                ]),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _gold.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Text('🪶', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 6),
                    Text('AI-LESUNG',
                        style: TextStyle(
                            color: _gold,
                            fontSize: 11,
                            letterSpacing: 2.5,
                            fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 10),
                  SelectableText(_aiInterpretation!,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13.5, height: 1.6)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: _resetToIdle,
            icon: const Icon(Icons.refresh, color: _accent),
            label:
                const Text('Neue Befragung', style: TextStyle(color: _accent)),
            style: OutlinedButton.styleFrom(
                side: BorderSide(color: _accent.withValues(alpha: 0.5))),
          ),
        ],
      ),
    );
  }

  Widget _hexCard(String label, LessonSeriesEntry hex, List<int> lines,
      {required bool isChanging}) {
    final binaryYang = isChanging
        ? <bool>[
            for (var i = 0; i < lines.length; i++)
              lines[i] == 6 || lines[i] == 7
          ]
        : <bool>[
            for (var i = 0; i < lines.length; i++)
              lines[i] == 7 || lines[i] == 9
          ];
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            border: Border.all(color: _accent.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: _accent.withValues(alpha: 0.25),
                  blurRadius: 20,
                  spreadRadius: -4),
            ],
          ),
          child: Column(
            children: [
              Text(label,
                  style: TextStyle(
                      color: _gold,
                      fontSize: 10,
                      letterSpacing: 2.5,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(hex.symbol,
                  style: const TextStyle(fontSize: 64, color: _gold, shadows: [
                    Shadow(color: Colors.black87, blurRadius: 14)
                  ])),
              const SizedBox(height: 8),
              ShaderMask(
                shaderCallback: (r) =>
                    const LinearGradient(colors: [_gold, _accent])
                        .createShader(r),
                child: Text(hex.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ),
              Text(hex.subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontStyle: FontStyle.italic)),
              const SizedBox(height: 14),
              // 6 Linien von oben (idx 5) nach unten (idx 0)
              for (var i = 5; i >= 0; i--) _staticLine(binaryYang[i]),
              const SizedBox(height: 14),
              Text(hex.meaning,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 13, height: 1.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _staticLine(bool yang) {
    if (yang) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        height: 5,
        width: 90,
        color: Colors.white,
      );
    }
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          height: 5,
          width: 40,
          color: Colors.white),
      const SizedBox(width: 10),
      Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          height: 5,
          width: 40,
          color: Colors.white),
    ]);
  }

  Widget _buildJournal() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          Row(children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => setState(() => _phase = _Phase.idle),
            ),
            Text('VERLAUF · ${_journal.length} BEFRAGUNGEN',
                style: TextStyle(
                    color: _gold,
                    fontSize: 12,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold)),
          ]),
          Expanded(
            child: _journal.isEmpty
                ? const Center(
                    child: Text('Noch keine Befragungen',
                        style: TextStyle(color: Colors.white60)))
                : ListView.builder(
                    itemCount: _journal.length,
                    itemBuilder: (_, i) {
                      final e = _journal[i];
                      final hex = ichingKingWen64[e.primaryHex - 1];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: _accent.withValues(alpha: 0.2)),
                        ),
                        child: Row(children: [
                          Text(hex.symbol,
                              style:
                                  const TextStyle(fontSize: 32, color: _gold)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    '${e.timestamp.day}.${e.timestamp.month}.${e.timestamp.year}',
                                    style: TextStyle(
                                        color: _accent,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600)),
                                Text(hex.title,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold)),
                                if (e.question.isNotEmpty)
                                  Text('"${e.question}"',
                                      style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                          fontStyle: FontStyle.italic),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
                                if (e.changingHex != null)
                                  Text(
                                      '→ ${ichingKingWen64[e.changingHex! - 1].title}',
                                      style: TextStyle(
                                          color: _gold.withValues(alpha: 0.8),
                                          fontSize: 10)),
                              ],
                            ),
                          ),
                        ]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _orb(Color color, double size, double opacity) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: opacity * 0.4),
            color.withValues(alpha: 0),
          ]),
        ),
      ),
    );
  }
}

class _JournalEntry {
  final DateTime timestamp;
  final String question;
  final int primaryHex;
  final int? changingHex;
  final List<int> changingLines;
  const _JournalEntry({
    required this.timestamp,
    required this.question,
    required this.primaryHex,
    this.changingHex,
    required this.changingLines,
  });
  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'question': question,
        'primaryHex': primaryHex,
        'changingHex': changingHex,
        'changingLines': changingLines,
      };
  factory _JournalEntry.fromJson(Map<String, dynamic> j) => _JournalEntry(
        timestamp: DateTime.parse(j['timestamp'] as String),
        question: j['question'] as String? ?? '',
        primaryHex: (j['primaryHex'] as num).toInt(),
        changingHex: (j['changingHex'] as num?)?.toInt(),
        changingLines: ((j['changingLines'] as List?)?.cast<num>() ?? const [])
            .map((e) => e.toInt())
            .toList(),
      );
}
