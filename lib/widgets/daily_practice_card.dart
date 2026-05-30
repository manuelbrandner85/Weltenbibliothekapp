import 'package:flutter/material.dart';

/// V5: Tägliche Praxis-Challenge.
///
/// Zeigt eine konkrete, umsetzbare Mikro-Übung des Tages -- deterministisch
/// per Datum gewählt, sodass alle Nutzer am selben Tag dieselbe Challenge sehen.
/// Wird auf der Vorhang-Startseite eingebunden.
class DailyPracticeCard extends StatefulWidget {
  final Color accent;
  final List<String> practices;

  const DailyPracticeCard({
    super.key,
    required this.accent,
    required this.practices,
  });

  /// Vorhang-Standard-Set: Mikro-Übungen aus den Modul-Themen.
  static const List<String> vorhangPractices = [
    'Beobachte heute in einem Gespräch bewusst die Körpersprache deines '
        'Gegenübers -- ohne zu bewerten.',
    'Erkenne eine Situation, in der jemand soziale Bewährtheit nutzt, um dich '
        'zu überzeugen.',
    'Formuliere eine Bitte heute als Frage statt als Forderung und beobachte '
        'die Reaktion.',
    'Achte auf deinen eigenen inneren Dialog -- welche Annahme triffst du, '
        'ohne sie zu prüfen?',
    'Halte in einer Diskussion bewusst eine Pause, bevor du antwortest.',
    'Identifiziere heute ein Framing in einer Nachricht oder Werbung.',
    'Übe aktives Zuhören: Fasse zusammen, was dein Gegenüber gesagt hat, bevor '
        'du antwortest.',
    'Erkenne einen eigenen Schatten-Anteil, der heute getriggert wurde.',
  ];

  @override
  State<DailyPracticeCard> createState() => _DailyPracticeCardState();
}

class _DailyPracticeCardState extends State<DailyPracticeCard> {
  bool _done = false;

  String get _todaysPractice {
    if (widget.practices.isEmpty) return '';
    final now = DateTime.now();
    final dayOfYear =
        now.difference(DateTime(now.year, 1, 1)).inDays;
    return widget.practices[dayOfYear % widget.practices.length];
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.14),
            accent.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_rounded, color: accent, size: 18),
              const SizedBox(width: 8),
              Text(
                'HEUTIGE PRAXIS',
                style: TextStyle(
                  color: accent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _todaysPractice,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => setState(() => _done = !_done),
              icon: Icon(
                _done ? Icons.check_circle : Icons.radio_button_unchecked,
                color: _done ? accent : Colors.white38,
                size: 18,
              ),
              label: Text(
                _done ? 'Erledigt' : 'Als erledigt markieren',
                style: TextStyle(
                  color: _done ? accent : Colors.white60,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
