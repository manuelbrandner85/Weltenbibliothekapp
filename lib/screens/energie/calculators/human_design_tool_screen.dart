import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/human_design_service.dart';
import '../../../services/storage_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HumanDesignToolScreen – Tool 3
//   Tab 0: Neu       (Geburtsdaten → Type/Profile/Authority/Centers/Gates)
//   Tab 1: Verlauf   (gespeicherte HD-Charts)
//   Tab 2: Lexikon   (Types, Authorities, Centers, 64 Gates)
// ─────────────────────────────────────────────────────────────────────────────

const _kPrimary   = Color(0xFF00BCD4); // Türkis
const _kSecondary = Color(0xFF7C4DFF); // Lila
// Legacy alias:
const _kTeal   = _kPrimary;
const _kDarkBg = Color(0xFF06040F);
const _kCardBg = Color(0xFF080D14);
const _kBorder = Color(0xFF0E2030);

final _db = Supabase.instance.client;

class HumanDesignToolScreen extends StatefulWidget {
  const HumanDesignToolScreen({super.key});

  @override
  State<HumanDesignToolScreen> createState() => _HumanDesignToolScreenState();
}

class _HumanDesignToolScreenState extends State<HumanDesignToolScreen>
    with TickerProviderStateMixin {
  late final TabController _tabs;
  late AnimationController _bgCtrl;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kDarkBg,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF006064), Color(0xFF311B92)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        title: const Text('🌀 Human Design',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: _kPrimary,
          labelColor: _kPrimary,
          unselectedLabelColor: Colors.white54,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.auto_awesome), text: 'Neu'),
            Tab(icon: Icon(Icons.history), text: 'Verlauf'),
            Tab(icon: Icon(Icons.menu_book), text: 'Lexikon'),
            Tab(icon: Icon(Icons.fitness_center), text: 'Coaching'),
          ],
        ),
      ),
      body: AnimatedBuilder(
        animation: _bgCtrl,
        builder: (context, child) => Stack(
          children: [
            Positioned.fill(child: Container(color: _kDarkBg)),
            Positioned(
              top: -80 + _bgCtrl.value * 50,
              right: -60,
              child: _CineOrb(
                color: _kPrimary,
                size: 280,
                opacity: 0.10 + _bgCtrl.value * 0.05,
              ),
            ),
            Positioned(
              bottom: -80,
              left: -60 + _bgCtrl.value * 30,
              child: const _CineOrb(
                color: _kSecondary,
                size: 240,
                opacity: 0.08,
              ),
            ),
            Positioned(
              top: 300 + _bgCtrl.value * 40,
              left: 60,
              child: _CineOrb(
                color: _kPrimary,
                size: 160,
                opacity: 0.04 + _bgCtrl.value * 0.03,
              ),
            ),
            child!,
          ],
        ),
        child: TabBarView(
          controller: _tabs,
          children: const [
            _NewHdTab(),
            _HdHistoryTab(),
            _HdLexiconTab(),
            _HdCoachingTab(),
          ],
        ),
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
  bool _prefilled = false;
  HumanDesignResult? _result;

  @override
  void initState() {
    super.initState();
    _prefillFromProfile();
  }

  Future<void> _prefillFromProfile() async {
    final p = await StorageService().loadEnergieProfile();
    if (p == null || !mounted) return;
    setState(() {
      _placeCtrl.text = p.birthPlace;
      _birthDate = p.birthDate;
      // ✨ v93: tz aus Profil (via Auto-Geocoding gesetzt)
      if (p.timezoneOffsetHours != null) {
        _tzCtrl.text = p.timezoneOffsetHours!.toString();
      }
      if (p.birthTime != null && p.birthTime!.contains(':') && !p.birthTimeUnknown) {
        final parts = p.birthTime!.split(':');
        final h = int.tryParse(parts[0]) ?? 12;
        final m = int.tryParse(parts[1]) ?? 0;
        _birthTime = TimeOfDay(hour: h, minute: m);
      } else {
        _timeUnknown = p.birthTimeUnknown || p.birthTime == null;
      }
      _labelCtrl.text = p.firstName.isNotEmpty ? p.firstName : 'Ich';
      _prefilled = true;
    });
  }

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
        _section(_prefilled ? 'Ort + Zeitzone (aus deinem Profil)' : 'Ort + Zeitzone'),
        _textField(_placeCtrl, 'Stadt, Land'),
        const SizedBox(height: 8),
        _textField(_tzCtrl, 'Zeitzone: 1 = MEZ (Winter) · 2 = MESZ (Sommer)'),
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
        gradient: LinearGradient(
          colors: [
            _kPrimary.withValues(alpha: 0.15),
            _kSecondary.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Dein Human-Design',
              style: TextStyle(
                  color: _kPrimary,
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

class _HdLexiconTab extends StatefulWidget {
  const _HdLexiconTab();
  @override
  State<_HdLexiconTab> createState() => _HdLexiconTabState();
}

class _HdLexiconTabState extends State<_HdLexiconTab> {
  static const _cats = <Map<String, String>>[
    {'key': 'type', 'label': '5 Typen'},
    {'key': 'authority', 'label': 'Autoritäten'},
    {'key': 'center', 'label': '9 Zentren'},
    {'key': 'gate', 'label': '64 Tore'},
    {'key': 'strategy', 'label': 'Strategien'},
  ];

  String _category = 'type';
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final res = await _db
        .from('hd_meanings')
        .select()
        .eq('category', _category)
        .order('sort_order', ascending: true);
    return (res as List).cast<Map<String, dynamic>>();
  }

  void _switch(String c) {
    if (_category == c) return;
    setState(() {
      _category = c;
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: _cats.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final c = _cats[i];
              final active = c['key'] == _category;
              return InkWell(
                onTap: () => _switch(c['key']!),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? _kTeal : _kCardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: active ? _kTeal : _kBorder),
                  ),
                  child: Text(
                    c['label']!,
                    style: TextStyle(
                      color: active ? Colors.black : Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _future,
            builder: (ctx, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(
                    child: CircularProgressIndicator(color: _kTeal));
              }
              if (snap.hasError) {
                return Center(
                  child: Text('Fehler: ${snap.error}',
                      style: const TextStyle(color: Colors.white70)),
                );
              }
              final items = snap.data ?? [];
              if (items.isEmpty) {
                return const Center(
                  child: Text('Keine Einträge.',
                      style: TextStyle(color: Colors.white54)),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                itemCount: items.length,
                itemBuilder: (_, i) => _HdLexiconCard(data: items[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HdLexiconCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _HdLexiconCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final title = data['title'] as String? ?? '';
    final emoji = data['emoji'] as String? ?? '✨';
    final short = data['short_text'] as String? ?? '';
    final keywords = (data['keywords'] as List?)?.cast<String>() ?? const [];
    final hasDeep = (data['deep_text'] as String?)?.isNotEmpty == true ||
        (data['shadow_text'] as String?)?.isNotEmpty == true;

    return InkWell(
      onTap: hasDeep ? () => _showDetail(context) : null,
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
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(short,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13)),
                  if (keywords.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: keywords
                          .take(4)
                          .map((k) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _kTeal.withValues(alpha: 0.12),
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
                      style: const TextStyle(fontSize: 32)),
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
                      color: Colors.white, fontSize: 15, height: 1.4)),
              if ((data['deep_text'] as String?)?.isNotEmpty == true) ...[
                const SizedBox(height: 20),
                const Text('Vertiefung',
                    style: TextStyle(
                        color: _kTeal,
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

// ─────────────────────────────────────────────────────────────────────────────
// Cinema Orb – ambient background glow element
// ─────────────────────────────────────────────────────────────────────────────

class _CineOrb extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;
  const _CineOrb({
    required this.color,
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: 0),
          ]),
        ),
      );
}

// ═══════════════════════════════════════════════════════════
// 💪 HD-COACHING · Strategie & Autorität pro Typ üben
// ═══════════════════════════════════════════════════════════
class _HdCoachingTab extends StatelessWidget {
  const _HdCoachingTab();

  static final List<({String typ, String emoji, String strategie, String autoritaet, List<String> uebungen})> _types = [
    (
      typ: 'Generator',
      emoji: '⚡',
      strategie: 'Reagieren auf das, was auftaucht',
      autoritaet: 'Sakrale Autorität (Bauchgefühl, "uh-huh" / "uh-uh")',
      uebungen: [
        'Heute 3x: vor einer Entscheidung warten, bis Bauch ein "Ja" oder "Nein" signalisiert',
        'Spüre den Sakralen Klang in Konversationen — antworte mit "mhh" statt schnellem Wort',
        'Abends: 3 Dinge notieren, die heute Frustration vs. Befriedigung gebracht haben',
        'Tu eine Sache nur, weil du Lust hast — ohne Begründung',
      ],
    ),
    (
      typ: 'Manifesting Generator',
      emoji: '🔥',
      strategie: 'Reagieren UND Informieren',
      autoritaet: 'Sakral + Schnelligkeit zwischen Schritten',
      uebungen: [
        'Vor einem Sprung in neue Tätigkeit: Bezugspersonen kurz informieren',
        'Erlaube dir Multi-Tasking ohne schlechtes Gewissen',
        'Frage dich: "Bin ich noch dran an dem ursprünglichen Thema oder bin ich abgesprungen?"',
        'Lass eine Sache mitten drin liegen — das ist okay',
      ],
    ),
    (
      typ: 'Manifestor',
      emoji: '🚀',
      strategie: 'Informieren BEVOR du handelst',
      autoritaet: 'Emotional ODER Splenisch',
      uebungen: [
        'Heute 1x klar informieren, was du als nächstes tust (auch wenn niemand fragt)',
        'Spüre nach: wo erlaubt der Körper, wo zieht er sich zusammen',
        'Praktiziere "Ich initiiere" — ohne Schuldgefühl wenn andere zucken',
        'Schaffe heute 30 Min reine Ruhepausen (Manifestoren brauchen mehr Pause als sie denken)',
      ],
    ),
    (
      typ: 'Projector',
      emoji: '🎯',
      strategie: 'Auf Einladung warten',
      autoritaet: 'Splenisch / Emotional / Ego / Self-Projected',
      uebungen: [
        'Heute mindestens 1x: NICHT von dir aus initiieren, sondern eingeladen werden',
        'Beobachte Energien anderer — du siehst Muster, die sie selbst nicht sehen',
        '2 Stunden Energie-Sparen pro Tag aktiv einplanen (Projektoren erschöpfen schnell)',
        'Frage: "Wem wurde ich heute eingeladen, einen Spiegel zu sein?"',
      ],
    ),
    (
      typ: 'Reflector',
      emoji: '🌙',
      strategie: 'Mondzyklus abwarten (28 Tage) bei großen Entscheidungen',
      autoritaet: 'Lunar (Mondzyklus-Reflexion)',
      uebungen: [
        'Notiere heute: welche Umgebung lädt dich auf, welche entzieht?',
        'Bei wichtiger Entscheidung: warte einen kompletten Mondzyklus, beobachte das Bild',
        'Lass dich heute von einem unerwarteten Ort/Mensch überraschen',
        'Du spiegelst die Umgebung — was siehst du gerade in dir, was nicht "deins" ist?',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _types.length + 1,
      itemBuilder: (_, i) {
        if (i == 0) {
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0288D1), Color(0xFF26C6DA)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'Pro HD-Typ vier praktische Übungen für deine STRATEGIE + AUTORITÄT. '
              'Tippe deinen Typ unten an, dann jeden Tag eine Übung. '
              '7 Tage Praxis = signifikante Erlebbarkeit der eigenen Energie.',
              style: TextStyle(color: Colors.white, fontSize: 12.5, height: 1.5),
            ),
          );
        }
        final t = _types[i - 1];
        return ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          backgroundColor: const Color(0xFF0D1B3E).withValues(alpha: 0.6),
          collapsedBackgroundColor: const Color(0xFF0D1B3E).withValues(alpha: 0.4),
          iconColor: const Color(0xFF26C6DA),
          collapsedIconColor: const Color(0xFF26C6DA),
          leading: Text(t.emoji, style: const TextStyle(fontSize: 28)),
          title: Text(t.typ,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          subtitle: Text(t.strategie,
              style: const TextStyle(color: Color(0xFF26C6DA), fontSize: 11)),
          children: [
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('AUTORITÄT: ${t.autoritaet}',
                  style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            for (var j = 0; j < t.uebungen.length; j++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      margin: const EdgeInsets.only(top: 1, right: 8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF26C6DA).withValues(alpha: 0.2),
                        border: Border.all(color: const Color(0xFF26C6DA)),
                      ),
                      child: Text('${j + 1}',
                          style: const TextStyle(color: Color(0xFF26C6DA), fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      child: Text(t.uebungen[j],
                          style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5)),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
