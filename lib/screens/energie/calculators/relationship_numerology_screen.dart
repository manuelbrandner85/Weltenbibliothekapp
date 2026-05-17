// 💕 BEZIEHUNGS-NUMEROLOGIE
//
// Synastrie-Analyse: zwei Profile (Vorname/Nachname/Geburtsdatum) →
// Vergleich von Lebenszahl, Schicksalszahl (Expression) und Seelenzahl.
// Score pro Achse + Gesamt-Kompatibilität.

import 'package:flutter/material.dart';

import '../../../services/spirit_calculations/numerology_engine.dart';

class RelationshipNumerologyScreen extends StatefulWidget {
  const RelationshipNumerologyScreen({super.key});

  @override
  State<RelationshipNumerologyScreen> createState() =>
      _RelationshipNumerologyScreenState();
}

class _RelationshipNumerologyScreenState
    extends State<RelationshipNumerologyScreen> {
  static const _bg = Color(0xFF06040F);
  static const _surface = Color(0xFF100B1E);
  static const _accent = Color(0xFFE91E63);

  // Person A
  final _aFirst = TextEditingController();
  final _aLast = TextEditingController();
  DateTime? _aBirth;
  // Person B
  final _bFirst = TextEditingController();
  final _bLast = TextEditingController();
  DateTime? _bBirth;

  bool _submitted = false;

  Future<void> _pickDate(bool a) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: _accent, surface: _surface),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (a) {
          _aBirth = picked;
        } else {
          _bBirth = picked;
        }
      });
    }
  }

  bool get _canSubmit =>
      _aFirst.text.isNotEmpty &&
      _aLast.text.isNotEmpty &&
      _aBirth != null &&
      _bFirst.text.isNotEmpty &&
      _bLast.text.isNotEmpty &&
      _bBirth != null;

  // Kompatibilitäts-Score: |a-b|=0 → 100%, |a-b|=4 → 0%
  int _scoreFor(int a, int b) {
    final diff = (a - b).abs();
    // Numbers 1-9 wrap-around: distance is min(diff, 9-diff)
    final wrapped = diff > 4 ? 9 - diff : diff;
    return ((1 - wrapped / 4) * 100).round().clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _accent,
        title: const Row(children: [
          Text('💕', style: TextStyle(fontSize: 22)),
          SizedBox(width: 10),
          Text('Beziehungs-Numerologie',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ]),
      ),
      body: _submitted ? _buildResult() : _buildForm(),
    );
  }

  Widget _buildForm() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [_accent.withValues(alpha: 0.4), _surface]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Text(
            'Synastrie aus Pythagoräischer Numerologie. Vergleicht Lebenszahl, Seelen-Drang '
            'und Schicksal/Ausdruck zweier Profile. Beide brauchen Namen + Geburtsdatum.',
            style: TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
          ),
        ),
        const SizedBox(height: 18),
        _personBlock('🧍 PERSON A', _aFirst, _aLast, _aBirth, () => _pickDate(true)),
        const SizedBox(height: 18),
        _personBlock('🧍 PERSON B', _bFirst, _bLast, _bBirth, () => _pickDate(false)),
        const SizedBox(height: 18),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _canSubmit ? () => setState(() => _submitted = true) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.white12,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('SYNASTRIE BERECHNEN',
                style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 2)),
          ),
        ),
      ],
    );
  }

  Widget _personBlock(String title, TextEditingController firstCtrl,
      TextEditingController lastCtrl, DateTime? birth, VoidCallback pickDate) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 10),
          TextField(
            controller: firstCtrl,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Vorname'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: lastCtrl,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Nachname'),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(children: [
                const Icon(Icons.calendar_today, color: _accent, size: 18),
                const SizedBox(width: 10),
                Text(
                  birth == null
                      ? 'Geburtsdatum wählen'
                      : '${birth.day}.${birth.month}.${birth.year}',
                  style: TextStyle(
                    color: birth == null ? Colors.white54 : Colors.white,
                    fontSize: 14,
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      );

  Widget _buildResult() {
    final aLife = NumerologyEngine.calculateLifePath(_aBirth!);
    final bLife = NumerologyEngine.calculateLifePath(_bBirth!);
    final aSoul = NumerologyEngine.calculateSoulNumber(_aFirst.text, _aLast.text);
    final bSoul = NumerologyEngine.calculateSoulNumber(_bFirst.text, _bLast.text);
    final aExpr = NumerologyEngine.calculateExpressionNumber(_aFirst.text, _aLast.text);
    final bExpr = NumerologyEngine.calculateExpressionNumber(_bFirst.text, _bLast.text);

    final lifeScore = _scoreFor(aLife, bLife);
    final soulScore = _scoreFor(aSoul, bSoul);
    final exprScore = _scoreFor(aExpr, bExpr);
    final overall = ((lifeScore + soulScore + exprScore) / 3).round();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: RadialGradient(colors: [_accent, _accent.withValues(alpha: 0.3)]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: _accent.withValues(alpha: 0.5), blurRadius: 24)],
          ),
          child: Column(
            children: [
              const Text('SYNASTRIE-SCORE',
                  style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 3, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('$overall%',
                  style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w900)),
              Text(_overallLabel(overall),
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontStyle: FontStyle.italic)),
              const SizedBox(height: 8),
              Text(
                '${_aFirst.text} ❤️ ${_bFirst.text}',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _axisCard('🌟 Lebenszahl',
            'Grundenergie & Lebensthema', aLife, bLife, lifeScore),
        const SizedBox(height: 10),
        _axisCard('💞 Seelenzahl',
            'Innere Sehnsucht (aus Vokalen)', aSoul, bSoul, soulScore),
        const SizedBox(height: 10),
        _axisCard('🎯 Schicksalszahl',
            'Ausdruck & Talent (voller Name)', aExpr, bExpr, exprScore),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _accent.withValues(alpha: 0.3)),
          ),
          child: Text(_synastryNote(lifeScore, soulScore, exprScore),
              style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.6)),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () => setState(() => _submitted = false),
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text('Neue Synastrie', style: TextStyle(color: Colors.white)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _axisCard(String title, String desc, int a, int b, int score) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    Text(desc,
                        style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),
              Text('$score%',
                  style: TextStyle(color: _accent, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          Row(children: [
            _numberChip(a, _aFirst.text),
            const SizedBox(width: 8),
            const Text('↔', style: TextStyle(color: Colors.white54, fontSize: 18)),
            const SizedBox(width: 8),
            _numberChip(b, _bFirst.text),
            const SizedBox(width: 12),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: score / 100.0,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  valueColor: const AlwaysStoppedAnimation(_accent),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _numberChip(int n, String name) {
    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [_accent, _accent.withValues(alpha: 0.4)]),
          ),
          child: Text('$n',
              style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 2),
        Text(name,
            style: const TextStyle(color: Colors.white60, fontSize: 9), overflow: TextOverflow.ellipsis),
      ],
    );
  }

  String _overallLabel(int s) => switch (s) {
        >= 85 => 'Seelen-Verwandtschaft',
        >= 70 => 'Starke Resonanz',
        >= 55 => 'Gute Basis',
        >= 40 => 'Lernfeld füreinander',
        _ => 'Polare Energie',
      };

  String _synastryNote(int life, int soul, int expr) {
    final lowest = [life, soul, expr].reduce((a, b) => a < b ? a : b);
    final highest = [life, soul, expr].reduce((a, b) => a > b ? a : b);
    return 'Eure Verbindung ist am stärksten in der Achse mit $highest% '
        '(${_axisName(life, soul, expr, highest)}). Reibung entsteht eher in der Achse '
        'mit $lowest% (${_axisName(life, soul, expr, lowest)}) — '
        'genau hier liegt das gemeinsame Wachstumsfeld. Numerologische Synastrie ist '
        'ein Modell, kein Schicksal: Bewusstsein verändert Resonanz.';
  }

  String _axisName(int life, int soul, int expr, int target) {
    if (life == target) return 'Lebenszahl';
    if (soul == target) return 'Seelenzahl';
    return 'Schicksalszahl';
  }

  @override
  void dispose() {
    _aFirst.dispose();
    _aLast.dispose();
    _bFirst.dispose();
    _bLast.dispose();
    super.dispose();
  }
}
