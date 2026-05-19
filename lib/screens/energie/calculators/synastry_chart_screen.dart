// Synastrie-Chart: Partner-Vergleich auf Astrologie-Ebene.
// Bereich B2 -- nutzt NatalAstrology.calculateSynastry().

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../services/natal_astrology_service.dart';
import '../../../services/storage_service.dart';
import '../../../services/streak_tracking_service.dart';
import '../../../widgets/cinematic/wb_ambient_particles.dart';
import '../../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../../widgets/cinematic/wb_vignette.dart';
import '../../../theme/wb_cinematic_tokens.dart';

class SynastryChartScreen extends StatefulWidget {
  const SynastryChartScreen({super.key});

  @override
  State<SynastryChartScreen> createState() => _SynastryChartScreenState();
}

class _SynastryChartScreenState extends State<SynastryChartScreen> {
  DateTime? _dateA;
  TimeOfDay? _timeA;
  DateTime? _dateB;
  TimeOfDay? _timeB;
  final _latACtrl = TextEditingController();
  final _lngACtrl = TextEditingController();
  final _latBCtrl = TextEditingController();
  final _lngBCtrl = TextEditingController();

  NatalChartResult? _chartA;
  NatalChartResult? _chartB;
  Map<String, dynamic>? _synastry;

  static const _accent = Color(0xFF7C4DFF);
  static const _gold = Color(0xFFC9A84C);

  @override
  void initState() {
    super.initState();
    StreakTrackingService().trackToolUsage('synastry');
    _autofillFromProfile();
  }

  Future<void> _autofillFromProfile() async {
    final p = await StorageService().loadEnergieProfile();
    if (p == null || !mounted) return;
    setState(() {
      _dateA = p.birthDate;
      if (p.birthTime != null && p.birthTime!.contains(':')) {
        final parts = p.birthTime!.split(':');
        final h = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (h != null && m != null) _timeA = TimeOfDay(hour: h, minute: m);
      }
      if (p.birthLatitude != null) _latACtrl.text = p.birthLatitude!.toStringAsFixed(4);
      if (p.birthLongitude != null) _lngACtrl.text = p.birthLongitude!.toStringAsFixed(4);
    });
  }

  @override
  void dispose() {
    _latACtrl.dispose();
    _lngACtrl.dispose();
    _latBCtrl.dispose();
    _lngBCtrl.dispose();
    super.dispose();
  }

  void _compute() {
    if (_dateA == null || _dateB == null) return;
    final timeA = _timeA ?? const TimeOfDay(hour: 12, minute: 0);
    final timeB = _timeB ?? const TimeOfDay(hour: 12, minute: 0);
    final dtA = DateTime.utc(_dateA!.year, _dateA!.month, _dateA!.day,
        timeA.hour, timeA.minute);
    final dtB = DateTime.utc(_dateB!.year, _dateB!.month, _dateB!.day,
        timeB.hour, timeB.minute);
    final latA = double.tryParse(_latACtrl.text);
    final lngA = double.tryParse(_lngACtrl.text);
    final latB = double.tryParse(_latBCtrl.text);
    final lngB = double.tryParse(_lngBCtrl.text);

    final a = NatalAstrology.compute(
        birthDateUtc: dtA, latitude: latA, longitude: lngA);
    final b = NatalAstrology.compute(
        birthDateUtc: dtB, latitude: latB, longitude: lngB);
    final s = NatalAstrology.calculateSynastry(chartA: a, chartB: b);
    setState(() {
      _chartA = a;
      _chartB = b;
      _synastry = s;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06040F),
      extendBodyBehindAppBar: true,
      appBar: const WBGlassAppBar(
        title: 'Synastrie',
        world: WBWorld.energie,
      ),
      body: Stack(
        children: [
          const IgnorePointer(
            child: WBAmbientParticles(world: WBWorld.energie, count: 26),
          ),
          const WBVignette(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 64, 20, 28),
              children: [
                _personBlock('Person A', _dateA, _timeA, _latACtrl, _lngACtrl,
                    (d) => setState(() => _dateA = d),
                    (t) => setState(() => _timeA = t)),
                const SizedBox(height: 14),
                _personBlock('Person B', _dateB, _timeB, _latBCtrl, _lngBCtrl,
                    (d) => setState(() => _dateB = d),
                    (t) => setState(() => _timeB = t)),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: (_dateA != null && _dateB != null) ? _compute : null,
                    icon: const Icon(Icons.calculate_rounded),
                    label: const Text('Synastrie berechnen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800,
                          letterSpacing: 0.6),
                    ),
                  ),
                ),
                if (_synastry != null) ...[
                  const SizedBox(height: 22),
                  _scoreCard(),
                  const SizedBox(height: 14),
                  _aspectsList(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _personBlock(
      String label,
      DateTime? date,
      TimeOfDay? time,
      TextEditingController lat,
      TextEditingController lng,
      ValueChanged<DateTime> onDate,
      ValueChanged<TimeOfDay> onTime) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _accent.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(),
                  style: TextStyle(
                      color: _accent.withValues(alpha: 0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                          context: context,
                          initialDate: date ?? DateTime(1990),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now());
                      if (picked != null) onDate(picked);
                    },
                    child: _inputBox(date == null
                        ? 'Geburtsdatum'
                        : '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final picked = await showTimePicker(
                          context: context,
                          initialTime: time ?? const TimeOfDay(hour: 12, minute: 0));
                      if (picked != null) onTime(picked);
                    },
                    child: _inputBox(time == null
                        ? 'Geburtszeit (opt.)'
                        : '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: _textField(lat, 'Breitengrad (opt.)')),
                const SizedBox(width: 8),
                Expanded(child: _textField(lng, 'Längengrad (opt.)')),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputBox(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontSize: 13)),
    );
  }

  Widget _textField(TextEditingController c, String hint) {
    return TextField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _scoreCard() {
    final score = (_synastry!['score'] as int);
    final count = (_synastry!['count'] as int);
    Color tone;
    String label;
    if (score >= 70) { tone = const Color(0xFF66BB6A); label = 'Stark harmonisch'; }
    else if (score >= 55) { tone = _gold; label = 'Ueberwiegend harmonisch'; }
    else if (score >= 45) { tone = const Color(0xFFFFB300); label = 'Gemischt'; }
    else { tone = const Color(0xFFEF5350); label = 'Wachstumsbeziehung'; }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: RadialGradient(colors: [
          tone.withValues(alpha: 0.35),
          tone.withValues(alpha: 0.08),
        ]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tone.withValues(alpha: 0.6), width: 1.4),
        boxShadow: [
          BoxShadow(color: tone.withValues(alpha: 0.35), blurRadius: 24),
        ],
      ),
      child: Column(
        children: [
          Text('SYNASTRIE-SCORE',
              style: TextStyle(
                  color: tone, fontSize: 11,
                  fontWeight: FontWeight.w800, letterSpacing: 2.5)),
          const SizedBox(height: 6),
          Text('$score%',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 52,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text('$count Aspekte gefunden',
              style: const TextStyle(
                  color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _aspectsList() {
    final aspects = (_synastry!['aspects'] as List)
        .cast<Map<String, dynamic>>();
    if (aspects.isEmpty) {
      return const Center(
        child: Text('Keine starken Aspekte gefunden.',
            style: TextStyle(color: Colors.white60)),
      );
    }
    // Sort by strongest (lowest orb)
    aspects.sort((a, b) =>
        (a['orb'] as double).compareTo(b['orb'] as double));
    final top = aspects.take(15).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('WICHTIGSTE ASPEKTE',
            style: TextStyle(
                color: Color(0xFFCE93D8),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 2)),
        const SizedBox(height: 10),
        ...top.map((a) {
          final weight = a['weight'] as int;
          final color = weight > 0
              ? const Color(0xFF66BB6A)
              : weight < 0
                  ? const Color(0xFFEF5350)
                  : const Color(0xFF4FC3F7);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Row(children: [
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${_dePlanet(a['planetA'] as String)} ${a['aspect']} '
                    '${_dePlanet(a['planetB'] as String)}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                Text('${(a['orb'] as double).toStringAsFixed(1)}°',
                    style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ]),
            ),
          );
        }),
      ],
    );
  }

  String _dePlanet(String key) => switch (key) {
        'sun' => 'Sonne',
        'moon' => 'Mond',
        'mercury' => 'Merkur',
        'venus' => 'Venus',
        'mars' => 'Mars',
        'jupiter' => 'Jupiter',
        'saturn' => 'Saturn',
        'uranus' => 'Uranus',
        'neptune' => 'Neptun',
        'pluto' => 'Pluto',
        _ => key,
      };
}
