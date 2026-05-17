// 📊 BIORHYTHMUS-KOMPATIBILITÄT
//
// Zwei Geburtsdaten → heutige Kompatibilität auf 3 Zyklen:
// Physisch (23d) · Emotional (28d) · Intellektuell (33d). Klassische
// Biorhythmus-Theorie (Fliess/Swoboda) — Score basiert auf Sinus-Phase.

import 'dart:math' as math;

import 'package:flutter/material.dart';

class BiorhythmCompatibilityScreen extends StatefulWidget {
  const BiorhythmCompatibilityScreen({super.key});

  @override
  State<BiorhythmCompatibilityScreen> createState() =>
      _BiorhythmCompatibilityScreenState();
}

class _BiorhythmCompatibilityScreenState
    extends State<BiorhythmCompatibilityScreen> {
  static const _bg = Color(0xFF06040F);
  static const _surface = Color(0xFF100B1E);
  static const _accent = Color(0xFF00897B);

  DateTime? _birthA;
  DateTime? _birthB;

  // Sinus-Wert eines Zyklus für ein Geburtsdatum am heutigen Tag.
  double _wave(DateTime birth, int periodDays) {
    final today = DateTime.now();
    final days =
        today.difference(DateTime(birth.year, birth.month, birth.day)).inDays;
    return math.sin(2 * math.pi * days / periodDays);
  }

  // Kompatibilität = 1 - |a-b|/2 → 0..1, Sinus geht von -1 bis 1.
  int _compatScore(double a, double b) {
    return (((1 - (a - b).abs() / 2) * 100)).round().clamp(0, 100);
  }

  Future<void> _pick(bool a) async {
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
      setState(() => a ? _birthA = picked : _birthB = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _accent,
        title: const Row(children: [
          Text('📊', style: TextStyle(fontSize: 22)),
          SizedBox(width: 10),
          Text('Biorhythmus-Kompat',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ]),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [_accent.withValues(alpha: 0.4), _surface]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'Heutige Biorhythmus-Kompatibilität zweier Personen. 3 Zyklen — '
              'physisch (23d), emotional (28d), intellektuell (33d). Klassisches '
              'Modell nach Fliess/Swoboda, mit kritischem Realismus betrachten.',
              style: TextStyle(color: Colors.white, fontSize: 12.5, height: 1.5),
            ),
          ),
          const SizedBox(height: 18),
          _personPicker('🧍 PERSON A', _birthA, () => _pick(true)),
          const SizedBox(height: 12),
          _personPicker('🧍 PERSON B', _birthB, () => _pick(false)),
          const SizedBox(height: 24),
          if (_birthA != null && _birthB != null) _buildResult(),
        ],
      ),
    );
  }

  Widget _personPicker(String title, DateTime? d, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _accent.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          const Icon(Icons.calendar_today, color: _accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                Text(
                  d == null
                      ? 'Geburtsdatum wählen'
                      : '${d.day}.${d.month}.${d.year}',
                  style: TextStyle(color: d == null ? Colors.white54 : Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white54),
        ]),
      ),
    );
  }

  Widget _buildResult() {
    final aPhys = _wave(_birthA!, 23);
    final bPhys = _wave(_birthB!, 23);
    final aEmot = _wave(_birthA!, 28);
    final bEmot = _wave(_birthB!, 28);
    final aIntel = _wave(_birthA!, 33);
    final bIntel = _wave(_birthB!, 33);

    final physScore = _compatScore(aPhys, bPhys);
    final emotScore = _compatScore(aEmot, bEmot);
    final intelScore = _compatScore(aIntel, bIntel);
    final overall = ((physScore + emotScore + intelScore) / 3).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: RadialGradient(colors: [_accent, _accent.withValues(alpha: 0.3)]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: _accent.withValues(alpha: 0.4), blurRadius: 20)],
          ),
          child: Column(
            children: [
              const Text('HEUTIGE KOMPATIBILITÄT',
                  style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 2.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('$overall%',
                  style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w900)),
              Text(_overallLabel(overall),
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontStyle: FontStyle.italic)),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _cycleCard('💪 Physisch', '23-Tage-Zyklus · Energie & Körper',
            aPhys, bPhys, physScore),
        const SizedBox(height: 10),
        _cycleCard('❤️ Emotional', '28-Tage-Zyklus · Gefühl & Empfindsamkeit',
            aEmot, bEmot, emotScore),
        const SizedBox(height: 10),
        _cycleCard('🧠 Intellektuell', '33-Tage-Zyklus · Denken & Konzentration',
            aIntel, bIntel, intelScore),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: const Text(
            '⚠️ Biorhythmus ist ein historisches Modell (Wilhelm Fliess, 1897). '
            'Wissenschaftlich nicht gestützt. Nützlich als Spiegel zur Selbst-Beobachtung — '
            'nicht als deterministisches System.',
            style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _cycleCard(String title, String desc, double a, double b, int score) {
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
                  style: TextStyle(color: _accent, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: _waveBar('A', a),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _waveBar('B', b),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _waveBar(String label, double value) {
    // value range -1..1, map to 0..1 for display
    final normalized = (value + 1) / 2;
    final color = value > 0.5
        ? const Color(0xFF66BB6A)
        : value > 0
            ? const Color(0xFFFFB300)
            : value > -0.5
                ? const Color(0xFFFB8C00)
                : const Color(0xFFE53935);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${(value * 100).toStringAsFixed(0)}%',
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: normalized,
            minHeight: 6,
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }

  String _overallLabel(int s) => switch (s) {
        >= 85 => 'Im Gleichklang',
        >= 70 => 'Harmonisch',
        >= 55 => 'Solide',
        >= 40 => 'Wechselhaft',
        _ => 'Gegensätzlich',
      };
}
