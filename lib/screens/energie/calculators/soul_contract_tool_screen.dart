import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/soul_numerology_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SoulContractToolScreen – 3 Tabs
//   Tab 0: Neu    (Name + Geburtsdatum → Seelenvertrag berechnen)
//   Tab 1: Verlauf (gespeicherte Seelenverträge aus soul_contracts)
//   Tab 2: Zahlen (numerologisches Lexikon mit Kategorie-Filter)
// ─────────────────────────────────────────────────────────────────────────────

const _kGold = Color(0xFFFFD54F);
const _kGoldDeep = Color(0xFFFFB300);
const _kLila = Color(0xFF9C27B0);
const _kDarkBg = Color(0xFF06040F);

final _db = Supabase.instance.client;

class SoulContractToolScreen extends StatefulWidget {
  const SoulContractToolScreen({super.key});

  @override
  State<SoulContractToolScreen> createState() => _SoulContractToolScreenState();
}

class _SoulContractToolScreenState extends State<SoulContractToolScreen>
    with TickerProviderStateMixin {
  late final TabController _tabs;
  late AnimationController _bgCtrl;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
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
      backgroundColor: const Color(0xFF06040F),
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.05),
        title: const Text('📜 Seelenvertrag',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: _kGold,
          labelColor: _kGold,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(icon: Icon(Icons.auto_awesome), text: 'Neu'),
            Tab(icon: Icon(Icons.history), text: 'Verlauf'),
            Tab(icon: Icon(Icons.menu_book), text: 'Zahlen'),
          ],
        ),
      ),
      body: AnimatedBuilder(
        animation: _bgCtrl,
        builder: (context, child) => Stack(
          children: [
            Positioned.fill(child: Container(color: const Color(0xFF06040F))),
            Positioned(
              top: -80 + _bgCtrl.value * 50,
              right: -60,
              child: _CineOrb(
                  color: _kGold,
                  size: 280,
                  opacity: 0.10 + _bgCtrl.value * 0.05),
            ),
            Positioned(
              bottom: -80,
              left: -60 + _bgCtrl.value * 30,
              child: _CineOrb(color: _kLila, size: 240, opacity: 0.08),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.45,
              left: MediaQuery.of(context).size.width * 0.2,
              child: _CineOrb(
                  color: _kGold,
                  size: 160,
                  opacity: 0.04 + _bgCtrl.value * 0.03),
            ),
            child!,
          ],
        ),
        child: TabBarView(
          controller: _tabs,
          children: const [
            _NewContractTab(),
            _HistoryTab(),
            _NumbersGuideTab(),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 0: Neu
// ─────────────────────────────────────────────────────────────────────────────

class _NewContractTab extends StatefulWidget {
  const _NewContractTab();
  @override
  State<_NewContractTab> createState() => _NewContractTabState();
}

class _NewContractTabState extends State<_NewContractTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  DateTime? _birthDate;
  SoulNumerologyResult? _result;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 30, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
            primary: _kGold,
            onPrimary: Colors.black,
            surface: const Color(0xFF0D0A1A),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  void _compute() {
    if (!_formKey.currentState!.validate()) return;
    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bitte Geburtsdatum wählen')));
      return;
    }
    try {
      final r = SoulNumerology.compute(
        fullName: _nameCtrl.text,
        birthDate: _birthDate!,
      );
      setState(() => _result = r);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Berechnungs-Fehler: $e')));
    }
  }

  String _formatDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mystische Header-Karte mit goldener Atmosphäre
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _kGold.withValues(alpha: 0.12),
                    _kLila.withValues(alpha: 0.07),
                    const Color(0xFF06040F),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _kGold.withValues(alpha: 0.4)),
                boxShadow: [
                  BoxShadow(
                      color: _kGold.withValues(alpha: 0.15),
                      blurRadius: 20,
                      spreadRadius: 2),
                ],
              ),
              child: const Row(
                children: [
                  Text('📜', style: TextStyle(fontSize: 32)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Seelenvertrag erstellen',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text(
                            'Vollständiger Geburtsname + Geburtsdatum → Numerologie des Seelenvertrags.',
                            style:
                                TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Name
            TextFormField(
              controller: _nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDeco(
                  label: 'Vollständiger Geburtsname',
                  hint: 'z. B. Maria Elisabeth Schmidt'),
              validator: (v) {
                if (v == null || v.trim().length < 2) {
                  return 'Bitte vollen Namen eingeben';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Birthdate picker – Glassmorphism
            InkWell(
              onTap: _pickBirthDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Row(children: [
                  const Icon(Icons.calendar_month, color: _kGold),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _birthDate == null
                          ? 'Geburtsdatum wählen'
                          : _formatDate(_birthDate!),
                      style: TextStyle(
                          color: _birthDate == null
                              ? Colors.white54
                              : Colors.white,
                          fontSize: 15),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white38),
                ]),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              child: ElevatedButton.icon(
                onPressed: _compute,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Berechnen'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: _kGoldDeep,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
              ),
            ),
            if (_result != null) ...[
              const SizedBox(height: 24),
              _ResultPreview(result: _result!),
              const SizedBox(height: 16),
              SizedBox(
                child: ElevatedButton.icon(
                  onPressed: () => _showDeepResult(_result!),
                  icon: const Icon(Icons.menu_book),
                  label: const Text('Deutung & Speichern'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.07),
                      foregroundColor: _kGold,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: _kGoldDeep))),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadMeanings(
      SoulNumerologyResult r) async {
    final wanted = <List<dynamic>>[
      [r.lifePath, 'life_path'],
      [r.destiny, 'destiny'],
      [r.soulUrge, 'soul_urge'],
      [r.personality, 'personality'],
      ...r.karmicDebts.map((n) => [n, 'karmic_debt']),
    ];
    final rows = await _db.from('soul_number_meanings').select(
        'number, category, title, keywords, short_text, deep_text, practice_text');
    final byKey = <String, Map<String, dynamic>>{
      for (final m in rows)
        '${m['number']}_${m['category']}': Map<String, dynamic>.from(m)
    };
    final out = <Map<String, dynamic>>[];
    for (final w in wanted) {
      final key = '${w[0]}_${w[1]}';
      final m = byKey[key];
      if (m != null) out.add(m);
    }
    return out;
  }

  Future<void> _saveContract(SoulNumerologyResult r, String notes) async {
    final user = _db.auth.currentUser;
    if (user == null) throw Exception('Nicht angemeldet');
    await _db.from('soul_contracts').insert({
      'user_id': user.id,
      'full_name': _nameCtrl.text.trim(),
      'birth_date': _birthDate!.toIso8601String().split('T').first,
      'life_path': r.lifePath,
      'destiny': r.destiny,
      'soul_urge': r.soulUrge,
      'personality': r.personality,
      'birth_day': r.birthDay,
      'karmic_debts': r.karmicDebts,
      'computation': r.computation,
      'notes': notes.trim().isEmpty ? null : notes.trim(),
    });
  }

  void _showDeepResult(SoulNumerologyResult r) {
    final notesCtrl = TextEditingController();
    bool saving = false;
    bool saved = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx2, setSheet) => Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0D0A1A),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: _kGold.withValues(alpha: 0.3), width: 1),
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.85,
            maxChildSize: 0.95,
            minChildSize: 0.5,
            expand: false,
            builder: (_, sc) => FutureBuilder<List<Map<String, dynamic>>>(
              future: _loadMeanings(r),
              builder: (_, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(
                      child: CircularProgressIndicator(color: _kGold));
                }
                if (snap.hasError) {
                  return Center(
                      child: Text('Fehler: ${snap.error}',
                          style: const TextStyle(color: Colors.white54)));
                }
                final meanings = snap.data ?? [];
                return ListView(
                  controller: sc,
                  padding: const EdgeInsets.all(20),
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('📜 Deutung deines Seelenvertrags',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ...meanings.map((m) => _MeaningCard(meaning: m)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: notesCtrl,
                      enabled: !saving && !saved,
                      maxLines: 3,
                      minLines: 2,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Optionale Notiz …',
                        hintStyle: const TextStyle(
                            color: Colors.white38, fontSize: 13),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.06),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.2))),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.2))),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: _kGold)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: (saving || saved)
                            ? null
                            : () async {
                                setSheet(() => saving = true);
                                try {
                                  await _saveContract(r, notesCtrl.text);
                                  if (!sheetCtx2.mounted) return;
                                  setSheet(() {
                                    saving = false;
                                    saved = true;
                                  });
                                  ScaffoldMessenger.of(sheetCtx2).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              '✅ Seelenvertrag gespeichert')));
                                } catch (e) {
                                  if (!sheetCtx2.mounted) return;
                                  setSheet(() => saving = false);
                                  ScaffoldMessenger.of(sheetCtx2).showSnackBar(
                                      SnackBar(content: Text('Fehler: $e')));
                                }
                              },
                        icon: saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.black))
                            : Icon(saved ? Icons.check_circle : Icons.save),
                        label: Text(saving
                            ? 'Speichern …'
                            : (saved ? 'Gespeichert' : 'Vertrag speichern')),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: saved ? Colors.green : _kGoldDeep,
                            foregroundColor: Colors.black,
                            disabledBackgroundColor: saved
                                ? Colors.green
                                : Colors.white.withValues(alpha: 0.1),
                            disabledForegroundColor: Colors.white70,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    ).whenComplete(() => notesCtrl.dispose());
  }

  InputDecoration _inputDeco({required String label, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: Colors.white70),
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.06),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kGold),
      ),
    );
  }
}

// Result Preview – große goldene Zahlen mit Glow-Effekt
class _ResultPreview extends StatelessWidget {
  final SoulNumerologyResult result;
  const _ResultPreview({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _kGold.withValues(alpha: 0.12),
            _kLila.withValues(alpha: 0.06),
            const Color(0xFF06040F),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kGold.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
              color: _kGold.withValues(alpha: 0.15),
              blurRadius: 16,
              spreadRadius: 1),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Dein Seelenvertrag (Zahlen)',
              style: TextStyle(
                  color: _kGold, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _ResultRow(label: 'Lebensweg', value: result.lifePath.toString()),
          _ResultRow(label: 'Ausdruck', value: result.destiny.toString()),
          _ResultRow(label: 'Seelenantrieb', value: result.soulUrge.toString()),
          _ResultRow(
              label: 'Persönlichkeit', value: result.personality.toString()),
          _ResultRow(label: 'Geburtstag', value: result.birthDay.toString()),
          if (result.karmicDebts.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Karmische Schulden: ${result.karmicDebts.join(', ')}',
              style: const TextStyle(color: Colors.orangeAccent, fontSize: 13),
            ),
          ],
          const SizedBox(height: 12),
          const Text(
            'Tippe im nächsten Schritt „Deutung ansehen" für die detaillierten Texte.',
            style: TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  const _ResultRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ),
          // Große goldene Zahl mit Glow-Effekt
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
              border: Border.all(color: _kGold, width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: _kGold.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 1),
              ],
            ),
            child: Text(value,
                style: const TextStyle(
                    color: _kGold, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1: Verlauf
// ─────────────────────────────────────────────────────────────────────────────

class _HistoryTab extends StatefulWidget {
  const _HistoryTab();
  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> {
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
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = 'Bitte zuerst anmelden';
        });
        return;
      }
      final rows = await _db
          .from('soul_contracts')
          .select()
          .eq('user_id', user.id)
          .order('computed_at', ascending: false);
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
        backgroundColor: const Color(0xFF0D0A1A),
        title: const Text('Seelenvertrag löschen?',
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
              child: const Text('Löschen', style: TextStyle(color: _kGold))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _db.from('soul_contracts').delete().eq('id', id);
      if (!mounted) return;
      setState(() => _rows.removeWhere((r) => r['id'] == id));
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Vertrag gelöscht')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Fehler: $e')));
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
      return const Center(child: CircularProgressIndicator(color: _kGold));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!,
                  style: const TextStyle(color: Colors.white54),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              TextButton(
                  onPressed: _load,
                  child: const Text('Erneut versuchen',
                      style: TextStyle(color: _kGold))),
            ],
          ),
        ),
      );
    }
    if (_rows.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
              'Noch keine Seelenverträge gespeichert.\nErstelle deinen ersten Vertrag im Neu-Tab.',
              style: TextStyle(color: Colors.white54),
              textAlign: TextAlign.center),
        ),
      );
    }
    return RefreshIndicator(
      color: _kGold,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _rows.length,
        itemBuilder: (_, i) {
          final r = _rows[i];
          final karmic = (r['karmic_debts'] as List?) ?? const [];
          final notes = r['notes'] as String?;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kGold.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(color: _kGold.withValues(alpha: 0.05), blurRadius: 8),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.auto_stories, color: _kGold),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r['full_name'] as String? ?? '—',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(
                            '★ ${r['birth_date']}  •  ${_formatDate(r['computed_at'] as String)}',
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
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _NumBadge(label: 'Lebensweg', value: r['life_path']),
                    _NumBadge(label: 'Ausdruck', value: r['destiny']),
                    _NumBadge(label: 'Seele', value: r['soul_urge']),
                    _NumBadge(label: 'Persönl.', value: r['personality']),
                    _NumBadge(label: 'Geburtstag', value: r['birth_day']),
                  ],
                ),
                if (karmic.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text('⚖️ Karmische Schulden: ${karmic.join(", ")}',
                      style: const TextStyle(
                          color: Colors.orangeAccent, fontSize: 12)),
                ],
                if (notes != null && notes.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15))),
                    child: Text(notes,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NumBadge extends StatelessWidget {
  final String label;
  final dynamic value;
  const _NumBadge({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: _kGold.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kGold.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(color: _kGold.withValues(alpha: 0.1), blurRadius: 4),
          ]),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label  ',
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
          Text('$value',
              style: const TextStyle(
                  color: _kGold, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2: Zahlen-Guide
// ─────────────────────────────────────────────────────────────────────────────

class _NumbersGuideTab extends StatefulWidget {
  const _NumbersGuideTab();
  @override
  State<_NumbersGuideTab> createState() => _NumbersGuideTabState();
}

class _NumbersGuideTabState extends State<_NumbersGuideTab> {
  List<Map<String, dynamic>> _all = [];
  bool _loading = true;
  String _category = 'life_path';

  static const _tabs = [
    ('life_path', '🌟 Lebensweg'),
    ('destiny', '🎯 Ausdruck'),
    ('soul_urge', '💖 Seele'),
    ('personality', '🎭 Person'),
    ('karmic_debt', '⚖️ Karma'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows =
          await _db.from('soul_number_meanings').select().order('sort_order');
      if (!mounted) return;
      setState(() {
        _all = List<Map<String, dynamic>>.from(rows);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _kGold));
    }
    final filtered = _all.where((m) => m['category'] == _category).toList();
    return Column(
      children: [
        SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: _tabs.length,
            itemBuilder: (_, i) {
              final t = _tabs[i];
              final sel = _category == t.$1;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(t.$2,
                      style: TextStyle(
                          color: sel ? Colors.black : Colors.white54,
                          fontSize: 12)),
                  selected: sel,
                  selectedColor: _kGold,
                  backgroundColor: Colors.white.withValues(alpha: 0.06),
                  side: BorderSide(
                      color:
                          sel ? _kGold : Colors.white.withValues(alpha: 0.2)),
                  onSelected: (_) => setState(() => _category = t.$1),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            itemCount: filtered.length,
            itemBuilder: (_, i) => _MeaningCard(meaning: filtered[i]),
          ),
        ),
      ],
    );
  }
}

const _kCategoryLabels = <String, String>{
  'life_path': '🌟 Lebensweg',
  'destiny': '🎯 Ausdruck',
  'soul_urge': '💖 Seelenantrieb',
  'personality': '🎭 Persönlichkeit',
  'birth_day': '🌙 Geburtstag',
  'karmic_debt': '⚖️ Karmische Schuld',
  'master': '✨ Meisterzahl',
};

class _MeaningCard extends StatelessWidget {
  final Map<String, dynamic> meaning;
  const _MeaningCard({required this.meaning});

  @override
  Widget build(BuildContext context) {
    final cat = meaning['category'] as String? ?? '';
    final catLabel = _kCategoryLabels[cat] ?? cat;
    final number = meaning['number'];
    final title = meaning['title'] as String? ?? '';
    final keywords = (meaning['keywords'] as List?) ?? const [];
    final shortText = meaning['short_text'] as String? ?? '';
    final deepText = meaning['deep_text'] as String? ?? '';
    final practice = meaning['practice_text'] as String?;
    final isKarmic = cat == 'karmic_debt';
    final accent = isKarmic ? Colors.orangeAccent : _kGold;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(color: accent.withValues(alpha: 0.08), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            // Große goldene Zahl mit Glow
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                  border: Border.all(color: accent, width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: accent.withValues(alpha: 0.3),
                        blurRadius: 10,
                        spreadRadius: 1),
                  ]),
              child: Text('$number',
                  style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(catLabel,
                      style: TextStyle(
                          color: accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ]),
          if (keywords.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: keywords
                  .map((k) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: accent.withValues(alpha: 0.35))),
                        child: Text('$k',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 11)),
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 10),
          Text(shortText,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontStyle: FontStyle.italic)),
          const SizedBox(height: 8),
          Text(deepText,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 13, height: 1.4)),
          if (practice != null && practice.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.lightGreenAccent.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Colors.lightGreenAccent.withValues(alpha: 0.4))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🌱 Praxis',
                      style: TextStyle(
                          color: Colors.lightGreenAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(practice,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12, height: 1.35)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CineOrb – ambient background glow orb
// ─────────────────────────────────────────────────────────────────────────────

class _CineOrb extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;
  const _CineOrb(
      {required this.color, required this.size, required this.opacity});
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
