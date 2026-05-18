// 🌟 AFFIRMATIONEN-STUDIO · AI-Generator + Tageszeit + Combo-Sets + TTS
//
// Hyperrealistisch-cinematic: WBGlassAppBar mit ShaderMask, 5-Layer-BG,
// BackdropFilter-Karten.
//
// Features:
// - Tageszeit-Trigger: erkennt Morgens/Mittags/Abends, Vorschlag passend
// - 9 Kategorien (Erfolg, Liebe, Gesundheit, Spirit, Fülle, Selbstliebe,
//   Heilung, Mut, Frieden) jeweils mit eigenem Farb-Akkord
// - AI-Generator via Worker /api/mentor/chat (alchemist persona, 5–7
//   personalisierte Affirmationen pro Set)
// - Fallback auf statische Liste (SpiritToolsData) wenn Worker offline
// - Swipe-Cards 5–7 Affirmationen pro Set
// - TTS-Aussprache pro Karte (langsam, klar)
// - Speichern als Combo-Set in spirit_readings (tool: 'affirmation')

import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/api_config.dart';
import '../../../core/storage/unified_storage_service.dart';
import '../../../services/spirit_reading_service.dart';
import '../../../theme/wb_cinematic_tokens.dart';
import '../../../widgets/cinematic/wb_ambient_particles.dart';
import '../../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../../widgets/cinematic/wb_vignette.dart';

class AffirmationsStudioScreen extends StatefulWidget {
  const AffirmationsStudioScreen({super.key});

  @override
  State<AffirmationsStudioScreen> createState() => _AffirmationsStudioScreenState();
}

class _AffirmationsStudioScreenState extends State<AffirmationsStudioScreen>
    with TickerProviderStateMixin {
  static const Color _bg = Color(0xFF06030F);
  static const Color _gold = Color(0xFFFFD54F);

  late final FlutterTts _tts;
  late final PageController _pageCtrl;
  late final AnimationController _glowCtrl;
  late final AnimationController _ambientCtrl;

  _Category _selected = _categories[0];
  List<String> _affirmations = [];
  int _currentIndex = 0;
  bool _generating = false;
  bool _speakingIndex = false;
  String? _error;
  bool _aiUsed = false; // true wenn Worker geantwortet hat

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts();
    _setupTts();
    _pageCtrl = PageController();
    _glowCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _ambientCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 9),
    )..repeat();
    _autoSelectByTime();
  }

  @override
  void dispose() {
    _tts.stop();
    _pageCtrl.dispose();
    _glowCtrl.dispose();
    _ambientCtrl.dispose();
    super.dispose();
  }

  Future<void> _setupTts() async {
    await _tts.setLanguage('de-DE');
    await _tts.setSpeechRate(0.42); // langsam, klar
    await _tts.setPitch(0.95);
    await _tts.setVolume(1.0);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _speakingIndex = false);
    });
  }

  void _autoSelectByTime() {
    final h = DateTime.now().hour;
    final code = h < 11 ? 'morgen' : (h < 17 ? 'fokus' : 'abend');
    final match = _categories.firstWhere(
      (c) => c.code == code,
      orElse: () => _categories[0],
    );
    _selected = match;
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 5) return 'Tiefe Nacht';
    if (h < 11) return 'Guten Morgen';
    if (h < 14) return 'Mittagskraft';
    if (h < 18) return 'Nachmittag';
    if (h < 22) return 'Guter Abend';
    return 'Stille Stunde';
  }

  Future<void> _generate() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _generating = true;
      _error = null;
      _affirmations = [];
      _currentIndex = 0;
      _aiUsed = false;
    });
    // Versuch 1: AI über Worker
    try {
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
              'message':
                  'Erschaffe 6 kraftvolle deutsche Affirmationen im Bereich "${_selected.label}" '
                  '(${_selected.code}). Jede Affirmation ist 1 Satz, beginnt mit "Ich". '
                  'Verwende Gegenwartsform. Kein Disclaimer, keine Einleitung, '
                  'nur die 6 Sätze nummeriert 1. bis 6., jeweils auf einer Zeile.',
              'world': 'energie',
              'conversationHistory': [],
            }),
          )
          .timeout(const Duration(seconds: 25));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final answer = (data['answer'] ?? data['response'] ?? data['message'] ?? '') as String;
        final parsed = _parseAffirmations(answer);
        if (parsed.length >= 3) {
          if (mounted) {
            setState(() {
              _affirmations = parsed;
              _aiUsed = true;
              _generating = false;
            });
          }
          return;
        }
      }
    } catch (e) {
      // fall through to static
    }
    // Fallback: statisch
    final list = [..._selected.staticAffirmations]..shuffle(math.Random());
    if (mounted) {
      setState(() {
        _affirmations = list.take(6).toList();
        _aiUsed = false;
        _generating = false;
      });
    }
  }

  List<String> _parseAffirmations(String text) {
    // Findet nummerierte Zeilen "1. xxx" oder "1) xxx" oder "- xxx"
    final lines = text.split('\n');
    final out = <String>[];
    final re = RegExp(r'^\s*(\d+[\.\)\-]|\-|\*)\s*(.+)$');
    for (final l in lines) {
      final m = re.firstMatch(l);
      if (m != null) {
        var s = m.group(2)!.trim();
        if (s.length > 6 && s.length < 200) out.add(s);
      } else {
        final t = l.trim();
        if (t.startsWith('Ich ') && t.length < 200) out.add(t);
      }
    }
    return out.take(8).toList();
  }

  Future<void> _speak(int index) async {
    if (index < 0 || index >= _affirmations.length) return;
    HapticFeedback.lightImpact();
    setState(() => _speakingIndex = true);
    await _tts.stop();
    await _tts.speak(_affirmations[index]);
  }

  Future<void> _saveSet() async {
    if (_affirmations.isEmpty) return;
    final username = UnifiedStorageService().getUsername('energie');
    final userId = await UnifiedStorageService().getCurrentUserId() ?? 'anonym';
    final saved = await SpiritReadingService.instance.save(
      userId: userId,
      username: username,
      tool: 'affirmation',
      summary: '${_selected.emoji} ${_selected.label} · ${_affirmations.length} Affirmationen',
      result: {
        'category_code': _selected.code,
        'category_label': _selected.label,
        'affirmations': _affirmations,
        'ai_used': _aiUsed,
        'time_of_day': _greeting(),
      },
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(saved != null
          ? '✨ Affirmations-Set gespeichert'
          : '⚠️ Speichern fehlgeschlagen'),
      backgroundColor: saved != null ? _selected.primary : Colors.redAccent,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final hasResults = _affirmations.isNotEmpty;

    return Scaffold(
      backgroundColor: _bg,
      extendBodyBehindAppBar: true,
      appBar: WBGlassAppBar(
        world: WBWorld.energie,
        titleWidget: ShaderMask(
          shaderCallback: (r) => LinearGradient(
            colors: [_gold, _selected.primary, _selected.accent],
          ).createShader(r),
          child: const Text(
            'AFFIRMATIONS-STUDIO',
            style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 3),
          ),
        ),
        actions: [
          if (hasResults)
            IconButton(
              icon: const Icon(Icons.bookmark_added_rounded, color: _gold),
              tooltip: 'Set speichern',
              onPressed: _saveSet,
            ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Layer 1: Radial-Nebula passend zur Kategorie
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.3),
                radius: 1.4,
                colors: [
                  _selected.primary.withValues(alpha: 0.25),
                  _selected.accent.withValues(alpha: 0.12),
                  _bg,
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),
          // Layer 2: CineOrbs
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _ambientCtrl,
              builder: (_, __) => CustomPaint(
                painter: _AffirmOrbsPainter(
                  t: _ambientCtrl.value,
                  primary: _selected.primary,
                  accent: _selected.accent,
                ),
                size: Size.infinite,
              ),
            ),
          ),
          // Layer 3: Particles
          const IgnorePointer(
              child: WBAmbientParticles(world: WBWorld.energie, count: 40)),

          // Layer 4: Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                children: [
                  const SizedBox(height: 4),
                  _greetingCard(),
                  const SizedBox(height: 12),
                  _categoryPicker(),
                  const SizedBox(height: 14),
                  Expanded(
                    child: hasResults
                        ? _affirmationCards()
                        : _idleState(),
                  ),
                  const SizedBox(height: 8),
                  _generateButton(),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // Layer 5: Vignette
          const IgnorePointer(child: WBVignette()),
        ],
      ),
    );
  }

  Widget _greetingCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(children: [
            Text(_selected.emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_greeting(),
                      style: TextStyle(
                          color: _gold.withValues(alpha: 0.9),
                          fontSize: 10,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700)),
                  Text(_selected.label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            if (_aiUsed)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: _selected.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _selected.primary.withValues(alpha: 0.5)),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.auto_awesome, color: Colors.white, size: 11),
                  SizedBox(width: 3),
                  Text('AI', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                ]),
              ),
          ]),
        ),
      ),
    );
  }

  Widget _categoryPicker() {
    return SizedBox(
      height: 88,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (_, i) {
          final c = _categories[i];
          final sel = c.code == _selected.code;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selected = c;
                  _affirmations = [];
                  _aiUsed = false;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 80,
                decoration: BoxDecoration(
                  gradient: sel
                      ? LinearGradient(
                          colors: [c.primary, c.accent],
                          begin: Alignment.topLeft, end: Alignment.bottomRight)
                      : null,
                  color: sel ? null : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: sel ? Colors.transparent : Colors.white12,
                      width: sel ? 0 : 1),
                  boxShadow: sel
                      ? [
                          BoxShadow(
                            color: c.primary.withValues(alpha: 0.4),
                            blurRadius: 14,
                            spreadRadius: 1,
                          )
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(c.emoji, style: const TextStyle(fontSize: 26)),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(c.label,
                          style: TextStyle(
                              color: sel ? Colors.white : Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _idleState() {
    if (_generating) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _glowCtrl,
              builder: (_, __) {
                return Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _selected.primary.withValues(alpha: 0.4 + 0.4 * _glowCtrl.value),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(Icons.auto_awesome, color: _gold, size: 40 + 10 * _glowCtrl.value),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Text('Affirmationen werden erschaffen…',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
            const SizedBox(height: 6),
            const Text('Der Alchemist destilliert deine Kraft-Sätze',
                style: TextStyle(color: Colors.white38, fontSize: 11, fontStyle: FontStyle.italic)),
          ],
        ),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.format_quote_rounded,
                color: _selected.primary.withValues(alpha: 0.6), size: 70),
            const SizedBox(height: 16),
            Text(_selected.tagline,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    height: 1.5),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            const Text(
                'Tippe unten "Generieren" für 6 personalisierte\nAffirmationen — vom AI-Alchemisten oder klassisch.',
                style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.5),
                textAlign: TextAlign.center),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 11),
                  textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }

  Widget _affirmationCards() {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageCtrl,
            itemCount: _affirmations.length,
            onPageChanged: (i) {
              HapticFeedback.selectionClick();
              setState(() => _currentIndex = i);
              _tts.stop();
            },
            itemBuilder: (_, i) {
              final selected = i == _currentIndex;
              return AnimatedScale(
                scale: selected ? 1.0 : 0.92,
                duration: const Duration(milliseconds: 250),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _selected.primary.withValues(alpha: 0.18),
                              _selected.accent.withValues(alpha: 0.06),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                              color: _selected.primary.withValues(alpha: 0.4)),
                          boxShadow: [
                            BoxShadow(
                              color: _selected.primary.withValues(alpha: 0.25),
                              blurRadius: 28,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('${i + 1} / ${_affirmations.length}',
                                style: TextStyle(
                                    color: _gold.withValues(alpha: 0.7),
                                    fontSize: 10,
                                    letterSpacing: 3,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 22),
                            Icon(Icons.format_quote_rounded,
                                color: _gold.withValues(alpha: 0.5), size: 32),
                            const SizedBox(height: 14),
                            Expanded(
                              child: Center(
                                child: SelectableText(
                                  _affirmations[i],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    height: 1.55,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _speakingIndex && i == _currentIndex
                                      ? () => _tts.stop().then((_) => setState(() => _speakingIndex = false))
                                      : () => _speak(i),
                                  icon: Icon(
                                    _speakingIndex && i == _currentIndex
                                        ? Icons.stop_rounded
                                        : Icons.volume_up_rounded,
                                    size: 18,
                                  ),
                                  label: Text(_speakingIndex && i == _currentIndex
                                      ? 'Stop'
                                      : 'Sprechen'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _selected.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 18, vertical: 10),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                IconButton(
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: _affirmations[i]));
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                      content: const Text('📋 In Zwischenablage'),
                                      backgroundColor: _selected.accent,
                                      duration: const Duration(seconds: 2),
                                    ));
                                  },
                                  icon: Icon(Icons.copy_rounded, color: _gold.withValues(alpha: 0.8)),
                                  tooltip: 'Kopieren',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_affirmations.length, (i) {
            final sel = i == _currentIndex;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: sel ? 18 : 6, height: 6,
              decoration: BoxDecoration(
                color: sel ? _selected.primary : Colors.white24,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _generateButton() {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _generating ? null : _generate,
        icon: _generating
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.auto_awesome_rounded),
        label: Text(
          _generating
              ? 'Generiere…'
              : _affirmations.isEmpty
                  ? 'AFFIRMATIONEN GENERIEREN'
                  : 'NEUES SET GENERIEREN',
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.8),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _selected.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
    );
  }
}

// ── Kategorien (9 mit eigenem Farb-Akkord) ──────────────────────────────────
class _Category {
  final String code;
  final String label;
  final String emoji;
  final String tagline;
  final Color primary;
  final Color accent;
  final List<String> staticAffirmations;
  const _Category(this.code, this.label, this.emoji, this.tagline,
      this.primary, this.accent, this.staticAffirmations);
}

const List<_Category> _categories = [
  _Category(
    'morgen', 'Morgens', '🌅', 'Der Tag öffnet sich für dich.',
    Color(0xFFFFA726), Color(0xFFFFD54F),
    [
      'Ich begrüße diesen Tag mit offenem Herzen.',
      'Heute ziehe ich Gutes magnetisch an.',
      'Mein Körper ist ausgeruht und voller Energie.',
      'Ich vertraue dem Fluss des heutigen Tages.',
      'Mit jedem Atemzug werde ich präsenter.',
      'Heute zähle ich, was zählt — und übe gelassen.',
    ],
  ),
  _Category(
    'fokus', 'Fokus & Kraft', '⚡', 'Klarheit jetzt — Distraction später.',
    Color(0xFF26C6DA), Color(0xFF1976D2),
    [
      'Ich konzentriere mich auf das, was ich beeinflussen kann.',
      'Meine Gedanken sind klar und scharf.',
      'Ich erledige das Wichtige zuerst.',
      'Jeder Schritt vorwärts ist Sieg genug.',
      'Mein Verstand ist mein Verbündeter.',
      'Ich bin diszipliniert und liebevoll mit mir gleichzeitig.',
    ],
  ),
  _Category(
    'abend', 'Abends', '🌙', 'Loslassen ist eine heilige Kunst.',
    Color(0xFF7E57C2), Color(0xFF5E35B1),
    [
      'Ich entlasse den Tag, er hat seine Arbeit getan.',
      'Mein Körper sinkt in tiefe Erholung.',
      'Was ich nicht erledigt habe, war heute nicht meins.',
      'Mein Atem wird langsam, weich, weit.',
      'Ich vergebe mir alles, was ich noch festhalte.',
      'Heute Nacht heilt, was tagsüber müde wurde.',
    ],
  ),
  _Category(
    'liebe', 'Selbstliebe', '💖', 'Du darfst dich selbst meinen.',
    Color(0xFFEC407A), Color(0xFFAD1457),
    [
      'Ich bin wertvoll, allein weil ich bin.',
      'Ich darf Grenzen setzen und sie wahren.',
      'Mein Körper trägt mich durchs Leben — ich danke ihm.',
      'Ich liebe die Person, die ich gestern war.',
      'Selbstmitgefühl macht mich nicht weniger stark.',
      'Ich verdiene Zärtlichkeit von mir selbst.',
    ],
  ),
  _Category(
    'fuelle', 'Fülle', '🌾', 'Dankbarkeit zieht mehr Fülle an.',
    Color(0xFF66BB6A), Color(0xFF2E7D32),
    [
      'Ich nehme wahr, was ich habe — und es wächst.',
      'Geld fließt zu mir aus erwarteten und unerwarteten Quellen.',
      'Ich darf empfangen, ohne Schuldgefühl.',
      'Meine Großzügigkeit kehrt vervielfacht zurück.',
      'Ich erkenne Wert und biete Wert.',
      'Die Welt ist großzügig zu mir, weil ich es zulasse.',
    ],
  ),
  _Category(
    'heilung', 'Heilung', '🌿', 'Dein Körper kennt den Weg.',
    Color(0xFF26A69A), Color(0xFF00695C),
    [
      'Jede Zelle in mir erinnert sich an Gesundheit.',
      'Mein Körper heilt, während ich atme.',
      'Schmerz darf da sein, aber er definiert mich nicht.',
      'Ich höre auf die leisen Botschaften meines Körpers.',
      'Meine Reise zur Heilung ist sicher und stetig.',
      'Was vergangen wurde, darf jetzt weichen.',
    ],
  ),
  _Category(
    'mut', 'Mut', '🦁', 'Du hast schon Schlimmeres überstanden.',
    Color(0xFFFF7043), Color(0xFFBF360C),
    [
      'Ich bin mutiger als ich denke.',
      'Angst ist ein Kompass — sie zeigt, was wichtig ist.',
      'Ich gehe voran, auch wenn die Stimme leise wird.',
      'Jeder kleine Schritt baut mein Selbstvertrauen.',
      'Ich darf scheitern und es trotzdem versuchen.',
      'Mein nächstes Kapitel beginnt mit einem mutigen Atemzug.',
    ],
  ),
  _Category(
    'frieden', 'Frieden', '🕊️', 'Stille ist nicht leer — sie ist voll.',
    Color(0xFF9FA8DA), Color(0xFF5C6BC0),
    [
      'Ich gönne mir den Raum, nicht reagieren zu müssen.',
      'Mein Atem ist mein Anker.',
      'Was ich nicht ändern kann, lasse ich los.',
      'Konflikt im außen muss nicht Konflikt im innen sein.',
      'Stille ist eine erlaubte Antwort.',
      'Ich wähle Frieden, immer wieder.',
    ],
  ),
  _Category(
    'spirit', 'Spirit', '✨', 'Du bist nie allein.',
    Color(0xFFAB47BC), Color(0xFF7B1FA2),
    [
      'Ich vertraue dem unsichtbaren Plan, der mich trägt.',
      'Ich bin verbunden mit allem, was lebt.',
      'Mein höheres Selbst flüstert mir die richtige Richtung.',
      'Synchronizitäten sind Zeichen meines Weges.',
      'Ich bin Geist, der gerade einen Körper trägt.',
      'Mein Herz weiß, was mein Verstand noch nicht weiß.',
    ],
  ),
];

// ── PAINTER: 3 Orbs in Kategorie-Farben ──────────────────────────────────────
class _AffirmOrbsPainter extends CustomPainter {
  final double t;
  final Color primary;
  final Color accent;
  _AffirmOrbsPainter({required this.t, required this.primary, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    _draw(canvas, Offset(size.width * 0.18,
        size.height * (0.35 + math.sin(t * 2 * math.pi) * 0.05)), 100, primary);
    _draw(canvas, Offset(size.width * 0.86,
        size.height * (0.50 + math.cos(t * 2 * math.pi) * 0.04)), 90, accent);
    _draw(canvas, Offset(size.width * 0.50,
        size.height * (0.92 + math.sin(t * math.pi) * 0.03)), 75, primary);
  }

  void _draw(Canvas canvas, Offset c, double r, Color color) {
    final p = Paint()
      ..color = color.withValues(alpha: 0.10)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.5);
    canvas.drawCircle(c, r, p);
  }

  @override
  bool shouldRepaint(_AffirmOrbsPainter old) =>
      old.t != t || old.primary != primary || old.accent != accent;
}
