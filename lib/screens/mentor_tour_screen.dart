// First-Launch Mentor-Tour — sanfter Einstieg in die 4 Welten.
//
// Eine Frage, vier Antworten, jede führt zu einer Welt. Nach der Wahl
// öffnet sich die empfohlene Welt mit cinematischem Übergang. SharedPref
// `mentor_tour_completed=true` verhindert, dass die Tour wiederkommt.
// "Überspringen"-Link bleibt jederzeit sichtbar.
//
// Trigger via MentorTour.maybeShow(context) — guard ist in dem Helper,
// damit der Aufrufer nichts wissen muss.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../animations/world_transition_video.dart';
import 'energie_world_wrapper.dart';
import 'materie_world_wrapper.dart';
import 'ursprung/ursprung_world_wrapper.dart';
import 'vorhang/vorhang_world_wrapper.dart';

class MentorTour {
  static const _prefKey = 'mentor_tour_completed';

  static Future<bool> isCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_prefKey) ?? false;
    } catch (_) {
      return true; // bei Fehler nicht nerven
    }
  }

  static Future<void> markCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, true);
    } catch (_) {}
  }

  /// Zeigt die Tour, sofern noch nicht abgeschlossen. Gibt true zurück
  /// wenn die Tour gezeigt wurde (egal ob durchgespielt oder skipped).
  static Future<bool> maybeShow(BuildContext context) async {
    if (await isCompleted()) return false;
    if (!context.mounted) return false;
    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const MentorTourScreen(),
      ),
    );
    return true;
  }
}

class MentorTourScreen extends StatefulWidget {
  const MentorTourScreen({super.key});

  @override
  State<MentorTourScreen> createState() => _MentorTourScreenState();
}

class _MentorTourScreenState extends State<MentorTourScreen>
    with TickerProviderStateMixin {
  int _page = 0; // 0 = welcome, 1 = question
  late final AnimationController _bgCtrl;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    super.dispose();
  }

  Future<void> _skip() async {
    await MentorTour.markCompleted();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _chooseWorld(_WorldChoice c) async {
    await MentorTour.markCompleted();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => WorldTransitionVideo(
          targetScreen: c.wrapper,
          targetWorld: c.key,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050310),
      body: SafeArea(
        child: Stack(
          children: [
            // Animierter 4-Farben-Hintergrund
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _bgCtrl,
                builder: (_, __) {
                  final t = _bgCtrl.value;
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(
                          -0.3 + 0.6 * t,
                          -0.3 + 0.6 * (1 - t),
                        ),
                        radius: 1.4,
                        colors: [
                          const Color(0xFFC9A84C).withValues(alpha: 0.14),
                          const Color(0xFFA855F7).withValues(alpha: 0.10),
                          const Color(0xFF3B82F6).withValues(alpha: 0.10),
                          const Color(0xFF00D4AA).withValues(alpha: 0.12),
                          const Color(0xFF050310),
                        ],
                        stops: const [0.0, 0.3, 0.55, 0.75, 1.0],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Skip-Link oben rechts
            Positioned(
              top: 8,
              right: 8,
              child: TextButton(
                onPressed: _skip,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white60,
                ),
                child: const Text(
                  'Überspringen',
                  style: TextStyle(fontSize: 12, letterSpacing: 0.6),
                ),
              ),
            ),
            // Inhalt
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeOutCubic,
              child: _page == 0 ? _buildWelcome() : _buildQuestion(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcome() {
    return Padding(
      key: const ValueKey('welcome'),
      padding: const EdgeInsets.fromLTRB(28, 64, 28, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          // Kleines Portal
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const SweepGradient(
                  colors: [
                    Color(0xFF3B82F6),
                    Color(0xFFA855F7),
                    Color(0xFFC9A84C),
                    Color(0xFF00D4AA),
                    Color(0xFF3B82F6),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFC9A84C).withValues(alpha: 0.45),
                    blurRadius: 36,
                  ),
                ],
              ),
              child: Container(
                margin: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF050310),
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: Color(0xFFC9A84C), size: 38),
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Willkommen in der Weltenbibliothek.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.3,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Vier Welten – ein Ursprung. Lass uns kurz herausfinden, '
            'wo deine Reise am besten beginnt.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
              height: 1.55,
            ),
          ),
          const Spacer(),
          SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () => setState(() => _page = 1),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text(
                'Los geht\'s',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC9A84C),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 10,
                shadowColor: const Color(0xFFC9A84C).withValues(alpha: 0.4),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildQuestion() {
    return ListView(
      key: const ValueKey('question'),
      padding: const EdgeInsets.fromLTRB(22, 60, 22, 32),
      children: [
        const Text(
          'Welche Frage brennt dir gerade am meisten?',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Wähle was am ehesten passt – du kannst später jederzeit zwischen den Welten wechseln.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 28),
        for (final c in _choices)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ChoiceCard(choice: c, onTap: () => _chooseWorld(c)),
          ),
      ],
    );
  }
}

class _WorldChoice {
  final String key;
  final String title;
  final String prompt;
  final Color color;
  final IconData icon;
  final Widget wrapper;

  const _WorldChoice({
    required this.key,
    required this.title,
    required this.prompt,
    required this.color,
    required this.icon,
    required this.wrapper,
  });
}

const _choices = [
  _WorldChoice(
    key: 'materie',
    title: 'Wissen & Fakten',
    prompt:
        'Was läuft wirklich in der Welt? Geopolitik, Geschichte, Wissenschaft.',
    color: Color(0xFF3B82F6),
    icon: Icons.public,
    wrapper: MaterieWorldWrapper(),
  ),
  _WorldChoice(
    key: 'energie',
    title: 'Spiritualität & Bewusstsein',
    prompt: 'Wer bin ich wirklich? Meditation, Chakren, innere Welten.',
    color: Color(0xFFA855F7),
    icon: Icons.auto_awesome,
    wrapper: EnergieWorldWrapper(),
  ),
  _WorldChoice(
    key: 'vorhang',
    title: 'Macht & Manipulation',
    prompt: 'Wer zieht die Fäden? Psychologie, Strategie, Schattenarbeit.',
    color: Color(0xFFC9A84C),
    icon: Icons.psychology,
    wrapper: VorhangWorldWrapper(),
  ),
  _WorldChoice(
    key: 'ursprung',
    title: 'Ursprung & Verbindung',
    prompt:
        'Wo kommen wir her? Naturvölker, Kosmologie, ursprüngliches Wissen.',
    color: Color(0xFF00D4AA),
    icon: Icons.all_inclusive,
    wrapper: UrsprungWorldWrapper(),
  ),
];

class _ChoiceCard extends StatelessWidget {
  final _WorldChoice choice;
  final VoidCallback onTap;

  const _ChoiceCard({required this.choice, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: [
                choice.color.withValues(alpha: 0.16),
                choice.color.withValues(alpha: 0.04),
              ],
            ),
            border: Border.all(color: choice.color.withValues(alpha: 0.45)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: choice.color.withValues(alpha: 0.22),
                  border: Border.all(
                    color: choice.color.withValues(alpha: 0.6),
                  ),
                ),
                child: Icon(choice.icon, color: choice.color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      choice.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      choice.prompt,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: choice.color.withValues(alpha: 0.8)),
            ],
          ),
        ),
      ),
    );
  }
}
