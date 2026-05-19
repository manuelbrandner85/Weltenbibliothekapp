// Welt-Quiz: 7-question personality quiz that maps the user to one of four
// symbolic "worlds" (Glitch, Mars, Spiegel, Quanten). Replaces the previous
// 60-second glitch effect which lacked clear user intent. Cinematic styling
// stays consistent with WBGlassAppBar / WBAmbientParticles / WBVignette.

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/wb_cinematic_tokens.dart';
import '../../widgets/cinematic/wb_ambient_particles.dart';
import '../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../widgets/cinematic/wb_vignette.dart';

// ---------------------------------------------------------------------------
// Domain models
// ---------------------------------------------------------------------------

/// The four symbolic worlds that a user can land in.
enum QuizWorld { glitch, mars, spiegel, quanten }

/// Static metadata for a [QuizWorld]. Plain class instead of records to keep
/// dart2js compilation safe and readable.
class QuizWorldInfo {
  const QuizWorldInfo({
    required this.world,
    required this.name,
    required this.emoji,
    required this.color,
    required this.description,
  });

  final QuizWorld world;
  final String name;
  final String emoji;
  final Color color;
  final String description;
}

/// One answer option of a question. Picking it grants +1 point to [world].
class QuizOption {
  const QuizOption({required this.label, required this.world});

  final String label;
  final QuizWorld world;
}

/// A single quiz question with exactly four [options].
class QuizQuestion {
  // NOTE: dart2js kann List.length im const-Kontext nicht evaluieren - daher
  // KEIN assert hier. Alle Fragen oben haben per Convention 4 Optionen.
  const QuizQuestion({required this.prompt, required this.options});

  final String prompt;
  final List<QuizOption> options;
}

/// Persisted quiz result, serialised as JSON in SharedPreferences.
class QuizResult {
  const QuizResult({
    required this.world,
    required this.scores,
    required this.timestamp,
  });

  final QuizWorld world;
  final Map<QuizWorld, int> scores;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'world': world.name,
        'scores': <String, int>{
          for (final entry in scores.entries) entry.key.name: entry.value,
        },
        'date': timestamp.toIso8601String(),
      };

  static QuizResult? fromJson(Map<String, dynamic> json) {
    try {
      final worldName = json['world'] as String?;
      final dateStr = json['date'] as String?;
      final rawScores = json['scores'] as Map<String, dynamic>?;
      if (worldName == null || dateStr == null || rawScores == null) {
        return null;
      }
      final world = QuizWorld.values.firstWhere(
        (w) => w.name == worldName,
        orElse: () => QuizWorld.glitch,
      );
      final scores = <QuizWorld, int>{
        for (final w in QuizWorld.values)
          w: (rawScores[w.name] as num?)?.toInt() ?? 0,
      };
      return QuizResult(
        world: world,
        scores: scores,
        timestamp: DateTime.tryParse(dateStr) ?? DateTime.now(),
      );
    } on Object {
      return null;
    }
  }
}

// ---------------------------------------------------------------------------
// Static catalogue
// ---------------------------------------------------------------------------

const Map<QuizWorld, QuizWorldInfo> _kWorldInfo = <QuizWorld, QuizWorldInfo>{
  QuizWorld.glitch: QuizWorldInfo(
    world: QuizWorld.glitch,
    name: 'Glitch-Welt',
    emoji: '🌀',
    color: Color(0xFF00BCD4),
    description:
        'Du erkennst Risse im Alltag. Realität ist für dich Verhandlungssache.',
  ),
  QuizWorld.mars: QuizWorldInfo(
    world: QuizWorld.mars,
    name: 'Mars-Welt',
    emoji: '🪐',
    color: Color(0xFFE53935),
    description:
        'Du suchst das Neue, das Pionierhafte. Hier ist nichts vorbestimmt.',
  ),
  QuizWorld.spiegel: QuizWorldInfo(
    world: QuizWorld.spiegel,
    name: 'Spiegel-Welt',
    emoji: '🪞',
    color: Color(0xFF7C4DFF),
    description:
        'Du findest Wahrheit über Selbstreflexion. Alles aussen ist ein Innen-Spiegel.',
  ),
  QuizWorld.quanten: QuizWorldInfo(
    world: QuizWorld.quanten,
    name: 'Quanten-Welt',
    emoji: '⚛️',
    color: Color(0xFFFFD700),
    description:
        'Du lebst in Möglichkeiten. Jede Entscheidung schafft eine neue Realität.',
  ),
};

const List<QuizQuestion> _kQuestions = <QuizQuestion>[
  QuizQuestion(
    prompt: 'Du wachst um 3:33 Uhr auf. Was denkst du?',
    options: <QuizOption>[
      QuizOption(
        label: 'Schon wieder dieselbe Zahl. Die Simulation flackert.',
        world: QuizWorld.glitch,
      ),
      QuizOption(
        label: 'Perfekte Zeit, um etwas zu beginnen, das niemand erwartet.',
        world: QuizWorld.mars,
      ),
      QuizOption(
        label: 'Etwas in mir wollte gerade gesehen werden.',
        world: QuizWorld.spiegel,
      ),
      QuizOption(
        label: 'Irgendwo entstehen jetzt drei Versionen dieser Nacht.',
        world: QuizWorld.quanten,
      ),
    ],
  ),
  QuizQuestion(
    prompt: 'Du triffst eine wichtige Entscheidung. Worauf hörst du?',
    options: <QuizOption>[
      QuizOption(
        label: 'Auf das, was hartnäckig in mir bleibt, wenn alles still wird.',
        world: QuizWorld.spiegel,
      ),
      QuizOption(
        label: 'Auf die Option, die niemand sonst gewählt hätte.',
        world: QuizWorld.mars,
      ),
      QuizOption(
        label: 'Auf die Variante, die noch die meisten Türen offen lässt.',
        world: QuizWorld.quanten,
      ),
      QuizOption(
        label: 'Auf das seltsame Gefühl, dass eigentlich keine echt ist.',
        world: QuizWorld.glitch,
      ),
    ],
  ),
  QuizQuestion(
    prompt: 'Beim Spazieren siehst du dieselbe Zahl dreimal hintereinander. '
        'Reaktion?',
    options: <QuizOption>[
      QuizOption(
        label: 'Der Code hat einen Bug — und ich sehe ihn gerade.',
        world: QuizWorld.glitch,
      ),
      QuizOption(
        label: 'Das Universum nudgt mich. Ich frage es zurück.',
        world: QuizWorld.quanten,
      ),
      QuizOption(
        label: 'Spiegelt mir, woran ich gerade nicht denken will.',
        world: QuizWorld.spiegel,
      ),
      QuizOption(
        label: 'Zufall. Ich gehe weiter und entdecke etwas Neues.',
        world: QuizWorld.mars,
      ),
    ],
  ),
  QuizQuestion(
    prompt: 'Was bedeutet "Heimat" für dich?',
    options: <QuizOption>[
      QuizOption(
        label: 'Ein Ort, den ich noch nicht erreicht habe.',
        world: QuizWorld.mars,
      ),
      QuizOption(
        label: 'Die Stille zwischen meinen eigenen Gedanken.',
        world: QuizWorld.spiegel,
      ),
      QuizOption(
        label: 'Jede mögliche Version meines Lebens gleichzeitig.',
        world: QuizWorld.quanten,
      ),
      QuizOption(
        label:
            'Ein Gefühl, das jeden Moment zerbrechen könnte — und schön ist.',
        world: QuizWorld.glitch,
      ),
    ],
  ),
  QuizQuestion(
    prompt: 'Ein Fremder sagt dir etwas seltsam Wichtiges. Was tust du?',
    options: <QuizOption>[
      QuizOption(
        label: 'Ich höre genau hin — das war kein Zufall.',
        world: QuizWorld.quanten,
      ),
      QuizOption(
        label: 'Ich frage mich, welcher Teil von mir gerade angesprochen wird.',
        world: QuizWorld.spiegel,
      ),
      QuizOption(
        label: 'Ich notiere es. Vielleicht ist es ein Hinweis im System.',
        world: QuizWorld.glitch,
      ),
      QuizOption(
        label: 'Ich frage zurück und gehe mit ihm einen Schritt weiter.',
        world: QuizWorld.mars,
      ),
    ],
  ),
  QuizQuestion(
    prompt: 'Wie sieht für dich das Universum aus?',
    options: <QuizOption>[
      QuizOption(
        label: 'Wie ein riesiges, leicht fehlerhaftes Rendering.',
        world: QuizWorld.glitch,
      ),
      QuizOption(
        label: 'Wie ein leeres Notizbuch, das ich beschreiben darf.',
        world: QuizWorld.mars,
      ),
      QuizOption(
        label: 'Wie ein Spiegel, der mir mein eigenes Bewusstsein zeigt.',
        world: QuizWorld.spiegel,
      ),
      QuizOption(
        label: 'Wie ein Akkord aus Möglichkeiten, der nie ganz auflöst.',
        world: QuizWorld.quanten,
      ),
    ],
  ),
  QuizQuestion(
    prompt: 'Welcher Satz beschreibt dich am besten?',
    options: <QuizOption>[
      QuizOption(
        label: '"Ich glaube nicht alles, was ich sehe — selbst mich selbst."',
        world: QuizWorld.glitch,
      ),
      QuizOption(
        label: '"Wo niemand vorher war, atme ich am leichtesten."',
        world: QuizWorld.mars,
      ),
      QuizOption(
        label:
            '"Jede Person, die mich nervt, kennt mich besser als ich denke."',
        world: QuizWorld.spiegel,
      ),
      QuizOption(
        label: '"Ich entscheide mich selten endgültig. Das ist Methode."',
        world: QuizWorld.quanten,
      ),
    ],
  ),
];

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

enum _ScreenPhase { intro, quiz, result }

class RealitaetsHopperScreen extends StatefulWidget {
  const RealitaetsHopperScreen({super.key});

  @override
  State<RealitaetsHopperScreen> createState() => _RealitaetsHopperScreenState();
}

class _RealitaetsHopperScreenState extends State<RealitaetsHopperScreen>
    with TickerProviderStateMixin {
  static const String _prefsKey = 'welt_quiz_result_v1';

  late final AnimationController _ambientCtrl;
  late final AnimationController _questionCtrl;
  late final AnimationController _resultCtrl;

  _ScreenPhase _phase = _ScreenPhase.intro;
  int _currentIndex = 0;
  final Map<QuizWorld, int> _scores = <QuizWorld, int>{
    for (final w in QuizWorld.values) w: 0,
  };
  QuizResult? _lastResult;
  QuizResult? _currentResult;

  @override
  void initState() {
    super.initState();
    _ambientCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
    _questionCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _resultCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _loadLastResult();
  }

  @override
  void dispose() {
    _ambientCtrl.dispose();
    _questionCtrl.dispose();
    _resultCtrl.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Persistence
  // -------------------------------------------------------------------------

  Future<void> _loadLastResult() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return;
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final parsed = QuizResult.fromJson(decoded);
        if (mounted && parsed != null) {
          setState(() => _lastResult = parsed);
        }
      }
    } on Object {
      // Ignore corrupt cache entries -- quiz still works fresh.
    }
  }

  Future<void> _persistResult(QuizResult result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(result.toJson()));
    } on Object {
      // Persistence failure is non-fatal.
    }
  }

  // -------------------------------------------------------------------------
  // Flow control
  // -------------------------------------------------------------------------

  void _startQuiz() {
    HapticFeedback.selectionClick();
    setState(() {
      _phase = _ScreenPhase.quiz;
      _currentIndex = 0;
      for (final w in QuizWorld.values) {
        _scores[w] = 0;
      }
    });
    _questionCtrl
      ..reset()
      ..forward();
  }

  Future<void> _answerSelected(QuizOption option) async {
    HapticFeedback.selectionClick();
    _scores[option.world] = (_scores[option.world] ?? 0) + 1;

    if (_currentIndex >= _kQuestions.length - 1) {
      await _finishQuiz();
      return;
    }

    await _questionCtrl.reverse();
    if (!mounted) return;
    setState(() => _currentIndex += 1);
    _questionCtrl.forward();
  }

  Future<void> _finishQuiz() async {
    // Determine winning world. On ties, prefer order in enum to stay stable.
    QuizWorld winner = QuizWorld.glitch;
    int best = -1;
    for (final w in QuizWorld.values) {
      final score = _scores[w] ?? 0;
      if (score > best) {
        best = score;
        winner = w;
      }
    }

    final result = QuizResult(
      world: winner,
      scores: Map<QuizWorld, int>.from(_scores),
      timestamp: DateTime.now(),
    );

    await _persistResult(result);
    HapticFeedback.mediumImpact();

    if (!mounted) return;
    setState(() {
      _phase = _ScreenPhase.result;
      _currentResult = result;
      _lastResult = result;
    });
    _resultCtrl
      ..reset()
      ..forward();
  }

  Future<void> _share(QuizResult result) async {
    final info = _kWorldInfo[result.world]!;
    final text =
        'Mein Weltenbibliothek-Welt-Quiz-Ergebnis: ${info.emoji} ${info.name} '
        '(${info.description}) -- Mach das Quiz auch: weltenbibliothek.app';

    try {
      await Share.share(text, subject: 'Mein Welt-Quiz-Ergebnis');
    } on Object {
      // Fallback: clipboard + snackbar.
      await Clipboard.setData(ClipboardData(text: text));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('In Zwischenablage kopiert'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF05060A),
      appBar: WBGlassAppBar(
        world: WBWorld.vorhang,
        titleWidget: ShaderMask(
          shaderCallback: (rect) => const LinearGradient(
            colors: <Color>[Color(0xFFFFD700), Color(0xFF7C4DFF)],
          ).createShader(rect),
          child: const Text(
            'WELT-QUIZ',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
              fontSize: 18,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: <Widget>[
          const _AmbientBackground(),
          AnimatedBuilder(
            animation: _ambientCtrl,
            builder: (context, _) => _OrbsLayer(progress: _ambientCtrl.value),
          ),
          const WBAmbientParticles(
            world: WBWorld.vorhang,
            count: 50,
          ),
          const WBVignette(),
          SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _buildPhase(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhase() {
    switch (_phase) {
      case _ScreenPhase.intro:
        return _IntroView(
          key: const ValueKey<String>('intro'),
          lastResult: _lastResult,
          onStart: _startQuiz,
        );
      case _ScreenPhase.quiz:
        final q = _kQuestions[_currentIndex];
        return _QuizView(
          key: ValueKey<int>(_currentIndex),
          question: q,
          index: _currentIndex,
          total: _kQuestions.length,
          animation: _questionCtrl,
          onSelected: _answerSelected,
        );
      case _ScreenPhase.result:
        final result = _currentResult;
        if (result == null) {
          // Defensive: should not happen, but fall back to intro.
          return _IntroView(
            key: const ValueKey<String>('intro-fallback'),
            lastResult: _lastResult,
            onStart: _startQuiz,
          );
        }
        return _ResultView(
          key: const ValueKey<String>('result'),
          result: result,
          animation: _resultCtrl,
          onShare: () => _share(result),
          onRetry: _startQuiz,
        );
    }
  }
}

// ---------------------------------------------------------------------------
// Background layers
// ---------------------------------------------------------------------------

class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.2, -0.4),
          radius: 1.4,
          colors: <Color>[
            Color(0xFF1A1230),
            Color(0xFF0A0A18),
            Color(0xFF02030A),
          ],
          stops: <double>[0.0, 0.55, 1.0],
        ),
      ),
      child: SizedBox.expand(),
    );
  }
}

class _OrbsLayer extends StatelessWidget {
  const _OrbsLayer({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final t = progress * 2 * math.pi;
    return IgnorePointer(
      child: Stack(
        children: <Widget>[
          _orb(
            left: 40 + math.sin(t) * 18,
            top: 90 + math.cos(t * 0.7) * 22,
            size: 220,
            color: const Color(0xFF7C4DFF).withValues(alpha: 0.18),
          ),
          _orb(
            right: 30 + math.cos(t * 0.5) * 20,
            top: 240 + math.sin(t * 0.4) * 18,
            size: 180,
            color: const Color(0xFF00BCD4).withValues(alpha: 0.16),
          ),
          _orb(
            left: 80 + math.cos(t * 0.3) * 14,
            bottom: 80 + math.sin(t * 0.6) * 24,
            size: 260,
            color: const Color(0xFFFFD700).withValues(alpha: 0.10),
          ),
        ],
      ),
    );
  }

  Widget _orb({
    double? left,
    double? right,
    double? top,
    double? bottom,
    required double size,
    required Color color,
  }) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[color, Colors.transparent],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Intro view
// ---------------------------------------------------------------------------

class _IntroView extends StatelessWidget {
  const _IntroView(
      {super.key, required this.lastResult, required this.onStart});

  final QuizResult? lastResult;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final lr = lastResult;
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 80, 28, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Spacer(),
          Center(
            child: Text(
              'Welche Welt\ngehört zu dir?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Cormorant Garamond',
                fontSize: 42,
                height: 1.05,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.96),
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              '7 Fragen. Sei ehrlich, nicht clever.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.68),
                letterSpacing: 0.4,
              ),
            ),
          ),
          const Spacer(),
          _GlassPrimaryButton(
            label: 'QUIZ STARTEN',
            onTap: onStart,
            accent: const Color(0xFFFFD700),
          ),
          const SizedBox(height: 18),
          if (lr != null) _LastResultPill(result: lr),
        ],
      ),
    );
  }
}

class _LastResultPill extends StatelessWidget {
  const _LastResultPill({required this.result});

  final QuizResult result;

  @override
  Widget build(BuildContext context) {
    final info = _kWorldInfo[result.world]!;
    final days = DateTime.now().difference(result.timestamp).inDays;
    final label = days <= 0
        ? 'heute'
        : days == 1
            ? 'gestern'
            : 'vor $days Tagen';
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: info.color.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(info.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  'Zuletzt: ${info.name} ($label)',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quiz view
// ---------------------------------------------------------------------------

class _QuizView extends StatelessWidget {
  const _QuizView({
    super.key,
    required this.question,
    required this.index,
    required this.total,
    required this.animation,
    required this.onSelected,
  });

  final QuizQuestion question;
  final int index;
  final int total;
  final AnimationController animation;
  final ValueChanged<QuizOption> onSelected;

  @override
  Widget build(BuildContext context) {
    final progress = (index + 1) / total;
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
    final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _ProgressBar(progress: progress),
          const SizedBox(height: 10),
          Text(
            'Frage ${index + 1} von $total',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 12,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 28),
          FadeTransition(
            opacity: fade,
            child: SlideTransition(
              position: slide,
              child: Text(
                question.prompt,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cormorant Garamond',
                  fontSize: 28,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.94),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Expanded(
            child: FadeTransition(
              opacity: fade,
              child: SlideTransition(
                position: slide,
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: question.options.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final opt = question.options[i];
                    return _OptionCard(
                      label: opt.label,
                      onTap: () => onSelected(opt),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Stack(
        children: <Widget>[
          Container(
            height: 4,
            color: Colors.white.withValues(alpha: 0.08),
          ),
          AnimatedFractionallySizedBox(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              height: 4,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[Color(0xFFFFD700), Color(0xFF7C4DFF)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatefulWidget {
  const _OptionCard({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_OptionCard> createState() => _OptionCardState();
}

class _OptionCardState extends State<_OptionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(
                  alpha: _pressed ? 0.12 : 0.06,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withValues(
                    alpha: _pressed ? 0.32 : 0.16,
                  ),
                  width: 1,
                ),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 6,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          Color(0xFFFFD700),
                          Color(0xFF7C4DFF),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: 15,
                        height: 1.35,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Result view
// ---------------------------------------------------------------------------

class _ResultView extends StatelessWidget {
  const _ResultView({
    super.key,
    required this.result,
    required this.animation,
    required this.onShare,
    required this.onRetry,
  });

  final QuizResult result;
  final AnimationController animation;
  final VoidCallback onShare;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final info = _kWorldInfo[result.world]!;
    final totalPoints = _kQuestions.length;
    final scale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
    );
    final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 96, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Center(
            child: FadeTransition(
              opacity: fade,
              child: ScaleTransition(
                scale: scale,
                child: Container(
                  width: 168,
                  height: 168,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: <Color>[
                        info.color.withValues(alpha: 0.45),
                        Colors.transparent,
                      ],
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: info.color.withValues(alpha: 0.55),
                        blurRadius: 60,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    info.emoji,
                    style: const TextStyle(fontSize: 96),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          FadeTransition(
            opacity: fade,
            child: Text(
              info.name.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                color: info.color,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                shadows: <Shadow>[
                  Shadow(
                    color: info.color.withValues(alpha: 0.6),
                    blurRadius: 18,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          FadeTransition(
            opacity: fade,
            child: Text(
              info.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Cormorant Garamond',
                color: Colors.white.withValues(alpha: 0.88),
                fontSize: 19,
                height: 1.4,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 32),
          FadeTransition(
            opacity: fade,
            child: Text(
              'DEINE AFFINITÄTEN',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 11,
                letterSpacing: 2.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 14),
          for (final w in QuizWorld.values)
            FadeTransition(
              opacity: fade,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _AffinityBar(
                  info: _kWorldInfo[w]!,
                  score: result.scores[w] ?? 0,
                  total: totalPoints,
                  isWinner: w == result.world,
                ),
              ),
            ),
          const SizedBox(height: 26),
          FadeTransition(
            opacity: fade,
            child: _GlassPrimaryButton(
              label: 'ERGEBNIS TEILEN',
              onTap: onShare,
              accent: info.color,
            ),
          ),
          const SizedBox(height: 12),
          FadeTransition(
            opacity: fade,
            child: TextButton(
              onPressed: onRetry,
              child: Text(
                'Quiz wiederholen',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AffinityBar extends StatelessWidget {
  const _AffinityBar({
    required this.info,
    required this.score,
    required this.total,
    required this.isWinner,
  });

  final QuizWorldInfo info;
  final int score;
  final int total;
  final bool isWinner;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : (score / total).clamp(0.0, 1.0);
    final percent = (ratio * 100).round();
    final emphasis = isWinner ? 1.0 : 0.55;
    return Opacity(
      opacity: isWinner ? 1.0 : 0.85,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(info.emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  info.name,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6 + 0.4 * emphasis),
                    fontSize: 13,
                    fontWeight: isWinner ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              Text(
                '$percent %',
                style: TextStyle(
                  color: info.color.withValues(alpha: 0.55 + 0.45 * emphasis),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: <Widget>[
                Container(
                  height: isWinner ? 8 : 5,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: ratio),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return FractionallySizedBox(
                      widthFactor: value,
                      child: Container(
                        height: isWinner ? 8 : 5,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: <Color>[
                              info.color.withValues(alpha: 0.95),
                              info.color.withValues(alpha: 0.55),
                            ],
                          ),
                          boxShadow: isWinner
                              ? <BoxShadow>[
                                  BoxShadow(
                                    color: info.color.withValues(alpha: 0.6),
                                    blurRadius: 10,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared primary button
// ---------------------------------------------------------------------------

class _GlassPrimaryButton extends StatefulWidget {
  const _GlassPrimaryButton({
    required this.label,
    required this.onTap,
    required this.accent,
  });

  final String label;
  final VoidCallback onTap;
  final Color accent;

  @override
  State<_GlassPrimaryButton> createState() => _GlassPrimaryButtonState();
}

class _GlassPrimaryButtonState extends State<_GlassPrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[
                    widget.accent.withValues(alpha: 0.18),
                    widget.accent.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: widget.accent.withValues(alpha: 0.45),
                  width: 1.2,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: widget.accent.withValues(alpha: 0.35),
                    blurRadius: 24,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.96),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.5,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
