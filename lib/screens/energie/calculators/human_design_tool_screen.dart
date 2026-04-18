import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/human_design_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HumanDesignToolScreen – Tool 3
//   Tab 0: Neu       (Geburtsdaten → Type/Profile/Authority/Centers/Gates)
//   Tab 1: Verlauf   (gespeicherte HD-Charts)
//   Tab 2: Lexikon   (Types, Authorities, Centers, 64 Gates)
// ─────────────────────────────────────────────────────────────────────────────

const _kTeal = Color(0xFF26C6DA);
const _kDarkBg = Color(0xFF0A0A0F);
const _kCardBg = Color(0xFF1A1A2E);
const _kBorder = Color(0xFF2A2A4E);

final _db = Supabase.instance.client;

class HumanDesignToolScreen extends StatefulWidget {
  const HumanDesignToolScreen({super.key});

  @override
  State<HumanDesignToolScreen> createState() => _HumanDesignToolScreenState();
}

class _HumanDesignToolScreenState extends State<HumanDesignToolScreen>
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
        title: const Text('🌀 Human Design',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: _kTeal,
          labelColor: _kTeal,
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
          _NewHdTab(),
          _HdHistoryTab(),
          _HdLexiconTab(),
        ],
      ),
    );
  }
}

class _NewHdTab extends StatefulWidget {
  const _NewHdTab();
  @override
  State<_NewHdTab> createState() => _NewHdTabState();
}

class _NewHdTabState extends State<_NewHdTab> {
  final _labelCtrl = TextEditingController(text: 'Ich');
  final _placeCtrl = TextEditingController();
  final _tzCtrl = TextEditingController(text: '1');

  DateTime _birthDate = DateTime(1990, 1, 1);
  TimeOfDay? _birthTime;
  bool _timeUnknown = false;
  bool _saving = false;
  HumanDesignResult? _result;

  @override
  void dispose() {
    _labelCtrl.dispose();
    _placeCtrl.dispose();
    _tzCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (_, c) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: _kTeal),
        ),
        child: c!,
      ),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _birthTime ?? const TimeOfDay(hour: 12, minute: 0),
      builder: (_, c) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: _kTeal),
        ),
        child: c!,
      ),
    );
    if (picked != null) setState(() => _birthTime = picked);
  }

  void _compute() {
    final tz = double.tryParse(_tzCtrl.text.replaceAll(',', '.')) ?? 0.0;
    DateTime local;
    if (_timeUnknown || _birthTime == null) {
      local = DateTime(_birthDate.year, _birthDate.month, _birthDate.day, 12, 0);
    } else {
      local = DateTime(_birthDate.year, _birthDate.month, _birthDate.day,
          _birthTime!.hour, _birthTime!.minute);
    }
    final utc = local.subtract(Duration(minutes: (tz * 60).round())).toUtc();
    final r = HumanDesign.compute(birthDateUtc: utc);
    setState(() => _result = r);
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
      final r = _result!;
      final row = {
        'user_id': user.id,
        'label': _labelCtrl.text.trim().isEmpty ? 'HD-Chart' : _labelCtrl.text.trim(),
        'birth_date':
            '${_birthDate.year.toString().padLeft(4, "0")}-${_birthDate.month.toString().padLeft(2, "0")}-${_birthDate.day.toString().padLeft(2, "0")}',
        'birth_time': (_timeUnknown || _birthTime == null)
            ? null
            : '${_birthTime!.hour.toString().padLeft(2, "0")}:${_birthTime!.minute.toString().padLeft(2, "0")}:00',
        'birth_time_unknown': _timeUnknown,
        'birth_place': _placeCtrl.text.trim().isEmpty ? null : _placeCtrl.text.trim(),
        'timezone_offset_hours': tz,
        'type': r.type,
        'authority': r.authority,
        'strategy': r.strategy,
        'profile': r.profile,
        'defined_gates': r.definedGates.toList()..sort(),
        'defined_centers': r.definedCenters.toList(),
        'computation': r.computation,
      };
      await _db.from('human_design_charts').insert(row);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Chart gespeichert.'),
        backgroundColor: _kTeal,
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
        _textField(_labelCtrl, 'z. B. Ich'),
        const SizedBox(height: 20),
        _section('Geburtsdatum'),
        _pickerTile(
          icon: Icons.calendar_today,
          label: '${_birthDate.day}.${_birthDate.month}.${_birthDate.year}',
          onTap: _pickDate,
        ),
        const SizedBox(height: 12),
        _section('Geburtszeit (für präzises Profil)'),
        _pickerTile(
          icon: Icons.schedule,
          label: _timeUnknown
              ? 'Zeit unbekannt'
              : (_birthTime == null
                  ? 'Zeit wählen'
                  : '${_birthTime!.hour.toString().padLeft(2, "0")}:${_birthTime!.minute.toString().padLeft(2, "0")}'),
          onTap: _timeUnknown ? null : _pickTime,
        ),
        CheckboxListTile(
          value: _timeUnknown,
          onChanged: (v) => setState(() => _timeUnknown = v ?? false),
          title: const Text('Zeit unbekannt',
              style: TextStyle(color: Colors.white70)),
          checkColor: Colors.white,
          activeColor: _kTeal,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        ),
        _section('Ort + Zeitzone'),
        _textField(_placeCtrl, 'Stadt, Land (optional)'),
        const SizedBox(height: 8),
        _textField(_tzCtrl, 'Zeitzone Offset Stunden (z. B. 1 = MEZ)'),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _compute,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Berechnen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kTeal,
                  foregroundColor: Colors.black,
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
        if (_result != null) _HdResultCard(result: _result!),
      ],
    );
  }

  Widget _section(String s) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(s,
            style: const TextStyle(
                color: _kTeal,
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
          borderSide: const BorderSide(color: _kTeal),
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
            Icon(icon, color: _kTeal, size: 20),
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
// Ergebnis-Card: Type / Profile / Authority / Strategy + Centers + Gates
// ─────────────────────────────────────────────────────────────────────────────

class _HdResultCard extends StatelessWidget {
  final HumanDesignResult result;
  const _HdResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
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
          const Text('Dein Human-Design',
              style: TextStyle(
                  color: _kTeal,
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          const SizedBox(height: 12),
          _kvRow('Typ', kHdTypeLabels[result.type] ?? result.type),
          _kvRow('Profil', result.profile),
          _kvRow('Strategie',
              kHdStrategyLabels[result.strategy] ?? result.strategy),
          _kvRow('Autorität',
              kHdAuthorityLabels[result.authority] ?? result.authority),
          const SizedBox(height: 16),
          const Text('Definierte Zentren',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: kCenters.map((c) {
              final def = result.definedCenters.contains(c);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: def ? _kTeal : _kCardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: def ? _kTeal : Colors.white24, width: 1),
                ),
                child: Text(
                  kHdCenterLabels[c] ?? c,
                  style: TextStyle(
                    color: def ? Colors.black : Colors.white54,
                    fontWeight: def ? FontWeight.bold : FontWeight.normal,
                    fontSize: 11,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text('Aktivierte Tore',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: (result.definedGates.toList()..sort())
                .map((g) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _kTeal.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: _kTeal.withValues(alpha: 0.4)),
                      ),
                      child: Text('$g',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12)),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          ExpansionTile(
            title: const Text('Aktivierungen (Personality / Design)',
                style: TextStyle(color: _kTeal, fontWeight: FontWeight.bold)),
            iconColor: _kTeal,
            collapsedIconColor: _kTeal,
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            children: [
              _activationTable('Personality ☉ (bewusst)', result.personality),
              const SizedBox(height: 8),
              _activationTable('Design ☉ (unbewusst, 88°)', result.design),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kvRow(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(k,
                  style: const TextStyle(color: Colors.white54, fontSize: 13)),
            ),
            Expanded(
              child: Text(v,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );

  Widget _activationTable(String title, List<HdActivation> acts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
                fontSize: 13)),
        const SizedBox(height: 4),
        ...acts.map((a) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(kHdBodyLabels[a.body] ?? a.body,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                  Text('${a.gate}.${a.line}',
                      style: const TextStyle(
                          color: _kTeal,
                          fontSize: 13,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            )),
      ],
    );
  }
}

class _HdHistoryTab extends StatefulWidget {
  const _HdHistoryTab();
  @override
  State<_HdHistoryTab> createState() => _HdHistoryTabState();
}

class _HdHistoryTabState extends State<_HdHistoryTab> {
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
        .from('human_design_charts')
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
      await _db.from('human_design_charts').delete().eq('id', id);
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
      color: _kTeal,
      backgroundColor: _kCardBg,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(
                child: CircularProgressIndicator(color: _kTeal));
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
                    'Noch keine HD-Charts gespeichert.\nGehe zu "Neu", um dein Design zu berechnen.',
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
            itemBuilder: (_, i) => _HdHistoryCard(
              data: items[i],
              onDelete: () => _delete(items[i]['id'] as String),
            ),
          );
        },
      ),
    );
  }
}

class _HdHistoryCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onDelete;
  const _HdHistoryCard({required this.data, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final label = (data['label'] as String?) ?? 'Chart';
    final date = (data['birth_date'] as String?) ?? '';
    final type = (data['type'] as String?) ?? '';
    final profile = (data['profile'] as String?) ?? '';
    final auth = (data['authority'] as String?) ?? '';

    return InkWell(
      onTap: () => _showDetail(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
            Text(date,
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (type.isNotEmpty)
                  _chip(kHdTypeLabels[type] ?? type),
                if (profile.isNotEmpty) _chip('Profil $profile'),
                if (auth.isNotEmpty)
                  _chip(kHdAuthorityLabels[auth] ?? auth),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String s) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _kTeal.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kTeal.withValues(alpha: 0.4)),
        ),
        child: Text(s,
            style: const TextStyle(color: Colors.white, fontSize: 11)),
      );

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
        builder: (_, ctrl) => _HdChartDetailView(data: data, scroll: ctrl),
      ),
    );
  }
}

class _HdChartDetailView extends StatelessWidget {
  final Map<String, dynamic> data;
  final ScrollController scroll;
  const _HdChartDetailView({required this.data, required this.scroll});

  @override
  Widget build(BuildContext context) {
    final definedCenters = ((data['defined_centers'] as List?)?.cast<String>() ?? const [])
        .toSet();
    final definedGates = ((data['defined_gates'] as List?)?.cast<int>() ?? const []);
    final type = (data['type'] as String?) ?? '';
    final profile = (data['profile'] as String?) ?? '';
    final auth = (data['authority'] as String?) ?? '';
    final strategy = (data['strategy'] as String?) ?? '';

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
            data['label'] as String? ?? 'HD-Chart',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            '${data['birth_date'] ?? ''}'
            '${data['birth_time'] != null ? "  ·  ${data['birth_time']}" : ""}'
            '${(data['birth_place'] as String?)?.isNotEmpty == true ? "\n${data['birth_place']}" : ""}',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 20),
          _row('Typ', kHdTypeLabels[type] ?? type),
          _row('Profil', profile),
          _row('Strategie', kHdStrategyLabels[strategy] ?? strategy),
          _row('Autorität', kHdAuthorityLabels[auth] ?? auth),
          const SizedBox(height: 20),
          const Text('Zentren',
              style: TextStyle(
                  color: _kTeal, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: kCenters.map((c) {
              final def = definedCenters.contains(c);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: def ? _kTeal : _kCardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: def ? _kTeal : Colors.white24, width: 1),
                ),
                child: Text(
                  kHdCenterLabels[c] ?? c,
                  style: TextStyle(
                    color: def ? Colors.black : Colors.white54,
                    fontWeight: def ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Text('Aktivierte Tore',
              style: TextStyle(
                  color: _kTeal, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: (definedGates.toList()..sort())
                .map((g) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _kTeal.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('$g',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12)),
                    ))
                .toList(),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(k,
                  style: const TextStyle(color: Colors.white54, fontSize: 13)),
            ),
            Expanded(
              child: Text(v,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
}

class _HdLexiconTab extends StatelessWidget {
  const _HdLexiconTab();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('HD-Lexikon…\n(Phase 3.2e)',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 16)),
    );
  }
}
