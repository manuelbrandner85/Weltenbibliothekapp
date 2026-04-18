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
// Tab 1: Verlauf  (Phase 2.2c) – Sub-Tabs: Reisen + Krafttiere
// ─────────────────────────────────────────────────────────────────────────────

class _JourneyHistoryTab extends StatefulWidget {
  const _JourneyHistoryTab();
  @override
  State<_JourneyHistoryTab> createState() => _JourneyHistoryTabState();
}

class _JourneyHistoryTabState extends State<_JourneyHistoryTab>
    with SingleTickerProviderStateMixin {
  late final TabController _sub;
  @override
  void initState() {
    super.initState();
    _sub = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _sub.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: _kCardBg,
          child: TabBar(
            controller: _sub,
            indicatorColor: _kDeep,
            labelColor: _kDeep,
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(text: 'Reisen'),
              Tab(text: 'Krafttiere'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _sub,
            children: const [
              _JourneysSubTab(),
              _PowerAnimalsSubTab(),
            ],
          ),
        ),
      ],
    );
  }
}

class _JourneysSubTab extends StatefulWidget {
  const _JourneysSubTab();
  @override
  State<_JourneysSubTab> createState() => _JourneysSubTabState();
}

class _JourneysSubTabState extends State<_JourneysSubTab> {
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = _db.auth.currentUser;
      if (user == null) {
        setState(() {
          _loading = false;
          _error = 'Bitte zuerst anmelden';
        });
        return;
      }
      final rows = await _db
          .from('shamanic_journeys')
          .select()
          .eq('user_id', user.id)
          .order('journeyed_at', ascending: false);
      if (!mounted) return;
      setState(() {
        _rows = List<Map<String, dynamic>>.from(rows);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  Future<void> _delete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kCardBg,
        title: const Text('Reise löschen?',
            style: TextStyle(color: Colors.white)),
        content: const Text('Dieser Eintrag wird unwiderruflich gelöscht.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abbrechen',
                  style: TextStyle(color: Colors.white54))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Löschen',
                  style: TextStyle(color: _kDeep))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _db.from('shamanic_journeys').delete().eq('id', id);
      if (!mounted) return;
      setState(() => _rows.removeWhere((r) => r['id'] == id));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')));
    }
  }

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return iso;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}.${two(dt.month)}.${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _kDeep));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_error!, style: const TextStyle(color: Colors.white54)),
            const SizedBox(height: 12),
            TextButton(
                onPressed: _load,
                child: const Text('Erneut versuchen',
                    style: TextStyle(color: _kDeep))),
          ]),
        ),
      );
    }
    if (_rows.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.nightlight_round, color: _kDeep, size: 48),
            SizedBox(height: 12),
            Text('Noch keine Reisen dokumentiert.\nStarte deine erste im Neu-Tab.',
                style: TextStyle(color: Colors.white54),
                textAlign: TextAlign.center),
          ]),
        ),
      );
    }
    return RefreshIndicator(
      color: _kDeep,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _rows.length,
        itemBuilder: (_, i) {
          final r = _rows[i];
          final beings = List<String>.from(
              (r['encountered_beings'] as List?) ?? const []);
          final symbols = List<String>.from(
              (r['symbols_received'] as List?) ?? const []);
          return Card(
            color: _kCardBg,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: _kDeep.withValues(alpha: 0.3))),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.nightlight_round, color: _kDeep),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r['intention'] as String? ?? '—',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(
                              '${_kWorldLabels[r['world']] ?? r['world']}  •  ${_kMethodLabels[r['method']] ?? r['method']}  •  ${r['duration_minutes']} Min  •  ${_formatDate(r['journeyed_at'] as String)}',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 11)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.white38, size: 20),
                      onPressed: () => _delete(r['id'] as String),
                    ),
                  ]),
                  if ((r['experience'] as String?)?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 10),
                    Text(r['experience'] as String,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            height: 1.4)),
                  ],
                  if (beings.isNotEmpty || symbols.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        ...beings.map((b) => _chip('🐾 $b')),
                        ...symbols.map((s) => _chip('✨ $s')),
                      ],
                    ),
                  ],
                  if ((r['message'] as String?)?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: _kDeep.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: _kDeep.withValues(alpha: 0.3))),
                      child: Row(children: [
                        const Icon(Icons.format_quote,
                            color: _kDeep, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(r['message'] as String,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic)),
                        ),
                      ]),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _chip(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: _kBorder, borderRadius: BorderRadius.circular(10)),
        child: Text(text,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
      );
}

class _PowerAnimalsSubTab extends StatefulWidget {
  const _PowerAnimalsSubTab();
  @override
  State<_PowerAnimalsSubTab> createState() => _PowerAnimalsSubTabState();
}

class _PowerAnimalsSubTabState extends State<_PowerAnimalsSubTab> {
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = _db.auth.currentUser;
      if (user == null) {
        setState(() {
          _loading = false;
          _error = 'Bitte zuerst anmelden';
        });
        return;
      }
      final rows = await _db
          .from('shamanic_power_animals')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      if (!mounted) return;
      setState(() {
        _rows = List<Map<String, dynamic>>.from(rows);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  Future<void> _openEditor({Map<String, dynamic>? existing}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PowerAnimalEditorSheet(existing: existing),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(String id) async {
    try {
      await _db.from('shamanic_power_animals').delete().eq('id', id);
      if (!mounted) return;
      setState(() => _rows.removeWhere((r) => r['id'] == id));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _kDeep,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Krafttier'),
        onPressed: () => _openEditor(),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _kDeep));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_error!, style: const TextStyle(color: Colors.white54)),
            const SizedBox(height: 12),
            TextButton(
                onPressed: _load,
                child: const Text('Erneut versuchen',
                    style: TextStyle(color: _kDeep))),
          ]),
        ),
      );
    }
    if (_rows.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.pets, color: _kDeep, size: 48),
            SizedBox(height: 12),
            Text('Noch keine Krafttiere eingetragen.\nFüge dein erstes Krafttier hinzu.',
                style: TextStyle(color: Colors.white54),
                textAlign: TextAlign.center),
          ]),
        ),
      );
    }
    return RefreshIndicator(
      color: _kDeep,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
        itemCount: _rows.length,
        itemBuilder: (_, i) {
          final r = _rows[i];
          final qualities =
              List<String>.from((r['qualities'] as List?) ?? const []);
          final active = r['is_active'] as bool? ?? true;
          return Card(
            color: _kCardBg,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                    color: active
                        ? _kDeep.withValues(alpha: 0.4)
                        : _kBorder)),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _openEditor(existing: r),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor:
                            active ? _kDeep : Colors.white24,
                        child: const Text('🐾',
                            style: TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r['animal'] as String? ?? '—',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700)),
                            if (!active)
                              const Text('(nicht mehr aktiv)',
                                  style: TextStyle(
                                      color: Colors.white38,
                                      fontSize: 11)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.white38, size: 20),
                        onPressed: () => _delete(r['id'] as String),
                      ),
                    ]),
                    if (qualities.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: qualities
                            .map((q) => Chip(
                                  label: Text(q,
                                      style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11)),
                                  backgroundColor: _kBorder,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                ))
                            .toList(),
                      ),
                    ],
                    if ((r['message'] as String?)?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 10),
                      Text(r['message'] as String,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PowerAnimalEditorSheet extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const _PowerAnimalEditorSheet({this.existing});
  @override
  State<_PowerAnimalEditorSheet> createState() =>
      _PowerAnimalEditorSheetState();
}

class _PowerAnimalEditorSheetState extends State<_PowerAnimalEditorSheet> {
  final _animalCtrl = TextEditingController();
  final _qualitiesCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  final _giftsCtrl = TextEditingController();
  bool _active = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _animalCtrl.text = e['animal'] as String? ?? '';
      _qualitiesCtrl.text =
          List<String>.from((e['qualities'] as List?) ?? const [])
              .join(', ');
      _messageCtrl.text = e['message'] as String? ?? '';
      _giftsCtrl.text = e['gifts'] as String? ?? '';
      _active = e['is_active'] as bool? ?? true;
    }
  }

  @override
  void dispose() {
    _animalCtrl.dispose();
    _qualitiesCtrl.dispose();
    _messageCtrl.dispose();
    _giftsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final animal = _animalCtrl.text.trim();
    if (animal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name des Krafttiers fehlt')));
      return;
    }
    final user = _db.auth.currentUser;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      final qualities = _qualitiesCtrl.text
          .split(RegExp(r'[,\n]'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      final payload = {
        'animal': animal,
        'qualities': qualities,
        'message': _messageCtrl.text.trim().isEmpty
            ? null
            : _messageCtrl.text.trim(),
        'gifts': _giftsCtrl.text.trim().isEmpty
            ? null
            : _giftsCtrl.text.trim(),
        'is_active': _active,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (widget.existing == null) {
        await _db.from('shamanic_power_animals').insert({
          ...payload,
          'user_id': user.id,
        });
      } else {
        await _db
            .from('shamanic_power_animals')
            .update(payload)
            .eq('id', widget.existing!['id'] as String);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: _kDarkBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(children: [
                const Icon(Icons.pets, color: _kDeep),
                const SizedBox(width: 8),
                Text(
                    widget.existing == null
                        ? 'Neues Krafttier'
                        : 'Krafttier bearbeiten',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context, false),
                ),
              ]),
            ),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  _field(_animalCtrl, 'Krafttier*', Icons.pets_outlined),
                  const SizedBox(height: 12),
                  _field(_qualitiesCtrl,
                      'Qualitäten (kommagetrennt)',
                      Icons.auto_awesome,
                      maxLines: 2),
                  const SizedBox(height: 12),
                  _field(_messageCtrl, 'Botschaft', Icons.message_outlined,
                      maxLines: 3),
                  const SizedBox(height: 12),
                  _field(_giftsCtrl, 'Gaben / Werkzeuge',
                      Icons.card_giftcard_outlined,
                      maxLines: 2),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: _kDeep,
                    title: const Text('Aktiver Begleiter',
                        style: TextStyle(color: Colors.white)),
                    subtitle: const Text(
                        'Noch in meinem Leben präsent',
                        style: TextStyle(
                            color: Colors.white54, fontSize: 12)),
                    value: _active,
                    onChanged: (v) => setState(() => _active = v),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save_outlined),
                      label: Text(widget.existing == null
                          ? 'Speichern'
                          : 'Aktualisieren'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kDeep,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon,
      {int maxLines = 1}) {
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
// Tab 2: Leitfäden  (Phase 2.2d)
// ─────────────────────────────────────────────────────────────────────────────

const Map<String, String> _kGuideWorldLabels = {
  'lower': 'Unterwelt',
  'upper': 'Oberwelt',
  'middle': 'Mittlere Welt',
  'any': 'Alle Welten',
};

class _GuidesTab extends StatefulWidget {
  const _GuidesTab();
  @override
  State<_GuidesTab> createState() => _GuidesTabState();
}

class _GuidesTabState extends State<_GuidesTab> {
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await _db
          .from('shamanic_journey_guides')
          .select()
          .order('sort_order', ascending: true);
      if (!mounted) return;
      setState(() {
        _rows = List<Map<String, dynamic>>.from(rows);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  void _openDetail(Map<String, dynamic> g) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GuideDetailSheet(guide: g),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _kDeep));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_error!, style: const TextStyle(color: Colors.white54)),
            const SizedBox(height: 12),
            TextButton(
                onPressed: _load,
                child: const Text('Erneut versuchen',
                    style: TextStyle(color: _kDeep))),
          ]),
        ),
      );
    }
    return RefreshIndicator(
      color: _kDeep,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
        itemCount: _rows.length,
        itemBuilder: (_, i) {
          final g = _rows[i];
          final steps = (g['steps'] as List?)?.length ?? 0;
          return Card(
            color: _kCardBg,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: _kDeep.withValues(alpha: 0.3))),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _openDetail(g),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(g['emoji'] as String? ?? '🥁',
                          style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(g['title'] as String? ?? '—',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                    color: _kDeep.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10)),
                                child: Text(
                                    _kGuideWorldLabels[g['world']] ??
                                        g['world'],
                                    style: const TextStyle(
                                        color: _kDeep,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600)),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.schedule,
                                  color: Colors.white38, size: 12),
                              const SizedBox(width: 3),
                              Text('${g['duration_minutes']} Min',
                                  style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 11)),
                              const SizedBox(width: 10),
                              const Icon(Icons.format_list_numbered,
                                  color: Colors.white38, size: 12),
                              const SizedBox(width: 3),
                              Text('$steps Schritte',
                                  style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 11)),
                            ]),
                          ],
                        ),
                      ),
                    ]),
                    const SizedBox(height: 10),
                    Text(g['description'] as String? ?? '',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            height: 1.4)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GuideDetailSheet extends StatelessWidget {
  final Map<String, dynamic> guide;
  const _GuideDetailSheet({required this.guide});

  @override
  Widget build(BuildContext context) {
    final steps = List<String>.from((guide['steps'] as List?) ?? const []);
    final intentions = List<String>.from(
        (guide['sample_intentions'] as List?) ?? const []);
    final preparation = guide['preparation'] as String?;
    final safety = guide['safety_notes'] as String?;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: _kDarkBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(children: [
              Text(guide['emoji'] as String? ?? '🥁',
                  style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(guide['title'] as String? ?? '—',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 3),
                    Text(
                        '${_kGuideWorldLabels[guide['world']] ?? guide['world']}  •  ${guide['duration_minutes']} Minuten',
                        style: const TextStyle(
                            color: _kDeep,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
          ),
          Expanded(
            child: ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              children: [
                Text(guide['description'] as String? ?? '',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 14, height: 1.5)),
                if (intentions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Beispiel-Intentionen',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...intentions.map((t) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.arrow_right,
                                color: _kDeep, size: 18),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(t,
                                  style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                      fontStyle: FontStyle.italic)),
                            ),
                          ],
                        ),
                      )),
                ],
                if (preparation != null && preparation.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _infoBox('Vorbereitung', preparation,
                      Icons.checklist_outlined, _kDeep),
                ],
                if (safety != null && safety.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _infoBox('Sicherheit', safety, Icons.shield_outlined,
                      const Color(0xFFFFAB40)),
                ],
                if (steps.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text('Ablauf',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  for (int i = 0; i < steps.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(
                                color: _kDeep, shape: BoxShape.circle),
                            alignment: Alignment.center,
                            child: Text('${i + 1}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(steps[i],
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      height: 1.5)),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _infoBox(String title, String body, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1)),
              const SizedBox(height: 4),
              Text(body,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.4)),
            ],
          ),
        ),
      ]),
    );
  }
}
