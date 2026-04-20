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
// Tab 1: Verlauf (Phase 1.2d) – Liste gespeicherter Charts
// ─────────────────────────────────────────────────────────────────────────────

class _HistoryTab extends StatefulWidget {
  const _HistoryTab();
  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final user = _db.auth.currentUser;
    if (user == null) return [];
    final res = await _db
        .from('natal_charts')
        .select()
        .eq('user_id', user.id)
        .order('computed_at', ascending: false);
    return (res as List).cast<Map<String, dynamic>>();
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _delete(String id) async {
    try {
      await _db.from('natal_charts').delete().eq('id', id);
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Löschen fehlgeschlagen: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      color: _kIndigo,
      backgroundColor: _kCardBg,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: _kIndigo),
            );
          }
          if (snap.hasError) {
            return ListView(children: [
              const SizedBox(height: 120),
              Center(
                child: Text('Fehler: ${snap.error}',
                    style: const TextStyle(color: Colors.white70)),
              ),
            ]);
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return ListView(children: const [
              SizedBox(height: 120),
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Noch keine Charts gespeichert.\nGehe zu "Neu", um dein Geburtshoroskop zu berechnen.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              ),
            ]);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (_, i) =>
                _HistoryCard(data: items[i], onDelete: () => _delete(items[i]['id'] as String)),
          );
        },
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onDelete;
  const _HistoryCard({required this.data, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final label = (data['label'] as String?) ?? 'Chart';
    final date = (data['birth_date'] as String?) ?? '';
    final place = (data['birth_place'] as String?) ?? '';
    final sunSign = data['sun_sign'] as int?;
    final moonSign = data['moon_sign'] as int?;
    final ascSign = data['ascendant_sign'] as int?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ),
              IconButton(
                onPressed: () => _confirmDelete(context),
                icon: const Icon(Icons.delete_outline, color: Colors.white54),
                tooltip: 'Löschen',
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text('$date${place.isNotEmpty ? "  ·  $place" : ""}',
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            children: [
              if (sunSign != null)
                _miniChip('☉', kZodiacSigns[sunSign], kZodiacGlyphs[sunSign]),
              if (moonSign != null)
                _miniChip('☽', kZodiacSigns[moonSign], kZodiacGlyphs[moonSign]),
              if (ascSign != null)
                _miniChip('AC', kZodiacSigns[ascSign], kZodiacGlyphs[ascSign]),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _showDetail(context),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Öffnen'),
              style: TextButton.styleFrom(foregroundColor: _kIndigo),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniChip(String glyph, String sign, String signGlyph) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _kIndigo.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kIndigo.withValues(alpha: 0.3)),
      ),
      child: Text('$glyph  $signGlyph $sign',
          style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kCardBg,
        title: const Text('Chart löschen?',
            style: TextStyle(color: Colors.white)),
        content: Text(
            'Möchtest du "${data['label']}" wirklich entfernen?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen',
                style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete();
            },
            child: const Text('Löschen',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _kDarkBg,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => _ChartDetailView(data: data, scroll: controller),
      ),
    );
  }
}

class _ChartDetailView extends StatelessWidget {
  final Map<String, dynamic> data;
  final ScrollController scroll;
  const _ChartDetailView({required this.data, required this.scroll});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (final key in kPlanetNames) {
      final sign = data['${key}_sign'] as int?;
      final deg = (data['${key}_degree'] as num?)?.toDouble();
      if (sign == null || deg == null) continue;
      rows.add(_detailRow(
        glyph: kPlanetGlyphs[key] ?? '•',
        label: kPlanetLabels[key] ?? key,
        sign: sign,
        degree: deg,
      ));
    }
    final ascSign = data['ascendant_sign'] as int?;
    final ascDeg = (data['ascendant_degree'] as num?)?.toDouble();
    if (ascSign != null && ascDeg != null) {
      rows.add(_detailRow(
          glyph: 'AC', label: 'Aszendent', sign: ascSign, degree: ascDeg));
    }
    final mcSign = data['mc_sign'] as int?;
    final mcDeg = (data['mc_degree'] as num?)?.toDouble();
    if (mcSign != null && mcDeg != null) {
      rows.add(_detailRow(
          glyph: 'MC', label: 'Medium Coeli', sign: mcSign, degree: mcDeg));
    }

    return Container(
      decoration: const BoxDecoration(
        color: _kDarkBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: ListView(
        controller: scroll,
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            data['label'] as String? ?? 'Chart',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '${data['birth_date'] ?? ''}'
            '${data['birth_time'] != null ? "  ·  ${data['birth_time']}" : ""}'
            '${(data['birth_place'] as String?)?.isNotEmpty == true ? "\n${data['birth_place']}" : ""}',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 20),
          ...rows,
          if ((data['notes'] as String?)?.isNotEmpty == true) ...[
            const SizedBox(height: 20),
            const Text('Notizen',
                style: TextStyle(
                    color: _kIndigo, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(data['notes'] as String,
                style: const TextStyle(color: Colors.white70)),
          ],
        ],
      ),
    );
  }

  Widget _detailRow({
    required String glyph,
    required String label,
    required int sign,
    required double degree,
  }) {
    final deg = degree.floor();
    final min = ((degree - deg) * 60).round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(glyph,
                style: const TextStyle(
                    color: _kIndigo, fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 14)),
          ),
          Text('${kZodiacGlyphs[sign]}  ',
              style: const TextStyle(color: Colors.white70, fontSize: 16)),
          Expanded(
            child: Text(
                '${kZodiacSigns[sign]}  $deg° ${min.toString().padLeft(2, "0")}′',
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2: Lexikon (Phase 1.2e) – Zeichen & Planeten aus astrology_meanings
// ─────────────────────────────────────────────────────────────────────────────

class _LexiconTab extends StatefulWidget {
  const _LexiconTab();
  @override
  State<_LexiconTab> createState() => _LexiconTabState();
}

class _LexiconTabState extends State<_LexiconTab> {
  String _category = 'sign';
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final res = await _db
        .from('astrology_meanings')
        .select()
        .eq('category', _category)
        .order('sort_order', ascending: true);
    return (res as List).cast<Map<String, dynamic>>();
  }

  void _switch(String cat) {
    if (_category == cat) return;
    setState(() {
      _category = cat;
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(child: _catChip('sign', '♈ Zeichen')),
              const SizedBox(width: 8),
              Expanded(child: _catChip('planet', '☉ Planeten')),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _future,
            builder: (ctx, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(
                    child: CircularProgressIndicator(color: _kIndigo));
              }
              if (snap.hasError) {
                return Center(
                    child: Text('Fehler: ${snap.error}',
                        style: const TextStyle(color: Colors.white70)));
              }
              final items = snap.data ?? [];
              if (items.isEmpty) {
                return const Center(
                    child: Text('Keine Einträge.',
                        style: TextStyle(color: Colors.white54)));
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                itemCount: items.length,
                itemBuilder: (_, i) => _LexiconCard(data: items[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _catChip(String cat, String label) {
    final active = _category == cat;
    return InkWell(
      onTap: () => _switch(cat),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: active ? _kIndigo : _kCardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? _kIndigo : _kBorder),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  color: active ? Colors.white : Colors.white70,
                  fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

class _LexiconCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _LexiconCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final title = data['title'] as String? ?? '';
    final emoji = data['emoji'] as String? ?? '✨';
    final short = data['short_text'] as String? ?? '';
    final keywords = (data['keywords'] as List?)?.cast<String>() ?? const [];

    return InkWell(
      onTap: () => _showDetail(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(short,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13)),
                  if (keywords.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: keywords
                          .take(4)
                          .map((k) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _kIndigo.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(k,
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 11)),
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _kDarkBg,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: _kDarkBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: ctrl,
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(data['emoji'] as String? ?? '',
                      style: const TextStyle(fontSize: 34)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(data['title'] as String? ?? '',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(data['short_text'] as String? ?? '',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.4)),
              if ((data['deep_text'] as String?)?.isNotEmpty == true) ...[
                const SizedBox(height: 20),
                const Text('Vertiefung',
                    style: TextStyle(
                        color: _kIndigo,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3)),
                const SizedBox(height: 6),
                Text(data['deep_text'] as String,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 14, height: 1.5)),
              ],
              if ((data['shadow_text'] as String?)?.isNotEmpty == true) ...[
                const SizedBox(height: 20),
                const Text('Schatten & Übung',
                    style: TextStyle(
                        color: Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3)),
                const SizedBox(height: 6),
                Text(data['shadow_text'] as String,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 14, height: 1.5)),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
