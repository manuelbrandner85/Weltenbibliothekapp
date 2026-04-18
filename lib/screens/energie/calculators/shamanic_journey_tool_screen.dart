import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ShamanicJourneyToolScreen – 3 Tabs
//   Tab 0: Neu        (Reise starten: Guide wählen, Intention, Timer, Journal)
//   Tab 1: Verlauf    (frühere Reisen + Krafttiere)
//   Tab 2: Leitfäden  (6 öffentliche Guides)
// ─────────────────────────────────────────────────────────────────────────────

const _kDeep = Color(0xFF8E5AE2);
const _kDarkBg = Color(0xFF0A0A0F);
const _kCardBg = Color(0xFF1A1A2E);
const _kBorder = Color(0xFF2A2A4E);

final _db = Supabase.instance.client;

class ShamanicJourneyToolScreen extends StatefulWidget {
  const ShamanicJourneyToolScreen({super.key});

  @override
  State<ShamanicJourneyToolScreen> createState() =>
      _ShamanicJourneyToolScreenState();
}

class _ShamanicJourneyToolScreenState extends State<ShamanicJourneyToolScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kDarkBg,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        title: const Text('🥁 Schamanische Reise',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: _kDeep,
          labelColor: _kDeep,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(icon: Icon(Icons.play_circle_outline), text: 'Neu'),
            Tab(icon: Icon(Icons.history), text: 'Verlauf'),
            Tab(icon: Icon(Icons.menu_book), text: 'Leitfäden'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _NewJourneyTab(),
          _JourneyHistoryTab(),
          _GuidesTab(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 0: Neu  (Phase 2.2b)
// ─────────────────────────────────────────────────────────────────────────────

const Map<String, String> _kWorldLabels = {
  'lower_world': 'Unterwelt',
  'upper_world': 'Oberwelt',
  'middle_world': 'Mittlere Welt',
};

const Map<String, String> _kMethodLabels = {
  'drum': 'Trommel',
  'rattle': 'Rassel',
  'breath': 'Atem',
  'silence': 'Stille',
  'guided': 'Geführt',
};

const Map<String, String> _kGuideWorldToJourney = {
  'lower': 'lower_world',
  'upper': 'upper_world',
  'middle': 'middle_world',
  'any': 'lower_world',
};

class _NewJourneyTab extends StatefulWidget {
  const _NewJourneyTab();
  @override
  State<_NewJourneyTab> createState() => _NewJourneyTabState();
}

class _NewJourneyTabState extends State<_NewJourneyTab> {
  final _intentionCtrl = TextEditingController();
  String _world = 'lower_world';
  String _method = 'drum';
  int _duration = 20;

  @override
  void dispose() {
    _intentionCtrl.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final intention = _intentionCtrl.text.trim();
    if (intention.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Bitte formuliere eine Intention')));
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _JourneyTimerScreen(
          intention: intention,
          world: _world,
          method: _method,
          duration: _duration,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_kDeep.withValues(alpha: 0.3), _kCardBg],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _kDeep.withValues(alpha: 0.4)),
            ),
            child: Row(children: [
              const Text('🥁', style: TextStyle(fontSize: 36)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Eine neue Reise beginnt',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text(
                        'Formuliere deine Intention. Wähle Welt & Methode. Dann reise.',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 12, height: 1.4)),
                  ],
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          const Text('Deine Intention',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _intentionCtrl,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Was willst du in dieser Reise erfahren?',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.flag_outlined, color: _kDeep),
              filled: true,
              fillColor: _kCardBg,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _kBorder)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _kBorder)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _kDeep)),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Welt',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _kWorldLabels.entries
                .map((e) => ChoiceChip(
                      label: Text(e.value),
                      selected: _world == e.key,
                      backgroundColor: _kCardBg,
                      selectedColor: _kDeep,
                      labelStyle: TextStyle(
                          color: _world == e.key
                              ? Colors.white
                              : Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                      side: BorderSide(
                          color: _world == e.key ? _kDeep : _kBorder),
                      onSelected: (_) => setState(() => _world = e.key),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
          const Text('Methode',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _kMethodLabels.entries
                .map((e) => ChoiceChip(
                      label: Text(e.value),
                      selected: _method == e.key,
                      backgroundColor: _kCardBg,
                      selectedColor: _kDeep,
                      labelStyle: TextStyle(
                          color: _method == e.key
                              ? Colors.white
                              : Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                      side: BorderSide(
                          color: _method == e.key ? _kDeep : _kBorder),
                      onSelected: (_) => setState(() => _method = e.key),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
          Row(children: [
            const Text('Dauer',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('$_duration Min',
                style: const TextStyle(
                    color: _kDeep,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
          ]),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _kDeep,
              inactiveTrackColor: _kBorder,
              thumbColor: _kDeep,
              overlayColor: _kDeep.withValues(alpha: 0.2),
              valueIndicatorColor: _kDeep,
            ),
            child: Slider(
              value: _duration.toDouble(),
              min: 5,
              max: 45,
              divisions: 8,
              label: '$_duration Min',
              onChanged: (v) => setState(() => _duration = v.round()),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 54,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _start,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Reise starten',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kDeep,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// Timer-Screen während der Reise
class _JourneyTimerScreen extends StatefulWidget {
  final String intention;
  final String world;
  final String method;
  final int duration;
  const _JourneyTimerScreen({
    required this.intention,
    required this.world,
    required this.method,
    required this.duration,
  });
  @override
  State<_JourneyTimerScreen> createState() => _JourneyTimerScreenState();
}

class _JourneyTimerScreenState extends State<_JourneyTimerScreen> {
  late int _remaining;
  late final DateTime _startedAt;
  bool _running = true;

  @override
  void initState() {
    super.initState();
    _remaining = widget.duration * 60;
    _startedAt = DateTime.now();
    _tick();
  }

  void _tick() async {
    while (mounted && _running && _remaining > 0) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || !_running) return;
      setState(() => _remaining--);
    }
    if (mounted && _remaining == 0) _openJournal(completed: true);
  }

  Future<void> _openJournal({required bool completed}) async {
    _running = false;
    if (!mounted) return;
    final elapsed = widget.duration * 60 - _remaining;
    final minutesDone = (elapsed / 60).round().clamp(1, 999);
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => _JourneyJournalScreen(
          intention: widget.intention,
          world: widget.world,
          method: widget.method,
          actualDuration: minutesDone,
          startedAt: _startedAt,
          completed: completed,
        ),
      ),
    );
  }

  String _format(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _running = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.duration * 60;
    final progress = 1.0 - (_remaining / total);
    return Scaffold(
      backgroundColor: _kDarkBg,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        title: const Text('Reise läuft',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _kCardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kDeep.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Deine Intention',
                      style: TextStyle(
                          color: _kDeep,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2)),
                  const SizedBox(height: 6),
                  Text(widget.intention,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1.4)),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              height: 220,
              width: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      backgroundColor: _kBorder,
                      color: _kDeep,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_format(_remaining),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 44,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 2)),
                      const SizedBox(height: 6),
                      Text(
                          '${_kWorldLabels[widget.world]} • ${_kMethodLabels[widget.method]}',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: () => _openJournal(completed: false),
              icon: const Icon(Icons.stop_circle_outlined),
              label: const Text('Reise beenden & Journal öffnen'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _kDeep,
                side: const BorderSide(color: _kDeep),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// Journal-Screen nach der Reise
class _JourneyJournalScreen extends StatefulWidget {
  final String intention;
  final String world;
  final String method;
  final int actualDuration;
  final DateTime startedAt;
  final bool completed;
  const _JourneyJournalScreen({
    required this.intention,
    required this.world,
    required this.method,
    required this.actualDuration,
    required this.startedAt,
    required this.completed,
  });
  @override
  State<_JourneyJournalScreen> createState() => _JourneyJournalScreenState();
}

class _JourneyJournalScreenState extends State<_JourneyJournalScreen> {
  final _expCtrl = TextEditingController();
  final _beingsCtrl = TextEditingController();
  final _symbolsCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  final _integrationCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _expCtrl.dispose();
    _beingsCtrl.dispose();
    _symbolsCtrl.dispose();
    _messageCtrl.dispose();
    _integrationCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final user = _db.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bitte zuerst anmelden')));
      return;
    }
    setState(() => _saving = true);
    try {
      final beings = _beingsCtrl.text
          .split(RegExp(r'[,\n]'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      final symbols = _symbolsCtrl.text
          .split(RegExp(r'[,\n]'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      await _db.from('shamanic_journeys').insert({
        'user_id': user.id,
        'world': widget.world,
        'intention': widget.intention,
        'method': widget.method,
        'duration_minutes': widget.actualDuration,
        'experience':
            _expCtrl.text.trim().isEmpty ? null : _expCtrl.text.trim(),
        'encountered_beings': beings,
        'symbols_received': symbols,
        'message': _messageCtrl.text.trim().isEmpty
            ? null
            : _messageCtrl.text.trim(),
        'integration': _integrationCtrl.text.trim().isEmpty
            ? null
            : _integrationCtrl.text.trim(),
        'journeyed_at': widget.startedAt.toUtc().toIso8601String(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reise gespeichert 🥁')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kDarkBg,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        title: const Text('Reise-Journal',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: _kCardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kDeep.withValues(alpha: 0.3))),
            child: Row(children: [
              Icon(
                widget.completed ? Icons.check_circle : Icons.stop_circle,
                color: _kDeep,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                    widget.completed
                        ? 'Reise vollständig (${widget.actualDuration} Min) – schreibe auf, solange alles frisch ist.'
                        : 'Reise beendet (${widget.actualDuration} Min). Notiere, was du erlebt hast.',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12, height: 1.4)),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          _field(_expCtrl, 'Was hast du erlebt?',
              Icons.auto_stories_outlined, 5),
          const SizedBox(height: 12),
          _field(_beingsCtrl, 'Begegnete Wesen (kommagetrennt)',
              Icons.pets_outlined, 1),
          const SizedBox(height: 12),
          _field(_symbolsCtrl, 'Empfangene Symbole (kommagetrennt)',
              Icons.star_border, 1),
          const SizedBox(height: 12),
          _field(_messageCtrl, 'Antwort / Botschaft',
              Icons.message_outlined, 3),
          const SizedBox(height: 12),
          _field(_integrationCtrl, 'Integration: was nimmst du mit?',
              Icons.integration_instructions_outlined, 3),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_outlined),
              label: const Text('Reise speichern',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kDeep,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon,
      int maxLines) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: _kDeep),
        filled: true,
        fillColor: _kCardBg,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _kBorder)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _kBorder)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _kDeep)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1: Verlauf  (Phase 2.2c)
// ─────────────────────────────────────────────────────────────────────────────

class _JourneyHistoryTab extends StatelessWidget {
  const _JourneyHistoryTab();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('Verlauf-Tab folgt in Phase 2.2c',
            style: TextStyle(color: Colors.white54),
            textAlign: TextAlign.center),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2: Leitfäden  (Phase 2.2d)
// ─────────────────────────────────────────────────────────────────────────────

class _GuidesTab extends StatelessWidget {
  const _GuidesTab();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('Leitfäden-Tab folgt in Phase 2.2d',
            style: TextStyle(color: Colors.white54),
            textAlign: TextAlign.center),
      ),
    );
  }
}
