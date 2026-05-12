import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 🏗️ Realitäts-Architekt — 6-Schritt Patterning / Manifestation Tool
///
/// Schritte:
///   1. Kategorie wählen
///   2. Ziel formulieren
///   3. Gegenwarts-Form
///   4. Sinnliche Eindrücke (sehen/hören/fühlen/riechen/schmecken)
///   5. Emotion + Intensität
///   6. Ziel-Datum
/// Speichert in `ursprung_patterns`.
class RealityArchitectScreen extends StatefulWidget {
  const RealityArchitectScreen({super.key});

  @override
  State<RealityArchitectScreen> createState() => _RealityArchitectScreenState();
}

class _RealityArchitectScreenState extends State<RealityArchitectScreen> {
  static const _cyan = Color(0xFF00D4AA);
  static const _bgDeep = Color(0xFF050510);

  int _step = 0;
  final _categories = const [
    'Gesundheit',
    'Beziehung',
    'Karriere',
    'Wohlstand',
    'Spirituell',
    'Kreativität',
  ];
  String _category = 'Gesundheit';
  final _goalCtrl = TextEditingController();
  final _presentCtrl = TextEditingController();
  final _seeCtrl = TextEditingController();
  final _hearCtrl = TextEditingController();
  final _feelCtrl = TextEditingController();
  final _smellCtrl = TextEditingController();
  final _tasteCtrl = TextEditingController();
  String _emotion = 'Freude';
  int _intensity = 7;
  DateTime _targetDate = DateTime.now().add(const Duration(days: 90));
  bool _saving = false;

  final _emotions = const [
    'Freude',
    'Dankbarkeit',
    'Liebe',
    'Frieden',
    'Begeisterung',
    'Stolz',
    'Vertrauen',
  ];

  @override
  void dispose() {
    _goalCtrl.dispose();
    _presentCtrl.dispose();
    _seeCtrl.dispose();
    _hearCtrl.dispose();
    _feelCtrl.dispose();
    _smellCtrl.dispose();
    _tasteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw 'Bitte melde dich an, um dein Muster zu speichern.';
      }
      await Supabase.instance.client.from('ursprung_patterns').insert({
        'user_id': user.id,
        'category': _category,
        'goal_text': _goalCtrl.text.trim(),
        'present_tense': _presentCtrl.text.trim(),
        'senses': {
          'see': _seeCtrl.text.trim(),
          'hear': _hearCtrl.text.trim(),
          'feel': _feelCtrl.text.trim(),
          'smell': _smellCtrl.text.trim(),
          'taste': _tasteCtrl.text.trim(),
        },
        'emotion': _emotion,
        'emotion_intensity': _intensity,
        'target_date':
            '${_targetDate.year.toString().padLeft(4, '0')}-${_targetDate.month.toString().padLeft(2, '0')}-${_targetDate.day.toString().padLeft(2, '0')}',
        'status': 'active',
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _cyan.withValues(alpha: 0.9),
          content: const Text('Muster gespeichert – Realität ist geprägt.'),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDeep,
      appBar: AppBar(
        backgroundColor: _bgDeep,
        elevation: 0,
        iconTheme: const IconThemeData(color: _cyan),
        title: Text(
          'Realitäts-Architekt (${_step + 1}/6)',
          style: const TextStyle(
            color: _cyan,
            letterSpacing: 2.0,
            fontSize: 15,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(
                value: (_step + 1) / 6,
                minHeight: 4,
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                valueColor: const AlwaysStoppedAnimation(_cyan),
              ),
              const SizedBox(height: 20),
              Expanded(child: SingleChildScrollView(child: _buildStep())),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (_step > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _step--),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: _cyan.withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Text(
                          'ZURÜCK',
                          style: TextStyle(color: _cyan),
                        ),
                      ),
                    ),
                  if (_step > 0) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving
                          ? null
                          : () {
                              if (_step < 5) {
                                setState(() => _step++);
                              } else {
                                _save();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _cyan,
                        foregroundColor: _bgDeep,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _saving
                            ? 'SPEICHERE …'
                            : (_step < 5 ? 'WEITER' : 'PRÄGEN'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _stepWrap(
          title: 'Wähle eine Kategorie',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((c) {
              final isSel = c == _category;
              return GestureDetector(
                onTap: () => setState(() => _category = c),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSel
                        ? _cyan.withValues(alpha: 0.20)
                        : Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isSel ? _cyan : Colors.white.withValues(alpha: 0.10),
                    ),
                  ),
                  child: Text(
                    c,
                    style: TextStyle(
                      color: isSel ? _cyan : Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      case 1:
        return _stepWrap(
          title: 'Formuliere dein Ziel',
          subtitle: 'Klar, konkret, in der Ich-Form',
          child: _input(_goalCtrl, 'Was möchtest du erschaffen?', 3),
        );
      case 2:
        return _stepWrap(
          title: 'Gegenwarts-Form',
          subtitle: '„Ich bin / Ich habe …" — als wäre es schon Realität',
          child: _input(_presentCtrl, 'Ich bin …', 3),
        );
      case 3:
        return _stepWrap(
          title: 'Aktiviere alle Sinne',
          subtitle: 'Beschreibe wie dein Ziel sich anfühlt',
          child: Column(
            children: [
              _input(_seeCtrl, 'Was siehst du? (sehen)', 2),
              const SizedBox(height: 10),
              _input(_hearCtrl, 'Was hörst du? (hören)', 2),
              const SizedBox(height: 10),
              _input(_feelCtrl, 'Was fühlst du? (fühlen)', 2),
              const SizedBox(height: 10),
              _input(_smellCtrl, 'Was riechst du? (optional)', 1),
              const SizedBox(height: 10),
              _input(_tasteCtrl, 'Was schmeckst du? (optional)', 1),
            ],
          ),
        );
      case 4:
        return _stepWrap(
          title: 'Emotion & Intensität',
          subtitle: 'Welches Gefühl trägt dieses Bild?',
          child: Column(
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _emotions.map((e) {
                  final isSel = e == _emotion;
                  return GestureDetector(
                    onTap: () => setState(() => _emotion = e),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSel
                            ? _cyan.withValues(alpha: 0.20)
                            : Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSel
                              ? _cyan
                              : Colors.white.withValues(alpha: 0.10),
                        ),
                      ),
                      child: Text(
                        e,
                        style: TextStyle(
                          color: isSel ? _cyan : Colors.white70,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Text(
                'Intensität: $_intensity / 10',
                style: const TextStyle(color: Colors.white70),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: _cyan,
                  inactiveTrackColor: _cyan.withValues(alpha: 0.15),
                  thumbColor: _cyan,
                ),
                child: Slider(
                  value: _intensity.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  onChanged: (v) => setState(() => _intensity = v.round()),
                ),
              ),
            ],
          ),
        );
      case 5:
        return _stepWrap(
          title: 'Ziel-Datum',
          subtitle: 'Wann wird dein Muster Realität?',
          child: Column(
            children: [
              Text(
                '${_targetDate.day}.${_targetDate.month}.${_targetDate.year}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w200,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _targetDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  );
                  if (picked != null) setState(() => _targetDate = picked);
                },
                icon: const Icon(Icons.calendar_today, color: _cyan),
                label:
                    const Text('Datum wählen', style: TextStyle(color: _cyan)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  side: BorderSide(color: _cyan.withValues(alpha: 0.4)),
                ),
              ),
            ],
          ),
        );
    }
    return const SizedBox.shrink();
  }

  Widget _stepWrap({
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w300,
            letterSpacing: 1.0,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 13,
            ),
          ),
        ],
        const SizedBox(height: 20),
        child,
      ],
    );
  }

  Widget _input(TextEditingController c, String hint, int maxLines) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: _cyan.withValues(alpha: 0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: _cyan.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _cyan.withValues(alpha: 0.6)),
        ),
      ),
    );
  }
}
