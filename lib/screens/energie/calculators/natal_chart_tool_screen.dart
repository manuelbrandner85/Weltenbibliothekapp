import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/natal_astrology_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NatalChartToolScreen – Geburtshoroskop (Tool 1)
//   Tab 0: Neu       (Geburtsdaten eingeben → berechnen → speichern)
//   Tab 1: Verlauf   (gespeicherte Charts laden / ansehen / löschen)
//   Tab 2: Lexikon   (Zeichen / Planeten-Bedeutungen)
// ─────────────────────────────────────────────────────────────────────────────

const _kIndigo = Color(0xFF6C63FF);
const _kDarkBg = Color(0xFF0A0A0F);
const _kCardBg = Color(0xFF1A1A2E);
const _kBorder = Color(0xFF2A2A4E);

final _db = Supabase.instance.client;

class NatalChartToolScreen extends StatefulWidget {
  const NatalChartToolScreen({super.key});

  @override
  State<NatalChartToolScreen> createState() => _NatalChartToolScreenState();
}

class _NatalChartToolScreenState extends State<NatalChartToolScreen>
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
        title: const Text('♓ Geburtshoroskop',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: _kIndigo,
          labelColor: _kIndigo,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(icon: Icon(Icons.auto_awesome), text: 'Neu'),
            Tab(icon: Icon(Icons.history), text: 'Verlauf'),
            Tab(icon: Icon(Icons.menu_book), text: 'Lexikon'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _NewChartTab(),
          _HistoryTab(),
          _LexiconTab(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 0: Neu (Phase 1.2c)
// ─────────────────────────────────────────────────────────────────────────────

class _NewChartTab extends StatefulWidget {
  const _NewChartTab();
  @override
  State<_NewChartTab> createState() => _NewChartTabState();
}

class _NewChartTabState extends State<_NewChartTab> {
  final _labelCtrl = TextEditingController(text: 'Ich');
  final _placeCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  final _tzCtrl = TextEditingController(text: '1');

  DateTime _birthDate = DateTime(1990, 1, 1);
  TimeOfDay? _birthTime;
  bool _timeUnknown = false;
  bool _saving = false;
  NatalChartResult? _result;

  @override
  void dispose() {
    _labelCtrl.dispose();
    _placeCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _tzCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: _kIndigo),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _birthTime ?? const TimeOfDay(hour: 12, minute: 0),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: _kIndigo),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _birthTime = picked);
  }

  void _compute() {
    final tz = double.tryParse(_tzCtrl.text.replaceAll(',', '.')) ?? 0.0;
    final lat = double.tryParse(_latCtrl.text.replaceAll(',', '.'));
    final lng = double.tryParse(_lngCtrl.text.replaceAll(',', '.'));

    // Baue UTC-DateTime aus Geburtsdatum + Zeit − TZ-Offset.
    DateTime local;
    if (_timeUnknown || _birthTime == null) {
      local = DateTime(_birthDate.year, _birthDate.month, _birthDate.day, 12, 0);
    } else {
      local = DateTime(_birthDate.year, _birthDate.month, _birthDate.day,
          _birthTime!.hour, _birthTime!.minute);
    }
    final utc = local.subtract(Duration(minutes: (tz * 60).round())).toUtc();

    final hasTimeAndPlace = !_timeUnknown &&
        _birthTime != null &&
        lat != null &&
        lng != null;

    final result = NatalAstrology.compute(
      birthDateUtc: utc,
      latitude: hasTimeAndPlace ? lat : null,
      longitude: hasTimeAndPlace ? lng : null,
    );
    setState(() => _result = result);
  }

  Future<void> _save() async {
    if (_result == null) return;
    final user = _db.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Bitte anmelden, um Charts zu speichern.'),
      ));
      return;
    }
    setState(() => _saving = true);
    try {
      final tz = double.tryParse(_tzCtrl.text.replaceAll(',', '.')) ?? 0.0;
      final lat = double.tryParse(_latCtrl.text.replaceAll(',', '.'));
      final lng = double.tryParse(_lngCtrl.text.replaceAll(',', '.'));
      final r = _result!;

      final row = {
        'user_id': user.id,
        'label': _labelCtrl.text.trim().isEmpty ? 'Chart' : _labelCtrl.text.trim(),
        'birth_date':
            '${_birthDate.year.toString().padLeft(4, "0")}-${_birthDate.month.toString().padLeft(2, "0")}-${_birthDate.day.toString().padLeft(2, "0")}',
        'birth_time': (_timeUnknown || _birthTime == null)
            ? null
            : '${_birthTime!.hour.toString().padLeft(2, "0")}:${_birthTime!.minute.toString().padLeft(2, "0")}:00',
        'birth_time_unknown': _timeUnknown,
        'birth_place': _placeCtrl.text.trim().isEmpty ? null : _placeCtrl.text.trim(),
        'birth_latitude': lat,
        'birth_longitude': lng,
        'timezone_offset_hours': tz,
        for (final p in kPlanetNames) ...{
          '${p}_sign': r.planets[p]?.sign,
          '${p}_degree': r.planets[p]?.degree,
        },
        'ascendant_sign': r.ascendant?.sign,
        'ascendant_degree': r.ascendant?.degree,
        'mc_sign': r.mc?.sign,
        'mc_degree': r.mc?.degree,
        'computation': r.computation,
      };
      await _db.from('natal_charts').insert(row);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Chart gespeichert.'),
        backgroundColor: _kIndigo,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Fehler: $e'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _section('Person / Titel'),
        _textField(_labelCtrl, 'z. B. Ich / Partner / Kind'),
        const SizedBox(height: 20),
        _section('Geburtsdatum'),
        _pickerTile(
          icon: Icons.calendar_today,
          label: '${_birthDate.day}.${_birthDate.month}.${_birthDate.year}',
          onTap: _pickDate,
        ),
        const SizedBox(height: 12),
        _section('Geburtszeit (für Aszendent)'),
        Row(
          children: [
            Expanded(
              child: _pickerTile(
                icon: Icons.schedule,
                label: _timeUnknown
                    ? 'Zeit unbekannt'
                    : (_birthTime == null
                        ? 'Zeit wählen'
                        : '${_birthTime!.hour.toString().padLeft(2, "0")}:${_birthTime!.minute.toString().padLeft(2, "0")}'),
                onTap: _timeUnknown ? null : _pickTime,
              ),
            ),
          ],
        ),
        CheckboxListTile(
          value: _timeUnknown,
          onChanged: (v) => setState(() => _timeUnknown = v ?? false),
          title: const Text('Zeit unbekannt',
              style: TextStyle(color: Colors.white70)),
          checkColor: Colors.white,
          activeColor: _kIndigo,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        ),
        const SizedBox(height: 8),
        _section('Geburtsort (optional, für Aszendent)'),
        _textField(_placeCtrl, 'Stadt, Land'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _textField(_latCtrl, 'Breite (Lat, z. B. 48.2)')),
            const SizedBox(width: 8),
            Expanded(child: _textField(_lngCtrl, 'Länge (Lng, z. B. 16.37)')),
          ],
        ),
        const SizedBox(height: 8),
        _textField(_tzCtrl, 'Zeitzone Offset Stunden (z. B. 1 = MEZ, 2 = MESZ)'),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _compute,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Berechnen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kIndigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: (_result == null || _saving) ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save),
                label: const Text('Speichern'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kCardBg,
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: _kBorder),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (_result != null) _ChartResultCard(result: _result!),
      ],
    );
  }

  Widget _section(String s) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(s,
            style: const TextStyle(
                color: _kIndigo,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3)),
      );

  Widget _textField(TextEditingController c, String hint) {
    return TextField(
      controller: c,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: _kCardBg,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kIndigo),
        ),
      ),
    );
  }

  Widget _pickerTile({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: _kIndigo, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      color: onTap == null ? Colors.white38 : Colors.white)),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chart-Ergebnis Card – Liste aller Planeten + ggf. AC/MC
// ─────────────────────────────────────────────────────────────────────────────

class _ChartResultCard extends StatelessWidget {
  final NatalChartResult result;
  const _ChartResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (final key in kPlanetNames) {
      final p = result.planets[key];
      if (p == null) continue;
      rows.add(_row(
        glyph: kPlanetGlyphs[key] ?? '•',
        label: kPlanetLabels[key] ?? key,
        pos: p,
      ));
    }
    if (result.ascendant != null) {
      rows.add(_row(glyph: 'AC', label: 'Aszendent', pos: result.ascendant!));
    }
    if (result.mc != null) {
      rows.add(_row(glyph: 'MC', label: 'Medium Coeli', pos: result.mc!));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Dein Geburtshoroskop',
              style: TextStyle(
                  color: _kIndigo,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const SizedBox(height: 4),
          const Text(
            'Zeichen-Positionen (Tropischer Zodiak, geozentrische Länge)',
            style: TextStyle(color: Colors.white54, fontSize: 11),
          ),
          const SizedBox(height: 12),
          ...rows,
        ],
      ),
    );
  }

  Widget _row({required String glyph, required String label, required PlanetPosition pos}) {
    final sign = kZodiacSigns[pos.sign];
    final glyphSign = kZodiacGlyphs[pos.sign];
    final deg = pos.degree.floor();
    final min = ((pos.degree - deg) * 60).round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(glyph,
                style: const TextStyle(
                    color: _kIndigo, fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 13)),
          ),
          Text('$glyphSign  ',
              style: const TextStyle(color: Colors.white70, fontSize: 15)),
          Expanded(
            child: Text('$sign  $deg° ${min.toString().padLeft(2, "0")}′',
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1: Verlauf (Phase 1.2d) – Skeleton
// ─────────────────────────────────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Gespeicherte Charts…\n(Phase 1.2d)',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white70, fontSize: 16),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2: Lexikon (Phase 1.2e) – Skeleton
// ─────────────────────────────────────────────────────────────────────────────

class _LexiconTab extends StatelessWidget {
  const _LexiconTab();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Astrologie-Lexikon…\n(Phase 1.2e)',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white70, fontSize: 16),
      ),
    );
  }
}
